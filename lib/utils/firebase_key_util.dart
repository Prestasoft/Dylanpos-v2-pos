// Utilidad para generar claves seguras para Firebase
import 'package:uuid/uuid.dart';

class FirebaseKeyUtil {
  /// Genera una clave segura para Firebase que no contiene caracteres especiales
  /// como '.', '#', '$', '[', ']'
  static String generateSafeKey() {
    // Crear un UUID aleatorio
    final uuid = Uuid().v4();
    
    // Eliminar cualquier guión que pueda contener el UUID
    return uuid.replaceAll('-', '_');
  }

  /// Sanitiza un string para que sea seguro como clave de Firebase
  /// Reemplaza caracteres no permitidos con '_'
  static String sanitizeKey(String key) {
    return key
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_')
        .replaceAll(' ', '_');
  }

  /// Convierte una fecha a un formato seguro para usarse como clave en Firebase
  static String dateToSafeKey(DateTime date) {
    // Formato: YYYY_MM_DD_HH_MM_SS_MS
    return '${date.year}_${_padTwoDigits(date.month)}_${_padTwoDigits(date.day)}_' +
           '${_padTwoDigits(date.hour)}_${_padTwoDigits(date.minute)}_${_padTwoDigits(date.second)}_${date.millisecond}';
  }

  /// Función auxiliar para asegurar que los números tengan dos dígitos
  static String _padTwoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }
}
