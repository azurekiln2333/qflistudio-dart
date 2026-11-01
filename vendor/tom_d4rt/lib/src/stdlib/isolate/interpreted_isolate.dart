import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/src/static_name_report.dart';

/// Native workers created by interpreted Isolate.run/spawn.
///
/// An embedding worker sets [spawnBrokerPort] to the parent-owned
/// [InterpretedIsolateSupervisorHost.sendPort]. The host creates and owns all
/// descendants, including paused workers whose requesting interpreter dies.
class InterpretedIsolateSupervisor {
  static SendPort? spawnBrokerPort;
  static final Set<Isolate> _workers = {};

  static void _register(Isolate worker) {
    _workers.add(worker);
  }

  static void killAll() {
    for (final worker in _workers) {
      worker.kill(priority: Isolate.immediate);
    }
    _workers.clear();
  }
}

/// Owns native creation, cancellation and exit observation for a whole run.
///
/// Keep this service in the application/root isolate and create the outer
/// interpreter with [spawn]. On Stop, await [stop]. The service closes incoming
/// requests, kills all owned workers, and also kills workers whose pending
/// native spawn finishes after Stop. It returns only after every native exit.
class InterpretedIsolateSupervisorHost {
  InterpretedIsolateSupervisorHost({
    this.onSpawnRequested,
    this.orderedExitPort,
    this.unhandledErrorPort,
  }) {
    _requests.listen(_handle);
  }

  /// Optional telemetry hook, invoked after a native spawn is pending and owned.
  final void Function()? onSpawnRequested;
  /// Receives a native `{'type': 'workerExited'}` marker for every owned worker.
  /// When output uses this same port, consuming all created workers' markers
  /// proves that their earlier output has drained before streams are closed.
  final SendPort? orderedExitPort;
  /// Receives native descendant errors when no program onError port is set.
  final SendPort? unhandledErrorPort;
  final ReceivePort _requests = ReceivePort();
  final Map<Isolate, Completer<void>> _workers = {};
  final Map<int, Isolate> _workerIds = {};
  final Set<Future<void>> _pending = {};
  Completer<void>? _idle;
  int _nextWorkerId = 0;
  bool _stopped = false;
  Future<void>? _stopFuture;
  int _created = 0;
  int _exited = 0;

  SendPort get sendPort => _requests.sendPort;
  bool get isStopped => _stopped;
  int get activeWorkerCount => _workers.length;
  int get pendingSpawnCount => _pending.length;
  int get createdWorkerCount => _created;
  int get exitedWorkerCount => _exited;

  /// Wait for owned workers to exit naturally and native creation to settle.
  ///
  /// Call this after starting the outer interpreter. Timers, unawaited work,
  /// and child-only liveness keep this future pending. Native exit markers and
  /// spawn requests use the same broker port, so an exit cannot hide an earlier
  /// queued request from that worker. This method does not cancel any worker.
  Future<void> waitForIdle() {
    if (_workers.isEmpty && _pending.isEmpty) return Future.value();
    return (_idle ??= Completer<void>()).future;
  }

  void _notifyIdle() {
    if (_workers.isNotEmpty || _pending.isNotEmpty) return;
    _idle?.complete();
    _idle = null;
  }

  /// Create an owned outer interpreter or another application worker.
  ///
  /// Pass [sendPort] in [message] and set
  /// [InterpretedIsolateSupervisor.spawnBrokerPort] in the interpreter worker.
  /// Descendant interpreted run/spawn requests then use this same host. Native
  /// creation is always paused until ownership and exit listeners are installed.
  /// A concurrent [stop] rejects this future and terminates the new worker.
  Future<Isolate> spawn<T>(
    void Function(T) entryPoint,
    T message, {
    bool paused = false,
    bool errorsAreFatal = true,
    SendPort? onExit,
    SendPort? onError,
    String? debugName,
  }) async {
    if (_stopped) throw StateError('Interpreter run stopped.');
    final worker = await _track(
      _createOwned(
        entryPoint,
        message,
        errorsAreFatal: errorsAreFatal,
        onExit: onExit,
        onError: onError,
        debugName: debugName,
      ),
    );
    if (_stopped) {
      worker.kill(priority: Isolate.immediate);
      throw StateError('Interpreter run stopped.');
    }
    if (!paused) worker.resume(worker.pauseCapability!);
    return worker;
  }

  Future<Isolate> _track(Future<Isolate> operation) {
    // Stop waits for creation to settle even when the requesting interpreter
    // dies before it receives the handle. A rejected caller future must not
    // turn cancellation itself into an unhandled async error.
    final pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _pending.add(pending);
    unawaited(
      pending.whenComplete(() {
        _pending.remove(pending);
        _notifyIdle();
      }),
    );
    onSpawnRequested?.call();
    return operation;
  }

  void _handle(Object? message) {
    if (message is int) {
      final worker = _workerIds.remove(message);
      if (worker == null) return;
      final exited = _workers.remove(worker);
      _exited++;
      exited?.complete();
      _notifyIdle();
      return;
    }
    if (message is! _SpawnRequest) return;
    if (_stopped) {
      _replyFailure(message.reply, StateError('Interpreter run stopped.'), '');
      return;
    }
    unawaited(_serve(message));
  }

  Future<void> _serve(_SpawnRequest message) async {
    try {
      final worker = await _track(
        _createOwned(
          message.runComputation ? _runWorker : _spawnWorker,
          message.request,
          errorsAreFatal: message.errorsAreFatal,
          onExit: message.request.output,
          onError: message.onError ?? unhandledErrorPort,
          debugName: message.debugName,
        ),
      );
      if (_stopped) {
        worker.kill(priority: Isolate.immediate);
        throw StateError('Interpreter run stopped.');
      }
      if (message.onExit != null) worker.addOnExitListener(message.onExit!);
      // The requester may exit without awaiting spawn's future. Resume here,
      // after root ownership/listeners exist, rather than relying on a reply
      // reaching a still-alive requesting interpreter.
      if (!message.paused) worker.resume(worker.pauseCapability!);
      message.reply.send(worker);
    } catch (error, stack) {
      _replyFailure(message.reply, error, '$stack');
    }
  }

  Future<Isolate> _createOwned<T>(
    void Function(T) entryPoint,
    T message, {
    required bool errorsAreFatal,
    required SendPort? onExit,
    required SendPort? onError,
    required String? debugName,
  }) async {
    final exited = Completer<void>();
    Isolate? worker;
    try {
      worker = await Isolate.spawn(
        entryPoint,
        message,
        paused: true,
        errorsAreFatal: errorsAreFatal,
        onError: onError,
        debugName: debugName,
      );
      _created++;
      _workers[worker] = exited;
      final id = _nextWorkerId++;
      _workerIds[id] = worker;
      worker.addOnExitListener(_requests.sendPort, response: id);
      if (orderedExitPort != null) {
        worker.addOnExitListener(
          orderedExitPort!,
          response: const {'type': 'workerExited'},
        );
      }
      // Install the computation's native exit listener before any client can
      // resume it. Keeping result and exit events on the same native port
      // preserves their order; relaying exits through the host would not.
      if (onExit != null) worker.addOnExitListener(onExit);
      if (_stopped) {
        worker.kill(priority: Isolate.immediate);
        throw StateError('Interpreter run stopped.');
      }
      return worker;
    } catch (_) {
      worker?.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  Future<void> stop() => _stopFuture ??= _stop();

  Future<void> _stop() async {
    _stopped = true;
    for (final worker in _workers.keys.toList()) {
      worker.kill(priority: Isolate.immediate);
    }
    await Future.wait(_pending.toList());
    _pending.clear();
    // A pending native spawn can finish only after the first kill pass.
    final remaining = Map<Isolate, Completer<void>>.of(_workers);
    for (final worker in remaining.keys) {
      worker.kill(priority: Isolate.immediate);
    }
    await Future.wait(remaining.values.map((exit) => exit.future));
    _notifyIdle();
    await waitForIdle();
    _requests.close();
  }
}

void _replyFailure(SendPort reply, Object error, String stack) {
  try {
    reply.send(_Failure(error, stack));
  } catch (_) {
    reply.send(_Failure(RemoteError('$error', stack), stack));
  }
}

class _ScopeSnapshot {
  _ScopeSnapshot(this.parent);
  final _ScopeSnapshot? parent;
  final Map<String, Object?> values = {};
}

class _FunctionSnapshot {
  _FunctionSnapshot(this.expression, this.scope);
  final FunctionExpression expression;
  final _ScopeSnapshot? scope;
}

class _SnapshotBuilder {
  _SnapshotBuilder(this.visitor, InterpretedFunction entry)
    : unit = entry.isolateExpression!.root as CompilationUnit {
    globals =
        visitor.moduleLoader.environmentFor(unit) ?? visitor.globalEnvironment;
  }

  final InterpreterVisitor visitor;
  final CompilationUnit unit;
  late final Environment globals;
  final Map<Object, Object> _seen = HashMap.identity();

  _ScopeSnapshot? _scope(Environment environment) {
    if (identical(environment, globals)) return null;
    final cached = _seen[environment];
    if (cached is _ScopeSnapshot) return cached;
    final enclosing = environment.enclosing;
    if (enclosing == null) {
      throw UnsupportedError(
        'The isolate closure has no source-library scope.',
      );
    }
    final result = _ScopeSnapshot(_scope(enclosing));
    _seen[environment] = result;
    return result;
  }

  _FunctionSnapshot function(InterpretedFunction function) {
    final cached = _seen[function];
    if (cached is _FunctionSnapshot) return cached;
    final expression = function.isolateExpression;
    if (expression == null || function.ownerType != null) {
      throw UnsupportedError(
        'Bound methods and constructors cannot be sent '
        'to the interpreted isolate bridge.',
      );
    }
    if (!identical(expression.root, unit)) {
      throw UnsupportedError(
        'Capturing a local function from another source '
        'library is not supported by the interpreted isolate bridge.',
      );
    }
    final thisUse = _ThisUse();
    expression.accept(thisUse);
    if (thisUse.found) {
      throw UnsupportedError(
        'An isolate closure cannot capture interpreted this.',
      );
    }
    final result = _FunctionSnapshot(expression, _scope(function.closure));
    _seen[function] = result;
    for (final name in reportFreeNames(expression)) {
      for (
        Environment? scope = function.closure;
        scope != null && !identical(scope, globals);
        scope = scope.enclosing
      ) {
        if (scope.values.containsKey(name)) {
          _scope(scope)!.values[name] = value(scope.values[name]);
          break;
        }
      }
    }
    return result;
  }

  Object? value(Object? value) {
    if (value == null) return null;
    final cached = _seen[value];
    if (cached != null) return cached;
    if (value is InterpretedFunction) return function(value);
    if (value is Callable ||
        (value is RuntimeValue && value is! BridgedInstance) ||
        value is RuntimeType ||
        value is LateVariable ||
        value is Environment ||
        value is InterpreterVisitor ||
        value is D4rt) {
      throw UnsupportedError(
        'Cannot send captured interpreted '
        '${value.runtimeType} to a native isolate.',
      );
    }
    _checkContainer(value, HashSet.identity());
    // The native isolate enforces sendability for ordinary host values. An
    // explicitly captured ReceivePort/Future/Completer is rejected, never run
    // in the parent as a fallback.
    return value;
  }

  // Pass ordinary collections through the VM unchanged. Rebuilding them as
  // List<Object?>/Map<Object?,Object?> would silently erase runtime generic
  // constraints and turn const/unmodifiable collections mutable. Nested
  // interpreted callbacks require a type-preserving serializer we do not have.
  static void _checkContainer(Object? value, Set<Object> seen) {
    if (value == null || !seen.add(value)) return;
    if (value is Callable ||
        (value is RuntimeValue && value is! BridgedInstance) ||
        value is RuntimeType ||
        value is LateVariable ||
        value is Environment ||
        value is InterpreterVisitor ||
        value is D4rt) {
      throw UnsupportedError(
        'A captured collection contains unsupported '
        'interpreted ${value.runtimeType}.',
      );
    }
    if (value is List || value is Set) {
      for (final element in value as Iterable) {
        _checkContainer(element, seen);
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        _checkContainer(entry.key, seen);
        _checkContainer(entry.value, seen);
      }
    } else if (value is InterpretedRecord) {
      _checkContainer(value.positionalFields, seen);
      _checkContainer(value.namedFields, seen);
    }
  }
}

class _ThisUse extends RecursiveAstVisitor<void> {
  bool found = false;
  @override
  void visitThisExpression(ThisExpression node) {
    found = true;
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    found = true;
  }
}

class _Request {
  _Request({
    required this.function,
    required this.source,
    required this.sources,
    required this.permissions,
    required this.arguments,
    required this.output,
    required this.sourceUri,
    required this.basePath,
    required this.allowFileSystemImports,
    required this.supervisor,
    required this.hostPolicy,
  });
  final _FunctionSnapshot function;
  final String source;
  final Map<String, String> sources;
  final List<Permission> permissions;
  final List<Object?> arguments;
  final SendPort output;
  final String? sourceUri;
  final String? basePath;
  final bool allowFileSystemImports;
  final SendPort? supervisor;
  final OfflineHostPolicy? hostPolicy;
}

class _Print {
  const _Print(this.line);
  final String line;
}

class _Result {
  const _Result(this.value);
  final Object? value;
}

class _Failure {
  const _Failure(this.error, this.stack);
  final Object error;
  final String stack;
}

class _SpawnRequest {
  _SpawnRequest(
    this.request,
    this.reply, {
    required this.runComputation,
    required this.errorsAreFatal,
    required this.paused,
    required this.onExit,
    required this.onError,
    required this.debugName,
  });
  final _Request request;
  final SendPort reply;
  final bool runComputation;
  final bool errorsAreFatal;
  final bool paused;
  final SendPort? onExit;
  final SendPort? onError;
  final String? debugName;
}

Future<Isolate> _spawnNative(
  _Request request, {
  required bool runComputation,
  required bool errorsAreFatal,
  required bool paused,
  required SendPort? onExit,
  required SendPort? onError,
  required String? debugName,
}) async {
  final broker = InterpretedIsolateSupervisor.spawnBrokerPort;
  if (broker == null) {
    return Isolate.spawn(
      runComputation ? _runWorker : _spawnWorker,
      request,
      paused: true,
      errorsAreFatal: errorsAreFatal,
      onExit: request.output,
      onError: onError,
      debugName: debugName,
    );
  }
  final reply = ReceivePort();
  try {
    broker.send(
      _SpawnRequest(
        request,
        reply.sendPort,
        runComputation: runComputation,
        errorsAreFatal: errorsAreFatal,
        paused: paused,
        onExit: onExit,
        onError: onError,
        debugName: debugName,
      ),
    );
    final result = await reply.first;
    if (result is Isolate) return result;
    if (result is _Failure) {
      Error.throwWithStackTrace(
        result.error,
        StackTrace.fromString(result.stack),
      );
    }
    throw StateError('Invalid interpreter isolate broker response.');
  } finally {
    reply.close();
  }
}

class _Restore {
  _Restore(this.globals);
  final Environment globals;
  final Map<Object, Object> _seen = HashMap.identity();

  Environment scope(_ScopeSnapshot? snapshot) {
    if (snapshot == null) return globals;
    final cached = _seen[snapshot];
    if (cached is Environment) return cached;
    final result = Environment(enclosing: scope(snapshot.parent));
    _seen[snapshot] = result;
    for (final entry in snapshot.values.entries) {
      result.define(entry.key, value(entry.value));
    }
    return result;
  }

  Object? value(Object? snapshot) {
    if (snapshot == null) return null;
    final cached = _seen[snapshot];
    if (cached != null) return cached;
    if (snapshot is _FunctionSnapshot) {
      // Register the closure's scope first so recursive local functions see
      // the same mutable lexical bindings rather than an independent copy.
      final closure = scope(snapshot.scope);
      final existing = _seen[snapshot];
      if (existing is InterpretedFunction) return existing;
      final result = InterpretedFunction.expression(
        snapshot.expression,
        closure,
      );
      _seen[snapshot] = result;
      return result;
    }
    return snapshot;
  }
}

_Request _request(
  InterpreterVisitor visitor,
  Object? callable,
  List<Object?> arguments,
  SendPort output,
) {
  if (callable is! InterpretedFunction ||
      callable.isolateExpression == null ||
      callable.ownerType != null) {
    throw UnsupportedError(
      'The native isolate bridge requires a source '
      'function or closure; bound and host functions are unsupported.',
    );
  }
  final runtime = visitor.moduleLoader.d4rt;
  if (runtime != null &&
      !runtime.checkPermission({'type': 'isolate', 'spawn': true})) {
    throw RuntimeD4rtException('Permission denied: creating an isolate.');
  }
  final builder = _SnapshotBuilder(visitor, callable);
  return _Request(
    function: builder.function(callable),
    source: builder.unit.toSource(),
    sources: Map.of(visitor.moduleLoader.sources),
    permissions: runtime?.grantedPermissionsSnapshot ?? const [],
    arguments: [for (final arg in arguments) builder.value(arg)],
    output: output,
    sourceUri: visitor.moduleLoader.sourceUriFor(builder.unit)?.toString(),
    basePath: visitor.moduleLoader.basePath,
    allowFileSystemImports: visitor.moduleLoader.allowFileSystemImports,
    supervisor: InterpretedIsolateSupervisor.spawnBrokerPort,
    hostPolicy: runtime?.hostPolicy,
  );
}

Future<Object?> _invoke(_Request request) async {
  InterpretedIsolateSupervisor.spawnBrokerPort = request.supervisor;
  final runtime = D4rt(hostPolicy: request.hostPolicy);
  return await runtime.runWithHostPolicy(() async {
    for (final permission in request.permissions) {
      runtime.grant(permission);
    }
    runtime.execute(
      source: request.source,
      sources: request.sources,
      sourceUri: request.sourceUri,
      basePath: request.basePath,
      allowFileSystemImports: request.allowFileSystemImports,
      executeEntryPoint: false,
    );
    final restore = _Restore(runtime.visitor!.globalEnvironment);
    final function = restore.value(request.function) as InterpretedFunction;
    final arguments = [for (final arg in request.arguments) restore.value(arg)];
    return await Future.value(function.call(runtime.visitor!, arguments));
  });
}

void _forwardPrint(_Request request, String line) {
  final hostOutput = request.hostPolicy?.output;
  if (hostOutput != null) {
    // A supervised descendant may outlive its requesting interpreter. Keep
    // output rooted in the application rather than relaying through that
    // interpreter's run/spawn result port after it has exited.
    hostOutput.send({'type': 'stdout', 'data': '$line\n'});
  } else {
    request.output.send(_Print(line));
  }
}

Future<void> _runWorker(_Request request) async {
  await runZoned(
    () async {
      try {
        final value = await _invoke(request);
        _SnapshotBuilder._checkContainer(value, HashSet.identity());
        Isolate.exit(request.output, _Result(value));
      } catch (error, stack) {
        final unwrapped = unwrapScriptError(error);
        try {
          Isolate.exit(request.output, _Failure(unwrapped, '$stack'));
        } catch (_) {
          Isolate.exit(
            request.output,
            _Failure(RemoteError('$unwrapped', '$stack'), '$stack'),
          );
        }
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => _forwardPrint(request, line),
    ),
  );
}

Future<void> _spawnWorker(_Request request) async {
  await runZoned(
    () => _invoke(request),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => _forwardPrint(request, line),
    ),
  );
}

/// Execute an interpreted computation in a fresh real native isolate.
Future<Object?> runInterpretedIsolate(
  InterpreterVisitor visitor,
  Object? computation, {
  String? debugName,
}) async {
  final output = ReceivePort();
  final completion = Completer<Object?>();
  Isolate? worker;
  output.listen((event) {
    if (event is _Print) {
      print(event.line);
      return;
    }
    if (completion.isCompleted) return;
    if (event is _Result) {
      completion.complete(event.value);
    } else if (event is _Failure) {
      completion.completeError(event.error, StackTrace.fromString(event.stack));
    } else if (event is List && event.length == 2) {
      completion.completeError(RemoteError('${event[0]}', '${event[1]}'));
    } else if (event == null) {
      completion.completeError(
        RemoteError('Isolate exited without a result.', ''),
      );
    }
  });
  try {
    final request = _request(visitor, computation, const [], output.sendPort);
    worker = await _spawnNative(
      request,
      runComputation: true,
      errorsAreFatal: true,
      paused: false,
      onExit: null,
      onError: output.sendPort,
      debugName: debugName,
    );
    if (InterpretedIsolateSupervisor.spawnBrokerPort == null) {
      InterpretedIsolateSupervisor._register(worker);
      worker.resume(worker.pauseCapability!);
    }
    return await completion.future;
  } finally {
    if (worker != null) {
      InterpretedIsolateSupervisor._workers.remove(worker);
      worker.kill(priority: Isolate.immediate);
    }
    output.close();
  }
}

/// Start an interpreted entrypoint and return its actual native Isolate.
Future<Isolate> spawnInterpretedIsolate(
  InterpreterVisitor visitor,
  Object? entrypoint,
  Object? message, {
  bool paused = false,
  bool errorsAreFatal = true,
  SendPort? onExit,
  SendPort? onError,
  String? debugName,
}) async {
  final output = ReceivePort();
  Isolate? worker;
  output.listen((event) {
    if (event is _Print) {
      print(event.line);
    }
    if (event == null) {
      if (worker != null) InterpretedIsolateSupervisor._workers.remove(worker);
      output.close();
    }
  });
  try {
    final request = _request(visitor, entrypoint, [message], output.sendPort);
    worker = await _spawnNative(
      request,
      runComputation: false,
      errorsAreFatal: errorsAreFatal,
      paused: paused,
      onExit: onExit,
      onError: onError,
      debugName: debugName,
    );
    if (InterpretedIsolateSupervisor.spawnBrokerPort == null) {
      if (onExit != null) worker.addOnExitListener(onExit);
      InterpretedIsolateSupervisor._register(worker);
      if (!paused) worker.resume(worker.pauseCapability!);
    }
    return worker;
  } catch (_) {
    worker?.kill(priority: Isolate.immediate);
    output.close();
    rethrow;
  }
}
