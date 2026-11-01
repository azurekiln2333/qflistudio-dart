import 'dart:io';

void main() {
  final f = File('tmp_lines.txt')..writeAsStringSync('a\nb\n');
  print(f.readAsLinesSync());
  f.deleteSync();
}
