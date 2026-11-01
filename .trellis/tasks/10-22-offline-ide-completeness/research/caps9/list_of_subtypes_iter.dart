abstract class Shape {
  Shape();
  double area();
}

class Sq extends Shape {
  Sq(this.s);
  final double s;
  @override
  double area() => s * s;
}

void main() {
  for (final s in <Shape>[Sq(2)]) {
    print(s.area());
  }
}
