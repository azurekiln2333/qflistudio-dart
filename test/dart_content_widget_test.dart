@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qfli_dart/dart_content_repository.dart';
import 'package:qfli_dart/main.dart' show dartProfile;
import 'package:qfli_studio_core/content/content_repository.dart';
import 'package:qfli_studio_core/pages/local_content_pages.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';

/// Widget evidence that the **real pages** render the Dart-owned 120-lesson
/// curriculum through the injected repository — i.e. the path HomePage builds
/// for an offline Dart app, not just the service layer.
///
/// This mounts [LocalTutorialsTab] and [ExampleCodeTab] exactly as
/// `HomePage._buildPage` does (offline + `profile.id`), with the repository the
/// Dart profile injects (`DartContentRepository`, backed by the **real bundled
/// assets**), then asserts the catalog lists and the lesson detail render the
/// authored teaching content.
///
/// Two environment facts drive the shape of these tests:
///   1. Asset-bundle loading needs real async, and a loading
///      [CircularProgressIndicator] never settles. `_preloaded` drains the real
///      load through `tester.runAsync`, then replays it from a synchronously
///      completing wrapper so the tree renders deterministically under the test
///      clock (still the real [DartContentRepository] output — no synthetic
///      content).
///   2. The detail body is a lazy `ListView`, so `pitfalls` must be scrolled
///      into view before asserting it.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(ListView).evaluate().isNotEmpty) return;
  }
}

/// Loads the real bundled assets once via [DartContentRepository], then wraps
/// the resolved catalog in a repository whose futures complete synchronously.
/// The catalog itself is the genuine 120-lesson Dart content.
Future<ContentRepository> _preloaded(WidgetTester tester) async {
  final catalog = await tester.runAsync(
    () => DartContentRepository().load(),
  );
  return _ImmediateRepository(catalog!);
}

class _ImmediateRepository implements ContentRepository {
  _ImmediateRepository(this.catalog);
  final ContentCatalog catalog;

  @override
  Future<ContentCatalog> load() => Future.value(catalog);

  @override
  Future<List<TutorialContent>> tutorials({
    ContentFilter filter = const ContentFilter(),
  }) async => [
    for (final t in catalog.tutorials)
      if (filter.matches(t)) t,
  ];

  @override
  Future<List<ExampleContent>> examples({
    ContentFilter filter = const ContentFilter(),
  }) async => [
    for (final e in catalog.examples)
      if (filter.matches(e)) e,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudioProfile? previous;
  setUp(() {
    previous = StudioProfile.current;
    StudioProfile.current = dartProfile;
  });
  tearDown(() => StudioProfile.current = previous);

  testWidgets('Dart profile injects the Dart content repository', (
    tester,
  ) async {
    expect(dartProfile.contentRepositoryFactory, isNotNull);
    final repository = dartProfile.contentRepositoryFactory!.call();
    expect(repository, isA<DartContentRepository>());
  });

  testWidgets('tutorial tab renders the 120 authored lessons and a detail', (
    tester,
  ) async {
    final repo = await _preloaded(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: LocalTutorialsTab(language: dartProfile.id, repository: repo),
      ),
    );
    await _settle(tester);

    // The catalog is a ListView that holds a chapter header + a lesson tile per
    // lesson, so at least 120 lesson tiles are laid out.
    final listFinder = find.byType(ListView);
    expect(listFinder, findsWidgets);
    expect(
      tester.widgetList<ListView>(listFinder).first.childrenDelegate
          .estimatedChildCount,
      greaterThanOrEqualTo(120),
      reason: 'catalog should list all 120 authored lessons',
    );
    // First authored lesson title appears in the catalog.
    expect(find.text('第一个 Dart 程序'), findsWidgets);

    // Open the first lesson detail. Tap the tile itself: the title text is
    // rendered in more than one place, so tapping the `Text` can miss the
    // hit-testable tile.
    final firstTile = find.byType(ListTile).first;
    await tester.ensureVisible(firstTile);
    await tester.tap(firstTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The real teaching fields render: objective label + prose, explain prose.
    expect(find.text('学习目标'), findsOneWidget);
    expect(find.textContaining('main 函数'), findsWidgets);

    // `pitfalls` sits far down the lazy detail list; scroll it into view.
    for (var i = 0; i < 30; i++) {
      if (find.text('易错点').evaluate().isNotEmpty) break;
      await tester.drag(
        find.byType(ListView).first,
        const Offset(0, -200),
        warnIfMissed: false,
      );
      await tester.pump();
    }
    expect(find.text('易错点'), findsOneWidget);
  });

  testWidgets('example tab renders the 120 authored examples', (tester) async {
    final repo = await _preloaded(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ExampleCodeTab(language: dartProfile.id, repository: repo),
      ),
    );
    await _settle(tester);
    final listWidget = tester.widgetList<ListView>(find.byType(ListView)).first;
    expect(
      listWidget.childrenDelegate.estimatedChildCount,
      greaterThanOrEqualTo(120),
    );
    expect(find.textContaining('示例 001'), findsWidgets);
  });
}
