Future<void> main() async {
  final v = await Future<int>.value(1);
  print(v);
}
