Future<void> main() async {
  final c = Completer<int>();
  print(c.isCompleted);
  c.complete(1);
  print(await c.future);
}
