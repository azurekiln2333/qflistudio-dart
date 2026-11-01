Future<void> main() async {
  print(await Stream<int>.fromIterable(<int>[1, 2, 3]).first);
}
