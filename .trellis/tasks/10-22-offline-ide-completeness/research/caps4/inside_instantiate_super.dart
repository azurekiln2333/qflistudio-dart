class A {
  A(this.x);
  final int x;
}

class B extends A {
  B(int x) : super(x);
  int get doubled => x * 2;
}

void main() {
  final b = B(5);
  print(b.x);
  print(b.doubled);
}
