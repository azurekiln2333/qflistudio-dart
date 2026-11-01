abstract class Shape {
  Shape();
  double area();
}

class Sq extends Shape {
  Sq(this.s);
  final double s;
  double area() => s * s;
}

void main() {
  print(Sq(3).area());
}
