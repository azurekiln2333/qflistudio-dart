void main() {
  Future<int>.error(StateError('x')).catchError((Object e) => 0).then(print);
}
