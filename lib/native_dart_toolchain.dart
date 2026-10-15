import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';

import 'android_dart_sdk.dart';

class NativeDartToolchain {
  const NativeDartToolchain({this.executable});

  final String? executable;

  static bool get supported =>
      Platform.isAndroid ||
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS;

  Future<String> resolveExecutable() async {
    if (executable != null) {
      if (await File(executable!).exists()) return executable!;
      throw FileSystemException(
        'Dart SDK executable does not exist',
        executable,
      );
    }
    if (Platform.isAndroid) return (await AndroidDartSdk.prepare()).vm;
    final name = Platform.isWindows ? 'dart.exe' : 'dart';
    final appDirectory = p.dirname(Platform.resolvedExecutable);
    final macArchitecture = Abi.current() == Abi.macosArm64 ? 'arm64' : 'x64';
    final sdkRoots = [
      if (Platform.environment['QFLI_DART_SDK'] case final String root) root,
      if (Platform.environment['DART_SDK'] case final String root) root,
      if (Platform.isMacOS)
        p.join(appDirectory, '..', 'Helpers', 'dart-sdk', macArchitecture)
      else
        p.join(appDirectory, 'data', 'dart-sdk'),
      if (Platform.environment['FLUTTER_ROOT'] case final String root)
        p.join(root, 'bin', 'cache', 'dart-sdk'),
    ];
    final paths = [
      for (final root in sdkRoots) p.join(root, 'bin', name),
      for (final directory in (Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ))
        if (directory.isNotEmpty) ...[
          p.join(directory, name),
          p.join(directory, 'cache', 'dart-sdk', 'bin', name),
        ],
    ];
    for (final path in paths) {
      if (await File(path).exists()) return p.normalize(p.absolute(path));
    }
    throw StateError('没有找到 Dart SDK，请配置本地 SDK。');
  }

  Future<ProgramRunResult> run({
    required String projectPath,
    required String entryFile,
  }) async {
    final sdk = await resolveExecutable();
    final entry = await _entry(projectPath, entryFile);
    final packages = await _packages(projectPath);
    late final Process process;
    try {
      process = await Process.start(
        sdk,
        [
          '--disable-dart-dev',
          if (packages.path != null) '--packages=${packages.path}',
          entry,
        ],
        workingDirectory: p.absolute(projectPath),
        environment: Platform.isAndroid
            ? (await AndroidDartSdk.prepare()).environment
            : null,
      );
    } catch (_) {
      await packages.dispose();
      rethrow;
    }
    unawaited(
      _feedInput(process.stdin, File(p.join(projectPath, 'input.txt'))),
    );
    var finished = false;
    var cancelled = false;
    final status = process.exitCode.then((code) async {
      finished = true;
      await packages.dispose();
      return cancelled ? 130 : code;
    });
    return ProgramRunResult(
      title: 'Dart SDK: ${p.basename(entry)}',
      stdout: process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter()),
      stderr: process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter()),
      exitCode: status,
      cancel: () async {
        if (finished) return;
        cancelled = process.kill();
        try {
          await status.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          cancelled = process.kill(ProcessSignal.sigkill) || cancelled;
          await status;
        }
      },
    );
  }

  /// Runs the SDK with [arguments] inside [workingDirectory].
  ///
  /// Used by the terminal's `dart` hook so an interactive command such as
  /// `dart run src/main.dart`, `dart --version` or `dart analyze` reaches the
  /// official VM/CLI with the sandbox session's real working directory.
  /// [workingDirectory] is the containment root: the process must not silently
  /// start somewhere else, so a missing directory fails like the SDK does.
  ///
  /// Refuses the flag forms that would let a caller reload packages from
  /// another location, write a snapshot outside the project or open a network
  /// service. This is deliberately enforced here as well as in the terminal
  /// policy, so a future caller cannot silently bypass it.
  Future<ProgramRunResult> runCommand({
    required String workingDirectory,
    required List<String> arguments,
  }) async {
    final forbidden = _forbiddenFlag(arguments);
    if (forbidden != null) {
      throw ArgumentError.value(arguments, 'arguments', forbidden);
    }
    final sdk = await resolveExecutable();
    final root = p.normalize(p.absolute(workingDirectory));
    if (!await Directory(root).exists()) {
      throw FileSystemException('工作目录不存在', root);
    }
    final packages = await _packages(root);
    late final Process process;
    try {
      process = await Process.start(
        sdk,
        [
          '--disable-dart-dev',
          if (packages.path != null) '--packages=${packages.path}',
          ...arguments,
        ],
        workingDirectory: root,
        environment: Platform.isAndroid
            ? (await AndroidDartSdk.prepare()).environment
            : null,
      );
    } catch (_) {
      await packages.dispose();
      rethrow;
    }
    unawaited(_feedInput(process.stdin, File(p.join(root, 'input.txt'))));
    var finished = false;
    var cancelled = false;
    final status = process.exitCode.then((code) async {
      finished = true;
      await packages.dispose();
      return cancelled ? 130 : code;
    });
    return ProgramRunResult(
      title: 'dart ${arguments.join(' ')}'.trim(),
      stdout: process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter()),
      stderr: process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter()),
      exitCode: status,
      cancel: () async {
        if (finished) return;
        cancelled = process.kill();
        try {
          await status.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          cancelled = process.kill(ProcessSignal.sigkill) || cancelled;
          await status;
        }
      },
    );
  }

  Future<Uint8List> compileKernel({
    required String projectPath,
    required String entryFile,
  }) async {
    final sdk = await resolveExecutable();
    final entry = await _entry(projectPath, entryFile);
    final packages = await _packages(projectPath);
    final output = await Directory.systemTemp.createTemp('qfli-dart-kernel-');
    try {
      final artifact = File(p.join(output.path, 'program.dill'));
      final process = await Process.start(
        sdk,
        [
          if (Platform.isAndroid) ...[
            '--disable-dart-dev',
            '--snapshot-kind=kernel',
            '--snapshot=${artifact.path}',
          ] else ...[
            'compile',
            'kernel',
          ],
          if (packages.path != null) '--packages=${packages.path}',
          entry,
          if (!Platform.isAndroid) ...['-o', artifact.path],
        ],
        workingDirectory: p.absolute(projectPath),
        environment: Platform.isAndroid
            ? (await AndroidDartSdk.prepare()).environment
            : null,
      );
      unawaited(process.stdin.close());
      final stdout = process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .join();
      final stderr = process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .join();
      final int code;
      try {
        code = await process.exitCode.timeout(const Duration(minutes: 1));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
        rethrow;
      }
      final errors = await stderr;
      final messages = await stdout;
      if (code != 0) throw StateError(errors.isNotEmpty ? errors : messages);
      return await artifact.readAsBytes();
    } finally {
      await packages.dispose();
      await output.delete(recursive: true);
    }
  }

  static Future<void> _feedInput(IOSink sink, File file) async {
    try {
      if (await file.exists()) await sink.addStream(file.openRead());
    } on IOException {
      // The program can exit before it consumes the input.
    }
    try {
      await sink.close();
    } on IOException {
      // Cancellation closes the native pipe.
    }
  }

  static Future<String> _entry(String projectPath, String entryFile) async {
    final root = await Directory(projectPath).resolveSymbolicLinks();
    final entry = await File(entryFile).resolveSymbolicLinks();
    if (!p.isWithin(root, entry)) {
      throw ArgumentError.value(entryFile, 'entryFile', '入口文件不在项目目录内');
    }
    return entry;
  }

  /// A refusal reason when [arguments] contains a flag that would let the
  /// runtime leave the project or open a network service, or null when safe.
  static String? _forbiddenFlag(List<String> arguments) {
    const forbidden = <String>[
      '--packages',
      '--packages-file',
      '--snapshot',
      '--snapshot-kind',
      '--enable-vm-service',
      '--observe',
      '--disable-service-auth-codes',
    ];
    for (final argument in arguments) {
      for (final flag in forbidden) {
        if (argument == flag || argument.startsWith('$flag=')) {
          return 'refused runtime flag $flag';
        }
      }
    }
    return null;
  }

  static Future<_PackageConfiguration> _packages(String projectPath) async {
    final root = p.absolute(projectPath);
    final existing = File(p.join(root, '.dart_tool', 'package_config.json'));
    if (await existing.exists()) return _PackageConfiguration(existing.path);
    final manifest = File(p.join(root, 'pubspec.yaml'));
    if (!await manifest.exists()) return const _PackageConfiguration(null);
    final pubspec = Pubspec.parse(await manifest.readAsString());
    if (pubspec.dependencies.isNotEmpty || pubspec.devDependencies.isNotEmpty) {
      throw StateError('项目依赖尚未解析，请先通过 Dart SDK 获取依赖。');
    }
    // Self-package imports work offline without rewriting the user's manifest.
    final temporary = await Directory.systemTemp.createTemp(
      'qfli-dart-packages-',
    );
    final config = File(p.join(temporary.path, 'package_config.json'));
    try {
      await config.writeAsString(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': pubspec.name,
              'rootUri': Directory(root).uri.toString(),
              'packageUri': 'lib/',
            },
          ],
        }),
      );
      return _PackageConfiguration(config.path, temporary);
    } catch (_) {
      await temporary.delete(recursive: true);
      rethrow;
    }
  }
}

class _PackageConfiguration {
  const _PackageConfiguration(this.path, [this.temporary]);

  final String? path;
  final Directory? temporary;

  Future<void> dispose() async {
    if (temporary != null) await temporary!.delete(recursive: true);
  }
}
