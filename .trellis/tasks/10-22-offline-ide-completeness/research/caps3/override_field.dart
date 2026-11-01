class A {
  A(this.x);
  int x;
}

class B extends A {
  B(super.x);
}

void main() {
  print(B(5).x);
}
