void main() {
  try {
    throw StateError('bad');
  } catch (e) {
    print(e is StateError);
    print(e is Object);
  }
}
