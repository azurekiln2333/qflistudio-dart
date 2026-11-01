"""Named Dart host gate: frozen identity, owned Job controls, three bounded phases.

Run only inside a NEW named Dart host slot. The root grants the slot after it
observed the previous outer terminal and active0. This executor:

  * records SHA256 of the live repo source/config, of
    ``tool/verify_b_draft_exercises.dart``, of ``assets/``, of
    ``.flutter-plugins-dependencies``, and of the Dart/Flutter tool paths BEFORE
    any process starts, and re-checks those hashes after every phase;
  * refuses a grant id already present in ``build/dart-host-gate/grant-ledger.json``,
    so an old authorization cannot be replayed from inside this file;
  * launches each phase suspended, assigns it to a KILL_ON_JOB_CLOSE Job, then
    resumes it, and keeps the exact job/process handles until the tree is
    terminal and active0;
  * runs the normal/orphan/timeout controls in the same run;
  * runs ``dart tool/verify_b_draft_exercises.dart --exercise-only`` then
    ``flutter analyze --no-pub`` then ``flutter test --no-pub --concurrency=1``
    serially, and starts a phase
    only while the configurable absolute deadline leaves enough time;
  * lists every phase that did not start as UNRUN;
  * writes only under ``build/dart-host-gate`` and never sends a grant or release.

The core path comes from the existing ``.dart_tool/package_config.json``. This
tool never runs ``pub get`` and never changes a dependency. It records the live
workspace core as-is and does not claim it equals any earlier frozen core.

Cleanup holds the exact handles until the owned tree is terminal and empty.
``--max-window-seconds`` has a hard ceiling of 240 seconds.
"""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes as wt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.parse import unquote, urljoin, urlparse


SOURCE_DIRS = ("lib", "test", "tool", "curriculum", "vendor", "assets")
VERIFY_SCRIPT = "tool/verify_b_draft_exercises.dart"
SOURCE_FILES = (
    "pubspec.yaml",
    "pubspec.lock",
    "pubspec_overrides.yaml",
    "analysis_options.yaml",
    ".dart_tool/package_config.json",
    ".flutter-plugins-dependencies",
    VERIFY_SCRIPT,
)
CORE_FILES = ("pubspec.yaml", "pubspec.lock", ".dart_tool/package_config.json")
RE_EDITOR_FILES = ("pubspec.yaml",)
CREATE_SUSPENDED = 0x4
CREATE_NO_WINDOW = 0x08000000
KILL_ON_JOB_CLOSE = 0x2000
CONTROLS_SECONDS = 6.0
MAX_WINDOW_SECONDS = 240.0
PHASE_ORDER = ("verify-exercises", "analyze", "test")
SKIP_DIR_PARTS = {"__pycache__", ".git", "build"}
SKIP_SUFFIXES = {".pyc", ".pyo"}


# --------------------------------------------------------------------------- #
# small helpers
# --------------------------------------------------------------------------- #

def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class _Stop(Exception):
    """Internal control-flow stop carrying the proposed exit code."""

    def __init__(self, code):
        super().__init__(code)
        self.code = code


def sha(path, deadline=None):
    digest = hashlib.sha256()
    with Path(path).open("rb") as source:
        while True:
            require(deadline is None or time.time() < deadline, "Evidence deadline reached")
            block = source.read(1024 * 1024)
            if not block:
                return digest.hexdigest()
            digest.update(block)


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def read_text(path):
    return Path(path).read_text(encoding="utf-8", errors="replace")


def capture_dir(root, deadline, dirs, files):
    """Hash selected files under ``dirs`` plus the named top-level ``files``."""
    paths = set()
    for folder in dirs:
        base = root / folder
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            require(deadline is None or time.time() < deadline, "Source capture deadline reached")
            if not path.is_file():
                continue
            parts = set(path.relative_to(root).parts)
            if parts & SKIP_DIR_PARTS or path.suffix.lower() in SKIP_SUFFIXES:
                continue
            paths.add(path)
    for name in files:
        path = root / name
        if path.is_file():
            paths.add(path)
    return {p.relative_to(root).as_posix(): sha(p, deadline) for p in sorted(paths)}


def package_root(config_path, package):
    """Resolve one package binding from the existing package_config.json."""
    config = json.loads(Path(config_path).read_text(encoding="utf-8"))
    matches = [p for p in config["packages"] if p["name"] == package]
    require(len(matches) == 1, f"Expected exactly one {package} binding")
    uri = urlparse(urljoin(Path(config_path).as_uri(), matches[0]["rootUri"]))
    require(uri.scheme == "file" and not uri.netloc, "Expected local package URI")
    return Path(unquote(uri.path).lstrip("/")).resolve()


def tool_record(tool, deadline):
    path = Path(tool).resolve()
    return {"path": str(tool), "resolvedPath": str(path), "sha256": sha(path, deadline)}


def batch_command(path, args):
    """Build a raw cmd.exe line for a .bat/.cmd tool with shell-safe tokens."""
    tokens = [str(path), *map(str, args)]
    require(all(not re.search(r'[&|<>^%!\r\n"]', t) for t in tokens),
            "Unsafe cmd argument; use a shell-safe path/slot/argument")
    prefix = subprocess.list2cmdline([
        os.environ.get("COMSPEC", "C:/Windows/System32/cmd.exe"),
        "/d", "/s", "/c",
    ])
    return prefix + ' "' + " ".join('"' + token + '"' for token in tokens) + '"'


def sdk_command(tool, args):
    """A .bat/.cmd needs the cmd wrapper; an .exe stays an argv list."""
    if str(tool).lower().endswith((".bat", ".cmd")):
        return batch_command(tool, args)
    return [str(tool), *map(str, args)]


# --------------------------------------------------------------------------- #
# frozen identity
# --------------------------------------------------------------------------- #

def build_identity(repo, deadline, dart_exe="", flutter_bat="", require_tools=True):
    config_path = repo / ".dart_tool/package_config.json"
    require(config_path.is_file(), "Existing .dart_tool/package_config.json required")
    require((repo / VERIFY_SCRIPT).is_file(), f"Required executor source missing: {VERIFY_SCRIPT}")
    core = package_root(config_path, "qfli_studio_core")
    re_editor = package_root(config_path, "re_editor")
    if require_tools:
        require(dart_exe and Path(dart_exe).is_file() and Path(dart_exe).is_absolute(),
                "Absolute --dart-exe file required")
        require(flutter_bat and Path(flutter_bat).is_file() and Path(flutter_bat).is_absolute(),
                "Absolute --flutter-bat file required")
        toolchain = {"dartExe": tool_record(dart_exe, deadline),
                     "flutterBat": tool_record(flutter_bat, deadline)}
    else:
        toolchain = {"dartExe": {"path": str(dart_exe), "recorded": False},
                     "flutterBat": {"path": str(flutter_bat), "recorded": False}}
    return {
        "schemaVersion": 1,
        "kind": "dart-host-gate-identity",
        "repoRoot": str(repo),
        "capturedAtEpoch": round(time.time(), 3),
        "packageConfig": {
            "path": str(config_path),
            "sha256": sha(config_path, deadline),
            "coreResolvedPath": str(core),
            "reEditorResolvedPath": str(re_editor),
        },
        "toolchain": toolchain,
        "coverage": {
            "repoAssets": True,
            "pluginManifest": True,
            "resolvedExternalPackageContents": False,
            "sdkInternals": False,
            "toolchainScope": "Dart executable and Flutter launcher bytes only",
        },
        "repoFiles": capture_dir(repo, deadline, SOURCE_DIRS, SOURCE_FILES),
        "core": {
            "role": "current-workspace-binding",
            "resolvedPath": str(core),
            "files": capture_dir(core, deadline, ("lib",), CORE_FILES),
        },
        "reEditor": {
            "role": "current-workspace-binding",
            "resolvedPath": str(re_editor),
            "files": capture_dir(re_editor, deadline, ("lib",), RE_EDITOR_FILES),
        },
        "note": (
            "Live workspace binding recorded as-is. This executor does not claim "
            "the current workspace core equals any earlier frozen core snapshot."
        ),
    }


def identity_stability(before, current):
    return {
        "repo": current["repoFiles"] == before["repoFiles"],
        "core": current["core"]["files"] == before["core"]["files"],
        "reEditor": current["reEditor"]["files"] == before["reEditor"]["files"],
        "packageConfig": current["packageConfig"]["sha256"] == before["packageConfig"]["sha256"],
        "toolchain": current["toolchain"] == before["toolchain"],
    }


def verify_identity(prepared, current):
    """Compare only the frozen parts; capturedAtEpoch is expected to differ."""
    require(prepared.get("kind") == "dart-host-gate-identity", "Not a prepared gate identity")
    require(prepared["packageConfig"]["sha256"] == current["packageConfig"]["sha256"],
            "package_config.json changed after preparation")
    require(prepared["packageConfig"]["coreResolvedPath"] == current["packageConfig"]["coreResolvedPath"],
            "core binding path changed after preparation")
    require(prepared["toolchain"] == current["toolchain"],
            "Dart/Flutter tool path or hash changed after preparation")
    require(prepared["repoFiles"] == current["repoFiles"],
            "Repo source/config drifted after preparation")
    require(prepared["core"]["files"] == current["core"]["files"],
            "Core binding files drifted after preparation")
    require(prepared["reEditor"]["files"] == current["reEditor"]["files"],
            "re_editor binding files drifted after preparation")


# --------------------------------------------------------------------------- #
# grant replay guard
# --------------------------------------------------------------------------- #

def consume_grant(output_root, grant_id, deadline_epoch, run_id):
    ledger_path = output_root / "grant-ledger.json"
    lock_path = output_root / "grant-ledger.lock"
    output_root.mkdir(parents=True, exist_ok=True)
    # Exclusive create serializes the read/check/write transaction across callers.
    # A crash leaves the lock in place: refuse execution until root reconciles it.
    try:
        lock = lock_path.open("x", encoding="utf-8")
    except FileExistsError:
        raise RuntimeError("Grant ledger is locked; reconcile ownership before retry") from None
    try:
        with lock:
            lock.write(json.dumps({"pid": os.getpid(), "runId": run_id}))
            lock.flush()
            ledger = {"schemaVersion": 1, "used": []}
            if ledger_path.is_file():
                ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
            used = ledger.setdefault("used", [])
            require(not any(entry.get("grantId") == grant_id for entry in used),
                    "Grant id already consumed; request a new window")
            used.append({"grantId": grant_id, "consumedAtEpoch": round(time.time(), 3),
                         "deadlineEpoch": deadline_epoch, "runId": run_id})
            write_json(ledger_path, ledger)
    finally:
        lock_path.unlink()


# --------------------------------------------------------------------------- #
# owned Windows Job (suspended launch, assign before resume, kill on close)
# --------------------------------------------------------------------------- #

class OwnedJob:
    def __init__(self):
        self.api = ctypes.WinDLL("kernel32", use_last_error=True)
        self.api.CreateJobObjectW.argtypes = [wt.LPVOID, wt.LPCWSTR]
        self.api.CreateJobObjectW.restype = wt.HANDLE
        self.api.SetInformationJobObject.argtypes = [wt.HANDLE, ctypes.c_int, wt.LPVOID, wt.DWORD]
        self.api.AssignProcessToJobObject.argtypes = [wt.HANDLE, wt.HANDLE]
        self.api.QueryInformationJobObject.argtypes = [wt.HANDLE, ctypes.c_int, wt.LPVOID, wt.DWORD, wt.LPVOID]
        self.api.TerminateJobObject.argtypes = [wt.HANDLE, wt.UINT]
        self.api.CloseHandle.argtypes = [wt.HANDLE]
        self.api.GetProcessId.argtypes = [wt.HANDLE]
        self.api.GetProcessId.restype = wt.DWORD
        self.api.GetProcessTimes.argtypes = [wt.HANDLE, *([ctypes.POINTER(wt.FILETIME)] * 4)]
        self.handle = self.api.CreateJobObjectW(None, None)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())
        # JOBOBJECT_EXTENDED_LIMIT_INFORMATION: LimitFlags sits at byte 16.
        info = ctypes.create_string_buffer(144 if ctypes.sizeof(ctypes.c_void_p) == 8 else 112)
        ctypes.c_uint32.from_buffer(info, 16).value = KILL_ON_JOB_CLOSE
        if not self.api.SetInformationJobObject(self.handle, 9, info, len(info)):
            self.api.CloseHandle(self.handle)
            raise ctypes.WinError(ctypes.get_last_error())
        self.observed_pids = set()
        self.proc = None
        self.assigned = False

    def state(self):
        info = ctypes.create_string_buffer(48)
        if not self.api.QueryInformationJobObject(self.handle, 1, info, len(info), None):
            raise ctypes.WinError(ctypes.get_last_error())
        ids = ctypes.create_string_buffer(8 + 4096 * ctypes.sizeof(ctypes.c_size_t))
        if self.api.QueryInformationJobObject(self.handle, 3, ids, len(ids), None):
            count = ctypes.c_uint32.from_buffer(ids, 4).value
            for i in range(min(count, 4096)):
                self.observed_pids.add(
                    ctypes.c_size_t.from_buffer(ids, 8 + i * ctypes.sizeof(ctypes.c_size_t)).value)
        return {"totalProcesses": ctypes.c_uint32.from_buffer(info, 36).value,
                "activeProcesses": ctypes.c_uint32.from_buffer(info, 40).value,
                "observedPids": sorted(self.observed_pids)}

    def identity(self, record):
        if self.proc is None:
            return
        handle = wt.HANDLE(int(self.proc._handle))
        created, exited, kernel, user = (wt.FILETIME() for _ in range(4))
        if not self.api.GetProcessTimes(handle, ctypes.byref(created), ctypes.byref(exited),
                                        ctypes.byref(kernel), ctypes.byref(user)):
            raise ctypes.WinError(ctypes.get_last_error())
        identity = str((created.dwHighDateTime << 32) | created.dwLowDateTime)
        require(self.api.GetProcessId(handle) == self.proc.pid, "Root HANDLE/PID mismatch")
        require(record.get("creationFiletime100ns", identity) == identity,
                "Root HANDLE creation identity changed")
        record.update(processHandle=str(int(self.proc._handle)), creationFiletime100ns=identity,
                      rootIdentityVerified=True)

    def launch(self, command, cwd, log, record):
        self.proc = subprocess.Popen(command, cwd=cwd, stdout=log, stderr=subprocess.STDOUT,
                                     stdin=subprocess.DEVNULL,
                                     creationflags=CREATE_SUSPENDED | CREATE_NO_WINDOW)
        proc = self.proc
        record["pid"] = proc.pid
        record.update(createdSuspended=True, assignedBeforeResume=False)
        self.identity(record)
        if not self.api.AssignProcessToJobObject(self.handle, wt.HANDLE(int(proc._handle))):
            raise ctypes.WinError(ctypes.get_last_error())
        self.assigned = True
        record["assignedBeforeResume"] = True
        resume = ctypes.WinDLL("ntdll").NtResumeProcess
        resume.argtypes = [wt.HANDLE]
        resume.restype = ctypes.c_long
        require(resume(wt.HANDLE(int(proc._handle))) == 0, "Cannot resume owned process")
        return proc

    def terminate(self):
        if not self.api.TerminateJobObject(self.handle, 124):
            raise ctypes.WinError(ctypes.get_last_error())

    def close(self):
        self.api.CloseHandle(self.handle)

    def confirm_terminal(self, record):
        """Hold the exact handles until the owned tree is terminal and active0.

        The handle closes only after terminal confirmation. If cleanup cannot
        confirm the tree, this prints HOLD_NO_RELEASE and keeps observing the
        same root and descendant handles. It never closes an unconfirmed handle.
        """
        cleanup_deadline = time.monotonic() + 2.0
        retirement_deadline = time.monotonic() + 0.5
        hold_printed = False
        while True:
            try:
                self.identity(record)
                code = self.proc.poll() if self.proc is not None else None
                state = self.state()
                record.update(treeFinal=state, rootTerminal=self.proc is None or code is not None)
                if code is not None:
                    record["exitCode"] = code
                if record["rootTerminal"] and state["activeProcesses"] == 0:
                    record["terminalConfirmed"] = True
                    self.close()
                    return
                if record["rootTerminal"] and state["activeProcesses"]:
                    record["residualObservedAfterRootExit"] = True
                    record["residualActiveProcesses"] = state["activeProcesses"]
                    if not record["timedOut"] and time.monotonic() < retirement_deadline:
                        record["naturalRetirementWaited"] = True
                        time.sleep(max(0.0, min(0.02, retirement_deadline - time.monotonic())))
                        continue
                record["ownedTreeTerminated"] = True
                if self.assigned:
                    self.terminate()
                elif self.proc is not None and code is None:
                    self.proc.kill()
            except BaseException as error:
                record["cleanupError"] = f"{type(error).__name__}: {error}"
                try:
                    record["ownedTreeTerminated"] = True
                    if self.assigned:
                        self.terminate()
                    elif self.proc is not None and self.proc.poll() is None:
                        self.proc.kill()
                except BaseException as termination_error:
                    record["terminationError"] = str(termination_error)
            if time.monotonic() >= cleanup_deadline and not hold_printed:
                print(json.dumps({"status": "HOLD_NO_RELEASE", "phase": record.get("phase"),
                                  "pid": record.get("pid"),
                                  "processHandle": record.get("processHandle"),
                                  "jobHandle": record.get("jobHandle"),
                                  "reason": record.get("cleanupError", "Owned tree not terminal/empty")}),
                      flush=True)
                record["cleanupHeld"] = hold_printed = True
            time.sleep(0.2 if hold_printed else 0.02)


def run_phase(name, command, cwd, output, deadline, report):
    record = {"phase": name, "command": command, "cwd": str(cwd), "pid": None,
              "exitCode": None, "timedOut": False, "terminalConfirmed": False,
              "ownedTreeTerminated": False}
    report["phases"].append(record)
    try:
        job = OwnedJob()
    except BaseException:
        record.update(rootTerminal=True, terminalConfirmed=True,
                      treeFinal={"activeProcesses": 0}, noProcessStarted=True)
        raise
    record["jobHandle"] = str(int(job.handle))
    log_path = output / (name + ".log")
    try:
        require(time.time() < deadline, "Work deadline reached before phase start")
        try:
            log_handle = log_path.open("wb")
        except OSError as error:
            record["logWriteError"] = str(error)
            log_handle = open(os.devnull, "wb")
        with log_handle:
            proc = job.launch(command, cwd, log_handle, record)
            while proc.poll() is None:
                record["tree"] = job.state()
                if time.time() >= deadline:
                    record["timedOut"] = True
                    record["ownedTreeTerminated"] = True
                    job.terminate()
                    break
                time.sleep(0.05)
            record["exitCode"] = proc.wait(timeout=5)
    finally:
        try:
            job.confirm_terminal(record)
        finally:
            if log_path.exists():
                try:
                    record["logSha256"] = sha(log_path)
                except BaseException as error:
                    record["logHashError"] = str(error)
    require("logWriteError" not in record and "logHashError" not in record,
            "Phase log evidence unavailable")
    if record["timedOut"] or record["ownedTreeTerminated"]:
        raise RuntimeError(f"{name} timed out or required forced owned-tree cleanup")
    return record["exitCode"]


def run_controls(cwd, output, work_deadline, report):
    """Same-run normal/orphan/timeout controls; forced cleanup differs from pass."""
    started = time.time()
    deadline = min(work_deadline, started + CONTROLS_SECONDS)
    report["controlPhases"] = []
    control_report = {"phases": report["controlPhases"]}
    child = "import time; time.sleep(15)"
    spawn = (f"import subprocess,sys; "
             f"subprocess.Popen([sys.executable,'-c',{child!r}],creationflags={CREATE_NO_WINDOW}); ")
    plans = (
        ("control-normal", "pass", "normal", 1.0),
        ("control-orphan", spawn, "orphan-rejected", 1.5),
        ("control-timeout", spawn + "import time; time.sleep(15)", "timeout-cleaned", 0.6),
    )
    results = []
    for name, source, expectation, seconds in plans:
        error = None
        try:
            run_phase(name, [sys.executable, "-c", source], cwd, output,
                      min(deadline, time.time() + seconds), control_report)
        except BaseException as failure:
            error = f"{type(failure).__name__}: {failure}"
        record = report["controlPhases"][-1]
        terminal = (record.get("pid") is not None and record.get("rootIdentityVerified") is True
                    and record.get("rootTerminal") is True
                    and record.get("terminalConfirmed") is True
                    and record.get("treeFinal", {}).get("activeProcesses") == 0)
        if expectation == "normal":
            passed = (terminal and error is None and record["exitCode"] == 0
                      and not record["timedOut"] and not record["ownedTreeTerminated"])
        elif expectation == "orphan-rejected":
            passed = (terminal and error is not None and record["exitCode"] == 0
                      and not record["timedOut"] and record["ownedTreeTerminated"]
                      and record.get("residualObservedAfterRootExit") is True)
        else:
            passed = (terminal and error is not None and record["exitCode"] == 124
                      and record["timedOut"] and record["ownedTreeTerminated"]
                      and len(record["treeFinal"].get("observedPids", [])) >= 2)
        results.append({"phase": name, "expectation": expectation, "passed": passed,
                        "observedError": error})
        if not passed or time.time() >= deadline:
            break
    passed = len(results) == 3 and all(r["passed"] for r in results) and time.time() <= deadline
    report["controls"] = {"passed": passed, "results": results,
                          "elapsedSeconds": round(time.time() - started, 3),
                          "budgetSeconds": CONTROLS_SECONDS}
    return passed


# --------------------------------------------------------------------------- #
# per-phase counts
# --------------------------------------------------------------------------- #

def verify_result_path(repo):
    """Exact path the migrated verifier writes for ``['--exercise-only']``.

    ``tool/verify_b_draft_exercises.dart`` builds the same
    ``results-${args.join('-').replaceAll('=', '-')}.json`` name.
    """
    suffix = "-".join(["--exercise-only"]).replace("=", "-")
    return repo / ".dart_tool/expansion-b" / f"results-{suffix}.json"


def record_verify_baseline(report, repo):
    path = verify_result_path(repo)
    entry = {"path": str(path), "existedBefore": path.is_file()}
    if path.is_file():
        entry["mtimeBefore"] = path.stat().st_mtime_ns
        entry["sha256Before"] = sha(path)
    report["verifyEvidence"] = entry


def parse_exercise_summary(log_path, expected, exit_code):
    text = read_text(log_path)
    matches = re.findall(r"unique=(\d+)\s+pairs=(\d+)\s+failures=(\d+)", text)
    summary = {"precise": bool(matches), "exitCode": exit_code}
    if matches:
        unique, pairs, failures = (int(value) for value in matches[-1])
        summary.update(planned=unique, checked=pairs, failures=failures, expected=expected)
    summary["clean"] = (exit_code == 0 and summary["precise"]
                        and summary.get("planned") == expected
                        and summary.get("checked") == expected
                        and summary.get("failures") == 0)
    if not summary["precise"]:
        summary["reason"] = "verify_b_draft_exercises.dart summary line not found"
    return summary


def validate_exercise_results(report, repo, expected, exit_code):
    """Read the exact new results file and require 58 clean exercise records."""
    require(exit_code == 0, "verify_b_draft_exercises.dart exited nonzero")
    path = verify_result_path(repo)
    require(path.is_file(), f"verify results file missing: {path}")
    baseline = report.get("verifyEvidence", {})
    new_sha = sha(path)
    new_mtime = path.stat().st_mtime_ns
    require(not baseline.get("existedBefore")
            or new_sha != baseline.get("sha256Before")
            or new_mtime != baseline.get("mtimeBefore"),
            "verify results file is stale; it did not change during this phase")
    document = json.loads(path.read_text(encoding="utf-8"))
    records = document.get("results")
    require(isinstance(records, list), "results list missing")
    require(document.get("infrastructureFailure") is False, "infrastructureFailure is true")
    require(document.get("failures") == 0, "failures is nonzero")
    require(len(records) == expected, f"expected {expected} exercise records, found {len(records)}")
    numbers = []
    for record in records:
        require(record.get("kind") == "exercise", "non-exercise record in results")
        require(record.get("passed") is True, "a record is not passed")
        require(record.get("sdkExitCode") == 0, "a record has nonzero sdkExitCode")
        require(record.get("sdkError") == "", "a record has non-empty sdkError")
        require(record.get("sdkOutput") == record.get("expected"),
                "a record has an SDK output mismatch")
        require(record.get("portableOutput") == record.get("expected"),
                "a record has a portable output mismatch")
        require(not record.get("portableError"), "a record carries portableError")
        identifier = record.get("id")
        require(isinstance(identifier, str), "a record has no string id")
        try:
            numbers.append(int(identifier.split("-")[-1]))
        except ValueError:
            raise RuntimeError(f"a record has an unparseable id: {identifier!r}")
    # 58 distinct ids covering 181..238 stops duplicate records from padding the count.
    require(sorted(numbers) == list(range(181, 181 + expected)),
            "records must carry unique ids 181..238")
    return {"precise": True, "checked": len(records), "expected": expected,
            "idFirst": min(numbers), "idLast": max(numbers), "uniqueIds": len(set(numbers)),
            "failures": document.get("failures"), "infrastructureFailure": False,
            "resultsPath": str(path), "resultsSha256": new_sha, "stale": False}


def reporter_text(log_path):
    return re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", read_text(log_path))


def parse_analyze_counts(log_path, exit_code):
    text = reporter_text(log_path)
    lines = [line for line in text.splitlines() if " • " in line]
    severities = {}
    for line in lines:
        severity = line.split(" • ", 1)[0].strip()
        severities[severity] = severities.get(severity, 0) + 1
    marker = bool(re.search(r"^\s*No issues found!(?:\s+\([^\r\n]*\))?\s*$",
                            text, re.MULTILINE))
    return {"precise": marker or bool(lines), "issueLines": len(lines),
            "bySeverity": severities, "noIssuesMarker": marker,
            "exitCode": exit_code, "clean": exit_code == 0 and marker and not lines}


def parse_test_counts(log_path, exit_code):
    text = reporter_text(log_path)
    # Only reporter counters count. Program output and test names may contain
    # arbitrary signed numbers (for example +240 and -2026).
    progress = list(re.finditer(
        r"^\s*\d+:\d+(?::\d+)?\s+\+(\d+)"
        r"(?:\s+~(\d+))?(?:\s+-(\d+))?:\s*([^\r\n]*)",
        text, re.MULTILINE,
    ))
    last = progress[-1] if progress else None
    passed_count = int(last.group(1)) if last else None
    skipped_count = int(last.group(2) or 0) if last else None
    failed_count = int(last.group(3) or 0) if last else None
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    markers = {"All tests passed!", "All other tests passed!"}
    passed = bool(last and (
        last.group(4).strip() in markers
        or (lines and lines[-1] in markers)
    ))
    return {"precise": last is not None,
            "testsRun": passed_count + failed_count if last else None,
            "testsPassed": passed_count, "testsFailed": failed_count,
            "testsSkipped": skipped_count, "allPassedMarker": passed,
            "allTestsExecuted": bool(last and skipped_count == 0),
            "exitCode": exit_code,
            "clean": (exit_code == 0 and passed and passed_count > 0
                      and failed_count == 0 and skipped_count == 0)}


# --------------------------------------------------------------------------- #
# main
# --------------------------------------------------------------------------- #

def repo_root():
    return Path(__file__).resolve().parents[1]


def output_root(repo):
    return repo / "build/dart-host-gate"


def run_id():
    return time.strftime("gate-%Y%m%d-%H%M%S-") + str(os.getpid())


def prepare(args):
    repo = repo_root()
    root = output_root(repo)
    run = run_id()
    out = root / run
    out.mkdir(parents=True, exist_ok=True)
    identity = build_identity(repo, time.time() + 600, args.dart_exe, args.flutter_bat)
    identity_path = out / "identity.json"
    write_json(identity_path, identity)
    digest = sha(identity_path)
    write_json(out / "identity.sha256.json", {"identity.json": digest})
    summary = {
        "status": "PREPARE_OK",
        "runId": run,
        "repoRoot": str(repo),
        "outputDir": str(out),
        "identityPath": str(identity_path),
        "identityFileSha256": digest,
        "packageConfigSha256": identity["packageConfig"]["sha256"],
        "coreResolvedPath": identity["packageConfig"]["coreResolvedPath"],
        "coreRole": identity["core"]["role"],
        "coreFrozenEqualityClaim": False,
        "toolchain": identity["toolchain"],
        "identityCoverage": identity["coverage"],
        "repoFileCount": len(identity["repoFiles"]),
        "coreFileCount": len(identity["core"]["files"]),
        "reEditorFileCount": len(identity["reEditor"]["files"]),
        "note": "Preparation only. No process started. Request a new named window before --execute.",
    }
    write_json(out / "prepare.json", summary)
    print(json.dumps(summary, ensure_ascii=False), flush=True)
    return 0


def print_identity(args):
    repo = repo_root()
    identity = build_identity(repo, time.time() + 600, require_tools=False)
    identity.pop("capturedAtEpoch", None)
    print(json.dumps(identity, ensure_ascii=False, indent=2))
    return 0


def execute(args):
    repo = repo_root()
    root = output_root(repo)
    started = time.time()
    deadline = float(args.deadline_epoch)
    reserve = float(args.reserve_seconds)
    work_deadline = deadline - reserve
    run = run_id()
    out = root / run
    out.mkdir(parents=True, exist_ok=True)
    report = {
        "schemaVersion": 1,
        "tool": "tool/run_dart_host_gate.py",
        "runId": run,
        "grantId": args.grant_id,
        "deadlineEpoch": deadline,
        "workDeadlineEpoch": work_deadline,
        "reserveSeconds": reserve,
        "repoRoot": str(repo),
        "outputDir": str(out),
        "status": "EXECUTE_REFUSED",
        "exitCode": 2,
        "phases": [],
        "controlPhases": [],
        "unrun": [],
        "counts": {},
        "coreFrozenEqualityClaim": False,
        "autoGrantSent": False,
        "autoReleaseSent": False,
        "killOnJobCloseEnforced": True,
    }
    core = re_editor = None
    before = after = None
    try:
        require(sys.platform == "win32", "Windows host with a Job object required")
        require(re.fullmatch(r"[A-Za-z0-9_.:-]+", args.grant_id), "Invalid grant id")
        require(deadline > time.time(), "Deadline must be in the future")
        require(float(args.max_window_seconds) <= MAX_WINDOW_SECONDS,
                f"--max-window-seconds hard cap is {MAX_WINDOW_SECONDS:g}")
        require(deadline <= time.time() + float(args.max_window_seconds),
                "Deadline is farther than the allowed window")
        require(reserve >= CONTROLS_SECONDS + 8, "Reserve must cover controls and evidence")
        require(args.identity.is_file(), "Prepared identity file required before execute")
        require(args.dart_exe.is_file() and Path(args.dart_exe).is_absolute(),
                "Absolute --dart-exe file required")
        require(args.flutter_bat.is_file() and Path(args.flutter_bat).is_absolute(),
                "Absolute --flutter-bat file required")
        out.mkdir(parents=True, exist_ok=True)

        # 1. Fully prepare the frozen identity first.
        before = build_identity(repo, work_deadline, args.dart_exe, args.flutter_bat)
        prepared = json.loads(args.identity.read_text(encoding="utf-8"))
        verify_identity(prepared, before)
        report["identityVerifiedUnchanged"] = True
        report["identityCoverage"] = before["coverage"]
        report["packageConfigSha256"] = before["packageConfig"]["sha256"]
        core = Path(before["core"]["resolvedPath"])
        re_editor = Path(before["reEditor"]["resolvedPath"])
        report["coreBinding"] = {"resolvedPath": str(core), "role": before["core"]["role"],
                                 "frozenEqualityClaim": False}
        report["reEditorBinding"] = {"resolvedPath": str(re_editor), "role": before["reEditor"]["role"]}
        write_json(out / "before.json", before)

        # 2. Only then consume the new window's grant.
        consume_grant(root, args.grant_id, deadline, run)
        report["grantConsumed"] = True

        # 3. Same-run controls, then the three serial SDK phases.
        if not run_controls(repo, out, work_deadline, report):
            report["stopReason"] = "controls failed"
            report.update(status="HOST_CONTROLS_FAILED")
            raise _Stop(1)

        phases = (
            ("verify-exercises", args.exercises_min_seconds,
             sdk_command(args.dart_exe, [repo / VERIFY_SCRIPT, "--exercise-only"])),
            ("analyze", args.analyze_min_seconds,
             sdk_command(args.flutter_bat, ["analyze", "--no-pub"])),
            ("test", args.test_min_seconds,
             sdk_command(args.flutter_bat, ["test", "--no-pub", "--concurrency=1"])),
        )
        for name, min_seconds, command in phases:
            remaining = work_deadline - time.time()
            if remaining < float(min_seconds):
                report["stopReason"] = f"remaining {remaining:.1f}s < {min_seconds}s before {name}"
                report.update(status="HOST_GATE_PARTIAL")
                raise _Stop(3)
            if name == "verify-exercises":
                record_verify_baseline(report, repo)
            try:
                code = run_phase(name, command, repo, out, work_deadline, report)
            except BaseException as failure:
                record = report["phases"][-1]
                record["failure"] = f"{type(failure).__name__}: {failure}"
                report["stopReason"] = record["failure"]
                report.update(status="HOST_GATE_FAILED")
                raise _Stop(record.get("exitCode") or 1)
            log_path = out / (name + ".log")
            try:
                if name == "verify-exercises":
                    summary = parse_exercise_summary(log_path, args.expected_exercises, code)
                    results = validate_exercise_results(report, repo, args.expected_exercises, code)
                    report["counts"]["verify-exercises"] = summary
                    report["counts"]["verifyResults"] = results
                    clean = summary.get("clean") is True and results.get("precise") is True
                elif name == "analyze":
                    counts = parse_analyze_counts(log_path, code)
                    report["counts"]["analyze"] = counts
                    clean = counts.get("clean") is True
                else:
                    counts = parse_test_counts(log_path, code)
                    report["counts"]["test"] = counts
                    clean = counts.get("clean") is True
            except BaseException as evidence_error:
                report["stopReason"] = (f"{name} evidence invalid: "
                                        f"{type(evidence_error).__name__}: {evidence_error}")
                report.update(status="HOST_GATE_FAILED")
                raise _Stop(code or 1)
            if not clean:
                report["stopReason"] = f"{name} was not clean"
                report.update(status="HOST_GATE_FAILED")
                raise _Stop(code or 1)
            # Re-check the frozen identity after every phase.
            try:
                current = build_identity(repo, work_deadline, args.dart_exe, args.flutter_bat)
            except BaseException as check_error:
                report.setdefault("phaseIdentityErrors", []).append(
                    f"{name}: {type(check_error).__name__}: {check_error}")
                report["stopReason"] = f"identity recheck failed after {name}"
                report.update(status="EVIDENCE_FAILED")
                raise _Stop(1)
            stable = identity_stability(before, current)
            report.setdefault("phaseIdentityChecks", {})[name] = stable
            if not all(stable.values()):
                report["stopReason"] = f"identity drift after {name}"
                report.update(status="IDENTITY_DRIFT")
                raise _Stop(1)

        report.update(status="HOST_GATE_PASS")
        raise _Stop(0)
    except _Stop as stop:
        report["exitCode"] = stop.code
    except BaseException as error:
        report["error"] = f"{type(error).__name__}: {error}"
        report.setdefault("stopReason", report["error"])
        if report["status"] == "EXECUTE_REFUSED":
            report["status"] = "HOST_GATE_FAILED"
            report["exitCode"] = 2
        elif not report["phases"] and not report["controlPhases"]:
            report["status"] = "HOST_GATE_FAILED"
            report["exitCode"] = report["exitCode"] or 2
    finally:
        # Final evidence uses the remaining absolute deadline, not a fresh budget.
        if before is not None and time.time() < deadline:
            try:
                after = build_identity(repo, deadline, args.dart_exe, args.flutter_bat)
                write_json(out / "after.json", after)
                report["identityStable"] = identity_stability(before, after)
                if not all(report["identityStable"].values()):
                    report["identityDriftDetected"] = True
                    if report["exitCode"] == 0:
                        report.update(status="IDENTITY_DRIFT", exitCode=1)
            except BaseException as error:
                report.setdefault("evidenceErrors", []).append(
                    f"after identity: {type(error).__name__}: {error}")
                if report["exitCode"] == 0:
                    report.update(status="EVIDENCE_FAILED", exitCode=1)
        elif before is not None:
            report.setdefault("evidenceErrors", []).append(
                "after identity skipped: absolute deadline reached")
            if report["exitCode"] == 0:
                report.update(status="EVIDENCE_FAILED", exitCode=1)
        for name in ("before.json", "after.json", "identity.json"):
            path = out / name
            if path.is_file():
                try:
                    report.setdefault("evidenceHashes", {})[name] = sha(path, deadline)
                except BaseException as error:
                    report.setdefault("evidenceErrors", []).append(
                        f"evidence hash {name}: {type(error).__name__}: {error}")
                    if report["exitCode"] == 0:
                        report.update(status="EVIDENCE_FAILED", exitCode=1)
        # Every phase that did not start is listed as UNRUN.
        executed = {record["phase"] for record in report["phases"]}
        listed = {entry["phase"] for entry in report["unrun"]}
        reason = report.get("stopReason", "not reached")
        for name in PHASE_ORDER:
            if name in executed or name in listed:
                continue
            report["unrun"].append({"phase": name, "reason": reason})
        order = {name: index for index, name in enumerate(PHASE_ORDER)}
        report["unrun"].sort(key=lambda entry: order.get(entry["phase"], len(order)))
        validation = [*report.get("controlPhases", []), *report["phases"]]
        report["allOwnedJobsTerminalAndEmpty"] = all(
            p.get("terminalConfirmed") is True
            and p.get("rootTerminal") is True
            and p.get("treeFinal", {}).get("activeProcesses") == 0 for p in validation)
        if report["exitCode"] == 0 and not report["allOwnedJobsTerminalAndEmpty"]:
            report.update(status="TERMINAL_UNCONFIRMED", exitCode=1)
        report["rootMustObserveOuterTerminalAndActiveZero"] = True
        report["rootMustIssueNextGrant"] = True
        report["elapsedSeconds"] = round(time.time() - started, 3)
        write_json(out / "final.json", report)
        print(json.dumps({"runId": run, "status": report["status"], "exit": report["exitCode"],
                          "outputDir": str(out), "unrun": report["unrun"],
                          "rootMustObserveOuterTerminalAndActiveZero": True,
                          "autoGrantSent": False, "autoReleaseSent": False}, ensure_ascii=False),
              flush=True)
    return report["exitCode"]


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="run_dart_host_gate.py", description=__doc__)
    parser.add_argument("--prepare", action="store_true",
                        help="Record the frozen identity only. No process starts. Default when --execute is absent.")
    parser.add_argument("--print-identity", action="store_true",
                        help="Print the live frozen identity JSON and write nothing.")
    parser.add_argument("--execute", action="store_true",
                        help="Run controls and the three phases. Requires a NEW named window.")
    parser.add_argument("--grant-id", default="", help="New named window id. No old grant is built in.")
    parser.add_argument("--deadline-epoch", type=float, default=0.0,
                        help="Absolute Unix-seconds deadline for this run.")
    parser.add_argument("--reserve-seconds", type=float, default=45.0,
                        help="Seconds reserved for controls, inspection and evidence.")
    parser.add_argument("--max-window-seconds", type=float, default=MAX_WINDOW_SECONDS,
                        help="Refuse a deadline farther than this. Hard cap 240.")
    parser.add_argument("--dart-exe", default="", help="Absolute path to the Dart executable.")
    parser.add_argument("--flutter-bat", default="", help="Absolute path to flutter.bat or flutter.cmd.")
    parser.add_argument("--identity", default="", help="Path to the prepared identity.json.")
    parser.add_argument("--expected-exercises", type=int, default=58,
                        help="Expected tool/verify_b_draft_exercises.dart --exercise-only count.")
    parser.add_argument("--exercises-min-seconds", type=float, default=20.0,
                        help="Start verify only with at least this much time left.")
    parser.add_argument("--analyze-min-seconds", type=float, default=60.0,
                        help="Start analyze only with at least this much time left.")
    parser.add_argument("--test-min-seconds", type=float, default=90.0,
                        help="Start test only with at least this much time left.")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.print_identity:
        return print_identity(args)
    args.dart_exe = Path(args.dart_exe) if args.dart_exe else Path("")
    args.flutter_bat = Path(args.flutter_bat) if args.flutter_bat else Path("")
    if args.execute:
        args.identity = Path(args.identity) if args.identity else Path("")
        return execute(args)
    return prepare(args)


if __name__ == "__main__":
    sys.exit(main())
