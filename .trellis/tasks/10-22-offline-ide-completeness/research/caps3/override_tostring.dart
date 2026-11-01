class P {
  P(this.n);
  final int n;
  @override
  String toString() => 'P(\$n)';
}

void main() {
  print(P(1));
}
