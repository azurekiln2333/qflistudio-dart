void main() {
  try {
    throw const FormatException('msg');
  } on FormatException catch (e) {
    print(e.message);
  }
}
