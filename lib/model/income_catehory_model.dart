class IncomeCategoryModel {
  String? id;
  late String categoryName;
  late String categoryDescription;

  IncomeCategoryModel({
    this.id,
    required this.categoryName,
    required this.categoryDescription,
  });

  IncomeCategoryModel.fromJson(Map<dynamic, dynamic> json) {
    // Soporta tanto snake_case (PostgreSQL) como camelCase (Firebase legacy)
    id = json['id']?.toString();
    categoryName = (json['category_name'] ?? json['categoryName'] ?? '').toString();
    categoryDescription = (json['category_description'] ?? json['categoryDescription'] ?? '').toString();
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'category_name': categoryName,
        'category_description': categoryDescription,
      };
}
