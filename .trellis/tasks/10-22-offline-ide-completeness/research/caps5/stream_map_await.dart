Future<void> main() async {
  await for (final v in Stream<int>.fromIterable([1, 2]).map((e) => e * 2)) {
    print(v);
  }
}
