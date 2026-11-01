Stream<int> gen() async* {
  yield 1;
  yield 2;
}

Future<void> main() async {
  await for (final v in gen()) {
    print(v);
  }
}
