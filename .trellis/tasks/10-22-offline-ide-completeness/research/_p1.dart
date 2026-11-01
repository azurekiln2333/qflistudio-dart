void main() {
  // 1. runtimeType of int
  final a = 20;
  print(a.runtimeType);
  // 2. Type object printing directly
  print(a.runtimeType == int);
  // 3. Set literal via from
  final s = <int>{1, 2, 3, 2};
  print(s);
  print(s.length);
  // 4. Set toList of iterable to set
  print(<int>{1, 2, 2, 3, 3, 3}.toSet());
  // 5. Map.update
  final counts = <String, int>{'a': 1};
  counts.update('a', (v) => v + 1, ifAbsent: () => 0);
  counts.update('b', (v) => v + 1, ifAbsent: () => 0);
  print(counts);
  // 6. putIfAbsent
  final m = <String, int>{};
  m.putIfAbsent('x', () => 1);
  print(m);
  // 7. continue in for
  for (var i = 0; i < 5; i++) {
    if (i == 2) continue;
    print('c$i');
  }
}
