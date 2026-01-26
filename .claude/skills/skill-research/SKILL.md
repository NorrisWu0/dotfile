# Skill Research

Research and evaluate existing Claude skills/plugins before installing.

## When to Use

- `/skill-research <topic>` - Find and evaluate skills for a topic
- Before installing any community skill
- When unsure if a credible skill exists

## Workflow

### 1. Search

**Priority order:**
1. GitHub API: `gh search repos "claude skill <topic>"` + `"claude plugin <topic>"`
2. If <3 results, web search: `claude code skill <topic> <current year>`

Filter to relevant results (must be Claude skill/plugin).

### 2. Evaluate Each Candidate

**Check metrics via GitHub API:**
```bash
gh api repos/<owner>/<repo> --jq '.stargazers_count, .forks_count, .pushed_at, .description'
```

**Trust thresholds:**

| Signal | ✅ Trust | ⚠️ Caution | ❌ Don't trust |
|--------|----------|------------|----------------|
| Stars | 50+ | 10-49 | <10 |
| Last updated | <3 months | 3-6 months | >6 months |
| Forks | 5+ | 1-4 | 0 |
| Author | Known org | Individual with history | Unknown |

**Content quality (note but don't warn):**
- Cites authoritative sources?
- Clear examples vs vague advice?
- Aligns with known standards?
- Sufficient depth?

### 3. Present Summary (Default)

```markdown
## Skill Research: <topic>

Found N candidates:

| Skill | Stars | Updated | Trust |
|-------|-------|---------|-------|
| org/skill-name | 450 | 2 weeks ago | ✅ |
| user/other | 12 | 8 months ago | ⚠️ Low activity |

**Recommendation:** [Install X / Create your own / Reference docs directly]

Want detailed report?
```

**Trust score:** Count ✅ signals (max 4)
- 4/4 = "Looks credible"
- 2-3 = "Use with caution"
- 0-1 = "Not recommended"

### 4. Detailed Report (On Request)

When user asks "elaborate", "details", or "tell me more":

```markdown
## Skill Research Report: <topic>

*Generated: YYYY-MM-DD*

### 1. org/skill-name ✅

**Metrics:**
- Stars: N | Forks: N
- Last updated: X ago
- Author: Name (org/individual, N public repos)

**Content evaluation:**
- Cites: [sources or "None"]
- Covers: [topics]
- Examples: [Yes/No/Minimal]
- Depth: N lines, [assessment]

**Verdict:** [Assessment]

---

### Recommendation

[Final recommendation with reasoning]
```

### 5. No Results

```markdown
No credible skills found for "<topic>".

Options:
- Create custom skill (want to brainstorm?)
- Reference authoritative docs directly
```

## Defaults

- Show top 5 candidates max
- Sort by trust score, then stars
- Current year in web searches for freshness
