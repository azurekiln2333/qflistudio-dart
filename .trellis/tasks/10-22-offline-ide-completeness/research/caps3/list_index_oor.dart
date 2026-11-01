void main() {
  final l = <int>[1, 2, 3];
  try {
    print(l[5]);
  } catch (e) {
    print(e.runtimeType);
  }
}
