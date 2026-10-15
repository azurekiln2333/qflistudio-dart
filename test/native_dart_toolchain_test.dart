import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_runner.dart';
import 'package:qfli_dart/native_dart_toolchain.dart';

void main() {
  const toolchain = NativeDartToolchain();
  late Directory project;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('qfli-native-dart-test-');
  });
  tearDown(() async {
    // Windows can hold a directory briefly while a child process closes its
    // handles; a cleanup failure must not be reported as a test failure.
    try {
      await project.delete(recursive: true);
    } on FileSystemException {
      // The OS reclaims the temp directory.
    }
  });

  Future<String> source(String content) async {
    final file = File(p.join(project.path, 'main.dart'));
    await file.writeAsString(content);
    return file.path;
  }

  test('native VM supports real file IO and asynchronous execution', () async {
    final entry = await source(
      "import 'dart:io'; Future<void> main() async { await File('result.txt').writeAsString('native'); print(await File('result.txt').readAsString()); }",
    );
    final run = await toolchain.run(
      projectPath: project.path,
      entryFile: entry,
    );
    final errors = run.stderr.toList();
    expect(await run.stdout.toList(), ['native']);
    expect(await errors, isEmpty);
    expect(await run.exitCode, 0);
    expect(
      await File(p.join(project.path, 'result.txt')).readAsString(),
      'native',
    );
  });

  test('official compiler generates a reusable kernel program', () async {
    final entry = await source("void main() { print('kernel execution'); }");
    final artifact = File(p.join(project.path, 'program.dill'));
    await artifact.writeAsBytes(
      await toolchain.compileKernel(
        projectPath: project.path,
        entryFile: entry,
      ),
    );
    await File(entry).delete();
    final run = (await const DartProgramRunner().run(
      projectPath: project.path,
      entryFile: artifact.path,
    ))!;
    final errors = run.stderr.toList();
    expect(await run.stdout.toList(), ['kernel execution']);
    expect(await errors, isEmpty);
    expect(await run.exitCode, 0);
  });

  test('compile errors fail without producing a runnable artifact', () async {
    final entry = await source('void main( {');
    expect(
      toolchain.compileKernel(projectPath: project.path, entryFile: entry),
      throwsStateError,
    );
  });

  test('program exit codes are preserved', () async {
    final entry = await source("import 'dart:io'; void main() { exit(42); }");
    final run = await toolchain.run(
      projectPath: project.path,
      entryFile: entry,
    );
    final output = run.stdout.toList();
    final errors = run.stderr.toList();
    expect(await run.exitCode, 42);
    await output;
    await errors;
  });

  test('input.txt is fed to stdin and missing input is EOF', () async {
    final entry = await source(
      "import 'dart:io'; void main() { print(stdin.readLineSync() ?? 'eof'); }",
    );
    final input = File(p.join(project.path, 'input.txt'));
    await input.writeAsString('native-input\n');
    for (final expected in ['native-input', 'eof']) {
      final run = await toolchain.run(
        projectPath: project.path,
        entryFile: entry,
      );
      final output = run.stdout.toList();
      final errors = run.stderr.toList();
      expect(await run.exitCode.timeout(const Duration(seconds: 20)), 0);
      expect(await output, [expected]);
      expect(await errors, isEmpty);
      if (await input.exists()) await input.delete();
    }
  });

  test('an active native program can be stopped', () async {
    final entry = await source(
      "void main() { print('ready'); while (true) {} }",
    );
    final run = await toolchain.run(
      projectPath: project.path,
      entryFile: entry,
    );
    final errors = run.stderr.toList();
    await run.stdout
        .firstWhere((line) => line == 'ready')
        .timeout(const Duration(seconds: 15));
    await run.cancel!();
    expect(await run.exitCode, 130);
    await errors;
  });
}
