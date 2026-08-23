---
name: make-pr
description: Write clear, concise PR descriptions readable in under 3 minutes. Use via /make-pr command with optional --draft flag.
---

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
- Group key changes by user-facing feature, not by architecture layer
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

### 5. Wrap Up After Merge

When the user confirms the PR is merged, clean up the local workspace:

```bash
# Capture the working branch before switching
branch=$(git branch --show-current)

# Detect the base branch (main, master, etc.)
base=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

# Switch to base branch
git checkout "$base"

# Delete the merged working branch
git branch -d "$branch"

# Pull latest base branch
git pull
```

- The base branch is auto-detected — never assume `main` vs `master`.
- If `git branch -d` fails because the branch isn't recognized as merged (e.g. squash merge), confirm with the user before using `git branch -D`.

## Default Template

When no project template exists:

```markdown
## TL;DR

- [one line per change, at a glance]

## Why are we making this change?

[1-2 sentences on the problem or motivation this PR solves]

## What are the key changes?

### [Feature/outcome 1]
[2-3 sentences max]

### [Feature/outcome 2]
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
| Why | Issue, context, or conversation | Problem it solves, not implementation |
| Key changes | Full diff analysis | Group by feature/outcome, not by layer (repo/service/UI) |
| Can be merged? | Project config | List actual commands, no checkboxes |
| What else? | Minor changes, deps, refactors | Only if notable, else "N/A" |

## Key Changes Examples

**Good** (feature/outcome, high-level):

```markdown
### Todo feature
Users can create, complete, and delete todos. Todos persist across reloads.

### Dark mode toggle
A global theme switch in settings applies instantly across all views.
```

**Bad** (spread too thin by layer, implementation detail):

```markdown
### Repository layer
Added TodoRepository with CRUD methods backed by SQLite.

### Service layer
Added TodoService to orchestrate validation and persistence.

### UI layer
Added TodoList and TodoItem components wired to the service.
```

## Anti-patterns

- Implementation details ("changed line 42 in foo.ts")
- Grouping by architecture layer (repo/service/UI) instead of user-facing outcome
- Verbose explanations
- Sub-bullets
- Padding empty sections
- Checking any checkboxes (human-only)
