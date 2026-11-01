class Box<T> {
  Box(this.value);
  final T value;
}

void main() {
  print(Box<int>(3).value);
}
