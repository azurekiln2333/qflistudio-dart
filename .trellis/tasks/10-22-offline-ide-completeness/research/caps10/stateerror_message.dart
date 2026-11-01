void main() {
  try {
    throw StateError('计算失败');
  } on StateError catch (e) {
    print(e.message);
  }
}
