import 'dart:io';

void main() {
  final f = File('tmp_len.txt')..writeAsStringSync('abc');
  print(f.lengthSync());
  f.deleteSync();
}
