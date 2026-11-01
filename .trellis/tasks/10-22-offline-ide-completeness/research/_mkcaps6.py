import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps6')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
'interp_simple_var': '''void main() {
  final a = 1;
  print('v=$a');
}
''',
'interp_brace_var': '''void main() {
  final a = 1;
  print('v=${a}');
}
''',
'interp_brace_expr': '''void main() {
  final a = 1;
  print('v=${a + 1}');
}
''',
'interp_brace_prop': '''void main() {
  final s = 'abc';
  print('len=${s.length}');
}
''',
'interp_brace_two': '''void main() {
  final a = 1;
  final b = 2;
  print('${a}-${b}');
}
''',
'interp_brace_in_map': '''void main() {
  final m = {'a': 1};
  print(m.entries.map((e) => '${e.key}=${e.value}').toList());
}
''',
'interp_simple_in_map': '''void main() {
  final m = {'a': 1};
  print(m.entries.map((e) => 'k').toList());
}
''',
'interp_brace_list_index': '''void main() {
  final l = [1, 2];
  print('first=${l[0]}');
}
''',
'interp_brace_toString': '''void main() {
  final l = [1, 2];
  print('l=$l');
}
''',
'interp_nested_quote': '''void main() {
  final a = 'x';
  print('v=${a.length}');
}
''',
'list_join': '''void main() {
  print([1, 2, 3].join(', '));
  print([1, 2, 3].join());
}
''',
'map_entries_loop': '''void main() {
  final m = {'a': 1, 'b': 2};
  for (final e in m.entries) {
    print('${e.key}=${e.value}');
  }
}
''',
'map_keys_sorted_loop': '''void main() {
  final m = {'b': 2, 'a': 1};
  final keys = m.keys.toList()..sort();
  for (final k in keys) {
    print('$k=${m[k]}');
  }
}
''',
'set_operations': '''void main() {
  final a = <int>{1, 2, 3};
  final b = <int>{2, 3, 4};
  print(a.intersection(b));
  print(a.union(b));
  print(a.difference(b));
  print(a.contains(2));
}
''',
'set_add_remove': '''void main() {
  final s = <int>{1};
  s.add(2);
  s.remove(1);
  print(s);
  print(s.length);
}
''',
'list_sort_custom': '''void main() {
  final l = [3, 1, 2];
  l.sort((a, b) => b.compareTo(a));
  print(l);
}
''',
'list_where_tolist': '''void main() {
  final l = [1, 2, 3];
  print(l.where((e) => e > 1).toList());
  print(l.map((e) => e + 1).toList());
}
''',
'list_indexOf_contains': '''void main() {
  final l = ['a', 'b'];
  print(l.indexOf('b'));
  print(l.contains('a'));
}
''',
'list_sublist': '''void main() {
  final l = [1, 2, 3, 4];
  print(l.sublist(1, 3));
  print(l.reversed.toList());
}
''',
'map_containsKey': '''void main() {
  final m = {'a': 1};
  print(m.containsKey('a'));
  print(m.length);
  print(m['a']);
  print(m['z']);
}
''',
'string_ops': '''void main() {
  const s = 'Hello, Dart';
  print(s.toUpperCase());
  print(s.split(', '));
  print(s.contains('Dart'));
  print(s.startsWith('Hell'));
  print(s.substring(0, 5));
  print(s.trim());
  print(s.replaceAll('Dart', 'World'));
  print(s.padLeft(15, '.'));
}
''',
'string_compare': '''void main() {
  final l = ['b', 'a', 'c'];
  l.sort();
  print(l);
  print('a'.compareTo('b'));
}
''',
'num_ops': '''void main() {
  print(7 % 3);
  print((-7) % 3);
  print(7 ~/ 2);
  print(2.5.round());
  print(2.4.floor());
  print(2.1.ceil());
  print(3.14159.toStringAsFixed(2));
  print((-5).abs());
}
''',
'bigint_like_double': '''void main() {
  print(0.1 + 0.2);
  print((0.1 + 0.2).toStringAsFixed(1));
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
