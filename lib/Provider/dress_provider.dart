import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../model/dress_model.dart';
import '../services/api_service.dart';
import 'branch_provider.dart';

/// ============================================================================
/// DRESS PROVIDER - VERSIÓN REACTIVA CON BRANCH PROVIDER
/// ============================================================================
///
/// Este provider ahora depende de branchIdProvider, lo que significa que:
/// - Cuando el usuario cambia de sucursal, branchIdProvider.state cambia
/// - Riverpod detecta el cambio y INVALIDA automáticamente este provider
/// - Los datos se recargan con la nueva sucursal
///
/// ESTO GARANTIZA que el cambio de sucursal siempre funcione.
/// ============================================================================

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Subir imagen a Firebase Storage (se mantiene para almacenamiento de imágenes)
Future<String> uploadImageToFirebase(dynamic imageFile) async {
  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('Admin Panel/dress_images/$fileName');

    if (kIsWeb) {
      // Handle web platform
      if (imageFile is XFile) {
        Uint8List bytes = await imageFile.readAsBytes();
        await storageRef.putData(
            bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else if (imageFile is Uint8List) {
        await storageRef.putData(
            imageFile, SettableMetadata(contentType: 'image/jpeg'));
      } else if (imageFile is File) {
        // For web, when File object is passed (might happen in some cases)
        Uint8List bytes = await imageFile.readAsBytes();
        await storageRef.putData(
            bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        throw Exception(
            "Unsupported file type for web: ${imageFile.runtimeType}");
      }
    } else {
      // Handle mobile platforms
      File file;
      if (imageFile is XFile) {
        file = File(imageFile.path);
      } else if (imageFile is File) {
        file = imageFile;
      } else {
        throw Exception(
            "Unsupported file type for mobile: ${imageFile.runtimeType}");
      }
      await storageRef.putFile(file);
    }

    return await storageRef.getDownloadURL();
  } catch (e) {
    rethrow;
  }
}

/// Subir múltiples imágenes y retornar URLs
Future<List<String>> uploadMultipleImages(List<dynamic> imageFiles) async {
  List<String> imageUrls = [];

  for (var imageFile in imageFiles) {
    String url = await uploadImageToFirebase(imageFile);
    if (url.isNotEmpty) {
      imageUrls.add(url);
    }
  }

  return imageUrls;
}

/// Agregar un nuevo vestido con URLs de imágenes - Usa PostgreSQL API
final addDressProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  try {
    DressModel dress = data['dress'] as DressModel;
    List<dynamic> imageFiles = data['imageFiles'] as List<dynamic>;

    // Convert XFiles to Uint8List if on web
    if (kIsWeb) {
      List<Uint8List> webImages = [];
      for (var file in imageFiles) {
        if (file is XFile) {
          webImages.add(await file.readAsBytes());
        } else if (file is Uint8List) {
          webImages.add(file);
        }
      }
      imageFiles = webImages;
    }

    // Upload new images if any (still uses Firebase Storage)
    List<String> newImageUrls = await uploadMultipleImages(imageFiles);

    // Combine with existing image URLs if editing
    List<String> allImageUrls = [...dress.images, ...newImageUrls];

    // Preparar datos para la API
    final dressData = {
      'name': dress.name,
      'category': dress.category,
      'subcategory': dress.subcategory,
      'branch_id': dress.branchId,
      'available': dress.available,
      'images': allImageUrls,
      'price': dress.price,
    };

    // Guardar vestido en PostgreSQL
    final response = await _apiService.post('dresses', dressData);

    return response.success;
  } catch (e) {
    return false;
  }
});

/// Actualizar un vestido existente - Usa PostgreSQL API
final updateDressProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  try {
    DressModel dress = data['dress'] as DressModel;
    List<dynamic> newImageFiles = data['imageFiles'] as List<dynamic>;

    // Convert XFiles to Uint8List if on web
    if (kIsWeb) {
      List<Uint8List> webImages = [];
      for (var file in newImageFiles) {
        if (file is XFile) {
          webImages.add(await file.readAsBytes());
        } else if (file is Uint8List) {
          webImages.add(file);
        }
      }
      newImageFiles = webImages;
    }

    // Upload new images if any (still uses Firebase Storage)
    List<String> newImageUrls = [];
    if (newImageFiles.isNotEmpty) {
      newImageUrls = await uploadMultipleImages(newImageFiles);
    }

    // Combine all images
    List<String> allImageUrls = [...dress.images, ...newImageUrls];

    // Preparar datos para actualizar
    final updateData = {
      'name': dress.name,
      'category': dress.category,
      'subcategory': dress.subcategory,
      'branch_id': dress.branchId,
      'available': dress.available,
      'images': allImageUrls,
      'price': dress.price,
    };

    // Actualizar en PostgreSQL
    final response = await _apiService.put('dresses/${dress.id}', updateData);

    return response.success;
  } catch (e) {
    return false;
  }
});

/// Eliminar un vestido - Usa PostgreSQL API
final deleteDressProvider =
    FutureProvider.family<bool, String>((ref, dressId) async {
  try {
    final response = await _apiService.delete('dresses/$dressId');
    return response.success;
  } catch (e) {
    return false;
  }
});

/// Cambiar disponibilidad del vestido - Usa PostgreSQL API
final toggleDressAvailabilityProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  try {
    String dressId = data['dressId'] as String;
    bool newAvailability = data['available'] as bool;

    final response = await _apiService.put('dresses/$dressId', {
      'available': newAvailability,
    });

    return response.success;
  } catch (e) {
    return false;
  }
});

/// Cambiar estado del vestido - Usa PostgreSQL API
final changeStateProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  try {
    String dressId = data['dressId'] as String;
    bool newAvailability = data['available'] as bool;
    String state = data['state'] as String;

    final response = await _apiService.put('dresses/$dressId', {
      'available': newAvailability,
      'state': state,
    });

    return response.success;
  } catch (e) {
    return false;
  }
});

/// ============================================================================
/// PROVIDER PRINCIPAL DE VESTIDOS - AHORA REACTIVO AL BRANCH
/// ============================================================================
///
/// Este provider:
/// 1. Observa branchIdProvider con ref.watch()
/// 2. Cuando branchId cambia, Riverpod INVALIDA este provider automáticamente
/// 3. Se ejecuta fetchDresses() con el nuevo branch
/// 4. Los datos se actualizan en la UI
/// ============================================================================
final dressesProvider = StreamProvider<List<DressModel>>((ref) {
  // ⚠️ CLAVE: Observamos el branchId - esto crea la dependencia reactiva
  final branchId = ref.watch(branchIdProvider);

  final controller = StreamController<List<DressModel>>();

  Future<void> fetchDresses() async {
    try {
      debugPrint('🔄 [dressesProvider] Cargando vestidos para branch: $branchId');

      final response = await _apiService.get('dresses', queryParams: {'limit': '5000'});

      if (response.success && response.data != null) {
        final dressesData = response.data['dresses'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            // Verificar campos mínimos
            if (data.containsKey('name') && data.containsKey('category')) {
              final id = data['id']?.toString() ?? '';
              dresses.add(DressModel.fromMap(data, id));
            }
          }
        }

        debugPrint('✅ [dressesProvider] Cargados ${dresses.length} vestidos para branch: $branchId');
        controller.add(dresses);
      } else {
        controller.add([]);
      }
    } catch (e) {
      debugPrint('❌ [dressesProvider] Error: $e');
      controller.add([]);
    }
  }

  // Fetch inicial
  fetchDresses();

  // Refresh periódico cada 30 segundos
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchDresses());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Proveedor de vestidos disponibles por componente/categoría - Usa PostgreSQL API
/// AHORA REACTIVO AL BRANCH
final availableDressesByComponentsProvider =
    StreamProvider.family<List<DressModel>, String>((ref, String category) {
  // ⚠️ CLAVE: Observamos el branchId
  final branchId = ref.watch(branchIdProvider);

  final controller = StreamController<List<DressModel>>();

  Future<void> fetchDresses() async {
    try {
      debugPrint('🔄 [availableDressesByComponentsProvider] branch: $branchId, category: $category');

      final response = await _apiService.get('dresses', queryParams: {
        'category': category,
        'limit': '100',
      });

      if (response.success && response.data != null) {
        final dressesData = response.data['dresses'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            final dressCategory = data['category'];
            if (dressCategory != null && dressCategory == category) {
              final id = data['id']?.toString() ?? '';
              dresses.add(DressModel.fromMap(data, id));
            }
          }
        }

        // Ordenar disponibles primero
        dresses.sort(
            (a, b) => a.available == b.available ? 0 : (a.available ? -1 : 1));

        controller.add(dresses);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.addError('Error al procesar los datos de vestidos. Intenta de nuevo.');
    }
  }

  // Fetch inicial
  fetchDresses();

  // Refresh periódico
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchDresses());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Proveedor de vestidos (una sola vez) por categoría - Usa PostgreSQL API
/// AHORA REACTIVO AL BRANCH
final dressesOnceProvider = FutureProvider.family<List<DressModel>, String>(
    (ref, String category) async {
  // ⚠️ CLAVE: Observamos el branchId
  final branchId = ref.watch(branchIdProvider);

  try {
    debugPrint('🔄 [dressesOnceProvider] branch: $branchId, category: $category');

    final response = await _apiService.get('dresses', queryParams: {
      'limit': '5000',
    });

    if (!response.success || response.data == null) return [];

    final dressesData = response.data['dresses'] as List<dynamic>? ?? [];
    List<DressModel> dresses = [];

    for (var item in dressesData) {
      if (item is Map) {
        final data = Map<String, dynamic>.from(item);
        final id = data['id']?.toString() ?? '';

        // Si no hay categoría especificada, incluir todos
        if (category.isEmpty) {
          dresses.add(DressModel.fromMap(data, id));
        } else {
          // Filtro flexible: coincidencia exacta o si la categoría del vestido contiene el término
          final dressCategory = (data['category'] ?? '').toString().toLowerCase();
          final searchCategory = category.toLowerCase();

          // Incluir si: coincide exactamente, contiene el término, o términos relacionados
          if (dressCategory == searchCategory ||
              dressCategory.contains(searchCategory) ||
              searchCategory.contains(dressCategory) ||
              // Mapeo de categorías de productos a categorías de vestidos
              _categoryMatches(searchCategory, dressCategory)) {
            dresses.add(DressModel.fromMap(data, id));
          }
        }
      }
    }

    // Si no hay vestidos con filtro, retornar todos para evitar pantalla vacía
    if (dresses.isEmpty && category.isNotEmpty) {
      for (var item in dressesData) {
        if (item is Map) {
          final data = Map<String, dynamic>.from(item);
          final id = data['id']?.toString() ?? '';
          dresses.add(DressModel.fromMap(data, id));
        }
      }
    }

    // Ordenar disponibles primero
    dresses.sort(
        (a, b) => a.available == b.available ? 0 : (a.available ? -1 : 1));

    debugPrint('✅ [dressesOnceProvider] Cargados ${dresses.length} vestidos');
    return dresses;
  } catch (e) {
    debugPrint('❌ [dressesOnceProvider] Error: $e');
    throw 'Error al cargar los vestidos. Por favor, intenta de nuevo.';
  }
});

/// Función auxiliar para mapear categorías de productos a categorías de vestidos
bool _categoryMatches(String productCategory, String dressCategory) {
  // Mapeos de categorías de productos a categorías de vestidos
  final Map<String, List<String>> categoryMappings = {
    'dama': ['vestidos', 'vestido de madre', 'vestidos colección cristal', 'vestidos cortos'],
    'niña': ['vestidos de niñas', 'niñas'],
    'caballero': ['trajes'],
    'niño': ['trajes'],
    'accesorios': ['corona', 'ramos'],
  };

  // Buscar coincidencias en el mapeo
  for (var entry in categoryMappings.entries) {
    if (productCategory.contains(entry.key)) {
      for (var dressMatch in entry.value) {
        if (dressCategory.contains(dressMatch)) {
          return true;
        }
      }
    }
  }

  return false;
}

/// Obtener un solo vestido - Usa PostgreSQL API
final singleDressProvider =
    FutureProvider.family<DressModel?, String>((ref, dressId) async {
  try {
    final response = await _apiService.get('dresses/$dressId');

    if (response.success && response.data != null) {
      final data = response.data['dress'] as Map<String, dynamic>? ?? response.data;
      if (data.isNotEmpty) {
        final id = data['id']?.toString() ?? dressId;
        return DressModel.fromMap(Map<String, dynamic>.from(data), id);
      }
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Obtener vestidos por categoría - Usa PostgreSQL API con StreamController
/// AHORA REACTIVO AL BRANCH
final dressesByCategoryProvider =
    StreamProvider.family<List<DressModel>, String>((ref, category) {
  // ⚠️ CLAVE: Observamos el branchId
  final branchId = ref.watch(branchIdProvider);

  final controller = StreamController<List<DressModel>>();

  Future<void> fetchDresses() async {
    try {
      debugPrint('🔄 [dressesByCategoryProvider] branch: $branchId, category: $category');

      final response = await _apiService.get('dresses', queryParams: {
        'category': category,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final dressesData = response.data['dresses'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            final id = data['id']?.toString() ?? '';
            dresses.add(DressModel.fromMap(data, id));
          }
        }

        controller.add(dresses);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.add([]);
    }
  }

  // Fetch inicial
  fetchDresses();

  // Refresh periódico
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchDresses());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// ============================================================================
/// PROVIDER DE CATEGORÍAS DE VESTIDOS
/// ============================================================================
/// Este provider extrae las categorías únicas de los vestidos.
/// Se usa en RegisterPackageScreen para los dropdowns de "Componentes"
/// (que son categorías de vestidos, NO categorías de servicios).
/// ============================================================================
final dressCategoriesProvider = FutureProvider<List<String>>((ref) async {
  // Observar el branchId para reaccionar a cambios de sucursal
  final branchId = ref.watch(branchIdProvider);

  try {
    debugPrint('🔄 [dressCategoriesProvider] Cargando categorías de vestidos para branch: $branchId');

    final response = await _apiService.get('dresses', queryParams: {'limit': '5000'});

    if (response.success && response.data != null) {
      final dressesData = response.data['dresses'] as List<dynamic>? ?? [];

      // Extraer categorías únicas
      final Set<String> categoriesSet = {};
      for (var item in dressesData) {
        if (item is Map) {
          final category = item['category']?.toString();
          if (category != null && category.isNotEmpty) {
            categoriesSet.add(category);
          }
        }
      }

      // Convertir a lista y ordenar
      final categories = categoriesSet.toList()..sort();

      debugPrint('✅ [dressCategoriesProvider] Encontradas ${categories.length} categorías: $categories');
      return categories;
    }

    return [];
  } catch (e) {
    debugPrint('❌ [dressCategoriesProvider] Error: $e');
    return [];
  }
});

/// Obtener vestidos por sucursal - Usa PostgreSQL API con StreamController
/// AHORA REACTIVO AL BRANCH
final dressesByBranchProvider =
    StreamProvider.family<List<DressModel>, String>((ref, branchId) {
  // Nota: Este provider usa el branchId del parámetro, no del provider
  // Pero aún observamos el branchIdProvider para invalidar cuando cambie globalmente
  ref.watch(branchIdProvider);

  final controller = StreamController<List<DressModel>>();

  Future<void> fetchDresses() async {
    try {
      final response = await _apiService.get('dresses', queryParams: {
        'branch_id': branchId,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final dressesData = response.data['dresses'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            final id = data['id']?.toString() ?? '';
            dresses.add(DressModel.fromMap(data, id));
          }
        }

        controller.add(dresses);
      } else {
        controller.add([]);
      }
    } catch (e) {
      controller.add([]);
    }
  }

  // Fetch inicial
  fetchDresses();

  // Refresh periódico
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchDresses());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
