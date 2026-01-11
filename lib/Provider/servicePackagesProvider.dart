import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';
import 'package:salespro_admin/Provider/branch_provider.dart';
import '../services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Estado inicial
final initialServicePackagesState =
    AsyncValue<List<ServicePackageModel>>.loading();

/// Provider principal - Usa PostgreSQL API
/// ⚠️ CLAVE: Observamos el branchId para crear la dependencia reactiva
final servicePackagesProvider = StateNotifierProvider<ServicePackageNotifier,
    AsyncValue<List<ServicePackageModel>>>((ref) {
  // Cuando cambie el branchId, este provider se recreará automáticamente
  final branchId = ref.watch(branchIdProvider);
  debugPrint('🔄 [servicePackagesProvider] Creando notifier para branch: $branchId');
  return ServicePackageNotifier(ref);
});

/// Notifier - Migrado a PostgreSQL API
class ServicePackageNotifier
    extends StateNotifier<AsyncValue<List<ServicePackageModel>>> {
  final Ref ref;

  ServicePackageNotifier(this.ref) : super(initialServicePackagesState) {
    // Cargar paquetes al inicializar
    loadPackages();
  }

  /// Cargar todos los paquetes de servicio desde PostgreSQL
  Future<void> loadPackages() async {
    try {
      state = const AsyncValue.loading(); // Mostrar estado de carga

      final response = await _apiService.get('services', queryParams: {'limit': '5000'});

      if (response.success && response.data != null) {
        final packages = <ServicePackageModel>[];
        final servicesData = response.data['services'] as List<dynamic>? ?? [];

        for (final element in servicesData) {
          try {
            if (element is Map) {
              final data = Map<String, dynamic>.from(element);
              final id = data['id']?.toString() ?? 'default_key';
              packages.add(ServicePackageModel.fromMap(data, id));
            }
          } catch (e) {
            // Error silencioso para elementos inválidos
          }
        }

        // Ordenar por fecha de creación (más recientes primero)
        packages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = AsyncValue.data(packages);
      } else {
        state = const AsyncValue.data([]); // No hay datos
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Agregar un nuevo paquete - Usa PostgreSQL API
  Future<bool> addPackage(ServicePackageModel newPackage) async {
    try {
      // Validar datos antes de guardar
      if (newPackage.name.isEmpty || newPackage.category.isEmpty) {
        throw Exception('Nombre y categoría son requeridos');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      final packageData = {
        'type': newPackage.type,
        'name': newPackage.name,
        'category': newPackage.category,
        'subcategory': newPackage.subcategory,
        'description': newPackage.description,
        'price': newPackage.price,
        'duration': newPackage.duration,
        'components': newPackage.components,
        'branches': newPackage.branches,
        'created_at': now,
        'updated_at': now,
      };

      final response = await _apiService.post('services', packageData);

      if (response.success) {
        // Obtener ID del nuevo paquete
        final newId = response.data?['service']?['id']?.toString() ??
                      response.data?['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString();

        // Actualizar estado local
        final addedPackage = newPackage.copyWith(
          id: newId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(now),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
        );

        state.whenData((packages) {
          state = AsyncValue.data([addedPackage, ...packages]);
        });

        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar un paquete existente - Usa PostgreSQL API
  Future<bool> updatePackage(ServicePackageModel updatedPackage) async {
    try {
      if (updatedPackage.id.isEmpty) {
        throw Exception('ID de paquete inválido');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      final updateData = {
        'type': updatedPackage.type,
        'name': updatedPackage.name,
        'category': updatedPackage.category,
        'subcategory': updatedPackage.subcategory,
        'description': updatedPackage.description,
        'price': updatedPackage.price,
        'duration': updatedPackage.duration,
        'components': updatedPackage.components,
        'branches': updatedPackage.branches,
        'updated_at': now,
      };

      final response = await _apiService.put('services/${updatedPackage.id}', updateData);

      if (response.success) {
        // Actualizar estado local
        final updated = updatedPackage.copyWith(
          updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
        );

        state.whenData((packages) {
          state = AsyncValue.data(
              packages.map((p) => p.id == updated.id ? updated : p).toList());
        });

        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar un paquete - Usa PostgreSQL API
  Future<bool> deletePackage(String packageId) async {
    try {
      if (packageId.isEmpty) {
        throw Exception('ID de paquete inválido');
      }

      final response = await _apiService.delete('services/$packageId');

      if (response.success) {
        // Actualizar estado local
        state.whenData((packages) {
          state =
              AsyncValue.data(packages.where((p) => p.id != packageId).toList());
        });

        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Buscar paquetes por nombre
  List<ServicePackageModel> searchPackages(String query) {
    return state.when(
      loading: () => [],
      error: (_, __) => [],
      data: (packages) {
        if (query.isEmpty) return packages;

        return packages
            .where((package) =>
                package.name.toLowerCase().contains(query.toLowerCase()) ||
                package.category.toLowerCase().contains(query.toLowerCase()) ||
                package.subcategory.toLowerCase().contains(query.toLowerCase()))
            .toList();
      },
    );
  }

  /// Obtener un paquete por ID
  ServicePackageModel? getPackageById(String id) {
    return state.when(
      loading: () => null,
      error: (_, __) => null,
      data: (packages) {
        try {
          return packages.firstWhere((package) => package.id == id);
        } catch (e) {
          return null;
        }
      },
    );
  }
}

/// Providers adicionales para funcionalidades específicas
final packageSearchProvider =
    Provider.family<List<ServicePackageModel>, String>((ref, query) {
  return ref.watch(servicePackagesProvider.notifier).searchPackages(query);
});

final packageByIdProvider =
    Provider.family<ServicePackageModel?, String>((ref, id) {
  return ref.watch(servicePackagesProvider.notifier).getPackageById(id);
});

/// Provider alternativo con Future para obtener paquete por ID
final packageByIdProviderA1 =
    FutureProvider.family<ServicePackageModel?, String>((ref, id) async {
  return ref.watch(servicePackagesProvider.notifier).getPackageById(id);
});

/// Provider adicional para obtener paquete directamente desde API
final singlePackageProvider =
    FutureProvider.family<ServicePackageModel?, String>((ref, packageId) async {
  try {
    final response = await _apiService.get('services/$packageId');

    if (response.success && response.data != null) {
      final data = response.data['service'] as Map<String, dynamic>? ?? response.data;
      if (data.isNotEmpty) {
        final id = data['id']?.toString() ?? packageId;
        return ServicePackageModel.fromMap(Map<String, dynamic>.from(data), id);
      }
    }
    return null;
  } catch (e) {
    return null;
  }
});
