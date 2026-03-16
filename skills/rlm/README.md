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

`/rlm` is a long-context analysis skill backed by a persistent local REPL (`scripts/rlm_repl.py`).
It supports single-file and recursive directory corpus ingestion for repeated query workflows.

## Usage

Invoke the skill with:

- `context=<path>`: file path or corpus directory
- `query="<your question>"`

Examples:

```text
/rlm context=./docs/observability.md query="Summarize alerting gaps"
/rlm context=./architecture-docs query="Compare security and communications assumptions"
```

`query` is required at the skill interface.

## How it works

1. Load context once (`init` for a file, `init-corpus` for a directory).
2. Reuse the persisted REPL state for additional queries.
3. Reset and reload manually when source content changes.

State is persisted at `.claude/rlm_state/state.pkl` by default.

## Key Considerations

- Most important workflow: load once, run many queries, reset only when needed.
- Corpus mode is recursive and honors `.rlmignore`.
- Default corpus excludes: `.git/`, `node_modules/`, `bin/`, `_archive/`.
- Optional parsers are required for `pdf`, `docx`, and `odt`.
- Best-effort ingestion is default; `--strict` fails on first parse error.

## Development Considerations

### Quick Start

```bash
python3 scripts/rlm_repl.py check-deps
python3 scripts/rlm_repl.py install-deps --all --dry-run
```

### Building & running

Single-file mode:

```bash
python3 scripts/rlm_repl.py init <context_file>
python3 scripts/rlm_repl.py status
python3 scripts/rlm_repl.py exec -c "print(grep('security', max_matches=5))"
```

Corpus mode:

```bash
python3 scripts/rlm_repl.py init-corpus <context_dir>
python3 scripts/rlm_repl.py status
python3 scripts/rlm_repl.py exec -c "print(grep('observability', max_matches=5))"
```

Strict corpus mode:

```bash
python3 scripts/rlm_repl.py init-corpus <context_dir> --strict
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
