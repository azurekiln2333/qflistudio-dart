class P {
  P(this.name);
  final String name;
}

void main() {
  final Object o = P('x');
  final p = o as P;
  print(p.name);
}
