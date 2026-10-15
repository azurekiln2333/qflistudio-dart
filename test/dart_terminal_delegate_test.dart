@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_runner.dart';
import 'package:qfli_dart/dart_tools.dart';
import 'package:qfli_dart/native_dart_toolchain.dart';
import 'package:qfli_studio_core/terminal/shell/sandbox_shell_backend.dart';
import 'package:qfli_studio_core/terminal/shell/shell_backend.dart';

/// Collects [SandboxShellBackend] output for assertions.
class _Harness {
  _Harness(String root, {required TerminalCommandDelegate delegate}) {
    backend = SandboxShellBackend(
      sandboxRoot: root,
      startDirectory: root,
      delegate: delegate,
    );
    _sub = backend.output.listen((chunk) {
      final lines = chunk.text
          .replaceAll('\r\n', '\n')
          .split('\n')
          .where((line) => line.isNotEmpty);
      switch (chunk.kind) {
        case OutputKind.stdout:
        case OutputKind.system:
          out.addAll(lines);
        case OutputKind.stderr:
          err.addAll(lines);
        case OutputKind.control:
          controls.add(chunk.text);
      }
    });
  }

  late final SandboxShellBackend backend;
  late final StreamSubscription<ShellChunk> _sub;
  final out = <String>[];
  final err = <String>[];
  final controls = <String>[];

  Future<void> run(String command) async {
    await backend.execute(command);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  Future<void> dispose() async {
    await _sub.cancel();
    await backend.shutdown();
  }
}

void main() {
  final nativeSupported = NativeDartToolchain.supported;
  late Directory project;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('qfli_dart_terminal_');
  });
  tearDown(() async {
    if (project.existsSync()) {
      try {
        await project.delete(recursive: true);
      } on FileSystemException {
        // Windows may hold the directory briefly; the OS reclaims the temp dir.
      }
    }
  });

  group('run routing', () {
    test('dart run <file> runs in the session working directory', () async {
      if (!nativeSupported) return;
      await File(p.join(project.path, 'src', 'main.dart'))
          .create(recursive: true)
          .then(
            (file) => file.writeAsString(
              "import 'dart:io'; void main() { print('terminal-dart'); "
              "print(File('marker.txt').absolute.path.contains('qfli_dart_terminal_')); }",
            ),
          );
      await File(p.join(project.path, 'marker.txt')).writeAsString('cwd');
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart run src/main.dart');
        expect(harness.err, isEmpty);
        expect(harness.out, contains('terminal-dart'));
        expect(harness.out, contains('true'));
        expect(harness.backend.lastExitCode, 0);
      } finally {
        await harness.dispose();
      }
    });

    test('the dart <file> shorthand behaves like run', () async {
      if (!nativeSupported) return;
      await File(
        p.join(project.path, 'main.dart'),
      ).writeAsString("void main() { print('shorthand'); }");
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart main.dart');
        expect(harness.err, isEmpty);
        expect(harness.out, contains('shorthand'));
        expect(harness.backend.lastExitCode, 0);
      } finally {
        await harness.dispose();
      }
    });

    test('a runtime failure keeps the program exit code', () async {
      if (!nativeSupported) return;
      await File(
        p.join(project.path, 'main.dart'),
      ).writeAsString("import 'dart:io'; void main() { exit(7); }");
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart run main.dart');
        expect(harness.backend.lastExitCode, 7);
      } finally {
        await harness.dispose();
      }
    });

    test('a missing file is reported without spawning', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart run nope.dart');
        expect(harness.err.join('\n'), contains('文件不存在'));
        expect(harness.backend.lastExitCode, isNull);
      } finally {
        await harness.dispose();
      }
    });

    test('a bare dart reports the missing subcommand honestly', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart');
        expect(harness.err.join('\n'), contains('子命令'));
        expect(harness.backend.lastExitCode, isNull);
      } finally {
        await harness.dispose();
      }
    });

    test('compound lines fall through instead of being misread', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart --version | cat');
        expect(harness.err.join('\n'), contains('管道'));
      } finally {
        await harness.dispose();
      }
    });

    test('an absolute path outside the sandbox is refused', () async {
      final outside = File(p.join(project.parent.path, 'outside_probe.dart'));
      await outside.parent.create(recursive: true);
      await outside.writeAsString('void main() {}');
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart run ${outside.path}');
        expect(harness.err.join('\n'), contains('不能越出沙盒目录'));
        expect(harness.backend.lastExitCode, isNull);
      } finally {
        await harness.dispose();
        if (outside.existsSync()) await outside.delete();
      }
    });

    test('a dart line from a nested session directory works', () async {
      if (!nativeSupported) return;
      final nested = Directory(p.join(project.path, 'src'))
        ..createSync(recursive: true);
      await File(
        p.join(nested.path, 'main.dart'),
      ).writeAsString("void main() { print('nested'); }");
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('cd src');
        await harness.run('dart run main.dart');
        expect(harness.err, isEmpty);
        expect(harness.out, contains('nested'));
        expect(harness.backend.lastExitCode, 0);
      } finally {
        await harness.dispose();
      }
    });
  });

  group('compile', () {
    test('dart compile kernel actually produces a runnable .dill', () async {
      if (!nativeSupported) return;
      await File(
        p.join(project.path, 'main.dart'),
      ).writeAsString("void main() { print('compiled'); }");
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart compile kernel main.dart');
        final artifact = File(p.join(project.path, 'build', 'main.dill'));
        expect(artifact.existsSync(), isTrue);
        expect(harness.err, isEmpty);
        expect(harness.out.join('\n'), contains('已生成'));
        // The produced artifact runs through the terminal's own run route.
        await harness.run('dart run build/main.dill');
        expect(harness.out, contains('compiled'));
        expect(harness.backend.lastExitCode, 0);
      } finally {
        await harness.dispose();
      }
    });

    test('dart compile without kernel is refused', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart compile exe main.dart');
        expect(harness.err.join('\n'), contains('compile kernel'));
        expect(harness.backend.lastExitCode, isNull);
      } finally {
        await harness.dispose();
      }
    });
  });

  group('format and analyze', () {
    test('dart format rewrites the file in place', () async {
      final file = File(p.join(project.path, 'main.dart'));
      await file.writeAsString('void main(){print("hi");}');
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart format main.dart');
        expect(harness.err, isEmpty);
        expect(await file.readAsString(), contains('void main() {'));
        expect(harness.out.join('\n'), contains('已格式化'));
      } finally {
        await harness.dispose();
      }
    });

    test('dart analyze reports parser diagnostics and labels them', () async {
      await File(
        p.join(project.path, 'main.dart'),
      ).writeAsString('void main( {');
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart analyze');
        expect(harness.err.join('\n'), contains('main.dart:'));
        expect(harness.out.join('\n'), contains('语法检查'));
      } finally {
        await harness.dispose();
      }
    });

    test('dart analyze on a clean project reports none', () async {
      await File(
        p.join(project.path, 'main.dart'),
      ).writeAsString('void main() {}');
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart analyze');
        expect(harness.err, isEmpty);
        expect(harness.out.join('\n'), contains('没有语法错误'));
      } finally {
        await harness.dispose();
      }
    });
  });

  group('offline refusals', () {
    test('network package commands are refused', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        for (final command in ['dart pub get', 'dart pub add http']) {
          harness.err.clear();
          await harness.run(command);
          expect(harness.err.join('\n'), contains('禁用'));
          expect(harness.backend.lastExitCode, isNull);
        }
      } finally {
        await harness.dispose();
      }
    });

    test('unknown subcommands name the supported set', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart test');
        expect(harness.err.join('\n'), contains('不支持'));
        expect(harness.err.join('\n'), contains('run'));
        expect(harness.backend.lastExitCode, isNull);
      } finally {
        await harness.dispose();
      }
    });

    test('unknown commands are not claimed by the hook', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dartlang --version');
        expect(harness.err.join('\n'), contains('dartlang'));
        expect(harness.err.join('\n'), contains('不支持'));
      } finally {
        await harness.dispose();
      }
    });
  });

  group('version', () {
    test('dart --version reports the real SDK version', () async {
      if (!nativeSupported) return;
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart --version');
        expect(harness.out.join(' '), contains('Dart SDK version'));
      } finally {
        await harness.dispose();
      }
    });
  });

  group('mobile argument assembly', () {
    test('run arguments are VM-native, never a CLI subcommand', () {
      final args = NativeDartToolchain.buildRunArguments(
        entry: '/proj/main.dart',
      );
      expect(args, ['--disable-dart-dev', '/proj/main.dart']);
      expect(args, isNot(contains('run')));
      final withPackages = NativeDartToolchain.buildRunArguments(
        entry: '/proj/main.dart',
        packageConfig: '/proj/.dart_tool/package_config.json',
      );
      expect(withPackages, [
        '--disable-dart-dev',
        '--packages=/proj/.dart_tool/package_config.json',
        '/proj/main.dart',
      ]);
    });

    test('android kernel arguments use the VM snapshot flags', () {
      final args = NativeDartToolchain.buildKernelArguments(
        entry: '/proj/main.dart',
        artifact: '/tmp/out.dill',
        packageConfig: '/proj/pkg.json',
        android: true,
      );
      expect(args, [
        '--disable-dart-dev',
        '--snapshot-kind=kernel',
        '--snapshot=/tmp/out.dill',
        '--packages=/proj/pkg.json',
        '/proj/main.dart',
      ]);
      // The bug this guards against: a CLI subcommand must never be sent to the
      // raw Android VM, which would read `run`/`compile` as a script name.
      expect(args, isNot(contains('run')));
      expect(args, isNot(contains('compile')));
      expect(args, isNot(contains('kernel')));
    });

    test('desktop kernel arguments use the CLI subcommand and -o', () {
      final args = NativeDartToolchain.buildKernelArguments(
        entry: '/proj/main.dart',
        artifact: '/tmp/out.dill',
        android: false,
      );
      expect(args, [
        'compile',
        'kernel',
        '/proj/main.dart',
        '-o',
        '/tmp/out.dill',
      ]);
    });
  });

  group('portable branch', () {
    test('the runner accepts a .dart file on every platform', () async {
      // This is the branch the OHOS delegate relies on: `NativeDartToolchain`
      // is unavailable there, so `DartProgramRunner` takes the portable
      // dart_eval path rather than reporting a missing capability.
      final file = File(p.join(project.path, 'main.dart'));
      await file.writeAsString("void main() { print('portable'); }");
      final result = await const DartProgramRunner().run(
        projectPath: project.path,
        entryFile: file.path,
      );
      expect(result, isNotNull);
      expect(await result!.stdout.toList(), ['portable']);
      expect(await result.exitCode, 0);
    });

    test('portable compilation round-trips through the evaluator', () async {
      final file = File(p.join(project.path, 'main.dart'));
      await file.writeAsString('int answer() => 42; void main() {}');
      final compiled = await DartTools.compilePortable(
        projectPath: project.path,
        entryFile: file.path,
      );
      expect(compiled.bytecode, isNotEmpty);
      expect(compiled.extension, '.evc');
    });

    test(
      'portable targets refuse a .dill entry rather than faking one',
      () async {
        // A `.dill` is a native Kernel artifact; the portable evaluator cannot
        // load it, so the runner must decline instead of reporting success.
        if (nativeSupported) return;
        final file = File(p.join(project.path, 'program.dill'));
        await file.writeAsBytes(const [0, 1, 2, 3]);
        final result = await const DartProgramRunner().run(
          projectPath: project.path,
          entryFile: file.path,
        );
        expect(result, isNull);
      },
    );
  });
}
