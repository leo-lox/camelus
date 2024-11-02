class TreeNode<T> {
  T value;
  List<TreeNode<T>> children;

  TreeNode(this.value) : children = <TreeNode<T>>[];

  void addChild(TreeNode<T> child) {
    children.add(child);
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
