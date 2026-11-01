class Node {
  Node(this.next);
  final Node? next;
}

void main() {
  final n = Node(Node(null));
  print(n.next!.next == null);
}
