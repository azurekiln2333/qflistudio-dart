class A {
  int f() => 1;
}

class B extends A {
  int f() => 2;
}

void main() {
  print(B().f());
  print((A() as A).f());
}
