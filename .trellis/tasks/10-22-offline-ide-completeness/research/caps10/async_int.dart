Future<int> v() async => 10;

Future<void> main() async {
  print(await v());
}
