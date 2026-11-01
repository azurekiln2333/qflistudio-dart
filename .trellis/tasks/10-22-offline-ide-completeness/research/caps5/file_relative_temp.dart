import 'dart:io';

void main() {
  final d = Directory('tmp_probe_dir')..createSync();
  final f = File('\${d.path}/a.txt')..writeAsStringSync('x');
  print(f.readAsStringSync());
  d.deleteSync(recursive: true);
}
