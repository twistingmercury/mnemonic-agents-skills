import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "rlm_repl.py"


def run_cmd(args, cwd=None):
    return subprocess.run(
        ["python3", str(SCRIPT), *args],
        cwd=str(cwd or REPO_ROOT),
        text=True,
        capture_output=True,
    )


class RlmReplTests(unittest.TestCase):
    def test_install_deps_dry_run(self):
        out = run_cmd(["install-deps", "--all", "--dry-run"])
        self.assertEqual(out.returncode, 0, msg=out.stderr)
        self.assertIn("Installing optional parser dependencies:", out.stdout)
        self.assertIn("-m pip install", out.stdout)
        self.assertIn("pypdf", out.stdout)
        self.assertIn("python-docx", out.stdout)
        self.assertIn("odfpy", out.stdout)
        self.assertIn("Dry run only; no changes made.", out.stdout)

    def test_check_deps_command(self):
        out = run_cmd(["check-deps"])
        self.assertIn("RLM optional dependency check", out.stdout)
        self.assertIn("pypdf", out.stdout)
        self.assertIn("python-docx", out.stdout)
        self.assertIn("odfpy", out.stdout)
        self.assertIn(out.returncode, (0, 1))

    def test_single_file_flow_regression(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            state = root / "state.pkl"
            ctx = root / "context.txt"
            ctx.write_text("hello\nTODO: verify\n", encoding="utf-8")

            init = run_cmd(["--state", str(state), "init", str(ctx)])
            self.assertEqual(init.returncode, 0, msg=init.stderr)

            status = run_cmd(["--state", str(state), "status"])
            self.assertEqual(status.returncode, 0, msg=status.stderr)
            self.assertIn("Mode: single", status.stdout)

            q1 = run_cmd(["--state", str(state), "exec", "-c", "print(len(content))"])
            self.assertEqual(q1.returncode, 0, msg=q1.stderr)
            self.assertIn("19", q1.stdout)

            q2 = run_cmd(
                [
                    "--state",
                    str(state),
                    "exec",
                    "-c",
                    "print(grep('TODO', max_matches=1)[0]['match'])",
                ]
            )
            self.assertEqual(q2.returncode, 0, msg=q2.stderr)
            self.assertIn("TODO", q2.stdout)

    def test_init_corpus_recursive_and_ignore(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            docs = root / "docs"
            (docs / "architecture").mkdir(parents=True)
            (docs / "architecture" / "observability.md").write_text(
                "OBS_MARKER", encoding="utf-8"
            )
            (docs / "architecture" / "security.txt").write_text(
                "SEC_MARKER", encoding="utf-8"
            )

            (docs / "_archive").mkdir(parents=True)
            (docs / "_archive" / "old.txt").write_text(
                "ARCHIVE_MARKER", encoding="utf-8"
            )

            (docs / "bin").mkdir(parents=True)
            (docs / "bin" / "tool.txt").write_text("BIN_MARKER", encoding="utf-8")

            (docs / "architecture" / "ignored.md").write_text(
                "SHOULD_NOT_APPEAR", encoding="utf-8"
            )
            (docs / ".rlmignore").write_text("architecture/ignored.md\n", encoding="utf-8")

            state = root / "state.pkl"
            init = run_cmd(["--state", str(state), "init-corpus", str(docs)])
            self.assertEqual(init.returncode, 0, msg=init.stderr)

            status = run_cmd(["--state", str(state), "status"])
            self.assertEqual(status.returncode, 0, msg=status.stderr)
            self.assertIn("Mode: corpus", status.stdout)

            contains_obs = run_cmd(
                ["--state", str(state), "exec", "-c", "print('OBS_MARKER' in content)"]
            )
            self.assertEqual(contains_obs.returncode, 0, msg=contains_obs.stderr)
            self.assertIn("True", contains_obs.stdout)

            contains_ignored = run_cmd(
                [
                    "--state",
                    str(state),
                    "exec",
                    "-c",
                    "print('SHOULD_NOT_APPEAR' in content)",
                ]
            )
            self.assertEqual(contains_ignored.returncode, 0, msg=contains_ignored.stderr)
            self.assertIn("False", contains_ignored.stdout)

            contains_bin = run_cmd(
                ["--state", str(state), "exec", "-c", "print('BIN_MARKER' in content)"]
            )
            self.assertEqual(contains_bin.returncode, 0, msg=contains_bin.stderr)
            self.assertIn("False", contains_bin.stdout)

            contains_archive = run_cmd(
                [
                    "--state",
                    str(state),
                    "exec",
                    "-c",
                    "print('ARCHIVE_MARKER' in content)",
                ]
            )
            self.assertEqual(contains_archive.returncode, 0, msg=contains_archive.stderr)
            self.assertIn("False", contains_archive.stdout)

    def test_write_chunks_emits_metadata_in_corpus_mode(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            docs = root / "docs"
            docs.mkdir(parents=True)
            (docs / "a.md").write_text("alpha\nbeta\ngamma\n", encoding="utf-8")

            state = root / "state.pkl"
            chunks_dir = root / "chunks"

            init = run_cmd(["--state", str(state), "init-corpus", str(docs)])
            self.assertEqual(init.returncode, 0, msg=init.stderr)

            write = run_cmd(
                [
                    "--state",
                    str(state),
                    "exec",
                    "-c",
                    f"print(write_chunks({str(chunks_dir)!r}, size=5, overlap=0))",
                ]
            )
            self.assertEqual(write.returncode, 0, msg=write.stderr)

            chunk_file = chunks_dir / "chunk_0000.txt"
            meta_file = chunks_dir / "chunk_0000.txt.meta.json"
            self.assertTrue(chunk_file.exists())
            self.assertTrue(meta_file.exists())

            meta = json.loads(meta_file.read_text(encoding="utf-8"))
            self.assertIn("sources", meta)
            self.assertTrue(meta["sources"])
            self.assertEqual(meta["sources"][0]["path"], "a.md")

    def test_strict_mode_fails_on_parse_error(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            docs = root / "docs"
            docs.mkdir(parents=True)
            (docs / "ok.txt").write_text("good", encoding="utf-8")
            (docs / "bad.pdf").write_bytes(b"not-a-real-pdf")

            state_best = root / "state_best.pkl"
            best = run_cmd(["--state", str(state_best), "init-corpus", str(docs)])
            self.assertEqual(best.returncode, 0, msg=best.stderr)
            self.assertIn("errors:", best.stdout)

            state_strict = root / "state_strict.pkl"
            strict = run_cmd(
                ["--state", str(state_strict), "init-corpus", str(docs), "--strict"]
            )
            self.assertNotEqual(strict.returncode, 0)
            self.assertIn("Strict mode failed", strict.stderr)


if __name__ == "__main__":
    unittest.main()
