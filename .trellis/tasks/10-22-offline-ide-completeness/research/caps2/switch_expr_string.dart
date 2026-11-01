void main() {
  final c = 'b';
  print(switch (c) { 'a' => 1, 'b' => 2, _ => 0 });
}
