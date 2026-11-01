void main() {
  Future<int> v() async => 10;
  v().then((x) => print(x * 2));
}
