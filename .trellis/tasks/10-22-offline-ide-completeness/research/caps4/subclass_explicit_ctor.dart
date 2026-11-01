class A {
  A();
  int f() => 1;
}

class B extends A {
  B();
  int g() => 2;
}

void main() {
  final b = B();
  print(b.f());
  print(b.g());
}
