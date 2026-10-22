import 'dart:async';
import 'dart:isolate';

import 'package:dart_eval/dart_eval.dart';

/// Executes the same Compiler/Runtime path used by the OHOS portable runner.
/// Each program owns an isolate so even a synchronous infinite loop can stop.
Future<({String output, String? error})> runPortableContent(
  String source, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final messages = ReceivePort();
  Isolate? worker;
  try {
    worker = await Isolate.spawn(
      _execute,
      (messages.sendPort, source),
      onError: messages.sendPort,
      onExit: messages.sendPort,
      errorsAreFatal: true,
    );
    final message = await messages.first.timeout(timeout);
    if (message is Map) {
      return (
        output: message['output'] as String,
        error: message['error'] as String?,
      );
    }
    return (
      output: '',
      error: 'Portable isolate exited unexpectedly: $message',
    );
  } on TimeoutException {
    return (output: '', error: 'Portable execution timed out after $timeout');
  } finally {
    worker?.kill(priority: Isolate.immediate);
    messages.close();
  }
}

Future<void> _execute((SendPort, String) request) async {
  final (reply, source) = request;
  final output = StringBuffer();
  try {
    final compiler = Compiler()..entrypoints.add('package:demo/main.dart');
    final program = compiler.compile({
      'demo': {'main.dart': source},
    });
    final runtime = Runtime.ofProgram(program);
    await runZoned(
      () async {
        await Future<dynamic>.value(
          runtime.executeLib('package:demo/main.dart', 'main', null),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => output.writeln(line),
      ),
    );
    reply.send({'output': output.toString(), 'error': null});
  } on Object catch (error, stack) {
    reply.send({'output': output.toString(), 'error': '$error\n$stack'});
  }
}
