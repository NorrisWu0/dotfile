---
name: design
description: Wireframing, prototyping, and aesthetic reasoning. Generates production-quality UI prototypes and design rationale.
---

# Design Skill

Capability for wireframing, prototyping, and aesthetic reasoning.

## Capabilities

- ASCII wireframe generation (2-3 options per prompt)
- Code prototype creation (HTML/CSS)
- Aesthetic reasoning and rationale
- Layout and spacing decisions
- Component hierarchy design

## Workflow

### Phase 1: Clarify

Before designing, establish:
- Feature scope (what's in/out)
- Target viewport (mobile-first, desktop, responsive)
- Existing patterns to match (if any)
- User constraints (accessibility, brand, etc.)

### Phase 2: High-Fidelity Prototype

**Go straight to production-quality code.** No wireframes, no rough layouts.

- Use existing design system components (discover via agent's design system flow)
- Apply design tokens (colors, typography, spacing)
- Production-ready quality, not sketches
- Each prototype should feel like a finished design

Create prototypes at derived location (e.g., `src/app/internal/{feature}/design-ideas-{N}/`)

Structure:
```
design-ideas-{N}/
  page.tsx        # if Next.js app
  # OR
  index.html      # standalone preview
  styles.css      # scoped styles (if needed)
  README.md       # brief design notes
```

Prototypes should be viewable in browser. Match the app's framework.

### Phase 3: Review & Iterate

User reviews prototypes in browser, provides feedback. Refine until approved.

## Constraints

- Prefer vanilla HTML/CSS unless a library adds clear value
- When proposing libraries, explain what problem they solve
- Creative freedom unless brand guidelines provided
- Prototypes should be viewable with minimal setup

## Output Quality

- Clean, readable code
- Semantic HTML
- Logical component boundaries
- Comments for non-obvious decisions
- Responsive by default
