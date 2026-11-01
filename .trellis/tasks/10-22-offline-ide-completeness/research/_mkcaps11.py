import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps11')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
'local_fn_closure_mutate': '''void main() {
  var passed = 0;

  void check() {
    passed++;
  }

  check();
  check();
  print(passed);
}
''',
'local_fn_param': '''void main() {
  void check(void Function() body) {
    body();
  }

  check(() => print('a'));
}
''',
'top_fn_object_param': '''void expectEquals(Object? actual, Object? expected, String label) {
  print(actual == expected);
  print(label);
}

void main() {
  expectEquals(1 + 1, 2, 'add');
}
''',
'field_fn_type': '''class TestCase {
  TestCase(this.name, this.body);
  final String name;
  final void Function() body;
}

void main() {
  final c = TestCase('a', () => print('run'));
  print(c.name);
}
''',
'field_fn_type_call': '''class TestCase {
  TestCase(this.name, this.body);
  final String name;
  final void Function() body;
}

void main() {
  final c = TestCase('a', () => print('run'));
  c.body();
}
''',
'list_of_testcase': '''class TestCase {
  TestCase(this.name);
  final String name;
}

void runGroup(String title, List<TestCase> cases) {
  print('$title ${cases.length}');
}

void main() {
  runGroup('m', <TestCase>[TestCase('a')]);
}
''',
'fn_param_in_class': '''class Runner {
  Runner(this.body);
  final void Function() body;
  void run() {
    body();
  }
}

void main() {
  Runner(() => print('x')).run();
}
''',
'closure_noop': '''void main() {
  final f = () => print('a');
  f();
}
''',
'list_last_field': '''void main() {
  print([1, 2, 3].last);
}
''',
'string_length_eq': '''void main() {
  print('ab'.length == 2);
}
''',
'set_of_const_same': '''class Point {
  const Point(this.x, this.y);
  final int x;
  final int y;
  @override
  bool operator ==(Object other) => other is Point && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

void main() {
  final s = <Point>{};
  s.add(const Point(1, 2));
  s.add(const Point(1, 2));
  s.add(const Point(3, 4));
  print(s.length);
  print(s.contains(const Point(1, 2)));
}
''',
'set_of_int_literal': '''void main() {
  final s = <int>{1, 1, 2};
  print(s.length);
  print(s.contains(1));
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
