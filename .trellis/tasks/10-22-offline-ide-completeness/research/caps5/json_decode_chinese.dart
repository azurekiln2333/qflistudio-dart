import 'dart:convert';

void main() {
  final m = jsonDecode('{"name":"小明"}') as Map<String, dynamic>;
  print(m['name']);
}
