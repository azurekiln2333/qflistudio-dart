Future<void> main() async {
  final vs = await Stream<int>.fromIterable([1, 2, 3]).toList();
  print(vs);
}
