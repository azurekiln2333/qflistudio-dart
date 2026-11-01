class A {
  int f() => 1;
}

class B extends A {
  int f() => 2;
  int g() => super.f() + f();
}

void main() {
  print(B().g());
}
