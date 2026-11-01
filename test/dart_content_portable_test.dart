@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../curriculum/dart_curriculum.dart';
import '../tool/portable_content_runner.dart';

/// Execute every authored unit through the same portable runtime as the app.
/// No compatibility whitelist, mock output, or unsupported-feature skip.
void main() {
  test(
    'every lesson and example runs through the product portable engine',
    () async {
      final failures = <String>[];
      var checked = 0;
      for (final lesson in dartCurriculum) {
        for (final (id, source) in [
          (lesson.id, lesson.code),
          (lesson.exampleId, lesson.resolvedExampleCode),
        ]) {
          checked++;
          final result = await runPortableContent(source);
          if (result.error != null ||
              _normalize(result.output) != _normalize(lesson.output)) {
            failures.add(
              '$id: ${result.error ?? 'stdout mismatch'}\n'
              'expected: ${lesson.output}\nactual: ${result.output}',
            );
          }
        }
      }
      expect(checked, dartCurriculum.length * 2);
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

String _normalize(String text) =>
    text.replaceAll('\r\n', '\n').replaceFirst(RegExp(r'\n+$'), '');
