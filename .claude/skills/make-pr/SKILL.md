# Make PR

Write clear, concise PR descriptions readable in under 3 minutes.

## When to Use

- `/make-pr` - Create a PR with well-structured description
- `/make-pr --draft` - Create as draft PR

## Workflow

### 1. Detect Template

Check for project template:
```bash
cat .github/pull_request_template.md 2>/dev/null
```

- If exists → follow that template's structure
- If not → use default template below

### 2. Gather Context

```bash
# Get base branch
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'

# Get commits on this branch
git log main..HEAD --oneline

# Get diff summary
git diff main...HEAD --stat

# Get full diff
git diff main...HEAD
```

### 3. Generate Description

**Writing rules:**
- Under 3 min read target
- High-level language, no implementation details
- One line per bullet, no sub-bullets
- Leave sections empty or "N/A" if not applicable
- No filler content

### 4. Preview & Confirm

Show the generated description:
> "Here's the PR description. Happy with it?"

On approval, create PR:
```bash
gh pr create --title "<title>" --body-file /tmp/pr-body.md
```

For draft: add `--draft` flag.

## Default Template

When no project template exists:

```markdown
## TL;DR

- [one line per change, at a glance]

## What are the key changes?

### [Change 1 title]
[2-3 sentences max]

### [Change 2 title]
[2-3 sentences max]

## How do I know this PR can be merged?

- Tests pass (`[detected command]`)
- Build succeeds (`[detected command]`)
- Manual testing: [brief description]

## What else should I know?

- [optional misc, one line each, or "N/A"]

---

## Confirmation

- [ ] I confirm I have read through this PR description and verify the information accurately reflects the intent of this PR.
```

**Detect test/build commands from:**
- `package.json` scripts (test, build)
- `Makefile` targets
- Common patterns (pytest, go test, cargo test)

## Content Guidelines

| Section | Source | Rule |
|---------|--------|------|
| TL;DR | Commit messages + diff summary | One line per logical change |
| Key changes | Full diff analysis | Group related files, explain "what" not "how" |
| Can be merged? | Project config | List actual commands, no checkboxes |
| What else? | Minor changes, deps, refactors | Only if notable, else "N/A" |

## Anti-patterns

- Implementation details ("changed line 42 in foo.ts")
- Verbose explanations
- Sub-bullets
- Padding empty sections
- Checking any checkboxes (human-only)
