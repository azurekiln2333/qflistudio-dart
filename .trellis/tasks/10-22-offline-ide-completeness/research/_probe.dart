import 'dart:async';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';

/// Probe: run ad-hoc snippets on dart_eval to pin down exact failure causes.
/// Usage: dart run .trellis/tasks/10-22-offline-ide-completeness/research/_probe.dart <file.dart>
Future<void> main(List<String> args) async {
  final source = File(args.single).readAsStringSync();
  final buffer = StringBuffer();
  Object? error;
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
        print: (self, parent, zone, line) => buffer.writeln(line),
      ),
    );
  } on Object catch (e) {
    error = e;
  }
  stdout.writeln('--- output ---');
  stdout.writeln(buffer.toString());
  if (error != null) {
    stdout.writeln('--- error ---');
    stdout.writeln('$error');
  }
}
