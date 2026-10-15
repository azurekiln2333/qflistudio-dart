@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_runner.dart';
import 'package:qfli_dart/native_dart_toolchain.dart';
import 'package:qfli_studio_core/terminal/shell/sandbox_shell_backend.dart';
import 'package:qfli_studio_core/terminal/shell/shell_backend.dart';

/// Collects [SandboxShellBackend] output for assertions, mirroring the shared
/// core's own terminal harness so a delegate regression is caught here.
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
    // Let the last queued chunks flush before asserting.
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

  test(
    'dart run executes the real program in the session working directory',
    () async {
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
        // The process ran with the session cwd as its working directory, so the
        // relative marker resolves inside this project rather than the host's
        // process directory.
        expect(harness.out, contains('true'));
        expect(harness.backend.lastExitCode, 0);
      } finally {
        await harness.dispose();
      }
    },
  );

  test('dart --version reports the real SDK version', () async {
    if (!nativeSupported) return;
    final harness = _Harness(project.path, delegate: dartTerminalDelegate);
    try {
      await harness.run('dart --version');
      expect(harness.backend.lastExitCode, 0);
      final text = '${harness.out.join(' ')} ${harness.err.join(' ')}';
      expect(text, contains('Dart SDK version'));
    } finally {
      await harness.dispose();
    }
  });

  test('a compiling failure surfaces the native exit status', () async {
    if (!nativeSupported) return;
    await File(p.join(project.path, 'main.dart')).writeAsString('void main( {');
    final harness = _Harness(project.path, delegate: dartTerminalDelegate);
    try {
      await harness.run('dart compile kernel main.dart');
      expect(harness.backend.lastExitCode, isNotNull);
      expect(harness.backend.lastExitCode, isNonZero);
      expect(harness.err.join('\n'), isNotEmpty);
    } finally {
      await harness.dispose();
    }
  });

  test('unknown commands are not claimed by the Dart hook', () async {
    final harness = _Harness(project.path, delegate: dartTerminalDelegate);
    try {
      await harness.run('dartlang --version');
      // The sandbox's own honest "unsupported command" message must appear,
      // proving the hook did not swallow a non-`dart` command.
      expect(harness.err.join('\n'), contains('dartlang'));
      expect(harness.err.join('\n'), contains('不支持'));
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

  test('dart runs from a nested session directory', () async {
    if (!nativeSupported) return;
    final nested = Directory(p.join(project.path, 'src'))
      ..createSync(recursive: true);
    await File(
      p.join(nested.path, 'main.dart'),
    ).writeAsString("void main() { print('nested'); }");
    final harness = _Harness(project.path, delegate: dartTerminalDelegate);
    try {
      await harness.run('cd src');
      await harness.run('dart main.dart');
      expect(harness.err, isEmpty);
      expect(harness.out, contains('nested'));
      expect(harness.backend.lastExitCode, 0);
    } finally {
      await harness.dispose();
    }
  });

  group('offline policy', () {
    test('all package-management commands are refused', () {
      for (final command in <List<String>>[
        ['pub', 'get'],
        ['pub', 'add', 'http'],
        ['pub', 'upgrade'],
        ['pub', 'cache', 'repair'],
        ['pub', 'publish'],
        ['pub', 'global', 'activate', 'foo'],
        ['pub', 'token', 'list'],
        ['global', 'activate', 'foo'],
      ]) {
        expect(
          DartTerminalPolicy.reject(command),
          isNotNull,
          reason: 'dart ${command.join(' ')} must be refused offline',
        );
      }
    });

    test('unsupported subcommands are refused, the allowlist passes', () {
      for (final command in <List<String>>[
        ['create', 'demo'],
        ['test'],
        ['doc'],
        ['compilejs'],
      ]) {
        expect(DartTerminalPolicy.reject(command), isNotNull);
      }
      for (final command in <List<String>>[
        ['run', 'src/main.dart'],
        ['compile', 'kernel', 'main.dart'],
        ['format', 'lib'],
        ['analyze'],
        ['fix', '--apply'],
        ['help'],
      ]) {
        expect(
          DartTerminalPolicy.reject(command),
          isNull,
          reason: 'dart ${command.join(' ')} must stay available offline',
        );
      }
    });

    test('VM flags that escape the project or open a port are refused', () {
      for (final command in <List<String>>[
        ['run', '--packages=/tmp/other/package_config.json', 'main.dart'],
        ['run', '--snapshot=/tmp/out.dill', 'main.dart'],
        ['run', '--enable-vm-service', 'main.dart'],
        ['--observe', 'run', 'main.dart'],
        ['--packages=/tmp/other/package_config.json', 'main.dart'],
      ]) {
        expect(
          DartTerminalPolicy.reject(command),
          isNotNull,
          reason: 'dart ${command.join(' ')} must be refused',
        );
      }
      expect(DartTerminalPolicy.reject(['--version']), isNull);
      expect(DartTerminalPolicy.reject(const []), isNotNull);
      // A flag after `run` belongs to the program, not the VM, so it is user
      // data the sandbox must forward rather than refuse.
      expect(DartTerminalPolicy.reject(['run', 'main.dart', '--flag']), isNull);
    });

    test('the dart <script> shorthand stays available offline', () {
      expect(DartTerminalPolicy.reject(['main.dart']), isNull);
      expect(DartTerminalPolicy.reject(['build/main.dill']), isNull);
      expect(DartTerminalPolicy.subcommand(['main.dart']), 'run');
      // A non-script bare word is still an unknown subcommand.
      expect(DartTerminalPolicy.reject(['frobnicate']), isNotNull);
    });

    test('runCommand refuses the same escape flags as a last resort', () async {
      expect(
        const NativeDartToolchain().runCommand(
          workingDirectory: Directory.systemTemp.path,
          arguments: const ['run', '--packages=/tmp/x.json', 'main.dart'],
        ),
        throwsArgumentError,
      );
    });

    test('a pub line through the backend never reaches a process', () async {
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart pub get');
        expect(harness.err.join('\n'), contains('禁用'));
        expect(harness.err.join('\n'), contains('pub'));
        // A refusal is not a command status: no process ran.
        expect(harness.backend.lastExitCode, isNull);
      } finally {
        await harness.dispose();
      }
    });

    test('an absolute path outside the sandbox is refused', () async {
      final outside = File(p.join(project.parent.path, 'outside_probe.dart'));
      await harnessWrite(outside, 'void main() {}');
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

    test('an in-sandbox run operand is still allowed', () async {
      if (!nativeSupported) return;
      await File(
        p.join(project.path, 'main.dart'),
      ).writeAsString("void main() { print('allowed'); }");
      final harness = _Harness(project.path, delegate: dartTerminalDelegate);
      try {
        await harness.run('dart run main.dart');
        expect(harness.err, isEmpty);
        expect(harness.out, contains('allowed'));
        expect(harness.backend.lastExitCode, 0);
      } finally {
        await harness.dispose();
      }
    });
  });
}

Future<void> harnessWrite(File file, String content) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
