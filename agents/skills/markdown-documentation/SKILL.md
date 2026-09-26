---
name: markdown-documentation
description: Apply the repository's documentation style and document layouts when creating or editing Markdown files.
---

# Markdown Documentation

Use this skill whenever you create, edit, or review a Markdown document. It provides the standard tone, structure, metadata, examples, and reference guidance for documentation.

## What should the document do first?

Start with a short answer to `What am I looking at?` Give the reader the purpose of the document and a simple map of what follows.

For task-focused or reference documents, prefer questions as headings. Answer each question immediately, then add examples or details.

## What metadata should the document include?

When a Markdown file needs document metadata or may be consumed by a documentation framework, add portable YAML front matter as the first content in the file:

```yaml
---
title: A clear page title
description: A short summary of what the reader will learn or do.
---
```

Use `title` and `description` as the shared baseline because they are supported by many documentation tools, including Astro Starlight. Keep values plain and framework-neutral. Add tool-specific fields only when the target framework requires them, and document those fields in that framework's guidance.

Front matter may be used in any Markdown file, including repository `README.md` files, when its metadata is useful to readers or consuming tools.

## Which layout should I use?

Use this small, flexible layout as the starting point:

````md
---
title: A clear page title
description: A short summary of the page.
---

## What am I looking at?

A short explanation of the topic and the main things the reader can do.

## Is there any external references to this documentation?

- [Related guide](./guide.md) — explains the connected workflow.
- [Source repository](https://github.com/example/project) — contains the implementation.
````

## Does the document follow the layout?

- Front matter, when used, is the first content and includes `title` and `description`.
- The document starts with `What am I looking at?`.
- External references, when relevant, use the `Is there any external references to this documentation?` section.
