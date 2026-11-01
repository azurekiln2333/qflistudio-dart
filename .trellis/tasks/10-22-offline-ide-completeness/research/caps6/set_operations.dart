void main() {
  final a = <int>{1, 2, 3};
  final b = <int>{2, 3, 4};
  print(a.intersection(b));
  print(a.union(b));
  print(a.difference(b));
  print(a.contains(2));
}
