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
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: map['updated_at']?.toDate() ?? DateTime.now(),
      state: map['state'] ?? "Sin Estado",
      images: map['images'] != null && map['images'] is List
          ? List<String>.from(map['images'].map((x) => x.toString()))
          : [],
      price: map['price']?.toDouble() ?? 0.0,
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
          : 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672',
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