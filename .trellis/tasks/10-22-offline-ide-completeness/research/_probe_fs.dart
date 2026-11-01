import 'dart:async';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';

/// Same portable path as tool/portable_content_runner.dart, but granting
/// filesystem permissions + printing the full error tail.
Future<void> main(List<String> args) async {
  final source = File(args.first).readAsStringSync();
  final grantFs = args.length > 1 && args[1] == '--fs';
  final buffer = StringBuffer();
  Object? error;
  try {
    final compiler = Compiler()..entrypoints.add('package:demo/main.dart');
    final program = compiler.compile({
      'demo': {'main.dart': source},
    });
    final runtime = Runtime.ofProgram(program);
    if (grantFs) {
      runtime.grant(FilesystemPermission.any);
    }
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
  stdout.write(buffer.toString());
  if (error != null) {
    stdout.writeln('--- error ---');
    stdout.writeln('$error'.split('\n').first);
  }
}
