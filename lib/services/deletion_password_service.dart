// deletion_password_service.dart - Migrado a PostgreSQL API
import 'api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Servicio para gestionar la contraseña de eliminación - Usa PostgreSQL API
class DeletionPasswordService {
  static const String _defaultPassword = "22400600452";

  /// Obtiene la contraseña de eliminación actual desde PostgreSQL API
  /// Si no existe, devuelve la contraseña por defecto
  static Future<String> getCurrentPassword() async {
    try {
      final response = await _apiService.get('settings/deletion-password');

      if (response.success && response.data != null) {
        final password = response.data['password']?.toString() ??
                        response.data['deletion_password']?.toString();
        if (password != null && password.isNotEmpty) {
          return password;
        }
      }

      // Si no existe, inicializar con la contraseña por defecto
      await _initializeDefaultPassword();
      return _defaultPassword;
    } catch (e) {
      print('Error al obtener contraseña de eliminación: $e');
      return _defaultPassword;
    }
  }

  /// Inicializa la contraseña por defecto en PostgreSQL
  static Future<void> _initializeDefaultPassword() async {
    try {
      await _apiService.post('settings/deletion-password', {
        'password': _defaultPassword,
      });
    } catch (e) {
      print('Error al inicializar contraseña por defecto: $e');
    }
  }

  /// Valida si la contraseña ingresada es correcta
  static Future<bool> validatePassword(String enteredPassword) async {
    final currentPassword = await getCurrentPassword();
    return enteredPassword == currentPassword;
  }

  /// Cambia la contraseña de eliminación
  /// Requiere la contraseña actual para validación
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Validar contraseña actual
      final isValid = await validatePassword(currentPassword);
      if (!isValid) {
        return false;
      }

      // Validar que la nueva contraseña no esté vacía
      if (newPassword.trim().isEmpty) {
        return false;
      }

      // Guardar nueva contraseña en PostgreSQL API
      final response = await _apiService.put('settings/deletion-password', {
        'password': newPassword.trim(),
      });

      return response.success;
    } catch (e) {
      print('Error al cambiar contraseña: $e');
      return false;
    }
  }

  /// Reinicia la contraseña al valor por defecto
  /// Solo para uso administrativo
  static Future<void> resetToDefault() async {
    try {
      await _apiService.put('settings/deletion-password', {
        'password': _defaultPassword,
      });
    } catch (e) {
      print('Error al reiniciar contraseña: $e');
    }
  }
}
