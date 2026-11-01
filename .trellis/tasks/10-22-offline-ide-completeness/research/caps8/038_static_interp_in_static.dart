class Counter {
  static int total = 2;
  static String describe() => 'n=$total';
}

void main() {
  print(Counter.describe());
}
