class Box<T> {
  Box(this.value);
  final T value;
  T get() => value;
}

void main() {
  print(Box<int>(3).get());
  print(Box<String>('x').get());
}
