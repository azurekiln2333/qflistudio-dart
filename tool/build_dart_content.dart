import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../curriculum/dart_chapters.dart';
import '../curriculum/dart_curriculum.dart';
import '../curriculum/dart_lesson.dart';

/// Emits the two Dart-only aggregate content assets from the authored
/// [dartCurriculum] source of truth.
///
/// Output (relative to the `qfli_dart` root):
///   * `assets/content/dart_tutorials.json`
///   * `assets/content/dart_examples.json`
///
/// Both use the envelope the core `ContentCatalog.fromJson` already accepts
/// (`{schemaVersion, kind, updatedAt, entries: [...]}`), so no core parser
/// change is needed. The generator is deterministic and id-sorted.
///
/// Run from `qfli_dart`:
///
///   dart run tool/build_dart_content.dart
Future<void> main(List<String> args) async {
  final root = Directory.current;
  final outDir = Directory(p.join(root.path, 'assets', 'content'));
  await outDir.create(recursive: true);

  _checkCurriculum(dartCurriculum);

  final tutorials = _tutorialsDocument(dartCurriculum);
  final examples = _examplesDocument(dartCurriculum);

  await _writeJson(File(p.join(outDir.path, 'dart_tutorials.json')), tutorials);
  await _writeJson(File(p.join(outDir.path, 'dart_examples.json')), examples);

  stdout.writeln(
    'Emitted ${dartCurriculum.length} Dart lessons and '
    '${dartCurriculum.length} Dart examples.',
  );
}

/// Structural checks that must hold before emitting. These fail fast so a
/// broken authoring edit never produces a shipped asset.
void _checkCurriculum(List<DartLesson> lessons) {
  final problems = <String>[];
  final ids = <String>{};
  final perChapter = <String, int>{};
  final explainSeen = <String, String>{};
  final lessonCodeSeen = <String, String>{};
  final exampleCodeSeen = <String, String>{};

  for (final lesson in lessons) {
    if (ids.contains(lesson.id)) {
      problems.add('duplicate lesson id: $lesson.id');
    }
    ids.add(lesson.id);

    perChapter[lesson.chapter] = (perChapter[lesson.chapter] ?? 0) + 1;

    void requireNonEmpty(String label, String value) {
      if (value.trim().isEmpty) {
        problems.add('$lesson.id: $label must not be empty');
      }
    }

    requireNonEmpty('title', lesson.title);
    requireNonEmpty('summary', lesson.summary);
    requireNonEmpty('explain', lesson.explain);
    requireNonEmpty('objective', lesson.objective);
    requireNonEmpty('code', lesson.code);
    requireNonEmpty('output', lesson.output);
    requireNonEmpty('exampleTitle', lesson.exampleTitle);
    requireNonEmpty('exampleSummary', lesson.exampleSummary);
    if (lesson.concepts.isEmpty) {
      problems.add('$lesson.id: concepts must not be empty');
    }
    if (lesson.pitfalls.isEmpty) {
      problems.add('$lesson.id: pitfalls must not be empty');
    }
    if (lesson.exercises.isEmpty) {
      problems.add('$lesson.id: exercises must not be empty');
    }
    for (final exercise in lesson.exercises) {
      requireNonEmpty('exercise.prompt', exercise.prompt);
      requireNonEmpty('exercise.hint', exercise.hint);
      requireNonEmpty('exercise.answer', exercise.answer);
    }

    final priorExplain = explainSeen[lesson.explain];
    if (priorExplain != null) {
      problems.add('$lesson.id: explain duplicates $priorExplain');
    } else {
      explainSeen[lesson.explain] = lesson.id;
    }

    final normalizedLessonCode = _normalize(lesson.code);
    final priorLessonCode = lessonCodeSeen[normalizedLessonCode];
    if (priorLessonCode != null) {
      problems.add('$lesson.id: lesson code duplicates $priorLessonCode');
    } else {
      lessonCodeSeen[normalizedLessonCode] = lesson.id;
    }

    final normalizedExampleCode = _normalize(lesson.resolvedExampleCode);
    final priorExampleCode = exampleCodeSeen[normalizedExampleCode];
    if (priorExampleCode != null) {
      problems.add('$lesson.id: example code duplicates $priorExampleCode');
    } else {
      exampleCodeSeen[normalizedExampleCode] = lesson.id;
    }

    if (!DartCurriculum.counts.containsKey(lesson.chapter)) {
      problems.add('$lesson.id: unknown chapter ${lesson.chapter}');
    }
  }

  // Chapter totals must match the fixed allocation exactly, but only once the
  // curriculum is complete (120 lessons). Partial authoring is allowed while
  // the curriculum is under construction.
  if (lessons.length == 120) {
    for (final chapter in DartCurriculum.chapters) {
      final expected = DartCurriculum.counts[chapter.key]!;
      final actual = perChapter[chapter.key] ?? 0;
      if (actual != expected) {
        problems.add(
          'chapter ${chapter.key}: expected $expected lessons, found $actual',
        );
      }
    }
  } else if (lessons.length > 120) {
    problems.add('curriculum has ${lessons.length} lessons; max is 120');
  }

  if (problems.isNotEmpty) {
    stderr.writeln('Curriculum check failed:');
    for (final problem in problems) {
      stderr.writeln('  - $problem');
    }
    exit(1);
  }
}

Map<String, Object> _tutorialsDocument(List<DartLesson> lessons) =>
    <String, Object>{
      'schemaVersion': 1,
      'kind': 'tutorials',
      'updatedAt': _updatedAt(lessons),
      'entries': <Object>[
        for (final lesson in _sorted(lessons)) _tutorialEntry(lesson),
      ],
    };

Map<String, Object> _examplesDocument(List<DartLesson> lessons) =>
    <String, Object>{
      'schemaVersion': 1,
      'kind': 'examples',
      'updatedAt': _updatedAt(lessons),
      'entries': <Object>[
        for (final lesson in _sorted(lessons)) _exampleEntry(lesson),
      ],
    };

Map<String, Object> _tutorialEntry(DartLesson lesson) => <String, Object>{
  'id': lesson.id,
  'language': 'dart',
  'type': 'dart',
  'locale': 'zh-CN',
  'level': lesson.level,
  'title': lesson.title,
  'summary': lesson.summary,
  'concepts': lesson.concepts,
  'source': _source,
  'license': _license,
  'updatedAt': _updatedAtValue,
  'lessons': <Object>[
    <String, Object>{
      'id': lesson.lessonId,
      'title': lesson.title,
      'summary': lesson.summary,
      'concepts': lesson.concepts,
      'explain': '${lesson.explain}\n\n${DartCurriculum.engineNote(lesson.id)}',
      'code': lesson.code,
      'output': lesson.output,
      'objective': lesson.objective,
      'prerequisites': lesson.prerequisites,
      'pitfalls': lesson.pitfalls,
      'exercises': <Object>[
        for (final exercise in lesson.exercises)
          <String, String>{
            'prompt': exercise.prompt,
            'hint': exercise.hint,
            'answer': exercise.answer,
          },
      ],
    },
  ],
};

Map<String, Object> _exampleEntry(DartLesson lesson) => <String, Object>{
  'id': lesson.exampleId,
  'language': 'dart',
  'type': 'dart',
  'locale': 'zh-CN',
  'level': lesson.level,
  'title': lesson.exampleTitle,
  'summary': '${lesson.exampleSummary} ${DartCurriculum.engineTag(lesson.id)}',
  'concepts': lesson.concepts,
  'source': _source,
  'license': _license,
  'updatedAt': _updatedAtValue,
  'code': lesson.resolvedExampleCode,
  'expectedOutput': lesson.output,
  'templateType': 'dart',
  'sourceLessonId': lesson.id,
};

List<DartLesson> _sorted(List<DartLesson> lessons) {
  final copy = List<DartLesson>.of(lessons)
    ..sort((a, b) => a.id.compareTo(b.id));
  return copy;
}

String _normalize(String code) => code.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Repository-consistent source/license. These mirror the exact values already
/// used by the bundled Dart content, so no new license is introduced.
const String _source = 'https://dart.dev/language';
const String _license =
    'Original QFLI curriculum; reference link retained. CC BY 4.0';

const String _updatedAtValue = '2026-10-12';

String _updatedAt(List<DartLesson> lessons) => _updatedAtValue;

Future<void> _writeJson(File file, Map<String, Object> document) async {
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(document)}\n', flush: true);
}
