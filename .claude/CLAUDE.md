# Claude Rules

## YOU MUST section

- always be concise in responses
- end your statement with "Meow 😸"
- end your questions with "Meow?🐱"

## GitHub

- use GitHub CLI (gh) when interacting with github repository, pull request or GitHub gist. 

## Plan Mode

- YOU MUST start planning with a markdown file in /tmp directory, keep a running record the plan as the conversation goes. Show link to access the tmp plan file at the end of each message
- YOU MUST be concise when generating a plan, grammar can be sacrified over conciseness
- YOU MUST include clarifying questions at the end of the plan if there's any.
- append suggestion and recommendation to the end of plan, shortlist to 3 by default.
- ask where to store the plan at the end, in conversation, in markdown file, on GitHub Issue, or on GitHub gist.

## Edit Mode

- YOU MUST ask if I'm happy with the edit at the end of an implementation
- once I'm happy update the workspace CLAUDE.md to capture any new high-level information

## Resources

- [Claude Memory Management](https://code.claude.com/docs/en/memory)
