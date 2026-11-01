import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps10')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
'async_int': '''Future<int> v() async => 10;

Future<void> main() async {
  print(await v());
}
''',
'async_int_body': '''Future<int> v() async {
  return 10;
}

Future<void> main() async {
  print(await v());
}
''',
'await_plain': '''Future<void> main() async {
  await null;
  print('done');
}
''',
'future_runtimeType': '''Future<int> v() async => 10;

Future<void> main() async {
  print(v().runtimeType);
}
''',
'then_int': '''void main() {
  Future<int> v() async => 10;
  v().then((x) => print(x * 2));
}
''',
'then_void': '''Future<void> main() async {
  final f = <int>[1];
  await Future<void>.value().then((_) => print(f));
}
''',
'delayed_value': '''Future<void> main() async {
  final x = await Future<int>.delayed(Duration.zero, () => 42);
  print(x);
}
''',
'delayed_void': '''Future<void> main() async {
  await Future<void>.delayed(Duration.zero);
  print('after');
}
''',
'stateerror_message': '''void main() {
  try {
    throw StateError('计算失败');
  } on StateError catch (e) {
    print(e.message);
  }
}
''',
'stateerror_tostring': '''void main() {
  try {
    throw StateError('计算失败');
  } on StateError catch (e) {
    print(e);
  }
}
''',
'format_exception_message': '''void main() {
  try {
    throw const FormatException('msg');
  } on FormatException catch (e) {
    print(e.message);
  }
}
''',
'int_parse_throws': '''void main() {
  try {
    print(int.parse('abc'));
  } on FormatException catch (e) {
    print('fmt');
  }
}
''',
'range_error_catch': '''void main() {
  try {
    print(<int>[1, 2, 3][5]);
  } on RangeError catch (e) {
    print('range');
  }
}
''',
'stream_tolist_ctor': '''Future<void> main() async {
  final s = Stream<int>.fromIterable(<int>[1, 2, 3]);
  print(await s.toList());
}
''',
'stream_listen': '''Future<void> main() async {
  final out = <int>[];
  await Stream<int>.fromIterable(<int>[1, 2, 3]).forEach(out.add);
  print(out);
}
''',
'stream_first_ctor': '''Future<void> main() async {
  print(await Stream<int>.fromIterable(<int>[1, 2, 3]).first);
}
''',
'iterable_stream_tolist': '''void main() {
  final l = [1, 2, 3].toList();
  print(l);
  print(l.length);
}
''',
'continue_any': '''void main() {
  for (final v in [1, 2, 3]) {
    if (v == 2) continue;
    print(v);
  }
}
''',
'continue_while': '''void main() {
  var i = 0;
  while (i < 3) {
    i++;
    if (i == 2) continue;
    print(i);
  }
}
''',
'label_break': '''void main() {
  outer:
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 2; j++) {
      if (j == 1) break outer;
      print('$i$j');
    }
  }
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
