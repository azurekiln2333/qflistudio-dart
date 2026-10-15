import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/android_dart_sdk.dart';
import 'package:qfli_dart/dart_runner.dart';
import 'package:qfli_dart/dart_tools.dart';
import 'package:qfli_studio_core/terminal/shell/sandbox_shell_backend.dart';
import 'package:qfli_studio_core/terminal/shell/shell_backend.dart';

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

    final terminal = SandboxShellBackend(
      sandboxRoot: root,
      delegate: dartTerminalDelegate,
    );
    final terminalOutput = StringBuffer();
    final terminalErrors = StringBuffer();
    final subscription = terminal.output.listen((chunk) {
      if (chunk.kind == OutputKind.stderr) {
        terminalErrors.write(chunk.text);
      } else {
        terminalOutput.write(chunk.text);
      }
    });
    Future<void> command(String text) async {
      terminalOutput.clear();
      terminalErrors.clear();
      await terminal.execute(text).timeout(const Duration(seconds: 60));
    }

    try {
      await command('dart --version');
      if (!terminalOutput.toString().contains('Dart SDK version:') ||
          terminalErrors.isNotEmpty) {
        throw StateError('Terminal version failed: $terminalErrors');
      }
      checks.add('terminal-version');
      await write('main.dart', "void main(){print('terminal-42');}");
      await command('dart run main.dart');
      if (terminal.lastExitCode != 0 ||
          !terminalOutput.toString().contains('terminal-42') ||
          terminalErrors.isNotEmpty) {
        throw StateError('Terminal run failed: $terminalErrors');
      }
      checks.add('terminal-source');
      await command('dart format main.dart');
      final formatted = await File(p.join(root, 'main.dart')).readAsString();
      if (terminalErrors.isNotEmpty ||
          formatted != DartTools.format(formatted)) {
        throw StateError('Terminal format failed: $terminalErrors');
      }
      checks.add('terminal-format');
      await write('main.dart', 'void main( {');
      await command('dart analyze main.dart');
      if (!terminalErrors.toString().contains('main.dart:')) {
        throw StateError('Terminal syntax diagnostics missing');
      }
      checks.add('terminal-syntax-diagnostics');
      await write('main.dart', "void main() { print('terminal-42'); }");
      await command('dart compile kernel main.dart');
      if (terminalErrors.isNotEmpty ||
          !await File(p.join(root, 'build/main.dill')).exists()) {
        throw StateError('Terminal Kernel compile failed: $terminalErrors');
      }
      await File(p.join(root, 'main.dart')).delete();
      await command('dart run build/main.dill');
      if (terminal.lastExitCode != 0 ||
          !terminalOutput.toString().contains('terminal-42')) {
        throw StateError('Terminal source-free Kernel failed: $terminalErrors');
      }
      checks.add('terminal-source-free-kernel');
      await write(
        'main.dart',
        "void main() { print('terminal-running'); while (true) {} }",
      );
      final started = terminal.output.firstWhere(
        (chunk) => chunk.text.contains('terminal-running'),
      );
      final running = terminal.execute('dart run main.dart');
      await started.timeout(const Duration(seconds: 30));
      // Output delivery is synchronous. Let that callback return before the
      // interrupt emits its own transcript line, as a separate UI event does.
      await Future<void>(() {});
      await terminal.interrupt().timeout(const Duration(seconds: 10));
      await running.timeout(const Duration(seconds: 10));
      // The shared terminal clears its last status on interruption; the direct
      // runner check above separately verifies the native cancellation code 130.
      if (terminal.busy ||
          terminal.lastExitCode != null ||
          !terminalOutput.toString().contains('^C')) {
        throw StateError('Terminal interruption did not finish cleanly');
      }
      await write('main.dart', "void main() { print('after-stop'); }");
      await command('dart run main.dart');
      if (terminal.lastExitCode != 0 ||
          !terminalOutput.toString().contains('after-stop')) {
        throw StateError('Terminal did not recover after Stop');
      }
      checks.add('terminal-stop-recovery');
      await command('dart pub get');
      if (!terminalErrors.toString().contains('离线版终端禁用')) {
        throw StateError('Terminal package downloads were not disabled');
      }
      checks.add('terminal-offline-policy');
    } finally {
      await terminal.shutdown();
      await subscription.cancel();
    }
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
