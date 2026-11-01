void main() {
  final n = int.parse('42');
  print(n + 1);
  print(double.parse('19.9') * 2);
  print((1 / 3).toStringAsFixed(3));
  print(255.toString());
  final bad = int.tryParse('abc');
  print(bad == null ? 'fail' : bad);
}
