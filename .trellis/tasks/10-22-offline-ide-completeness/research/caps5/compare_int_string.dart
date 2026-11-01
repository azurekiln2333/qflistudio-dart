void main() {
  final m = {'a': 1, 'b': 2};
  final keys = m.keys.toList()..sort();
  print(keys);
  print(m.entries.map((e) => '\${e.key}=\${e.value}').toList());
}
