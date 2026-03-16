#!/usr/bin/env python3

# I want to give credit where credit is due; this is not my creation. I got it from this post Zero-Setup RLMs with Claude Code (https://www.youtube.com/watch?v=m6itCxJFqpo)

"""Persistent mini-REPL for RLM-style workflows in Claude Code.

This script provides a *stateful* Python environment across invocations by
saving a pickle file to disk. It is intentionally small and dependency-free.

Typical flow:
  1) Initialise context:
       python rlm_repl.py init path/to/context.txt
  2) Execute code repeatedly (state persists):
       python rlm_repl.py exec -c 'print(len(content))'
       python rlm_repl.py exec <<'PYCODE'
       # you can write multi-line code
       hits = grep('TODO')
       print(hits[:3])
       PYCODE

The script injects these variables into the exec environment:
  - context: dict with keys {path, loaded_at, content}
  - content: string alias for context['content']
  - buffers: list[str] for storing intermediate text results

It also injects helpers:
  - peek(start=0, end=1000) -> str
  - grep(pattern, max_matches=20, window=120, flags=0) -> list[dict]
  - chunk_indices(size=200000, overlap=0) -> list[(start,end)]
  - write_chunks(out_dir, size=200000, overlap=0, prefix='chunk') -> list[str]
  - add_buffer(text: str) -> None

Security note:
  This runs arbitrary Python via exec. Treat it like running code you wrote.
"""

from __future__ import annotations

import argparse
import fnmatch
import io
import json
import os
import pickle
import re
import subprocess
import sys
import textwrap
import time
import traceback
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any, Dict, List, Tuple


DEFAULT_STATE_PATH = Path(".claude/rlm_state/state.pkl")
DEFAULT_MAX_OUTPUT_CHARS = 8000
DEFAULT_INCLUDE_EXTS = {
    ".txt",
    ".md",
    ".markdown",
    ".adoc",
    ".rst",
    ".log",
    ".csv",
    ".json",
    ".yml",
    ".yaml",
    ".pdf",
    ".docx",
    ".odt",
}
DEFAULT_EXCLUDE_DIRS = {".git", "node_modules", "bin", "_archive"}
PLAIN_TEXT_EXTS = {
    ".txt",
    ".md",
    ".markdown",
    ".adoc",
    ".rst",
    ".log",
    ".csv",
    ".json",
    ".yml",
    ".yaml",
}


class RlmReplError(RuntimeError):
    pass


class UnsupportedFormatError(RuntimeError):
    pass


def _check_optional_dependencies() -> List[Dict[str, str]]:
    checks = [
        ("pypdf", "pypdf", "PDF parsing"),
        ("docx", "python-docx", "DOCX parsing"),
        ("odf", "odfpy", "ODT parsing"),
    ]
    results: List[Dict[str, str]] = []
    for module_name, package_name, purpose in checks:
        try:
            __import__(module_name)
            results.append(
                {
                    "module": module_name,
                    "package": package_name,
                    "purpose": purpose,
                    "status": "ok",
                    "detail": "installed",
                }
            )
        except Exception as e:
            results.append(
                {
                    "module": module_name,
                    "package": package_name,
                    "purpose": purpose,
                    "status": "missing",
                    "detail": str(e),
                }
            )
    return results


def _ensure_parent_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def _load_state(state_path: Path) -> Dict[str, Any]:
    if not state_path.exists():
        raise RlmReplError(
            f"No state found at {state_path}. Run: python rlm_repl.py init <context_path>"
        )
    with state_path.open("rb") as f:
        state = pickle.load(f)
    if not isinstance(state, dict):
        raise RlmReplError(f"Corrupt state file: {state_path}")
    return state


def _save_state(state: Dict[str, Any], state_path: Path) -> None:
    _ensure_parent_dir(state_path)
    tmp_path = state_path.with_suffix(state_path.suffix + ".tmp")
    with tmp_path.open("wb") as f:
        pickle.dump(state, f, protocol=pickle.HIGHEST_PROTOCOL)
    tmp_path.replace(state_path)


def _read_text_file(path: Path, max_bytes: int | None = None) -> str:
    if not path.exists():
        raise RlmReplError(f"Context file does not exist: {path}")
    data: bytes
    with path.open("rb") as f:
        data = f.read() if max_bytes is None else f.read(max_bytes)
    return data.decode("utf-8", errors="replace")


def _normalize_text(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")


def _truncate(s: str, max_chars: int) -> str:
    if max_chars <= 0:
        return ""
    if len(s) <= max_chars:
        return s
    return s[:max_chars] + f"\n... [truncated to {max_chars} chars] ...\n"


def _is_pickleable(value: Any) -> bool:
    try:
        pickle.dumps(value, protocol=pickle.HIGHEST_PROTOCOL)
        return True
    except Exception:
        return False


def _filter_pickleable(d: Dict[str, Any]) -> Tuple[Dict[str, Any], List[str]]:
    kept: Dict[str, Any] = {}
    dropped: List[str] = []
    for k, v in d.items():
        if _is_pickleable(v):
            kept[k] = v
        else:
            dropped.append(k)
    return kept, dropped


def _read_ignore_patterns(path: Path | None) -> List[str]:
    if path is None or not path.exists():
        return []
    patterns: List[str] = []
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        patterns.append(line)
    return patterns


def _match_pattern(rel_posix: str, is_dir: bool, pattern: str) -> bool:
    dir_only = pattern.endswith("/")
    core = pattern[:-1] if dir_only else pattern
    if not core:
        return False
    if dir_only and not is_dir:
        return False

    rel = rel_posix
    if rel.startswith("./"):
        rel = rel[2:]
    rel_parts = rel.split("/") if rel else []

    # Path-anchored-like match if pattern contains '/'.
    if "/" in core:
        if fnmatch.fnmatch(rel, core):
            return True
        if is_dir and fnmatch.fnmatch(rel + "/", core.rstrip("/") + "/"):
            return True
        return False

    # gitignore-like loose matching: any path segment can match.
    for part in rel_parts:
        if fnmatch.fnmatch(part, core):
            return True
    if rel_parts and fnmatch.fnmatch(rel_parts[-1], core):
        return True
    return False


def _is_ignored(rel_posix: str, is_dir: bool, patterns: List[str]) -> bool:
    ignored = False
    for pat in patterns:
        negated = pat.startswith("!")
        pattern = pat[1:] if negated else pat
        if not pattern:
            continue
        if _match_pattern(rel_posix, is_dir, pattern):
            ignored = not negated
    return ignored


def _parse_include_exts(value: str | None) -> set[str]:
    if not value:
        return set(DEFAULT_INCLUDE_EXTS)
    out: set[str] = set()
    for token in value.split(","):
        ext = token.strip().lower()
        if not ext:
            continue
        if not ext.startswith("."):
            ext = "." + ext
        out.add(ext)
    return out or set(DEFAULT_INCLUDE_EXTS)


def _discover_files(
    root: Path,
    include_exts: set[str],
    ignore_patterns: List[str],
    max_files: int | None,
) -> tuple[List[Path], Dict[str, Any]]:
    if not root.exists() or not root.is_dir():
        raise RlmReplError(f"Corpus root must be an existing directory: {root}")

    selected: List[Path] = []
    scanned_files = 0
    considered_files = 0

    for dirpath, dirnames, filenames in os.walk(root, topdown=True):
        base = Path(dirpath)

        kept_dirs: List[str] = []
        for d in sorted(dirnames):
            rel = (base / d).relative_to(root).as_posix()
            if d in DEFAULT_EXCLUDE_DIRS:
                continue
            if _is_ignored(rel, is_dir=True, patterns=ignore_patterns):
                continue
            kept_dirs.append(d)
        dirnames[:] = kept_dirs

        for fname in sorted(filenames):
            scanned_files += 1
            path = base / fname
            rel = path.relative_to(root).as_posix()
            if _is_ignored(rel, is_dir=False, patterns=ignore_patterns):
                continue
            considered_files += 1

            ext = path.suffix.lower()
            if ext not in include_exts:
                continue

            selected.append(path)
            if max_files is not None and len(selected) > max_files:
                raise RlmReplError(
                    f"Discovered {len(selected)} files, exceeding --max-files={max_files}"
                )

    report = {
        "scanned_files": scanned_files,
        "considered_files": considered_files,
        "selected_files": len(selected),
    }
    return selected, report


def _extract_text(path: Path, ext: str) -> str:
    if ext in PLAIN_TEXT_EXTS:
        return _read_text_file(path)

    if ext == ".pdf":
        try:
            from pypdf import PdfReader  # type: ignore
        except ImportError as e:
            raise RlmReplError(
                "Missing optional dependency for PDF parsing: pypdf"
            ) from e
        reader = PdfReader(str(path))
        chunks: List[str] = []
        for page in reader.pages:
            chunks.append(page.extract_text() or "")
        return "\n".join(chunks)

    if ext == ".docx":
        try:
            from docx import Document  # type: ignore
        except ImportError as e:
            raise RlmReplError(
                "Missing optional dependency for DOCX parsing: python-docx"
            ) from e
        doc = Document(str(path))
        return "\n".join(p.text for p in doc.paragraphs)

    if ext == ".odt":
        try:
            from odf import teletype  # type: ignore
            from odf import text as odf_text  # type: ignore
            from odf.opendocument import load as odf_load  # type: ignore
        except ImportError as e:
            raise RlmReplError(
                "Missing optional dependency for ODT parsing: odfpy"
            ) from e
        doc = odf_load(str(path))
        paras = doc.getElementsByType(odf_text.P)
        return "\n".join(teletype.extractText(p) for p in paras)

    raise UnsupportedFormatError(f"Unsupported extension: {ext}")


def _build_corpus(
    root: Path,
    files: List[Path],
    strict: bool,
    max_bytes_per_file: int | None,
) -> tuple[Dict[str, Any], Dict[str, Any]]:
    docs: List[Dict[str, Any]] = []
    index: List[Dict[str, Any]] = []
    full_text_parts: List[str] = []

    loaded = 0
    skipped = 0
    errors = 0
    format_counts: Dict[str, int] = {}
    cursor = 0

    for path in files:
        rel = path.relative_to(root).as_posix()
        ext = path.suffix.lower()
        fmt = ext[1:] if ext.startswith(".") else ext

        record: Dict[str, Any] = {
            "path": rel,
            "format": fmt,
            "text": "",
            "status": "loaded",
            "error": None,
        }

        try:
            if max_bytes_per_file is not None:
                size = path.stat().st_size
                if size > max_bytes_per_file:
                    raise RlmReplError(
                        f"File exceeds --max-bytes-per-file={max_bytes_per_file}: {rel} ({size} bytes)"
                    )

            text = _normalize_text(_extract_text(path, ext))
            record["text"] = text
            docs.append(record)

            if full_text_parts:
                full_text_parts.append("\n\n")
                cursor += 2

            start = cursor
            full_text_parts.append(text)
            cursor += len(text)
            end = cursor

            index.append(
                {
                    "path": rel,
                    "doc_index": len(docs) - 1,
                    "corpus_start": start,
                    "corpus_end": end,
                    "doc_char_start": 0,
                    "doc_char_end": len(text),
                }
            )

            loaded += 1
            format_counts[fmt] = format_counts.get(fmt, 0) + 1

        except UnsupportedFormatError:
            record["status"] = "skipped"
            skipped += 1
            docs.append(record)
        except Exception as e:
            record["status"] = "error"
            record["error"] = str(e)
            errors += 1
            docs.append(record)
            if strict:
                raise RlmReplError(f"Strict mode failed on {rel}: {e}") from e

    full_text = "".join(full_text_parts)
    corpus = {
        "root": str(root),
        "docs": docs,
        "full_text": full_text,
        "index": index,
    }
    report = {
        "loaded": loaded,
        "skipped": skipped,
        "errors": errors,
        "formats": format_counts,
        "total_chars": len(full_text),
    }
    return corpus, report


def _corpus_sources_for_span(
    corpus_index: List[Dict[str, Any]], start: int, end: int
) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for entry in corpus_index:
        e_start = int(entry.get("corpus_start", 0))
        e_end = int(entry.get("corpus_end", 0))
        if e_end <= start or e_start >= end:
            continue

        overlap_start = max(start, e_start)
        overlap_end = min(end, e_end)
        source_start = overlap_start - e_start + int(entry.get("doc_char_start", 0))
        source_end = overlap_end - e_start + int(entry.get("doc_char_start", 0))

        out.append(
            {
                "path": entry.get("path"),
                "corpus_start": overlap_start,
                "corpus_end": overlap_end,
                "source_start": source_start,
                "source_end": source_end,
            }
        )
    return out


def _make_helpers(
    context_ref: Dict[str, Any],
    buffers_ref: List[str],
    corpus_index_ref: List[Dict[str, Any]] | None,
):
    # These close over context_ref/buffers_ref so changes persist.
    def peek(start: int = 0, end: int = 1000) -> str:
        content = context_ref.get("content", "")
        return content[start:end]

    def grep(
        pattern: str,
        max_matches: int = 20,
        window: int = 120,
        flags: int = 0,
    ) -> List[Dict[str, Any]]:
        content = context_ref.get("content", "")
        out: List[Dict[str, Any]] = []
        for m in re.finditer(pattern, content, flags):
            start, end = m.span()
            snippet_start = max(0, start - window)
            snippet_end = min(len(content), end + window)
            hit: Dict[str, Any] = {
                "match": m.group(0),
                "span": (start, end),
                "snippet": content[snippet_start:snippet_end],
            }
            if corpus_index_ref:
                hit["sources"] = _corpus_sources_for_span(corpus_index_ref, start, end)
            out.append(hit)
            if len(out) >= max_matches:
                break
        return out

    def chunk_indices(size: int = 200_000, overlap: int = 0) -> List[Tuple[int, int]]:
        if size <= 0:
            raise ValueError("size must be > 0")
        if overlap < 0:
            raise ValueError("overlap must be >= 0")
        if overlap >= size:
            raise ValueError("overlap must be < size")

        content = context_ref.get("content", "")
        n = len(content)
        spans: List[Tuple[int, int]] = []
        step = size - overlap
        for start in range(0, n, step):
            end = min(n, start + size)
            spans.append((start, end))
            if end >= n:
                break
        return spans

    def write_chunks(
        out_dir: str | os.PathLike,
        size: int = 200_000,
        overlap: int = 0,
        prefix: str = "chunk",
        encoding: str = "utf-8",
    ) -> List[str]:
        content = context_ref.get("content", "")
        spans = chunk_indices(size=size, overlap=overlap)
        out_path = Path(out_dir)
        out_path.mkdir(parents=True, exist_ok=True)
        paths: List[str] = []
        for i, (s, e) in enumerate(spans):
            p = out_path / f"{prefix}_{i:04d}.txt"
            p.write_text(content[s:e], encoding=encoding)
            paths.append(str(p))

            if corpus_index_ref:
                meta = {
                    "chunk_index": i,
                    "corpus_start": s,
                    "corpus_end": e,
                    "sources": _corpus_sources_for_span(corpus_index_ref, s, e),
                }
                meta_path = p.with_suffix(p.suffix + ".meta.json")
                meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
        return paths

    def add_buffer(text: str) -> None:
        buffers_ref.append(str(text))

    return {
        "peek": peek,
        "grep": grep,
        "chunk_indices": chunk_indices,
        "write_chunks": write_chunks,
        "add_buffer": add_buffer,
    }


def cmd_init(args: argparse.Namespace) -> int:
    state_path = Path(args.state)
    ctx_path = Path(args.context)

    content = _normalize_text(_read_text_file(ctx_path, max_bytes=args.max_bytes))
    state: Dict[str, Any] = {
        "version": 2,
        "context": {
            "path": str(ctx_path),
            "loaded_at": time.time(),
            "content": content,
            "mode": "single",
        },
        "corpus": None,
        "buffers": [],
        "globals": {},
    }
    _save_state(state, state_path)

    print(f"Initialised RLM REPL state at: {state_path}")
    print(f"Loaded context: {ctx_path} ({len(content):,} chars)")
    return 0


def cmd_init_corpus(args: argparse.Namespace) -> int:
    state_path = Path(args.state)
    root = Path(args.root).resolve()

    include_exts = _parse_include_exts(args.include_ext)
    ignore_file = Path(args.ignore_file) if args.ignore_file else (root / ".rlmignore")
    ignore_patterns = _read_ignore_patterns(ignore_file)

    files, discovery_report = _discover_files(
        root=root,
        include_exts=include_exts,
        ignore_patterns=ignore_patterns,
        max_files=args.max_files,
    )

    corpus, ingest_report = _build_corpus(
        root=root,
        files=files,
        strict=args.strict,
        max_bytes_per_file=args.max_bytes_per_file,
    )

    state: Dict[str, Any] = {
        "version": 2,
        "context": {
            "path": str(root),
            "loaded_at": time.time(),
            "content": corpus["full_text"],
            "mode": "corpus",
        },
        "corpus": {
            **corpus,
            "report": {
                **discovery_report,
                **ingest_report,
            },
        },
        "buffers": [],
        "globals": {},
    }
    _save_state(state, state_path)

    report = state["corpus"]["report"]
    print(f"Initialised RLM REPL corpus state at: {state_path}")
    print(f"Corpus root: {root}")
    print(f"Files scanned: {report['scanned_files']}")
    print(f"Files considered: {report['considered_files']}")
    print(f"Files selected: {report['selected_files']}")
    print(f"Loaded: {report['loaded']}, skipped: {report['skipped']}, errors: {report['errors']}")
    print(f"Total corpus chars: {report['total_chars']:,}")
    if report["formats"]:
        print("Loaded by format:")
        for fmt in sorted(report["formats"].keys()):
            print(f"  - {fmt}: {report['formats'][fmt]}")

    if report["errors"]:
        print("Top errors:")
        shown = 0
        for doc in corpus["docs"]:
            if doc.get("status") == "error":
                print(f"  - {doc.get('path')}: {doc.get('error')}")
                shown += 1
                if shown >= 5:
                    break

    return 0


def cmd_status(args: argparse.Namespace) -> int:
    state = _load_state(Path(args.state))
    ctx = state.get("context", {})
    content = ctx.get("content", "")
    buffers = state.get("buffers", [])
    g = state.get("globals", {})

    print("RLM REPL status")
    print(f"  State file: {args.state}")
    print(f"  Mode: {ctx.get('mode', 'single')}")
    print(f"  Context path: {ctx.get('path')}")
    print(f"  Context chars: {len(content):,}")

    corpus = state.get("corpus")
    if isinstance(corpus, dict):
        report = corpus.get("report", {})
        print(f"  Corpus root: {corpus.get('root')}")
        print(f"  Corpus docs: {len(corpus.get('docs', []))}")
        print(f"  Corpus index entries: {len(corpus.get('index', []))}")
        if isinstance(report, dict) and report:
            print(
                "  Corpus loaded/skipped/errors: "
                f"{report.get('loaded', 0)}/{report.get('skipped', 0)}/{report.get('errors', 0)}"
            )

    print(f"  Buffers: {len(buffers)}")
    print(f"  Persisted vars: {len(g)}")
    if args.show_vars and g:
        for k in sorted(g.keys()):
            print(f"    - {k}")
    return 0


def cmd_reset(args: argparse.Namespace) -> int:
    state_path = Path(args.state)
    if state_path.exists():
        state_path.unlink()
        print(f"Deleted state: {state_path}")
    else:
        print(f"No state to delete at: {state_path}")
    return 0


def cmd_export_buffers(args: argparse.Namespace) -> int:
    state = _load_state(Path(args.state))
    buffers = state.get("buffers", [])
    out_path = Path(args.out)
    _ensure_parent_dir(out_path)
    out_path.write_text("\n\n".join(str(b) for b in buffers), encoding="utf-8")
    print(f"Wrote {len(buffers)} buffers to: {out_path}")
    return 0


def cmd_check_deps(args: argparse.Namespace) -> int:
    results = _check_optional_dependencies()
    print("RLM optional dependency check")
    missing = 0
    for item in results:
        marker = "OK" if item["status"] == "ok" else "MISSING"
        print(
            f"  [{marker}] {item['package']} ({item['module']}): {item['purpose']}"
        )
        if item["status"] != "ok":
            missing += 1
            print(f"         detail: {item['detail']}")

    if missing:
        packages = " ".join(item["package"] for item in results if item["status"] != "ok")
        print("")
        print("Install missing packages with:")
        print(f"  python3 -m pip install --user {packages}")
        return 1

    return 0


def cmd_install_deps(args: argparse.Namespace) -> int:
    checks = _check_optional_dependencies()
    if args.all:
        packages = [item["package"] for item in checks]
    else:
        packages = [item["package"] for item in checks if item["status"] != "ok"]

    if not packages:
        print("All optional parser dependencies are already installed.")
        return 0

    cmd = [sys.executable, "-m", "pip", "install"]
    if args.user:
        cmd.append("--user")
    cmd.extend(packages)

    print("Installing optional parser dependencies:")
    print("  " + " ".join(cmd))
    if args.dry_run:
        print("Dry run only; no changes made.")
        return 0

    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.stdout:
        sys.stdout.write(proc.stdout)
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    if proc.returncode != 0:
        print(
            "Dependency installation failed. You can re-run with --dry-run to inspect the command.",
            file=sys.stderr,
        )
    return int(proc.returncode)


def cmd_exec(args: argparse.Namespace) -> int:
    state_path = Path(args.state)
    state = _load_state(state_path)

    ctx = state.get("context")
    if not isinstance(ctx, dict):
        raise RlmReplError("State is missing a valid 'context'. Re-run init.")

    corpus = state.get("corpus")
    if isinstance(corpus, dict):
        # Keep compatibility with existing workflows that expect `content`.
        ctx["content"] = str(corpus.get("full_text", ctx.get("content", "")))

    if "content" not in ctx:
        raise RlmReplError("State is missing a valid 'context.content'. Re-run init.")

    buffers = state.setdefault("buffers", [])
    if not isinstance(buffers, list):
        buffers = []
        state["buffers"] = buffers

    persisted = state.setdefault("globals", {})
    if not isinstance(persisted, dict):
        persisted = {}
        state["globals"] = persisted

    code = args.code
    if code is None:
        code = sys.stdin.read()

    # Build execution environment.
    # Start from persisted variables, then inject context, buffers and helpers.
    env: Dict[str, Any] = dict(persisted)
    env["context"] = ctx
    env["content"] = ctx.get("content", "")
    env["buffers"] = buffers

    corpus_index = None
    if isinstance(corpus, dict):
        idx = corpus.get("index")
        if isinstance(idx, list):
            corpus_index = idx

    helpers = _make_helpers(ctx, buffers, corpus_index)
    env.update(helpers)

    # Capture output.
    stdout_buf = io.StringIO()
    stderr_buf = io.StringIO()

    try:
        with redirect_stdout(stdout_buf), redirect_stderr(stderr_buf):
            exec(code, env, env)
    except Exception:
        traceback.print_exc(file=stderr_buf)

    # Pull back possibly mutated context/buffers.
    maybe_ctx = env.get("context")
    if isinstance(maybe_ctx, dict) and "content" in maybe_ctx:
        state["context"] = maybe_ctx

    maybe_buffers = env.get("buffers")
    if isinstance(maybe_buffers, list):
        state["buffers"] = maybe_buffers

    # Persist any new variables, excluding injected keys.
    injected_keys = {
        "__builtins__",
        "context",
        "content",
        "buffers",
        *helpers.keys(),
    }
    to_persist = {k: v for k, v in env.items() if k not in injected_keys}
    filtered, dropped = _filter_pickleable(to_persist)
    state["globals"] = filtered

    _save_state(state, state_path)

    out = stdout_buf.getvalue()
    err = stderr_buf.getvalue()

    if dropped and args.warn_unpickleable:
        msg = "Dropped unpickleable variables: " + ", ".join(dropped)
        err = (err + ("\n" if err else "") + msg + "\n")

    if out:
        sys.stdout.write(_truncate(out, args.max_output_chars))

    if err:
        sys.stderr.write(_truncate(err, args.max_output_chars))

    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="rlm_repl",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent(
            """\
            Persistent mini-REPL for RLM-style workflows.

            Examples:
              python rlm_repl.py init context.txt
              python rlm_repl.py init-corpus ./docs
              python rlm_repl.py status
              python rlm_repl.py exec -c "print(len(content))"
              python rlm_repl.py exec <<'PY'
              print(peek(0, 2000))
              PY
            """
        ),
    )
    p.add_argument(
        "--state",
        default=str(DEFAULT_STATE_PATH),
        help=f"Path to state pickle (default: {DEFAULT_STATE_PATH})",
    )

    sub = p.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init", help="Initialise state from a context file")
    p_init.add_argument("context", help="Path to the context file")
    p_init.add_argument(
        "--max-bytes",
        type=int,
        default=None,
        help="Optional cap on bytes read from the context file",
    )
    p_init.set_defaults(func=cmd_init)

    p_init_corpus = sub.add_parser(
        "init-corpus", help="Initialise state from a recursively discovered document corpus"
    )
    p_init_corpus.add_argument("root", help="Root directory containing documents")
    p_init_corpus.add_argument(
        "--ignore-file",
        default=None,
        help="Path to ignore file (defaults to <root>/.rlmignore if present)",
    )
    p_init_corpus.add_argument(
        "--strict",
        action="store_true",
        help="Fail on first extraction error",
    )
    p_init_corpus.add_argument(
        "--include-ext",
        default=None,
        help="Comma-separated extension list (default: document-focused set)",
    )
    p_init_corpus.add_argument(
        "--max-files",
        type=int,
        default=None,
        help="Optional cap on discovered files",
    )
    p_init_corpus.add_argument(
        "--max-bytes-per-file",
        type=int,
        default=None,
        help="Optional cap on input file size in bytes",
    )
    p_init_corpus.set_defaults(func=cmd_init_corpus)

    p_status = sub.add_parser("status", help="Show current state summary")
    p_status.add_argument(
        "--show-vars", action="store_true", help="List persisted variable names"
    )
    p_status.set_defaults(func=cmd_status)

    p_reset = sub.add_parser("reset", help="Delete the current state file")
    p_reset.set_defaults(func=cmd_reset)

    p_export = sub.add_parser(
        "export-buffers", help="Export buffers list to a text file"
    )
    p_export.add_argument("out", help="Output file path")
    p_export.set_defaults(func=cmd_export_buffers)

    p_check = sub.add_parser(
        "check-deps",
        help="Check optional parser dependencies for pdf/docx/odt support",
    )
    p_check.set_defaults(func=cmd_check_deps)

    p_install = sub.add_parser(
        "install-deps",
        help="Install optional parser dependencies for pdf/docx/odt support",
    )
    p_install.add_argument(
        "--all",
        action="store_true",
        help="Install all optional parser dependencies, not just missing ones",
    )
    p_install.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the install command without executing it",
    )
    p_install.add_argument(
        "--no-user",
        action="store_false",
        dest="user",
        help="Install without --user (use environment/system default)",
    )
    p_install.set_defaults(func=cmd_install_deps, user=True)

    p_exec = sub.add_parser("exec", help="Execute Python code with persisted state")
    p_exec.add_argument(
        "-c",
        "--code",
        default=None,
        help="Inline code string. If omitted, reads code from stdin.",
    )
    p_exec.add_argument(
        "--max-output-chars",
        type=int,
        default=DEFAULT_MAX_OUTPUT_CHARS,
        help=f"Truncate stdout/stderr to this many characters (default: {DEFAULT_MAX_OUTPUT_CHARS})",
    )
    p_exec.add_argument(
        "--warn-unpickleable",
        action="store_true",
        help="Warn on stderr when variables could not be persisted",
    )
    p_exec.set_defaults(func=cmd_exec)

    return p


def main(argv: List[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        return int(args.func(args))
    except RlmReplError as e:
        sys.stderr.write(f"ERROR: {e}\n")
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
