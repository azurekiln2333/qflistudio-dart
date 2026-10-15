@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_runner.dart';

import '../curriculum/dart_curriculum.dart';
import '../curriculum/dart_lesson.dart';

/// Runtime gate for the 120-lesson Dart curriculum: every lesson and every
/// example is compiled and **actually executed** through the real
/// [DartProgramRunner] (the app's injected runner), and stdout is compared to
/// the declared output.
///
/// The host Dart SDK is required. When it is absent the suite fails loudly
/// rather than skipping, so a green run always means real execution happened.
///
/// Runs all 240 programs. Kept as a single sequential test to bound process
/// churn; `flutter test` runs it on the VM.
void main() {
  const runner = DartProgramRunner();

  final nativeSupported = NativeSupport.available;
  if (!nativeSupported) {
    test('host Dart SDK is required for runtime verification', () {
      fail(
        'Native Dart toolchain unavailable on this host. '
        'Cannot verify the 120 lessons for real.',
      );
    });
    return;
  }

  test(
    'every lesson and example compiles, runs, and matches output',
    () async {
      final failures = <String>[];
      var checked = 0;

      for (final lesson in dartCurriculum) {
        checked++;
        await _verify(
          runner: runner,
          lesson: lesson,
          code: lesson.code,
          label: 'lesson',
          expected: lesson.output,
          failures: failures,
        );
        if (lesson.resolvedExampleCode != lesson.code) {
          await _verify(
            runner: runner,
            lesson: lesson,
            code: lesson.resolvedExampleCode,
            label: 'example',
            expected: lesson.output,
            failures: failures,
          );
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'checked=$checked\n${failures.join('\n')}',
      );
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

Future<void> _verify({
  required DartProgramRunner runner,
  required DartLesson lesson,
  required String code,
  required String label,
  required String expected,
  required List<String> failures,
}) async {
  final project = await Directory.systemTemp.createTemp('qfli_lesson_');
  try {
    final entry = File(p.join(project.path, 'main.dart'));
    await entry.writeAsString(code);

    final result = await runner.run(
      projectPath: project.path,
      entryFile: entry.path,
    );
    if (result == null) {
      failures.add('${lesson.id} $label: runner returned null');
      return;
    }

    final stdoutLines = await result.stdout.toList();
    final stderrLines = await result.stderr.toList();
    final code0 = await result.exitCode;
    final actual = stdoutLines.isEmpty ? '' : '${stdoutLines.join('\n')}\n';

    if (code0 != 0) {
      failures.add(
        '${lesson.id} $label: exit=$code0 stderr=${stderrLines.join(' | ')}',
      );
    }
    if (!_matches(expected, actual)) {
      failures.add(
        '${lesson.id} $label: stdout mismatch\n'
        '    expect: ${_escape(expected)}\n'
        '    actual: ${_escape(actual)}',
      );
    }
  } finally {
    if (project.existsSync()) {
      try {
        await project.delete(recursive: true);
      } on FileSystemException {
        // Windows can hold the entry briefly; temp dir is reclaimed by the OS.
      }
    }
  }
}

bool _matches(String expected, String actual) {
  if (expected == actual) return true;
  return expected.trimRight() == actual.trimRight();
}

String _escape(String value) =>
    value.replaceAll('\n', r'\n').replaceAll('\t', r'\t');

/// Local capability probe mirroring [NativeDartToolchain.supported] without
/// importing the toolchain (keeps this test's dependency surface small).
abstract final class NativeSupport {
  static bool get available =>
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isAndroid;
}
