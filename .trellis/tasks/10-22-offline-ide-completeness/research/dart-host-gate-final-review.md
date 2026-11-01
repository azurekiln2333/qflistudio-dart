# Dart host gate: read-only final review

Scope of this note: a read-only review of `tool/run_dart_host_gate.py`, the
prepared identity `gate-20261026-024519-64752`, and the later GRANT630 evidence.

Two review points are recorded. The first is the 02:45 static review. The second
is the 03:20 update after GRANT630 and the root timeout fix.

No source, identity or evidence file was edited by this review. No `--execute`
ran from this review. No control ran from this review. No Dart, Flutter, SDK,
analyzer, test, build or device command ran. No git command ran. Python use was
read-only reading and hashing, plus an earlier parser fixture in a temporary
directory.

## 1. Identity under review

- Directory `build/dart-host-gate/gate-20261026-024519-64752`.
- Files `identity.json`, `identity.sha256.json`, `prepare.json`.
- `identity.json` SHA256 `ff0ed038f62d76840eea0fc3734c4a167cc050dffb88262ed2475eaf36d114a4`.
- The sidecar value matches that hash.
- No `grant-ledger.json` exists yet, so prepare consumed no grant.

Prepared identity contents:

| Item | Value |
| --- | --- |
| repo files | 259 |
| core files | 164 |
| re_editor files | 37 |
| core path | `D:\MyNewProjects\qfli_studio_core` |
| core role | `current-workspace-binding` |
| frozen equality claim | false |
| package_config SHA256 | `f25483f26a216b2c...` |
| `verify.dart` SHA256 | `926df9a2e0f4f494...` |
| `dart.exe` SHA256 | `f65cad70999405c5...` |
| `flutter.bat` SHA256 | `f83bfed7ecd10fd1...` |
| tool source SHA256 | `21197e5ad3e7dd0f...` |

## 2. Identity status after GRANT630

At the 02:45 review the prepared identity `gate-20261026-024519-64752` matched the
live tree. Its sidecar hash was `ff0ed038...`. Its recorded tool hash was
`21197e5ad3e7dd0f...`. A full read-only capture then took about 0.29 seconds.

That identity is now consumed and stale. The GRANT630 run used it. The root then
changed the tool source. The current tool hash is `40db6e90...`.

So the old identity no longer matches the live tool. Any claim that it still
matches the current source would be false.

The grant ledger holds one consumed id. It is `Dart-host-20261026-02`, for run
`gate-20261026-032037-58280`. Request 621 was consumed by 630.

A new `--prepare` must run against the new source. Then a new READY and a new
grant are required. The consumed grant must not be replayed.

## 3. HOLD cleanup of the exact handles

Location `OwnedJob.confirm_terminal`, around line 338.

- The Job handle closes only inside the `terminalConfirmed` branch.
- That branch requires `rootTerminal` true and `activeProcesses == 0`.
- If the tree is not terminal, it calls `TerminateJobObject` and loops.
- On a cleanup error it records the error and retries termination.
- After two seconds without confirmation it prints `HOLD_NO_RELEASE`.
- There is no hard-stop path that closes an unconfirmed handle.
- `allOwnedJobsTerminalAndEmpty` accepts only `terminalConfirmed`.

Verdict: the code holds the exact root and descendant handles until terminal and
active0. This is not runtime proven here.

## 4. Controls judgement and the GRANT630 result

Location `run_controls`, around line 439.

- `terminal` requires `terminalConfirmed` and `activeProcesses == 0`.
- `control-normal` requires exit 0 and no forced cleanup.
- `control-orphan` requires root exit 0, a residual child, and a forced terminate.
- `control-timeout` requires exit 124, a timeout, a forced terminate, and at
  least two observed PIDs.
- A failed control stops the run with `HOST_CONTROLS_FAILED`.

The GRANT630 run `gate-20261026-032037-58280` recorded this:

| Control | Result | Evidence |
| --- | --- | --- |
| `control-normal` | PASS | exit 0, no forced cleanup |
| `control-orphan` | PASS | root exit 0, residual child, forced terminate |
| `control-timeout` | FAIL | exit 124, active0, 4 observed PIDs, but `ownedTreeTerminated` was false |

The run status was `HOST_CONTROLS_FAILED` with exit 1. All three SDK phases stayed
UNRUN with reason `controls failed`. No SDK phase ran.

The timeout cleanup itself worked. The tree reached exit 124 and active0. It saw
four PIDs. It had no cleanup error and no HOLD. The only gap was the missing
`ownedTreeTerminated` flag, so the expectation check rejected it.

In that same run `identityVerifiedUnchanged` was true and `identityStable` was
true for repo, core, re_editor, package_config and toolchain.

### 4.1 Root fix and pure regression

The root changed `run_phase` in the timeout branch. It now sets
`record["ownedTreeTerminated"] = True` before `job.terminate()`. The current
source shows that at lines 419 and 420.

The root added `test/test_dart_host_gate.py`. I read it. It imports the gate
module, patches `OwnedJob` with a `FakeJob`, and patches `gate.time.time`. It
calls `run_phase` and asserts exit code 124, `timedOut`, `ownedTreeTerminated`,
`terminalConfirmed`, `rootTerminal`, and `activeProcesses == 0`.

The test uses only a fake Job and a fake process. It starts no real process. It is
a source-level regression for the timeout accounting gap.

This review did not run that test. It also did not run any control. The fix and
the test are recorded as the root's own work.

## 5. Deadline and publication margin

- `--deadline-epoch` is absolute Unix seconds.
- `--max-window-seconds` defaults to 240 and refuses anything larger.
- `work_deadline = deadline - reserve`.
- The reserve defaults to 45 and must be at least 14.
- Controls and phases use `work_deadline`.
- The final identity recheck and evidence hashes use the absolute `deadline`.

Verdict: controls, inspection and evidence sit inside the reserve. There is no
external publication step, so publication means the `final.json` write.

Budget risk to watch: the phase minimums are 20, 60 and 90 seconds. With a 240
second window the test phase needs 90 seconds left after verify and analyze. A
full PASS may be hard to reach. A PARTIAL with UNRUN is then the honest result.

## 6. Python final return

Location `execute`, around line 648.

- Every early stop raises an internal `_Stop(code)`.
- `except _Stop` records the code.
- `except BaseException` records the error and a failure code.
- The `finally` block can raise a pass to failure for identity drift, evidence
  failure or an unconfirmed terminal.
- The only `return report["exitCode"]` is after the `finally`.

Verdict: the returned code is the final code. A drift or evidence failure cannot
leave a stale zero.

## 7. UNRUN completeness

In the `finally` block:

- Executed phases come from `report["phases"]`.
- Every phase in `PHASE_ORDER` that did not execute and is not already listed is
  appended to `unrun`.
- The list is sorted by phase order.
- A failed phase stays in `phases` with its failure. Later phases are UNRUN.

Verdict: every unstarted phase is listed, including after an early refusal or a
control failure.

## 8. Snapshot drift rejection

- The frozen identity is captured before the grant is consumed.
- After every phase the code rebuilds the identity and compares it.
- Any difference stops the next phase with `IDENTITY_DRIFT`.
- The final `finally` compares again.
- A capture that cannot finish inside the deadline is treated as an evidence
  failure, not a pass.

Verdict: drift is rejected before the next phase and again at the end.

## 9. The 58 exercise records

Location `validate_exercise_results`, around line 526.

- The phase exit code must be 0.
- The exact path `results---exercise-only.json` is computed from the script rule.
- A pre-phase mtime and hash are recorded.
- The file must change during the phase, or the check fails as stale.
- The file must hold 58 records.
- Each record must have `kind` `exercise`.
- Each record must have `passed` true.
- Each record must have `sdkExitCode` 0.
- Each record must have an empty `sdkError`.
- Each record must have `sdkOutput` equal to `expected`.
- Each record must have `portableOutput` equal to `expected`.
- No record may carry `portableError`.
- Top-level `failures` must be 0 and `infrastructureFailure` must be false.
- The ids must be unique and cover exactly 181 through 238.
- The results file SHA256 goes into the report.

Verdict: the validator rejects a nonzero exit, a stale file, a duplicate id, and
an output mismatch.

One honesty note. For `kind` `exercise`, `verify.dart` sets `expected` equal to
`sdkOutput`. So the `sdkOutput == expected` check is tautological for exercises.
The real SDK-to-portable comparison is `portableOutput == expected`. The extra
check is harmless but adds no proof for exercises.

## 10. Existing evidence

- No `results---exercise-only.json` exists under `.dart_tool/expansion-b`.
- The `programs` directory holds 193 old `.dart` files from earlier runs.
- So there is no prior exercise evidence to validate for this window.
- I did not fabricate evidence and did not run the phase.
- The GRANT630 run left `before.json`, `after.json`, `final.json` and three
  control logs under `build/dart-host-gate/gate-20261026-032037-58280`.
- Its `final.json` has an empty `phases` list. So the SDK gate is not proven.

The earlier pure parser fixture still covers the validator cases. Those results
were positive unique ids, nonzero exit, stale mtime, duplicate id, portable
output mismatch, SDK output mismatch and non-empty SDK stderr.

## 11. Verdict after GRANT630

The earlier source review found no blocking defect. The GRANT630 window proved
the controls at runtime, except for the timeout flag gap. The root then fixed
that gap and added a pure regression.

Current status:

- The old PREPARE `ff0ed038...` is consumed and stale.
- The old identity does not match the new tool source.
- The SDK gate is not proven. No SDK phase has run.
- Request 621 is consumed by 630.

These remain UNRUN:

- the timeout control against the fixed source
- the 58 exercise verify phase
- `flutter analyze --no-pub`
- `flutter test --no-pub --concurrency=1`
- any target-device action

The next required step is a new `--prepare` with the new source and the real
`dart.exe` and `flutter.bat`. Then a new READY and a new grant. Do not replay the
consumed grant.

Runtime risks still to watch:

1. The timeout control needs two observed PIDs inside a short phase.
2. The 240 second cap plus the 90 second test minimum can force a PARTIAL.
3. After a PASS, the final identity recheck must fit the absolute deadline.
