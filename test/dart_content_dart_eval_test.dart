@TestOn('vm')
library;

import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:flutter_test/flutter_test.dart';

import '../curriculum/dart_chapters.dart';
import '../curriculum/dart_curriculum.dart';

/// Real execution on the **dart_eval portable engine** — the branch the app
/// uses when the official SDK is unavailable (iOS/OHOS and unsupported hosts).
///
/// Complementary to `dart_content_run_test.dart` (official SDK VM). dart_eval
/// 0.8.5 covers only a narrow subset of Dart; most of this curriculum targets
/// the official SDK. This test runs the lessons in the shared, empirically
/// verified [DartCurriculum.dartEvalVerifiedIds] whitelist and asserts their
/// output. Every other lesson is reported as SDK-required and is NOT counted as
/// passing here.
///
/// The whitelist lives in `curriculum/dart_chapters.dart` so the generator can
/// project the same requirement into the UI; it was curated from actual runs
/// because dart_eval has non-obvious gaps (`continue`, operator overloads,
/// value-equality in `Set`, `runtimeType` printing, some casts).
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
      'SDK-required',
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
