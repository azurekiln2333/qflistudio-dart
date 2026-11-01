class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  Vec operator +(Vec other) => Vec(x + other.x, y + other.y);
}

void main() {
  final v = const Vec(1, 2) + const Vec(3, 4);
  print(v.x);
  print(v.y);
}
