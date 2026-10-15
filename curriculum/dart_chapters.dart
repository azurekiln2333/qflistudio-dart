import 'dart_lesson.dart';

/// The 14 chapters and their fixed lesson counts.
///
/// Total = 120. Ownership split (do not edit across the boundary):
///   * Lessons 001-060 — chapters `basics` .. `exceptions` (this pi).
///   * Lessons 061-120 — chapters `dart3` .. `engineering` (second pi).
///
/// Each chapter's lesson file is named `chapters/<key>.dart` and exports a
/// `const List<DartLesson> <listName>`. Only the owning pi edits that file.
abstract final class DartCurriculum {
  static const chapters = <DartChapter>[
    DartChapter(key: 'basics', title: '第一章 入门与基础'),
    DartChapter(key: 'control', title: '第二章 流程控制与函数'),
    DartChapter(key: 'collections', title: '第三章 集合与迭代'),
    DartChapter(key: 'nullsafety', title: '第四章 空安全'),
    DartChapter(key: 'oop', title: '第五章 面向对象'),
    DartChapter(key: 'generics', title: '第六章 泛型与类型系统'),
    DartChapter(key: 'exceptions', title: '第七章 异常与错误处理'),
    DartChapter(key: 'dart3', title: '第八章 Dart 3 模式与记录'),
    DartChapter(key: 'async', title: '第九章 异步编程'),
    DartChapter(key: 'streams', title: '第十章 流'),
    DartChapter(key: 'isolates', title: '第十一章 隔离与并发'),
    DartChapter(key: 'io', title: '第十二章 IO 与文件'),
    DartChapter(key: 'json', title: '第十三章 JSON 与序列化'),
    DartChapter(key: 'engineering', title: '第十四章 测试与工程'),
  ];

  /// Fixed per-chapter lesson counts. Keys match [DartChapter.key].
  static const counts = <String, int>{
    'basics': 10,
    'control': 8,
    'collections': 10,
    'nullsafety': 6,
    'oop': 12,
    'generics': 8,
    'exceptions': 6,
    'dart3': 12,
    'async': 10,
    'streams': 8,
    'isolates': 6,
    'io': 8,
    'json': 6,
    'engineering': 10,
  };

  /// Lessons empirically verified to run on dart_eval 0.8.5 and match output.
  ///
  /// This is the single source of truth for engine compatibility. It was
  /// produced by actually running every lesson through the dart_eval
  /// compile+execute path; the remaining lessons require the official SDK. The
  /// generator projects this into each lesson's `explain` so the requirement is
  /// visible in the UI, and the tests assert against it.
  ///
  /// Do not extend from static inspection — only from a passing dart_eval run.
  static const dartEvalVerifiedIds = <String>{
    'dart-lesson-001',
    'dart-lesson-003',
    'dart-lesson-004',
    'dart-lesson-006',
    'dart-lesson-007',
    'dart-lesson-008',
    'dart-lesson-009',
    'dart-lesson-010',
    'dart-lesson-011',
    'dart-lesson-012',
    'dart-lesson-014',
    'dart-lesson-017',
    'dart-lesson-018',
    'dart-lesson-019',
    'dart-lesson-020',
    'dart-lesson-021',
    'dart-lesson-022',
    'dart-lesson-024',
    'dart-lesson-025',
    'dart-lesson-028',
    'dart-lesson-029',
    'dart-lesson-030',
    'dart-lesson-032',
    'dart-lesson-035',
    'dart-lesson-037',
    'dart-lesson-039',
    'dart-lesson-041',
    'dart-lesson-056',
    'dart-lesson-057',
    'dart-lesson-061',
    'dart-lesson-074',
    'dart-lesson-105',
    'dart-lesson-106',
    'dart-lesson-107',
    'dart-lesson-108',
    'dart-lesson-109',
    'dart-lesson-113',
    'dart-lesson-114',
    'dart-lesson-115',
    'dart-lesson-117',
    'dart-lesson-118',
    'dart-lesson-119',
    'dart-lesson-120',
  };

  /// Short engine tag for example summaries (compact catalog subtitle).
  static String engineTag(String lessonId) =>
      dartEvalVerifiedIds.contains(lessonId)
      ? '[引擎：官方 SDK / dart_eval 均可]'
      : '[引擎：需官方 Dart SDK]';

  /// Human-readable runtime requirement for [lessonId].
  static String engineNote(String lessonId) =>
      dartEvalVerifiedIds.contains(lessonId)
      ? '运行要求：本课已在官方 Dart SDK 与 dart_eval 便携引擎上实测通过，'
            '两者都能直接运行本课代码。'
      : '运行要求：本课需要官方 Dart SDK 引擎（Android/桌面/原生构建）。'
            'dart_eval 便携子集不支持本课用到的语法，请勿以 dart_eval 结果判定本课。';

  /// First lesson id (inclusive) of each chapter, derived from [counts] order.
  static Map<String, int> get firstIndex {
    final result = <String, int>{};
    var next = 1;
    for (final chapter in chapters) {
      result[chapter.key] = next;
      next += counts[chapter.key]!;
    }
    return result;
  }
}
