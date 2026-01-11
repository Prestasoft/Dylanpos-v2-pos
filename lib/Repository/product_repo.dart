import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/model/category_model.dart';

import '../model/brands_model.dart';
import '../model/product_model.dart';
import '../model/unit_model.dart';
import '../services/api_service.dart';

/// Repositorio de productos - Usa PostgreSQL API
class ProductRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los productos desde PostgreSQL
  Future<List<ProductModel>> getAllProduct() async {
    try {
      final response = await _apiService.getProducts(limit: 1000);

      if (response.success && response.data != null) {
        final productsData = response.data['products'] as List<dynamic>? ?? [];

        return productsData.map((data) {
          return ProductModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener productos por nombre (búsqueda) - retorna JSON dinámico
  Future<List<dynamic>> getAllProductByJson({required String searchData}) async {
    try {
      final response = await _apiService.getProducts(limit: 1000, search: searchData);

      if (response.success && response.data != null) {
        final productsData = response.data['products'] as List<dynamic>? ?? [];

        // Filtrar por nombre si hay datos de búsqueda
        if (searchData.isEmpty) {
          return productsData;
        }

        return productsData.where((product) {
          final name = product['productName']?.toString().toLowerCase() ?? '';
          return name.contains(searchData.toLowerCase());
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener productos filtrados por almacén (warehouse)
  Future<List<dynamic>> getAllProductByJsonWarehouse({
    required String searchData,
    required WareHouseModel warehouseId,
  }) async {
    try {
      final response = await _apiService.getProducts(limit: 1000, search: searchData);

      if (response.success && response.data != null) {
        final productsData = response.data['products'] as List<dynamic>? ?? [];

        return productsData.where((product) {
          final name = product['productName']?.toString().toLowerCase() ?? '';
          final matchesName = searchData.isEmpty || name.contains(searchData.toLowerCase());

          // Por ahora retornamos todos los productos ya que el filtro de warehouse
          // se puede implementar después en el servidor
          return matchesName;
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener todas las categorías de servicios/paquetes desde PostgreSQL
  /// Usa el endpoint /api/categories/services que consulta la tabla 'categories'
  Future<List<CategoryModel>> getAllCategory() async {
    try {
      final response = await _apiService.get('categories/services', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final categoriesData = response.data['categories'] as List<dynamic>? ?? [];

        return categoriesData.map((data) {
          return CategoryModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener todas las marcas/bancos desde PostgreSQL
  Future<List<BrandsModel>> getAllBrands() async {
    try {
      final response = await _apiService.get('banks', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        final banksData = response.data['banks'] as List<dynamic>? ?? [];

        return banksData.map((data) {
          final mapData = data as Map<String, dynamic>;
          // Verificar que tenga los campos necesarios
          if (mapData.containsKey('accountName') && mapData.containsKey('bankName')) {
            return BrandsModel.fromJson(mapData);
          }
          return null;
        }).whereType<BrandsModel>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtener todas las unidades desde PostgreSQL
  Future<List<UnitModel>> getAllUnits() async {
    try {
      final response = await _apiService.get('units', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        final unitsData = response.data['units'] as List<dynamic>? ?? [];

        return unitsData.map((data) {
          return UnitModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear un nuevo producto
  Future<ProductModel?> createProduct(ProductModel product) async {
    try {
      final productData = Map<String, dynamic>.from(product.toJson());
      final response = await _apiService.post('products', productData);

      if (response.success && response.data != null) {
        return ProductModel.fromJson(response.data['product']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar un producto existente
  Future<ProductModel?> updateProduct(String id, ProductModel product) async {
    try {
      final productData = Map<String, dynamic>.from(product.toJson());
      final response = await _apiService.put('products/$id', productData);

      if (response.success && response.data != null) {
        return ProductModel.fromJson(response.data['product']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar un producto
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _apiService.delete('products/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
