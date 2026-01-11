import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';
import '../services/api_service.dart';

/// Repositorio de productos y servicios fotográficos - Usa PostgreSQL API
class PhotoProductsServicesRepository {
  final String userId;
  final ApiService _apiService = ApiService();

  PhotoProductsServicesRepository({required this.userId});

  // ==================== PRODUCTOS ====================

  /// Guardar un nuevo producto
  Future<String> saveProduct(FrameProductModel product) async {
    try {
      debugPrint('Guardando producto en PostgreSQL API...');

      final productData = product.toJson();
      final response = await _apiService.post('photo-products', productData);

      if (response.success && response.data != null) {
        final savedProduct = response.data['photo_product'];
        final productId = savedProduct?['id']?.toString() ?? '';
        debugPrint('Producto guardado exitosamente: ${product.productName}');
        return productId;
      }
      throw Exception('Error al guardar el producto');
    } catch (e) {
      debugPrint('Error al guardar producto: $e');
      throw Exception('Error al guardar el producto: $e');
    }
  }

  /// Obtener todos los productos (como Stream para compatibilidad)
  Stream<List<FrameProductModel>> getProducts() {
    final controller = StreamController<List<FrameProductModel>>();

    _fetchProducts().then((products) {
      controller.add(products);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  /// Obtener productos desde PostgreSQL
  Future<List<FrameProductModel>> _fetchProducts() async {
    try {
      final response = await _apiService.get('photo-products', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final productsData = response.data['photo_products'] as List<dynamic>? ?? [];

        final products = productsData.map((data) {
          final productData = Map<String, dynamic>.from(data as Map);
          productData['productId'] = productData['id']?.toString();
          return FrameProductModel.fromJson(productData);
        }).toList();

        // Ordenar por nombre
        products.sort((a, b) => a.productName.compareTo(b.productName));
        return products;
      }
      return [];
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      return [];
    }
  }

  /// Actualizar un producto
  Future<void> updateProduct(FrameProductModel product) async {
    try {
      if (product.productId == null || product.productId!.isEmpty) {
        throw Exception('El producto debe tener un ID');
      }

      final productData = product.toJson();
      await _apiService.put('photo-products/${product.productId}', productData);

      debugPrint('Producto actualizado: ${product.productName}');
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
      throw Exception('Error al actualizar el producto: $e');
    }
  }

  /// Eliminar un producto
  Future<void> deleteProduct(String productId) async {
    try {
      // Primero verificar si el producto tiene ventas
      final hasInvoices = await _productHasInvoices(productId);
      if (hasInvoices) {
        throw Exception('No se puede eliminar el producto porque tiene ventas registradas');
      }

      await _apiService.delete('photo-products/$productId');
      debugPrint('Producto eliminado: $productId');
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      rethrow;
    }
  }

  /// Verificar si un producto tiene facturas asociadas
  Future<bool> _productHasInvoices(String productId) async {
    try {
      final response = await _apiService.get('photo-invoices', queryParams: {
        'product_id': productId,
        'limit': '1',
      });

      if (response.success && response.data != null) {
        final invoices = response.data['photo_invoices'] as List? ?? [];
        return invoices.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('Error verificando facturas del producto: $e');
      return true; // Por seguridad, si hay error asumimos que tiene facturas
    }
  }

  // ==================== SERVICIOS ====================

  /// Guardar un nuevo servicio
  Future<String> saveService(PhotoServiceModel service) async {
    try {
      debugPrint('Guardando servicio en PostgreSQL API...');

      final serviceData = service.toJson();
      final response = await _apiService.post('photo-services', serviceData);

      if (response.success && response.data != null) {
        final savedService = response.data['photo_service'];
        final serviceId = savedService?['id']?.toString() ?? '';
        debugPrint('Servicio guardado exitosamente: ${service.serviceName}');
        return serviceId;
      }
      throw Exception('Error al guardar el servicio');
    } catch (e) {
      debugPrint('Error al guardar servicio: $e');
      throw Exception('Error al guardar el servicio: $e');
    }
  }

  /// Obtener todos los servicios (como Stream para compatibilidad)
  Stream<List<PhotoServiceModel>> getServices() {
    final controller = StreamController<List<PhotoServiceModel>>();

    _fetchServices().then((services) {
      controller.add(services);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  /// Obtener servicios desde PostgreSQL
  Future<List<PhotoServiceModel>> _fetchServices() async {
    try {
      final response = await _apiService.get('photo-services', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final servicesData = response.data['photo_services'] as List<dynamic>? ?? [];

        final services = servicesData.map((data) {
          final serviceData = Map<String, dynamic>.from(data as Map);
          serviceData['serviceId'] = serviceData['id']?.toString();
          return PhotoServiceModel.fromJson(serviceData);
        }).toList();

        // Ordenar por nombre
        services.sort((a, b) => a.serviceName.compareTo(b.serviceName));
        return services;
      }
      return [];
    } catch (e) {
      debugPrint('Error al obtener servicios: $e');
      return [];
    }
  }

  /// Actualizar un servicio
  Future<void> updateService(PhotoServiceModel service) async {
    try {
      if (service.serviceId == null || service.serviceId!.isEmpty) {
        throw Exception('El servicio debe tener un ID');
      }

      final serviceData = service.toJson();
      await _apiService.put('photo-services/${service.serviceId}', serviceData);

      debugPrint('Servicio actualizado: ${service.serviceName}');
    } catch (e) {
      debugPrint('Error al actualizar servicio: $e');
      throw Exception('Error al actualizar el servicio: $e');
    }
  }

  /// Eliminar un servicio
  Future<void> deleteService(String serviceId) async {
    try {
      // Primero verificar si el servicio tiene ventas
      final hasInvoices = await _serviceHasInvoices(serviceId);
      if (hasInvoices) {
        throw Exception('No se puede eliminar el servicio porque tiene ventas registradas');
      }

      await _apiService.delete('photo-services/$serviceId');
      debugPrint('Servicio eliminado: $serviceId');
    } catch (e) {
      debugPrint('Error al eliminar servicio: $e');
      rethrow;
    }
  }

  /// Verificar si un servicio tiene facturas asociadas
  Future<bool> _serviceHasInvoices(String serviceId) async {
    try {
      final response = await _apiService.get('photo-invoices', queryParams: {
        'service_id': serviceId,
        'limit': '1',
      });

      if (response.success && response.data != null) {
        final invoices = response.data['photo_invoices'] as List? ?? [];
        return invoices.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('Error verificando facturas del servicio: $e');
      return true; // Por seguridad, si hay error asumimos que tiene facturas
    }
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Importar productos predefinidos (para migración inicial)
  Future<void> importDefaultProducts(List<FrameProductModel> products) async {
    try {
      for (var product in products) {
        await saveProduct(product);
      }
      debugPrint('${products.length} productos importados exitosamente');
    } catch (e) {
      debugPrint('Error importando productos: $e');
      throw Exception('Error al importar productos: $e');
    }
  }

  /// Importar servicios predefinidos (para migración inicial)
  Future<void> importDefaultServices(List<PhotoServiceModel> services) async {
    try {
      for (var service in services) {
        await saveService(service);
      }
      debugPrint('${services.length} servicios importados exitosamente');
    } catch (e) {
      debugPrint('Error importando servicios: $e');
      throw Exception('Error al importar servicios: $e');
    }
  }
}
