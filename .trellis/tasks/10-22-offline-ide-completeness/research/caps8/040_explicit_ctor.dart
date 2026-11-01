abstract class Shape {
  Shape();
  double area();
  String describe() => 'area=${area().toStringAsFixed(2)}';
}

class Circle extends Shape {
  Circle(this.radius);
  final double radius;
  @override
  double area() => 3.14159 * radius * radius;
}

class Square extends Shape {
  Square(this.side);
  final double side;
  @override
  double area() => side * side;
}

void main() {
  for (final shape in [Circle(2), Square(3)]) {
    print(shape.describe());
  }
}
