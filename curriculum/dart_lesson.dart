/// Authoring model for the QFLIDartWing 120-lesson curriculum.
///
/// This is the single source of truth for lesson content. It is authored in
/// Dart (typed, greppable, reviewable) and emitted to the two aggregate asset
/// files by `tool/build_dart_content.dart`.
///
/// Only fields the existing core detail page can render are carried here:
/// `objective`, `prerequisites`, `explain`, `code`, `output`, `pitfalls`,
/// `exercises` (`core/lib/pages/local_content_pages.dart`). There is no
/// `engine` field in the parser, so runtime/engine compatibility must be stated
/// inside [DartLesson.explain] (optionally echoed in [pitfalls]).
library;

/// One authored lesson plus its paired example.
///
/// A lesson and its own paired example MAY share [code]; the 120-uniqueness bar
/// applies within each type (120 distinct lessons, 120 distinct examples), not
/// across the pair.
class DartLesson {
  const DartLesson({
    required this.id,
    required this.chapter,
    required this.level,
    required this.title,
    required this.summary,
    required this.concepts,
    required this.explain,
    required this.objective,
    required this.pitfalls,
    required this.code,
    required this.output,
    required this.exercises,
    required this.exampleTitle,
    required this.exampleSummary,
    this.prerequisites = const <String>[],
    this.exampleCode,
  });

  /// Stable lesson id, `dart-lesson-NNN` (001..120). Also the tutorial entry id.
  final String id;

  /// Chapter key; see [DartChapter].
  final String chapter;

  /// `beginner` | `intermediate` | `advanced`.
  final String level;

  final String title;
  final String summary;
  final List<String> concepts;

  /// Real Chinese teaching prose. Must be unique across the curriculum.
  final String explain;

  /// One-line learning objective.
  final String objective;

  /// Knowledge the learner should already have. Engine-requirement notes live
  /// here or in [explain]; both are rendered.
  final List<String> prerequisites;

  /// Common mistakes and caveats. Must be non-empty.
  final List<String> pitfalls;

  /// Complete, runnable, multi-line program. Self-contained: no stdin, no
  /// network. IO lessons create their own temporary files and clean up.
  final String code;

  /// Exact stdout produced by [code].
  final String output;

  final List<DartExercise> exercises;

  /// Paired example metadata.
  final String exampleTitle;
  final String exampleSummary;

  /// Example code. Defaults to [code] when null (the common case).
  final String? exampleCode;

  String get lessonId => '$id-lesson';
  String get exampleId => id.replaceFirst('dart-lesson-', 'dart-example-');

  String get resolvedExampleCode => exampleCode ?? code;
}

/// One practice exercise.
class DartExercise {
  const DartExercise({
    required this.prompt,
    required this.hint,
    required this.answer,
  });

  final String prompt;
  final String hint;
  final String answer;
}

/// A chapter grouping. Only the display title is authored; the 120 count is
/// enforced per-chapter by the generator's checks.
class DartChapter {
  const DartChapter({required this.key, required this.title});

  final String key;
  final String title;
}
