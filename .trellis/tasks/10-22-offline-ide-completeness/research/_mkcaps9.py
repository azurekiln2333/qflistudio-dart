import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps9')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
# --- operator overload variants (lesson 044)
'op_plus_block': '''class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec operator +(Vec other) {
    return Vec(x + other.x, y + other.y);
  }
  @override
  String toString() => '($x, $y)';
}

void main() {
  print(const Vec(1, 2) + const Vec(3, 4));
}
''',
'op_plus_no_tostring': '''class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec operator +(Vec other) => Vec(x + other.x, y + other.y);
}

void main() {
  final v = const Vec(1, 2) + const Vec(3, 4);
  print(v.x);
  print(v.y);
}
''',
'op_plus_method_equivalent': '''class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec add(Vec other) => Vec(x + other.x, y + other.y);
  @override
  String toString() => '($x, $y)';
}

void main() {
  print(const Vec(1, 2).add(const Vec(3, 4)));
}
''',
'eq_override_set': '''class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

void main() {
  final a = const Vec(1, 2);
  print(a == const Vec(1, 2));
  print({a, const Vec(1, 2)}.length);
}
''',
'eq_plus_hash_simple': '''class P {
  const P(this.v);
  final int v;
  @override
  bool operator ==(Object o) => o is P && o.v == v;
  @override
  int get hashCode => v;
}

void main() {
  print(<P>{const P(1), const P(1)}.length);
}
''',
# --- enum (045/046)
'enum_values_simple': '''enum P { low, high }

void main() {
  print(P.values.length);
}
''',
'enum_name_simple': '''enum P { low, high }

void main() {
  print(P.low.name);
  print(P.low.index);
}
''',
'enum_enhanced_no_values': '''enum Priority {
  low(1, 'a'),
  high(3, 'b');

  const Priority(this.level, this.label);
  final int level;
  final String label;
}

void main() {
  print(Priority.high.label);
  print(Priority.high.level);
}
''',
'enum_enhanced_tostring': '''enum Priority {
  low(1),
  high(3);

  const Priority(this.level);
  final int level;
}

void main() {
  print(Priority.high);
}
''',
'enum_iterate_manual': '''enum Priority { low, medium, high }

void main() {
  print(Priority.low);
  print(Priority.medium);
  print(Priority.high);
}
''',
# --- class via const constructor list
'list_of_subtypes_iter': '''abstract class Shape {
  Shape();
  double area();
}

class Sq extends Shape {
  Sq(this.s);
  final double s;
  @override
  double area() => s * s;
}

void main() {
  for (final s in <Shape>[Sq(2)]) {
    print(s.area());
  }
}
''',
# --- generics fallbacks
'generic_runtime_check': '''class IntBox {
  IntBox(this.value);
  final int value;
}

void main() {
  print(IntBox(3).value);
}
''',
'generic_void_fn': '''void printIt(Object v) => print(v);

void main() {
  printIt(1);
  printIt('s');
}
''',
'generic_inference_site': '''class Box<T> {
  Box(this.value);
  final T value;
}

void main() {
  print(Box<int>(3).value);
}
''',
'generic_typedef': '''typedef Mapper = int Function(int);

void main() {
  const Mapper m = _inc;
  print(m(1));
}

int _inc(int v) => v + 1;
''',
'generic_typedef_alias': '''typedef IntPair = (int, int);

void main() {
  final p = (1, 2);
  print(p.$1);
}
''',
'func_type_var': '''void main() {
  int Function(int) f = (v) => v + 1;
  print(f(1));
}
''',
'func_type_list': '''void main() {
  final List<int Function(int)> fs = [(v) => v + 1];
  print(fs.first(1));
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
