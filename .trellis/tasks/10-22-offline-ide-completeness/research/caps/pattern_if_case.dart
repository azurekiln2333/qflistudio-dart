void main() {
  final Object value = 42;
  if (value case int n) {
    print('int \$n');
  }
}
