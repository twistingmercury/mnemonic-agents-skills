---
name: prime
description: Survey a repository to build working context by reading its README and enumerating tracked files. Use when asked to prime, orient to, familiarize yourself with, or understand a project before starting work.
---

# Prime

Read the project's root `README.md` first, if it exists.

If the project is a Git repository, run `git ls-files` to understand its contents. Otherwise, walk the directory to understand the project context.

Ignore files and directories listed in `.gitignore`, as well as these:

- `**/_archive/`
- `**/bin/`
- `**/*_/`
- `.claude/`
- `**/.github/`
