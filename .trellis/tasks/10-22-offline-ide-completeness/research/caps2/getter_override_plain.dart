class A {
  int get x => 1;
}

class B extends A {
  int get x => 2;
}

void main() {
  print(B().x);
}
