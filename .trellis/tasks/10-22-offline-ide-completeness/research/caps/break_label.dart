void main() {
  outer:
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (j == 1) {
        break outer;
      }
      print('\$i\$j');
    }
  }
}
