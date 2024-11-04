class TreeNode<T> {
  final T value;
  TreeNode<T>? parent;
  final List<TreeNode<T>> _children;

  bool get isFirstChild => parent?.children.first == this;
  bool get isLastChild => parent?.children.last == this;
  bool get hasSiblings => parent != null && parent!.children.length > 1;

  bool get hasParent => parent != null;

  bool get parentHasChildren => parent?.hasChildren ?? false;
  bool get hasChildren => _children.isNotEmpty;
  bool get isLeaf => _children.isEmpty;
  List<TreeNode<T>> get children => List.unmodifiable(_children);

  TreeNode(this.value) : _children = <TreeNode<T>>[];

  void addChild(TreeNode<T> child) {
    _children.add(child);
    child.parent = this;
  }

  void addChildren(List<TreeNode<T>> children) {
    for (var child in children) {
      addChild(child);
    }
  }

  void removeChild(TreeNode<T> child) {
    _children.remove(child);
    child.parent = null;
  }

  void printTree([String prefix = '']) {
    print('$prefix${value.toString()}');
    for (var i = 0; i < _children.length; i++) {
      var child = _children[i];
      var isLastChild = i == _children.length - 1;
      child.printTree('$prefix${isLastChild ? '└── ' : '├── '}');
    }
  }

  @override
  String toString() {
    return value.toString();
  }
}
