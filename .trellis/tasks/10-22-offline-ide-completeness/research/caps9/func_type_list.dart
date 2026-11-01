void main() {
  final List<int Function(int)> fs = [(v) => v + 1];
  print(fs.first(1));
}
