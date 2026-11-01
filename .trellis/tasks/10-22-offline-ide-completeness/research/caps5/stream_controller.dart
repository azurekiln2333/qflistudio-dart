import 'dart:async';

Future<void> main() async {
  final c = StreamController<int>();
  c.add(1);
  await c.close();
  await for (final v in c.stream) {
    print(v);
  }
}
