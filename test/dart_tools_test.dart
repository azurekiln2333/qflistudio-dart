import 'dart:io';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_tools.dart';

void main() {
  test('Dart formatter applies language-aware layout', () {
    final formatted = DartTools.format('void main(){print("hi");}');
    expect(formatted, contains('void main() {\n  print("hi");\n}'));
  });

  test('syntax diagnostics include source location', () {
    final diagnostics = DartTools.syntaxDiagnostics(
      'void main() {\n  print(\n}',
    );
    expect(diagnostics, isNotEmpty);
    expect(diagnostics.any((item) => item.line > 1), isTrue);
    expect(diagnostics.every((item) => item.code.isNotEmpty), isTrue);
    expect(diagnostics.every((item) => item.offset >= 0), isTrue);
  });

  test('AST outline ignores code-shaped comments and strings', () {
    const source = '''
import 'dart:math';
export 'helper.dart';
// class Fake {}
const text = 'void imaginary() {}';
class Meter {
  int value() => 1;
  int get size => 2;
}
enum Choice { first, second }
mixin Useful { void work() {} }
extension TextInfo on String { int count() => length; }
void main() { print(text); }
''';
    final overview = DartTools.sourceOverview(source);
    expect(overview.directives.map((item) => item.label), [
      'dart:math',
      'helper.dart',
    ]);
    expect(overview.directives.map((item) => item.kind), ['import', 'export']);
    expect(overview.outline.map((item) => item.label), [
      'Meter',
      'value',
      'size',
      'Choice',
      'Useful',
      'work',
      'TextInfo',
      'count',
      'main',
    ]);
    for (final item in overview.outline) {
      expect(
        source.substring(item.offset, item.offset + item.length),
        contains(item.label),
      );
      expect(item.line, greaterThan(1));
    }
  });

  test(
    'source locations preserve UTF-16 offsets and Unicode character count',
    () {
      const source = "// 😀\nvoid main() { print(\n}\n";
      final overview = DartTools.sourceOverview(source);
      expect(overview.characters, source.runes.length);
      expect(overview.lines, 4);
      expect(overview.outline.single.offset, source.indexOf('void'));
      final errors = DartTools.syntaxDiagnostics(source);
      expect(errors, isNotEmpty);
      for (final error in errors) {
        expect(error.offset, inInclusiveRange(0, source.length));
        expect(error.length, greaterThanOrEqualTo(0));
        expect(error.line, greaterThanOrEqualTo(2));
      }
    },
  );

  test('compiled EVC bytecode can be loaded and executed', () async {
    final project = await Directory.systemTemp.createTemp('qfli_dart_compile');
    try {
      final mainFile = File(p.join(project.path, 'src', 'main.dart'));
      await mainFile.parent.create(recursive: true);
      await mainFile.writeAsString('int main() => 42;');

      final compiled = await DartTools.compilePortable(
        projectPath: project.path,
        entryFile: mainFile.path,
      );
      expect(compiled.bytecode, isNotEmpty);
      final artifact = File(p.join(project.path, 'program.evc'));
      await artifact.writeAsBytes(compiled.bytecode);
      final runtime = Runtime(
        ByteData.sublistView(await artifact.readAsBytes()),
      );
      expect(runtime.executeLib(compiled.entryUri, 'main'), 42);
    } finally {
      // Windows may still hold the file briefly; a cleanup failure must not
      // mask the assertion above.
      try {
        await project.delete(recursive: true);
      } on FileSystemException {
        // The OS reclaims the temp directory.
      }
    }
  });
}
