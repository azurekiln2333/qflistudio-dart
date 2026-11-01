import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:tom_d4rt/d4rt.dart';

/// Pure Dart execution shared by the product runner and the content verifier.
/// Output is split into lines, matching the shared editor runner contract.
class PortableDartRun {
  const PortableDartRun({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.cancel,
  });

  final Stream<String> stdout;
  final Stream<String> stderr;
  final Future<int> exitCode;
  final Future<void> Function() cancel;
}

/// Runs preloaded project sources without SDK, source downloads or native exec.
/// Each run owns its temporary IO directory and all descendant native isolates.
Future<PortableDartRun> startPortableDart({
  required Map<String, Map<String, String>> packages,
  required String entryUri,
  String? projectPath,
}) async {
  final sources = <String, String>{
    for (final package in packages.entries)
      for (final file in package.value.entries)
        'package:${package.key}/${file.key}': file.value,
  };
  if (!sources.containsKey(entryUri)) {
    throw ArgumentError.value(entryUri, 'entryUri', '找不到预加载的入口源码');
  }
  final projectRoot = projectPath == null
      ? null
      : await Directory(projectPath).resolveSymbolicLinks();
  final scratch = await Directory.systemTemp.createTemp('qfli_dart_run_');
  final root = projectRoot ?? scratch.path;
  final output = _OutputLines();
  final errors = _OutputLines();
  final exitCode = Completer<int>();
  final messages = ReceivePort();
  final host = InterpretedIsolateSupervisorHost(
    orderedExitPort: messages.sendPort,
    unhandledErrorPort: messages.sendPort,
  );
  Future<void>? finishing;
  Completer<void>? outputDrained;
  var exitedWorkers = 0;
  var mainCompleted = false;

  Future<void> finish(int code) => finishing ??= () async {
    // Shutdown also waits for pending native spawns and every owned exit.
    await host.stop();
    outputDrained?.complete();
    outputDrained = null;
    messages.close();
    try {
      if (await scratch.exists()) await scratch.delete(recursive: true);
    } on FileSystemException catch (error) {
      errors.add('无法清理 Dart 临时目录：${error.message}\n');
      if (code == 0) code = 127;
    }
    output.close();
    errors.close();
    exitCode.complete(code);
  }();

  messages.listen((message) {
    if (finishing != null) return;
    if (message is Map) {
      switch (message['type']) {
        case 'stdout':
          output.add(message['data'] as String);
        case 'stderr':
          errors.add(message['data'] as String);
        case 'mainDone':
          mainCompleted = true;
        case 'workerExited':
          exitedWorkers++;
          if (exitedWorkers == host.createdWorkerCount) {
            outputDrained?.complete();
            outputDrained = null;
          }
        case 'failed':
          unawaited(finish(message['code'] as int));
      }
    } else if (message is List && message.isNotEmpty) {
      errors.add('${message.first}\n');
      unawaited(finish(1));
    }
  });

  try {
    await host.spawn(
      _execute,
      (
        output: messages.sendPort,
        broker: host.sendPort,
        sources: sources,
        entryUri: entryUri,
        projectPath: root,
        scratchPath: scratch.path,
      ),
      onError: messages.sendPort,
      debugName: 'qfli-dart-portable',
    );
    // Native exit markers share the output port. Consuming one for every
    // created worker drains all earlier output without an event-turn guess.
    unawaited(() async {
      await host.waitForIdle();
      if (finishing != null) return;
      if (exitedWorkers < host.createdWorkerCount) {
        outputDrained ??= Completer<void>();
        await outputDrained!.future;
      }
      await finish(mainCompleted ? 0 : 127);
    }());
  } on Object catch (error) {
    errors.add('无法启动 Dart 便携运行时：$error\n');
    await finish(127);
  }

  return PortableDartRun(
    stdout: output.stream,
    stderr: errors.stream,
    exitCode: exitCode.future,
    cancel: () => finish(130),
  );
}

typedef _ExecutionRequest = ({
  SendPort output,
  SendPort broker,
  Map<String, String> sources,
  String entryUri,
  String projectPath,
  String scratchPath,
});

Future<void> _execute(_ExecutionRequest request) async {
  InterpretedIsolateSupervisor.spawnBrokerPort = request.broker;
  void failed(Object error) {
    request.output.send({'type': 'stderr', 'data': '$error\n'});
    request.output.send({
      'type': 'failed',
      'code': error is SourceCodeD4rtException ? 127 : 1,
    });
  }

  await runZonedGuarded(
    () async {
      try {
        final runtime =
            D4rt(
                hostPolicy: OfflineHostPolicy(
                  projectPath: request.projectPath,
                  scratchPath: request.scratchPath,
                  output: request.output,
                ),
              )
              ..grant(FilesystemPermission.readPath(request.projectPath))
              ..grant(FilesystemPermission.writePath(request.projectPath))
              ..grant(FilesystemPermission.readPath(request.scratchPath))
              ..grant(FilesystemPermission.writePath(request.scratchPath))
              ..grant(IsolatePermission.any);
        final source = request.sources[request.entryUri]!;
        await Future<Object?>.value(
          runtime.execute(
            source: source,
            sourceUri: request.entryUri,
            sources: request.sources,
            positionalArgs: _mainAcceptsArguments(source)
                ? [<String>[]]
                : const [],
          ),
        );
        request.output.send({'type': 'mainDone'});
      } on Object catch (error) {
        failed(error);
      }
    },
    (error, stack) => failed(error),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        request.output.send({'type': 'stdout', 'data': '$line\n'});
      },
    ),
  );
}

bool _mainAcceptsArguments(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  return unit.declarations.whereType<FunctionDeclaration>().any(
    (declaration) =>
        declaration.name.lexeme == 'main' &&
        (declaration.functionExpression.parameters?.parameters.isNotEmpty ??
            false),
  );
}

class _OutputLines {
  final _controller = StreamController<String>();
  String _pending = '';

  Stream<String> get stream => _controller.stream;

  void add(String chunk) {
    _pending += chunk;
    var newline = _pending.indexOf('\n');
    while (newline >= 0) {
      final line = _pending.substring(0, newline);
      _controller.add(
        line.endsWith('\r') ? line.substring(0, line.length - 1) : line,
      );
      _pending = _pending.substring(newline + 1);
      newline = _pending.indexOf('\n');
    }
  }

  void close() {
    if (_pending.isNotEmpty) _controller.add(_pending);
    _pending = '';
    unawaited(_controller.close());
  }
}
