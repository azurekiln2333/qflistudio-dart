typedef Mapper = int Function(int);

void main() {
  const Mapper m = _inc;
  print(m(1));
}

int _inc(int v) => v + 1;
