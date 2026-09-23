# Claude Rules

## YOU MUST section

- always be concise in responses
- end your statement with "Meow 😸"
- end your questions with "Meow?🐱"
- remember that your user is dyslexia, keep your response in maximum 20 - 30 lines, and use progressive disclosure technique when outputting information
- remember that your user did not went to school, therefore, keeping your explanation in plain English is preferred.

## GitHub

- use GitHub CLI (gh) when interacting with github repository, pull request or GitHub gist.

## Init Mode /init

- Try to generate a mermaid graph to connect all the resources involed in the scope you are intializing for
- Update root README with a brief and concise verion of the understanding

## Plan Mode

- YOU MUST start planning with a markdown file in /tmp directory, keep a running record the plan as the conversation goes. Show link to access the tmp plan file at the end of each message
- YOU MUST be concise when generating a plan, grammar can be sacrified over conciseness
- YOU MUST break down large plan into stages, each stage will have a testable outcome we can reference to verify the completion of each stage.
- YOU MUST include clarifying questions at the end of the plan if there's any.
- append suggestion and recommendation to the end of plan, shortlist to 3 by default.

## Edit Mode

- YOU MUST always make sure the code can build without error
- YOU MUST always make sure the sanity check passes (`pnpm sanity`, `pnpm build lint type-check`, or relevant script passes) after implementations
- YOU MUST not push unless explicitly instructed, always default to let user handle git push.

## Pull Request (PR)

- Use `/make-pr` skill for creating PRs
- Reference project template if exists, else use default structure
- Under 3 min read, high-level language, no implementation details
- Do not check off any checkboxes (human-only)

## General Coding Practice

- Check `package.json` or the repo lock file to understand which package manager to use
- DO NOT write new dependencies directly into `pacakge.json`, always use package manager to manage dependencies
- Follow the DRY principle: keep each piece of information in one authoritative place and avoid duplicating logic, configuration, or documentation.
- Prefer self-documenting code with clear names and simple structure over comments that explain what the code already says.
- Add comments only when they explain intent, non-obvious constraints, trade-offs, or important context that cannot be expressed clearly in code.
- Avoid comments that merely repeat a variable name, function name, field name, or the next line of code.
- When documentation includes examples and reference tables, do not repeat the same description in both places; choose one authoritative location.

## Documentation Style

- Prefer a Q&A structure for documentation when it matches the reader's needs.
- Start with `What am I looking at?` as an executive summary and high-level map of the document.
- Use questions as section headings when they reflect the reader's likely intent.
- Answer each question directly before adding supporting details, examples, or references.
- Keep examples copyable and place field-specific explanations in the example only when they add useful context.
- Avoid repeating the same explanation across the summary, examples, tables, and prose.
- Include an `Is there any external references to this documentation?` section when related resources exist outside the document.
- Use that section for links to external websites, repository documentation, source code, examples, and related design documents.
- Add a short description explaining why each reference is relevant.
- Do not duplicate reference content; link to the authoritative source instead.

Example opening:

```md
## What am I looking at?

A high-level overview of the system, followed by its main use cases,
configuration examples, reference details, and related resources.

## Is there any external references to this documentation?

- [Related architecture](./architecture.md) — explains the system components and their relationships.
- [Project repository](https://github.com/example/project) — contains the implementation and source code.
```

## Language Specific Rules

### TypeScript

- YOU MUST AVOID use of `any` wherever possible, ask for explicitly permission if use of any is unavoidable
