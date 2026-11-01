# Portable Dart Runtime Contract

## 1. Scope / Trigger

Use this when changing portable execution, the vendored interpreter, IO bridges,
isolate lifecycle or curriculum portable verification. Android/desktop SDK
execution is separate. `vendor/tom_d4rt` is production source pinned to
`1.229.0+qfli.1` and analyzer 8.4.1; retain upstream MIT provenance. Never patch
the global pub cache or replace production files from an experimental copy.
Legacy EVC compilation remains a separate dart_eval syntax subset.

## 2. Signatures

```dart
Future<PortableDartRun> startPortableDart({
  required Map<String, Map<String, String>> packages,
  required String entryUri,
  String? projectPath,
});
// PortableDartRun: Stream<String> stdout, stderr; Future<int> exitCode;
// Future<void> Function() cancel.
```

`lib/portable_dart_runtime.dart` is pure Dart, shared by `DartProgramRunner` and
`tool/portable_content_runner.dart`. The latter supplies a per-unit timeout and
always cancels in finally. `DartProjectSources` owns canonical project loading.

Vendor `InterpretedIsolateSupervisorHost` exposes `spawn`, `waitForIdle`, `stop`,
`sendPort`, optional `orderedExitPort` / `unhandledErrorPort`, and native worker
created/exited/active/pending counts. `OfflineHostPolicy` takes `scratchPath`,
optional `projectPath`, and an output `SendPort`.

## 3. Contracts

- Flatten preloaded package sources into canonical package URIs. Execute direct
  `source`, `sourceUri`, and `sources`; the upstream `execute(library:)` path
  initializes the same root twice and is not the product entrypoint. Record the
  root URI for reconstruction in descendant interpreters. Imports never read
  arbitrary filesystem sources or download dependencies.
- Each run creates a dedicated scratch directory. Grant reads/writes only for
  the resolved project and scratch roots under `OfflineHostPolicy`. IOOverrides
  provide per-run current/temp directories; relative and raw paths must share
  the same checks. Reject symlink path components, including broken links, and
  do not follow links when listing. Rename/copy check both paths.
- The policy ceiling rejects network/DNS/socket operations, native process or
  filesystem execution, process exit, process-global cwd mutation, and stdin.
  Explicit broad permission grants must not bypass this ceiling. Output sinks
  belong to the run; closing stdout cannot close the application's stdout.
- Isolate.run/spawn reconstruct source and required lexical captures in actual
  native workers with fresh globals/statics. Preserve collection types,
  immutability, aliasing and cycles. Unsupported interpreted objects/types,
  bound/host functions, late captures and unsupported cross-library closure
  shapes fail explicitly. `spawnUri` returns a catchable unsupported Future.
- The application owns one spawn broker. Create workers paused, register exit
  listeners, then resume. Descendants use this same broker. Stop kills both
  live workers and pending spawns when they complete, waits for all native exit
  observations, and is idempotent. Do not infer idle from a parent's exit while
  a descendant spawn request is queued; exit markers and spawn requests share
  the broker queue.
- A returned main may still own timers/children. On normal completion wait for
  native idle and consume every created worker's ordered output-port exit
  marker before closing streams. Descendant output goes directly to the
  application, so it survives its parent interpreter exiting. Registering two
  exit listeners with the same port replaces the earlier response; never use
  the output port for both a null response and the worker marker.
- Unhandled child errors without a user onError port fail the product run.
  Explicit user error ports may handle a failure and allow normal completion.
- Preserve stdout/stderr as independent line streams, including final partial
  lines and CRLF. A failure is never a clean run. No language feature is
  considered implemented merely because a lesson prints its expected text.

## 4. Validation & Error Matrix

| Condition | Result |
| --- | --- |
| Unknown preloaded entry / invalid project | Caller failure mapped to runner 127 |
| Syntax or missing source/module | Real stderr, exit 127 |
| User runtime exception / unhandled child error | Real stderr, exit 1 |
| Backend spawn or cleanup failure | Real stderr, exit 127 |
| User Stop | Await entire owned native tree, exit 130 |
| Normal main plus live timer/child | Remain running until native idle and output drain |
| Forbidden host capability | Actual denied/unsupported error, nonzero unless caught |
| Unsupported capture or spawnUri | Explicit error, no unsupervised native execution |
| Timeout in verifier | Cancel whole tree; record failure, never skip |

## 5. Good / Base / Bad Cases

Good: write/read a real scratch file, run a child with fresh global state and
captured local data, preserve late child output, then reclaim resources.
Base: preloaded main prints its calculated result and exits zero.
Bad: execute a native source via spawnUri, treat a simulated same-isolate call
as Isolate.run, or close output when main returns while its child is still live.

## 6. Tests Required

- `portable_dart_runtime_test.dart`: exact imports/main args, syntax/runtime
  status, actual IO, denied capabilities, globals/captures, late output,
  handled/unhandled child errors, indexed updates and full-tree cancellation.
- `portable_isolate_supervisor_test.dart`: native worker ownership, pending
  creation and queued grandchild races, idle, actual typed captures, rejection.
- `portable_offline_policy_test.dart`: real raw-path/link/temporary IO, stdout
  decoding/close, denied network/process calls without real external effects.
- `dart_content_portable_test.dart` and CLI verifier: every tutorial and paired
  example through the production helper, exact output, no whitelist. Legacy
  EVC tests do not stand in for this gate.
- Host SDK, portable JIT, Windows AOT, OHOS package and installed target execution
  are distinct gates. Keep portable profile status unavailable until the
  target build/execution are actually verified.

## 7. Wrong vs Correct

Wrong: a child inherits its parent's mutable global through a copied closure.
Correct: reconstruct globals from source and carry only valid lexical captures.

Wrong: mark idle after receiving the parent's exit on a separate port while a
grandchild request is still queued. Correct: use the broker's ordered lifecycle
queue and wait for pending creation and every native exit.

Wrong: a List.filled wrapper rejects `items[i]++` or prefix evaluates `i` twice.
Correct: unwrap native collection receivers for the same native write checks,
evaluate receiver/index once, and return old/new values for postfix/prefix.
