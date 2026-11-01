import 'dart:convert';

void main() {
  final m = jsonDecode('{"name":"\u5c0f\u660e"}') as Map<String, dynamic>;
  print(m['name']);
}
