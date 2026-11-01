void main() {
  final v = 3;
  final r = switch (v) { 1 => 'a', _ => 'other' };
  print(r);
}
