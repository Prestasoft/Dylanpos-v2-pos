class DressModel {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final String branchId;
  final bool available;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;
  DressModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.branchId,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
    List<String>? images, // 👈 Constructor admite lista opcional
  }) : images = images ?? [];

  factory DressModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DressModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      branchId: map['branch_id'] ?? '',
      available: map['available'] ?? false,
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: map['updated_at']?.toDate() ?? DateTime.now(),
      images: map['images'] != null && map['images'] is List
          ? List<String>.from(map['images'].map((x) => x.toString()))
          : [],
    );
  }
  factory DressModel.fromRealtimeDB(Map<dynamic, dynamic> map, dynamic documentId) {
    return DressModel(
      id: documentId.toString(),
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      subcategory: map['subcategory']?.toString() ?? '',
      branchId: map['branch_id']?.toString() ?? '',
      available: map['available'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] ?? 0),
      images: map['images'] != null
          ? (map['images'] is List
          ? List<String>.from((map['images'] as List).map((x) => x.toString()))
          : map['images'] is Map
          ? List<String>.from((map['images'] as Map).values.map((x) => x.toString()))
          : [])
          : [],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'branch_id': branchId,
      'available': available,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'images': images, // 👈 Guardar la lista de imágenes
    };
  }
}
