import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps3')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
# --- int.parse variants
'int_parse_only': '''void main() {
  print(int.parse('42'));
}
''',
'int_parse_plus': '''void main() {
  print(int.parse('42') + 1);
}
''',
'int_parse_var': '''void main() {
  final n = int.parse('42');
  print(n);
}
''',
'double_parse_only': '''void main() {
  print(double.parse('19.9'));
}
''',
'double_parse_mul': '''void main() {
  final p = double.parse('19.9');
  print(p * 2);
}
''',
'num_parse_int': '''void main() {
  print(num.parse('42'));
}
''',
# --- override narrowing
'override_method': '''class A {
  int f() => 1;
}

class B extends A {
  int f() => 2;
}

void main() {
  print(B().f());
}
''',
'override_method_no_ann': '''class A {
  int f() => 1;
}

class B extends A {
  int g() => 2;
}

void main() {
  print(B().g());
}
''',
'override_tostring': '''class P {
  P(this.n);
  final int n;
  @override
  String toString() => 'P(\$n)';
}

void main() {
  print(P(1));
}
''',
'override_tostring_noann': '''class P {
  P(this.n);
  final int n;
  String toString() => 'P';
}

void main() {
  print(P(1));
}
''',
'subclass_no_override': '''class A {
  int f() => 1;
}

class B extends A {
  int g() => 2;
}

void main() {
  final b = B();
  print(b.f());
  print(b.g());
}
''',
'override_field': '''class A {
  A(this.x);
  int x;
}

class B extends A {
  B(super.x);
}

void main() {
  print(B(5).x);
}
''',
'super_method': '''class A {
  int f() => 1;
}

class B extends A {
  int f() => 2;
  int g() => super.f() + f();
}

void main() {
  print(B().g());
}
''',
# --- abstract variations
'abstract_iface_impl_ann': '''abstract class Shape {
  double area();
}

class Sq implements Shape {
  Sq(this.s);
  final double s;
  @override
  double area() => s * s;
}

void main() {
  print(Sq(3).area());
}
''',
'abstract_concrete_method': '''abstract class Shape {
  double area() => 0;
}

class Sq extends Shape {}

void main() {
  print(Sq().area());
}
''',
'abstract_two_levels': '''abstract class A {
  int f();
}

abstract class B extends A {}

class C extends B {
  int f() => 3;
}

void main() {
  print(C().f());
}
''',
# --- range errors
'list_index_oor': '''void main() {
  final l = <int>[1, 2, 3];
  try {
    print(l[5]);
  } catch (e) {
    print(e.runtimeType);
  }
}
''',
'list_index_oor_catch': '''void main() {
  final l = <int>[1, 2, 3];
  try {
    print(l[5]);
  } on RangeError {
    print('range');
  } catch (e) {
    print('other');
  }
}
''',
'string_index_oor': '''void main() {
  try {
    print('abc'[5]);
  } catch (e) {
    print('caught');
  }
}
''',
'error_message': '''void main() {
  try {
    throw StateError('bad');
  } catch (e) {
    print(e is StateError);
    print(e is Object);
  }
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
