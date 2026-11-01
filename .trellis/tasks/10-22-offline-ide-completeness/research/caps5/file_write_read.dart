import 'dart:io';

void main() {
  final f = File('tmp_probe.txt');
  f.writeAsStringSync('hello');
  print(f.readAsStringSync());
  f.deleteSync();
}
