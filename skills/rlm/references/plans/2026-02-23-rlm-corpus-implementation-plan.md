# RLM Corpus Implementation Plan (Document-Focused)

Date: 2026-02-23
Status: Ready for execution
Depends on: `docs/plans/2026-02-23-rlm-corpus-design.md`

## Objective

Implement corpus-based document ingestion for `scripts/rlm_repl.py` while preserving backward compatibility with existing single-file flows.

## Scope Guardrails

In scope:
- Single root directory ingestion (recursive)
- `.rlmignore` support + default excludes
- Best-effort default + optional `--strict`
- Metadata-aware chunk output
- Optional FOSS extractors (`pypdf`, `python-docx`, `odfpy`)

Out of scope:
- Multi-root ingestion
- Code-intelligence features (AST, symbol graph, semantic refactors)

## Deliverables

1. `init-corpus` command in `scripts/rlm_repl.py`
2. Corpus-aware state model and status reporting
3. Ignore/filter pipeline with `.rlmignore`
4. Extractor abstraction for text/pdf/docx/odt
5. Best-effort/strict execution modes
6. Metadata-aware `write_chunks`
7. Tests and fixtures
8. Updated skill docs (`SKILL.md`) with new usage examples

## Implementation Sequence

### Phase 1: Corpus State And Command Skeleton

Goal:
- Add `init-corpus <root_dir>` and persist corpus state without breaking `init`.

Tasks:
1. Extend CLI parser with `init-corpus` and flags:
   - `--ignore-file`
   - `--strict`
   - `--include-ext`
   - `--max-files`
   - `--max-bytes-per-file`
2. Add corpus state schema:
   - `corpus.root`
   - `corpus.docs`
   - `corpus.full_text`
   - `corpus.index`
   - `corpus.report`
3. Keep legacy fields for compatibility:
   - set `content` alias to corpus full text in `exec`
4. Extend `status` to report corpus metrics when corpus mode is active.

Acceptance criteria:
- Existing `init` and `exec` behavior remains functional.
- `init-corpus` can initialize from a directory and persist valid state.
- `status` clearly distinguishes single-file vs corpus mode.

### Phase 2: Discovery, Ignore Rules, And File Limits

Goal:
- Deterministic recursive discovery with ignore controls and safety caps.

Tasks:
1. Implement recursive file discovery (sorted deterministic order).
2. Add built-in excludes:
   - `.git/`, `node_modules/`, `bin/`, `_archive/`
3. Add `.rlmignore` loading from corpus root.
4. Add `--ignore-file` override.
5. Enforce `--max-files` and `--max-bytes-per-file`.
6. Add extension include filtering from `--include-ext` with document-focused defaults.

Acceptance criteria:
- Ignored paths are excluded reliably, including nested paths.
- Discovery order is stable across runs.
- Limit violations produce clear, actionable errors.

### Phase 3: Extractor Layer And Modes

Goal:
- Parse supported formats with robust error handling.

Tasks:
1. Add extractor registry keyed by extension/format.
2. Implement baseline text extraction for plain text docs.
3. Add optional extractors:
   - PDF via `pypdf`
   - DOCX via `python-docx`
   - ODT via `odfpy`
4. Implement best-effort mode (default): continue on per-file errors.
5. Implement strict mode: fail-fast on first extraction error.
6. Normalize extracted text (newline normalization, UTF-8 replacement fallback).

Acceptance criteria:
- Supported text files ingest without regressions.
- Missing optional dependencies yield clear diagnostics.
- Best-effort and strict produce expected exit behavior.

### Phase 4: Corpus Indexing And Chunk Metadata

Goal:
- Preserve existing chunk workflow while adding source traceability.

Tasks:
1. Build `corpus.full_text` by concatenating loaded docs.
2. Build `corpus.index` mapping corpus spans to file paths.
3. Update `write_chunks` to output chunk metadata including:
   - `path`
   - `chunk_index`
   - `corpus_start`, `corpus_end`
   - source span when derivable
4. Keep existing `write_chunks` return behavior stable (list of chunk paths).

Acceptance criteria:
- `grep/peek/chunk_indices/write_chunks` continue working in corpus mode.
- Chunk metadata allows path-level attribution for every chunk.

### Phase 5: Reporting, Docs, And Final Hardening

Goal:
- Make ingestion observable and user-facing docs complete.

Tasks:
1. Add ingestion summary output to `init-corpus`:
   - scanned count
   - considered count
   - loaded/skipped/error counts
   - counts by format
   - total corpus chars
2. Add concise error summaries (top failing paths).
3. Update `SKILL.md` examples for directory corpus usage.
4. Document dependency installation for optional extractors.

Acceptance criteria:
- Users can diagnose ingestion outcomes from CLI output alone.
- Skill docs accurately show new invocation and behavior.

## Test Plan

Unit tests:
- discovery ordering and recursion
- ignore matching (`.rlmignore` + defaults)
- include-ext filtering
- strict vs best-effort control flow
- corpus index span correctness

Extractor tests:
- fixture success for txt/md/pdf/docx/odt
- malformed/corrupt fixture failures
- missing dependency diagnostics

Integration tests:
- end-to-end `init-corpus -> status -> exec(grep) -> write_chunks`
- nested directories with ignored subtrees
- strict mode non-zero exit verification

Regression checks:
- legacy `init <context_file>` flow unchanged
- existing helper signatures preserved

## Suggested Work Breakdown

1. Data model + parser changes (Phase 1)
2. Discovery/ignore pipeline (Phase 2)
3. Extractors + mode handling (Phase 3)
4. Index + chunk metadata (Phase 4)
5. Reporting/docs/tests completion (Phase 5)

## Risks And Mitigations

Risk: Large corpus can bloat state pickle.
Mitigation: enforce file and byte caps; document guidance for splitting corpora.

Risk: Format extraction inconsistency.
Mitigation: explicit per-format status and clear error reporting.

Risk: Backward compatibility break.
Mitigation: keep legacy command path untouched; run regression checks each phase.

## Definition Of Done

All are true:
1. `init-corpus` works on nested document trees with `.rlmignore`.
2. Best-effort and strict modes behave as specified.
3. Optional extractor dependencies are detected and reported cleanly.
4. Chunk outputs include required metadata for source attribution.
5. Existing single-file workflows continue to run unchanged.
6. Tests cover core logic and pass locally.
