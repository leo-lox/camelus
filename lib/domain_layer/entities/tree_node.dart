class TreeNode<T> {
  T value;
  TreeNode<T>? parent;
  List<TreeNode<T>> children;

  bool get isFirstChild => parent?.children.first == this;
  bool get isLastChild => parent?.children.last == this;
  bool get hasSiblings => parent != null && parent!.children.length > 1;

  TreeNode(this.value) : children = <TreeNode<T>>[];

  void addChild(TreeNode<T> child) {
    children.add(child);
    child.parent = this;
  }

  void printTree([String prefix = '']) {
    print('$prefix${value.toString()}');
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      var isLastChild = i == children.length - 1;
      child.printTree('$prefix${isLastChild ? '└── ' : '├── '}');
    }
  }

  @override
  String toString() {
    return value.toString();
  }
}
