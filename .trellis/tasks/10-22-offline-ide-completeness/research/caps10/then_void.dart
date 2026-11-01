Future<void> main() async {
  final f = <int>[1];
  await Future<void>.value().then((_) => print(f));
}
