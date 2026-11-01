class A {
  A(this.x);
  final int x;
}

class B extends A {
  B(int x) : super(x);
}

void main() {
  print(B(5).x);
}
