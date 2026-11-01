void main() {
  final counts = {'a': 1};
  final upper = counts.map((k, v) => MapEntry(k.toUpperCase(), v * 2));
  print(upper);
}
