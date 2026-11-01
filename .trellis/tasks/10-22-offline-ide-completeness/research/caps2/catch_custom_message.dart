class MyErr implements Exception {
  MyErr(this.message);
  final String message;
}

void main() {
  try {
    throw MyErr('boom');
  } catch (e) {
    print((e as MyErr).message);
  }
}
