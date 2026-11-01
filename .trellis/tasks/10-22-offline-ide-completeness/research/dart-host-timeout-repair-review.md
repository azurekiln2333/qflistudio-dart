# Dart host gate: timeout repair review

Read-only review of the gray-area timeout fix and its regression test.

Scope of this note:

- `tool/run_dart_host_gate.py`, the `run_phase` timeout branch.
- `test/test_dart_host_gate.py`, the pure fake-Job regression.
- The prepare identity capture rules and their gaps.

No source, core, identity or other worker file was edited. No git command ran.
The GRANT630 grant was not replayed. No real control process ran. No SDK, Dart,
Flutter, build or device command ran.

The only executions were the pure Python unit test in `test/test_dart_host_gate.py`
and read-only file hashing. Both write nothing to the repo.

## 1. The original failure

GRANT630 run `gate-20261026-032037-58280` recorded:

- `control-normal` PASS.
- `control-orphan` PASS.
- `control-timeout` FAIL.
- The timeout tree did reach exit 124 and active0. It saw four PIDs. There was no
  cleanup error and no HOLD.
- The only failing condition was `ownedTreeTerminated` false.

So the cleanup itself worked. The gate only rejected the case because a required
accounting flag was missing.

## 2. The fix

`run_phase` now sets the flag before terminating. Current source lines 418 to 421:

```
                if time.time() >= deadline:
                    record["timedOut"] = True
                    record["ownedTreeTerminated"] = True
                    job.terminate()
                    break
```

The flag is set before `job.terminate()`. It is present in the record that
`run_controls` later reads. The timeout expectation now sees
`ownedTreeTerminated` true and can pass.

Verdict: the fix addresses the exact missing flag from the 630 failure.

## 3. Test accuracy

`test/test_dart_host_gate.py` imports the gate module and patches `OwnedJob` with
a `FakeJob` and a `FakeProcess`. It patches `gate.time.time` with a two-value
side effect. It calls `run_phase` and asserts:

- one `terminate` call
- `exitCode` 124
- `timedOut` true
- `ownedTreeTerminated` true
- `terminalConfirmed` true
- `rootTerminal` true
- `treeFinal.activeProcesses` 0

The test starts no real process. The fake Job mirrors the real behavior that
`confirm_terminal` does not set `ownedTreeTerminated` for a timeout.

I ran the test. It passed one test in 0.003 seconds.

I also ran a temp-only mutation check. I copied the module to a temporary
directory, removed the single `record["ownedTreeTerminated"] = True` line, and
loaded the copy. No repo source changed. The mutant result was:

- `exitCode` 124
- `timedOut` true
- `ownedTreeTerminated` false
- `terminate` called once
- the forced-cleanup error still raised

So the real test assertion `ownedTreeTerminated` true would fail on the mutant.
The test is sensitive to exactly the 630 regression.

Verdict: the test accurately covers the original failure's root cause.

Coverage boundaries to keep in mind:

- The test exercises `run_phase` fields. It does not call `run_controls`. The
  timeout expectation logic in `run_controls` is covered only through the shared
  record fields.
- The test patches `time.time` with a strict two-value list. A future extra
  `time.time()` call in `run_phase` would make the test error with a side-effect
  exhaustion instead of testing behavior.
- This test is a pure Python regression. The gate itself does not run it during
  `--execute`.

## 4. Prepare coverage of current source and runners

I rebuilt the capture with `require_tools=False` and read the membership.

The capture currently includes 260 repo files. It includes:

- `tool/run_dart_host_gate.py` at SHA256 `40db6e90...` (the fixed tool)
- `test/test_dart_host_gate.py` at SHA256 `ea213a47...` (the new regression)
- `tool/portable_content_runner.dart` (the runner used by `verify.dart`)
- `lib/dart_runner.dart`
- `.dart_tool/expansion-b/verify.dart`
- `pubspec.yaml` and `pubspec.lock`
- `analysis_options.yaml`
- `.dart_tool/package_config.json`
- all files under `lib`, `test`, `tool`, `curriculum`, `vendor`
- core `lib` files, 164 of them
- re_editor `lib` files, 37 of them

So current source and the Dart runner are covered. The new test file is captured
as a file. Its capture is for reproducibility, not for gate execution.

## 5. Gaps before a new READY

These are not covered by the prepare identity. Each is material to what the gate
runs.

1. Assets. `pubspec.yaml` declares `assets/app_icon.png`,
   `assets/content/dart_tutorials.json` and `assets/content/dart_examples.json`.
   There are 11 asset references across `lib` and `test`. No `assets/` path is in
   the identity. An asset change would not trip drift.
2. Resolved Pub-cache package sources. The app imports `analyzer`, `dart_style`,
   `dart_eval`, `path` and `pubspec_parse`. Core imports `archive`, `fast_gbk`,
   `file_selector`, `http`, `intl`, `path`, `path_provider`, `re_highlight` and
   `xml`. All of these live in the Pub cache. Only `pubspec.lock` is hashed. The
   actual package bytes are not. A cache change without a lock change would not
   trip drift.
3. SDK internals. Only `dart.exe` and `flutter.bat` are hashed. The Flutter tool
   snapshot and packages, and the Dart SDK lib directory, are not. So the SDK
   part of the identity is partial.
4. `.flutter-plugins-dependencies` is not captured. This is minor, because the
   plugin set is small.

Also note the old PREPARE `ff0ed038...` is consumed and stale. Its recorded tool
hash is `21197e5a...`. The current tool hash is `40db6e90...`. So the old identity
does not match the current source and must not be reused.

## 6. Static status of the report and files

- The pure unit test passed.
- The temp mutation check failed the flag as expected.
- The read-only capture shows the new test and both runners are included.
- The old identity is stale and consumed.
- Request 621 was consumed by 630.

## 7. What remains UNRUN

- The timeout control against the fixed source, with a real process.
- The normal and orphan controls against the fixed source.
- The 58 exercise verify phase.
- `flutter analyze --no-pub`.
- `flutter test --no-pub --concurrency=1`.
- Any target-device action.

## 8. Verdict

The fix is correct and minimal. The test is an accurate regression for the
original failure. I verified the test is sensitive to the fix with a temp-only
mutation.

Before a new READY, the root must:

1. Run a new `--prepare` with the fixed tool and the real `dart.exe` and
   `flutter.bat`.
2. Obtain a new READY and a new grant. Do not replay `Dart-host-20261026-02`.
3. Decide whether the four capture gaps above must be closed. The asset gap and
   the Pub-cache gap are the most material for content and analysis tests.

No blocking defect was found in the fix or the test.
