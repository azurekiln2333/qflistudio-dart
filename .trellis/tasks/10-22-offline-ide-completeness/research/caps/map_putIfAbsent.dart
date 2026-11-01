void main() {
  final m = <String, int>{};
  m.putIfAbsent('x', () => 1);
  print(m);
}
