import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_studio_core/services/studio_profile.dart';

import 'dart_project_sources.dart';

class DartProgramRunner implements ProgramRunner {
  const DartProgramRunner();

  @override
  Future<ProgramRunResult?> run({
    required String projectPath,
    required String entryFile,
  }) async {
    if (p.extension(entryFile).toLowerCase() != '.dart') return null;

    try {
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
