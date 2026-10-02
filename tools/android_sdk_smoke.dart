import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/android_dart_sdk.dart';
import 'package:qfli_dart/dart_runner.dart';
import 'package:qfli_dart/dart_tools.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.shrink(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => _check());
}

Future<void> _check() async {
  final checks = <String>[];
  Directory? project;
  try {
    final sdk = await AndroidDartSdk.prepare();
    checks.add('native-version');
    project = await Directory(p.join(sdk.home, 'tmp')).createTemp('sdk-smoke-');
    final root = project.path;
    Future<void> write(String name, String source) async {
      final file = File(p.join(root, name));
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
    }

    Future<({List<String> output, List<String> errors, int code})> run(
      String entry,
    ) async {
      final result = await const DartProgramRunner().run(
        projectPath: root,
        entryFile: p.join(root, entry),
      );
      if (result == null) throw StateError('Runner rejected $entry');
      final output = result.stdout.toList();
      final errors = result.stderr.toList();
      final code = await result.exitCode.timeout(const Duration(seconds: 60));
      return (output: await output, errors: await errors, code: code);
    }

    await write('pubspec.yaml', 'name: native_sdk_smoke\n');
    await write('lib/helper.dart', 'int twice(int value) => value * 2;');
    await write('input.txt', '21\n');
    await write('main.dart', r'''
import 'dart:io';
import 'package:native_sdk_smoke/helper.dart';
Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
  final value = twice(int.parse(stdin.readLineSync()!));
  await File('native-result.txt').writeAsString('$value');
  print(await File('native-result.txt').readAsString());
  print('\u4f60\u597d\uff0cDart');
}
''');
    final first = await run('main.dart');
    if (first.code != 0 ||
        first.output.join('|') != '42|\u4f60\u597d\uff0cDart' ||
        first.errors.isNotEmpty) {
      throw StateError('Native Dart source failed: $first');
    }
    checks.addAll(['self-package-import', 'stdin', 'async-file-io', 'utf8']);

    final compiled = await DartTools.compile(
      projectPath: root,
      entryFile: p.join(root, 'main.dart'),
    );
    if (compiled.extension != '.dill') {
      throw StateError('Expected upstream Kernel');
    }
    await File(p.join(root, 'main.dill')).writeAsBytes(compiled.bytecode);
    await File(p.join(root, 'main.dart')).delete();
    await File(p.join(root, 'lib/helper.dart')).delete();
    final artifact = await run('main.dill');
    if (artifact.code != 0 ||
        artifact.output.join('|') != first.output.join('|')) {
      throw StateError('Source-free Kernel failed: $artifact');
    }
    checks.add('source-free-kernel');

    await write('main.dart', 'void main( {');
    final invalid = await run('main.dart');
    if (invalid.code == 0 || !invalid.errors.join().contains('main.dart')) {
      throw StateError('Compiler diagnostics missing: $invalid');
    }
    checks.add('compiler-diagnostics');
    await write('main.dart', "import 'dart:io'; void main() { exit(7); }");
    final exited = await run('main.dart');
    if (exited.code != 7) {
      throw StateError('Native exit code was ${exited.code}');
    }
    checks.add('exit-code');

    await write(
      'main.dart',
      "void main() { print('running'); while (true) {} }",
    );
    final loop = (await const DartProgramRunner().run(
      projectPath: root,
      entryFile: p.join(root, 'main.dart'),
    ))!;
    final errors = loop.stderr.toList();
    await loop.stdout
        .firstWhere((line) => line == 'running')
        .timeout(const Duration(seconds: 30));
    await loop.cancel!().timeout(const Duration(seconds: 10));
    if (await loop.exitCode != 130) {
      throw StateError('Cancellation did not return 130');
    }
    await errors;
    checks.add('cancel');
    debugPrint(
      'QFLI_DART_ANDROID_SMOKE ${jsonEncode({'ok': true, 'checks': checks, 'home': sdk.home})}',
    );
  } catch (error, stack) {
    debugPrint(
      'QFLI_DART_ANDROID_SMOKE ${jsonEncode({'ok': false, 'checks': checks, 'error': error.toString(), 'stack': stack.toString()})}',
    );
  } finally {
    await project?.delete(recursive: true);
  }
}
