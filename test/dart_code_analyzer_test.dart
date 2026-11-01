import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_code_analyzer.dart';
import 'package:qfli_dart/dart_tools.dart';
import 'package:qfli_studio_core/services/code_analysis.dart';

void main() {
  late Directory root;
  late String path;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('qfli_dart_analysis_');
    path = p.join(root.path, 'main.dart');
    await File(path).writeAsString('void main() {}');
  });
  tearDown(() => root.delete(recursive: true));

  CodeAnalysisRequest request(
    List<CodeDocumentSnapshot> documents, {
    String language = 'dart',
    int revision = 7,
    String? activeFilePath,
    String? projectPath,
  }) => CodeAnalysisRequest(
    projectPath: projectPath ?? root.path,
    activeFilePath: activeFilePath ?? path,
    language: language,
    revision: revision,
    documents: documents,
  );

  CodeDocumentSnapshot snapshot(
    String at,
    String text, {
    int revision = 7,
  }) => CodeDocumentSnapshot(path: at, text: text, revision: revision);

  test(
    'analyzes exact unsaved CRLF and UTF-16 source without changing disk',
    () async {
      const text = '// 😀\r\nvoid main() {\r\n  print(\r\n}\r\n';
      final result = await const DartCodeAnalyzer().analyze(
        request([snapshot(path, text)]),
      );
      expect(result.unavailableReason, isNull);
      final expected = DartTools.syntaxDiagnostics(text);
      expect(result.diagnostics, hasLength(expected.length));
      expect(result.diagnostics, isNotEmpty);
      // Parser-independent: the emoji is one surrogate pair and each line ends
      // with CRLF, so the unmatched brace sits at UTF-16 unit 32.
      expect(text.indexOf('\r\n'), 5);
      expect(text.indexOf('}'), 32);
      expect(
        result.diagnostics.any((item) => item.startOffset >= 32),
        isTrue,
        reason: 'Offsets must count the emoji pair and CRLF units',
      );
      for (var i = 0; i < expected.length; i++) {
        final diagnostic = result.diagnostics[i];
        expect(diagnostic.filePath, path);
        expect(diagnostic.startOffset, expected[i].offset);
        expect(diagnostic.endOffset, expected[i].offset + expected[i].length);
        expect(diagnostic.source, DartCodeAnalyzer.sourceLabel);
        expect(diagnostic.code, isNotEmpty);
      }
      expect(await File(path).readAsString(), 'void main() {}');
      expect(root.listSync(), hasLength(1));
    },
  );

  test(
    'checks other open Dart buffers and excludes foreign/outside files',
    () async {
      final helper = p.join(root.path, 'helper.dart');
      final result = await const DartCodeAnalyzer().analyze(
        request([
          snapshot(path, 'void main() {}'),
          snapshot(helper, 'void broken( {', revision: 3),
          snapshot(p.join(root.path, 'note.txt'), 'void ('),
          snapshot(p.join(root.parent.path, 'outside.dart'), 'void ('),
        ]),
      );
      expect(result.unavailableReason, isNull);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.every((item) => item.filePath == helper),
        isTrue,
      );
      expect(await File(helper).exists(), isFalse);
    },
  );

  test(
    'valid parser result is distinct from missing snapshot availability',
    () async {
      final good = await const DartCodeAnalyzer().analyze(
        request([snapshot(path, 'void main() { unresolved(); }')]),
      );
      expect(good.unavailableReason, isNull);
      expect(
        good.diagnostics,
        isEmpty,
        reason: 'Parser does not claim type analysis',
      );
      final missing = await const DartCodeAnalyzer().analyze(request([]));
      expect(missing.unavailableReason, isNotNull);
    },
  );

  test(
    'rejects a non-Dart language request instead of reporting clean',
    () async {
      final result = await const DartCodeAnalyzer().analyze(
        request(
          [snapshot(path, 'void main( {')],
          language: 'cpp',
        ),
      );
      expect(result.unavailableReason, isNotNull);
      expect(result.diagnostics, isEmpty);
    },
  );

  test('rejects a relative project or active path', () async {
    final relativeProject = await const DartCodeAnalyzer().analyze(
      request([snapshot(path, 'void main() {}')], projectPath: 'proj'),
    );
    expect(relativeProject.unavailableReason, isNotNull);
    final relativeActive = await const DartCodeAnalyzer().analyze(
      request([snapshot(path, 'void main() {}')], activeFilePath: 'main.dart'),
    );
    expect(relativeActive.unavailableReason, isNotNull);
  });

  test('rejects a non-Dart active file', () async {
    final note = p.join(root.path, 'notes.txt');
    final result = await const DartCodeAnalyzer().analyze(
      request([snapshot(note, 'void main( {')], activeFilePath: note),
    );
    expect(result.unavailableReason, isNotNull);
    expect(result.diagnostics, isEmpty);
  });

  test('rejects a duplicate active snapshot alias', () async {
    final alias = p.join(root.path, '.', 'main.dart');
    final result = await const DartCodeAnalyzer().analyze(
      request([
        snapshot(path, 'void main( {'),
        snapshot(alias, 'void main() {}'),
      ]),
    );
    expect(result.unavailableReason, isNotNull);
    expect(result.diagnostics, isEmpty);
  });

  test(
    'rejects a stale active revision but keeps other revisions free',
    () async {
      final stale = await const DartCodeAnalyzer().analyze(
        request([snapshot(path, 'void main( {', revision: 3)], revision: 7),
      );
      expect(stale.unavailableReason, isNotNull);
      expect(stale.diagnostics, isEmpty);

      final helper = p.join(root.path, 'helper.dart');
      final mixed = await const DartCodeAnalyzer().analyze(
        request([
          snapshot(path, 'void main() {}', revision: 7),
          snapshot(helper, 'void helper( {', revision: 2),
        ], revision: 7),
      );
      expect(mixed.unavailableReason, isNull);
      expect(
        mixed.diagnostics,
        isNotEmpty,
        reason: 'A helper revision may differ from the active revision',
      );
      expect(mixed.diagnostics.every((item) => item.filePath == helper), isTrue);
    },
  );

  test('rejects duplicate aliases of a non-active buffer', () async {
    final helper = p.join(root.path, 'helper.dart');
    final alias = p.join(root.path, 'sub', '..', 'helper.dart');
    final result = await const DartCodeAnalyzer().analyze(
      request([
        snapshot(path, 'void main() {}'),
        snapshot(helper, 'void helper( {'),
        snapshot(alias, 'void helper() {}'),
      ]),
    );
    expect(result.unavailableReason, isNotNull);
    expect(result.diagnostics, isEmpty);
  });

  test('emits normalized absolute diagnostic paths', () async {
    final raw = '${root.path}/main.dart'.replaceAll('\\', '/');
    final result = await const DartCodeAnalyzer().analyze(
      request([snapshot(raw, 'void main( {')]),
    );
    expect(result.unavailableReason, isNull);
    expect(result.diagnostics, isNotEmpty);
    expect(
      result.diagnostics.every((item) => item.filePath == p.normalize(raw)),
      isTrue,
    );
    expect(
      result.diagnostics.every((item) => p.isAbsolute(item.filePath)),
      isTrue,
    );
  });

  test('rejects an absolute active file outside the project root', () async {
    final outside = p.join(root.parent.path, 'outside.dart');
    final result = await const DartCodeAnalyzer().analyze(
      request([
        snapshot(path, 'void main() {}'),
        snapshot(outside, 'void broken( {'),
      ], activeFilePath: outside),
    );
    expect(result.unavailableReason, isNotNull);
    expect(result.diagnostics, isEmpty);
  });

  test('rejects a duplicate active alias with identical text', () async {
    final alias = p.join(root.path, '.', 'main.dart');
    const text = 'void main( {';
    final result = await const DartCodeAnalyzer().analyze(
      request([snapshot(path, text), snapshot(alias, text)]),
    );
    expect(
      result.unavailableReason,
      isNotNull,
      reason: 'Matching text cannot merge two buffers for one path',
    );
    expect(result.diagnostics, isEmpty);
  });

  test('rejects a non-absolute document path', () async {
    final result = await const DartCodeAnalyzer().analyze(
      request([
        snapshot(path, 'void main() {}'),
        snapshot('helper.dart', 'void helper( {'),
      ]),
    );
    expect(result.unavailableReason, isNotNull);
    expect(result.diagnostics, isEmpty);
  });
}
