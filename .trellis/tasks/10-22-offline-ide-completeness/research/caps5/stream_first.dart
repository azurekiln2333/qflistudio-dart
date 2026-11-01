Future<void> main() async {
  final v = await Stream<int>.fromIterable([5, 6]).first;
  print(v);
}
