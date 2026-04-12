# Dual Boot: Windows + Omarchy with Limine

Set up a machine running both Windows and Omarchy (Arch Linux), with Limine as the bootloader and LUKS disk encryption on the Arch side.

---

## Before you start

- Back up everything
- Have a [Ventoy](https://www.ventoy.net/) USB stick ready with both a Windows ISO and an Arch Linux ISO

---

## 1. Install Windows

1. Boot from your Ventoy stick and select the Windows ISO
2. When prompted, delete all existing partitions to start with a clean slate
3. Select the unallocated space and proceed with the Windows installation
4. Once Windows is installed and booted, open **Disk Management** (`Win + X > Disk Management`)
5. Right-click the Windows partition and select **Shrink Volume**
6. Shrink by ~300,000 MiB (≈300 GiB) to leave room for Arch — leave the freed space as unallocated, no need to create a new volume

---

## 2. Boot into Arch Install Media

Reboot and boot from your Ventoy stick, this time selecting the Arch Linux ISO.

### Connect to WiFi

```bash
iwctl
```

Inside the `iwctl` prompt:

```
# If you have multiple network interfaces, list them first:
station list

# Otherwise, with a single NIC (wlan0 is typical):
station wlan0 scan
station wlan0 connect <your-network-name>   # press Tab to autocomplete
station wlan0 show                          # confirm connected
exit
```

---

## 3. Install Arch Linux via `archinstall`

```bash
archinstall
```

Use the following settings:

| Section | Option |
| --- | --- |
| Mirrors and repositories | Select regions > Your country |
| Disk configuration | Partitioning > Default partitioning layout > Select your disk (Space + Enter) |
| Disk > File system | `btrfs` — default structure: yes, use compression: yes |
| Disk > Partitions | 1 GiB `fat32` for `/boot`, rest for `btrfs` |
| Disk > btrfs subvolumes | `@` → `/`, `@home` → `/home`, `@log` → `/var/log`, `@pkg` → `/var/cache/pacman/pkg` |
| Disk > Disk encryption | Encryption type: `LUKS` + set a password + select the btrfs partition |
| Hostname | Give your machine a name |
| Bootloader | `Limine` |
| Authentication > Root password | Set yours |
| Authentication > User account | Add a user > Superuser: Yes > Confirm and exit |
| Applications > Audio | `pipewire` |
| Network configuration | Copy ISO network config |
| Timezone | Set yours |

> **Important:** The LUKS encryption password is what you'll enter on every boot — not your user account password. Don't forget it.

---

## 4. Install Omarchy

After `archinstall` completes, reboot into your new Arch install and log in.

### Fix the mirror issue (if you hit 404 errors)

The default Omarchy mirror may return 404 errors. Replace it with a mirror close to your region before installing. Since no text editor is available yet, use `cat`:

```bash
# Find your closest mirror at https://archlinux.org/mirrorlist/
# Example using a Singapore mirror:
cat "https://mirror.sg.gs/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
```

> See also: [Reddit thread on 404 errors](https://www.reddit.com/r/omarchy/comments/1ng8qmw/404_errors_installing_packages/)

### Run the Omarchy installer

```bash
curl -fsSL https://omarchy.org/install | bash
```

Then reboot.

> Reference: [Omarchy Manual Installation](https://learn.omarchy.org/2/the-omarchy-manual/96/manual-installation)

---

## 5. Enable Dual Boot in Limine

After Omarchy installs and you reboot, Limine will only show the Linux entry by default. To add Windows:

```bash
limine-entry-tool --scan
```

This detects "Windows Boot Manager" and adds it to the Limine menu. Reboot to confirm both options appear.

---

## Boot sequence

1. **Limine menu** — choose Windows or Linux
2. If Linux: **LUKS prompt** — enter your disk encryption password
3. Omarchy loads — log in with your user password
