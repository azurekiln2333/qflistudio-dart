import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:qfli_studio_core/services/code_analysis.dart';

import 'dart_tools.dart';

/// Offline scanner/parser analysis of exact unsaved Dart snapshots.
/// This does not run user code or claim type/package resolution.
class DartCodeAnalyzer implements CodeAnalyzer {
  const DartCodeAnalyzer();

  @override
  Future<CodeAnalysisResult> analyze(CodeAnalysisRequest request) async {
    final root = p.normalize(p.absolute(request.projectPath));
    final active = p.normalize(p.absolute(request.activeFilePath));
    if (!p.isWithin(root, active)) {
      return const CodeAnalysisResult(unavailableReason: 'Dart 文件不在当前项目内');
    }
    final documents = request.documents.where((document) {
      final path = p.normalize(p.absolute(document.path));
      return p.isWithin(root, path) &&
          p.extension(path).toLowerCase() == '.dart';
    }).toList();
    if (!documents.any((document) => p.equals(document.path, active))) {
      return const CodeAnalysisResult(unavailableReason: '没有当前 Dart 文件的未保存快照');
    }
    return Isolate.run(() => _analyzeDocuments(documents));
  }
}

CodeAnalysisResult _analyzeDocuments(List<CodeDocumentSnapshot> documents) =>
    CodeAnalysisResult(
      diagnostics: [
        for (final document in documents)
          for (final diagnostic in DartTools.syntaxDiagnostics(document.text))
            CodeDiagnostic(
              filePath: document.path,
              startOffset: diagnostic.offset.clamp(0, document.text.length),
              endOffset: (diagnostic.offset + diagnostic.length).clamp(
                0,
                document.text.length,
              ),
              message: diagnostic.message,
              severity: switch (diagnostic.severity.toLowerCase()) {
                'warning' => CodeDiagnosticSeverity.warning,
                'info' => CodeDiagnosticSeverity.information,
                _ => CodeDiagnosticSeverity.error,
              },
              source: 'Dart 语法',
              code: diagnostic.code,
            ),
      ],
    );
