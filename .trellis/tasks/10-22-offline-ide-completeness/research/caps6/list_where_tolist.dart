void main() {
  final l = [1, 2, 3];
  print(l.where((e) => e > 1).toList());
  print(l.map((e) => e + 1).toList());
}
