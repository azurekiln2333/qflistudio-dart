abstract class Shape {
  double area() => 0;
}

class Sq extends Shape {}

void main() {
  print(Sq().area());
}
