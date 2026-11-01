import 'dart:convert';

void main() {
  final m = jsonDecode('{"a":1}') as Map<String, dynamic>;
  print(m['a']);
}
