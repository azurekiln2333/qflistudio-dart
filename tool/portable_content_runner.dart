import 'dart:async';

import 'package:qfli_dart/portable_dart_runtime.dart';

/// Executes the real product portable path, including IO policy/supervision.
/// Timeouts cancel the entire owned isolate tree, including pending spawns.
Future<({String output, String? error})> runPortableContent(
  String source, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final run = await startPortableDart(
    packages: {
      'demo': {'main.dart': source},
    },
    entryUri: 'package:demo/main.dart',
  );
  final output = run.stdout.toList();
  final errors = run.stderr.toList();
  String? failure;
  try {
    final code = await run.exitCode.timeout(timeout);
    if (code != 0) failure = 'Portable program exited $code';
  } on TimeoutException {
    failure = 'Portable execution timed out after $timeout';
  } finally {
    await run.cancel();
  }
  final stdout = await output;
  final stderr = await errors;
  return (
    output: stdout.isEmpty ? '' : '${stdout.join('\n')}\n',
    error: failure == null && stderr.isEmpty
        ? null
        : [?failure, ...stderr].join('\n'),
  );
}
