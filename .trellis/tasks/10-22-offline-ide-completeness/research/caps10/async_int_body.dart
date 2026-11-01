Future<int> v() async {
  return 10;
}

Future<void> main() async {
  print(await v());
}
