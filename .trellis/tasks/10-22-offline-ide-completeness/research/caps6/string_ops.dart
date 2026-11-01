void main() {
  const s = 'Hello, Dart';
  print(s.toUpperCase());
  print(s.split(', '));
  print(s.contains('Dart'));
  print(s.startsWith('Hell'));
  print(s.substring(0, 5));
  print(s.trim());
  print(s.replaceAll('Dart', 'World'));
  print(s.padLeft(15, '.'));
}
