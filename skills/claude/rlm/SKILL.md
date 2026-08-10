---
name: rlm
description: Run a Recursive Language Model-style loop for long-context tasks using a persistent local REPL.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# rlm (Recursive Language Model workflow)

Use this skill when:
- The user provides a large context file or document directory.
- You need iterative search/chunk/extract over that context.
- You want to reuse loaded context across multiple queries.

## Inputs

This skill reads `$ARGUMENTS`.

Required:
- `context=<path>`: file path (single-file mode) or directory path (corpus mode)
- `query=<question>`: question/task to run against the loaded context

Optional:
- `chunk_chars=<int>` (default ~200000)
- `overlap_chars=<int>` (default 0)
- `strict=true` (corpus mode only, fail on first parse error)

If arguments are missing, ask for:
1. context path
2. query

## Workflow

1. Initialize state.

   Single-file mode:

   ```bash
   python3 scripts/rlm_repl.py init <context_path>
   python3 scripts/rlm_repl.py status
   ```

   Corpus mode (recursive, honors `.rlmignore` if present):

   ```bash
   python3 scripts/rlm_repl.py init-corpus <context_dir>
   python3 scripts/rlm_repl.py status
   ```

   Corpus strict mode:

   ```bash
   python3 scripts/rlm_repl.py init-corpus <context_dir> --strict
   ```

2. Check/install optional parsers when needed.

   ```bash
   python3 scripts/rlm_repl.py check-deps
   python3 scripts/rlm_repl.py install-deps
   python3 scripts/rlm_repl.py install-deps --all --dry-run
   ```

3. Scout the loaded context.

   ```bash
   python3 scripts/rlm_repl.py exec -c "print(peek(0, 3000))"
   python3 scripts/rlm_repl.py exec -c "print(peek(len(content)-3000, len(content)))"
   ```

4. Materialize chunks for subagent analysis.

   ```bash
   python3 scripts/rlm_repl.py exec <<'PY'
   paths = write_chunks('.claude/rlm_state/chunks', size=200000, overlap=0)
   print(len(paths))
   print(paths[:5])
   PY
   ```

5. Run subcalls and synthesize results.

## Guardrails

- Do not paste large raw chunks into chat.
- Quote only needed excerpts.
- Keep scratch/state files under `.claude/rlm_state/`.
- For first iteration, refresh manually when sources change:
  - `/rlm reset`
  - then re-run `/rlm context=... query=...`

## Notes

- Optional document parsers:
  - PDF: `pypdf`
  - DOCX: `python-docx`
  - ODT: `odfpy`
- Default corpus excludes: `.git/`, `node_modules/`, `bin/`, `_archive/`.
- Additional reference docs are in `references/`.
