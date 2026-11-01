class A {
  A();
  int f() => 1;
}

class B extends A {
  B();
  int f() => 2;
}

void main() {
  print(B().f());
}
