# Document Skill

Generate concise, educational documentation scoped to directory-level.

## When to Use

- Manual: `/document` or `/document path/to/scope`
- Suggested: After completing significant implementation changes

**Never interrupts active implementation.**

## Workflow

### 1. Trigger
User runs `/document [path]` or confirms ready to document after implementation.

### 2. Clarify
Ask 2-3 quick questions with sensible defaults (inferred from content):

- "Who's the audience?" → Default: developers (for code), users (for CLI/app)
- "Key points to highlight?" → Default: infer from changes made
- "External sources to cite?" → Default: none unless referenced in code/comments

Present defaults for quick confirmation:
> "Audience: developers. Key points: auth guard setup, JWT config. Any additions?"

Skip questions if defaults are obvious from context.

### 3. Outline
Propose structure based on directory-level scope. Use question headings:

```markdown
## What should I know before reading this?
## What does this [thing] do?
## How do I [use/install/configure] it?
## Where can I learn more?
```

Adapt questions to content - CLI tools, API modules, configs each need different questions.

### 4. Write
After approval, generate documentation.

### 5. Confirm
"Happy with this documentation?"

## Directory-Level Scope

Documentation scope matches its location:
- `repo/README.md` → High-level overview, purpose, getting started
- `repo/src/README.md` → Source structure, architecture decisions
- `repo/src/auth/README.md` → Auth module specifics, how it fits with siblings
- `repo/src/auth/guards/README.md` → Guard implementations, usage examples

**Principle:** Docs explain their siblings and children, not the whole project.

## Read Time & Length

**Target: 5 minutes or less per document.**

Include estimated read time at the top:
```markdown
*~3 min read*
```

Calculate: ~200 words per minute. A 5-min doc is ~1000 words max.

**If content exceeds 5 minutes:**
- Break into multiple documents
- Create index/overview doc linking to sub-docs
- Each sub-doc covers one focused topic

Example split:
```
src/auth/
├── README.md          (~2 min - overview, links to details)
├── GUARDS.md          (~3 min - guard implementations)
└── STRATEGIES.md      (~3 min - passport strategies)
```

**Long docs are a sign to split.** Better to have multiple focused docs than one sprawling one.

## Writing Style

**Tone:**
- Concise - no fluff, every sentence earns its place
- Educational - explain "why" briefly, not just "what"
- Direct - active voice, second person ("you")

**Formatting:**
- Question headings (not statements)
- Short paragraphs (2-3 sentences max)
- Code examples where helpful
- Tables for comparisons/options
- Bullet points for lists

**Citations:**
```markdown
> This approach follows [NestJS Guards documentation](https://docs.nestjs.com/guards).
```

**Structure:**
- Start with prerequisites/audience ("What should I know before reading this?")
- End with references if cited ("Where can I learn more?")
- Middle sections adapt to content

**Anti-patterns to avoid:**
- Walls of text
- Obvious statements ("This file contains code")
- Over-explaining basics covered in prerequisites

## When to Suggest Documentation

**Suggest after:**
- New files/modules added
- README's sibling files changed significantly
- User explicitly completed a feature

**Don't suggest after:**
- Bug fixes, typos, minor tweaks
- Mid-implementation changes
- Config-only changes
