import 'dart:convert';

void main() {
  final l = jsonDecode('[1,2,3]') as List<dynamic>;
  print(l.length);
  print(l.first);
}
