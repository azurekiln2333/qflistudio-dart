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
import 'native_dart_toolchain.dart';

/// Offline policy for the terminal's `dart` hook.
///
/// The Dart app is an offline product: the embedded terminal must never reach
/// the network or act outside the sandbox project. The official CLI exposes
/// both (`dart pub get` downloads packages; `--packages=`, `--snapshot=` and
/// `--enable-vm-service` let a caller redirect loading or open a listener), so
/// the hook only claims an explicit allowlist of local subcommands and rejects
/// the flag forms that would redefine them.
///
/// Pure so it can be unit-tested without spawning a process or a backend.
abstract final class DartTerminalPolicy {
  /// Subcommands the offline terminal may run. Everything else is refused,
  /// including all of `dart pub` (package management is a network feature),
  /// `dart create`/`dart test` (may resolve dependencies) and any future
  /// command this app has not vetted.
  static const Set<String> allowedSubcommands = <String>{
    'run',
    'compile',
    'format',
    'analyze',
    'fix',
    'help',
  };

  /// Top-level `dart` options the offline hook still permits. They only print
  /// local information; everything else starting with `-` is refused so a VM
  /// flag cannot redefine package loading, write outside the project or open a
  /// network service (e.g. `--packages=`, `--snapshot=`, `--enable-vm-service`).
  static const Set<String> allowedTopLevelOptions = <String>{
    '--version',
    '-v',
    '--help',
    '-h',
    '--disable-analytics',
  };

  /// The subcommand token for [arguments], or null when the line is refused.
  ///
  /// A leading allowed option (e.g. `dart --version`) is recognised before the
  /// subcommand check, so `dart --version` passes while `dart --snapshot=x run`
  /// does not. A bare `.dart`/`.dill` operand (the `dart <script>` shorthand)
  /// is reported as `run`, because that is what the VM does with it.
  static String? subcommand(List<String> arguments) {
    if (arguments.isEmpty) return null;
    final first = arguments.first;
    if (!first.startsWith('-')) {
      if (allowedSubcommands.contains(first)) return first;
      return _scriptOperand(first) ? 'run' : null;
    }
    return allowedTopLevelOptions.contains(first) ? first : null;
  }

  /// A human-readable refusal reason for [arguments], or null when allowed.
  static String? reject(List<String> arguments) {
    if (arguments.isEmpty) {
      return '请在命令中给出子命令（例如 dart run src/main.dart）。';
    }
    final first = arguments.first;
    if (first.startsWith('-')) {
      if (allowedTopLevelOptions.contains(first)) return null;
      return '离线版终端不接受 VM 参数 $first；只允许 dart run/compile/format/analyze/fix/--version。';
    }
    if (first == 'pub' || first == 'global') {
      return '离线版终端禁用 dart $first：包管理与发布需要网络。';
    }
    // `dart <script.dart>` is the VM's run shorthand; keep it available so the
    // terminal behaves like the CLI for the most common local command.
    if (!allowedSubcommands.contains(first) && !_scriptOperand(first)) {
      return '离线版终端不支持 dart $first；只允许 dart run/compile/format/analyze/fix/--version。';
    }
    // `dart run/compile ...` must not let the VM reload packages from another
    // location or write a snapshot outside the sandbox, so refuse any embedded
    // `--packages=`/`--snapshot=`/observatory flag in the remaining operands.
    for (final argument in arguments.skip(1)) {
      final forbidden = _forbiddenFlag(argument);
      if (forbidden != null) return forbidden;
    }
    return null;
  }

  static bool _scriptOperand(String token) {
    final lower = token.toLowerCase();
    return lower.endsWith('.dart') || lower.endsWith('.dill');
  }

  static String? _forbiddenFlag(String argument) {
    if (!argument.startsWith('-')) return null;
    const forbidden = <String>[
      '--packages',
      '--packages-file',
      '--snapshot',
      '--snapshot-kind',
      '--enable-vm-service',
      '--observe',
      '--disable-service-auth-codes',
      '--enable-asserts',
    ];
    for (final flag in forbidden) {
      if (argument == flag || argument.startsWith('$flag=')) {
        return '离线版终端禁用 $flag：它会让运行时越过项目或打开网络服务。';
      }
    }
    return null;
  }
}

/// Terminal hook for the Dart toolchain.
///
/// Claims a plain `dart <...>` line and routes it through the official SDK in
/// the terminal session's real working directory, streaming stdout, stderr and
/// the native exit status back into the sandbox. Returns false for anything
/// else so the sandbox reports its own honest message.
///
/// The sandbox always classifies with a literal backslash (Windows path
/// separator), so tokenize the same way; a `C:\dir` operand must not be
/// mangled. Compound lines (pipes/redirection/chaining/globs) are deliberately
/// **not** claimed: the sandbox cannot evaluate them, so they must fall through
/// to the sandbox's construct message instead of being misread as arguments.
///
/// On platforms without the native toolchain (portable dart_eval targets) the
/// hook reports the platform limitation instead of silently doing nothing.
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
  final refusal = DartTerminalPolicy.reject(arguments);
  if (refusal != null) {
    backend.error('dart: $refusal');
    return true;
  }
  if (!NativeDartToolchain.supported) {
    backend.error('dart: 当前平台没有官方 Dart SDK，无法执行该命令（便携运行时只支持编辑器运行按钮）。');
    return true;
  }
  // Reject a path operand that would leave the sandbox before spawning, so a
  // `dart run /somewhere/else/main.dart` cannot read a project the session is
  // not confined to.
  if (!_withinSandbox(backend, arguments)) {
    return true;
  }
  final ProgramRunResult run;
  try {
    run = await const NativeDartToolchain().runCommand(
      workingDirectory: backend.cwd,
      arguments: arguments,
    );
  } on StateError catch (error) {
    backend.error('dart: ${error.message}');
    return true;
  } on ArgumentError catch (error) {
    backend.error('dart: ${error.message}');
    return true;
  } on FileSystemException catch (error) {
    backend.error('dart: ${error.message}');
    return true;
  } on ProcessException catch (error) {
    backend.error('dart: ${error.message}');
    return true;
  }
  await backend.runStreams(
    title: run.title,
    stdout: run.stdout,
    stderr: run.stderr,
    exitCode: run.exitCode,
    cancel: run.cancel,
  );
  return true;
}

/// True when every path-looking operand stays inside the sandbox root.
///
/// Flags are skipped (the policy already vetted their names) and so are plain
/// words that are not files; only `dart:...` URIs and actual escapes are
/// refused. Emits the reason itself when it refuses.
bool _withinSandbox(SandboxShellBackend backend, List<String> arguments) {
  for (final argument in arguments.skip(1)) {
    if (argument.startsWith('-')) continue;
    if (argument.contains('://')) continue;
    if (!argument.contains('/') &&
        !argument.contains(r'\') &&
        !argument.endsWith('.dart') &&
        !argument.endsWith('.dill')) {
      continue;
    }
    try {
      backend.resolveSandboxPath(argument);
    } on SandboxEscapeException {
      backend.error('dart: 不能越出沙盒目录: $argument');
      return false;
    }
  }
  return true;
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
