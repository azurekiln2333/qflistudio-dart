void main() {
  final counts = {'a': 1};
  counts['a'] = counts['a']! + 10;
  print(counts);
}
