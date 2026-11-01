abstract class Named {
  String get name;
}

class P implements Named {
  @override
  String get name => 'p';
}

void main() {
  print(P().name);
}
