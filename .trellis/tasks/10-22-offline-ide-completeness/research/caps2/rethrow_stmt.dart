void main() {
  try {
    try {
      throw Exception('inner');
    } catch (e) {
      print('inner caught');
      rethrow;
    }
  } catch (e) {
    print('outer caught');
  }
}
