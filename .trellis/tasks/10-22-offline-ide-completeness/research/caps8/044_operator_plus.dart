class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec operator +(Vec other) => Vec(x + other.x, y + other.y);
  @override
  String toString() => '($x, $y)';
}

void main() {
  final a = const Vec(1, 2);
  final b = const Vec(3, 4);
  print(a + b);
}
