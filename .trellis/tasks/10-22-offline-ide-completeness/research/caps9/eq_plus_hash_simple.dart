class P {
  const P(this.v);
  final int v;
  @override
  bool operator ==(Object o) => o is P && o.v == v;
  @override
  int get hashCode => v;
}

void main() {
  print(<P>{const P(1), const P(1)}.length);
}
