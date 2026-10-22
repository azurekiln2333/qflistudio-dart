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

  CodeAnalysisRequest request(List<CodeDocumentSnapshot> documents) =>
      CodeAnalysisRequest(
        projectPath: root.path,
        activeFilePath: path,
        language: 'dart',
        revision: 7,
        documents: documents,
      );

  test(
    'analyzes exact unsaved CRLF and UTF-16 source without changing disk',
    () async {
      const text = '// 😀\r\nvoid main() {\r\n  print(\r\n}\r\n';
      final result = await const DartCodeAnalyzer().analyze(
        request([CodeDocumentSnapshot(path: path, text: text, revision: 7)]),
      );
      expect(result.unavailableReason, isNull);
      final expected = DartTools.syntaxDiagnostics(text);
      expect(result.diagnostics, hasLength(expected.length));
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((item) => item.startOffset == 32),
        isTrue,
        reason:
            'The closing brace follows an emoji and three CRLF pairs at UTF-16 offset 32',
      );
      for (var i = 0; i < expected.length; i++) {
        final diagnostic = result.diagnostics[i];
        expect(diagnostic.filePath, path);
        expect(diagnostic.startOffset, expected[i].offset);
        expect(diagnostic.endOffset, expected[i].offset + expected[i].length);
        expect(diagnostic.source, 'Dart 语法');
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
          CodeDocumentSnapshot(path: path, text: 'void main() {}', revision: 7),
          CodeDocumentSnapshot(
            path: helper,
            text: 'void broken( {',
            revision: 3,
          ),
          CodeDocumentSnapshot(
            path: p.join(root.path, 'note.txt'),
            text: 'void (',
            revision: 1,
          ),
          CodeDocumentSnapshot(
            path: p.join(root.parent.path, 'outside.dart'),
            text: 'void (',
            revision: 1,
          ),
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
        request([
          CodeDocumentSnapshot(
            path: path,
            text: 'void main() { unresolved(); }',
            revision: 7,
          ),
        ]),
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
}
