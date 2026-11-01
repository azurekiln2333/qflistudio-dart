mixin M {
  int get doubled => 2;
}

class C with M {}

void main() {
  print(C().doubled);
}
