import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/terminal/shell/command_parser.dart';
import 'package:qfli_studio_core/terminal/shell/sandbox_shell_backend.dart';

import 'dart_project_sources.dart';
import 'dart_tools.dart';
import 'native_dart_toolchain.dart';

/// Terminal hook for the Dart toolchain.
///
/// Routes a plain `dart` line onto the same already-verified code paths the
/// editor Run button uses, in the terminal session's working directory. The
/// raw VM (`dartvm`) cannot accept CLI subcommands (`dartvm run x.dart` treats
/// `run` as a script name), so no subcommand is ever handed to the VM directly:
///
/// - `dart run <file.dart>` / `dart <file.dart>` -> [DartProgramRunner.run]
///   (native VM on desktop/Android with packages + input; portable `dart_eval`
///   on OHOS/iOS/web).
/// - `dart run <file.dill>` -> the same runner's native compiled-program path.
/// - `dart compile kernel <file.dart>` -> [NativeDartToolchain.compileKernel],
///   saving the artifact beside the source and pointing at `dart run`.
/// - `dart format <file>` -> [DartTools.format], written in place.
/// - `dart analyze` -> [DartTools.syntaxDiagnostics] (scanner/parser level).
/// - `dart --version` -> the real SDK version.
///
/// `dart pub`/`dart global` are refused (an offline product has no network).
/// Flags other than the ones parsed here are not forwarded, so no VM flag can
/// reload packages elsewhere or open a port. Returns false for anything that is
/// not a `dart` line so the sandbox keeps its own honest message.
Future<bool> dartTerminalDelegate(
  SandboxShellBackend backend,
  String command,
) async {
  const policy = EscapePolicy.backslashLiteral;
  if (CommandParser.classify(command, escapePolicy: policy) !=
      CommandSyntax.simple) {
    return false;
  }
  final parsed = CommandParser.tokenize(command, escapePolicy: policy);
  if (!parsed.ok || parsed.tokens.isEmpty) return false;
  final tokens = parsed.tokens.map((token) => token.text).toList();
  if (tokens.first != 'dart') return false;
  final arguments = tokens.sublist(1);
  if (arguments.isEmpty) {
    backend.error('dart: 请在命令中给出子命令（例如 dart run src/main.dart）。');
    return true;
  }

  final verb = arguments.first;
  if (verb == 'pub' || verb == 'global') {
    backend.error('dart: 离线版终端禁用 dart $verb（包管理与发布需要网络）。');
    return true;
  }
  if (verb == '--version' || verb == '-v') {
    await _runVersion(backend);
    return true;
  }
  if (verb == '--help' || verb == '-h' || verb == 'help') {
    backend.line(dartTerminalHelp);
    return true;
  }
  if (verb == 'run' || _isScript(verb)) {
    await _runScript(backend, arguments, shorthand: verb != 'run');
    return true;
  }
  if (verb == 'compile') {
    await _runCompile(backend, arguments.skip(1).toList());
    return true;
  }
  if (verb == 'format') {
    await _runFormat(backend, arguments.skip(1).toList());
    return true;
  }
  if (verb == 'analyze') {
    await _runAnalyze(backend, arguments.skip(1).toList());
    return true;
  }
  backend.error(
    'dart: 离线版终端不支持 dart $verb；支持 run/compile/format/analyze/--version。',
  );
  return true;
}

/// Help text listing exactly what the terminal hook implements.
const String dartTerminalHelp =
    'dart（本地 SDK，离线）\n'
    '  dart run <文件.dart>            运行源文件（与编辑器运行按钮相同）\n'
    '  dart <文件.dart>               运行源文件的简写\n'
    '  dart run <文件.dill>           运行已编译的 Kernel 产物\n'
    '  dart compile kernel <文件.dart>  编译为 build/<入口>.dill\n'
    '  dart format <文件>             就地格式化\n'
    '  dart analyze                   语法检查（扫描/解析级，非语义分析）\n'
    '  dart --version                 显示 SDK 版本\n'
    'dart pub / dart global 等联网命令在离线版被禁用。';

bool _isScript(String token) {
  final lower = token.toLowerCase();
  return lower.endsWith('.dart') || lower.endsWith('.dill');
}

/// The single non-flag operand of a `run`/shorthand line, or a message.
///
/// Returns the path when exactly one file operand is present; otherwise reports
/// the usage error and returns null.
Future<String?> _singleFileOperand(
  SandboxShellBackend backend,
  List<String> operands,
  String usage,
) async {
  if (operands.length != 1) {
    backend.error('dart: 用法：$usage');
    return null;
  }
  final operand = operands.single;
  if (operand.startsWith('-')) {
    backend.error('dart: 离线版终端不接受参数 $operand。');
    return null;
  }
  return backend.resolveSandboxPath(operand);
}

Future<void> _runScript(
  SandboxShellBackend backend,
  List<String> arguments, {
  required bool shorthand,
}) async {
  final operands = shorthand ? arguments : arguments.skip(1).toList();
  final String path;
  try {
    final resolved = await _singleFileOperand(
      backend,
      operands,
      'dart ${shorthand ? '<文件.dart>' : 'run <文件.dart>'}',
    );
    if (resolved == null) return;
    path = resolved;
  } on SandboxEscapeException {
    backend.error('dart: 不能越出沙盒目录：${operands.single}');
    return;
  }
  if (!await File(path).exists()) {
    backend.error('dart: 文件不存在：${operands.single}');
    return;
  }
  await _stream(
    backend,
    () => const DartProgramRunner().run(
      projectPath: backend.cwd,
      entryFile: path,
    ),
    fallbackMessage: 'dart: 无法运行 ${operands.single}（该文件类型不受支持）。',
  );
}

Future<void> _runCompile(
  SandboxShellBackend backend,
  List<String> arguments,
) async {
  if (arguments.isEmpty || arguments.first != 'kernel') {
    // `dart compile exe/js/wasm` are not available offline (native target or
    // downloads); keep the honest message instead of a partial implementation.
    backend.error('dart: 离线版终端只支持 dart compile kernel <文件.dart>。');
    return;
  }
  if (!NativeDartToolchain.supported) {
    backend.error('dart: 当前平台没有官方 Dart SDK，无法编译 Kernel（便携运行时只支持直接运行）。');
    return;
  }
  final operands = arguments.skip(1).toList();
  final String path;
  try {
    final resolved = await _singleFileOperand(
      backend,
      operands,
      'dart compile kernel <文件.dart>',
    );
    if (resolved == null) return;
    path = resolved;
  } on SandboxEscapeException {
    backend.error('dart: 不能越出沙盒目录：${operands.single}');
    return;
  }
  final relative = p.relative(path, from: backend.cwd);
  final artifact = File(
    p.join(backend.cwd, 'build', '${p.withoutExtension(relative)}.dill'),
  );
  backend.line(
    '编译 $relative -> ${p.relative(artifact.path, from: backend.cwd)}',
  );
  try {
    final bytes = await const NativeDartToolchain().compileKernel(
      projectPath: backend.cwd,
      entryFile: path,
    );
    await artifact.parent.create(recursive: true);
    await artifact.writeAsBytes(bytes, flush: true);
    backend.line(
      '已生成 ${p.relative(artifact.path, from: backend.cwd)}；用 dart run 运行该 .dill。',
    );
  } on StateError catch (error) {
    backend.error('dart: 编译失败：${error.message}');
  } on FileSystemException catch (error) {
    backend.error('dart: 编译失败：${error.message}');
  }
}

Future<void> _runFormat(
  SandboxShellBackend backend,
  List<String> arguments,
) async {
  if (arguments.isEmpty) {
    backend.error('dart: 用法：dart format <文件.dart>');
    return;
  }
  for (final operand in arguments) {
    if (operand.startsWith('-')) {
      backend.error('dart: 离线版终端不接受参数 $operand。');
      return;
    }
    final String path;
    try {
      path = backend.resolveSandboxPath(operand);
    } on SandboxEscapeException {
      backend.error('dart: 不能越出沙盒目录：$operand');
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      backend.error('dart: 文件不存在：$operand');
      return;
    }
    try {
      final formatted = DartTools.format(await file.readAsString());
      await file.writeAsString(formatted, flush: true);
      backend.line('已格式化 $operand');
    } on Object catch (error) {
      backend.error('dart: 格式化失败：$error');
      return;
    }
  }
}

Future<void> _runAnalyze(
  SandboxShellBackend backend,
  List<String> arguments,
) async {
  final targets = arguments.isEmpty ? <String>[backend.cwd] : arguments;
  for (final target in targets) {
    if (target.startsWith('-')) {
      backend.error('dart: 离线版终端不接受参数 $target。');
      return;
    }
    final String path;
    try {
      path = backend.resolveSandboxPath(target);
    } on SandboxEscapeException {
      backend.error('dart: 不能越出沙盒目录：$target');
      return;
    }
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.notFound) {
      backend.error('dart: 路径不存在：$target');
      return;
    }
    final files = entity == FileSystemEntityType.directory
        ? _dartFilesUnder(Directory(path))
        : <String>[path];
    var issues = 0;
    for (final file in files) {
      final diagnostics = DartTools.syntaxDiagnostics(
        await File(file).readAsString(),
      );
      for (final diagnostic in diagnostics) {
        issues++;
        backend.error(
          '${p.relative(file, from: backend.cwd)}:${diagnostic.line}:${diagnostic.column}: '
          '${diagnostic.message} (${diagnostic.code})',
        );
      }
    }
    backend.line(
      issues == 0
          ? '${p.relative(path, from: backend.cwd)}: 没有语法错误（语法检查）'
          : '语法检查完成：$issues 个问题（扫描/解析级，未做语义与依赖分析）',
    );
  }
}

List<String> _dartFilesUnder(Directory directory) {
  final result = <String>[];
  for (final entity in directory.listSync(followLinks: false)) {
    final name = p.basename(entity.path);
    if (name.startsWith('.') || name == 'build') continue;
    if (entity is Directory) {
      result.addAll(_dartFilesUnder(entity));
    } else if (entity is File && p.extension(name).toLowerCase() == '.dart') {
      result.add(entity.path);
    }
  }
  return result;
}

Future<void> _runVersion(SandboxShellBackend backend) async {
  try {
    final version = await const NativeDartToolchain().version();
    backend.line(version);
  } on Object catch (error) {
    backend.error('dart: 无法获取 SDK 版本：$error');
  }
}

/// Streams a runner result into the backend, or reports [fallbackMessage] when
/// the runner declined the file (returned null).
Future<void> _stream(
  SandboxShellBackend backend,
  Future<ProgramRunResult?> Function() run, {
  required String fallbackMessage,
}) async {
  try {
    final result = await run();
    if (result == null) {
      backend.error(fallbackMessage);
      return;
    }
    await backend.runStreams(
      title: result.title,
      stdout: result.stdout,
      stderr: result.stderr,
      exitCode: result.exitCode,
      cancel: result.cancel,
    );
  } on Object catch (error) {
    backend.error('dart: $error');
  }
}

class DartProgramRunner implements ProgramRunner {
  const DartProgramRunner();

  @override
  Future<ProgramRunResult?> run({
    required String projectPath,
    required String entryFile,
  }) async {
    final extension = p.extension(entryFile).toLowerCase();
    if (extension != '.dart' &&
        !(extension == '.dill' && NativeDartToolchain.supported)) {
      return null;
    }

    try {
      if (NativeDartToolchain.supported) {
        return await const NativeDartToolchain().run(
          projectPath: projectPath,
          entryFile: entryFile,
        );
      }
      final project = await DartProjectSources.load(
        projectPath: projectPath,
        entryFile: entryFile,
      );
      return _start(
        title: '运行 ${p.basename(entryFile)}',
        packages: project.packages,
        entryUri: project.entryUri,
      );
    } on ArgumentError catch (error) {
      return _failed('运行 ${p.basename(entryFile)}', error.message.toString());
    } on FileSystemException catch (error) {
      return _failed('运行 ${p.basename(entryFile)}', error.message);
    } on FormatException catch (error) {
      return _failed('运行 ${p.basename(entryFile)}', error.toString());
    } on ProcessException catch (error) {
      return _failed('运行 ${p.basename(entryFile)}', error.message);
    } on StateError catch (error) {
      return _failed('运行 ${p.basename(entryFile)}', error.message);
    } on PlatformException catch (error) {
      return _failed(
        '运行 ${p.basename(entryFile)}',
        error.message ?? error.code,
      );
    }
  }

  static ProgramRunResult _failed(String title, String message) =>
      ProgramRunResult(
        title: title,
        stdout: const Stream<String>.empty(),
        stderr: Stream<String>.value(message),
        exitCode: Future<int>.value(kProgramNotRunExitCode),
      );

  static Future<ProgramRunResult> _start({
    required String title,
    required Map<String, Map<String, String>> packages,
    required String entryUri,
  }) async {
    final output = StreamController<String>();
    final errors = StreamController<String>();
    final exitCode = Completer<int>();
    final messages = ReceivePort();
    Isolate? worker;

    void finish(int code) {
      if (exitCode.isCompleted) return;
      exitCode.complete(code);
      messages.close();
      unawaited(output.close());
      unawaited(errors.close());
    }

    messages.listen((message) {
      if (message is Map) {
        if (message['type'] == 'stdout') {
          output.add(message['value'] as String);
        } else if (message['type'] == 'stderr') {
          errors.add(message['value'] as String);
        } else if (message['type'] == 'done') {
          finish(message['value'] as int);
        }
      } else if (message is List && message.isNotEmpty) {
        errors.add(message.first.toString());
        finish(kProgramNotRunExitCode);
      } else if (message == null) {
        finish(kProgramNotRunExitCode);
      }
    });

    try {
      worker = await Isolate.spawn(
        _execute,
        [messages.sendPort, packages, entryUri],
        onError: messages.sendPort,
        onExit: messages.sendPort,
      );
    } on Object catch (error) {
      errors.add('无法启动 Dart 运行时：$error');
      finish(kProgramNotRunExitCode);
    }

    return ProgramRunResult(
      title: title,
      stdout: output.stream,
      stderr: errors.stream,
      exitCode: exitCode.future,
      cancel: () async {
        worker?.kill(priority: Isolate.immediate);
        finish(130);
      },
    );
  }

  static Future<void> _execute(List<Object> args) async {
    final port = args[0] as SendPort;
    final packages = (args[1] as Map).cast<String, Map<String, String>>();
    final entryUri = args[2] as String;

    await runZoned(
      () async {
        late final Program program;
        try {
          final compiler = Compiler()..entrypoints.add(entryUri);
          program = compiler.compile(packages);
        } on Object catch (error) {
          port.send({'type': 'stderr', 'value': error.toString()});
          port.send({'type': 'done', 'value': kProgramNotRunExitCode});
          return;
        }

        try {
          final runtime = Runtime.ofProgram(program);
          final uriSegments = Uri.parse(entryUri).pathSegments;
          final source =
              packages[uriSegments.first]![uriSegments.skip(1).join('/')]!;
          final args = _mainAcceptsArguments(source) ? [<String>[]] : null;
          await Future<dynamic>.value(
            runtime.executeLib(entryUri, 'main', args),
          );
          port.send({'type': 'done', 'value': 0});
        } on Object catch (error) {
          port.send({'type': 'stderr', 'value': error.toString()});
          port.send({'type': 'done', 'value': 1});
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          port.send({'type': 'stdout', 'value': line});
        },
      ),
    );
  }

  static bool _mainAcceptsArguments(String source) {
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;
    for (final declaration in unit.declarations) {
      if (declaration is FunctionDeclaration &&
          declaration.name.lexeme == 'main') {
        return declaration
                .functionExpression
                .parameters
                ?.parameters
                .isNotEmpty ??
            false;
      }
    }
    return false;
  }
}
