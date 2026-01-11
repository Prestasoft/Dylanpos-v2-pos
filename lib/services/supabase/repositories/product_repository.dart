import 'base_repository.dart';

/// Modelo de Producto para Supabase
class ProductModel {
  final String? id;
  final String branchId;
  final String? categoryId;
  final String name;
  final String? description;
  final String? barcode;
  final double price;
  final double purchasePrice;
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.id,
    required this.branchId,
    this.categoryId,
    required this.name,
    this.description,
    this.barcode,
    this.price = 0,
    this.purchasePrice = 0,
    this.stock = 0,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString(),
      branchId: map['branch_id'] ?? '',
      categoryId: map['category_id']?.toString(),
      name: map['name'] ?? '',
      description: map['description'],
      barcode: map['barcode'],
      price: (map['price'] ?? 0).toDouble(),
      purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      imageUrl: map['image_url'],
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
      'category_id': categoryId,
      'name': name,
      'description': description,
      'barcode': barcode,
      'price': price,
      'purchase_price': purchasePrice,
      'stock': stock,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  ProductModel copyWith({
    String? id,
    String? branchId,
    String? categoryId,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? purchasePrice,
    int? stock,
    String? imageUrl,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Repositorio de Productos
class ProductRepository extends BaseRepository<ProductModel> {
  @override
  final String tableName = 'products';

  @override
  ProductModel fromMap(Map<String, dynamic> map) => ProductModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProductModel model) => model.toMap();

  /// Buscar productos por nombre
  Future<List<ProductModel>> searchByName(String query) async {
    return search('name', query);
  }

  /// Buscar producto por código de barras
  Future<ProductModel?> findByBarcode(String barcode) async {
    final results = await findBy('barcode', barcode);
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtener productos activos
  Future<List<ProductModel>> getActiveProducts() async {
    return findBy('is_active', true);
  }

  /// Obtener productos por categoría
  Future<List<ProductModel>> getByCategory(String categoryId) async {
    return findBy('category_id', categoryId);
  }

  /// Actualizar stock del producto
  Future<bool> updateStock(String productId, int newStock) async {
    return update(productId, {'stock': newStock});
  }

  /// Reducir stock (para ventas)
  Future<bool> reduceStock(String productId, int quantity) async {
    try {
      final product = await getById(productId);
      if (product == null) return false;

      final newStock = (product.stock - quantity).clamp(0, 999999);
      return updateStock(productId, newStock);
    } catch (e) {
      return false;
    }
  }

  /// Aumentar stock (para compras o devoluciones)
  Future<bool> increaseStock(String productId, int quantity) async {
    try {
      final product = await getById(productId);
      if (product == null) return false;

      final newStock = product.stock + quantity;
      return updateStock(productId, newStock);
    } catch (e) {
      return false;
    }
  }

  /// Obtener productos con bajo stock
  Future<List<ProductModel>> getLowStockProducts(int threshold) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .eq('is_active', true)
          .lte('stock', threshold)
          .order('stock', ascending: true);

      return (response as List)
          .map((item) => ProductModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Instancia global del repositorio
final productRepository = ProductRepository();
