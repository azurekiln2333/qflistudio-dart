void main() {
  final l = [1, 2, 3, 4];
  print(l.where((e) => e.isEven).toList());
  print(l.map((e) => e * 2).toList());
}
