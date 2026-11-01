class Counter {
  static int total = 0;
  Counter(this.label) {
    total++;
  }
  final String label;
}

void main() {
  Counter('a');
  Counter('b');
  print(Counter.total);
}
