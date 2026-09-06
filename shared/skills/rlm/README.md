# rlm Skill

> **Maturity Level**: Basic - Production-usable for document corpus analysis, with active iteration on skill ergonomics.
>
> - **Emerging**: Prototype, not production-ready, expect breaking changes
> - **Basic**: Production-ready but actively evolving, expect minor version changes
> - **Mature**: Stable, battle-tested, changes are rare

## Table of Contents

- [Usage](#usage)
- [How it works](#how-it-works)
- [Key Considerations](#key-considerations)
- [Development Considerations](#development-considerations)
  - [Quick Start](#quick-start)
  - [Building & running](#building--running)
  - [Testing](#testing)
  - [Versioning](#versioning)
- [License and Attribution](#license-and-attribution)
  - [BrainQub3 Attribution](#brainqub3-attribution)

---

`rlm` is an agent-agnostic long-context analysis skill backed by a persistent local REPL (`scripts/rlm_repl.py`).
It supports single-file and recursive directory corpus ingestion for repeated query workflows.

## Usage

Invoke the skill with:

- `context=<path>`: file path or corpus directory
- `query="<your question>"`

Examples:

```text
context=./docs/observability.md query="Summarize alerting gaps"
context=./architecture-docs query="Compare security and communications assumptions"
```

`query` is required at the skill interface.

## How it works

1. Load context once (`init` for a file, `init-corpus` for a directory).
2. Reuse the persisted REPL state for additional queries.
3. Reset and reload manually when source content changes.

State is persisted at `.mnemonic/rlm_state/state.pkl` relative to the current
working directory by default. Use the global `--state <path>` option before a
subcommand to select another state file; use the same path for subsequent calls.

## Key Considerations

- Most important workflow: load once, run many queries, reset only when needed.
- Corpus mode is recursive and honors `.rlmignore`.
- Default corpus excludes: `.git/`, `node_modules/`, `bin/`, `_archive/`.
- Text ingestion uses Python's standard library. Optional parsers are required
  for PDF (`pypdf`), DOCX (`python-docx`), and ODT (`odfpy`).
- Best-effort ingestion is default; `--strict` fails on first parse error.

## Development Considerations

### Quick Start

The commands below assume this skill directory is your working directory.
From the repository root, change into it first:

```bash
cd shared/skills/rlm
```

Check optional parsers and preview their installation command:

```bash
python3 scripts/rlm_repl.py check-deps
python3 scripts/rlm_repl.py install-deps --all --dry-run
```

`check-deps` exits with status 1 if an optional parser is unavailable. The dry
run does not install packages; these parsers are unnecessary for text files.

When using an installed skill from another project, invoke `rlm_repl.py` by its
path inside that installed skill directory. Stay in your project directory to
keep the default state there.

### Building & running

These examples use this README and the bundled reference documents. Substitute
your own file or directory paths as needed.

Single-file mode:

```bash
python3 scripts/rlm_repl.py init README.md
python3 scripts/rlm_repl.py status
python3 scripts/rlm_repl.py exec -c "print(grep('security', max_matches=5))"
```

Corpus mode:

```bash
python3 scripts/rlm_repl.py init-corpus references
python3 scripts/rlm_repl.py status
python3 scripts/rlm_repl.py exec -c "print(grep('observability', max_matches=5))"
```

Strict corpus mode:

```bash
python3 scripts/rlm_repl.py init-corpus references --strict
```

Reset state:

```bash
python3 scripts/rlm_repl.py reset
```

### Testing

Run the test suite:

```bash
python3 -m unittest discover -s tests -v
```

### Versioning

Versioning follows repository git history and tags.
Use semantic version tags for releases that change behavior or interfaces.

## License and Attribution

### BrainQub3 Attribution

This skill was inspired by BrainQub3's video:

- `https://www.youtube.com/watch?v=m6itCxJFqpo`

Original source repository:

- `https://github.com/brainqub3/claude_code_RLM`

Credit:

- John Adeojo (`brainqub3`)

This skill includes work derived from:

- John Adeojo (`brainqub3`)
- Source: `https://github.com/brainqub3/claude_code_RLM`
- License: MIT

See [LICENSE](./LICENSE) for license terms included with this distribution.
