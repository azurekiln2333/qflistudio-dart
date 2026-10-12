import 'package:flutter_test/flutter_test.dart';
import 'package:qfli_dart/dart_content_repository.dart';
import 'package:qfli_studio_core/content/content_repository.dart';
import 'package:qfli_studio_core/content/local_content_adapter.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';

import '../curriculum/dart_chapters.dart';
import '../curriculum/dart_curriculum.dart';

/// Content-integrity gate for the 120-lesson Dart curriculum.
///
/// Loads the **real bundled assets** through the Dart-app repository and the
/// shared adapter, exactly as the running app does, then asserts structure,
/// uniqueness, completeness, and licensing. Runtime correctness (compile/run/
/// output) is covered by `dart_content_run_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await DartContentRepository().load();
  });

  group('curriculum size and pairing', () {
    test('exactly 120 Dart tutorials and 120 Dart examples', () {
      final tutorials = catalog.tutorials
          .where((t) => t.type.toLowerCase() == 'dart')
          .toList();
      final examples = catalog.examples
          .where((e) => e.type.toLowerCase() == 'dart')
          .toList();
      expect(tutorials, hasLength(120));
      expect(examples, hasLength(120));
    });

    test('unique tutorial ids and titles', () {
      final tutorials = catalog.tutorials;
      expect(tutorials.map((t) => t.id).toSet(), hasLength(120));
      expect(tutorials.map((t) => t.title).toSet(), hasLength(120));
    });

    test('unique example ids and titles', () {
      final examples = catalog.examples;
      expect(examples.map((e) => e.id).toSet(), hasLength(120));
      expect(examples.map((e) => e.title).toSet(), hasLength(120));
    });

    test('every example pairs 1:1 to a lesson by sourceLessonId', () {
      final lessonIds = catalog.tutorials.map((t) => t.id).toSet();
      for (final example in catalog.examples) {
        expect(
          lessonIds,
          contains(example.sourceLessonId),
          reason: '${example.id} must pair to a tutorial',
        );
      }
      expect(
        catalog.examples.map((e) => e.sourceLessonId).toSet(),
        hasLength(120),
      );
    });

    test('authored source matches the fixed chapter allocation', () {      final perChapter = <String, int>{};
      for (final lesson in dartCurriculum) {
        perChapter[lesson.chapter] = (perChapter[lesson.chapter] ?? 0) + 1;
      }
      for (final chapter in DartCurriculum.chapters) {
        expect(
          perChapter[chapter.key],
          DartCurriculum.counts[chapter.key],
          reason: 'chapter ${chapter.key} count',
        );
      }
      expect(dartCurriculum, hasLength(120));
    });

    test('lesson ids are sequential dart-lesson-001..120', () {
      final ids = dartCurriculum.map((l) => l.id).toList()..sort();
      for (var i = 0; i < 120; i++) {
        expect(ids[i], 'dart-lesson-${(i + 1).toString().padLeft(3, '0')}');
      }
    });
  });

  group('lesson completeness', () {
    test('every lesson has complete, real content', () {
      for (final tutorial in catalog.tutorials) {
        expect(tutorial.lessons, hasLength(1), reason: tutorial.id);
        final lesson = tutorial.lessons.first;
        expect(lesson.title.trim(), isNotEmpty, reason: tutorial.id);
        expect(lesson.summary.trim(), isNotEmpty, reason: tutorial.id);
        expect(lesson.explain.trim(), isNotEmpty, reason: tutorial.id);
        expect(lesson.code.trim(), isNotEmpty, reason: tutorial.id);
        expect(lesson.output.trim(), isNotEmpty, reason: tutorial.id);
        expect(
          lesson.objective.trim(),
          isNotEmpty,
          reason: '${tutorial.id} objective',
        );
        expect(lesson.pitfalls, isNotEmpty, reason: '${tutorial.id} pitfalls');
        expect(lesson.exercises, isNotEmpty, reason: '${tutorial.id} exercises');
        expect(tutorial.concepts, isNotEmpty, reason: tutorial.id);
      }
    });

    test('every example has non-empty code and expected output', () {
      for (final example in catalog.examples) {
        expect(example.code.trim(), isNotEmpty, reason: example.id);
        expect(example.expectedOutput.trim(), isNotEmpty, reason: example.id);
      }
    });
  });

  group('uniqueness and quality', () {
    test('every lesson explain is distinct', () {
      final explains = catalog.tutorials
          .map((t) => t.lessons.first.explain)
          .toList();
      expect(explains.toSet(), hasLength(120));
    });

    test('lesson and example summaries are distinct after normalization', () {
      final lessonSummaries = catalog.tutorials
          .map((t) => t.lessons.first.summary.replaceAll(RegExp(r'\s+'), ' ').trim())
          .toList();
      expect(lessonSummaries.toSet(), hasLength(120));
      final exampleSummaries = catalog.examples
          .map((e) => e.summary.replaceAll(RegExp(r'\s+'), ' ').trim())
          .toList();
      expect(exampleSummaries.toSet(), hasLength(120));
    });

    test('no placeholder or ellipsis markers', () {
      final pattern = RegExp(
        r'//\s*TODO|/\*\s*TODO|FIXME|<code>|placeholder|待补|待实现|未完待续',
        caseSensitive: false,
      );
      for (final tutorial in catalog.tutorials) {
        final lesson = tutorial.lessons.first;
        expect(pattern.hasMatch(lesson.code), isFalse, reason: tutorial.id);
        expect(pattern.hasMatch(lesson.explain), isFalse, reason: tutorial.id);
      }
      for (final example in catalog.examples) {
        expect(pattern.hasMatch(example.code), isFalse, reason: example.id);
      }
    });

    test('code is genuinely multi-line with a main entry', () {
      for (final tutorial in catalog.tutorials) {
        final lesson = tutorial.lessons.first;
        expect(
          lesson.code.split('\n').length,
          greaterThanOrEqualTo(3),
          reason: '${tutorial.id} needs real structure',
        );
        expect(
          lesson.code.contains('main('),
          isTrue,
          reason: '${tutorial.id} needs a main function',
        );
      }
    });

    test('lesson code bodies are unique after normalization', () {
      final bodies = catalog.tutorials
          .map((t) => _normalize(t.lessons.first.code))
          .toList();
      expect(bodies.toSet(), hasLength(120));
    });

    test('example code bodies are unique after normalization', () {
      final bodies = catalog.examples.map((e) => _normalize(e.code)).toList();
      expect(bodies.toSet(), hasLength(120));
    });

    test('exactly one introductory Hello-World topic', () {
      final hello = catalog.examples
          .where((e) => e.code.contains('Hello, Dart!'))
          .toList();
      expect(hello, hasLength(1));
      expect(hello.single.id, 'dart-example-001');
    });

    test('progression spans beginner, intermediate and advanced', () {
      final levels = catalog.tutorials.map((t) => t.level).toSet();
      expect(
        levels,
        containsAll(<String>['beginner', 'intermediate', 'advanced']),
      );
    });

    test('license mirrors the existing Dart content value', () {
      for (final tutorial in catalog.tutorials) {
        expect(
          tutorial.license,
          'Original QFLI curriculum; reference link retained. CC BY 4.0',
          reason: tutorial.id,
        );
      }
    });

    test('every lesson and example carries a visible engine requirement', () {
      // Engine notes must be in the rendered fields (explain / example summary),
      // driven by the shared verified whitelist, not only a test constant.
      for (final tutorial in catalog.tutorials) {
        final isEval = DartCurriculum.dartEvalVerifiedIds.contains(tutorial.id);
        final lesson = tutorial.lessons.first;
        if (isEval) {
          expect(
            lesson.explain,
            contains('dart_eval'),
            reason: '${tutorial.id} should say dart_eval-capable',
          );
        } else {
          expect(
            lesson.explain,
            contains('需要官方 Dart SDK'),
            reason: '${tutorial.id} should say official-SDK-required',
          );
        }
      }
      for (final example in catalog.examples) {
        final lessonId = example.sourceLessonId!;
        final isEval = DartCurriculum.dartEvalVerifiedIds.contains(lessonId);
        expect(
          example.summary,
          contains(isEval ? '均可' : '需官方 Dart SDK'),
          reason: example.id,
        );
      }
    });

    test('no whitelist lesson body contradicts its engine note', () {
      // A dart_eval-verified lesson must not still say, in its authored prose,
      // that it requires the official SDK.
      final contradictory = RegExp(
        r'需要官方 Dart SDK|必须在官方|在官方 Dart SDK 引擎上运行',
      );
      for (final tutorial in catalog.tutorials) {
        if (!DartCurriculum.dartEvalVerifiedIds.contains(tutorial.id)) continue;
        final explain = tutorial.lessons.first.explain;
        final body = explain.split('运行要求：').first;
        expect(
          contradictory.hasMatch(body),
          isFalse,
          reason: '${tutorial.id} prose contradicts its dart_eval support',
        );
      }
    });
  });

  group('adapter projection (what the pages actually render)', () {
    test('adapter yields 120 lessons with the new Chinese runtime labels', () async {
      final previous = StudioProfile.current;
      StudioProfile.current = null;
      addTearDown(() => StudioProfile.current = previous);

      final tutorial = await LocalContentAdapter.loadTutorial(
        repository: DartContentRepository(),
        language: 'dart',
        displayName: 'Dart',
      );
      expect(tutorial, isNotNull);
      expect(tutorial!.lessonCount, 120);
      final first = tutorial.allLessons.first;
      expect(first.objective.trim(), isNotEmpty);
      expect(first.pitfalls, isNotEmpty);
      expect(first.explain.trim(), isNotEmpty);
    });

    test('adapter yields 120 examples', () async {
      final examples = await LocalContentAdapter.loadExamples(
        repository: DartContentRepository(),
        language: 'dart',
      );
      expect(examples, hasLength(120));
    });
  });
}

String _normalize(String code) => code.replaceAll(RegExp(r'\s+'), ' ').trim();
