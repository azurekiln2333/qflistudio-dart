import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps5')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
# ---- async
'future_delayed': '''Future<void> main() async {
  final v = await Future<int>.delayed(Duration(milliseconds: 10), () => 1);
  print(v);
}
''',
'future_value': '''Future<void> main() async {
  final v = await Future<int>.value(1);
  print(v);
}
''',
'future_wait': '''Future<void> main() async {
  final vs = await Future.wait([Future<int>.value(1), Future<int>.value(2)]);
  print(vs);
}
''',
'future_then': '''void main() {
  Future<int>.value(1).then((v) => print(v));
}
''',
'future_catchError': '''void main() {
  Future<int>.error(StateError('x')).catchError((Object e) => 0).then(print);
}
''',
'future_timeout': '''Future<void> main() async {
  try {
    await Future<int>.delayed(Duration(seconds: 1), () => 1)
        .timeout(const Duration(milliseconds: 10));
  } on Object {
    print('timeout');
  }
}
''',
'async_star_drain': '''Stream<int> gen() async* {
  yield 1;
  yield 2;
}

Future<void> main() async {
  await for (final v in gen()) {
    print(v);
  }
}
''',
'sync_star': '''Iterable<int> gen() sync* {
  yield 1;
  yield 2;
}

void main() {
  print(gen().toList());
}
''',
'is_negative_state': '''Future<void> main() async {
  final c = Completer<int>();
  print(c.isCompleted);
  c.complete(1);
  print(await c.future);
}
''',
# ---- streams
'stream_from_iterable': '''Future<void> main() async {
  await for (final v in Stream<int>.fromIterable([1, 2])) {
    print(v);
  }
}
''',
'stream_map_await': '''Future<void> main() async {
  await for (final v in Stream<int>.fromIterable([1, 2]).map((e) => e * 2)) {
    print(v);
  }
}
''',
'stream_controller': '''import 'dart:async';

Future<void> main() async {
  final c = StreamController<int>();
  c.add(1);
  await c.close();
  await for (final v in c.stream) {
    print(v);
  }
}
''',
'stream_sub_listen': '''void main() {
  Stream<int>.fromIterable([1, 2]).listen(print);
}
''',
'stream_first': '''Future<void> main() async {
  final v = await Stream<int>.fromIterable([5, 6]).first;
  print(v);
}
''',
'stream_toList': '''Future<void> main() async {
  final vs = await Stream<int>.fromIterable([1, 2, 3]).toList();
  print(vs);
}
''',
'stream_where': '''Future<void> main() async {
  final vs = await Stream<int>.fromIterable([1, 2, 3])
      .where((e) => e.isOdd)
      .toList();
  print(vs);
}
''',
# ---- json
'json_decode_basic': '''import 'dart:convert';

void main() {
  final m = jsonDecode('{"a":1}') as Map<String, dynamic>;
  print(m['a']);
}
''',
'json_decode_en': '''import 'dart:convert';

void main() {
  final s = jsonEncode({'a': 1});
  print(s);
  print(jsonDecode(s));
}
''',
'json_decode_utf8': '''import 'dart:convert';

void main() {
  final m = jsonDecode('{"name":"\\u5c0f\\u660e"}') as Map<String, dynamic>;
  print(m['name']);
}
''',
'json_decode_chinese': '''import 'dart:convert';

void main() {
  final m = jsonDecode('{"name":"\u5c0f\u660e"}') as Map<String, dynamic>;
  print(m['name']);
}
''',
'json_decode_list': '''import 'dart:convert';

void main() {
  final l = jsonDecode('[1,2,3]') as List<dynamic>;
  print(l.length);
  print(l.first);
}
''',
'json_encode_fixed': '''import 'dart:convert';

void main() {
  print(jsonEncode(<String, Object?>{'n': 1, 's': 'a'}));
}
''',
# ---- io
'file_write_read': '''import 'dart:io';

void main() {
  final f = File('tmp_probe.txt');
  f.writeAsStringSync('hello');
  print(f.readAsStringSync());
  f.deleteSync();
}
''',
'directory_systemTemp': '''import 'dart:io';

void main() {
  print(Directory.systemTemp.path.isNotEmpty);
}
''',
'file_relative_temp': '''import 'dart:io';

void main() {
  final d = Directory('tmp_probe_dir')..createSync();
  final f = File('\${d.path}/a.txt')..writeAsStringSync('x');
  print(f.readAsStringSync());
  d.deleteSync(recursive: true);
}
''',
'file_lines': '''import 'dart:io';

void main() {
  final f = File('tmp_lines.txt')..writeAsStringSync('a\\nb\\n');
  print(f.readAsLinesSync());
  f.deleteSync();
}
''',
'exists_sync': '''import 'dart:io';

void main() {
  final f = File('tmp_exists.txt');
  print(f.existsSync());
  f.writeAsStringSync('x');
  print(f.existsSync());
  f.deleteSync();
}
''',
'file_length': '''import 'dart:io';

void main() {
  final f = File('tmp_len.txt')..writeAsStringSync('abc');
  print(f.lengthSync());
  f.deleteSync();
}
''',
# ---- misc
'string_buffer_write': '''void main() {
  final b = StringBuffer();
  b.write('a');
  b.writeln('b');
  print(b.toString().trim());
}
''',
'sort_compareto': '''void main() {
  final l = ['b', 'a'];
  l.sort();
  print(l);
  final n = [3, 1, 2]..sort();
  print(n);
}
''',
'fold_reduce': '''void main() {
  print([1, 2, 3].reduce((a, b) => a + b));
  print([1, 2, 3].fold<int>(0, (a, b) => a + b));
}
''',
'list_map_where': '''void main() {
  final l = [1, 2, 3, 4];
  print(l.where((e) => e.isEven).toList());
  print(l.map((e) => e * 2).toList());
}
''',
'compare_int_string': '''void main() {
  final m = {'a': 1, 'b': 2};
  final keys = m.keys.toList()..sort();
  print(keys);
  print(m.entries.map((e) => '\${e.key}=\${e.value}').toList());
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
