"""Pure regressions for host-gate timeout accounting and asset identity.

Starts no process and runs no SDK. Temp directories only.
"""
from concurrent.futures import ThreadPoolExecutor
import threading
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "tool/run_dart_host_gate.py"
SPEC = importlib.util.spec_from_file_location("dart_host_gate", MODULE_PATH)
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)



def _write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _make_repo(root):
    """A tiny valid repo for build_identity, with no tools required."""
    core = root / "core"
    re_editor = root / "re_editor"
    _write(root / "pubspec.yaml", "name: qfli_dart\n")
    _write(root / "pubspec.lock", "packages: {}\n")
    _write(root / "analysis_options.yaml", "analyzer:\n  errors: {}\n")
    _write(root / ".flutter-plugins-dependencies", '{"plugins": {}}\n')
    _write(root / "lib" / "main.dart", "void main() {}\n")
    _write(root / "assets" / "app_icon.png", "icon-v1")
    _write(root / "assets" / "content" / "dart_tutorials.json", '{"version": 1}\n')
    _write(root / "tool" / "verify_b_draft_exercises.dart", "void main() {}\n")
    _write(core / "lib" / "core.dart", "class Core {}\n")
    _write(core / "pubspec.yaml", "name: qfli_studio_core\n")
    _write(core / "pubspec.lock", "packages: {}\n")
    _write(core / ".dart_tool" / "package_config.json", '{"packages": []}\n')
    _write(re_editor / "lib" / "re_editor.dart", "class Editor {}\n")
    _write(re_editor / "pubspec.yaml", "name: re_editor\n")
    config = {
        "configVersion": 2,
        "packages": [
            {"name": "qfli_studio_core", "rootUri": core.resolve().as_uri()},
            {"name": "re_editor", "rootUri": re_editor.resolve().as_uri()},
        ],
    }
    _write(root / ".dart_tool" / "package_config.json", json.dumps(config))
    return root


class FakeProcess:
    def __init__(self):
        self.code = None

    def poll(self):
        return self.code

    def wait(self, timeout):
        return self.code


class FakeJob:
    last = None

    def __init__(self):
        type(self).last = self
        self.handle = 123
        self.proc = FakeProcess()
        self.terminations = 0

    def launch(self, command, cwd, log, record):
        record.update(pid=42, processHandle="456", rootIdentityVerified=True)
        return self.proc

    def state(self):
        return {"activeProcesses": int(self.proc.code is None)}

    def terminate(self):
        self.terminations += 1
        self.proc.code = 124

    def confirm_terminal(self, record):
        record.update(rootTerminal=self.proc.poll() is not None,
                      terminalConfirmed=self.proc.poll() is not None,
                      treeFinal=self.state())


class TimeoutAccountingTest(unittest.TestCase):
    def test_deadline_cleanup_records_forced_tree_termination(self):
        report = {"phases": []}
        with tempfile.TemporaryDirectory(prefix="qfli_gate_timeout_") as temp:
            with patch.object(gate, "OwnedJob", FakeJob):
                # First call permits launch; second reaches the phase deadline.
                with patch.object(gate.time, "time", side_effect=[0.0, 2.0]):
                    with self.assertRaisesRegex(RuntimeError, "timed out"):
                        gate.run_phase("timeout", ["unused"], Path(temp),
                                       Path(temp), 1.0, report)
        record = report["phases"][0]
        self.assertEqual(FakeJob.last.terminations, 1)
        self.assertEqual(record["exitCode"], 124)
        self.assertTrue(record["timedOut"])
        self.assertTrue(record["ownedTreeTerminated"])
        self.assertTrue(record["terminalConfirmed"])
        self.assertTrue(record["rootTerminal"])
        self.assertEqual(record["treeFinal"]["activeProcesses"], 0)


class AssetIdentityTest(unittest.TestCase):
    def _identity(self, root):
        return gate.build_identity(root, None, require_tools=False)

    def test_unchanged_repo_passes(self):
        with tempfile.TemporaryDirectory(prefix="qfli_gate_id_") as temp:
            root = _make_repo(Path(temp))
            before = self._identity(root)
            # Guard against a vacuous test: these keys must be captured.
            self.assertIn("assets/app_icon.png", before["repoFiles"])
            self.assertIn(".flutter-plugins-dependencies", before["repoFiles"])
            gate.verify_identity(before, self._identity(root))

    def test_modified_asset_is_rejected(self):
        with tempfile.TemporaryDirectory(prefix="qfli_gate_id_") as temp:
            root = _make_repo(Path(temp))
            before = self._identity(root)
            _write(root / "assets" / "app_icon.png", "icon-v2")
            with self.assertRaisesRegex(RuntimeError, "Repo source/config drifted"):
                gate.verify_identity(before, self._identity(root))

    def test_deleted_asset_is_rejected(self):
        with tempfile.TemporaryDirectory(prefix="qfli_gate_id_") as temp:
            root = _make_repo(Path(temp))
            before = self._identity(root)
            (root / "assets" / "app_icon.png").unlink()
            with self.assertRaisesRegex(RuntimeError, "Repo source/config drifted"):
                gate.verify_identity(before, self._identity(root))

    def test_modified_plugin_manifest_is_rejected(self):
        with tempfile.TemporaryDirectory(prefix="qfli_gate_id_") as temp:
            root = _make_repo(Path(temp))
            before = self._identity(root)
            _write(root / ".flutter-plugins-dependencies", '{"plugins": {"x": 1}}\n')
            with self.assertRaisesRegex(RuntimeError, "Repo source/config drifted"):
                gate.verify_identity(before, self._identity(root))


class AnalyzeEvidenceTest(unittest.TestCase):
    def _parse(self, text, code=0):
        with tempfile.TemporaryDirectory(prefix="qfli_analyze_") as temp:
            log = Path(temp) / "analyze.log"
            log.write_text(text, encoding="utf-8")
            return gate.parse_analyze_counts(log, code)

    def test_empty_log_is_unproven_even_with_exit_zero(self):
        result = self._parse("")
        self.assertFalse(result["precise"])
        self.assertFalse(result["clean"])

    def test_real_completion_marker_proves_clean_analysis(self):
        result = self._parse("Analyzing qfli_dart...\nNo issues found! (ran in 1.2s)\n")
        self.assertTrue(result["clean"])
        self.assertEqual(result["issueLines"], 0)

    def test_colored_completion_marker_is_recognized(self):
        result = self._parse("\x1b[32mNo issues found! (ran in 1.2s)\x1b[0m\n")
        self.assertTrue(result["clean"])

    def test_issues_override_a_completion_marker(self):
        result = self._parse("warning • unused variable • lib/a.dart:1:2 • unused_local_variable\n"
                             "No issues found!\n")
        self.assertFalse(result["clean"])
        self.assertEqual(result["bySeverity"], {"warning": 1})


class ReporterCountTest(unittest.TestCase):
    def _parse(self, text, code=0):
        with tempfile.TemporaryDirectory(prefix="qfli_reporter_") as temp:
            log = Path(temp) / "test.log"
            log.write_text(text, encoding="utf-8")
            return gate.parse_test_counts(log, code)

    def test_program_numbers_do_not_inflate_reporter_counts(self):
        result = self._parse("00:01 +2: signed +240 and -2026 in a test name\n"
                             "program stdout: +999 -888\n"
                             "00:02 +3: All tests passed!\n")
        self.assertTrue(result["clean"])
        self.assertEqual(result["testsRun"], 3)
        self.assertEqual(result["testsFailed"], 0)

    def test_failed_and_skipped_counters_are_distinct(self):
        result = self._parse("00:02 +3 ~2 -1: Some tests failed.\n", 1)
        self.assertFalse(result["clean"])
        self.assertEqual(result["testsRun"], 4)
        self.assertEqual(result["testsPassed"], 3)
        self.assertEqual(result["testsFailed"], 1)
        self.assertEqual(result["testsSkipped"], 2)

    def test_compact_ansi_reporter_and_carriage_returns(self):
        result = self._parse("\x1b[2K00:01 +2: running\r"
                             "\x1b[2K00:02 +3: All tests passed!\n")
        self.assertTrue(result["clean"])
        self.assertEqual(result["testsRun"], 3)

    def test_skipped_tests_cannot_become_full_suite_proof(self):
        for marker in ("All tests passed!", "All other tests passed!"):
            with self.subTest(marker=marker):
                result = self._parse(f"00:02 +3 ~2: {marker}\n")
                self.assertTrue(result["precise"])
                self.assertTrue(result["allPassedMarker"])
                self.assertFalse(result["clean"])
                self.assertFalse(result["allTestsExecuted"])
                self.assertEqual(result["testsSkipped"], 2)

    def test_marker_without_reporter_evidence_is_not_precise(self):
        result = self._parse("program output: +999\nAll tests passed!\n")
        self.assertFalse(result["precise"])
        self.assertFalse(result["clean"])
        self.assertIsNone(result["testsRun"])


class GrantReplayTests(unittest.TestCase):
    def test_concurrent_callers_consume_exactly_once(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            barrier = threading.Barrier(8)

            def attempt(index):
                barrier.wait(timeout=10)
                try:
                    gate.consume_grant(root, "fresh-grant", 1234, f"run-{index}")
                    return True
                except RuntimeError:
                    return False

            with ThreadPoolExecutor(max_workers=8) as pool:
                results = list(pool.map(attempt, range(8)))
            self.assertEqual(results.count(True), 1)
            used = json.loads((root / "grant-ledger.json").read_text())["used"]
            self.assertEqual(len(used), 1)
            self.assertEqual(used[0]["grantId"], "fresh-grant")
            self.assertFalse((root / "grant-ledger.lock").exists())
            with self.assertRaises(RuntimeError):
                gate.consume_grant(root, "fresh-grant", 1234, "replay")
            self.assertFalse((root / "grant-ledger.lock").exists())

    def test_existing_lock_refuses_without_altering_ownership(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            lock = root / "grant-ledger.lock"
            lock.write_text("retained owner", encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "locked"):
                gate.consume_grant(root, "fresh-grant", 1234, "new-run")
            self.assertEqual(lock.read_text(), "retained owner")
            self.assertFalse((root / "grant-ledger.json").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
