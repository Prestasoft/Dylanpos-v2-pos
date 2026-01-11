import 'package:flutter/foundation.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';

import '../services/api_service.dart';

/// Repositorio de paquetes de servicio - Usa PostgreSQL API
class ServicePackageRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los paquetes de servicio desde PostgreSQL
  Future<List<ServicePackageModel>> getAllPackages() async {
    try {
      debugPrint('📦 ServicePackageRepository: Cargando paquetes desde PostgreSQL API...');

      final response = await _apiService.getServices(limit: 1000);

      if (response.success && response.data != null) {
        final packagesData = response.data['services'] as List<dynamic>? ?? [];

        debugPrint('📦 Paquetes encontrados: ${packagesData.length}');

        final packages = packagesData.map((data) {
          return ServicePackageModel.fromMap(data as Map<String, dynamic>, data['id']?.toString() ?? '');
        }).toList();

        debugPrint('📦 Paquetes parseados exitosamente: ${packages.length}');
        return packages;
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ ServicePackageRepository Error: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      return [];
    }
  }

  /// Agregar un paquete de servicio
  Future<bool> addPackage(ServicePackageModel newPackage) async {
    try {
      final packageData = {
        'name': newPackage.name,
        'category': newPackage.category,
        'subcategory': newPackage.subcategory,
        'price': newPackage.price,
        'duration': newPackage.duration,
        'components': newPackage.components,
      };

      final response = await _apiService.createService(packageData);
      return response.success;
    } catch (e) {
      debugPrint('❌ Error al agregar paquete: $e');
      return false;
    }
  }

  /// Actualizar un paquete de servicio
  Future<bool> updatePackage(ServicePackageModel updatedPackage) async {
    try {
      final packageData = {
        'name': updatedPackage.name,
        'category': updatedPackage.category,
        'subcategory': updatedPackage.subcategory,
        'price': updatedPackage.price,
        'duration': updatedPackage.duration,
        'components': updatedPackage.components,
      };

      final response = await _apiService.put('services/${updatedPackage.id}', packageData);
      return response.success;
    } catch (e) {
      debugPrint('❌ Error al actualizar paquete: $e');
      return false;
    }
  }

  /// Eliminar un paquete de servicio
  Future<bool> deletePackage(String packageId) async {
    try {
      final response = await _apiService.delete('services/$packageId');
      return response.success;
    } catch (e) {
      debugPrint('❌ Error al eliminar paquete: $e');
      return false;
    }
  }
}
