import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';

class DartProgramRunner implements ProgramRunner {
  const DartProgramRunner();

  @override
  Future<ProgramRunResult?> run({
    required String projectPath,
    required String entryFile,
  }) async {
    if (p.extension(entryFile).toLowerCase() != '.dart') return null;

    final root = p.normalize(p.absolute(projectPath));
    final entry = p.normalize(p.absolute(entryFile));
    if (!p.isWithin(root, entry)) {
      return _failed('运行 ${p.basename(entry)}', '入口文件不在项目目录内。');
    }

    try {
      final sources = await _readSources(root);
      final relativeEntry = _sourcePath(root, entry);
      if (!sources.containsKey(relativeEntry)) {
        return _failed('运行 ${p.basename(entry)}', '找不到入口文件：$relativeEntry');
      }

      final packageName = await _packageName(root);
      final librarySources = <String, String>{};
      for (final source in sources.entries) {
        if (source.key.startsWith('lib/')) {
          librarySources[source.key.substring(4)] = source.value;
        }
      }
      final workspaceName = '${packageName}_workspace';
      final entryUri = relativeEntry.startsWith('lib/')
          ? 'package:$packageName/${relativeEntry.substring(4)}'
          : 'package:$workspaceName/$relativeEntry';
      return _start(
        title: '运行 ${p.basename(entry)}',
        packages: {packageName: librarySources, workspaceName: sources},
        entryUri: entryUri,
      );
    } on FileSystemException catch (error) {
      return _failed('运行 ${p.basename(entry)}', error.message);
    } on FormatException catch (error) {
      return _failed('运行 ${p.basename(entry)}', error.message);
    }
  }

  static String _sourcePath(String root, String file) =>
      p.relative(file, from: root).replaceAll('\\', '/');

  static Future<Map<String, String>> _readSources(String root) async {
    final sources = <String, String>{};

    Future<void> visit(Directory directory) async {
      await for (final entity in directory.list(followLinks: false)) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') || name == 'build') continue;
        if (entity is Directory) {
          await visit(entity);
        } else if (entity is File &&
            p.extension(name).toLowerCase() == '.dart') {
          sources[_sourcePath(root, entity.path)] = await entity.readAsString();
        }
      }
    }

    await visit(Directory(root));
    return sources;
  }

  static Future<String> _packageName(String root) async {
    final pubspec = File(p.join(root, 'pubspec.yaml'));
    if (!await pubspec.exists()) return 'qfli_project';
    return Pubspec.parse(await pubspec.readAsString()).name;
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
