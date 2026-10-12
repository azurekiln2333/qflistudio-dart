import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qfli_studio_core/content/content_repository.dart';

/// Dart-app-owned offline content source.
///
/// Loads the two Dart-only aggregate assets bundled by this package and parses
/// them with the shared [ContentCatalog.fromJson], so the existing catalog,
/// detail, import and run pipeline is reused unchanged.
///
/// The shared core normally reads `packages/qfli_studio_core/assets/content/…`.
/// This repository instead reads this package's own
/// `packages/qfli_dart/assets/content/…`, which keeps the 120 Dart lessons
/// isolated from other languages' shared content.
class DartContentRepository implements ContentRepository {
  DartContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String tutorialAsset =
      'packages/qfli_dart/assets/content/dart_tutorials.json';
  static const String exampleAsset =
      'packages/qfli_dart/assets/content/dart_examples.json';

  /// Asset keys also tried without the package prefix (package self-tests).
  static const List<String> _tutorialKeys = <String>[
    tutorialAsset,
    'assets/content/dart_tutorials.json',
  ];
  static const List<String> _exampleKeys = <String>[
    exampleAsset,
    'assets/content/dart_examples.json',
  ];

  final AssetBundle _bundle;
  Future<ContentCatalog>? _catalogFuture;

  @override
  Future<ContentCatalog> load() => _catalogFuture ??= _loadCatalog();

  @override
  Future<List<TutorialContent>> tutorials({
    ContentFilter filter = const ContentFilter(),
  }) async {
    final catalog = await load();
    return <TutorialContent>[
      for (final tutorial in catalog.tutorials)
        if (filter.matches(tutorial)) tutorial,
    ];
  }

  @override
  Future<List<ExampleContent>> examples({
    ContentFilter filter = const ContentFilter(),
  }) async {
    final catalog = await load();
    return <ExampleContent>[
      for (final example in catalog.examples)
        if (filter.matches(example)) example,
    ];
  }

  Future<ContentCatalog> _loadCatalog() async {
    final tutorials = await _loadString(_tutorialKeys);
    final examples = await _loadString(_exampleKeys);
    return ContentCatalog.fromJson(
      tutorialsSource: tutorials,
      examplesSource: examples,
    );
  }

  Future<String> _loadString(List<String> keys) async {
    final failures = <String>[];
    for (final key in keys) {
      try {
        return await _bundle.loadString(key);
      } on FlutterError catch (error) {
        failures.add('$key: ${error.message}');
      } on Exception catch (error) {
        failures.add('$key: $error');
      }
    }
    throw ContentAssetException(keys.first, failures);
  }
}

/// Raised when neither Dart content asset can be loaded from the bundle.
class ContentAssetException implements Exception {
  const ContentAssetException(this.asset, this.failures);

  final String asset;
  final List<String> failures;

  @override
  String toString() =>
      'Unable to load content asset $asset: ${failures.join(' | ')}';
}
