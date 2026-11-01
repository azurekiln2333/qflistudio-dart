Future<void> main() async {
  final v = await Future<int>.delayed(Duration(milliseconds: 10), () => 1);
  print(v);
}
