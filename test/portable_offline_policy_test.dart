@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/src/stdlib/io/file.dart';
import 'package:tom_d4rt/src/stdlib/io/file_system_entity.dart';
import 'package:tom_d4rt/src/stdlib/io/process.dart';
import 'package:tom_d4rt/src/stdlib/io/socket.dart';

const _timeout = Duration(seconds: 10);

InterpreterVisitor _visitor(D4rt runtime) {
  final environment = Environment();
  return InterpreterVisitor(
    globalEnvironment: environment,
    moduleLoader: ModuleLoader(environment, {}, {}, {}, d4rt: runtime),
  );
}

Future<void> _expectDenied(
  FutureOr<Object?> Function() operation, [
  String message = 'permission',
]) async {
  try {
    final result = await operation();
    if (result is RandomAccessFile) await result.close();
  } on RuntimeD4rtException catch (error) {
    expect('$error'.toLowerCase(), contains(message.toLowerCase()));
    return;
  }
  fail('Expected a permission denial containing "$message".');
}

class _OfflineRun {
  _OfflineRun(Directory scratch, {Directory? project, bool grants = true}) {
    _port.listen((message) {
      if (message is! Map) return;
      if (message['_barrier'] case final int id) {
        _barriers.remove(id)?.complete();
        return;
      }
      if (message case {'type': final String type, 'data': final String data}) {
        _chunks.add((type: type, data: data));
        _changes.add(null);
      }
    });
    runtime = D4rt(
      hostPolicy: OfflineHostPolicy(
        scratchPath: scratch.path,
        projectPath: project?.path,
        output: _port.sendPort,
      ),
    );
    if (grants) {
      for (final directory in [scratch, ?project]) {
        runtime.grant(FilesystemPermission.readPath(directory.path));
        runtime.grant(FilesystemPermission.writePath(directory.path));
      }
      runtime.grant(IsolatePermission.any);
    }
  }

  late final D4rt runtime;
  final ReceivePort _port = ReceivePort();
  final _changes = StreamController<void>.broadcast(sync: true);
  final _chunks = <({String type, String data})>[];
  final _barriers = <int, Completer<void>>{};
  int _nextBarrier = 0;

  String get stdout => _text('stdout');
  String get stderr => _text('stderr');
  String _text(String type) =>
      _chunks.where((chunk) => chunk.type == type).map((c) => c.data).join();

  void grantBroadly() {
    runtime.grant(FilesystemPermission.any);
    runtime.grant(NetworkPermission.any);
    runtime.grant(ProcessRunPermission.any);
    runtime.grant(DangerousPermission.any);
    runtime.grant(CertificatePermission.any);
  }

  Future<Object?> execute(
    String source, {
    String? basePath,
    bool filesystem = false,
  }) async {
    Object? failure;
    // This is the interpreter boundary: any user-program exception is evidence
    // for the caller, rather than a successful empty run.
    try {
      await runZoned(
        () async {
          await Future<dynamic>.value(
            runtime.execute(
              source: source,
              basePath: basePath,
              allowFileSystemImports: filesystem,
            ),
          ).timeout(_timeout);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            _port.sendPort.send({'type': 'stdout', 'data': '$line\n'});
          },
        ),
      );
    } on Object catch (error) {
      failure = error;
    }
    final id = _nextBarrier++;
    final barrier = _barriers[id] = Completer<void>();
    _port.sendPort.send({'_barrier': id});
    await barrier.future.timeout(_timeout);
    return failure;
  }

  Future<void> waitForOutput(String output, {String errors = ''}) async {
    bool complete() => stdout == output && stderr == errors;
    if (!complete()) {
      await _changes.stream.firstWhere((_) => complete()).timeout(_timeout);
    }
    expect(stdout, output);
    expect(stderr, errors);
  }

  Future<void> close() async {
    _port.close();
    await _changes.close();
  }
}

class _Fixture {
  _Fixture() {
    root = Directory.systemTemp.createTempSync('qfli_offline_policy_test_');
    scratch = Directory(p.join(root.path, 'scratch'))..createSync();
    project = Directory(p.join(root.path, 'project'))..createSync();
    outside = Directory(p.join(root.path, 'outside'))..createSync();
    native = Directory(p.join(root.path, 'native'))..createSync();
  }

  late final Directory root;
  late final Directory scratch;
  late final Directory project;
  late final Directory outside;
  late final Directory native;
  final _runs = <_OfflineRun>[];

  _OfflineRun run({
    bool project = false,
    bool broad = false,
    bool grants = true,
  }) {
    final run = _OfflineRun(
      scratch,
      project: project ? this.project : null,
      grants: grants,
    );
    if (broad) run.grantBroadly();
    _runs.add(run);
    return run;
  }

  Future<void> dispose() async {
    InterpretedIsolateSupervisor.killAll();
    for (final run in _runs) {
      await run.close();
    }
    root.deleteSync(recursive: true);
  }
}

class _AddressStandIn implements InternetAddress {
  _AddressStandIn(this.host);
  @override
  final String host;
  @override
  String get address => host;
  int reverseCalls = 0;
  @override
  Future<InternetAddress> reverse() async {
    reverseCalls++;
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected address operation: ${invocation.memberName}',
  );
}

class _DatagramStandIn implements RawDatagramSocket {
  int sendCalls = 0;
  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    sendCalls++;
    return buffer.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected socket operation: ${invocation.memberName}');
}

Future<RandomAccessFile> _open(
  D4rt runtime,
  File file,
  FileMode mode,
  String method,
) async =>
    await Future<Object?>.value(
          FileIo.definition.methods[method]!(
            _visitor(runtime),
            file,
            const [],
            {'mode': mode},
            null,
          ),
        )
        as RandomAccessFile;

Future<String> _readWriteResult(RandomAccessFile handle) async {
  try {
    await handle.setPosition(0);
    final before = utf8.decode(await handle.read(100));
    await handle.writeString('!');
    await handle.setPosition(0);
    return '$before|${utf8.decode(await handle.read(100))}';
  } finally {
    await handle.close();
  }
}

bool _createLinkOrSkip(Link link, String target) {
  try {
    link.createSync(target);
    return true;
  } on FileSystemException catch (error) {
    markTestSkipped('Host cannot create symbolic link: $error');
    return false;
  }
}

void main() {
  late _Fixture fixture;
  setUp(() => fixture = _Fixture());
  tearDown(() => fixture.dispose());

  group('offline host policy', () {
    for (final id in ['097', '098', '099', '100', '101', '102', '103', '104']) {
      test(
        'unchanged lesson $id uses and cleans real temporary files',
        () async {
          final catalog =
              jsonDecode(
                    File(
                      p.join('assets', 'content', 'dart_tutorials.json'),
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>;
          final entry = (catalog['entries'] as List)
              .cast<Map<String, dynamic>>()
              .singleWhere((entry) => entry['id'] == 'dart-lesson-$id');
          final lesson =
              (entry['lessons'] as List).single as Map<String, dynamic>;
          final run = fixture.run();
          expect(await run.execute(lesson['code'] as String), isNull);
          await run.waitForOutput(lesson['output'] as String);
          expect(fixture.scratch.listSync(), isEmpty);
        },
      );
    }

    test(
      'relative files, directories and raw directory use project and scratch',
      () async {
        final cwd = Directory.current.path;
        final run = fixture.run(project: true);
        expect(
          await run.execute(r'''
import 'dart:io';
import 'dart:typed_data';
void main() {
  final file = File('relative.txt')..writeAsStringSync('real project');
  file.copySync('copied.txt');
  file.renameSync('renamed.txt');
  final directory = Directory('directory')..createSync();
  directory.renameSync('renamed-directory');
  Directory.fromRawPath(Uint8List.fromList([114, 97, 119])).createSync();
  print(Directory.current.path);
  print(Directory.systemTemp.path);
  print(File('copied.txt').readAsStringSync());
}
'''),
          isNull,
        );
        await run.waitForOutput(
          '${fixture.project.path}\n${fixture.scratch.path}\nreal project\n',
        );
        expect(
          File(p.join(fixture.project.path, 'renamed.txt')).readAsStringSync(),
          'real project',
        );
        expect(
          File(p.join(fixture.project.path, 'copied.txt')).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            p.join(fixture.project.path, 'renamed-directory'),
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(p.join(fixture.project.path, 'raw')).existsSync(),
          isTrue,
        );
        expect(Directory.current.path, cwd);
      },
    );

    test(
      'read and write grants remain independent inside permitted roots',
      () async {
        final file = File(p.join(fixture.scratch.path, 'data.txt'))
          ..writeAsStringSync('seed');
        final read = fixture.run(grants: false).runtime
          ..grant(FilesystemPermission.readPath(fixture.scratch.path));
        final write = fixture.run(grants: false).runtime
          ..grant(FilesystemPermission.writePath(fixture.scratch.path));
        final methods = FileIo.definition.methods;
        expect(
          methods['readAsStringSync']!(_visitor(read), file, [], {}, null),
          'seed',
        );
        await _expectDenied(
          () => methods['writeAsStringSync']!(
            _visitor(read),
            file,
            ['changed'],
            {},
            null,
          ),
        );
        expect(file.readAsStringSync(), 'seed');
        await _expectDenied(
          () =>
              methods['readAsStringSync']!(_visitor(write), file, [], {}, null),
        );
        methods['writeAsStringSync']!(
          _visitor(write),
          file,
          ['written'],
          {},
          null,
        );
        expect(file.readAsStringSync(), 'written');
      },
    );

    test(
      'broad grants cannot read or write outside roots or escape temp prefix',
      () async {
        final run = fixture.run(project: true, broad: true);
        final outside = File(p.join(fixture.outside.path, 'secret.txt'))
          ..writeAsStringSync('outside');
        final target = jsonEncode(outside.path);
        final prefix = jsonEncode(p.join('..', 'outside', 'escaped_'));
        expect(
          await run.execute('''
import 'dart:io';
void main() {
  try { File($target).readAsStringSync(); } catch (_) { print('read denied'); }
  try { File($target).writeAsStringSync('changed'); } catch (_) { print('write denied'); }
  try { Directory.systemTemp.createTempSync($prefix); } catch (_) { print('prefix denied'); }
}
'''),
          isNull,
        );
        await run.waitForOutput('read denied\nwrite denied\nprefix denied\n');
        expect(outside.readAsStringSync(), 'outside');
        expect(
          fixture.outside.listSync().map((entity) => p.basename(entity.path)),
          ['secret.txt'],
        );
      },
    );

    test(
      'offline ceiling denies broad network, process and privileged grants',
      () async {
        final runtime = fixture.run(broad: true).runtime;
        for (final operation in <Map<String, dynamic>>[
          {'type': 'network', 'host': '203.0.113.1', 'connect': true},
          {'type': 'process', 'command': 'qfli_never_execute'},
          {'type': 'dangerous'},
          {'type': 'certificate'},
          {
            'type': 'filesystem',
            'path': p.join(fixture.scratch.path, 'program'),
            'execute': true,
          },
        ]) {
          expect(
            runtime.checkPermission(operation),
            isFalse,
            reason: '$operation',
          );
        }
        expect(
          runtime.checkPermission({'type': 'isolate', 'spawn': true}),
          isTrue,
        );
        await _expectDenied(
          () => ProcessIo.definition.staticMethods['run']!(
            _visitor(runtime),
            ['qfli_never_execute', <String>[]],
            {},
            null,
          ),
        );
      },
    );

    test(
      'broad socket grant is denied before the native connection hook',
      () async {
        final runtime = fixture.run(broad: true).runtime;
        var nativeCalls = 0;
        await IOOverrides.runZoned(
          () => _expectDenied(
            () => SocketIo.definition.staticMethods['connect']!(
              _visitor(runtime),
              ['203.0.113.1', 9000],
              {},
              null,
            ),
          ),
          socketConnect:
              (
                host,
                port, {
                sourceAddress,
                int sourcePort = 0,
                Duration? timeout,
              }) {
                nativeCalls++;
                throw StateError('A denied connect reached the native hook.');
              },
        );
        expect(nativeCalls, 0);
      },
    );

    test('outside paths are rejected before native metadata queries', () {
      final runtime = fixture.run(broad: true).runtime;
      var queries = 0;
      final allowed = IOOverrides.runZoned(
        () => runtime.checkPermission({
          'type': 'filesystem',
          'path': p.join(fixture.outside.path, 'secret.txt'),
          'read': true,
        }),
        fseGetTypeSync: (path, followLinks) {
          queries++;
          return FileSystemEntityType.notFound;
        },
      );
      expect(allowed, isFalse);
      expect(queries, 0);
    });

    test('broken link ancestor is rejected before querying its descendant', () {
      final runtime = fixture.run(broad: true).runtime;
      final queried = <String>[];
      final allowed = IOOverrides.runZoned(
        () => runtime.checkPermission({
          'type': 'filesystem',
          'path': p.join(fixture.scratch.path, 'broken-link', 'new.txt'),
          'write': true,
        }),
        fseGetTypeSync: (path, followLinks) {
          queried.add(path);
          return p.basename(path) == 'broken-link' && !followLinks
              ? FileSystemEntityType.link
              : FileSystemEntityType.directory;
        },
      );
      expect(allowed, isFalse);
      expect(queried.any((path) => p.basename(path) == 'broken-link'), isTrue);
      expect(queried.any((path) => p.basename(path) == 'new.txt'), isFalse);
    });

    for (final method in ['list', 'listSync']) {
      test('$method does not follow a real outside directory link', () async {
        File(
          p.join(fixture.outside.path, 'secret.txt'),
        ).writeAsStringSync('outside');
        final link = Link(p.join(fixture.scratch.path, 'outside-link'));
        if (!_createLinkOrSkip(link, fixture.outside.path)) return;
        final run = fixture.run(broad: true);
        final entries = method == 'list'
            ? 'await Directory.systemTemp.list(recursive: true).toList()'
            : 'Directory.systemTemp.listSync(recursive: true)';
        expect(
          await run.execute('''
import 'dart:io';
Future<void> main() async {
  final entries = $entries;
  print(entries.whereType<File>().any((file) => file.path.endsWith('secret.txt')));
  try { File('\${Directory.systemTemp.path}/outside-link/secret.txt').readAsStringSync(); }
  catch (_) { print('linked read denied'); }
}
'''),
          isNull,
        );
        await run.waitForOutput('false\nlinked read denied\n');
        expect(
          File(p.join(fixture.outside.path, 'secret.txt')).readAsStringSync(),
          'outside',
        );
      });
    }

    test('real broken file link cannot create an outside target', () async {
      final target = File(p.join(fixture.outside.path, 'new.txt'));
      final link = Link(p.join(fixture.scratch.path, 'broken-link'));
      if (!_createLinkOrSkip(link, target.path)) return;
      final run = fixture.run(broad: true);
      expect(
        await run.execute(r'''
import 'dart:io';
void main() {
  try { File('${Directory.systemTemp.path}/broken-link').writeAsStringSync('escape'); }
  catch (_) { print('link denied'); }
}
'''),
        isNull,
      );
      await run.waitForOutput('link denied\n');
      expect(target.existsSync(), isFalse);
    });

    test(
      'stdin and cwd changes fail without affecting the host process',
      () async {
        final cwd = Directory.current.path;
        final run = fixture.run(broad: true);
        expect(
          await run.execute(r'''
import 'dart:io';
void main() {
  try { Directory.current = Directory.systemTemp; } catch (_) { print('cwd denied'); }
  try { stdin.readLineSync(); } catch (_) { print('stdin denied'); }
}
'''),
          isNull,
        );
        await run.waitForOutput('cwd denied\nstdin denied\n');
        expect(Directory.current.path, cwd);
        expect(
          () => run.runtime.runWithHostPolicy(() => stdin),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'partial output, stderr and split UTF8 bytes are captured exactly',
      () async {
        final host = stdout;
        final encoding = host.encoding;
        final terminator = host.lineTerminator;
        final run = fixture.run();
        expect(
          await run.execute(r'''
import 'dart:io';
Future<void> main() async {
  stdout.write('part'); stdout.writeln('ial');
  stderr.write('error');
  stdout.add([0xE4]); stdout.add([0xBD, 0xA0, 0xE5, 0xA5, 0xBD]);
  stdout.writeln();
  stdout.lineTerminator = '\r\n';
  stdout.writeln('line');
  await stdout.close();
}
'''),
          isNull,
        );
        await run.waitForOutput('partial\n你好\nline\r\n', errors: 'error');
        expect(identical(stdout, host), isTrue);
        expect(host.encoding, same(encoding));
        expect(host.lineTerminator, terminator);
        expect(
          await run.execute(
            "import 'dart:io'; void main() { stdout.writeln('next'); }",
          ),
          isNull,
        );
        await run.waitForOutput('partial\n你好\nline\r\nnext\n', errors: 'error');
      },
    );

    test('void and null policy bodies execute exactly once', () {
      final runtime = fixture.run().runtime;
      var calls = 0;
      runtime.runWithHostPolicy<void>(() {
        calls++;
      });
      expect(calls, 1);
      expect(
        runtime.runWithHostPolicy<Object?>(() {
          calls++;
          return null;
        }),
        isNull,
      );
      expect(calls, 2);
    });

    test('filesystem source imports stay within scratch and project', () async {
      File(
        p.join(fixture.project.path, 'local.dart'),
      ).writeAsStringSync("String value() => 'local source';");
      final run = fixture.run(project: true, broad: true);
      expect(
        await run.execute(
          "import 'local.dart'; void main() { print(value()); }",
          basePath: fixture.project.path,
          filesystem: true,
        ),
        isNull,
      );
      await run.waitForOutput('local source\n');
      final outside = File(p.join(fixture.outside.path, 'module.dart'))
        ..writeAsStringSync("String secret() => 'outside source';");
      final error = await run.execute(
        "import '${outside.uri}'; void main() { print(secret()); }",
        basePath: fixture.project.path,
        filesystem: true,
      );
      expect(error, isNotNull);
      expect('$error'.toLowerCase(), contains('permission'));
      expect(run.stdout, 'local source\n');
    });

    test('child inherits virtual roots, output and the policy ceiling', () async {
      final run = fixture.run(project: true, broad: true);
      expect(
        await run.execute(r'''
import 'dart:io';
import 'dart:isolate';
Future<void> main() async {
  print(await Isolate.run(() {
    stdout.write('child output\n'); stderr.write('child error');
    File('child.txt').writeAsStringSync('child file');
    String policy;
    try { Directory.current = Directory.systemTemp; policy = 'escaped'; }
    catch (_) { policy = 'inherited'; }
    return '${Directory.current.path}|${Directory.systemTemp.path}|$policy';
  }));
}
'''),
        isNull,
      );
      await run.waitForOutput(
        'child output\n${fixture.project.path}|${fixture.scratch.path}|inherited\n',
        errors: 'child error',
      );
      expect(
        File(p.join(fixture.project.path, 'child.txt')).readAsStringSync(),
        'child file',
      );
    });
  });

  group('native bridge permission gates', () {
    for (final method in ['open', 'openSync']) {
      for (final mode in {
        'write': FileMode.write,
        'append': FileMode.append,
      }.entries) {
        test(
          '$method ${mode.key} requires read and write before opening',
          () async {
            final file = File(p.join(fixture.scratch.path, 'kept.txt'))
              ..writeAsStringSync('kept');
            for (final permission in [
              FilesystemPermission.readPath(fixture.scratch.path),
              FilesystemPermission.writePath(fixture.scratch.path),
            ]) {
              final runtime = D4rt()..grant(permission);
              await _expectDenied(
                () => _open(runtime, file, mode.value, method),
                'Filesystem permission denied',
              );
              expect(file.readAsStringSync(), 'kept');
            }
          },
        );

        test(
          '$method ${mode.key} matches real SDK read/write handle semantics',
          () async {
            final native = File(p.join(fixture.native.path, 'data.txt'))
              ..writeAsStringSync('seed');
            final candidate = File(p.join(fixture.scratch.path, 'data.txt'))
              ..writeAsStringSync('seed');
            final expected = await _readWriteResult(
              await native.open(mode: mode.value),
            );
            final runtime = D4rt()
              ..grant(FilesystemPermission.readPath(fixture.scratch.path))
              ..grant(FilesystemPermission.writePath(fixture.scratch.path));
            final actual = await _readWriteResult(
              await _open(runtime, candidate, mode.value, method),
            );
            expect(actual, expected);
            expect(candidate.readAsStringSync(), native.readAsStringSync());
          },
        );
      }

      for (final mode in {
        'writeOnly': FileMode.writeOnly,
        'writeOnlyAppend': FileMode.writeOnlyAppend,
      }.entries) {
        test('$method ${mode.key} needs only a write grant', () async {
          final file = File(p.join(fixture.scratch.path, 'data.txt'))
            ..writeAsStringSync('seed');
          final runtime = D4rt()
            ..grant(FilesystemPermission.writePath(fixture.scratch.path));
          final handle = await _open(runtime, file, mode.value, method);
          try {
            await handle.writeString('!');
          } finally {
            await handle.close();
          }
          expect(
            file.readAsStringSync(),
            mode.value == FileMode.writeOnly ? '!' : 'seed!',
          );
        });
      }

      test('$method read needs only a read grant', () async {
        final file = File(p.join(fixture.scratch.path, 'data.txt'))
          ..writeAsStringSync('read me');
        final runtime = D4rt()
          ..grant(FilesystemPermission.readPath(fixture.scratch.path));
        final handle = await _open(runtime, file, FileMode.read, method);
        try {
          expect(utf8.decode(await handle.read(100)), 'read me');
        } finally {
          await handle.close();
        }
      });
    }

    test(
      'reverse DNS checks its address before calling the stand-in',
      () async {
        final address = _AddressStandIn('203.0.113.1');
        final reverse = InternetAddressIo.definition.methods['reverse']!;
        for (final runtime in [
          D4rt(),
          D4rt()..grant(FilesystemPermission.readPath(fixture.scratch.path)),
          D4rt()..grant(NetworkPermission.connectTo('203.0.113.2')),
          fixture.run(broad: true).runtime,
        ]) {
          await _expectDenied(
            () => reverse(_visitor(runtime), address, [], {}, null),
            'Network permission denied',
          );
        }
        expect(address.reverseCalls, 0);
        final allowed = D4rt()
          ..grant(NetworkPermission.connectTo(address.host));
        await Future<Object?>.value(
          reverse(_visitor(allowed), address, [], {}, null),
        );
        expect(address.reverseCalls, 1);
      },
    );

    test(
      'UDP send checks destination and port without creating sockets',
      () async {
        final socket = _DatagramStandIn();
        final address = _AddressStandIn('203.0.113.1');
        final send = RawDatagramSocketIo.definition.methods['send']!;
        final args = [
          <int>[1, 2],
          address,
          9000,
        ];
        for (final runtime in [
          D4rt(),
          D4rt()..grant(NetworkPermission.bind),
          D4rt()..grant(NetworkPermission.connectToPort('203.0.113.2', 9000)),
          D4rt()..grant(NetworkPermission.connectToPort(address.host, 9001)),
          fixture.run(broad: true).runtime,
        ]) {
          await _expectDenied(
            () => send(_visitor(runtime), socket, args, {}, null),
            'Network permission denied',
          );
        }
        expect(socket.sendCalls, 0);
        final allowed = D4rt()
          ..grant(NetworkPermission.connectToPort(address.host, 9000));
        expect(send(_visitor(allowed), socket, args, {}, null), 2);
        expect(socket.sendCalls, 1);
      },
    );

    for (final offline in [false, true]) {
      for (final absolute in [false, true]) {
        test(
          'raw ${absolute ? 'absolute' : 'relative'} file preserves ${offline ? 'offline' : 'default'} cwd behavior',
          () async {
            final runtime = offline
                ? fixture.run(project: true, grants: false).runtime
                : D4rt();
            final expected = offline || absolute
                ? fixture.project
                : fixture.native;
            runtime.grant(FilesystemPermission.writePath(expected.path));
            final path = absolute
                ? p.join(fixture.project.path, 'raw-file.txt')
                : 'raw-file.txt';
            final bytes = Uint8List.fromList(utf8.encode(path));
            final nativePath = File.fromRawPath(bytes).path;
            final cwd = Directory.current.path;
            try {
              Directory.current = fixture.native.path;
              runtime.runWithHostPolicy(() {
                final file =
                    FileIo.definition.staticMethods['fromRawPath']!(
                          _visitor(runtime),
                          [bytes],
                          {},
                          null,
                        )
                        as File;
                if (!offline || absolute) {
                  expect(file.path, nativePath);
                }
                FileIo.definition.methods['writeAsStringSync']!(
                  _visitor(runtime),
                  file,
                  ['raw path data'],
                  {},
                  null,
                );
              });
            } finally {
              Directory.current = cwd;
            }
            expect(
              File(p.join(expected.path, 'raw-file.txt')).readAsStringSync(),
              'raw path data',
            );
            if (offline || absolute) {
              expect(
                File(p.join(fixture.native.path, 'raw-file.txt')).existsSync(),
                isFalse,
              );
            }
            expect(Directory.current.path, cwd);
          },
        );
      }
    }

    for (final method in ['copy', 'copySync', 'rename', 'renameSync']) {
      test('$method destination follows the checked virtual cwd', () async {
        final run = fixture.run(project: true);
        final source = File(p.join(fixture.project.path, 'source.txt'))
          ..writeAsStringSync('destination test');
        final cwd = Directory.current.path;
        try {
          Directory.current = fixture.native.path;
          await run.runtime.runWithHostPolicy(() async {
            await Future<Object?>.value(
              FileIo.definition.methods[method]!(
                _visitor(run.runtime),
                source,
                ['destination.txt'],
                {},
                null,
              ),
            );
          });
        } finally {
          Directory.current = cwd;
        }
        expect(
          File(p.join(fixture.native.path, 'destination.txt')).existsSync(),
          isFalse,
        );
        expect(
          File(
            p.join(fixture.project.path, 'destination.txt'),
          ).readAsStringSync(),
          'destination test',
        );
      });
    }

    for (final method in ['rename', 'renameSync']) {
      test('FileSystemEntity $method fallback uses virtual cwd', () async {
        final run = fixture.run(project: true);
        final source = File(p.join(fixture.project.path, 'entity.txt'))
          ..writeAsStringSync('entity data');
        await run.runtime.runWithHostPolicy(() async {
          await Future<Object?>.value(
            FileSystemEntityIo.definition.methods[method]!(
              _visitor(run.runtime),
              source,
              ['renamed-entity.txt'],
              {},
              null,
            ),
          );
        });
        expect(
          File(
            p.join(fixture.project.path, 'renamed-entity.txt'),
          ).readAsStringSync(),
          'entity data',
        );
      });
    }
  });
}
