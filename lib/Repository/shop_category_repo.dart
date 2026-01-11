import '../model/shop_category_model.dart';
import '../services/api_service.dart';

/// Repositorio de categorías de tienda - Usa PostgreSQL API
class ShopCategoryRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las categorías de tienda desde PostgreSQL
  Future<List<ShopCategoryModel>> getAllCategory() async {
    try {
      final response = await _apiService.get('shop-categories', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        final categoriesData = response.data['shop_categories'] as List<dynamic>? ?? [];

        return categoriesData.map((data) {
          return ShopCategoryModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva categoría de tienda
  Future<ShopCategoryModel?> createCategory(ShopCategoryModel category) async {
    try {
      final categoryData = Map<String, dynamic>.from(category.toJson());
      final response = await _apiService.post('shop-categories', categoryData);

      if (response.success && response.data != null) {
        return ShopCategoryModel.fromJson(response.data['shop_category']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar una categoría de tienda
  Future<ShopCategoryModel?> updateCategory(String id, ShopCategoryModel category) async {
    try {
      final categoryData = Map<String, dynamic>.from(category.toJson());
      final response = await _apiService.put('shop-categories/$id', categoryData);

      if (response.success && response.data != null) {
        return ShopCategoryModel.fromJson(response.data['shop_category']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una categoría de tienda
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _apiService.delete('shop-categories/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
