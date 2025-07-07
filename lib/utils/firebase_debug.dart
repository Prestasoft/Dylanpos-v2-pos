// Path: lib/utils/firebase_debug.dart
// Un archivo para hacer debug de Firebase y encontrar errores en las claves

import 'package:firebase_database/firebase_database.dart';

class FirebaseDebugInterceptor {
  static void init() {
    // Instalar el interceptor
    FirebaseDatabase.instance.ref().onChildAdded.listen((event) {
      final path = event.snapshot.ref.path;
      print('DEBUG Firebase Path: $path');
      
      // Verificar si la ruta contiene caracteres no permitidos
      if (path.contains('.') || path.contains('#') || path.contains('\$') || 
          path.contains('[') || path.contains(']')) {
        print('⚠️ ALERTA: Ruta de Firebase inválida detectada: $path');
      }
    });
  }
}
