import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../model/dress_model.dart';

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
    print('Error uploading image: $e');
    rethrow;
  }
}

// Upload multiple images and return URLs
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

// Add a new dress with image URLs
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

    // Upload new images if any
    List<String> newImageUrls = await uploadMultipleImages(imageFiles);

    // Combine with existing image URLs if editing
    List<String> allImageUrls = [...dress.images, ...newImageUrls];

    // Generate a new key if id is empty
    String dressId = dress.id.isEmpty
        ? FirebaseDatabase.instance.ref('Admin Panel/dresses').push().key ?? ''
        : dress.id;

    // Save dress to Realtime Database with image URLs
    await FirebaseDatabase.instance.ref('Admin Panel/dresses/$dressId').set({
      'name': dress.name,
      'category': dress.category,
      'subcategory': dress.subcategory,
      'branch_id': dress.branchId,
      'available': dress.available,
      'created_at': dress.createdAt.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'images': allImageUrls,
      'price': dress.price, // Save price if available
    });

    return true;
  } catch (e) {
    print('Error saving dress with images: $e');
    return false;
  }
});

// Update an existing dress
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

    // Upload new images if any
    List<String> newImageUrls = [];
    if (newImageFiles.isNotEmpty) {
      newImageUrls = await uploadMultipleImages(newImageFiles);
    }

    // Combine all images
    List<String> allImageUrls = [...dress.images, ...newImageUrls];

    // Update the dress in Realtime Database
    await FirebaseDatabase.instance
        .ref('Admin Panel/dresses/${dress.id}')
        .update({
      'name': dress.name,
      'category': dress.category,
      'subcategory': dress.subcategory,
      'branch_id': dress.branchId,
      'available': dress.available,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'images': allImageUrls,
      'price': dress.price, // Update price if available
    });

    return true;
  } catch (e) {
    print('Error updating dress: $e');
    return false;
  }
});
// Delete a dress
final deleteDressProvider =
    FutureProvider.family<bool, String>((ref, dressId) async {
  try {
    // Get the dress first to potentially handle images
    final dataSnapshot = await FirebaseDatabase.instance
        .ref('Admin Panel/dresses/$dressId')
        .get();

    if (dataSnapshot.exists) {
      Map<dynamic, dynamic>? data =
          dataSnapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        // Convert to our model

        // Delete the node from Realtime Database
        await FirebaseDatabase.instance
            .ref('Admin Panel/dresses/$dressId')
            .remove();

        return true;
      }
    }
    return false;
  } catch (e) {
    print('Error deleting dress: $e');
    return false;
  }
});

// Toggle dress availability
final toggleDressAvailabilityProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  try {
    String dressId = data['dressId'] as String;
    bool newAvailability = data['available'] as bool;

    await FirebaseDatabase.instance.ref('Admin Panel/dresses/$dressId').update({
      'available': newAvailability,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    return true;
  } catch (e) {
    print('Error toggling dress availability: $e');
    return false;
  }
});

// Get all dresses
final dressesProvider = StreamProvider<List<DressModel>>((ref) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/dresses')
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    // Aquí imprimes el JSON completo
    print('JSON de Firebase: ${snapshot.value}');

    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    List<DressModel> dresses = [];

    data.forEach((key, value) {
      if (value is Map &&
          value.containsKey('name') &&
          value.containsKey('category')) {
        // Solo agregar si tiene campos mínimos de un vestido
        dresses.add(DressModel.fromRealtimeDB(value, key));
      }
    });

    return dresses;
  });
});

// 1. Proveedor con timeout y manejo de errores
final availableDressesByComponentsProvider =
    StreamProvider.family<List<DressModel>, String>((ref, String category) {
  // Crear un completer para gestionar el timeout
  final future = FirebaseDatabase.instance
      .ref('Admin Panel/dresses')
      // 2. Optimizar consulta: limitamos el tamaño de descarga
      .limitToFirst(100) // Ajusta este número según tus necesidades
      .onValue
      .timeout(
    Duration(seconds: 15), // Timeout de 15 segundos
    onTimeout: (sink) {
      print('Firebase query timeout: Category $category');
      sink.addError(
          'Tiempo de espera agotado. Verifica tu conexión a internet.');
      sink.close();
    },
  ).map((event) {
    final snapshot = event.snapshot;

    // 3. Manejo adecuado de valores nulos
    if (snapshot.value == null) {
      print('No dresses found for category: $category');
      return <DressModel>[];
    }

    try {
      // 4. Manejo seguro de tipos
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      List<DressModel> dresses = [];

      // 5. Validación de cada elemento antes de procesarlo
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          try {
            // Solo filtramos por categoría si existe
            final dressCategory = value['category'];
            if (dressCategory != null && dressCategory == category) {
              dresses.add(DressModel.fromRealtimeDB(value, key));
            }
          } catch (e) {
            print('Error parsing dress with key $key: $e');
            // Continuamos con el siguiente vestido en caso de error
          }
        }
      });

      // 6. Ordenamiento más eficiente
      dresses.sort(
          (a, b) => a.available == b.available ? 0 : (a.available ? -1 : 1));

      return dresses;
    } catch (e) {
      print('Error processing dresses: $e');
      throw 'Error al procesar los datos de vestidos. Intenta de nuevo.';
    }
  });

  return future;
});

// 7. Proveedor alternativo con método de una sola vez (sin listener permanente)
final dressesOnceProvider = FutureProvider.family<List<DressModel>, String>(
    (ref, String category) async {
  try {
    final snapshot = await FirebaseDatabase.instance
        .ref('Admin Panel/dresses')
        .get(); // Usa get() en lugar de onValue para una sola consulta

    if (snapshot.value == null) return [];

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    List<DressModel> dresses = [];

    data.forEach((key, value) {
      if (value is Map<dynamic, dynamic> && value['category'] == category) {
        dresses.add(DressModel.fromRealtimeDB(value, key));
      }
    });

    dresses.sort(
        (a, b) => a.available == b.available ? 0 : (a.available ? -1 : 1));

    return dresses;
  } catch (e) {
    print('Error fetching dresses: $e');
    throw 'Error al cargar los vestidos. Por favor, intenta de nuevo.';
  }
});

// Get a single dress
final singleDressProvider =
    FutureProvider.family<DressModel?, String>((ref, dressId) async {
  final snapshot =
      await FirebaseDatabase.instance.ref('Admin Panel/dresses/$dressId').get();

  if (snapshot.exists) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return DressModel.fromRealtimeDB(data, dressId);
  }
  return null;
});

// Get dresses by category
final dressesByCategoryProvider =
    StreamProvider.family<List<DressModel>, String>((ref, category) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/dresses')
      .orderByChild('category')
      .equalTo(category)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    List<DressModel> dresses = [];

    data.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        dresses.add(DressModel.fromRealtimeDB(value, key));
      }
    });

    return dresses;
  });
});

// Get dresses by branch
final dressesByBranchProvider =
    StreamProvider.family<List<DressModel>, String>((ref, branchId) {
  return FirebaseDatabase.instance
      .ref('Admin Panel/dresses')
      .orderByChild('branch_id')
      .equalTo(branchId)
      .onValue
      .map((event) {
    final snapshot = event.snapshot;
    if (snapshot.value == null) return [];

    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    List<DressModel> dresses = [];

    data.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        dresses.add(DressModel.fromRealtimeDB(value, key));
      }
    });

    return dresses;
  });
});
