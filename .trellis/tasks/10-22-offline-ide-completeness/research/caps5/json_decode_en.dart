import 'dart:convert';

void main() {
  final s = jsonEncode({'a': 1});
  print(s);
  print(jsonDecode(s));
}
