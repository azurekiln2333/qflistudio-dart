@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/src/stdlib/isolate/interpreted_isolate.dart';

const _nested = '''
import 'dart:isolate';
Future<void> main(SendPort signal) async {
  await Isolate.run(() async {
    await Isolate.run(() {
      signal.send('loop-entered');
      while (true) {}
    });
  });
}
''';

const _burst = '''
import 'dart:isolate';
Future<void> main(SendPort signal) async {
  final pending = <Future<Object?>>[];
  for (var i = 0; i < 50; i++) {
    pending.add(Isolate.run(() { while (true) {} }));
  }
  await Future.wait(pending);
}
''';

const _timer = '''
import 'dart:async';
import 'dart:isolate';
void main(SendPort signal) {
  Timer(Duration(milliseconds: 100), () => signal.send('timer-finished'));
  signal.send('main-done');
}
''';

const _queuedGrandchild = '''
import 'dart:async';
import 'dart:isolate';
Future<void> main(SendPort signal) async {
  await Isolate.run(() {
    Isolate.spawn((SendPort target) {
      final release = ReceivePort();
      target.send(release.sendPort);
      release.listen((_) {
        target.send('child-finished');
        release.close();
      });
    }, signal);
    return 7;
  });
  signal.send('main-done');
}
''';

Future<void> _interpreterWorker((SendPort, String, SendPort) request) async {
  InterpretedIsolateSupervisor.spawnBrokerPort = request.$1;
  try {
    final runtime = D4rt()..grant(IsolatePermission.any);
    await Future.value(
      runtime.execute(source: request.$2, positionalArgs: [request.$3]),
    );
  } catch (error) {
    request.$3.send('worker-error: $error');
  }
}

Future<void> _policyWorker(
  (SendPort, String, SendPort, OfflineHostPolicy) request,
) async {
  InterpretedIsolateSupervisor.spawnBrokerPort = request.$1;
  try {
    final runtime = D4rt(hostPolicy: request.$4)..grant(IsolatePermission.any);
    await Future.value(
      runtime.execute(source: request.$2, positionalArgs: [request.$3]),
    );
  } catch (error) {
    request.$3.send('worker-error: $error');
  }
}

Future<void> _cancelAt(int threshold, {bool waitForLoop = false}) async {
  final reached = Completer<void>();
  final enteredLoop = Completer<void>();
  final signals = ReceivePort();
  var requests = 0;
  var pendingAtStop = 0;
  Future<void>? stopping;
  late final InterpretedIsolateSupervisorHost host;
  host = InterpretedIsolateSupervisorHost(
    onSpawnRequested: () {
      requests++;
      if (requests != threshold) return;
      pendingAtStop = host.pendingSpawnCount;
      if (!waitForLoop) stopping = host.stop();
      reached.complete();
    },
  );
  signals.listen((message) {
    if (message == 'loop-entered' && !enteredLoop.isCompleted) {
      enteredLoop.complete();
    }
  });
  try {
    try {
      await host.spawn(_interpreterWorker, (
        host.sendPort,
        threshold > 3 ? _burst : _nested,
        signals.sendPort,
      ));
    } on StateError {
      // Stop can run inside native creation of the outer worker itself.
      if (threshold != 1) rethrow;
    }
    await reached.future.timeout(const Duration(seconds: 8));
    if (waitForLoop) {
      await enteredLoop.future.timeout(const Duration(seconds: 8));
      expect(host.activeWorkerCount, 3);
    } else {
      expect(pendingAtStop, greaterThan(0));
    }
    await (stopping ?? host.stop()).timeout(const Duration(seconds: 8));
    expect(host.activeWorkerCount, 0);
    expect(host.pendingSpawnCount, 0);
    expect(host.createdWorkerCount, threshold);
    expect(host.exitedWorkerCount, host.createdWorkerCount);
  } finally {
    await host.stop().timeout(const Duration(seconds: 8));
    signals.close();
  }
}

Future<void> _finishNaturally(
  String source,
  int expectedWorkers, {
  required bool childSurvivesOuter,
}) async {
  final host = InterpretedIsolateSupervisorHost();
  final signals = ReceivePort();
  final exits = ReceivePort();
  final mainDone = Completer<void>();
  final releaseChild = Completer<SendPort>();
  final events = <String>[];
  signals.listen((message) {
    if (message is SendPort) {
      releaseChild.complete(message);
      return;
    }
    events.add('$message');
    if (message == 'main-done' && !mainDone.isCompleted) mainDone.complete();
  });
  try {
    await host.spawn(_interpreterWorker, (
      host.sendPort,
      source,
      signals.sendPort,
    ), onExit: exits.sendPort);
    var idle = false;
    final finished = host.waitForIdle().then((_) => idle = true);
    await mainDone.future.timeout(const Duration(seconds: 8));
    expect(idle, isFalse);
    await exits.first.timeout(const Duration(seconds: 8));
    if (childSurvivesOuter) {
      expect(idle, isFalse);
      // The grandchild may still be inside native Isolate.spawn when the
      // outer exit arrives, so pending creation is liveness too.
      expect(host.activeWorkerCount + host.pendingSpawnCount, greaterThan(0));
      final release = await releaseChild.future.timeout(
        const Duration(seconds: 8),
      );
      release.send('finish');
    }
    await finished.timeout(const Duration(seconds: 8));
    await Future<void>.delayed(Duration.zero);
    expect(
      events,
      contains(childSurvivesOuter ? 'child-finished' : 'timer-finished'),
    );
    expect(events.where((event) => event.startsWith('worker-error:')), isEmpty);
    expect(host.createdWorkerCount, expectedWorkers);
    expect(host.exitedWorkerCount, expectedWorkers);
    expect(host.activeWorkerCount, 0);
    expect(host.pendingSpawnCount, 0);
  } finally {
    await host.stop().timeout(const Duration(seconds: 8));
    signals.close();
    exits.close();
  }
}

Future<List<Object?>> _collect(String source, int workers) async {
  final host = InterpretedIsolateSupervisorHost();
  final signals = ReceivePort();
  final messages = <Object?>[];
  signals.listen(messages.add);
  try {
    await host.spawn(_interpreterWorker, (
      host.sendPort,
      source,
      signals.sendPort,
    ));
    await host.waitForIdle().timeout(const Duration(seconds: 8));
    await Future<void>.delayed(Duration.zero);
    expect(host.createdWorkerCount, workers);
    expect(host.exitedWorkerCount, workers);
    return messages;
  } finally {
    await host.stop().timeout(const Duration(seconds: 8));
    signals.close();
  }
}

void main() {
  test(
    'native child uses fresh globals and minimal lexical captures',
    () async {
      final messages = await _collect('''
import 'dart:isolate';
int counter = 7;
class Counters { static int counter = 11; }
Future<void> main(SendPort signal) async {
  counter = 100;
  Counters.counter = 200;
  var local = 13;
  final unused = ReceivePort();
  final values = <Object?>[1];
  final alias = values;
  values.add(values);
  final parent = Isolate.current.hashCode;
  try {
    signal.send(await Isolate.run(() {
      counter++;
      Counters.counter = Counters.counter + 1;
      local++;
      alias[0] = 2;
      return [counter, Counters.counter, local, identical(values, alias),
          identical(values, values[1]), Isolate.current.hashCode != parent];
    }));
    signal.send([counter, Counters.counter, local, values[0]]);
  } finally {
    unused.close();
  }
}
''', 2);
      expect(messages, [
        [8, 12, 14, true, true, true],
        [100, 200, 13, 1],
      ]);
    },
  );

  test(
    'native captured collections preserve generic constraints and immutability',
    () async {
      final host = InterpretedIsolateSupervisorHost();
      InterpretedIsolateSupervisor.spawnBrokerPort = host.sendPort;
      try {
        for (final entry in <String, Object>{
          'list': <int>[1],
          'const-list': const <int>[1],
          'unmodifiable-list': List<int>.unmodifiable([1]),
          'map': <String, int>{'a': 1},
          'const-map': const <String, int>{'a': 1},
          'set': <int>{1},
          'const-set': const <int>{1},
        }.entries) {
          final map = entry.value is Map;
          final invalidInsert = map
              ? "data['b'] = 'wrong';"
              : "data.add('wrong');";
          final validInsert = map ? "data['b'] = 2;" : "data.add(2);";
          final immutable =
              entry.key.startsWith('const-') ||
              entry.key.startsWith('unmodifiable-');
          final runtime = D4rt()..grant(IsolatePermission.any);
          final function =
              runtime.execute(
                    source:
                        '''
main() {
  var data = <Object?>[];
  return () {
    var rejected = false;
    try { $invalidInsert } catch (error) { rejected = true; }
    var immutable = false;
    try { $validInsert } catch (error) { immutable = true; }
    return [data.runtimeType.toString(), rejected, immutable, data.length];
  };
}
''',
                  )
                  as InterpretedFunction;
          function.closure.assign('data', entry.value);
          final result = await runInterpretedIsolate(
            runtime.visitor!,
            function,
          );
          expect(result, [
            '${entry.value.runtimeType}',
            true,
            immutable,
            immutable ? 1 : 2,
          ], reason: entry.key);
          final original = entry.value;
          expect(
            original is Map ? original.length : (original as Iterable).length,
            1,
            reason: 'parent ${entry.key}',
          );
        }
        await host.waitForIdle().timeout(const Duration(seconds: 8));
        expect(host.createdWorkerCount, 7);
        expect(host.exitedWorkerCount, 7);
      } finally {
        await host.stop().timeout(const Duration(seconds: 8));
        InterpretedIsolateSupervisor.spawnBrokerPort = null;
      }
    },
  );

  test(
    'Stop before creation rejects work without creating a native worker',
    () async {
      final host = InterpretedIsolateSupervisorHost();
      final signal = ReceivePort();
      try {
        await host.stop();
        await expectLater(
          host.spawn(_interpreterWorker, (
            host.sendPort,
            _nested,
            signal.sendPort,
          )),
          throwsStateError,
        );
        expect(host.createdWorkerCount, 0);
        expect(host.activeWorkerCount, 0);
        expect(host.pendingSpawnCount, 0);
      } finally {
        await host.stop();
        signal.close();
      }
    },
  );

  test('Stop drains native creation of the outer worker', () => _cancelAt(1));
  test('Stop drains native creation of a descendant', () => _cancelAt(2));
  test(
    'Stop kills a confirmed busy child and grandchild',
    () => _cancelAt(3, waitForLoop: true),
  );
  test(
    'Stop drains a queued burst of 50 computation requests',
    () => _cancelAt(6),
  );
  test('repeated pending native spawn races leave no owned worker', () async {
    for (var iteration = 0; iteration < 20; iteration++) {
      await _cancelAt(2);
    }
  });

  test(
    'idle preserves timer work after main returns',
    () => _finishNaturally(_timer, 1, childSurvivesOuter: false),
  );
  test(
    'queued unawaited grandchildren survive requester exit and drain naturally',
    () async {
      for (var iteration = 0; iteration < 20; iteration++) {
        await _finishNaturally(_queuedGrandchild, 3, childSurvivesOuter: true);
      }
    },
  );

  test(
    'grandchild print reaches host output after requesting interpreter exits',
    () async {
      final scratch = Directory.systemTemp.createTempSync('qfli-child-output-');
      final host = InterpretedIsolateSupervisorHost();
      final signals = ReceivePort();
      final exits = ReceivePort();
      final output = ReceivePort();
      final childRelease = Completer<SendPort>();
      final mainDone = Completer<void>();
      final messages = <Object?>[];
      output.listen(messages.add);
      signals.listen((message) {
        if (message is SendPort) childRelease.complete(message);
        if (message == 'main-done') mainDone.complete();
      });
      try {
        await host.spawn(_policyWorker, (
          host.sendPort,
          _queuedGrandchild.replaceFirst(
            "target.send('child-finished');",
            "print('late-child-print');",
          ),
          signals.sendPort,
          OfflineHostPolicy(scratchPath: scratch.path, output: output.sendPort),
        ), onExit: exits.sendPort);
        final idle = host.waitForIdle();
        await mainDone.future.timeout(const Duration(seconds: 8));
        await exits.first.timeout(const Duration(seconds: 8));
        final release = await childRelease.future.timeout(
          const Duration(seconds: 8),
        );
        release.send('finish');
        await idle.timeout(const Duration(seconds: 8));
        await Future<void>.delayed(Duration.zero);
        expect(messages, [
          {'type': 'stdout', 'data': 'late-child-print\n'},
        ]);
        expect(host.createdWorkerCount, 3);
        expect(host.exitedWorkerCount, 3);
      } finally {
        await host.stop().timeout(const Duration(seconds: 8));
        signals.close();
        exits.close();
        output.close();
        scratch.deleteSync(recursive: true);
      }
    },
  );

  test('spawnUri rejection is catchable by interpreted await', () async {
    final runtime = D4rt()..grant(IsolatePermission.any);
    final result = await Future.value(
      runtime.execute(
        source: '''
import 'dart:isolate';
Future<String> main() async {
  try {
    await Isolate.spawnUri(Uri.parse('file:///qfli-unavailable-native.dart'), <String>[], null);
    return 'unexpected';
  } on UnsupportedError {
    return 'rejected';
  }
}
''',
      ),
    );
    expect(result, 'rejected');
  });

  test(
    'spawnUri rejects valid native source with restricted and full isolate grants',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'qfli-native-source-test-',
      );
      final script = File('${directory.path}/worker.dart')
        ..writeAsStringSync('''
import 'dart:isolate';
void main(List<String> args, Object? message) {
  (message as SendPort).send('escaped-native-source');
  ReceivePort().listen((_) {});
}
''');
      try {
        for (final permission in [
          IsolatePermission.communicate,
          IsolatePermission.any,
        ]) {
          final signal = ReceivePort();
          final exits = ReceivePort();
          final seen = <Object?>[];
          signal.listen(seen.add);
          Isolate? nativeWorker;
          try {
            final runtime = D4rt()..grant(permission);
            Object? rejection;
            try {
              final result = await Future.value(
                runtime.execute(
                  source: '''
import 'dart:isolate';
dynamic main(Uri source, SendPort signal, SendPort exits) {
  return Isolate.spawnUri(source, <String>[], signal, onExit: exits);
}
''',
                  positionalArgs: [script.uri, signal.sendPort, exits.sendPort],
                ),
              );
              if (result is Isolate) nativeWorker = result;
            } catch (error) {
              rejection = unwrapScriptError(error);
            }
            expect(rejection, isA<UnsupportedError>());
            expect('$rejection', contains('Isolate.spawnUri is unsupported'));
            await Future<void>.delayed(const Duration(milliseconds: 50));
            expect(seen, isEmpty);
            expect(nativeWorker, isNull);
          } finally {
            nativeWorker?.kill(priority: Isolate.immediate);
            if (nativeWorker != null) {
              await exits.first.timeout(const Duration(seconds: 8));
            }
            signal.close();
            exits.close();
          }
        }
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
  );
}
