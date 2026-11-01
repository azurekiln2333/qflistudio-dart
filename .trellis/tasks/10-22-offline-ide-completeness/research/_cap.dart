// ==== runtimeType-print
void main() {
  final a = 20;
  print(a.runtimeType);
}
// ==== runtimeType-eq
void main() {
  final a = 20;
  print(a.runtimeType == int);
  print(a.runtimeType.toString());
}
// ==== set-toSet
void main() {
  final s = <int>{1, 2, 2, 3, 3, 3}.toSet();
  print(s);
  print(s.length);
}
// ==== set-literal
void main() {
  final s = <int>{1, 2, 2, 3};
  print(s);
  print(s.length);
}
// ==== map-update
void main() {
  final counts = <String, int>{'a': 1};
  counts.update('a', (v) => v + 1, ifAbsent: () => 0);
  counts.update('b', (v) => v + 1, ifAbsent: () => 0);
  print(counts);
}
// ==== map-putIfAbsent
void main() {
  final m = <String, int>{};
  m.putIfAbsent('x', () => 1);
  print(m);
}
// ==== continue
void main() {
  for (var i = 0; i < 5; i++) {
    if (i == 2) continue;
    print('c$i');
  }
}
// ==== labelled-continue
void main() {
  outer:
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (j == 1) continue outer;
      print('$i$j');
    }
  }
}
// ==== switch-expr
void main() {
  final v = 3;
  final r = switch (v) { 1 => 'a', _ => 'other' };
  print(r);
}
// ==== generic-fn
T id<T>(T v) => v;
void main() {
  print(id(1));
  print(id('s'));
}
// ==== generic-class
class Box<T> {
  Box(this.value);
  final T value;
  T get() => value;
}
void main() {
  print(Box<int>(3).get());
  print(Box<String>('x').get());
}
// ==== enum-values
enum P { low, high }
void main() {
  print(P.values.length);
  print(P.low.name);
  print(P.low.index);
}
// ==== enum-basic
enum P { low, high }
void main() {
  print(P.low);
  print(P.high.toString());
}
// ==== record
void main() {
  final r = (1, 2);
  print(r.$1);
  print(r.$2);
}
// ==== record-named
void main() {
  final r = (a: 1, b: 'x');
  print(r.a);
  print(r.b);
}
// ==== mixin
mixin M {
  int get doubled => 2;
}
class C with M {}
void main() {
  print(C().doubled);
}
// ==== num-to-double
double half(int v) => v / 2;
void main() {
  print(half(3));
}
// ==== unawaited
void main() async {
  unawaited(Future<int>.value(1));
  print('ok');
}
