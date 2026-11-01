import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps4')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
'override_method_explicit_ctor': '''class A {
  A();
  int f() => 1;
}

class B extends A {
  B();
  int f() => 2;
}

void main() {
  print(B().f());
}
''',
'subclass_explicit_ctor': '''class A {
  A();
  int f() => 1;
}

class B extends A {
  B();
  int g() => 2;
}

void main() {
  final b = B();
  print(b.f());
  print(b.g());
}
''',
'super_explicit_noargs': '''class A {
  A();
}

class B extends A {
  B() : super();
}

void main() {
  print('ok');
}
''',
'abstract_impl_explicit': '''abstract class Shape {
  Shape();
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
'abstract_impl_super': '''abstract class Shape {
  Shape(this.name);
  final String name;
  double area();
}

class Sq extends Shape {
  Sq(this.s) : super('sq');
  final double s;
  double area() => s * s;
}

void main() {
  final q = Sq(3);
  print(q.name);
  print(q.area());
}
''',
'no_super_ctor_impl': '''class A {
  int f() => 1;
}

void main() {
  print(A().f());
}
''',
'no_explicit_ctor_extends': '''class A {
  int f() => 1;
}

class B extends A {}

void main() {
  print(B().f());
}
''',
'super_method_explicit': '''class A {
  A();
  int f() => 1;
}

class B extends A {
  B();
  int f() => 2;
  int g() => super.f() + f();
}

void main() {
  print(B().g());
}
''',
'super_field_explicit': '''class A {
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
'positional_super_param': '''class A {
  A(this.x);
  final int x;
}

class B extends A {
  B(int x) : super(x);
}

void main() {
  print(B(5).x);
}
''',
'inside_instantiate_super': '''class A {
  A(this.x);
  final int x;
}

class B extends A {
  B(int x) : super(x);
  int get doubled => x * 2;
}

void main() {
  final b = B(5);
  print(b.x);
  print(b.doubled);
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
