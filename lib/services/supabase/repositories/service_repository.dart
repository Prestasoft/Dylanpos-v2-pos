import 'dart:convert';
import 'base_repository.dart';

/// Modelo de Servicio/Paquete para Supabase
class ServiceModel {
  final String? id;
  final String branchId;
  final String? type;
  final String name;
  final String category;
  final String? subcategory;
  final String? description;
  final double price;
  final int? duration;
  final List<Map<String, dynamic>> components;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    this.id,
    required this.branchId,
    this.type,
    required this.name,
    required this.category,
    this.subcategory,
    this.description,
    this.price = 0,
    this.duration,
    this.components = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parseComponents(dynamic data) {
      if (data == null) return [];
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) {
            return decoded.cast<Map<String, dynamic>>();
          }
        } catch (_) {}
        return [];
      }
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }

    return ServiceModel(
      id: map['id']?.toString(),
      branchId: map['branch_id'] ?? '',
      type: map['type'],
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'],
      description: map['description'],
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'],
      components: parseComponents(map['components']),
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'branch_id': branchId,
      'type': type,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'price': price,
      'duration': duration,
      'components': components,
      'is_active': isActive,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? branchId,
    String? type,
    String? name,
    String? category,
    String? subcategory,
    String? description,
    double? price,
    int? duration,
    List<Map<String, dynamic>>? components,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      type: type ?? this.type,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      components: components ?? this.components,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Repositorio de Servicios/Paquetes
class ServiceRepository extends BaseRepository<ServiceModel> {
  @override
  final String tableName = 'services';

  @override
  ServiceModel fromMap(Map<String, dynamic> map) => ServiceModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ServiceModel model) => model.toMap();

  /// Buscar servicios por nombre
  Future<List<ServiceModel>> searchByName(String query) async {
    return search('name', query);
  }

  /// Obtener servicios por categoría
  Future<List<ServiceModel>> getByCategory(String category) async {
    return findBy('category', category);
  }

  /// Obtener servicios por tipo
  Future<List<ServiceModel>> getByType(String type) async {
    return findBy('type', type);
  }

  /// Obtener servicios activos
  Future<List<ServiceModel>> getActiveServices() async {
    return findBy('is_active', true);
  }

  /// Obtener categorías únicas
  Future<List<String>> getCategories() async {
    try {
      final services = await getAll();
      final categories = services.map((s) => s.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }

  /// Obtener subcategorías por categoría
  Future<List<String>> getSubcategories(String category) async {
    try {
      final services = await getByCategory(category);
      final subcategories = services
          .where((s) => s.subcategory != null && s.subcategory!.isNotEmpty)
          .map((s) => s.subcategory!)
          .toSet()
          .toList();
      subcategories.sort();
      return subcategories;
    } catch (e) {
      return [];
    }
  }
}

/// Instancia global del repositorio
final serviceRepository = ServiceRepository();
