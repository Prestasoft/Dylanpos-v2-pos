import 'dart:async';
import '../services/api_service.dart';

/// Repositorio de tipos de productos/servicios fotográficos - Usa PostgreSQL API
class PhotoTypesRepository {
  final String userId;
  final ApiService _apiService = ApiService();

  PhotoTypesRepository({required this.userId});

  /// Stream de tipos de productos
  Stream<List<Map<String, dynamic>>> getProductTypes() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    _fetchProductTypes().then((types) {
      controller.add(types);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  /// Obtener tipos de productos desde PostgreSQL
  Future<List<Map<String, dynamic>>> _fetchProductTypes() async {
    try {
      final response = await _apiService.get('photo-product-types');

      if (response.success && response.data != null) {
        final typesData = response.data['photo_product_types'] as List<dynamic>? ?? [];
        return typesData.map((data) => Map<String, dynamic>.from(data as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Stream de tipos de servicios
  Stream<List<Map<String, dynamic>>> getServiceTypes() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    _fetchServiceTypes().then((types) {
      controller.add(types);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  /// Obtener tipos de servicios desde PostgreSQL
  Future<List<Map<String, dynamic>>> _fetchServiceTypes() async {
    try {
      final response = await _apiService.get('photo-service-types');

      if (response.success && response.data != null) {
        final typesData = response.data['photo_service_types'] as List<dynamic>? ?? [];
        return typesData.map((data) => Map<String, dynamic>.from(data as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Agregar tipo de producto
  Future<void> addProductType(String name, String icon) async {
    try {
      final id = name.toLowerCase().replaceAll(' ', '_');
      await _apiService.post('photo-product-types', {
        'id': id,
        'name': name,
        'icon': icon,
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Error al agregar tipo de producto: $e');
    }
  }

  /// Agregar tipo de servicio
  Future<void> addServiceType(String name, String icon) async {
    try {
      final id = name.toLowerCase().replaceAll(' ', '_');
      await _apiService.post('photo-service-types', {
        'id': id,
        'name': name,
        'icon': icon,
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Error al agregar tipo de servicio: $e');
    }
  }

  /// Actualizar tipo de producto
  Future<void> updateProductType(String id, String name, String icon) async {
    try {
      await _apiService.put('photo-product-types/$id', {
        'name': name,
        'icon': icon,
      });
    } catch (e) {
      throw Exception('Error al actualizar tipo de producto: $e');
    }
  }

  /// Actualizar tipo de servicio
  Future<void> updateServiceType(String id, String name, String icon) async {
    try {
      await _apiService.put('photo-service-types/$id', {
        'name': name,
        'icon': icon,
      });
    } catch (e) {
      throw Exception('Error al actualizar tipo de servicio: $e');
    }
  }

  /// Eliminar tipo de producto
  Future<void> deleteProductType(String id) async {
    try {
      // Verificar si hay productos usando este tipo
      final productsResponse = await _apiService.get('photo-products', queryParams: {
        'product_type': id,
        'limit': '1',
      });

      if (productsResponse.success && productsResponse.data != null) {
        final products = productsResponse.data['photo_products'] as List? ?? [];
        if (products.isNotEmpty) {
          throw Exception('No se puede eliminar: hay productos usando este tipo');
        }
      }

      await _apiService.delete('photo-product-types/$id');
    } catch (e) {
      throw Exception('Error al eliminar tipo de producto: $e');
    }
  }

  /// Eliminar tipo de servicio
  Future<void> deleteServiceType(String id) async {
    try {
      // Verificar si hay servicios usando este tipo
      final servicesResponse = await _apiService.get('photo-services', queryParams: {
        'service_type': id,
        'limit': '1',
      });

      if (servicesResponse.success && servicesResponse.data != null) {
        final services = servicesResponse.data['photo_services'] as List? ?? [];
        if (services.isNotEmpty) {
          throw Exception('No se puede eliminar: hay servicios usando este tipo');
        }
      }

      await _apiService.delete('photo-service-types/$id');
    } catch (e) {
      throw Exception('Error al eliminar tipo de servicio: $e');
    }
  }

  /// Importar tipos predeterminados de productos
  Future<void> importDefaultProductTypes() async {
    final defaultTypes = [
      {'name': 'Marco', 'icon': 'crop_square'},
      {'name': 'Álbum', 'icon': 'photo_album'},
      {'name': 'Lienzo', 'icon': 'image'},
      {'name': 'Otro', 'icon': 'more_horiz'},
    ];

    for (var type in defaultTypes) {
      await addProductType(type['name']!, type['icon']!);
    }
  }

  /// Importar tipos predeterminados de servicios
  Future<void> importDefaultServiceTypes() async {
    final defaultTypes = [
      {'name': 'Impresión', 'icon': 'print'},
      {'name': 'Revelado', 'icon': 'photo'},
      {'name': 'Digitalización', 'icon': 'scanner'},
      {'name': 'Restauración', 'icon': 'healing'},
      {'name': 'Otro', 'icon': 'more_horiz'},
    ];

    for (var type in defaultTypes) {
      await addServiceType(type['name']!, type['icon']!);
    }
  }
}
