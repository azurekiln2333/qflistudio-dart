Future<void> main() async {
  final vs = await Future.wait([Future<int>.value(1), Future<int>.value(2)]);
  print(vs);
}
