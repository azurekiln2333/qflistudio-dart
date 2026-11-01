void main() {
  print([1, 2, 3].reduce((a, b) => a + b));
  print([1, 2, 3].fold<int>(0, (a, b) => a + b));
}
