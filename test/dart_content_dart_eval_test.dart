@TestOn('vm')
library;

import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:flutter_test/flutter_test.dart';

import '../curriculum/dart_chapters.dart';
import '../curriculum/dart_curriculum.dart';

/// Legacy EVC compiler regression, independent of the product AST interpreter.
/// Only the empirically verified [DartCurriculum.dartEvalVerifiedIds] subset is
/// checked here. The full production portable gate is
/// `dart_content_portable_test.dart`; this subset never establishes its result.
void main() {
  test('dart_eval subset lessons run and match declared output', () async {
    final byId = {for (final l in dartCurriculum) l.id: l};
    var ran = 0;
    final failures = <String>[];

    for (final id in DartCurriculum.dartEvalVerifiedIds) {
      final lesson = byId[id];
      if (lesson == null) {
        failures.add('$id missing from curriculum');
        continue;
      }
      try {
        final output = await _runPortable(lesson.code);
        if (_normalize(output) != _normalize(lesson.output)) {
          failures.add(
            '${lesson.id} output mismatch\n'
            '    expect: ${_escape(lesson.output)}\n'
            '    actual: ${_escape(output)}',
          );
        } else {
          ran++;
        }
      } on Object catch (error) {
        failures.add('${lesson.id}: ${error.toString().split('\n').first}');
      }
    }

    expect(ran, greaterThan(0), reason: 'no lesson ran on dart_eval');
    expect(failures, isEmpty, reason: failures.join('\n'));
    // ignore: avoid_print
    print(
      'dart_eval: ran=$ran of ${dartCurriculum.length} lessons; '
      '${dartCurriculum.length - DartCurriculum.dartEvalVerifiedIds.length} '
      'outside this legacy EVC regression subset',
    );
  });
}

/// Runs one self-contained program on dart_eval, capturing `print` output.
Future<String> _runPortable(String source) async {
  const packageName = 'demo';
  final compiler = Compiler()
    ..entrypoints.add('package:$packageName/main.dart');
  final program = compiler.compile({
    packageName: {'main.dart': source},
  });
  final runtime = Runtime.ofProgram(program);
  final buffer = StringBuffer();
  await runZoned(
    () async {
      await Future<dynamic>.value(
        runtime.executeLib('package:$packageName/main.dart', 'main', null),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => buffer.writeln(line),
    ),
  );
  return buffer.toString();
}

String _normalize(String value) => value.replaceAll('\r\n', '\n').trimRight();

String _escape(String value) => value.replaceAll('\n', r'\n');
