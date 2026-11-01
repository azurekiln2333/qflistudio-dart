# Portable content and native-isolate research

Date: 2026-10-22. This research owns no production/shared-core files.

## Runtime evidence

The unmodified `tom_d4rt 1.229.0` experiment runs 220/240 existing tutorial and
example bodies with matching stdout, but its `Isolate.run` only uses
`Future.microtask` in the same isolate and `Isolate.spawn` throws. Matching
stdout alone therefore cannot prove the isolate chapter's teaching claims.
The exact first-pass results are in `research/tom-d4rt-1229-probe.json`.

The actual package code's blanket claim that interpreted functions cannot cross
an isolate was tested rather than assumed. Same-code native Isolate.spawn can
send an InterpretedFunction, Environment, visitor, and even D4rt when the reachable
object graph is sendable. However, copying them directly is incorrect: changed
parent globals/statics are copied instead of reinitialized; unused ReceivePorts
are overcaptured; and async classes reach an unsendable Completer through their
declaringVisitor. The original negative and lifecycle probes are under
`.dart_tool/native-isolate-probe/`.

## Candidate implementation boundary

The candidate remains entirely under `.dart_tool/tom-engine-patched/`; production
runner, package cache, curriculum, and shared core remain unchanged by this
research. The isolate changes are:

- `lib/src/stdlib/isolate/interpreted_isolate.dart`: real native workers,
  selected lexical captures, fresh source-library globals, stdout/error forwarding,
  pause/resume/kill lifecycle and a root-owned native spawn broker.
- `lib/src/stdlib/isolate/isolate.dart`: call this bridge for run/spawn instead
  of same-isolate simulation/unimplemented spawn.
- `lib/src/callable.dart`: additive `isolateExpression` AST getter.
- `lib/src/d4rt_base.dart`: immutable permission snapshot; `executeEntryPoint`
  and `sourceUri` options for declaration initialization without invoking main.
- `lib/src/module_loader.dart`: source URI/environment lookup by parsed unit.
- `lib/src/static_name_report.dart`: additive free-name entrypoint reusing the
  existing lexical-scope visitor rather than copying its rules.

Snapshot requests contain source syntax, source map/import context, permissions,
arguments, and only referenced lexical values. They never contain a live parent
visitor/global environment. Lexical scopes preserve shared mutable bindings,
recursive local functions, alias identity and container cycles. Ordinary native
collections go directly through the VM serializer so generic constraints and
const/unmodifiable status survive. Captured collections containing interpreted
callbacks/objects are explicitly rejected until a type-preserving serializer
exists. Bound/host functions, interpreted object/type/late captures, and local
functions captured from another source library also fail explicitly.

## Verified matrix

`dart run candidate_probe.dart` in `.dart_tool/native-isolate-probe` passes all
13 controls:

1. Child globals/statics start at 7/11, become 8/12; parent remains 100/200.
   Captured local increments in child while parent remains 13.
2. Unused global ReceivePort excluded from request.
3. Unused local ReceivePort excluded from closure captures.
4. Explicit ReceivePort capture rejected by native sendability.
5. Shared lexical scalar across helper functions and recursive local function.
6. Mutable collection aliases/cycles stay identical in child; parent unchanged.
7. Local shadowing avoids capturing an unused outer ReceivePort.
8. Child stdout forwarded; interpreted Isolate.current is a different native
   isolate from parent.
9. Real spawn handle supports debugName, paused/resume, immediate kill and onExit.
10. Native spawn error listener gets the child error.
11. Isolate.run propagates typed StateError and permits a later computation.
12. Nested real Isolate.run workers return the expected value.
13. Imported relative-source function has fresh child library globals while
    parent module state remains changed.

`dart run typed_capture_probe.dart` passes all 7 native typed controls:
mutable/const/unmodifiable `List<int>`, mutable/const `Map<String,int>`, and
mutable/const `Set<int>`. Runtime types survive; invalid inserts fail; valid
inserts work only on mutable collections; parent objects remain unchanged.

`dart run supervision_probe.dart` passes five cancellation controls: before the
first spawn, while the outer native spawn is pending, while a descendant native
spawn is pending, a confirmed running child/grandchild loop, and a burst of 50
requests stopped after five descendant requests. Twenty additional pending-spawn
races all start Stop while `pendingSpawnCount > 0`; their 40 created workers all
produce native exit events. Every case ends with zero active and pending workers.

`dart run idle_probe.dart` checks natural liveness: returning main does not finish
before an outstanding timer, and a child remains owned after its parent calls
native `Isolate.exit`. Root-owned exit markers and requests share one broker port
so an exit cannot overtake an earlier queued spawn request from that worker.
Twenty unawaited-grandchild requests sent immediately before requester exit all
finish naturally (60 created/exited workers), including an observed outer exit
while active count is zero and native creation is still pending. The host applies
pause/onExit options and resumes unpaused descendants before replying: a requester
may exit before it receives the native handle and cannot be responsible for resume.

Windows native AOT (`dart compile exe`) also runs the semantic/control probes.
Files ending `-aot-results.json` contain the separately compiled executable
results. Host AOT viability does not prove OHOS execution. OHOS release HAP/APP
compilation and target-device execution remain separate gates. HDC availability
must be checked by the integrator.

The tracked aggregate is `research/isolate-host-aot-results.json`.
`test/portable_isolate_supervisor_test.dart` retains 13 passing Flutter VM tests,
including 20 cancellation races and 20 unawaited-grandchild races. The retained
idle test uses a release-port handshake rather than an elapsed-time assumption.

After the initial isolate bridge, the full 240-body candidate sweep passes all
isolate entries 091..096; 16 other failures remained while parallel numeric,
class dispatch and Future fixes were still in progress. Use the latest
`research/tom-d4rt-patched-probe.json` rather than freezing that intermediate count.

## Supervisor integration contract

Create one host in the application/root isolate and create the outer interpreter
through its public `spawn` method:

```dart
final host = InterpretedIsolateSupervisorHost();
final outer = await host.spawn(
  interpreterEntryPoint,
  requestIncludingBrokerPort(host.sendPort),
  onExit: outerExitPort,
  onError: outerErrorPort,
  debugName: 'offline-interpreter',
);
// In interpreterEntryPoint, before executing user code:
InterpretedIsolateSupervisor.spawnBrokerPort = request.brokerPort;
// Natural completion preserves timers, unawaited work and descendant liveness:
await host.waitForIdle();
// Stop/timeout/disposal kills every owned worker and waits for native exits:
await host.stop();
```

`host.spawn<T>` mirrors native spawn options `paused`, `errorsAreFatal`, `onExit`,
`onError`, and `debugName`. Every native creation starts paused until the host
records ownership and installs exit listeners. Descendant interpreted run/spawn
requests carry the same broker port; only the root host creates their native
workers. If Stop begins before a pending native spawn returns its handle, the
host kills that newly returned worker before it can run and rejects the request.
Stop is idempotent and returns after pending creation and all native exits finish.
Sending newly created handles to a parent registry is insufficient: the creating
interpreter could die before it reports its handle, leaving an orphan.

`waitForIdle()` observes completion without cancellation and should be called
after starting the owned outer worker. Native exit markers and spawn requests use
the same broker queue. Stop keeps this port open while exits drain and rejects
incoming creation requests, then closes it. Counters expose active/pending/
created/exited workers for retained lifecycle controls. `killAll()` is only an
unsupervised standalone fallback; it cannot replace the application-owned host.

The child request also carries the immutable `OfflineHostPolicy` configuration.
Fresh runtime initialization, closure reconstruction, and direct function calls
all run inside that policy's I/O zone, preserving paths, output and permission
ceilings in child and grandchild interpreters.
With a policy, interpreted `print` goes directly to its application-owned output
port. Relaying through a requesting interpreter would lose late descendant output
after that interpreter exits. A dedicated probe releases the grandchild only after
outer native exit, then verifies `print`, stdout, stderr and the inherited scratch
directory. Null-policy standalone use retains the parent print relay.

`Isolate.spawnUri` now rejects its Future with a deliberate `UnsupportedError`: loading native
user source bypassed interpreter permissions and broker ownership. The valid-file
control in `spawn_uri_probe.dart` executes and exits under native host spawnUri,
but the interpreter rejects it with both communicate-only and full isolate grants;
no native source message or isolate handle is produced and host counts remain zero.
The Future rejection is catchable by interpreted `try/await/on UnsupportedError`.

The public supervisor currently lives at
`package:tom_d4rt/src/stdlib/isolate/interpreted_isolate.dart`; promoting the engine
should export a deliberate public entrypoint. The root regression suite retains
the lifecycle, capture, output and rejection contracts. No package-cache edits
were made.

## Independent regression bisect

The intermediate candidate's static calls (Temperature.celsius, Counter.describe,
User.fromJson, Arguments.parse) incorrectly became native Function method calls.
A separate copied engine in `.dart_tool/native-isolate-probe/engine-bisect/`
restored every candidate change except `stdlib/async/future.dart`; the failures
remained. Restoring only that file made all four controls pass. The correct
unawaited NativeFunction conversion removed an old `nativeType: Function` bridge
that had shadowed broad Callable wrapping. The root/editor owners were informed
to exclude class/type callables from native Function matching; the isolate hooks
were independently ruled out. Do not revert the correct unawaited behavior as a
workaround.

## Remaining boundaries

The surrounding engine eagerly initializes top-level values, unlike Dart's lazy
global initialization. This predates the bridge and is not evidence of general
language-semantic parity. The matrix proves the listed behavior only. It does
not establish support for every possible Dart closure, platform resource, bridge
registration, or debugging API. Device runtime checks and the complete expanded
curriculum sweep remain mandatory before claiming OHOS content completeness.
