@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_project_sources.dart';
import 'package:qfli_dart/portable_dart_runtime.dart';

void main() {
  late Directory project;

  setUp(() {
    project = Directory.systemTemp.createTempSync('qfli_portable_test_');
  });

  tearDown(() {
    if (project.existsSync()) project.deleteSync(recursive: true);
  });

  Future<PortableDartRun> start(String source) => startPortableDart(
    packages: {
      'test': {'main.dart': source},
    },
    entryUri: 'package:test/main.dart',
    projectPath: project.path,
  );

  Future<({List<String> output, List<String> errors, int code})> collect(
    PortableDartRun run,
  ) async {
    final output = run.stdout.toList();
    final errors = run.stderr.toList();
    try {
      final code = await run.exitCode.timeout(const Duration(seconds: 10));
      return (output: await output, errors: await errors, code: code);
    } finally {
      await run.cancel();
    }
  }

  test(
    'project loader retains relative and self-package imports and main args',
    () async {
      File(
        p.join(project.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: demo\n');
      Directory(p.join(project.path, 'lib')).createSync();
      Directory(p.join(project.path, 'src')).createSync();
      File(
        p.join(project.path, 'lib', 'value.dart'),
      ).writeAsStringSync('int value() => 40;');
      File(
        p.join(project.path, 'src', 'helper.dart'),
      ).writeAsStringSync('int extra() => 2;');
      final entry = File(p.join(project.path, 'src', 'main.dart'))
        ..writeAsStringSync('''
import 'helper.dart';
import 'package:demo/value.dart';
Future<void> main(List<String> args) async {
  await Future<void>.delayed(Duration(milliseconds: 1));
  print(value() + extra());
  print(args.length);
}
''');
      final sources = await DartProjectSources.load(
        projectPath: project.path,
        entryFile: entry.path,
      );
      final result = await collect(
        await startPortableDart(
          packages: sources.packages,
          entryUri: sources.entryUri,
          projectPath: project.path,
        ),
      );
      expect(result.output, ['42', '0']);
      expect(result.errors, isEmpty);
      expect(result.code, 0);
    },
  );

  test('parser and runtime errors cannot become a clean run', () async {
    for (final (source, expectedCode) in [
      ('void main( {', 127),
      ("import 'missing.dart'; void main() {}", 127),
      ("void main() { throw StateError('actual-error'); }", 1),
    ]) {
      final result = await collect(await start(source));
      expect(result.code, expectedCode);
      expect(result.errors, isNotEmpty);
    }
  });

  test(
    'real temp IO and captured stdout chunks survive a run-owned close',
    () async {
      final cwd = Directory.current.path;
      final result = await collect(
        await start('''
import 'dart:io';
void main() {
  final dir = Directory.systemTemp.createTempSync('lesson_');
  try {
    final file = File('\${dir.path}/actual.txt');
    file.writeAsStringSync('真实文件');
    stdout.write(file.readAsStringSync());
    stdout.write('\\r\\n');
    stdout.write('tail');
    stdout.close();
  } finally {
    dir.deleteSync(recursive: true);
  }
}
'''),
      );
      expect(result.output, ['真实文件', 'tail']);
      expect(result.errors, isEmpty);
      expect(result.code, 0);
      expect(Directory.current.path, cwd);
      expect(
        (await collect(
          await start("void main() { print('next-run'); }"),
        )).output,
        ['next-run'],
      );
    },
  );

  test(
    'project writes work but source imports only see preloaded files',
    () async {
      final target = p.join(project.path, 'saved.txt');
      final result = await collect(
        await start('''
import 'dart:io';
void main() {
  final file = File(${jsonEncode(target)});
  file.writeAsStringSync('stored-by-program');
  print(file.readAsStringSync());
}
'''),
      );
      expect(result.output, ['stored-by-program']);
      expect(result.code, 0);
      expect(File(target).readAsStringSync(), 'stored-by-program');

      final external = File(p.join(project.path, 'not_preloaded.dart'))
        ..writeAsStringSync('int secret() => 9;');
      final imported = await collect(
        await start(
          "import '${external.uri}'; void main() { print(secret()); }",
        ),
      );
      expect(imported.code, isNonZero);
      expect(imported.output, isEmpty);
      expect(imported.errors, isNotEmpty);
    },
  );

  test('native network, process, stdin and global cwd mutation are denied', () async {
    final cwd = Directory.current.path;
    final programs = [
      "import 'dart:io'; Future<void> main() async { await HttpClient().getUrl(Uri.parse('http://127.0.0.1:9')); }",
      "import 'dart:io'; Future<void> main() async { await Process.run(${jsonEncode(Platform.resolvedExecutable)}, ['--version']); }",
      "import 'dart:io'; void main() { stdin.readLineSync(); }",
      "import 'dart:io'; void main() { Directory.current = ${jsonEncode(project.path)}; }",
    ];
    for (final source in programs) {
      final result = await collect(await start(source));
      expect(result.code, isNonZero, reason: source);
      expect(
        result.errors.join('\n'),
        matches(
          RegExp(
            'denied|unsupported|disabled|unavailable|requires.*Permission',
            caseSensitive: false,
          ),
        ),
        reason: source,
      );
    }
    expect(Directory.current.path, cwd);
  });

  test('spawnUri cannot execute a native source file', () async {
    final marker = File(p.join(project.path, 'native-executed.txt'));
    final native = File(p.join(project.path, 'native.dart'))
      ..writeAsStringSync('''
import 'dart:io';
void main() { File(${jsonEncode(marker.path)}).writeAsStringSync('escaped'); }
''');
    final result = await collect(
      await start('''
import 'dart:isolate';
Future<void> main() async { await Isolate.spawnUri(Uri.parse(${jsonEncode(native.uri.toString())}), [], null); }
'''),
    );
    expect(result.code, isNonZero);
    expect(result.errors.join('\n'), contains('spawnUri'));
    expect(marker.existsSync(), isFalse);
  });

  test(
    'native isolate resets globals while preserving actual lexical capture',
    () async {
      final result = await collect(
        await start('''
import 'dart:isolate';
int global = 4;
Future<void> main() async {
  global = 100;
  final local = 7;
  print(await Isolate.run(() => global + local));
  print(global);
}
'''),
      );
      expect(result.output, ['11', '100']);
      expect(result.errors, isEmpty);
      expect(result.code, 0);
    },
  );

  test(
    'unawaited timers and native children finish before a successful result',
    () async {
      final result = await collect(
        await start('''
import 'dart:async';
import 'dart:isolate';
Future<void> child(Object? message) async {
  await Future<void>.delayed(Duration(milliseconds: 20));
  print('child-finished');
}
Future<void> main() async {
  await Isolate.spawn(child, null);
  Timer(Duration(milliseconds: 10), () => print('timer-finished'));
}
'''),
      );
      expect(result.output, containsAll(['timer-finished', 'child-finished']));
      expect(result.errors, isEmpty);
      expect(result.code, 0);
    },
  );

  test(
    'isolate reconstruction retains root and imported library URIs',
    () async {
      final run = await startPortableDart(
        packages: {
          'demo': {
            'main.dart': '''
import 'dart:isolate';
import 'values.dart';
Future<void> main() async {
  print(await Isolate.run(() => importedValue() + 1));
  print(await isolatedValue());
}
''',
            'values.dart': '''
import 'dart:isolate';
int value = 20;
int importedValue() => value;
Future<Object?> isolatedValue() async {
  value = 200;
  return await Isolate.run(() => value + 2);
}
''',
          },
        },
        entryUri: 'package:demo/main.dart',
        projectPath: project.path,
      );
      final result = await collect(run);
      expect(result.output, ['21', '22']);
      expect(result.errors, isEmpty);
      expect(result.code, 0);
    },
  );

  test(
    'late child print, stdout and stderr drain before product streams close',
    () async {
      for (var iteration = 0; iteration < 20; iteration++) {
        final result = await collect(
          await start('''
import 'dart:io';
import 'dart:isolate';
Future<void> child(Object? message) async {
  await Future<void>.delayed(Duration(milliseconds: 1));
  print('late-print');
  stdout.write('late-stdout');
  stderr.write('late-stderr');
}
Future<void> main() async { await Isolate.spawn(child, null); }
'''),
        );
        expect(result.output, [
          'late-print',
          'late-stdout',
        ], reason: 'iteration $iteration');
        expect(result.errors, ['late-stderr'], reason: 'iteration $iteration');
        expect(result.code, 0);
      }
    },
  );

  test(
    'uncaught spawn errors fail the run while an explicit error port handles them',
    () async {
      final uncaught = await collect(
        await start('''
import 'dart:isolate';
void child(Object? message) { throw StateError('actual-child-error'); }
Future<void> main() async { await Isolate.spawn(child, null); }
'''),
      );
      expect(uncaught.code, isNonZero);
      expect(uncaught.errors.join('\n'), contains('actual-child-error'));
      final handled = await collect(
        await start('''
import 'dart:isolate';
void child(Object? message) { throw StateError('handled-child-error'); }
Future<void> main() async {
  final errors = ReceivePort();
  await Isolate.spawn(child, null, onError: errors.sendPort);
  final error = await errors.first;
  print(error[0].toString().contains('handled-child-error'));
  errors.close();
}
'''),
      );
      expect(handled.code, 0);
      expect(handled.output, ['true']);
      expect(handled.errors, isEmpty);
    },
  );

  test(
    'indexed updates preserve values, side effects and native write errors',
    () async {
      final result = await collect(
        await start('''
void main() {
  final values = List<int>.filled(3, 0);
  var targets = 0;
  var indices = 0;
  List<int> target() { targets++; return values; }
  int index() { indices++; return 1; }
  print(target()[index()]++);
  print(++target()[index()]);
  print(target()[index()]--);
  print(--target()[index()]);
  print(values);
  print([targets, indices]);
  final dynamic map = Map<String, int>.from({'x': 4});
  print(map['x']++);
  print(++map['x']);
  print(map['x']);
  try {
    final frozen = List<int>.unmodifiable([3]);
    frozen[0]++;
  } on UnsupportedError { print('immutable'); }
  try { values[9]++; } on RangeError { print('bounds'); }
}
'''),
      );
      expect(result.code, 0);
      expect(result.errors, isEmpty);
      expect(result.output, [
        '0',
        '2',
        '2',
        '0',
        '[0, 0, 0]',
        '[4, 4]',
        '4',
        '6',
        '6',
        'immutable',
        'bounds',
      ]);
    },
  );

  test('Stop interrupts a synchronous loop and is idempotent', () async {
    final run = await start('void main() { while (true) {} }');
    final output = run.stdout.toList();
    final errors = run.stderr.toList();
    await run.cancel().timeout(const Duration(seconds: 5));
    await run.cancel();
    expect(await run.exitCode, 130);
    expect(await output, isEmpty);
    expect(await errors, isEmpty);
  });

  test('Stop reclaims busy nested native isolates before returning', () async {
    final heartbeat = File(p.join(project.path, 'heartbeat.txt'));
    final run = await start('''
import 'dart:io';
import 'dart:isolate';
Future<void> main() async {
  await Isolate.run(() async {
    await Isolate.run(() {
      final file = File(${jsonEncode(heartbeat.path)});
      var count = 0;
      while (true) { file.writeAsStringSync('\${count++}'); }
    });
  });
}
''');
    final output = run.stdout.toList();
    final errors = run.stderr.toList();
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!heartbeat.existsSync() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        heartbeat.existsSync(),
        isTrue,
        reason: 'real nested worker never started',
      );
      await run.cancel().timeout(const Duration(seconds: 5));
      final stopped = heartbeat.readAsStringSync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(heartbeat.readAsStringSync(), stopped);
      expect(await run.exitCode, 130);
      expect(await errors, isEmpty);
      await output;
    } finally {
      await run.cancel();
    }
  });
}
