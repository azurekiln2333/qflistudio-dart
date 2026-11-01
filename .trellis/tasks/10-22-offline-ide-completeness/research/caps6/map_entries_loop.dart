void main() {
  final m = {'a': 1, 'b': 2};
  for (final e in m.entries) {
    print('${e.key}=${e.value}');
  }
}
