abstract class Shape {
  double area();
}

class Sq implements Shape {
  Sq(this.s);
  final double s;
  @override
  double area() => s * s;
}

void main() {
  print(Sq(3).area());
}
