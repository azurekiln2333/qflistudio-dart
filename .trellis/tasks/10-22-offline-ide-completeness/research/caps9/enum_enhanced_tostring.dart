enum Priority {
  low(1),
  high(3);

  const Priority(this.level);
  final int level;
}

void main() {
  print(Priority.high);
}
