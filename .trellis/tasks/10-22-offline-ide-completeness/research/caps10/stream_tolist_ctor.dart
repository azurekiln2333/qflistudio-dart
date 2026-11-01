Future<void> main() async {
  final s = Stream<int>.fromIterable(<int>[1, 2, 3]);
  print(await s.toList());
}
