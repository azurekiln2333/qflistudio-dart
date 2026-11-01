double toFahrenheit(double celsius) => celsius * 9.0 / 5.0 + 32.0;

void main() {
  print(toFahrenheit(25).toStringAsFixed(1));
}
