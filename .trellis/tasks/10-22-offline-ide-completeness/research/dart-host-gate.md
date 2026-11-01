# Dart host gate: frozen identity and bounded SDK phases

Scope of this note: `tool/run_dart_host_gate.py` and this file.

No lib, test, curriculum, vendor, pubspec, package_config, core, native, android,
ohos or device file was edited. No Dart, Flutter, SDK, analyzer, test, build or
device command ran. Only `python -m py_compile`, `--help` and a read-only
`--print-identity` ran. There is no new host grant.

## 1. Why identity first, grant second

The root grants one named window. The executor must not touch that window
before the frozen identity exists.

Order of operations:

1. Resolve the core path from the existing `.dart_tool/package_config.json`.
2. Capture SHA256 of repo source, config, `tool/verify_b_draft_exercises.dart`, the core binding and the
   Dart/Flutter tool paths.
3. Verify the prepared identity file still matches the live files.
4. Consume the grant id in `build/dart-host-gate/grant-ledger.json`.
5. Run the controls.
6. Run the three SDK phases serially.
7. Re-check the same identity after every phase.
8. Re-capture the identity and compare, then write `final.json`.

A stale identity or a stale grant stops the run before any process starts.

## 2. No built-in grant replay

The executor has no default grant id. `--grant-id` is mandatory for `--execute`.
The ledger records every consumed id. A repeated id is refused.

The ledger lives under `build/dart-host-gate` and is append only. It is not a
source file and not a dependency.

## 3. Windows Job mechanics

Each phase starts through one owned Job object.

- The process starts with `CREATE_SUSPENDED`.
- The process is assigned to the Job before it runs.
- `NtResumeProcess` releases the process.
- The Job sets `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`.
- The exact job HANDLE and process HANDLE stay recorded until the tree is
  terminal and active0.
- The process creation FILETIME is rechecked to catch a reused PID.

Assignment before resume stops a descendant from escaping the owned tree.

Cleanup never closes an unconfirmed handle. While the tree is not terminal and
active0, the executor prints `HOLD_NO_RELEASE` and keeps observing the same root
and descendant handles. It closes the Job handle only after terminal
confirmation. `allOwnedJobsTerminalAndEmpty` accepts only `terminalConfirmed`.

A run that holds never writes a pass. The root sees a live outer process and
withholds the next grant.

## 4. Controls in the same run

The controls run before any SDK phase and share the deadline.

| Control | Expectation |
| --- | --- |
| `control-normal` | exits 0 with no forced cleanup |
| `control-orphan` | root exits 0, a residual child is observed, the Job terminates it |
| `control-timeout` | the phase deadline expires, exit 124, the Job terminates the tree |

A failed control stops the run with `HOST_CONTROLS_FAILED`. The control budget is
bounded to six seconds.

Forced cleanup is distinct from a clean pass. The orphan control must show a
residual process and a forced terminate. A normal exit must never need one.

## 5. Deadline math

`--deadline-epoch` is an absolute Unix-seconds deadline. `--reserve-seconds`
defaults to 45 and must be at least controls plus evidence.

`--max-window-seconds` defaults to 240 and has a hard ceiling of 240. A larger
value is refused. A future window must change the source to raise it.

The work deadline is the deadline minus the reserve. The reserve covers the
controls, the identity re-captures and the evidence writes.

Each phase has a minimum remaining time:

- `--exercises-min-seconds` defaults to 20.
- `--analyze-min-seconds` defaults to 60.
- `--test-min-seconds` defaults to 90.

A phase starts only while the remaining time is at least its minimum. A phase
that does not fit is recorded as UNRUN, together with every later phase.

A phase timeout or a non-clean phase ends the batch at once. Later phases stay
UNRUN.

The final identity re-capture and the evidence hashes use the remaining part of
the same absolute deadline. They never take a fresh 30-second budget.

After every phase the executor re-captures the frozen identity. Drift stops the
next phase and reports `IDENTITY_DRIFT`.

## 6. Phases and counts

Phases run serially in this order:

1. `dart tool/verify_b_draft_exercises.dart --exercise-only`
2. `flutter analyze --no-pub`
3. `flutter test --no-pub --concurrency=1`

`tool/verify_b_draft_exercises.dart` prints `unique=N pairs=N failures=N`. The executor requires phase
exit code 0 and that summary. The expected count defaults to 58. The 58 ids are
`dart-lesson-181` through `dart-lesson-238`.

The summary alone is not enough. The executor computes the exact results path
`results---exercise-only.json` from the script's own naming rule. It records the
old mtime and hash before the phase and requires the file to change during the
phase. It then requires 58 records. Each record must have `kind` `exercise`,
`passed` true, `sdkExitCode` 0, an empty `sdkError`, `sdkOutput` equal to
`expected`, and `portableOutput` equal to `expected`. The ids must be unique and
cover exactly 181 through 238, so duplicate records cannot pad the count. The
top-level `failures` must be 0 and `infrastructureFailure` must be false. The
results file SHA256 goes into the report. No old report is selected by glob.

`flutter analyze` counts issue lines by severity. Exit 0 with no issue line is
clean.

`flutter test` counts the highest `+N` and `-M` progress numbers and looks for
`All tests passed!`. Exit 0 is not enough on its own.

`final.json` holds these counts or an explicit UNRUN entry for each phase that
did not start. Every phase that did not start is listed, not only the phase that
stopped the batch.

The final exit code is computed after the `finally` evidence step. An identity
drift or an evidence failure can turn a pass into exit 1.

## 7. Read-only inputs and outputs

The executor reads the repo source, the config and the core binding. It writes
only under `build/dart-host-gate`:

- prepare run `build/dart-host-gate/<run>/identity.json`, `identity.sha256.json`,
  `prepare.json`
- execute run `build/dart-host-gate/<run>/before.json`, `after.json`,
  `<phase>.log`, `final.json`
- `grant-ledger.json` at the output root

The executor never runs `pub get` and never changes a dependency. It uses the
existing `package_config.json`.

Two honest caveats:

- `tool/verify_b_draft_exercises.dart` writes its own program and result files under
  `.dart_tool/expansion-b`. That is the existing behavior of that tool. It is not
  an executor write.
- Flutter writes its own build cache under `build` and `.dart_tool`. That is the
  SDK behavior. The executor does not write there.

## 8. Core equality honesty

The core path comes from the live `package_config.json`. The executor records
that path and its SHA256 as `current-workspace-binding`.

The executor never claims this core equals an earlier frozen core. The
`final.json` field `coreFrozenEqualityClaim` is always false.

A core drift during the run is reported as `IDENTITY_DRIFT` and fails the run.

## 9. Static checks done in this session

- `python -m py_compile tool/run_dart_host_gate.py` exited 0.
- `python tool/run_dart_host_gate.py --help` exited 0.
- A pure parser fixture exercised the results path and record validation with a
temporary directory. It started no process and wrote nothing under `build`.
  It checked the exact path `results---exercise-only.json`, the summary parse, a
  clean 58-record case with unique ids 181..238, and these rejections: nonzero
  phase exit, an unchanged (stale) results file, a duplicate id, a portable
  output mismatch, an SDK output mismatch, and a non-empty SDK stderr.

The fixture proves the parser and path rules. It does not prove the Job or SDK
behavior.

## 10. UNRUN items

These need a new named window. None of them ran.

- the normal, orphan and timeout controls
- the 58-exercise verify phase
- `flutter analyze --no-pub`
- `flutter test --no-pub --concurrency=1`
- any target-device action

## 11. Exact commands for the root

Prepare the frozen identity first. Prepare now records the Dart and Flutter tool
hashes, so pass the same two paths here and later. This starts no process:

```
python tool\run_dart_host_gate.py --prepare ^
  --dart-exe <absolute-dart-exe> ^
  --flutter-bat <absolute-flutter-bat>
```

Read the printed `identityPath`. After the root grants one new window, run:

```
python tool\run_dart_host_gate.py --execute ^
  --grant-id <new-window-id> ^
  --deadline-epoch <absolute-unix-seconds> ^
  --dart-exe <absolute-dart-exe> ^
  --flutter-bat <absolute-flutter-bat> ^
  --identity <identityPath>
```

The deadline must be within 240 seconds. The reserve must leave room for the
controls and evidence.

The executor sends no grant and no release. The root must observe this outer
process terminal and active0 before issuing the next grant. Then the root reads
`build/dart-host-gate/<run>/final.json`.

## Current source repair review

The timeout branch now records forced termination before terminating its Job. Assets and the plugin manifest are included in the identity. Coverage metadata explicitly excludes external package bytes and SDK internals. Toolchain hashes cover the Dart executable and Flutter launcher only.

Root removed four source-marker checks and kept behavior regressions. Additional pure fixtures verify reporter-only test counts and require analyzer completion evidence. Current pure Python suite: 16 passed. The additional regressions cover skipped/ANSI reporter evidence and exclusive grant consumption, including concurrent callers and retained-lock refusal. The repaired real controls, 58 exercises, analysis and full Flutter suite remain UNRUN pending a new named grant. Old630 and its prepared identity are consumed.

## READY781 after C779 source freeze

Preparation gate-20261026-102655-69272 captured264 repo/164core/37re_editor files. Identity SHA256 d789f928051511aad2e6d7f7fde236f1747d8ae1708ef0ea0058324f7f5336ab. Live pre-ACK comparison passed. Shared core lib/config is frozen at current terminal source7bf7d365; core/test is excluded and C may investigate fixtures there. This is not a tested-core acceptance claim. External package contents and SDK internals remain outside coverage. No SDK process started. Web fresh180 precedes a new named Dart240 grant; READY is not that grant. Retired716 and consumed630 must never replay.

Launch receipt is persisted in finally after postcheck errors. Terminal publisher discloses process start and identity verdict independently from test status. Safe terminal release does not require validation success or on-time publication; all actual roots and Jobs must still be proven terminal/empty.
