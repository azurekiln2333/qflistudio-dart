void main() {
  final m = {'a': 1};
  print(m.entries.map((e) => '${e.key}=${e.value}').toList());
}
