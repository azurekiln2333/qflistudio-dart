Future<void> main() async {
  final out = <int>[];
  await Stream<int>.fromIterable(<int>[1, 2, 3]).forEach(out.add);
  print(out);
}
