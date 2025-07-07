// Path: lib/utils/firebase_interceptor.dart

import 'package:firebase_database/firebase_database.dart';
import 'firebase_key_util.dart';

class FirebaseInterceptor {
  static final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();
  
  static void init() {
    // Este método podría usarse para inicializar interceptores globales si es necesario
    print('Firebase Interceptor inicializado');
  }
  
  // Función segura para obtener una referencia de Firebase con clave sanitizada
  static DatabaseReference getReference(String path) {
    // Dividir la ruta en segmentos
    final segments = path.split('/');
    
    // Sanitizar cada segmento individualmente
    final sanitizedSegments = segments.map((segment) {
      // No sanitizar segmentos vacíos (que aparecen cuando hay doble slash)
      if (segment.isEmpty) return segment;
      return FirebaseKeyUtil.sanitizeKey(segment);
    }).toList();
    
    // Reconstruir la ruta sanitizada
    final sanitizedPath = sanitizedSegments.join('/');
    
    return _rootRef.child(sanitizedPath);
  }
  
  // Función para guardar datos con clave generada
  static Future<String> push(String path, Map<String, dynamic> data) async {
    final ref = getReference(path);
    final newRef = ref.push();
    await newRef.set(data);
    return newRef.key ?? '';
  }
  
  // Función para guardar datos en una ruta específica
  static Future<void> set(String path, Map<String, dynamic> data) async {
    final ref = getReference(path);
    await ref.set(data);
  }
  
  // Función para actualizar datos
  static Future<void> update(String path, Map<String, dynamic> data) async {
    final ref = getReference(path);
    await ref.update(data);
  }
}
