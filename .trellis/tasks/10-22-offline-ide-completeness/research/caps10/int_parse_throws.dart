void main() {
  try {
    print(int.parse('abc'));
  } on FormatException catch (e) {
    print('fmt');
  }
}
