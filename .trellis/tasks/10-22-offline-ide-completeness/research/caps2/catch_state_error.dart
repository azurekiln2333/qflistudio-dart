void main() {
  try {
    throw StateError('bad');
  } on StateError catch (e) {
    print(e.message);
  }
}
