import pathlib, sys
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps')

cases = {
'runtimeType_print': '''void main() {
  final a = 20;
  print(a.runtimeType);
}
''',
'runtimeType_compare': '''void main() {
  final a = 20;
  print(a.runtimeType == int);
  print(a.runtimeType.toString());
}
''',
'set_toSet': '''void main() {
  final s = <int>{1, 2, 2, 3, 3, 3}.toSet();
  print(s);
  print(s.length);
}
''',
'set_literal': '''void main() {
  final s = <int>{1, 2, 2, 3};
  print(s);
  print(s.length);
}
''',
'map_update': '''void main() {
  final counts = <String, int>{'a': 1};
  counts.update('a', (v) => v + 1, ifAbsent: () => 0);
  counts.update('b', (v) => v + 1, ifAbsent: () => 0);
  print(counts);
}
''',
'map_putIfAbsent': '''void main() {
  final m = <String, int>{};
  m.putIfAbsent('x', () => 1);
  print(m);
}
''',
'continue_plain': '''void main() {
  for (var i = 0; i < 5; i++) {
    if (i == 2) {
      continue;
    }
    print('c\$i');
  }
}
''',
'continue_label': '''void main() {
  outer:
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (j == 1) {
        continue outer;
      }
      print('\$i\$j');
    }
  }
}
''',
'break_label': '''void main() {
  outer:
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (j == 1) {
        break outer;
      }
      print('\$i\$j');
    }
  }
}
''',
'switch_expr': '''void main() {
  final v = 3;
  final r = switch (v) { 1 => 'a', _ => 'other' };
  print(r);
}
''',
'switch_stmt': '''void main() {
  final v = 3;
  String r;
  switch (v) {
    case 1:
      r = 'a';
      break;
    default:
      r = 'other';
  }
  print(r);
}
''',
'generic_fn': '''T id<T>(T v) => v;

void main() {
  print(id(1));
  print(id('s'));
}
''',
'generic_class': '''class Box<T> {
  Box(this.value);
  final T value;
  T get() => value;
}

void main() {
  print(Box<int>(3).get());
  print(Box<String>('x').get());
}
''',
'generic_extends': '''class Box<T extends num> {
  Box(this.value);
  final T value;
}

void main() {
  print(Box<int>(3).value);
}
''',
'enum_values': '''enum P { low, high }

void main() {
  print(P.values.length);
  print(P.low.name);
  print(P.low.index);
}
''',
'enum_basic': '''enum P { low, high }

void main() {
  print(P.low);
  print(P.high.toString());
}
''',
'record_pos': '''void main() {
  final r = (1, 2);
  print(r.\$1);
  print(r.\$2);
}
''',
'record_named': '''void main() {
  final r = (a: 1, b: 'x');
  print(r.a);
  print(r.b);
}
''',
'mixin': '''mixin M {
  int get doubled => 2;
}

class C with M {}

void main() {
  print(C().doubled);
}
''',
'num_to_double': '''double half(int v) => v / 2;

void main() {
  print(half(3));
}
''',
'unawaited': '''void main() async {
  unawaited(Future<int>.value(1));
  print('ok');
}
''',
'getter_override': '''class A {
  int get x => 1;
  int get name => 10;
}

class B extends A {
  @override
  int get x => 2;
}

void main() {
  final b = B();
  print(b.x);
  print(b.name);
}
''',
'pattern_if_case': '''void main() {
  final Object value = 42;
  if (value case int n) {
    print('int \$n');
  }
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
