// Draft content gate for the 180 expansion lessons (dart-lesson-121..300).
//
// This verifier is deliberately INDEPENDENT of the curriculum aggregate and of
// the generated assets:
//
//   * The expected inventory (180 lessons, ids 121..300, 16 chapters, one
//     standalone exercise per lesson) is declared HERE as constants, so a
//     missing, extra, duplicated or misplaced draft is reported instead of
//     silently shrinking the gate.
//   * Draft bodies are read from `curriculum/chapters/*.dart` directly, because
//     `curriculum/dart_curriculum.dart` (the aggregate) and `assets/content`
//     are not this tool's to change during the draft phase.
//
// Every unit — each lesson, each paired example, each standalone exercise — is
// executed twice:
//
//   * real official Dart SDK, through `NativeDartToolchain` (the same
//     resolution/argument path the app uses), and
//   * the actual production portable helper `runPortableContent`
//     (tom_d4rt through `PortableDartRuntime`), including its own isolate
//     supervision, IO policy and cancellation.
//
// Lesson and example stdout is compared against the authored `output`.
// Exercise stdout has no authored expectation by design: the real SDK run is the
// reference and the portable engine must reproduce it exactly. Nothing in this
// file fabricates, trims or re-derives an expected value.
//
// Usage (run from the repository root):
//
//   dart run tool/verify_draft_content.dart                      # full gate
//   dart run tool/verify_draft_content.dart --chapter=mini-apps
//   dart run tool/verify_draft_content.dart --start=250 --end=261
//   dart run tool/verify_draft_content.dart --kind=exercise
//   dart run tool/verify_draft_content.dart --limit=20
//   dart run tool/verify_draft_content.dart --inventory-only
//
// Filters change WHAT THIS RUN EXECUTES, never the denominator: `gate.covered`
// stays false and the exit code stays non-zero until the full inventory has been
// executed and passed. See research/draft-verifier.md for the contract.
//
// Exit codes: 0 gate ok · 1 content/behaviour failure · 2 infrastructure
// failure (SDK missing/crashed/OOM) · 3 usage error · 4 partial (filtered /
// limited / inventory-only) with no failures.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:qfli_dart/native_dart_toolchain.dart';

import '../curriculum/chapters/algorithms_advanced.dart';
import '../curriculum/chapters/algorithms_basic.dart';
import '../curriculum/chapters/apis_contracts.dart';
import '../curriculum/chapters/async_patterns.dart';
import '../curriculum/chapters/collection_reporting.dart';
import '../curriculum/chapters/data_structures.dart';
import '../curriculum/chapters/dates_money.dart';
import '../curriculum/chapters/enum_states.dart';
import '../curriculum/chapters/errors_resilience.dart';
import '../curriculum/chapters/formatting_output.dart';
import '../curriculum/chapters/json_modeling.dart';
import '../curriculum/chapters/math_stats.dart';
import '../curriculum/chapters/mini_apps.dart';
import '../curriculum/chapters/numbers_strings.dart';
import '../curriculum/chapters/oop_modeling.dart';
import '../curriculum/chapters/text_processing.dart';
import '../curriculum/dart_lesson.dart';
import 'portable_content_runner.dart';

/// The JSON map shape every report node uses.
typedef Json = Map<String, Object?>;

// ---------------------------------------------------------------------------
// Independent expected inventory. Changing these numbers is a deliberate act:
// they define what "complete" means and they must not track the authored files.
// ---------------------------------------------------------------------------

/// First and last draft lesson number (inclusive).
const int _firstLessonNumber = 121;
const int _lastLessonNumber = 300;

/// Expected totals. Exercises are one standalone program per lesson by design.
const int _expectedLessons = 180;
const int _expectedExamples = 180;
const int _expectedExercises = 180;
const int _expectedExercisesPerLesson = 1;

/// `chapter key -> [first lesson number, last lesson number]`.
///
/// Ascending by first id, contiguous, and summing to [_expectedLessons].
const Map<String, List<int>> _expectedChapters = <String, List<int>>{
  'numbers-strings': <int>[121, 132],
  'text-processing': <int>[133, 144],
  'algorithms-basic': <int>[145, 156],
  'algorithms-advanced': <int>[157, 168],
  'data-structures': <int>[169, 180],
  'math-stats': <int>[181, 192],
  'oop-modeling': <int>[193, 204],
  'enum-states': <int>[205, 215],
  'errors-resilience': <int>[216, 226],
  'json-modeling': <int>[227, 238],
  'dates-money': <int>[239, 249],
  'collection-reporting': <int>[250, 261],
  'formatting-output': <int>[262, 272],
  'async-patterns': <int>[273, 283],
  'apis-contracts': <int>[284, 294],
  'mini-apps': <int>[295, 300],
};

/// Placeholder markers that must never appear in shipped teaching code.
final RegExp _placeholderPattern = RegExp(
  r'//\s*TODO|/\*\s*TODO|FIXME|<code>|placeholder|待补|待实现|未完待续',
  caseSensitive: false,
);

/// How much captured text a single unit record may carry.
const int _maxCapturedChars = 4000;

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final BaseOptions options;
  try {
    options = BaseOptions.parse(args);
  } on FormatException catch (error) {
    stderr.writeln('usage error: ${error.message}');
    stderr.writeln(BaseOptions.usage);
    exitCode = 3;
    return;
  }
  if (options.help) {
    stdout.writeln(BaseOptions.usage);
    return;
  }

  // Trust the local digest only after it reproduces the published vectors: a
  // wrong hash would make the recorded source, stdout and output hashes
  // untrustworthy, and silence is worse than a loud infrastructure exit here.
  try {
    _selfCheckSha256();
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
    return;
  }

  final root = _repositoryRoot();
  final reportPath = options.reportPath ?? p.join(
    root.path,
    '.dart_tool',
    'expansion-b',
    'draft-verify${options.reportSuffix}.json',
  );

  final report = DraftReport(
    reportPath: File(reportPath),
    options: options,
    rootPath: root.path,
  )..inventory = _buildInventory();

  final plan = report.plan;
  stdout.writeln(
    'inventory: ${report.inventory.lessonIds.length} lessons, '
    '${report.inventory.lessonIds.length} examples, '
    '${report.inventory.exercisesPerLesson} exercise(s)/lesson',
  );
  stdout.writeln(
    'plan: ${plan.units.length} units selected of '
    '${report.inventory.totalUnits} expected '
    '(${plan.skippedByFilter} skipped by filter, '
    '${plan.skippedByLimit} by --limit)',
  );

  // Structure checks and the first report write happen before any engine work,
  // so a durable record survives a later SDK or runtime startup failure.
  report.runStaticChecks();
  report.flush();

  if (options.inventoryOnly) {
    report.finish(reason: 'inventory-only');
    exitCode = report.exitCode;
    return;
  }

  if (!NativeDartToolchain.supported) {
    report.noteInfrastructure(
      'official Dart SDK is not supported on ${Platform.operatingSystem}; '
      'no unit can be executed',
    );
    report.finish(reason: 'sdk-unsupported-platform');
    exitCode = report.exitCode;
    return;
  }

  // Non-nullable and definitely assigned: every exit path above returns, so
  // the run loop always has a real SDK executable.
  final String sdkExecutable;
  try {
    sdkExecutable = await const NativeDartToolchain().resolveExecutable();
  } on Object catch (error) {
    report.noteInfrastructure('cannot resolve the official Dart SDK: $error');
    report.finish(reason: 'sdk-unresolved');
    exitCode = report.exitCode;
    return;
  }
  report.sdkExecutable = sdkExecutable;

  final packageConfig = File(
    p.join(root.path, '.dart_tool', 'package_config.json'),
  );
  final packageConfigPath =
      await packageConfig.exists() ? packageConfig.path : null;

  final scratch = await Directory.systemTemp.createTemp('qfli_draft_verify_');
  try {
    for (final unit in plan.units) {
      if (report.halted) {
        report.markNotRun(unit, 'halted after infrastructure failure');
        continue;
      }
      await report.runUnit(
        unit,
        sdkExecutable: sdkExecutable,
        packageConfigPath: packageConfigPath,
        scratch: scratch,
      );
      final record = report.lastRecord!;
      stdout.writeln(
        '${record.passed ? 'PASS' : 'FAIL'} ${unit.key}'
        '${record.passed ? '' : '  ${record.failure ?? ''}'}',
      );
      report.flush();
    }
    // Units that a filter removed are recorded, never dropped, so the report
    // always accounts for the whole inventory.
    report.markFilteredOut(plan);
  } finally {
    // Report a cleanup failure instead of assuming the OS reclaims the path.
    final cleanupError = await _deleteScratch(scratch);
    if (cleanupError != null) {
      report.noteCleanup(cleanupError);
      stderr.writeln(cleanupError);
    }
  }

  report.finish();
  exitCode = report.exitCode;
}

// ---------------------------------------------------------------------------
// Options
// ---------------------------------------------------------------------------

class BaseOptions {
  const BaseOptions({
    this.chapters = const <String>{},
    this.kinds,
    this.start,
    this.end,
    this.limit,
    this.inventoryOnly = false,
    this.help = false,
    this.reportPath,
    this.sdkTimeout = const Duration(seconds: 30),
    this.portableTimeout = const Duration(seconds: 10),
  });

  final Set<String> chapters;

  /// `null` means every kind. Values are `lesson`, `example`, `exercise`.
  final Set<String>? kinds;
  final int? start;
  final int? end;
  final int? limit;
  final bool inventoryOnly;
  final bool help;
  final String? reportPath;
  final Duration sdkTimeout;
  final Duration portableTimeout;

  static const String usage = '''
Draft content gate — 180 expansion lessons (dart-lesson-121..300).

  --chapter=<key>     restrict to a chapter key (repeatable / comma separated)
  --start=<n>         lowest lesson number to select
  --end=<n>           highest lesson number to select
  --kind=<list>       lesson, example, exercise (repeatable / comma separated)
  --limit=<n>         execute at most n selected units (bounded validation)
  --report=<path>     report path (default .dart_tool/expansion-b/draft-verify*.json)
  --sdk-timeout=<s>   per-unit official SDK lifetime (default 30s)
  --portable-timeout=<s> per-unit portable lifetime (default 10s)
  --inventory-only    structure checks only; never a passing gate
  --help              this text

Filters never lower the denominator: the gate stays incomplete and the exit code
stays non-zero until the full inventory has executed and passed.

--resume is refused on purpose. A stored pass does not fingerprint the SDK, the
portable vendor, the expected stdout or the engine evidence, so it cannot stand
in for a run in the current environment. Every selected unit always runs.
''';

  String get reportSuffix {
    final parts = <String>[
      if (chapters.isNotEmpty)
        'chapters-${(chapters.toList()..sort()).join('+')}',
      if (kinds != null) 'kinds-${(kinds!.toList()..sort()).join('+')}',
      if (start != null) 'from-$start',
      if (end != null) 'to-$end',
      if (limit != null) 'limit-$limit',
      if (inventoryOnly) 'inventory',
    ];
    if (parts.isEmpty) return '';
    return '-${parts.join('-')}';
  }

  static BaseOptions parse(List<String> args) {
    final chapters = <String>{};
    Set<String>? kinds;
    int? start;
    int? end;
    int? limit;
    var inventoryOnly = false;
    var help = false;
    String? reportPath;
    var sdkTimeout = const Duration(seconds: 30);
    var portableTimeout = const Duration(seconds: 10);

    int requireInt(String flag, String value) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw FormatException('$flag expects an integer, got "$value"');
      }
      return parsed;
    }

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        help = true;
        continue;
      }
      if (arg == '--resume') {
        // Refused, not silently ignored: a stored pass is not a fingerprint of
        // the SDK, the portable vendor, the expected stdout or the engine
        // evidence, so it cannot count as a pass in this environment.
        throw const FormatException(
          '--resume is disabled: a prior pass does not fingerprint the SDK, '
          'portable vendor, expected stdout or engine evidence, so it cannot '
          'count as a current pass. Every selected unit must run.',
        );
      }
      if (arg == '--inventory-only') {
        inventoryOnly = true;
        continue;
      }
      if (!arg.startsWith('--')) {
        throw FormatException('unexpected positional argument "$arg"');
      }
      final separator = arg.indexOf('=');
      if (separator < 0) {
        throw FormatException('option "$arg" needs a value (--name=value)');
      }
      final flag = arg.substring(0, separator);
      final value = arg.substring(separator + 1);
      switch (flag) {
        case '--chapter':
          for (final key in value.split(',')) {
            final trimmed = key.trim();
            if (trimmed.isEmpty) {
              throw const FormatException('--chapter has an empty key');
            }
            if (!_expectedChapters.containsKey(trimmed)) {
              throw FormatException(
                'unknown chapter "$trimmed"; expected one of '
                '${_expectedChapters.keys.join(', ')}',
              );
            }
            chapters.add(trimmed);
          }
        case '--kind':
          kinds ??= <String>{};
          for (final kind in value.split(',')) {
            final trimmed = kind.trim();
            if (trimmed == 'all') {
              kinds = null;
              break;
            }
            if (!const <String>{'lesson', 'example', 'exercise'}
                .contains(trimmed)) {
              throw FormatException(
                'unknown kind "$trimmed"; expected lesson, example or exercise',
              );
            }
            kinds!.add(trimmed);
          }
        case '--start':
          start = requireInt(flag, value);
        case '--end':
          end = requireInt(flag, value);
        case '--limit':
          limit = requireInt(flag, value);
          if (limit <= 0) {
            throw const FormatException('--limit must be positive');
          }
        case '--report':
          if (value.trim().isEmpty) {
            throw const FormatException('--report needs a path');
          }
          reportPath = value;
        case '--sdk-timeout':
          sdkTimeout = Duration(seconds: requireInt(flag, value));
        case '--portable-timeout':
          portableTimeout = Duration(seconds: requireInt(flag, value));
        default:
          throw FormatException('unknown option "$flag"');
      }
    }
    if (start != null && end != null && start > end) {
      throw FormatException('--start=$start is after --end=$end');
    }
    return BaseOptions(
      chapters: chapters,
      kinds: kinds,
      start: start,
      end: end,
      limit: limit,
      inventoryOnly: inventoryOnly,
      help: help,
      reportPath: reportPath,
      sdkTimeout: sdkTimeout,
      portableTimeout: portableTimeout,
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory
// ---------------------------------------------------------------------------

enum UnitKind { lesson, example, exercise }

String _lessonIdFor(int number) =>
    'dart-lesson-${number.toString().padLeft(3, '0')}';

String _exampleIdFor(int number) =>
    'dart-example-${number.toString().padLeft(3, '0')}';

/// The expected inventory, derived only from this file's constants.
class ExpectedInventory {
  ExpectedInventory();

  final List<String> lessonIds = <String>[];
  final Map<String, String> lessonChapter = <String, String>{};
  final Map<String, int> lessonNumber = <String, int>{};
  late final int exercisesPerLesson = _expectedExercisesPerLesson;

  int get exampleCount => lessonIds.length;
  int get exerciseCount => lessonIds.length * exercisesPerLesson;
  int get totalUnits => lessonIds.length + exampleCount + exerciseCount;

  String chapterOfLesson(String lessonId) =>
      lessonChapter[lessonId] ?? '<unknown-chapter>';

  int numberOfLesson(String lessonId) => lessonNumber[lessonId] ?? -1;
}

ExpectedInventory _buildInventory() {
  final inventory = ExpectedInventory();
  for (var number = _firstLessonNumber; number <= _lastLessonNumber; number++) {
    final id = _lessonIdFor(number);
    inventory.lessonIds.add(id);
    inventory.lessonNumber[id] = number;
  }
  for (final entry in _expectedChapters.entries) {
    for (var number = entry.value[0]; number <= entry.value[1]; number++) {
      inventory.lessonChapter[_lessonIdFor(number)] = entry.key;
    }
  }
  return inventory;
}

/// One executable unit: a lesson body, its paired example body, or one
/// standalone exercise answer.
class Unit {
  const Unit({
    required this.kind,
    required this.lessonId,
    required this.chapter,
    required this.number,
    required this.source,
    required this.sourceOrigin,
    this.exerciseIndex = 0,
    this.expectedOutput,
    this.sharedBodyWithLesson = false,
    this.structureProblem,
  });

  final UnitKind kind;
  final String lessonId;
  final String chapter;
  final int number;

  /// The exact program text that will be written to disk and hashed.
  final String source;

  /// Where [source] came from, so a reader can tell an authored body from a
  /// missing one: `authored`, `shared-with-lesson`, `missing`.
  final String sourceOrigin;

  final int exerciseIndex;

  /// Authored expectation for lessons and examples. `null` for exercises,
  /// whose reference is the real SDK run.
  final String? expectedOutput;
  final bool sharedBodyWithLesson;

  /// Set when the unit cannot even be built from the drafts (missing lesson,
  /// missing exercise). Recorded as a failure, never skipped.
  final String? structureProblem;

  String get kindLabel => switch (kind) {
    UnitKind.lesson => 'lesson',
    UnitKind.example => 'example',
    UnitKind.exercise => 'exercise$exerciseIndex',
  };

  String get key => switch (kind) {
    UnitKind.lesson => lessonId,
    UnitKind.example => _exampleIdFor(number),
    UnitKind.exercise => '$lessonId:exercise$exerciseIndex',
  };

  String get fileName => key.replaceAll(':', '-');
}

class Plan {
  Plan({
    required this.units,
    required this.skippedByFilter,
    required this.skippedByLimit,
  });

  final List<Unit> units;
  final int skippedByFilter;
  final int skippedByLimit;
}

/// Builds units for the whole inventory, then applies filters for selection.
///
/// The units list is always generated from the independent inventory, so a
/// draft that is absent, duplicated or mis-numbered becomes a failing unit
/// instead of a smaller gate.
Plan _buildPlan(
  ExpectedInventory inventory,
  BaseOptions options,
  List<DartLesson> authoredLessons,
) {
  final byId = <String, DartLesson>{};
  final duplicates = <String>[];
  for (final lesson in authoredLessons) {
    if (byId.containsKey(lesson.id)) {
      duplicates.add(lesson.id);
    } else {
      byId[lesson.id] = lesson;
    }
  }

  final units = <Unit>[];
  for (final lessonId in inventory.lessonIds) {
    final chapter = inventory.chapterOfLesson(lessonId);
    final number = inventory.numberOfLesson(lessonId);
    final lesson = byId[lessonId];
    final duplicateNote = duplicates.contains(lessonId)
        ? 'duplicate authored lesson id $lessonId'
        : null;

    units.add(
      Unit(
        kind: UnitKind.lesson,
        lessonId: lessonId,
        chapter: chapter,
        number: number,
        source: lesson?.code ?? '',
        sourceOrigin: lesson == null ? 'missing' : 'authored',
        expectedOutput: lesson?.output,
        structureProblem: lesson == null
            ? 'lesson $lessonId is declared in the expected inventory but no '
                  'draft provides it'
            : duplicateNote,
      ),
    );

    final exampleCode = lesson?.resolvedExampleCode;
    units.add(
      Unit(
        kind: UnitKind.example,
        lessonId: lessonId,
        chapter: chapter,
        number: number,
        source: exampleCode ?? '',
        sourceOrigin: lesson == null
            ? 'missing'
            : (lesson.exampleCode == null ? 'shared-with-lesson' : 'authored'),
        expectedOutput: lesson?.output,
        sharedBodyWithLesson:
            lesson != null &&
            lesson.exampleCode == null &&
            lesson.code.isNotEmpty,
        structureProblem: lesson == null
            ? 'example $_exampleIdFor(number) has no paired draft'
            : duplicateNote,
      ),
    );

    final exercises = lesson?.exercises ?? const <DartExercise>[];
    final expectedExerciseCount = inventory.exercisesPerLesson;
    final totalExercises = exercises.length;
    for (var index = 1; index <= (totalExercises < expectedExerciseCount
        ? expectedExerciseCount
        : totalExercises); index++) {
      final exercise = index <= totalExercises ? exercises[index - 1] : null;
      units.add(
        Unit(
          kind: UnitKind.exercise,
          lessonId: lessonId,
          chapter: chapter,
          number: number,
          exerciseIndex: index,
          source: exercise?.answer ?? '',
          sourceOrigin: exercise == null ? 'missing' : 'authored',
          structureProblem: exercise == null
              ? '$lessonId is missing exercise $index'
              : (totalExercises != expectedExerciseCount
                    ? '$lessonId authored $totalExercises exercises, expected '
                          '$expectedExerciseCount'
                    : duplicateNote),
        ),
      );
    }
  }

  var skippedByFilter = 0;
  final selected = <Unit>[];
  for (final unit in units) {
    if (!_selects(options, unit)) {
      skippedByFilter++;
      continue;
    }
    selected.add(unit);
  }
  if (options.limit != null && selected.length > options.limit!) {
    final dropped = selected.length - options.limit!;
    return Plan(
      units: selected.sublist(0, options.limit!),
      skippedByFilter: skippedByFilter,
      skippedByLimit: dropped,
    );
  }
  return Plan(
    units: selected,
    skippedByFilter: skippedByFilter,
    skippedByLimit: 0,
  );
}

bool _selects(BaseOptions options, Unit unit) {
  if (options.chapters.isNotEmpty && !options.chapters.contains(unit.chapter)) {
    return false;
  }
  if (options.start != null && unit.number < options.start!) return false;
  if (options.end != null && unit.number > options.end!) return false;
  final kinds = options.kinds;
  if (kinds != null && !kinds.contains(unit.kind.name)) return false;
  return true;
}

/// The 16 draft chapter lists, read directly because the aggregate and the
/// generated assets are out of scope for this gate.
List<DartLesson> _authoredDraftLessons() => <DartLesson>[
  ...numbersStringsLessons,
  ...textProcessingLessons,
  ...algorithmsBasicLessons,
  ...algorithmsAdvancedLessons,
  ...dataStructuresLessons,
  ...mathStatsLessons,
  ...oopModelingLessons,
  ...enumStatesLessons,
  ...errorsResilienceLessons,
  ...jsonModelingLessons,
  ...datesMoneyLessons,
  ...collectionReportingLessons,
  ...formattingOutputLessons,
  ...asyncPatternsLessons,
  ...apisContractsLessons,
  ...miniAppsLessons,
];

// ---------------------------------------------------------------------------
// Normalisation: the only tolerance is line endings and one trailing newline.
// Spaces are significant everywhere, including trailing ones.
// ---------------------------------------------------------------------------

String _normaliseLineEndings(String text) => text.replaceAll('\r\n', '\n');

/// Whether [actual] represents [expected] exactly.
///
/// Accepted differences, and nothing else:
///   * `\r\n` versus `\n` for every line ending;
///   * exactly one trailing newline present on one side only.
///
/// Spaces are never trimmed, so a collapsed or padded output is a failure.
bool stdoutMatches(String expected, String actual) {
  final e = _normaliseLineEndings(expected);
  final a = _normaliseLineEndings(actual);
  if (e == a) return true;
  if ('$e\n' == a) return true;
  if (e == '$a\n') return true;
  return false;
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

class UnitRecord {
  UnitRecord({
    required this.unit,
    required this.sourceHash,
    required this.sourceLength,
  });

  final Unit unit;
  final String sourceHash;
  final int sourceLength;

  bool passed = false;
  String? failure;
  bool infrastructure = false;
  bool notRun = false;

  SdkRun? sdk;
  PortableRun? portable;

  Json toJson({bool includeCaptured = false}) => <String, Object?>{
    'unit': unit.key,
    'kind': unit.kindLabel,
    'lessonId': unit.lessonId,
    'chapter': unit.chapter,
    'number': unit.number,
    'sourceOrigin': unit.sourceOrigin,
    'sharedBodyWithLesson': unit.sharedBodyWithLesson,
    'sourceHash': sourceHash,
    'sourceLength': sourceLength,
    'expectedKind': unit.expectedOutput == null ? 'sdk-reference' : 'authored',
    'passed': passed,
    if (failure != null) 'failure': failure,
    if (infrastructure) 'infrastructure': true,
    if (notRun) 'notRun': true,
    if (sdk != null) 'sdk': sdk!.toJson(includeCaptured: includeCaptured),
    if (portable != null)
      'portable': portable!.toJson(includeCaptured: includeCaptured),
  };
}

class SdkRun {
  const SdkRun({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
    required this.launchError,
    required this.streamError,
    required this.durationMs,
  });

  final int? exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
  final String? launchError;

  /// Set when the output pipes did not close in time. [stdout] and [stderr] are
  /// then unknown, not empty, and must never be compared or reported as content.
  final String? streamError;
  final int durationMs;

  Json toJson({required bool includeCaptured}) => <String, Object?>{
    'exitCode': exitCode,
    'timedOut': timedOut,
    if (launchError != null) 'launchError': launchError,
    if (streamError != null) 'streamError': _capture(streamError!),
    'durationMs': durationMs,
    // A closed pipe is evidence; a pipe that never closed is not. When the drain
    // failed, the report says the streams are unknown instead of showing an
    // empty string that could be mistaken for real empty output.
    if (streamError == null) ...<String, Object?>{
      'stderr': _capture(stderr),
      'stdoutLength': stdout.length,
      'stdoutHash': sha256Hex(utf8.encode(stdout)),
      if (includeCaptured) 'stdout': _capture(stdout),
    } else ...<String, Object?>{'stdoutKnown': false, 'stderrKnown': false},
  };
}

class PortableRun {
  const PortableRun({
    required this.output,
    required this.error,
    required this.timedOut,
    required this.durationMs,
  });

  final String output;
  final String? error;
  final bool timedOut;
  final int durationMs;

  Json toJson({required bool includeCaptured}) => <String, Object?>{
    'timedOut': timedOut,
    if (error != null) 'error': _capture(error!),
    'durationMs': durationMs,
    'outputLength': output.length,
    'outputHash': sha256Hex(utf8.encode(output)),
    if (includeCaptured) 'output': _capture(output),
  };
}

String _capture(String text) {
  if (text.length <= _maxCapturedChars) return text;
  return '${text.substring(0, _maxCapturedChars)}\n…[truncated '
      '${text.length - _maxCapturedChars} chars]';
}

class DraftReport {
  DraftReport({
    required this.reportPath,
    required this.options,
    required this.rootPath,
  });

  final File reportPath;
  final BaseOptions options;
  final String rootPath;

  late final ExpectedInventory inventory;
  String? sdkExecutable;

  final List<String> structureFailures = <String>[];
  final List<String> infrastructureNotes = <String>[];
  final List<String> cleanupFailures = <String>[];
  final List<UnitRecord> records = <UnitRecord>[];
  final Set<String> _recordedKeys = <String>{};

  UnitRecord? lastRecord;
  bool halted = false;
  String? _reason;

  int _passed = 0;
  int _failed = 0;
  int _infrastructureCount = 0;
  int _notRun = 0;

  /// Built once, lazily, from the independent inventory.
  ///
  /// There is deliberately no reuse of a previous run's verdicts: a stored pass
  /// is not a fingerprint of the current SDK, portable vendor, expected stdout
  /// or engine evidence, so every selected unit is executed in this run.
  late final Plan plan = _buildPlan(
    inventory,
    options,
    _authoredDraftLessons(),
  );

  void runStaticChecks() {
    final lessons = _authoredDraftLessons();

    // Identity: exactly the declared ids, no gaps, no extras, no duplicates.
    final seen = <String>{};
    final duplicates = <String>[];
    final outOfRange = <String>[];
    final misplaced = <String>[];
    for (final lesson in lessons) {
      if (!seen.add(lesson.id)) duplicates.add(lesson.id);
      if (!inventory.lessonIds.contains(lesson.id)) {
        outOfRange.add(lesson.id);
      } else if (lesson.chapter != inventory.chapterOfLesson(lesson.id)) {
        misplaced.add(
          '${lesson.id} declares chapter "${lesson.chapter}", expected '
          '"${inventory.chapterOfLesson(lesson.id)}"',
        );
      }
    }
    final missing = inventory.lessonIds.where((id) => !seen.contains(id));

    if (lessons.length != _expectedLessons) {
      structureFailures.add(
        'authored draft lessons: ${lessons.length}, expected $_expectedLessons',
      );
    }
    if (missing.isNotEmpty) {
      structureFailures.add('missing draft lessons: ${missing.join(', ')}');
    }
    if (duplicates.isNotEmpty) {
      structureFailures.add(
        'duplicate draft lesson ids: ${duplicates.join(', ')}',
      );
    }
    if (outOfRange.isNotEmpty) {
      structureFailures.add(
        'draft lesson ids outside $_firstLessonNumber..$_lastLessonNumber: '
        '${outOfRange.join(', ')}',
      );
    }
    structureFailures.addAll(misplaced);

    final exerciseTotal = lessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.exercises.length,
    );
    if (exerciseTotal != _expectedExercises) {
      structureFailures.add(
        'standalone exercises: $exerciseTotal, expected $_expectedExercises',
      );
    }

    // Per-lesson content requirements.
    final lessonBodies = <String, String>{};
    final exampleBodies = <String, String>{};
    final explains = <String, String>{};
    final titles = <String, String>{};
    final summaries = <String, String>{};
    final exampleTitles = <String, String>{};
    final exampleSummaries = <String, String>{};

    void requireText(String id, String label, String value) {
      if (value.trim().isEmpty) {
        structureFailures.add('$id: $label must not be empty');
      }
    }

    void requireUnique(
      Map<String, String> table,
      String id,
      String label,
      String value,
    ) {
      final normalised = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalised.isEmpty) return;
      final previous = table[normalised];
      if (previous != null) {
        structureFailures.add('$id: $label duplicates $previous');
      } else {
        table[normalised] = id;
      }
    }

    for (final lesson in lessons) {
      final id = lesson.id;
      requireText(id, 'title', lesson.title);
      requireText(id, 'summary', lesson.summary);
      requireText(id, 'explain', lesson.explain);
      requireText(id, 'objective', lesson.objective);
      requireText(id, 'code', lesson.code);
      requireText(id, 'output', lesson.output);
      requireText(id, 'exampleTitle', lesson.exampleTitle);
      requireText(id, 'exampleSummary', lesson.exampleSummary);
      if (lesson.concepts.isEmpty) {
        structureFailures.add('$id: concepts must not be empty');
      }
      if (lesson.pitfalls.isEmpty) {
        structureFailures.add('$id: pitfalls must not be empty');
      }
      if (lesson.exercises.isEmpty) {
        structureFailures.add('$id: exercises must not be empty');
      }
      for (final exercise in lesson.exercises) {
        requireText(id, 'exercise.prompt', exercise.prompt);
        requireText(id, 'exercise.hint', exercise.hint);
        requireText(id, 'exercise.answer', exercise.answer);
        if (exercise.answer.trim().isNotEmpty &&
            !exercise.answer.contains('main(')) {
          structureFailures.add('$id: exercise answer has no main()');
        }
      }

      // Real structure, not a one-liner.
      if (lesson.code.isNotEmpty) {
        if (lesson.code.split('\n').length < 3) {
          structureFailures.add('$id: code needs at least three lines');
        }
        if (!lesson.code.contains('main(')) {
          structureFailures.add('$id: code has no main()');
        }
        if (_placeholderPattern.hasMatch(lesson.code)) {
          structureFailures.add('$id: code contains a placeholder marker');
        }
      }
      if (_placeholderPattern.hasMatch(lesson.explain)) {
        structureFailures.add('$id: explain contains a placeholder marker');
      }

      requireUnique(explains, id, 'explain', lesson.explain);
      requireUnique(titles, id, 'title', lesson.title);
      requireUnique(summaries, id, 'summary', lesson.summary);
      requireUnique(exampleTitles, id, 'exampleTitle', lesson.exampleTitle);
      requireUnique(
        exampleSummaries,
        id,
        'exampleSummary',
        lesson.exampleSummary,
      );
      requireUnique(lessonBodies, id, 'lesson code', lesson.code);
      requireUnique(
        exampleBodies,
        id,
        'example code',
        lesson.resolvedExampleCode,
      );
    }

    if (lessonBodies.length != lessons.length &&
        lessons.length == _expectedLessons) {
      structureFailures.add(
        'lesson bodies: ${lessonBodies.length} distinct of ${lessons.length}',
      );
    }
    if (exampleBodies.length != lessons.length &&
        lessons.length == _expectedLessons) {
      structureFailures.add(
        'example bodies: ${exampleBodies.length} distinct of ${lessons.length}',
      );
    }
    if (explains.length != lessons.length &&
        lessons.length == _expectedLessons) {
      structureFailures.add(
        'explain prose: ${explains.length} distinct of ${lessons.length}',
      );
    }
  }

  void markNotRun(Unit unit, String reason) {
    final record = UnitRecord(
      unit: unit,
      sourceHash: sha256Hex(utf8.encode(unit.source)),
      sourceLength: unit.source.length,
    )
      ..notRun = true
      ..failure = reason;
    _notRun++;
    records.add(record);
    _recordedKeys.add(unit.key);
    lastRecord = record;
  }

  void markFilteredOut(Plan plan) {
    final selected = plan.units.map((unit) => unit.key).toSet();
    for (final unit in _allUnits) {
      if (selected.contains(unit.key)) continue;
      if (_recordedKeys.contains(unit.key)) continue;
      final record = UnitRecord(
        unit: unit,
        sourceHash: sha256Hex(utf8.encode(unit.source)),
        sourceLength: unit.source.length,
      )
        ..notRun = true
        ..failure = 'not selected by this run\'s filters';
      _notRun++;
      records.add(record);
      _recordedKeys.add(unit.key);
    }
  }

  List<Unit> get _allUnits => _allUnitsCache ??= _buildPlan(
    inventory,
    const BaseOptions(),
    _authoredDraftLessons(),
  ).units;

  List<Unit>? _allUnitsCache;

  Future<void> runUnit(
    Unit unit, {
    required String sdkExecutable,
    required String? packageConfigPath,
    required Directory scratch,
  }) async {
    final hash = sha256Hex(utf8.encode(unit.source));
    final record = UnitRecord(
      unit: unit,
      sourceHash: hash,
      sourceLength: unit.source.length,
    );
    _recordedKeys.add(unit.key);
    records.add(record);
    lastRecord = record;

    if (unit.hasStructureProblem) {
      record
        ..passed = false
        ..failure = unit.structureProblem;
      _failed++;
      return;
    }
    if (unit.source.trim().isEmpty) {
      record
        ..passed = false
        ..failure = 'unit source is empty';
      _failed++;
      return;
    }

    final file = File(p.join(scratch.path, '${unit.fileName}.dart'));
    try {
      await file.writeAsString(unit.source, flush: true);
    } on FileSystemException catch (error) {
      record
        ..infrastructure = true
        ..failure = 'cannot write the unit source: $error';
      _infrastructureCount++;
      infrastructureNotes.add('${unit.key}: $error');
      return;
    }

    final sdk = await _runSdk(
      executable: sdkExecutable,
      entryFile: file.path,
      packageConfigPath: packageConfigPath,
      timeout: options.sdkTimeout,
    );
    record.sdk = sdk;

    if (sdk.launchError != null ||
        sdk.streamError != null ||
        sdk.timedOut ||
        _isOutOfMemory(sdk)) {
      // Infrastructure, never a pass and never a silent skip. Execution stops:
      // continuing after the SDK could not start, lose its output pipes, hang or
      // exhaust memory would produce results that mean nothing.
      record
        ..infrastructure = true
        ..passed = false
        ..failure = sdk.launchError != null
            ? 'official SDK did not start: ${sdk.launchError}'
            : sdk.streamError != null
            ? 'official SDK output pipes did not close: captured output is '
                  'unknown, not empty'
            : sdk.timedOut
            ? 'official SDK exceeded ${options.sdkTimeout.inSeconds}s'
            : 'official SDK ran out of memory';
      _infrastructureCount++;
      halted = true;
      infrastructureNotes.add('${unit.key}: ${record.failure}');
      return;
    }

    if (sdk.exitCode != 0) {
      record
        ..passed = false
        ..failure =
            'official SDK exited ${sdk.exitCode}\n${_capture(sdk.stderr)}';
      _failed++;
      return;
    }
    if (sdk.stderr.trim().isNotEmpty) {
      record
        ..passed = false
        ..failure = 'official SDK wrote to stderr\n${_capture(sdk.stderr)}';
      _failed++;
      return;
    }

    final portable = await _runPortable(unit.source, options.portableTimeout);
    record.portable = portable;

    if (portable.timedOut || portable.error != null) {
      record
        ..passed = false
        ..failure = portable.timedOut
            ? 'portable engine exceeded ${options.portableTimeout.inSeconds}s'
            : 'portable engine error: ${_capture(portable.error!)}';
      _failed++;
      return;
    }

    // Lessons and examples have an authored expectation; exercises are
    // referenced against the real SDK output for the same program.
    final expected = unit.expectedOutput ?? sdk.stdout;
    final sdkAgrees = stdoutMatches(expected, sdk.stdout);
    final portableAgrees = stdoutMatches(expected, portable.output);
    if (sdkAgrees && portableAgrees) {
      record.passed = true;
      _passed++;
      return;
    }
    final expectedLabel =
        unit.expectedOutput == null ? 'reference' : 'authored output';
    record
      ..passed = false
      ..failure = <String>[
        if (!sdkAgrees) 'official SDK stdout != $expectedLabel',
        if (!portableAgrees) 'portable stdout != expected',
        'expected: ${_capture(expected)}',
        'sdk: ${_capture(sdk.stdout)}',
        'portable: ${_capture(portable.output)}',
      ].join('\n');
    _failed++;
  }

  void noteInfrastructure(String note) {
    infrastructureNotes.add(note);
    halted = true;
  }

  void noteCleanup(String failure) {
    cleanupFailures.add(failure);
  }

  bool get covered {
    if (options.inventoryOnly) return false;
    if (options.limit != null) return false;
    if (options.chapters.isNotEmpty) return false;
    if (options.start != null || options.end != null) return false;
    if (options.kinds != null) return false;
    return true;
  }

  Json toJson() {
    final structureOk = structureFailures.isEmpty;
    final inventoryComplete =
        records.length == inventory.totalUnits && _notRun == 0;
    final fullCoverage = covered;
    final gateOk =
        fullCoverage &&
        options.limit == null &&
        !options.inventoryOnly &&
        structureOk &&
        _failed == 0 &&
        _infrastructureCount == 0 &&
        inventoryComplete;

    return <String, Object?>{
      'verifier': 'tool/verify_draft_content.dart',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'repository': rootPath,
      'engines': <String, Object?>{
        'officialSdkExecutable': sdkExecutable,
        'portable': 'tool/portable_content_runner.dart -> PortableDartRuntime '
            '(tom_d4rt, production path)',
      },
      'normalisation': <String, Object?>{
        'lineEndings': r'\r\n -> \n',
        'trailingNewline': 'exactly one newline tolerated on either side',
        'spaces': 'significant, never trimmed',
        'hash': 'sha256 over the exact unit source (UTF-8)',
      },
      'inventory': <String, Object?>{
        'lessonIdRange': '${inventory.lessonIds.first}..'
            '${inventory.lessonIds.last}',
        'expectedLessons': _expectedLessons,
        'expectedExamples': _expectedExamples,
        'expectedExercises': _expectedExercises,
        'exercisesPerLesson': inventory.exercisesPerLesson,
        'expectedUnits': inventory.totalUnits,
        'chapters': _expectedChapters.map(
          (key, range) => MapEntry(key, '${_lessonIdFor(range[0])}..'
              '${_lessonIdFor(range[1])}'),
        ),
      },
      'selection': <String, Object?>{
        'chapters': options.chapters.toList()..sort(),
        'kinds': options.kinds == null
            ? null
            : (options.kinds!.toList()..sort()),
        'start': options.start,
        'end': options.end,
        'limit': options.limit,
        'inventoryOnly': options.inventoryOnly,
        'historyTrusted': false,
        'historyNote':
            'no prior report is reused; every selected unit runs in this run',
        'selectedUnits': plan.units.length,
        'skippedByFilter': plan.skippedByFilter,
        'skippedByLimit': plan.skippedByLimit,
        'denominator': inventory.totalUnits,
        'lowersDenominator': false,
      },
      'counters': <String, Object?>{
        'passed': _passed,
        'failed': _failed,
        'infrastructureFailures': _infrastructureCount,
        'notRun': _notRun,
        'records': records.length,
      },
      'structure': <String, Object?>{
        'ok': structureOk,
        'failures': structureFailures,
      },
      'infrastructure': <String, Object?>{
        'notes': infrastructureNotes,
        'halted': halted,
        'sdkOutOfMemoryIsInfrastructure': true,
        'streamDrainTimeoutIsInfrastructure': true,
      },
      'cleanup': <String, Object?>{
        'ok': cleanupFailures.isEmpty,
        'failures': cleanupFailures,
      },
      'gate': <String, Object?>{
        'ok': gateOk,
        'fullCoverage': fullCoverage,
        'inventoryComplete': inventoryComplete,
        'reason': gateOk
            ? 'full inventory executed and passed on both engines'
            : _reason ??
                  (options.inventoryOnly
                      ? 'inventory-only: no execution, cannot pass'
                      : fullCoverage
                      ? 'see counters/structure/infrastructure'
                      : 'partial selection: filters or --limit applied'),
        'note':
            'this gate complements, and does not replace, the original '
            'installed OHOS 240-lesson gate; drafts are not promoted here',
      },
      'units': <Object?>[
        for (final record in records)
          record.toJson(includeCaptured: !record.passed),
      ],
    };
  }

  void finish({String? reason}) {
    _reason = reason;
    flush();
  }

  void flush() {
    try {
      reportPath.parent.createSync(recursive: true);
      reportPath.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(toJson())}\n',
        flush: true,
      );
    } on FileSystemException catch (error) {
      stderr.writeln('cannot write report ${reportPath.path}: $error');
    }
  }

  int get exitCode {
    if (_infrastructureCount > 0 || halted) return 2;
    if (_failed > 0) return 1;
    final gate = toJson()['gate'] as Json;
    if (gate['ok'] == true) return 0;
    return 4;
  }
}

extension _UnitStructure on Unit {
  bool get hasStructureProblem =>
      structureProblem != null && structureProblem!.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Engine adapters
// ---------------------------------------------------------------------------

/// Real official SDK, bounded.
///
/// `finally` signals the ROOT process only. This function does not reap
/// grandchildren and must not claim to: whole-tree containment and kill are the
/// responsibility of the outer Windows Job gate. Here we guarantee the root is
/// killed and its pipes are closed.
Future<SdkRun> _runSdk({
  required String executable,
  required String entryFile,
  required String? packageConfigPath,
  required Duration timeout,
}) async {
  final stopwatch = Stopwatch()..start();
  Process? process;
  try {
    try {
      process = await Process.start(
        executable,
        NativeDartToolchain.buildRunArguments(
          entry: entryFile,
          packageConfig: packageConfigPath,
        ),
        workingDirectory: p.dirname(entryFile),
      );
    } on Object catch (error) {
      return SdkRun(
        exitCode: null,
        stdout: '',
        stderr: '',
        timedOut: false,
        launchError: '$error',
        streamError: null,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
    // Decode as UTF-8 explicitly: the Windows console codepage would otherwise
    // mangle the Chinese in these programs.
    final stdoutFuture = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
    final stderrFuture = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
    unawaited(process.stdin.close().catchError((Object _) {}));
    var timedOut = false;
    int? exit;
    try {
      exit = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
      try {
        exit = await process.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        exit = null;
      }
    }
    // Bound the drains, but never treat a stuck drain as success. An empty
    // substitution would let an empty-output program look like it passed, so a
    // drain timeout becomes an infrastructure error and the captured values are
    // marked unknown.
    var stdout = '';
    var stderr = '';
    String? streamError;
    try {
      final captured = await Future.wait<String>(<Future<String>>[
        stdoutFuture,
        stderrFuture,
      ]).timeout(const Duration(seconds: 5));
      stdout = captured[0];
      stderr = captured[1];
    } on TimeoutException {
      streamError =
          'SDK output pipes did not close after SIGKILL; captured '
          'stdout/stderr are unknown, not empty';
    } on Object catch (error) {
      streamError = 'SDK output capture failed: $error';
    }
    return SdkRun(
      exitCode: exit,
      stdout: stdout,
      stderr: stderr,
      timedOut: timedOut,
      launchError: null,
      streamError: streamError,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  } finally {
    final alive = process;
    if (alive != null) {
      try {
        alive.kill(ProcessSignal.sigkill);
        await alive.stdin.close();
      } on Object {
        // Already exited, or the pipe closed with the child. Root only: this
        // does not reach any grandchild.
      }
    }
  }
}

/// The production portable helper. Its own timeout cancels the supervised
/// isolate tree; the outer guard guarantees this awaits even if that path hangs.
Future<PortableRun> _runPortable(String source, Duration timeout) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await runPortableContent(
      source,
      timeout: timeout,
    ).timeout(timeout + const Duration(seconds: 15));
    final error = result.error;
    return PortableRun(
      output: result.output,
      error: error,
      timedOut: error != null && error.contains('timed out'),
      durationMs: stopwatch.elapsedMilliseconds,
    );
  } on TimeoutException {
    return PortableRun(
      output: '',
      error: 'portable helper did not return within '
          '${timeout + const Duration(seconds: 15)}',
      timedOut: true,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  } on Object catch (error) {
    return PortableRun(
      output: '',
      error: '$error',
      timedOut: false,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

bool _isOutOfMemory(SdkRun run) {
  final text = '${run.stderr}\n${run.stdout}'.toLowerCase();
  return text.contains('out of memory') ||
      text.contains('cannot allocate memory') ||
      text.contains('std::bad_alloc');
}

/// Deletes the scratch directory. Returns a message when deletion did not
/// complete, so the run reports the retained path instead of assuming the OS
/// reclaims it.
Future<String?> _deleteScratch(Directory directory) async {
  try {
    if (await directory.exists()) await directory.delete(recursive: true);
    return null;
  } on FileSystemException catch (error) {
    return 'scratch directory was not deleted and is retained at '
        '${directory.path}: $error';
  }
}

/// Repository root: the nearest ancestor of the current directory (or of this
/// script) that holds `pubspec.yaml` and `curriculum/`.
Directory _repositoryRoot() {
  bool looksLikeRoot(Directory directory) =>
      File(p.join(directory.path, 'pubspec.yaml')).existsSync() &&
      Directory(p.join(directory.path, 'curriculum')).existsSync();

  Directory? walk(Directory start) {
    var current = start;
    for (var depth = 0; depth < 12; depth++) {
      if (looksLikeRoot(current)) return current;
      final parent = current.parent;
      if (parent.path == current.path) return null;
      current = parent;
    }
    return null;
  }

  final fromCurrent = walk(Directory.current.absolute);
  if (fromCurrent != null) return fromCurrent;
  try {
    final scriptPath = Platform.script.toFilePath();
    if (scriptPath.isNotEmpty) {
      final fromScript = walk(Directory(p.dirname(scriptPath)));
      if (fromScript != null) return fromScript;
    }
  } on Object {
    // A kernel-snapshot script URI need not be a file path; fall back below.
  }
  return Directory.current.absolute;
}

// ---------------------------------------------------------------------------
// SHA-256 (dependency-free). `crypto` is only a transitive package here, and
// this tool must not add a direct dependency, so the digest is implemented
// locally and self-checked against RFC 6234 vectors before it is trusted.
// ---------------------------------------------------------------------------

const List<int> _sha256K = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const int _mask32 = 0xFFFFFFFF;

int _rotr(int value, int bits) =>
    ((value >> bits) | (value << (32 - bits))) & _mask32;

String sha256Hex(List<int> message) {
  final h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final bytes = List<int>.of(message, growable: true);
  final bitLength = bytes.length * 8;
  bytes.add(0x80);
  while (bytes.length % 64 != 56) {
    bytes.add(0);
  }
  for (var shift = 56; shift >= 0; shift -= 8) {
    bytes.add((bitLength >> shift) & 0xFF);
  }
  final w = List<int>.filled(64, 0);
  for (var offset = 0; offset < bytes.length; offset += 64) {
    for (var i = 0; i < 16; i++) {
      final base = offset + i * 4;
      w[i] =
          (bytes[base] << 24) |
          (bytes[base + 1] << 16) |
          (bytes[base + 2] << 8) |
          bytes[base + 3];
    }
    for (var i = 16; i < 64; i++) {
      final x = w[i - 15];
      final y = w[i - 2];
      final s0 = _rotr(x, 7) ^ _rotr(x, 18) ^ (x >> 3);
      final s1 = _rotr(y, 17) ^ _rotr(y, 19) ^ (y >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask32;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & _mask32) & g);
      final temp1 = (hh + s1 + ch + _sha256K[i] + w[i]) & _mask32;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & _mask32;
      hh = g;
      g = f;
      f = e;
      e = (d + temp1) & _mask32;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & _mask32;
    }
    h[0] = (h[0] + a) & _mask32;
    h[1] = (h[1] + b) & _mask32;
    h[2] = (h[2] + c) & _mask32;
    h[3] = (h[3] + d) & _mask32;
    h[4] = (h[4] + e) & _mask32;
    h[5] = (h[5] + f) & _mask32;
    h[6] = (h[6] + g) & _mask32;
    h[7] = (h[7] + hh) & _mask32;
  }
  final digest = StringBuffer();
  for (final word in h) {
    digest.write(word.toRadixString(16).padLeft(8, '0'));
  }
  return digest.toString();
}

/// Guards the local digest against a silent implementation error: a wrong hash
/// would make every recorded source, stdout and output hash untrustworthy.
void _selfCheckSha256() {
  const empty =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
  const abc =
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  const long =
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06'
      'c2';
  final longMessage = 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmno'
      'mnopnopq';
  if (sha256Hex(const <int>[]) != empty ||
      sha256Hex(utf8.encode('abc')) != abc ||
      sha256Hex(utf8.encode(longMessage)) != long) {
    throw StateError(
      'internal sha256 self-check failed; refusing to hash sources with an '
      'unverified digest',
    );
  }
}
