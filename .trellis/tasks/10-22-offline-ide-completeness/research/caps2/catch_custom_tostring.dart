class MyErr implements Exception {
  MyErr(this.message);
  final String message;
  @override
  String toString() => 'MyErr: \$message';
}

void main() {
  try {
    throw MyErr('boom');
  } catch (e) {
    print(e);
  }
}
