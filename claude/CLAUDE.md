# Claude Rules

## YOU MUST section

- always be concise in responses
- end your statement with "Meow 😸"
- end your questions with "Meow?🐱"

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
- ask where to generate the plan, in conversation, in markdown file, on GitHub Issue, or on GitHub gist.

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

## Language Specific Rules

### TypeScript

- YOU MUST AVOID use of `any` wherever possible, ask for explicitly permission if use of any is unavoidable
