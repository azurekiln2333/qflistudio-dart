void main() {
  outer:
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 2; j++) {
      if (j == 1) break outer;
      print('$i$j');
    }
  }
}
