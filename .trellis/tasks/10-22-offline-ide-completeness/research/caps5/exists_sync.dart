import 'dart:io';

void main() {
  final f = File('tmp_exists.txt');
  print(f.existsSync());
  f.writeAsStringSync('x');
  print(f.existsSync());
  f.deleteSync();
}
