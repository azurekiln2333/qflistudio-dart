Future<void> main() async {
  final x = await Future<int>.delayed(Duration.zero, () => 42);
  print(x);
}
