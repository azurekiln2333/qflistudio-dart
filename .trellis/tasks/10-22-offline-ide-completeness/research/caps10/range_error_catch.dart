void main() {
  try {
    print(<int>[1, 2, 3][5]);
  } on RangeError catch (e) {
    print('range');
  }
}
