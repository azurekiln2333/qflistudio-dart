abstract class A {
  int f();
}

abstract class B extends A {}

class C extends B {
  int f() => 3;
}

void main() {
  print(C().f());
}
