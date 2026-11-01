class A {
  A();
  int v = 0;
  void add(int x) {
    v += x;
  }
}

void main() {
  final a = A()
    ..add(1)
    ..add(2);
  print(a.v);
}
