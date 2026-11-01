void main() {
  final m = {'b': 2, 'a': 1};
  final keys = m.keys.toList()..sort();
  for (final k in keys) {
    print('$k=${m[k]}');
  }
}
