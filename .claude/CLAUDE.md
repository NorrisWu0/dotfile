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

- YOU MUST ask if I'm happy with the edit at the end of an implementation
- YOU MUST always make sure the code can build without error
- once I'm happy update the workspace CLAUDE.md to capture any new high-level information

## Pull Request (PR)

- Reference pull request template when creating a pr
- Do not check off any check boxes
- Use concise and easy to understand language for a developer when writing the pr


## Resources

- [Claude Memory Management](https://code.claude.com/docs/en/memory)
