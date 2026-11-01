import pathlib
base = pathlib.Path('.trellis/tasks/10-22-offline-ide-completeness/research/caps7')
base.mkdir(parents=True, exist_ok=True)
for f in base.glob('*.dart'):
    f.unlink()

cases = {
# 023: toSet prints as List in dart_eval
'toSet_print': '''void main() {
  final nums = [1, 2, 2, 3, 3, 3];
  final unique = nums.toSet();
  print(unique);
  print(unique.toList());
  print(unique.length);
}
''',
'toSet_literal_brace': '''void main() {
  final nums = [1, 2, 2, 3, 3, 3];
  final unique = <int>{...nums};
  print(unique);
  print(unique.length);
}
''',
'set_literal_typed': '''void main() {
  final a = <int>{1, 2, 3};
  final b = <int>{2, 3, 4};
  print(a);
  print(a.intersection(b));
  print(a.union(b));
  print(a.difference(b));
}
''',
# 026: spread / collection-if / collection-for / ...?
'spread_basic': '''void main() {
  final base = [1, 2, 3];
  print([0, ...base, 4]);
}
''',
'collection_if': '''void main() {
  const inc = true;
  print(['a', if (inc) 'b']);
}
''',
'collection_for': '''void main() {
  print([for (var i = 1; i <= 4; i++) i * i]);
}
''',
'spread_null_aware': '''void main() {
  final List<int>? maybe = null;
  print([...?maybe, 9]);
}
''',
# 027: update/putIfAbsent
'update_plain': '''void main() {
  final counts = {'a': 1};
  counts['a'] = counts['a']! + 10;
  print(counts);
}
''',
'update_ifabsent_plain': '''void main() {
  final counts = {'a': 1};
  if (!counts.containsKey('c')) {
    counts['c'] = 5;
  }
  print(counts);
}
''',
'map_map_entry': '''void main() {
  final counts = {'a': 1};
  final upper = counts.map((k, v) => MapEntry(k.toUpperCase(), v * 2));
  print(upper);
}
''',
'map_addall_keys': '''void main() {
  final counts = {'a': 1};
  counts.addAll({'d': 4});
  print(counts.keys.toList());
}
''',
}
for name, code in cases.items():
    (base / f'{name}.dart').write_text(code, encoding='utf-8')
print(len(cases))
