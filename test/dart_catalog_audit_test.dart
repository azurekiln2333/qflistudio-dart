@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_catalog_audit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dart_catalog_audit_');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Map<String, Object?> tutorials(String code, String expected) => {
    'schemaVersion': 1,
    'kind': 'tutorials',
    'entries': [
      {
        'id': 'dart-lesson-001',
        'language': 'dart',
        'type': 'dart',
        'lessons': [
          {'id': 'dart-lesson-001-lesson', 'code': code, 'output': expected},
        ],
      },
    ],
  };
  Map<String, Object?> examples(String code, String expected) => {
    'schemaVersion': 1,
    'kind': 'examples',
    'entries': [
      {
        'id': 'dart-example-001',
        'language': 'dart',
        'type': 'dart',
        'sourceLessonId': 'dart-lesson-001',
        'code': code,
        'expectedOutput': expected,
      },
    ],
  };

  test(
    'inventory rejects truncation, duplicates, foreign and extra programs',
    () {
      final tutorial = tutorials('void main() {}', '');
      final example = examples('void main() {}', '');
      expect(
        () => inventoryDartCatalog(
          tutorials: jsonEncode(tutorial),
          examples: jsonEncode(example),
          expectedTopics: 120,
        ),
        throwsFormatException,
      );
      for (final invalid in [
        {...tutorial, 'entries': []},
        {...tutorial, 'schemaVersion': 2},
        {...tutorial, 'kind': 'examples'},
        {
          ...tutorial,
          'entries': [null],
        },
        {
          ...tutorial,
          'entries': [
            {'id': 'dart-lesson-001', 'language': 'python'},
          ],
        },
        {
          ...tutorial,
          'entries': [
            ...(tutorial['entries'] as List),
            ...(tutorial['entries'] as List),
          ],
        },
        {
          ...tutorial,
          'entries': [
            {
              'id': 'dart-lesson-001',
              'type': 'dart',
              'language': 'dart',
              'lessons': [
                {
                  'id': 'dart-lesson-001-lesson',
                  'code': 'void main() {}',
                  'output': '',
                },
                {'id': 'extra', 'code': 'void main() {}', 'output': ''},
              ],
            },
          ],
        },
      ]) {
        expect(
          () => inventoryDartCatalog(
            tutorials: jsonEncode(invalid),
            examples: jsonEncode(example),
            expectedTopics: 1,
          ),
          throwsFormatException,
        );
      }
      final invalidExample = examples('void main() {}', '');
      ((invalidExample['entries'] as List).single as Map)['sourceLessonId'] =
          'dart-lesson-002';
      expect(
        () => inventoryDartCatalog(
          tutorials: jsonEncode(tutorial),
          examples: jsonEncode(invalidExample),
          expectedTopics: 1,
        ),
        throwsFormatException,
      );
    },
  );

  Future<Map<String, Object?>> audit(
    String code,
    String expected, {
    String? exampleCode,
    Duration timeout = const Duration(seconds: 10),
  }) => auditBundledDartCatalog(
    workspace: Directory(p.join(directory.path, 'projects')),
    reportFile: File(p.join(directory.path, 'report.json')),
    expectedTopics: 1,
    timeout: timeout,
    bundle: _Assets({
      'assets/content/dart_tutorials.json': jsonEncode(
        tutorials(code, expected),
      ),
      'assets/content/dart_examples.json': jsonEncode(
        examples(exampleCode ?? code, expected),
      ),
    }),
  );

  test(
    'both actual source payloads run and persist independent observations',
    () async {
      final report = await audit(
        'void main() { print(6 * 7); }',
        '42\n',
        exampleCode: 'void main() { print([20, 22].reduce((a, b) => a + b)); }',
      );
      expect(report['ok'], true);
      expect(report['checked'], 2);
      expect(report['passed'], 2);
      expect(
        report['deviceGatePassed'],
        false,
        reason: 'host execution is never OHOS proof',
      );
      final rows = report['results'] as List;
      expect(rows.map((row) => row['sourceSha256']).toSet(), hasLength(2));
      expect(rows.map((row) => row['actual']), ['42', '42']);
      final persisted = jsonDecode(
        await File(p.join(directory.path, 'report.json')).readAsString(),
      );
      expect(persisted['executionComplete'], true);
      expect((persisted['assets'] as Map).length, 2);
      expect(
        await Directory(p.join(directory.path, 'projects')).list().toList(),
        isEmpty,
      );
    },
  );

  test(
    'example failure cannot hide behind an identical lesson identity',
    () async {
      final report = await audit(
        'void main() { print(42); }',
        '42\n',
        exampleCode: 'void main() { print(43); }',
      );
      expect(report['ok'], false);
      expect(report['executionComplete'], true);
      expect(report['passed'], 1);
      expect(report['failed'], 1);
    },
  );

  test('syntax failure and extra stdout spaces remain failures', () async {
    final report = await audit(
      'void main( {',
      '42\n',
      exampleCode: "void main() { print('42 '); }",
    );
    expect(report['ok'], false);
    expect(report['failed'], 2);
    expect((report['results'] as List).first['exitCode'], 127);
  });

  test(
    'infinite code is cancelled and the remaining inventory still runs',
    () async {
      final report = await audit(
        'void main() { while (true) {} }',
        '42\n',
        exampleCode: 'void main() { print(42); }',
        timeout: const Duration(seconds: 2),
      );
      expect(report['ok'], false);
      expect(report['checked'], 2);
      expect(report['passed'], 1);
      expect((report['results'] as List).first['timedOut'], true);
      expect(
        await Directory(p.join(directory.path, 'projects')).list().toList(),
        isEmpty,
      );
    },
  );

  test(
    'the real packaged original catalog passes the installed audit path',
    () async {
      final report = await auditBundledDartCatalog(
        workspace: Directory(p.join(directory.path, 'projects')),
        reportFile: File(p.join(directory.path, 'report.json')),
        expectedTopics: 120,
      );
      expect(report['ok'], true, reason: jsonEncode(report));
      expect(report['checked'], 240);
      expect(report['passed'], 240);
      expect(report['deviceGatePassed'], false);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

class _Assets extends CachingAssetBundle {
  _Assets(this.sources);
  final Map<String, String> sources;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(sources[key]!)));
}
