import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

/// Subir imagen al servidor propio (en lugar de Firebase Storage)
/// Usa el endpoint /api/upload/single con la categoría dress_images
Future<String> uploadImageToServer(dynamic imageFile) async {
  try {
    // Obtener bytes de la imagen
    Uint8List bytes;
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (imageFile is XFile) {
      bytes = await imageFile.readAsBytes();
      // Usar nombre original si está disponible
      if (imageFile.name.isNotEmpty) {
        fileName = imageFile.name;
      }
    } else if (imageFile is Uint8List) {
      bytes = imageFile;
    } else if (imageFile is File) {
      bytes = await imageFile.readAsBytes();
      fileName = imageFile.path.split('/').last;
    } else {
      throw Exception("Unsupported file type: ${imageFile.runtimeType}");
    }

    // Preparar multipart request
    final uri = Uri.parse('https://sistema.victorguzmanfotografia.com/api/upload/single?category=dress_images');
    final request = http.MultipartRequest('POST', uri);

    // Agregar headers de autenticación
    final token = _apiService.token;
    final branchId = _apiService.branchId;

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (branchId != null && branchId.isNotEmpty) {
      request.headers['X-Branch-Id'] = branchId;
    }

    // Agregar el archivo
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));

    debugPrint('📤 [uploadImageToServer] Subiendo imagen: $fileName');
    debugPrint('📤 [uploadImageToServer] Branch: $branchId');

    // Enviar request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['url'] != null) {
        debugPrint('✅ [uploadImageToServer] Imagen subida: ${jsonResponse['url']}');
        return jsonResponse['url'];
      }
    }

    debugPrint('❌ [uploadImageToServer] Error: ${response.statusCode} - ${response.body}');
    throw Exception('Error al subir imagen: ${response.statusCode}');
  } catch (e) {
    debugPrint('❌ [uploadImageToServer] Exception: $e');
    rethrow;
  }
}

/// Subir múltiples imágenes y retornar URLs
Future<List<String>> uploadMultipleImages(List<dynamic> imageFiles) async {
  List<String> imageUrls = [];

  for (var imageFile in imageFiles) {
    String url = await uploadImageToServer(imageFile);
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

    // Subir imágenes al servidor propio
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

    // Subir imágenes al servidor propio
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
      debugPrint('🔄 [dressesProvider] ApiService.isAuthenticated: ${_apiService.isAuthenticated}');
      debugPrint('🔄 [dressesProvider] ApiService.branchId: ${_apiService.branchId}');

      final response = await _apiService.get('dresses', queryParams: {'limit': '5000'});

      debugPrint('🔄 [dressesProvider] Response success: ${response.success}');
      debugPrint('🔄 [dressesProvider] Response error: ${response.error}');
      debugPrint('🔄 [dressesProvider] Response statusCode: ${response.statusCode}');

      if (response.success && response.data != null) {
        // El API puede devolver 'dresses' (formato completo) o 'd' (formato compacto)
        final dressesData = response.data['dresses'] as List<dynamic>? ??
                            response.data['d'] as List<dynamic>? ?? [];

        debugPrint('🔄 [dressesProvider] Datos recibidos: ${dressesData.length} items');

        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);

            // Soportar formato compacto (i=id, n=name, c=category, etc) y completo
            // Convertir thumbnail URL a imagen original (thumbnails no preservan orientación EXIF)
            String? thumbnailUrl = data['t']?.toString();
            String? originalUrl = thumbnailUrl?.replaceAll('/thumbnails/', '/');

            final Map<String, dynamic> normalizedData = {
              'id': data['id'] ?? data['i'] ?? '',
              'name': data['name'] ?? data['n'] ?? '',
              'category': data['category'] ?? data['c'] ?? '',
              'subcategory': data['subcategory'] ?? '',
              'branch_id': data['branch_id'] ?? data['b'] ?? '',  // Sucursal (formato compacto: b)
              'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
              'state': data['state'] ?? data['s'] ?? 'available',
              'images': data['images'] ?? (originalUrl != null ? [originalUrl] : []),
              'price': data['price'] ?? data['p'] ?? 0,
              'rental_price': data['rental_price'] ?? data['p'] ?? 0,
            };

            // Verificar campos mínimos
            if (normalizedData['name'] != null && normalizedData['name'].toString().isNotEmpty) {
              final id = normalizedData['id']?.toString() ?? '';
              dresses.add(DressModel.fromMap(normalizedData, id));
            }
          }
        }

        debugPrint('✅ [dressesProvider] Cargados ${dresses.length} vestidos para branch: $branchId');
        controller.add(dresses);
      } else {
        debugPrint('⚠️ [dressesProvider] No hay datos o error: ${response.error}');
        controller.add([]);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [dressesProvider] Error: $e');
      debugPrint('❌ [dressesProvider] StackTrace: $stackTrace');
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
        // El API puede devolver 'dresses' (formato completo) o 'd' (formato compacto)
        final dressesData = response.data['dresses'] as List<dynamic>? ??
                            response.data['d'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);

            // Soportar formato compacto (i=id, n=name, c=category, etc) y completo
            // Convertir thumbnail URL a imagen original
            String? thumbUrl = data['t']?.toString();
            String? origUrl = thumbUrl?.replaceAll('/thumbnails/', '/');

            final Map<String, dynamic> normalizedData = {
              'id': data['id'] ?? data['i'] ?? '',
              'name': data['name'] ?? data['n'] ?? '',
              'category': data['category'] ?? data['c'] ?? '',
              'subcategory': data['subcategory'] ?? '',
              'branch_id': data['branch_id'] ?? data['b'] ?? '',  // Sucursal
              'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
              'state': data['state'] ?? data['s'] ?? 'available',
              'images': data['images'] ?? (origUrl != null ? [origUrl] : []),
              'price': data['price'] ?? data['p'] ?? 0,
              'rental_price': data['rental_price'] ?? data['p'] ?? 0,
            };

            final dressCategory = normalizedData['category'];
            if (dressCategory != null && dressCategory == category) {
              final id = normalizedData['id']?.toString() ?? '';
              dresses.add(DressModel.fromMap(normalizedData, id));
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

    // El API puede devolver 'dresses' (formato completo) o 'd' (formato compacto)
    final dressesData = response.data['dresses'] as List<dynamic>? ??
                        response.data['d'] as List<dynamic>? ?? [];
    List<DressModel> dresses = [];

    for (var item in dressesData) {
      if (item is Map) {
        final data = Map<String, dynamic>.from(item);

        // Convertir thumbnail URL a imagen original
        String? thumbUrl2 = data['t']?.toString();
        String? origUrl2 = thumbUrl2?.replaceAll('/thumbnails/', '/');

        // Soportar formato compacto (i=id, n=name, c=category, etc) y completo
        final Map<String, dynamic> normalizedData = {
          'id': data['id'] ?? data['i'] ?? '',
          'name': data['name'] ?? data['n'] ?? '',
          'category': data['category'] ?? data['c'] ?? '',
          'subcategory': data['subcategory'] ?? '',
          'branch_id': data['branch_id'] ?? data['b'] ?? '',  // Sucursal
          'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
          'state': data['state'] ?? data['s'] ?? 'available',
          'images': data['images'] ?? (origUrl2 != null ? [origUrl2] : []),
          'price': data['price'] ?? data['p'] ?? 0,
          'rental_price': data['rental_price'] ?? data['p'] ?? 0,
        };

        final id = normalizedData['id']?.toString() ?? '';
        final dressCategory = (normalizedData['category'] ?? '').toString().toLowerCase();

        // Si no hay categoría especificada, incluir todos
        if (category.isEmpty) {
          dresses.add(DressModel.fromMap(normalizedData, id));
        } else {
          // Filtro flexible: coincidencia exacta o si la categoría del vestido contiene el término
          final searchCategory = category.toLowerCase();

          // Incluir si: coincide exactamente, contiene el término, o términos relacionados
          if (dressCategory == searchCategory ||
              dressCategory.contains(searchCategory) ||
              searchCategory.contains(dressCategory) ||
              // Mapeo de categorías de productos a categorías de vestidos
              _categoryMatches(searchCategory, dressCategory)) {
            dresses.add(DressModel.fromMap(normalizedData, id));
          }
        }
      }
    }

    // Si no hay vestidos con filtro, retornar todos para evitar pantalla vacía
    if (dresses.isEmpty && category.isNotEmpty) {
      for (var item in dressesData) {
        if (item is Map) {
          final data = Map<String, dynamic>.from(item);

          // Convertir thumbnail URL a imagen original
          String? thumbUrl3 = data['t']?.toString();
          String? origUrl3 = thumbUrl3?.replaceAll('/thumbnails/', '/');

          // Normalizar también aquí
          final Map<String, dynamic> normalizedData = {
            'id': data['id'] ?? data['i'] ?? '',
            'name': data['name'] ?? data['n'] ?? '',
            'category': data['category'] ?? data['c'] ?? '',
            'subcategory': data['subcategory'] ?? '',
            'branch_id': data['branch_id'] ?? data['b'] ?? '',  // Sucursal
            'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
            'state': data['state'] ?? data['s'] ?? 'available',
            'images': data['images'] ?? (origUrl3 != null ? [origUrl3] : []),
            'price': data['price'] ?? data['p'] ?? 0,
            'rental_price': data['rental_price'] ?? data['p'] ?? 0,
          };
          final id = normalizedData['id']?.toString() ?? '';
          dresses.add(DressModel.fromMap(normalizedData, id));
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
        // El API puede devolver 'dresses' (formato completo) o 'd' (formato compacto)
        final dressesData = response.data['dresses'] as List<dynamic>? ??
                            response.data['d'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);

            // Convertir thumbnail URL a imagen original
            String? thumbUrl4 = data['t']?.toString();
            String? origUrl4 = thumbUrl4?.replaceAll('/thumbnails/', '/');

            // Soportar formato compacto (i=id, n=name, c=category, etc) y completo
            final Map<String, dynamic> normalizedData = {
              'id': data['id'] ?? data['i'] ?? '',
              'name': data['name'] ?? data['n'] ?? '',
              'category': data['category'] ?? data['c'] ?? '',
              'subcategory': data['subcategory'] ?? '',
              'branch_id': data['branch_id'] ?? data['b'] ?? '',  // Sucursal
              'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
              'state': data['state'] ?? data['s'] ?? 'available',
              'images': data['images'] ?? (origUrl4 != null ? [origUrl4] : []),
              'price': data['price'] ?? data['p'] ?? 0,
              'rental_price': data['rental_price'] ?? data['p'] ?? 0,
            };

            final id = normalizedData['id']?.toString() ?? '';
            dresses.add(DressModel.fromMap(normalizedData, id));
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

    // Usar endpoint dedicado /api/dresses/categories que devuelve TODAS las categorías
    // directamente desde la BD, sin límite de vestidos
    final response = await _apiService.get('dresses/categories');

    if (response.success && response.data != null) {
      // El endpoint devuelve { categories: [...], total: N }
      final categoriesData = response.data['categories'] as List<dynamic>? ?? [];

      final categories = categoriesData
          .map((c) => c?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList();

      // Ya vienen ordenadas del backend, pero ordenamos por si acaso
      categories.sort();

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
        // El API puede devolver 'dresses' (formato completo) o 'd' (formato compacto)
        final dressesData = response.data['dresses'] as List<dynamic>? ??
                            response.data['d'] as List<dynamic>? ?? [];
        List<DressModel> dresses = [];

        for (var item in dressesData) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);

            // Convertir thumbnail URL a imagen original
            String? thumbUrl5 = data['t']?.toString();
            String? origUrl5 = thumbUrl5?.replaceAll('/thumbnails/', '/');

            // Soportar formato compacto (i=id, n=name, c=category, etc) y completo
            final Map<String, dynamic> normalizedData = {
              'id': data['id'] ?? data['i'] ?? '',
              'name': data['name'] ?? data['n'] ?? '',
              'category': data['category'] ?? data['c'] ?? '',
              'subcategory': data['subcategory'] ?? '',
              'branch_id': data['branch_id'] ?? data['b'] ?? '',  // Sucursal
              'available': data['available'] ?? (data['a'] == 1 ? true : data['a'] == 0 ? false : true),
              'state': data['state'] ?? data['s'] ?? 'available',
              'images': data['images'] ?? (origUrl5 != null ? [origUrl5] : []),
              'price': data['price'] ?? data['p'] ?? 0,
              'rental_price': data['rental_price'] ?? data['p'] ?? 0,
            };

            final id = normalizedData['id']?.toString() ?? '';
            dresses.add(DressModel.fromMap(normalizedData, id));
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
