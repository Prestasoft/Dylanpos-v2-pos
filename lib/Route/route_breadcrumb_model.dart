class RouteBreadcrumbModel {
  final String title;
  final String parentRoute;
  final String childRoute;
  const RouteBreadcrumbModel({
    required this.title,
    required this.parentRoute,
    required this.childRoute,
  });

  @override
  String toString() {
    return 'RouteBreadcrumbModel(parentName: $parentRoute, childName: $childRoute)';
  }
}
