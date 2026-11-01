import 'dart:async';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';

/// Probe runner: splits `_cases.dart` snippets separated by `// ---- name`
Future<void> main(List<String> args) async {
  final source = File(args.single).readAsStringSync();
  final parts = source.split(RegExp(r'^// ==== (.+)$', multiLine: true));
  for (var i = 1; i < parts.length; i += 2) {
    final name = parts[i].trim();
    final code = parts[i + 1];
    final buffer = StringBuffer();
    Object? error;
    try {
      final compiler = Compiler()..entrypoints.add('package:demo/main.dart');
      final program = compiler.compile({
        'demo': {'main.dart': code},
      });
      final runtime = Runtime.ofProgram(program);
      await runZoned(
        () async {
          await Future<dynamic>.value(
            runtime.executeLib('package:demo/main.dart', 'main', null),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => buffer.writeln(line),
        ),
      );
    } on Object catch (e) {
      error = e;
    }
    final out = buffer.toString().trimRight();
    if (error != null) {
      stdout.writeln('FAIL $name :: ${'$error'.split('\n').first}');
    } else {
      stdout.writeln('PASS $name :: ${out.replaceAll('\n', r'\n')}');
    }
  }
}
