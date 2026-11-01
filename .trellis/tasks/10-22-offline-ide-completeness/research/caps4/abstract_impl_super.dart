abstract class Shape {
  Shape(this.name);
  final String name;
  double area();
}

class Sq extends Shape {
  Sq(this.s) : super('sq');
  final double s;
  double area() => s * s;
}

void main() {
  final q = Sq(3);
  print(q.name);
  print(q.area());
}
