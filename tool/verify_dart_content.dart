import 'dart:convert';
import 'dart:io';

import '../curriculum/dart_chapters.dart';
import '../curriculum/dart_curriculum.dart';
import '../curriculum/dart_lesson.dart';

/// Canonical verifier for the Dart curriculum: compiles and **actually runs**
/// every authored lesson on the host Dart SDK and compares stdout to the
/// declared `output` byte-exactly (LF-normalized, trailing newline tolerant).
///
/// This is the integration-owned harness. Chapter owners run it for their own
/// chapters with `--chapter <key>` while authoring, and the whole set runs
/// before integration.
///
/// Run from `qfli_dart`:
///
///   dart run tool/verify_dart_content.dart                 # all lessons
///   dart run tool/verify_dart_content.dart --chapter dart3 # one chapter
///
/// Exit code is non-zero if any lesson fails. When the host SDK is missing this
/// reports a hard failure — it never silently skips.
Future<void> main(List<String> args) async {
  final chapterFilter = _chapterArg(args);
  final lessons = chapterFilter == null
      ? dartCurriculum
      : dartCurriculum.where((l) => l.chapter == chapterFilter).toList();

  if (!await _sdkAvailable()) {
    stderr.writeln('FATAL: host Dart SDK not available.');
    exit(2);
  }

  final tmp = Directory.systemTemp.createTempSync('qfli_dart_verify_');
  var failures = 0;
  var checked = 0;
  try {
    for (final lesson in lessons) {
      checked++;
      final problems = await _checkLesson(tmp, lesson);
      if (problems.isEmpty) {
        stdout.writeln('PASS ${lesson.id}');
      } else {
        failures++;
        stdout.writeln('FAIL ${lesson.id}');
        for (final problem in problems) {
          stdout.writeln('  $problem');
        }
      }
    }
  } finally {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  }

  stdout.writeln('checked=$checked failures=$failures');
  if (failures > 0) exitCode = 1;
}

Future<List<String>> _checkLesson(Directory tmp, DartLesson lesson) async {
  final problems = <String>[];

  final lessonFile = File('${tmp.path}/${lesson.id}.dart');
  lessonFile.writeAsStringSync(lesson.code);
  final lessonResult = await _run(lessonFile);
  _diffOutput(
    problems,
    label: 'lesson',
    expected: lesson.output,
    result: lessonResult,
  );

  if (lesson.resolvedExampleCode != lesson.code) {
    final exampleFile = File('${tmp.path}/${lesson.exampleId}.dart');
    exampleFile.writeAsStringSync(lesson.resolvedExampleCode);
    final exampleResult = await _run(exampleFile);
    _diffOutput(
      problems,
      label: 'example',
      expected: lesson.output,
      result: exampleResult,
    );
  }

  return problems;
}

void _diffOutput(
  List<String> problems, {
  required String label,
  required String expected,
  required ({int exitCode, String stdout, String stderr}) result,
}) {
  final actual = _normalizeNewlines(result.stdout);
  if (result.exitCode != 0) {
    problems.add('$label exited ${result.exitCode}');
    final err = result.stderr.trim();
    if (err.isNotEmpty) problems.add('$label stderr: $err');
  }
  if (!_outputMatches(expected, actual)) {
    problems.add('$label stdout mismatch');
    problems.add('  expect: ${_escape(expected)}');
    problems.add('  actual: ${_escape(actual)}');
  }
}

/// Accepts an exact match or a match that differs only by a single trailing
/// newline, so authors are not forced to count the final `\n`.
bool _outputMatches(String expected, String actual) {
  if (expected == actual) return true;
  return '${expected.trimRight()}\n' == actual ||
      expected.trimRight() == actual.trimRight();
}

Future<({int exitCode, String stdout, String stderr})> _run(File file) async {
  // Decode child output as UTF-8 explicitly: on Windows the default system
  // codepage (GBK) mangles Chinese stdout from `dart`.
  final result = await Process.run(
    'dart',
    <String>[file.path],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  return (
    exitCode: result.exitCode,
    stdout: result.stdout as String,
    stderr: result.stderr as String,
  );
}

Future<bool> _sdkAvailable() async {
  try {
    final result = await Process.run('dart', <String>['--version']);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

String? _chapterArg(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--chapter' && i + 1 < args.length) return args[i + 1];
  }
  return null;
}

String _normalizeNewlines(String value) => value.replaceAll('\r\n', '\n');

String _escape(String value) =>
    value.replaceAll('\n', r'\n').replaceAll('\t', r'\t');

/// Referenced so the chapter catalog stays linked from this tool.
// ignore: unused_element
List<String> get _chapterKeys =>
    DartCurriculum.chapters.map((c) => c.key).toList();
