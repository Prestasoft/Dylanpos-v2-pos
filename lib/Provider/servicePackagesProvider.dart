import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';

// Estado inicial
final initialServicePackagesState =
    AsyncValue<List<ServicePackageModel>>.loading();

// Provider principal
final servicePackagesProvider = StateNotifierProvider<ServicePackageNotifier,
    AsyncValue<List<ServicePackageModel>>>((ref) {
  return ServicePackageNotifier(ref);
});

// Notifier
class ServicePackageNotifier
    extends StateNotifier<AsyncValue<List<ServicePackageModel>>> {
  final Ref ref;
  final DatabaseReference _dbRef;

  ServicePackageNotifier(this.ref)
      : _dbRef = FirebaseDatabase.instance.ref('Admin Panel/services'),
        super(initialServicePackagesState) {
    // Cargar paquetes al inicializar
    loadPackages();
  }

  /// Cargar todos los paquetes de servicio
  Future<void> loadPackages() async {
    try {
      state = const AsyncValue.loading(); // Mostrar estado de carga

      final snapshot = await _dbRef.get();
      print(
          'Snapshot: ${snapshot.value}'); // Ver qué datos están siendo devueltos
      if (snapshot.exists) {
        final packages = <ServicePackageModel>[];

        for (final element in snapshot.children) {
          try {
            final data = ServicePackageModel.fromMap(
              Map<String, dynamic>.from(element.value as Map),
              element.key ?? 'default_key',
            );
            packages.add(data);
          } catch (e) {
            print('Error parsing package ${element.key}: $e');
          }
        }
        // Ordenar por fecha de creación (más recientes primero)
        packages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = AsyncValue.data(packages);
      } else {
        print('No data found at the specified reference.');
        state = const AsyncValue.data([]); // No hay datos
      }
    } catch (e) {
      print('Error loading packages: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Agregar un nuevo paquete
  Future<bool> addPackage(ServicePackageModel newPackage) async {
    try {
      // Validar datos antes de guardar
      if (newPackage.name.isEmpty || newPackage.category.isEmpty) {
        throw Exception('Nombre y categoría son requeridos');
      }

      final newRef = _dbRef.push();
      final now = DateTime.now().millisecondsSinceEpoch;

      await newRef.set({
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
      });

      // Actualizar estado local
      final addedPackage = newPackage.copyWith(
        id: newRef.key,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );

      state.whenData((packages) {
        state = AsyncValue.data([addedPackage, ...packages]);
      });

      return true;
    } catch (e) {
      print('Error adding package: $e');
      rethrow;
    }
  }

  /// Actualizar un paquete existente
  Future<bool> updatePackage(ServicePackageModel updatedPackage) async {
    try {
      if (updatedPackage.id.isEmpty) {
        throw Exception('ID de paquete inválido');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _dbRef.child(updatedPackage.id).update({
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
      });

      // Actualizar estado local
      final updated = updatedPackage.copyWith(
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );

      state.whenData((packages) {
        state = AsyncValue.data(
            packages.map((p) => p.id == updated.id ? updated : p).toList());
      });

      return true;
    } catch (e) {
      print('Error updating package: $e');
      rethrow;
    }
  }

  /// Eliminar un paquete
  Future<bool> deletePackage(String packageId) async {
    try {
      if (packageId.isEmpty) {
        throw Exception('ID de paquete inválido');
      }

      await _dbRef.child(packageId).remove();

      // Actualizar estado local
      state.whenData((packages) {
        state =
            AsyncValue.data(packages.where((p) => p.id != packageId).toList());
      });

      return true;
    } catch (e) {
      print('Error deleting package: $e');
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

// Providers adicionales para funcionalidades específicas
final packageSearchProvider =
    Provider.family<List<ServicePackageModel>, String>((ref, query) {
  return ref.watch(servicePackagesProvider.notifier).searchPackages(query);
});

final packageByIdProvider =
    Provider.family<ServicePackageModel?, String>((ref, id) {
  return ref.watch(servicePackagesProvider.notifier).getPackageById(id);
});
// Cambia esto en el archivo donde tienes definido packageByIdProvider
final packageByIdProviderA1 =
    FutureProvider.family<ServicePackageModel?, String>((ref, id) async {
  return ref.watch(servicePackagesProvider.notifier).getPackageById(id);
});
