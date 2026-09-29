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
  });

  test('compiled EVC bytecode can be loaded and executed', () async {
    final project = await Directory.systemTemp.createTemp('qfli_dart_compile');
    try {
      final mainFile = File(p.join(project.path, 'src', 'main.dart'));
      await mainFile.parent.create(recursive: true);
      await mainFile.writeAsString('int main() => 42;');

      final compiled = await DartTools.compile(
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
      await project.delete(recursive: true);
    }
  });
}
