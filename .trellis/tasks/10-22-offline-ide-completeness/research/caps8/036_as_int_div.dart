class Temperature {
  Temperature.celsius(this.celsius);
  Temperature.fahrenheit(double fahrenheit)
      : celsius = (fahrenheit - 32) * 5 / 9;

  final double celsius;

  double get fahrenheit => celsius * 9 / 5 + 32;
}

void main() {
  final a = Temperature.celsius(25);
  print(a.fahrenheit.toStringAsFixed(1));
  final b = Temperature.fahrenheit(77);
  print(b.celsius.toStringAsFixed(1));
}
