import 'dart:isolate';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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
    this.offset = 0,
    this.length = 0,
  });

  final String message;
  final String code;
  final String severity;
  final int line;
  final int column;
  final int offset;
  final int length;
}

class DartSourceItem {
  const DartSourceItem({
    required this.label,
    required this.kind,
    required this.offset,
    required this.length,
    required this.line,
  });

  final String label;
  final String kind;
  final int offset;
  final int length;
  final int line;
}

class DartSourceOverview {
  const DartSourceOverview({
    required this.lines,
    required this.characters,
    required this.outline,
    required this.directives,
  });

  final int lines;
  final int characters;
  final List<DartSourceItem> outline;
  final List<DartSourceItem> directives;
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
          offset: diagnostic.offset,
          length: diagnostic.length,
        ),
    ];
  }

  /// AST structure of the current buffer, without saving or resolving packages.
  static DartSourceOverview sourceOverview(String source) {
    final parsed = parseString(content: source, throwIfDiagnostics: false);
    final outline = <DartSourceItem>[];
    final visitor = _SourceOutline((label, kind, node) {
      outline.add(
        DartSourceItem(
          label: label,
          kind: kind,
          offset: node.offset,
          length: node.length,
          line: parsed.lineInfo.getLocation(node.offset).lineNumber,
        ),
      );
    });
    parsed.unit.accept(visitor);
    return DartSourceOverview(
      lines: parsed.lineInfo.lineCount,
      characters: source.runes.length,
      outline: List.unmodifiable(outline),
      directives: List.unmodifiable([
        for (final directive in parsed.unit.directives)
          if (directive is UriBasedDirective)
            DartSourceItem(
              label: directive.uri.stringValue ?? directive.uri.toSource(),
              kind: switch (directive) {
                ImportDirective() => 'import',
                ExportDirective() => 'export',
                PartDirective() => 'part',
              },
              offset: directive.offset,
              length: directive.length,
              line: parsed.lineInfo.getLocation(directive.offset).lineNumber,
            ),
      ]),
    );
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

class _SourceOutline extends RecursiveAstVisitor<void> {
  _SourceOutline(this.add);

  final void Function(String label, String kind, AstNode node) add;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    add(node.name.lexeme, 'class', node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    add(node.name.lexeme, 'enum', node);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    add(node.name.lexeme, 'mixin', node);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    add(node.name?.lexeme ?? '(unnamed extension)', 'extension', node);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    add(node.name.lexeme, 'function', node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    add(node.name.lexeme, node.isGetter ? 'getter' : 'method', node);
    super.visitMethodDeclaration(node);
  }
}
