import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:qfli_studio_core/services/code_analysis.dart';

import 'dart_tools.dart';

/// Offline scanner/parser analysis of exact unsaved Dart snapshots.
///
/// This provider runs no user code, reads no source file and writes nothing to
/// disk. It reports scanner/parser diagnostics only, so a clean result never
/// claims type, lint or dependency correctness.
///
/// The request is rejected with an [CodeAnalysisResult.unavailableReason]
/// instead of a clean result whenever the input cannot be attributed to exactly
/// one Dart buffer. A false clean result is the failure mode this guards
/// against.
class DartCodeAnalyzer implements CodeAnalyzer {
  const DartCodeAnalyzer();

  /// The only language this provider can parse.
  static const String dartLanguage = 'dart';

  /// Source label attached to every emitted diagnostic.
  static const String sourceLabel = 'Dart 语法';

  static const String _notDartLanguage = '当前请求不是 Dart 语言';
  static const String _relativePath = 'Dart 快照路径必须是绝对路径';
  static const String _activeNotDart = '当前文件不是 Dart 源文件';
  static const String _activeOutsideRoot = 'Dart 文件不在当前项目内';
  static const String _noActiveSnapshot = '没有当前 Dart 文件的未保存快照';
  static const String _duplicateActive = '当前 Dart 文件存在重复快照';
  static const String _duplicateSnapshot = 'Dart 快照路径重复或冲突';
  static const String _staleActiveRevision = '当前 Dart 快照版本与请求不一致';

  @override
  Future<CodeAnalysisResult> analyze(CodeAnalysisRequest request) async {
    if (request.language.trim().toLowerCase() != dartLanguage) {
      return _unavailable(_notDartLanguage);
    }
    // A relative path would be resolved against the process working directory,
    // so a wrong guess could attribute diagnostics to an unrelated file.
    if (!p.isAbsolute(request.projectPath) ||
        !p.isAbsolute(request.activeFilePath)) {
      return _unavailable(_relativePath);
    }

    final root = p.normalize(request.projectPath);
    final active = p.normalize(request.activeFilePath);
    if (!_isDartSource(active)) return _unavailable(_activeNotDart);
    if (!p.isWithin(root, active)) return _unavailable(_activeOutsideRoot);

    final grouped = <String, List<CodeDocumentSnapshot>>{};
    final paths = <String, String>{};
    for (final document in request.documents) {
      if (!p.isAbsolute(document.path)) return _unavailable(_relativePath);
      final path = p.normalize(document.path);
      if (!_isDartSource(path) || !p.isWithin(root, path)) continue;
      final identity = _identity(path);
      final group = grouped.putIfAbsent(
        identity,
        () => <CodeDocumentSnapshot>[],
      );
      group.add(document);
      paths[identity] = path;
    }

    final activeIdentity = _identity(active);
    final activeDocuments = grouped[activeIdentity];
    if (activeDocuments == null || activeDocuments.isEmpty) {
      return _unavailable(_noActiveSnapshot);
    }
    // Two snapshots for one path cannot be attributed to a single buffer, even
    // when their text happens to match.
    if (activeDocuments.length > 1) return _unavailable(_duplicateActive);
    // Other buffers carry independent revisions, so only the active buffer is
    // checked against the request revision.
    if (activeDocuments.single.revision != request.revision) {
      return _unavailable(_staleActiveRevision);
    }
    if (grouped.values.any((documents) => documents.length > 1)) {
      return _unavailable(_duplicateSnapshot);
    }

    final snapshots = <_DartSnapshot>[
      for (final entry in grouped.entries)
        _DartSnapshot(path: paths[entry.key]!, text: entry.value.single.text),
    ];
    return Isolate.run(() => _analyzeDocuments(snapshots));
  }

  static CodeAnalysisResult _unavailable(String reason) =>
      CodeAnalysisResult(unavailableReason: reason);

  static bool _isDartSource(String path) =>
      p.extension(path).toLowerCase() == '.dart';

  /// Filesystem identity used to detect duplicate aliases. Windows paths are
  /// case-insensitive, matching how the shared core compares paths.
  static String _identity(String path) =>
      Platform.isWindows ? path.toLowerCase() : path;
}

/// One exact unsaved buffer with its normalized absolute path.
///
/// The text is passed through untouched, so CRLF and UTF-16 offsets inside the
/// parser result keep matching the editor buffer.
class _DartSnapshot {
  const _DartSnapshot({required this.path, required this.text});

  final String path;
  final String text;
}

CodeAnalysisResult _analyzeDocuments(List<_DartSnapshot> documents) =>
    CodeAnalysisResult(
      diagnostics: [
        for (final document in documents)
          for (final diagnostic in DartTools.syntaxDiagnostics(document.text))
            CodeDiagnostic(
              filePath: document.path,
              startOffset: diagnostic.offset.clamp(0, document.text.length),
              endOffset: (diagnostic.offset + diagnostic.length).clamp(
                diagnostic.offset.clamp(0, document.text.length),
                document.text.length,
              ),
              message: diagnostic.message,
              severity: _severity(diagnostic.severity),
              source: DartCodeAnalyzer.sourceLabel,
              code: diagnostic.code,
            ),
      ],
    );

CodeDiagnosticSeverity _severity(String value) => switch (value.toLowerCase()) {
  'warning' => CodeDiagnosticSeverity.warning,
  'info' || 'information' => CodeDiagnosticSeverity.information,
  'hint' => CodeDiagnosticSeverity.hint,
  _ => CodeDiagnosticSeverity.error,
};
