@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/native_dart_toolchain.dart';

import '../tool/portable_content_runner.dart';

void main() {
  late Directory directory;
  late String sdk;

  setUpAll(() async {
    sdk = await const NativeDartToolchain().resolveExecutable();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'portable_async_semantics_',
    );
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<void> matchesSdk(String source, String expected) async {
    final file = File(p.join(directory.path, 'main.dart'));
    await file.writeAsString(source);
    final process = await Process.start(sdk, ['--enable-asserts', file.path]);
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    try {
      expect(
        await process.exitCode.timeout(const Duration(seconds: 12)),
        0,
        reason: await stderr,
      );
      expect((await stdout).replaceAll('\r\n', '\n'), expected);
    } finally {
      process.kill();
      await process.exitCode;
    }
    final portable = await runPortableContent(source);
    expect(portable.error, isNull);
    expect(portable.output, expected);
  }

  test('async prefix runs before its caller continues', () async {
    await matchesSdk(r'''
Future<void> stage() async {
  print('阶段开始');
  await Future<void>.delayed(Duration.zero);
  print('阶段结束');
}
Future<void> main() async {
  final pending = stage();
  print('调用方继续');
  await pending;
  print('全部完成');
}
''', '阶段开始\n调用方继续\n阶段结束\n全部完成\n');
  });

  test('nested async prefixes restore the outer execution frame', () async {
    await matchesSdk(
      r'''
Future<void> inner(String value) async {
  print('inner:$value');
  await Future<void>.value();
  print('inner resumed:$value');
}
Future<void> outer(String value) async {
  print('outer:$value');
  final pending = inner('child');
  print('outer before await:$value');
  await pending;
  print('outer resumed:$value');
}
Future<void> main() async {
  final pending = outer('parent');
  print('caller');
  await pending;
  print('finished');
}
''',
      'outer:parent\ninner:child\nouter before await:parent\ncaller\n'
          'inner resumed:child\nouter resumed:parent\nfinished\n',
    );
  });

  test('async methods and closures perform immediate side effects', () async {
    await matchesSdk(
      r'''
class Worker {
  int started = 0;
  Future<void> run() async {
    started++;
    print('method starts');
    await 1;
    print('method resumes');
  }
}
Future<void> main() async {
  final worker = Worker();
  var closureStarted = false;
  final callback = () async {
    closureStarted = true;
    print('closure starts');
    await 2;
    print('closure resumes');
  };
  final method = worker.run();
  final closure = callback();
  print('caller:${worker.started}:$closureStarted');
  await method;
  await closure;
}
''',
      'method starts\nclosure starts\ncaller:1:true\nmethod resumes\nclosure resumes\n',
    );
  });

  test('async bodies without await run now but listeners run later', () async {
    await matchesSdk(
      r'''
int recordArrow() { print('arrow body'); return 5; }
Future<int> arrow() async => recordArrow();
Future<int> immediate() async { print('block body'); return 3; }
Future<void> main() async {
  final first = immediate();
  final second = arrow();
  print('caller');
  first.then((value) => print('listener:$value'));
  print('listener installed');
  print('first:${await first}');
  print('second:${await second}');
}
''',
      'block body\narrow body\ncaller\nlistener installed\nlistener:3\nfirst:3\nsecond:5\n',
    );
  });

  test(
    'a prefix exception completes its Future instead of escaping the call',
    () async {
      await matchesSdk(r'''
Future<void> fail() async { print('throwing'); throw StateError('boom'); }
Future<void> invoke() {
  try {
    final pending = fail();
    print('returned Future');
    return pending;
  } catch (_) {
    print('synchronous catch');
    rethrow;
  }
}
Future<void> main() async {
  try { await invoke(); }
  on StateError { print('Future error caught'); }
}
''', 'throwing\nreturned Future\nFuture error caught\n');
    },
  );

  test(
    'catch and finally before the first await stay in the synchronous prefix',
    () async {
      await matchesSdk(r'''
Future<void> guarded() async {
  try { print('try'); throw StateError('expected'); }
  on StateError { print('catch'); }
  finally { print('finally'); }
  print('before await');
  await 0;
  print('after await');
}
Future<void> main() async {
  final pending = guarded();
  print('caller');
  await pending;
}
''', 'try\ncatch\nfinally\nbefore await\ncaller\nafter await\n');
    },
  );

  test(
    'repeated synchronous error transitions do not recurse or yield',
    () async {
      await matchesSdk(r'''
Future<int> countCaught() async {
  var total = 0;
  for (var i = 0; i < 2000; i++) {
    try { throw StateError('count'); }
    on StateError { total++; }
  }
  print('prefix:$total');
  await 0;
  return total;
}
Future<void> main() async {
  final pending = countCaught();
  print('caller');
  print('result:${await pending}');
}
''', 'prefix:2000\ncaller\nresult:2000\n');
    },
  );

  test(
    'an already completed Future resumes in its scheduled microtask',
    () async {
      await matchesSdk(r'''
import 'dart:async';
Future<void> work() async {
  print('start');
  await Future<void>.value();
  print('resume');
}
Future<void> main() async {
  final pending = work();
  scheduleMicrotask(() => print('queued microtask'));
  print('caller');
  await pending;
}
''', 'start\ncaller\nresume\nqueued microtask\n');
    },
  );

  test(
    'awaiting an ordinary value still suspends before its continuation',
    () async {
      await matchesSdk(r'''
import 'dart:async';
Future<void> work() async {
  print('start');
  final value = await 7;
  print('resume:$value');
}
Future<void> main() async {
  final pending = work();
  scheduleMicrotask(() => print('queued microtask'));
  print('caller');
  await pending;
}
''', 'start\ncaller\nresume:7\nqueued microtask\n');
    },
  );

  test(
    'async generators remain lazy and start after subscription returns',
    () async {
      await matchesSdk(
        r'''
import 'dart:async';
Stream<int> values() async* {
  print('generator starts');
  yield 1;
  print('generator ends');
}
Future<void> main() async {
  final stream = values();
  print('created');
  final done = Completer<void>();
  stream.listen((value) => print('value:$value'), onDone: () => done.complete());
  print('subscribed');
  await done.future;
  print('finished');
}
''',
        'created\nsubscribed\ngenerator starts\nvalue:1\ngenerator ends\nfinished\n',
      );
    },
  );

  test('for-in resumes after awaiting its iterable directly', () async {
    await matchesSdk(r'''
Future<List<String>> traceTask(String id) async {
  final lines = <String>['$id:start'];
  await Future<void>.delayed(Duration.zero);
  lines.add('$id:end');
  return lines;
}
Future<void> main() async {
  for (final lines in await Future.wait([traceTask('X'), traceTask('Y')])) {
    print(lines.join(','));
  }
  print('loop finished');
}
''', 'X:start,X:end\nY:start,Y:end\nloop finished\n');
  });

  test('nested awaited for-in initializers replay once per entry', () async {
    await matchesSdk(r'''
var calls = 0;
Future<List<int>> items(int start) async {
  calls++;
  return [start, start + 1];
}
Future<void> main() async {
  for (var pass = 1; pass <= 2; pass++) {
    for (final item in await items(pass)) {
      if (item == pass) continue;
      await 0;
      print('pass:$pass item:$item');
    }
  }
  print('calls:$calls');
}
''', 'pass:1 item:2\npass:2 item:3\ncalls:2\n');
  });

  test(
    'for-in replays multiple awaits inside an iterable invocation',
    () async {
      await matchesSdk(r'''
var calls = 0;
Future<List<int>> items(int value) async { calls++; return [value]; }
List<int> combine(List<int> first, List<int> second) => [...first, ...second];
Future<void> main() async {
  var item = 0;
  for (item in combine(await items(2), await items(5))) print(item);
  for (final missing in await Future<List<int>>.value([])) print(missing);
  print('calls:$calls last:$item');
}
''', '2\n5\ncalls:2 last:5\n');
    },
  );

  test('await-for initializes an awaited stream only once', () async {
    await matchesSdk(r'''
import 'dart:async';
var calls = 0;
Future<Stream<int>> open() async {
  calls++;
  return Stream<int>.fromIterable([2, 4]);
}
Future<void> main() async {
  await for (final value in await open()) print(value);
  print('calls:$calls');
}
''', '2\n4\ncalls:1\n');
  });

  test(
    'an iterable await resumes before a separate await in its body',
    () async {
      await matchesSdk(r'''
Future<List<int>> items() async => [2, 5];
Future<String> describe(int item) async => 'item:$item';
Future<void> main() async {
  for (final item in await items()) print(await describe(item));
  print('finished');
}
''', 'item:2\nitem:5\nfinished\n');
    },
  );
}
