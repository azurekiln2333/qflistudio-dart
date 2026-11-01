import 'dart:async';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';

/// Probe runner: runs every *.dart file in the given directory as a separate
/// dart_eval program and reports the first error line or the output.
/// Usage: dart run _caps.dart <dir>
Future<void> main(List<String> args) async {
  final dir = Directory(args.single);
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.dart', '');
    final buffer = StringBuffer();
    Object? error;
    try {
      final compiler = Compiler()..entrypoints.add('package:demo/main.dart');
      final program = compiler.compile({
        'demo': {'main.dart': file.readAsStringSync()},
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
      final flat = out.replaceAll('\n', r' | ');
      stdout.writeln('PASS $name :: $flat');
    }
  }
}
