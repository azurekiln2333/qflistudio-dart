class A {
  A();
  int f() => 1;
}

class B extends A {
  B();
  int f() => 2;
  int g() => super.f() + f();
}

void main() {
  print(B().g());
}
