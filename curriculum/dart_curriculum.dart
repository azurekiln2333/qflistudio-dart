import 'dart_lesson.dart';
import 'chapters/async.dart';
import 'chapters/basics.dart';
import 'chapters/collections.dart';
import 'chapters/control.dart';
import 'chapters/dart3.dart';
import 'chapters/engineering.dart';
import 'chapters/exceptions.dart';
import 'chapters/generics.dart';
import 'chapters/io.dart';
import 'chapters/isolates.dart';
import 'chapters/json.dart';
import 'chapters/nullsafety.dart';
import 'chapters/oop.dart';
import 'chapters/streams.dart';

/// Aggregate of all authored lessons, in id order.
///
/// 120 lessons total. Each chapter file owns its own list; this file only
/// concatenates them. Do not edit across an ownership boundary.
const List<DartLesson> dartCurriculum = <DartLesson>[
  ...basicsLessons,
  ...controlLessons,
  ...collectionsLessons,
  ...nullSafetyLessons,
  ...oopLessons,
  ...genericsLessons,
  ...exceptionsLessons,
  ...dart3Lessons,
  ...asyncLessons,
  ...streamsLessons,
  ...isolateLessons,
  ...ioLessons,
  ...jsonLessons,
  ...engineeringLessons,
];
