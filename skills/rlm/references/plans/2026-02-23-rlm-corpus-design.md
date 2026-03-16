# RLM Corpus Design (Document-Focused)

Date: 2026-02-23
Status: Draft validated in-session

## Goal

Extend the current single-file `rlm_repl.py` workflow to support a unified corpus built from a directory tree (including subdirectories), while staying document-focused and format-agnostic across technical and non-technical content.

This design supports text-like docs (`.txt`, `.md`, etc.) and common document formats (`.pdf`, `.docx`, `.odt`) with optional FOSS parser dependencies.

## Scope

In scope:
- Recursive ingestion from a root directory
- Unified searchable corpus with source attribution
- `.rlmignore` support and built-in default excludes
- Best-effort mode by default, with optional strict mode
- Metadata-aware chunk output (path + chunk span)
- Backward compatibility for existing single-file workflows

Out of scope:
- Software-code-specific indexing (AST, symbol graph, call graph)
- Refactor-safe code understanding
- Language-server-style code intelligence

A separate future tool will target software docs + source code analysis.

## Current State

Today, `scripts/rlm_repl.py` initializes state from one context file (`init <context_path>`) and stores:
- `context.path`
- `context.loaded_at`
- `context.content`
- `buffers`
- persisted `globals`

Helpers (`peek`, `grep`, `chunk_indices`, `write_chunks`, `add_buffer`) operate on one `content` string.

## Proposed Architecture

Add a new corpus initializer and state model while preserving existing behavior.

### New command

- `init-corpus <root_dir>`

Optional flags:
- `--ignore-file <path>` (defaults to `<root_dir>/.rlmignore` if present)
- `--strict` (fail on first extraction error)
- `--include-ext <csv>` (defaults to document-focused list)
- `--max-files <n>` (safety cap)
- `--max-bytes-per-file <n>` (safety cap)

`init <context_file>` remains unchanged for backward compatibility.

### Corpus state shape

Add `corpus` object in state:

- `corpus.root`: corpus root directory
- `corpus.docs[]`: per-file records
- `corpus.full_text`: concatenated normalized text
- `corpus.index[]`: mapping from corpus char spans to source docs
- `corpus.report`: summary stats for status/diagnostics

Per-doc record (`corpus.docs[]`):
- `path`
- `format` (`txt`, `md`, `pdf`, `docx`, `odt`, ...)
- `text`
- `status` (`loaded`, `skipped`, `error`)
- `error` (nullable)

Index record (`corpus.index[]`):
- `path`
- `doc_index`
- `corpus_start`
- `corpus_end`

## Discovery And Ignore Rules

Directory walk is recursive and deterministic (sorted paths).

Default excludes (always applied unless explicit override is added later):
- `.git/`
- `node_modules/`
- `bin/`
- `_archive/`

Ignore file behavior:
- Use `<root_dir>/.rlmignore` by default if present
- Allow override with `--ignore-file <path>`
- Pattern style should follow gitignore-like semantics where practical

Inclusion behavior:
- Default extensions are document-oriented
- Include code extensions only via explicit `--include-ext` opt-in (not default)

## Extraction Layer

Use pluggable extractors by extension/content type.

Baseline:
- Plain text formats: stdlib read/decode

Optional FOSS extractors:
- PDF: `pypdf`
- DOCX: `python-docx`
- ODT: `odfpy`

Dependency policy:
- No paid or proprietary parser requirements
- Missing optional parser should produce clear diagnostics

Normalization:
- newline normalization
- UTF-8 replacement fallback where needed
- minimal whitespace normalization only

## Execution Semantics

### Modes

Best-effort (default):
- Continue past extraction failures
- Mark doc status as `error`
- Save error detail in doc record and report

Strict (`--strict`):
- Abort on first extraction failure
- Print exact file and failure reason
- Exit non-zero

### Reporting

`init-corpus` completion output should include:
- total files scanned
- total files considered after ignore filters
- loaded/skipped/error counts
- counts by format
- top error file paths with short reasons
- total corpus chars

`status` should include corpus metrics when corpus mode is active.

## REPL Compatibility

Preserve existing helper signatures where possible.

Compatibility mapping:
- `content` alias points to `corpus.full_text` in corpus mode
- `peek`, `grep`, `chunk_indices`, `write_chunks` continue to operate over `content`

Enhance `write_chunks` output with metadata sidecars or embedded metadata including:
- source `path`
- `chunk_index`
- corpus span (`start`, `end`)
- source span when derivable

This preserves existing prompt/workflow habits while improving traceability.

## Testing Strategy

Unit tests:
- ignore matching (`.rlmignore` + defaults)
- recursive discovery and deterministic ordering
- extension routing and parser selection
- strict vs best-effort branching

Extractor tests:
- valid fixtures for `txt/md/pdf/docx/odt`
- malformed fixtures per type
- missing dependency behavior

Integration tests:
- nested directory ingestion
- `init-corpus -> status -> grep -> write_chunks` end-to-end
- report correctness and non-zero behavior in strict failures

## Rollout Plan

Phase 1:
- Add `init-corpus` command and state support
- Keep existing `init` path untouched

Phase 2:
- Add `.rlmignore` and reporting improvements
- Add metadata-aware chunk outputs

Phase 3:
- Add optional extractor dependencies and diagnostics
- Stabilize tests and docs

## Risks And Mitigations

Risk: Large corpora can create oversized state files.
Mitigation: enforce `--max-files` and `--max-bytes-per-file`; document practical limits.

Risk: Parse quality varies by file type and source quality.
Mitigation: best-effort defaults, strict mode option, explicit extraction report.

Risk: Users expect code-intelligent behavior for source files.
Mitigation: keep defaults document-focused and clearly separate future code-specialized tool.

## Decision Log

Accepted decisions from this session:
- Unified corpus model selected
- Input source is a root directory with recursive subdirectory ingestion
- Ignore controls include defaults plus `.rlmignore` and optional `--ignore-file`
- Chunk metadata baseline: path + chunk span
- Mode support: best-effort default + strict option
- Optional third-party parsers are acceptable if FOSS
- Scope constrained to document-focused ingestion; code-specialized tooling deferred
