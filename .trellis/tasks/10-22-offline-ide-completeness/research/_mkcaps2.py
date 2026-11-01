import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps2')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
# ---------- basics 005: conversions
'int_parse': '''void main() {
  final n = int.parse('42');
  print(n + 1);
  print(double.parse('19.9') * 2);
  print((1 / 3).toStringAsFixed(3));
  print(255.toString());
  final bad = int.tryParse('abc');
  print(bad == null ? 'fail' : bad);
}
''',
'num_tryparse_null': '''void main() {
  final bad = int.tryParse('abc');
  print(bad == null);
}
''',
# ---------- control 013: switch expr over string
'switch_expr_string': '''void main() {
  final c = 'b';
  print(switch (c) { 'a' => 1, 'b' => 2, _ => 0 });
}
''',
# ---------- control 015 / nullsafety: casts
'cast_string_instance': '''class P {
  P(this.name);
  final String name;
}

void main() {
  final Object o = P('x');
  final p = o as P;
  print(p.name);
}
''',
'cast_string_value': '''void main() {
  final dynamic d = 'hello';
  final s = d as String;
  print(s.length);
}
''',
'null_assert_chain': '''class Node {
  Node(this.next);
  final Node? next;
}

void main() {
  final n = Node(Node(null));
  print(n.next!.next == null);
}
''',
'null_assert_value': '''void main() {
  String? s = 'abc';
  print(s!.length);
}
''',
'null_coalesce_num': '''void main() {
  int? a;
  print((a ?? 0) + 1);
  num? b;
  print(b ?? 5);
}
''',
# ---------- oop
'getter_override_plain': '''class A {
  int get x => 1;
}

class B extends A {
  int get x => 2;
}

void main() {
  print(B().x);
}
''',
'field_getter_named_x': '''class A {
  int get x => 1;
  String get name => 'n';
}

void main() {
  final a = A();
  print(a.x);
  print(a.name);
}
''',
'abstract_class': '''abstract class Shape {
  double area();
}

class Sq extends Shape {
  Sq(this.s);
  final double s;
  double area() => s * s;
}

void main() {
  print(Sq(3).area());
}
''',
'implements': '''abstract class Named {
  String get name;
}

class P implements Named {
  @override
  String get name => 'p';
}

void main() {
  print(P().name);
}
''',
'interface_default': '''class A {
  int f() => 1;
}

class B extends A {
  int f() => 2;
}

void main() {
  print(B().f());
  print((A() as A).f());
}
''',
# ---------- exceptions
'catch_custom_message': '''class MyErr implements Exception {
  MyErr(this.message);
  final String message;
}

void main() {
  try {
    throw MyErr('boom');
  } catch (e) {
    print((e as MyErr).message);
  }
}
''',
'catch_custom_tostring': '''class MyErr implements Exception {
  MyErr(this.message);
  final String message;
  @override
  String toString() => 'MyErr: \$message';
}

void main() {
  try {
    throw MyErr('boom');
  } catch (e) {
    print(e);
  }
}
''',
'catch_two_types': '''void main() {
  try {
    final list = <int>[];
    print(list[5]);
  } on RangeError catch (e) {
    print('range');
  } on Object catch (e) {
    print('other');
  }
}
''',
'catch_state_error': '''void main() {
  try {
    throw StateError('bad');
  } on StateError catch (e) {
    print(e.message);
  }
}
''',
'finally_runs': '''void main() {
  try {
    throw Exception('x');
  } catch (e) {
    print('caught');
  } finally {
    print('finally');
  }
}
''',
'rethrow_stmt': '''void main() {
  try {
    try {
      throw Exception('inner');
    } catch (e) {
      print('inner caught');
      rethrow;
    }
  } catch (e) {
    print('outer caught');
  }
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
