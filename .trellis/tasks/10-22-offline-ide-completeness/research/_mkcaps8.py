import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps8')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
# 036: `double fahrenheit => celsius*9/5+32` returns num in eval
'036_as_int_div': '''class Temperature {
  Temperature.celsius(this.celsius);
  Temperature.fahrenheit(double fahrenheit)
      : celsius = (fahrenheit - 32) * 5 / 9;

  final double celsius;

  double get fahrenheit => celsius * 9 / 5 + 32;
}

void main() {
  final a = Temperature.celsius(25);
  print(a.fahrenheit.toStringAsFixed(1));
  final b = Temperature.fahrenheit(77);
  print(b.celsius.toStringAsFixed(1));
}
''',
'036_double_literals': '''class Temperature {
  Temperature.celsius(this.celsius);
  Temperature.fahrenheit(double fahrenheit)
      : celsius = (fahrenheit - 32) * 5 / 9;

  final double celsius;

  double get fahrenheit => celsius * 9.0 / 5.0 + 32.0;
}

void main() {
  final a = Temperature.celsius(25);
  print(a.fahrenheit.toStringAsFixed(1));
  final b = Temperature.fahrenheit(77);
  print(b.celsius.toStringAsFixed(1));
}
''',
'036_getter_plain_fn': '''double toFahrenheit(double celsius) => celsius * 9.0 / 5.0 + 32.0;

void main() {
  print(toFahrenheit(25).toStringAsFixed(1));
}
''',
# 038: static field read from instance method
'038_static_basic': '''class Counter {
  static int total = 0;
  Counter(this.label) {
    total++;
  }
  final String label;
}

void main() {
  Counter('a');
  Counter('b');
  print(Counter.total);
}
''',
'038_static_in_static_method': '''class Counter {
  static int total = 0;
  static String describe() => 'count';
}

void main() {
  print(Counter.describe());
}
''',
'038_static_interp_in_static': '''class Counter {
  static int total = 2;
  static String describe() => 'n=$total';
}

void main() {
  print(Counter.describe());
}
''',
# 040: abstract + implicit super ctor (already known) + describe default method
'040_explicit_ctor': '''abstract class Shape {
  Shape();
  double area();
  String describe() => 'area=${area().toStringAsFixed(2)}';
}

class Circle extends Shape {
  Circle(this.radius);
  final double radius;
  @override
  double area() => 3.14159 * radius * radius;
}

class Square extends Shape {
  Square(this.side);
  final double side;
  @override
  double area() => side * side;
}

void main() {
  for (final shape in [Circle(2), Square(3)]) {
    print(shape.describe());
  }
}
''',
# 044: operator overload + Set with value equality
'044_operator_plus': '''class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec operator +(Vec other) => Vec(x + other.x, y + other.y);
  @override
  String toString() => '($x, $y)';
}

void main() {
  final a = const Vec(1, 2);
  final b = const Vec(3, 4);
  print(a + b);
}
''',
'044_eq_no_hash': '''class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;
}

void main() {
  print(const Vec(1, 2) == const Vec(1, 2));
}
''',
'044_hash': '''void main() {
  print(Object.hash(1, 2) == Object.hash(1, 2));
}
''',
# 045: enum with fields/values/name
'045_enum_simple': '''enum Priority { low, medium, high }

void main() {
  print(Priority.values.length);
  print(Priority.high.name);
}
''',
'045_enum_tostring': '''enum Priority { low, medium, high }

void main() {
  for (final p in Priority.values) {
    print(p);
  }
}
''',
# 046: getter on enum .name, List.unmodifiable, cascade
'046_cascade': '''class A {
  A();
  int v = 0;
  void add(int x) {
    v += x;
  }
}

void main() {
  final a = A()
    ..add(1)
    ..add(2);
  print(a.v);
}
''',
'046_list_unmodifiable': '''void main() {
  final l = List<int>.unmodifiable([1, 2]);
  print(l);
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
