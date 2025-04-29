class ServicePackageModel {
  final String id;
  final String type;
  final String name;
  final String category;
  final String subcategory;
  final String description;
  final double price;
  final Map<String, dynamic> duration;
  final List<String> components;
  final List<String> branches;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicePackageModel({
    required this.id,
    required this.type,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.price,
    required this.duration,
    required this.components,
    required this.branches,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePackageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ServicePackageModel(
        id: documentId,
        type: map['type'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        subcategory: map['subcategory'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        duration: (map['duration'] is Map) ? Map<String, dynamic>.from(map['duration']) : {'value': 1, 'unit': 'hours'},
        components: List<String>.from(map['components'] ?? []),
        branches: List<String>.from(map['branches'] ?? []),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'price': price,
      'duration': duration,
      'components': components,
      'branches': branches,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }

  // Método para copiar el objeto y permitir la actualización del ID
  ServicePackageModel copyWith({
    String? id,
    String? type,
    String? name,
    String? category,
    String? subcategory,
    String? description,
    double? price,
    Map<String, dynamic>? duration,
    List<String>? components,
    List<String>? branches,
    DateTime? createdAt,
    DateTime? updatedAt
  }) {
    return ServicePackageModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      components: components ?? this.components,
      branches: branches ?? this.branches,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt
    );
  }
}
