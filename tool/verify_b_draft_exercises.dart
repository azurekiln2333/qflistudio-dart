import 'dart:convert';
import 'dart:io';

import '../curriculum/chapters/enum_states.dart';
import '../curriculum/chapters/errors_resilience.dart';
import '../curriculum/chapters/json_modeling.dart';
import '../curriculum/chapters/math_stats.dart';
import '../curriculum/chapters/oop_modeling.dart';
import '../curriculum/dart_lesson.dart';
import 'portable_content_runner.dart';

/// Runs the draft exercises through the real SDK and the production portable
/// runtime, and compares the exact outputs.
///
/// The scratch report keeps the historical path
/// `.dart_tool/expansion-b/results-<args>.json` so the host gate parser stays
/// compatible.
Future<void> main(List<String> args) async {
  const all = <DartLesson>[...mathStatsLessons, ...oopModelingLessons, ...enumStatesLessons,
    ...errorsResilienceLessons, ...jsonModelingLessons];
  final chapterFilters = args.where((arg) => !arg.startsWith('--')).toList();
  final starts = args.where((arg) => arg.startsWith('--start=')).toList();
  final start = int.parse(starts.isEmpty ? '181' : starts.first.split('=').last);
  final exerciseOnly = args.contains('--exercise-only');
  final lessons = all.where((lesson) => int.parse(lesson.id.split('-').last) >= start &&
      (chapterFilters.isEmpty || chapterFilters.contains(lesson.chapter))).toList();
  final numbers = <int>[for (final lesson in lessons) int.parse(lesson.id.split('-').last)];
  final canonicalScope = chapterFilters.isEmpty && start == 181;
  final expectedNumbers = <int>[for (var n = 181; n <= 238; n++) n];
  if (lessons.isEmpty) {
    stderr.writeln('未选中课程。验证失败。');
    exitCode = 1;
    return;
  }
  if (numbers.toSet().length != numbers.length) {
    stderr.writeln('课程 id 重复。验证失败。');
    exitCode = 1;
    return;
  }
  final sortedNumbers = [...numbers]..sort();
  if (canonicalScope && sortedNumbers.join(',') != expectedNumbers.join(',')) {
    stderr.writeln('期望 181..238 共 58 个唯一 id，实际 ${sortedNumbers.length} 个'
        '（${sortedNumbers.first}..${sortedNumbers.last}）。');
    exitCode = 1;
    return;
  }
  final scratch = Directory('.dart_tool/expansion-b')..createSync(recursive: true);
  final programDir = Directory('${scratch.path}/programs')..createSync(recursive: true);
  final suffix = args.isEmpty ? 'all' : args.join('-').replaceAll('=', '-');
  final report = File('${scratch.path}/results-$suffix.json');
  final results = <Map<String, Object?>>[];
  var failures = 0;
  var infrastructureFailure = false;
  void save() {
    report.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'plannedLessons': lessons.length,
      'pairedEntriesChecked': results.where((r) => r['kind'] != 'exercise').length,
      'standaloneExercisesChecked': results.where((r) => r['kind'] == 'exercise').length,
      'totalEntriesChecked': results.length,
      'failures': failures,
      'infrastructureFailure': infrastructureFailure,
      'targetDeviceVerified': false,
      'results': results,
    }));
  }
  batches: for (final lesson in lessons) {
    for (final kind in exerciseOnly ? ['exercise'] : ['lesson', 'example', 'exercise']) {
      final source = kind == 'lesson' ? lesson.code :
          kind == 'example' ? lesson.resolvedExampleCode : lesson.exercises.single.answer;
      final file = File('${programDir.path}/${lesson.id}-$kind.dart');
      file.writeAsStringSync(source);
      final sdk = await Process.run(Platform.resolvedExecutable, [file.path],
          stdoutEncoding: null, stderrEncoding: null);
      final sdkOutput = utf8.decode(sdk.stdout as List<int>, allowMalformed: true).replaceAll('\r\n', '\n');
      final sdkError = utf8.decode(sdk.stderr as List<int>, allowMalformed: true).replaceAll('\r\n', '\n');
      if (sdkError.contains('Out of memory')) {
        infrastructureFailure = true;
        failures++;
        results.add({'id': lesson.id, 'kind': kind, 'chapter': lesson.chapter,
          'sdkExitCode': sdk.exitCode, 'sdkError': sdkError,
          'portableSkipped': 'SDK infrastructure failure', 'passed': false});
        save();
        stdout.writeln(jsonEncode(results.last));
        break batches;
      }
      final portable = await runPortableContent(source);
      final expected = kind == 'exercise' ? sdkOutput : lesson.output.replaceAll('\r\n', '\n');
      final passed = sdk.exitCode == 0 && sdkError == '' &&
          sdkOutput == expected && portable.error == null && portable.output == expected;
      results.add({
        'id': lesson.id, 'kind': kind, 'chapter': lesson.chapter,
        'expected': expected, 'sdkOutput': sdkOutput, 'sdkError': sdkError,
        'sdkExitCode': sdk.exitCode, 'portableOutput': portable.output,
        'portableError': portable.error, 'passed': passed,
      });
      if (!passed) {
        failures++;
        stdout.writeln(jsonEncode(results.last));
      }
      save();
    }
    stdout.writeln('${lesson.id}: SDK + portable checked lesson/example/exercise');
  }
  save();
  stdout.writeln('unique=${lessons.length} pairs=${results.length} failures=$failures');
  if (failures != 0) exitCode = 1;
}
