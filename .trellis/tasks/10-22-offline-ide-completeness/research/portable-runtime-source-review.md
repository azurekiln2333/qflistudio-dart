# Portable runtime source review (read-only)

Owner: read-only cross review. Scope of writes: this file only.
The four frozen tooling files (`tool/ohos/build_dart_audit.ps1`,
`tool/ohos/inspect_dart_hap.py`, `tool/ohos/verify_dart_hap.ps1`,
`tool/ohos/test_inspect_dart_hap.py`) and
`research/dart-package-tooling-review.md` were not modified.

## 1. Method and limits

This is a static source review. No Dart, Flutter, Java, SDK, build, HDC or
emulator command was run. No mutating git command was run; only read-only
queries and text search were used. Conclusions below come from reading code and
existing tests, not from executing them.

Files read:

- `lib/portable_dart_runtime.dart` (full)
- `lib/dart_runner.dart` (full)
- `lib/dart_project_sources.dart` (full)
- `tool/portable_content_runner.dart` (full)
- `vendor/tom_d4rt/lib/src/security/offline_host_policy.dart` (full)
- `vendor/tom_d4rt/lib/src/stdlib/isolate/interpreted_isolate.dart` (full)
- `vendor/tom_d4rt/lib/src/stdlib/isolate/isolate.dart` (full)
- `vendor/tom_d4rt/lib/src/async_state.dart` (full)
- `vendor/tom_d4rt/lib/src/callable.dart` (async drive region)
- `vendor/tom_d4rt/lib/src/interpreter_visitor.dart` (await replay regions)
- `vendor/tom_d4rt/lib/src/d4rt_base.dart` (checkPermission, host-policy entry)
- `vendor/tom_d4rt/lib/src/module_loader.dart` (import gates, path-agnostic gate)
- `vendor/tom_d4rt/lib/src/stdlib/io/{process,platform,directory,file}.dart`
- `test/portable_dart_runtime_test.dart`, `test/portable_isolate_supervisor_test.dart`,
  `test/portable_offline_policy_test.dart`, `test/portable_async_semantics_test.dart`

## 2. Stop and exit lifecycle — no defect found

`lib/portable_dart_runtime.dart`:

- `finish` is memoized with `finishing ??=` (line 58), so natural completion,
  a `failed` message, and `cancel` all share one shutdown. `exitCode` is
  completed once (line 72) and the scratch directory is deleted once (line 65).
- Stop is `cancel: () => finish(130)` (line 134). The only exit-code rewrite is
  `if (code == 0) code = 127` on a scratch-delete failure (lines 65-70), so a
  Stop stays 130.
- Natural completion awaits `host.waitForIdle()` and then every `workerExited`
  marker before closing streams (lines 117-127, markers at 85-90). Late child
  stdout/stderr therefore drains before `output.close()`/`errors.close()`.
- An uncaught descendant error arrives on `unhandledErrorPort` (lines 51, 111)
  and forces `finish(1)`, so a child failure cannot become a clean run.

Covered by existing tests: `portable_dart_runtime_test.dart` "Stop interrupts a
synchronous loop and is idempotent", "Stop reclaims busy nested native isolates
before returning", "late child print, stdout and stderr drain before product
streams close", "uncaught spawn errors fail the run...".

Verdict: the double-finish and lost-output classes are handled in source and
pinned by tests. No defect.

## 3. Native descendant ownership and leaks — no defect found

`vendor/tom_d4rt/lib/src/stdlib/isolate/interpreted_isolate.dart`:

- `_createOwned` spawns paused, registers the worker in `_workers`, installs
  both exit listeners (the `_requests` id listener and `orderedExitPort`), and
  only then returns (lines 188-231). A `_stopped` check kills and throws before
  the worker is handed out.
- `_serve` resumes the worker only after ownership and listeners exist
  (lines 161-186), so a requester that dies before receiving the handle cannot
  orphan a child.
- `_stop` sets `_stopped`, kills once, awaits pending spawns, kills a second
  time for spawns that finished after the first pass, awaits every recorded
  exit, then closes `_requests` (lines 235-248). Descendants created during a
  pending native spawn are therefore drained, not leaked.

Covered by existing tests: `portable_isolate_supervisor_test.dart` "Stop drains
native creation of the outer worker/descendant", "Stop kills a confirmed busy
child and grandchild", "Stop drains a queued burst of 50 computation requests",
"repeated pending native spawn races leave no owned worker" (20 iterations),
"queued unawaited grandchildren survive requester exit and drain naturally".

Verdict: the descendant-leak class is handled in source and pinned by tests.

## 4. Offline capability — no bypass found

- `OfflineHostPolicy.allows` (`offline_host_policy.dart` 53-95) returns false for
  any non-filesystem type, for `execute: true`, for paths outside the scratch and
  project roots, and for any path with a symbolic-link component checked before
  native metadata (97-116).
- `_OfflineIOOverrides` resolves relative paths against project/scratch and
  throws on `setCurrentDirectory`, `stdin` and `exit` (152-198).
- `D4rt.checkPermission` is the ceiling AND the granted set
  (`d4rt_base.dart` 1733-1741), so a broad grant cannot exceed the policy.
- `Process.start`/`run`/`runSync` are all gated (process.dart 14-24). The
  `FilesystemPermission`-with-`execute` fallback (process.dart 226) is still
  blocked because `allows` rejects `execute: true`.
- `Platform.environment` and the other host properties are gated by
  `DangerousPermission` (platform.dart 40-42 and neighbours); the ceiling denies
  `type: dangerous`.
- `Directory.list`/`listSync` force `followLinks: false` under a host policy
  (directory.dart 124, 138), so recursive listing cannot traverse an out-of-scope
  link after the single starting-directory check.
- `Isolate.spawnUri` is rejected unconditionally (isolate.dart), and there is no
  `dart:ffi`/`dart:mirrors` bridge in the vendor tree, so native-code and
  reflection escapes are not reachable.

Covered by existing tests: `portable_offline_policy_test.dart` "broad grants
cannot read or write outside roots...", "offline ceiling denies broad network,
process and privileged grants", "broad socket grant is denied before the native
connection hook", "outside paths are rejected before native metadata queries",
"broken link ancestor is rejected...", the list/listSync link tests, "stdin and
cwd changes fail...", "child inherits virtual roots, output and the policy
ceiling".

Verdict: no offline capability bypass found.

## 5. Terminal routing (`lib/dart_runner.dart`) — no defect found

`dartTerminalDelegate` refuses `pub`/`global`, accepts only
run/compile-kernel/format/analyze/`--version`, requires a single non-flag
operand and resolves it through `resolveSandboxPath` (containment). Compile
writes only under `backend.cwd/build`. `DartProgramRunner.run` returns null for
unsupported extensions and maps failures to `kProgramNotRunExitCode`
(lines 343-405). This matches the offline policy and adds no capability.

## 6. Async semantics (state machine) — reviewed, not proven

`callable.dart` `_resumeStateMachine` (3798-3825) drains synchronous
catch/finally transfers iteratively and completes body failures into the
returned Future. `async_state.dart` documents the per-site await replay,
loop-stack truncation, cascade memoisation and catch-scope maps, each keyed by
identity. This machinery is deep; a read-only pass cannot prove it. It is
covered by `portable_async_semantics_test.dart`, which diffs the portable
output against the real SDK for each case. No defect identified in the regions
read; correctness here rests on that suite, not on this review.

## 7. Observations that are not counted as bugs

Per the instruction not to treat theoretical risks as bugs, these are recorded
as observations only, not as findings.

1. `Process` instance `kill` (process.dart 32) has no permission check, unlike
   static `killPid` (26). A `Process` handle exists only after a permitted
   start, and the offline ceiling denies every start, so this is not an offline
   bypass.
2. A user program that leaves a `ReceivePort` open keeps its worker alive, so
   the run does not self-exit until Stop. This matches Dart VM semantics and is
   not a defect.

A prior draft listed a third item claiming `spawnInterpretedIsolate` could leave
`output` unclosed when the worker exited before its handle was assigned. That
claim was wrong and has been removed. In `interpreted_isolate.dart` 731-737 the
`output.close()` call is outside the `if (worker != null)` guard, so the port is
closed on every exit notification regardless of whether the handle is assigned
yet. Only the `_workers.remove(worker)` call depends on the non-null handle. No
unclosed-port condition exists there.

## 8. Conclusion

No definitive source-level error was found in the reviewed areas. The three
named risk classes (Stop/exit lifecycle, offline capability bypass, native
isolate descendant leak) are handled by design and pinned by existing tests.
The async state machine was reviewed at the invariant level only.

Source review cannot replace execution. The current portable and offline test
suites and real device evidence remain the authority; nothing here should be
read as a substitute for running them.
