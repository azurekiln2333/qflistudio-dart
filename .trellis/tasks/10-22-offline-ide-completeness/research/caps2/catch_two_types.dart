void main() {
  try {
    final list = <int>[];
    print(list[5]);
  } on RangeError catch (e) {
    print('range');
  } on Object catch (e) {
    print('other');
  }
}
