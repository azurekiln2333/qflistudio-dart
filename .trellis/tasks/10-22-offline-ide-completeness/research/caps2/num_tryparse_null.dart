void main() {
  final bad = int.tryParse('abc');
  print(bad == null);
}
