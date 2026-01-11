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
    // Helper para parsear listas de strings de forma segura
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    // Helper para parsear timestamps de forma segura
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // Helper para parsear precio de forma segura
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ServicePackageModel(
        id: documentId,
        type: map['type']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        subcategory: map['subcategory']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        price: parsePrice(map['price']),
        duration: (map['duration'] is Map) ? Map<String, dynamic>.from(map['duration']) : {'value': 1, 'unit': 'hours'},
        components: parseStringList(map['components']),
        branches: parseStringList(map['branches']),
        createdAt: parseTimestamp(map['created_at']),
        updatedAt: parseTimestamp(map['updated_at']),
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
