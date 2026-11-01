void main() {
  final counts = <String, int>{'a': 1};
  counts.update('a', (v) => v + 1, ifAbsent: () => 0);
  counts.update('b', (v) => v + 1, ifAbsent: () => 0);
  print(counts);
}
