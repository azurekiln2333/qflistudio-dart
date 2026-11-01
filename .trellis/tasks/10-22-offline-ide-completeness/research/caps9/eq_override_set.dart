class Vec {
  const Vec(this.x, this.y);
  final int x;
  final int y;
  @override
  bool operator ==(Object other) => other is Vec && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

void main() {
  final a = const Vec(1, 2);
  print(a == const Vec(1, 2));
  print({a, const Vec(1, 2)}.length);
}
