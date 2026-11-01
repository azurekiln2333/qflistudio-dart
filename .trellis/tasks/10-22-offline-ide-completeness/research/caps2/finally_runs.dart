void main() {
  try {
    throw Exception('x');
  } catch (e) {
    print('caught');
  } finally {
    print('finally');
  }
}
