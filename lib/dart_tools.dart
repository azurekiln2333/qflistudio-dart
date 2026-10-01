import 'dart:isolate';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_style/dart_style.dart';

import 'dart_project_sources.dart';
import 'native_dart_toolchain.dart';

class DartDiagnostic {
  const DartDiagnostic({
    required this.message,
    required this.code,
    required this.severity,
    required this.line,
    required this.column,
  });

  final String message;
  final String code;
  final String severity;
  final int line;
  final int column;
}

class CompiledDartProgram {
  const CompiledDartProgram({
    required this.bytecode,
    required this.entryUri,
    this.extension = '.evc',
  });

  final Uint8List bytecode;
  final String entryUri;
  final String extension;
}

abstract final class DartTools {
  static String format(String source) => DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format(source);

  /// Scanner and parser diagnostics for a single unsaved editor buffer.
  static List<DartDiagnostic> syntaxDiagnostics(String source) {
    final result = parseString(content: source, throwIfDiagnostics: false);
    return [
      for (final diagnostic in result.errors)
        DartDiagnostic(
          message: diagnostic.message,
          code: diagnostic.diagnosticCode.name,
          severity: diagnostic.severity.name,
          line: result.lineInfo.getLocation(diagnostic.offset).lineNumber,
          column: result.lineInfo.getLocation(diagnostic.offset).columnNumber,
        ),
    ];
  }

  static Future<CompiledDartProgram> compile({
    required String projectPath,
    required String entryFile,
  }) async {
    if (NativeDartToolchain.supported) {
      return CompiledDartProgram(
        bytecode: await const NativeDartToolchain().compileKernel(
          projectPath: projectPath,
          entryFile: entryFile,
        ),
        entryUri: Uri.file(entryFile).toString(),
        extension: '.dill',
      );
    }
    return compilePortable(projectPath: projectPath, entryFile: entryFile);
  }

  static Future<CompiledDartProgram> compilePortable({
    required String projectPath,
    required String entryFile,
  }) async {
    final project = await DartProjectSources.load(
      projectPath: projectPath,
      entryFile: entryFile,
    );
    return Isolate.run(() {
      final compiler = Compiler()..entrypoints.add(project.entryUri);
      final program = compiler.compile(project.packages);
      return CompiledDartProgram(
        bytecode: program.write(),
        entryUri: project.entryUri,
      );
    });
  }
}
