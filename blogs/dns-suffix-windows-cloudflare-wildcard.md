# DNS Debugging: Windows Resolving Everything to Cloudflare

The initial symptom was `ERR_SSL_VERSION_OR_CIPHER_MISMATCH` in Chrome — sites were loading with a TLS certificate mismatch. Digging into DNS revealed all domains, including `google.com`, were returning Cloudflare IPs (`104.21.x.x`, `172.67.x.x`) regardless of which DNS server was queried. Turned out to be three compounding issues.

---

## The Clue

Running `nslookup google.com` showed the non-authoritative answer coming back as `google.com.norriswu.me` — a dead giveaway that a DNS search suffix was being appended to every query.

---

## Root Cause

Two things combining to break DNS:

1. **OPNsense broadcasting `norriswu.me` as the DHCP domain name** — Windows receives this via DHCP and appends it to all queries as a search suffix
2. **Cloudflare wildcard record `*.norriswu.me`** — means `google.com.norriswu.me` actually resolves (to Cloudflare proxy IPs), so Windows stops there instead of falling back to the real `google.com`

Other devices (iOS, Android, Mac) were unaffected because they handle DHCP-provided domain suffixes less aggressively than Windows.

Confirm this by checking the registry:

```powershell
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" | Select-Object Domain, SearchList, DhcpDomain
```

`DhcpDomain` will show `norriswu.me` — set by DHCP, not manually.

---

## Fix 1: Override the DNS Search Suffix on Windows

Rather than removing the OPNsense DHCP domain setting, override it on the Windows side via the registry (the GUI requires at least one entry and won't accept empty):

```powershell
# Run as Administrator
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "SearchList" -Value "local"
```

`SearchList` takes precedence over `DhcpDomain`. Setting it to `local` is harmless — Windows will only try appending `.local` to unqualified names.

Flush and verify:

```cmd
ipconfig /flushdns
nslookup google.com
```

Should now return `142.250.x.x`.

After fixing system DNS, clear Chrome's internal DNS cache too — it caches resolutions independently and was still connecting to the Cloudflare IP, causing the TLS cert mismatch:

```
chrome://net-internals/#dns     → Clear host cache
chrome://net-internals/#sockets → Flush socket pools
```

Then hard reload: `Ctrl + Shift + R`

---

## Fix 2: Disable Chrome's DNS over HTTPS

`*.home.norriswu.me` is already handled by Unbound on OPNsense with host overrides — Windows resolved it fine via `nslookup`. But Chrome was still failing because it uses its own **DNS over HTTPS (DoH)** resolver, bypassing OPNsense entirely and hitting Cloudflare's public DoH instead.

Disable it at:

```
chrome://settings/security → Use secure DNS → Off
```

Since OPNsense + Unbound is already managing DNS locally, Chrome's DoH only conflicts with local overrides.

---

## Summary

| Problem | Cause | Fix |
|---------|-------|-----|
| `ERR_SSL_VERSION_OR_CIPHER_MISMATCH` in Chrome | Wrong IP cached — DNS resolving to Cloudflare instead of origin | Fix DNS + clear Chrome DNS cache & socket pools |
| All domains → Cloudflare IPs | OPNsense DHCP domain + Cloudflare wildcard | Set `SearchList` in registry |
| Chrome ignoring local DNS overrides | DNS over HTTPS bypassing OPNsense | Disable Secure DNS in Chrome settings |
