Future<void> main() async {
  try {
    await Future<int>.delayed(Duration(seconds: 1), () => 1)
        .timeout(const Duration(milliseconds: 10));
  } on Object {
    print('timeout');
  }
}
