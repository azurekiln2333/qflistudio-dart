class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec add(Vec other) => Vec(x + other.x, y + other.y);
  @override
  String toString() => '($x, $y)';
}

void main() {
  print(const Vec(1, 2).add(const Vec(3, 4)));
}
