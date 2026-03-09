import 'add_to_cart_model.dart';

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
  final double price;
  final String state;

  DressModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.branchId,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
    required this.state,
    this.price = 0.0,
    List<String>? images,
  }) : images = images ?? [];

  factory DressModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DressModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      branchId: map['branch_id'] ?? '',
      available: map['available'] ?? false,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      state: map['state'] ?? "Sin Estado",
      images: map['images'] != null && map['images'] is List
          ? List<String>.from(map['images'].map((x) => x.toString()))
          : [],
      price: map['price']?.toDouble() ?? 0.0,
    );
  }

  /// Helper method to parse DateTime from various formats (Firebase Timestamp, int milliseconds, or String)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // Si es un int (milisegundos desde epoch - formato de la API PostgreSQL)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // Si es un String (ISO 8601 o similar)
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    // Si tiene método toDate() (Firebase Timestamp)
    if (value != null) {
      try {
        return value.toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
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
      state: map['state'] ?? 'Sin Estado',
      images: map['images'] != null
          ? (map['images'] is List
              ? List<String>.from((map['images'] as List).map((x) => x.toString()))
              : map['images'] is Map
                  ? List<String>.from((map['images'] as Map).values.map((x) => x.toString()))
                  : [])
          : [],
      price: map['price']?.toDouble() ?? 0.0,
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
      'state': state,
      'images': images,
      'price': price,
    };
  }

  AddToCartModel toCartItem() {
    return AddToCartModel(
      productName: name,
      productId: id,
      quantity: 1,
      subTotal: price.toString(),
      productPurchasePrice: price * 0.7, // 30% de margen
      warehouseName: 'Vestimentas',
      warehouseId: 'dresses-warehouse',
      unitPrice: price,
      productImage: images.isNotEmpty 
          ? images.first 
          : 'https://sistema.victorguzmanfotografia.com/assets/images/no-image-found.png',
      taxType: 'none',
      margin: 30,
      excTax: 0,
      incTax: price,
      groupTaxName: 'Sin impuesto',
      groupTaxRate: 0,
      subTaxes: [],
      isDress: true,
      dressId: id,
      dressState: state,
      dressAvailable: available,
      dressCategory: category,
      descricpion: 'Vestido: $name - Estado: $state - Categoría: $category',
    );
  }
}