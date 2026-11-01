class A {
  int f() => 1;
}

class B extends A {}

void main() {
  print(B().f());
}
