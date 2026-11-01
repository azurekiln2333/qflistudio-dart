class A {
  int f() => 1;
}

class B extends A {
  int g() => 2;
}

void main() {
  print(B().g());
}
