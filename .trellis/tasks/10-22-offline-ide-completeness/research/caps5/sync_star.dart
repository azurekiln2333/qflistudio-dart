Iterable<int> gen() sync* {
  yield 1;
  yield 2;
}

void main() {
  print(gen().toList());
}
