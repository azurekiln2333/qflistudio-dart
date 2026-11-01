enum Priority {
  low(1, 'a'),
  high(3, 'b');

  const Priority(this.level, this.label);
  final int level;
  final String label;
}

void main() {
  print(Priority.high.label);
  print(Priority.high.level);
}
