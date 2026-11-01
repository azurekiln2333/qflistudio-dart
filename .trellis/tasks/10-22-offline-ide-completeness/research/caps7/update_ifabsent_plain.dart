void main() {
  final counts = {'a': 1};
  if (!counts.containsKey('c')) {
    counts['c'] = 5;
  }
  print(counts);
}
