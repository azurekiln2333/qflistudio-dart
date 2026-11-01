class A {
  int get x => 1;
  int get name => 10;
}

class B extends A {
  @override
  int get x => 2;
}

void main() {
  final b = B();
  print(b.x);
  print(b.name);
}
