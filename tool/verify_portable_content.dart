import 'dart:convert';
import 'dart:io';

import '../curriculum/dart_curriculum.dart';
import 'portable_content_runner.dart';

/// Full portable gate: no whitelist and no unsupported/timeout skip.
/// `--report path` saves exact output and errors; `--chapter key` narrows a fix.
Future<void> main(List<String> args) async {
  String? chapter;
  String? report;
  for (var i = 0; i < args.length; i++) {
    final flag = args[i];
    if ((flag != '--chapter' && flag != '--report') || i + 1 == args.length) {
      stderr.writeln('Usage: --chapter <key> --report <path>');
      exitCode = 64;
      return;
    }
    final value = args[++i];
    if (flag == '--chapter') chapter = value;
    if (flag == '--report') report = value;
  }
  final lessons = dartCurriculum
      .where((lesson) => chapter == null || lesson.chapter == chapter)
      .toList();
  if (lessons.isEmpty) {
    stderr.writeln('No lessons match chapter $chapter');
    exitCode = 64;
    return;
  }
  final results = <Map<String, Object?>>[];
  for (final lesson in lessons) {
    for (final unit in [
      (id: lesson.id, code: lesson.code),
      (id: lesson.exampleId, code: lesson.resolvedExampleCode),
    ]) {
      final result = await runPortableContent(unit.code);
      final passed =
          result.error == null &&
          _normalize(result.output) == _normalize(lesson.output);
      results.add({
        'id': unit.id,
        'chapter': lesson.chapter,
        'passed': passed,
        'expected': lesson.output,
        'actual': result.output,
        'error': result.error,
      });
      final detail = result.error?.split('\n').first ?? 'stdout mismatch';
      stdout.writeln(
        '${passed ? 'PASS' : 'FAIL'} ${unit.id}${passed ? '' : ': $detail'}',
      );
    }
  }
  final failures = results.where((result) => result['passed'] == false).length;
  stdout.writeln('portable checked=${results.length} failures=$failures');
  if (report != null) {
    final file = File(report);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert({'engine': 'dart_eval 0.8.5', 'scope': 'host portable engine; not OHOS device execution', 'checked': results.length, 'failures': failures, 'results': results})}\n',
      flush: true,
    );
  }
  if (failures != 0) exitCode = 1;
}

String _normalize(String text) =>
    text.replaceAll('\r\n', '\n').replaceFirst(RegExp(r'\n+$'), '');
