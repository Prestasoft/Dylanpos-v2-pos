class CategoryModel {
  late String categoryName;
  late bool size;
  late bool color;
  late bool weight;
  late bool capacity;
  late bool type;
  late bool warranty;

  CategoryModel({
    required this.categoryName,
    required this.size,
    required this.color,
    required this.capacity,
    required this.type,
    required this.weight,
    required this.warranty,
  });

  CategoryModel.fromJson(Map<dynamic, dynamic> json) {
    // Soporta tanto el formato PostgreSQL (name) como el formato antiguo (categoryName)
    categoryName = json['name'] as String? ?? json['categoryName'] as String? ?? '';
    // Soporta tanto snake_case (PostgreSQL) como camelCase (Firebase legacy)
    size = json['variation_size'] as bool? ?? json['variationSize'] as bool? ?? false;
    color = json['variation_color'] as bool? ?? json['variationColor'] as bool? ?? false;
    capacity = json['variation_capacity'] as bool? ?? json['variationCapacity'] as bool? ?? false;
    type = json['variation_type'] as bool? ?? json['variationType'] as bool? ?? false;
    weight = json['variation_weight'] as bool? ?? json['variationWeight'] as bool? ?? false;
    warranty = json['variation_warranty'] as bool? ?? json['variationWarranty'] as bool? ?? false;
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'categoryName': categoryName,
        'variationSize': size,
        'variationColor': color,
        'variationCapacity': capacity,
        'variationType': type,
        'variationWeight': weight,
        'variationWarranty': warranty,
      };
}

class GetCategoryAndVariationModel {
  GetCategoryAndVariationModel({required this.categoryName, required this.variations});

  final String categoryName;
  final List<String> variations;
}
