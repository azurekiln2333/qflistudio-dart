class Box<T extends num> {
  Box(this.value);
  final T value;
}

void main() {
  print(Box<int>(3).value);
}
