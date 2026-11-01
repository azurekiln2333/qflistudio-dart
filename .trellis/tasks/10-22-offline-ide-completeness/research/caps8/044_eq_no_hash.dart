class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;
}

void main() {
  print(const Vec(1, 2) == const Vec(1, 2));
}
