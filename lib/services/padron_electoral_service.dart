import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../Screen/HRM/employees/model/padron_electoral_response.dart';

/// Servicio para consultar el Padrón Electoral Dominicano
/// Utiliza el proxy backend para evitar problemas de CORS
class PadronElectoralService {
  // Singleton
  static final PadronElectoralService _instance = PadronElectoralService._internal();
  factory PadronElectoralService() => _instance;
  PadronElectoralService._internal();

  final ApiService _apiService = ApiService();

  /// Consulta los datos de un ciudadano por su cédula
  ///
  /// [cedula] puede contener guiones (ej: 402-0040196-8) o no (40200401968)
  /// El servicio limpia automáticamente los guiones antes de consultar
  ///
  /// Retorna [PadronElectoralResponse] con los datos del ciudadano o error
  Future<PadronElectoralResponse> consultarCedula(String cedula) async {
    try {
      // Limpiar cédula (remover guiones y espacios)
      final cleanCedula = cedula.replaceAll(RegExp(r'[^0-9]'), '');

      // Validar longitud
      if (cleanCedula.length != 11) {
        return PadronElectoralResponse(
          success: false,
          message: 'Cédula inválida. Debe tener 11 dígitos.',
        );
      }

      print('[PadronElectoralService] Consultando cédula: $cleanCedula');

      // Llamar al proxy backend
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/padron-electoral/$cleanCedula'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 25));

      print('[PadronElectoralService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PadronElectoralResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        return PadronElectoralResponse(
          success: false,
          message: 'Cédula no encontrada en el Padrón Electoral.',
        );
      } else {
        final body = json.decode(response.body);
        return PadronElectoralResponse(
          success: false,
          message: body['message'] ?? 'Error consultando Padrón Electoral.',
        );
      }
    } catch (e) {
      print('[PadronElectoralService] Error: $e');

      if (e.toString().contains('TimeoutException')) {
        return PadronElectoralResponse(
          success: false,
          message: 'Timeout consultando Padrón Electoral. Intente nuevamente.',
        );
      }

      return PadronElectoralResponse(
        success: false,
        message: 'Error de conexión al consultar Padrón Electoral.',
      );
    }
  }

  /// Valida si una cédula tiene el formato correcto (sin consultar API)
  static bool validarFormatoCedula(String cedula) {
    final cleanCedula = cedula.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCedula.length != 11) return false;
    if (!RegExp(r'^\d{11}$').hasMatch(cleanCedula)) return false;

    // Algoritmo de validación de cédula dominicana (Luhn modificado)
    final weights = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    int sum = 0;
    for (int i = 0; i < 10; i++) {
      int digit = int.parse(cleanCedula[i]) * weights[i];
      if (digit > 9) digit -= 9;
      sum += digit;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(cleanCedula[10]);
  }

  /// Formatea una cédula con guiones (###-#######-#)
  static String formatearCedula(String cedula) {
    final clean = cedula.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 11) return cedula;
    return '${clean.substring(0, 3)}-${clean.substring(3, 10)}-${clean.substring(10)}';
  }

  /// Resultado de actualización de foto de un empleado
  static const String resultSuccess = 'success';
  static const String resultNotFound = 'not_found';
  static const String resultNoPhoto = 'no_photo';
  static const String resultError = 'error';
  static const String resultNoCedula = 'no_cedula';
  static const String resultAlreadyHasPhoto = 'already_has_photo';

  /// Actualiza la foto de un empleado desde el Padrón Electoral
  ///
  /// [cedula] - Cédula del empleado
  /// [employeeId] - ID del empleado en la base de datos
  /// [currentPhotoUrl] - URL de foto actual (para verificar si ya tiene foto)
  /// [forceUpdate] - Si es true, actualiza aunque ya tenga foto
  ///
  /// Retorna un Map con:
  /// - 'result': String indicando el resultado
  /// - 'photoUrl': String con la URL de la foto (si tuvo éxito)
  /// - 'message': String con mensaje descriptivo
  Future<Map<String, dynamic>> actualizarFotoDesdePardon({
    required String cedula,
    required dynamic employeeId,
    String? currentPhotoUrl,
    bool forceUpdate = false,
  }) async {
    // Verificar si ya tiene foto y no se fuerza actualización
    if (!forceUpdate && currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) {
      return {
        'result': resultAlreadyHasPhoto,
        'message': 'El empleado ya tiene foto asignada',
      };
    }

    // Verificar que tenga cédula
    if (cedula.isEmpty) {
      return {
        'result': resultNoCedula,
        'message': 'El empleado no tiene cédula registrada',
      };
    }

    // Validar formato de cédula
    if (!validarFormatoCedula(cedula)) {
      return {
        'result': resultError,
        'message': 'Cédula inválida: $cedula',
      };
    }

    try {
      // Consultar Padrón Electoral
      final response = await consultarCedula(cedula);

      if (!response.success || response.data == null) {
        return {
          'result': resultNotFound,
          'message': response.message ?? 'No encontrado en Padrón Electoral',
        };
      }

      // Verificar si tiene foto
      if (!response.data!.tieneFoto) {
        return {
          'result': resultNoPhoto,
          'message': 'No hay foto disponible en el Padrón Electoral',
        };
      }

      // Obtener foto en formato data URL
      final photoUrl = response.data!.fotoDataUrl;

      // Actualizar en la base de datos
      final updateResponse = await _apiService.put(
        'hrm/employees/$employeeId',
        {'image_url': photoUrl},
      );

      if (updateResponse.success) {
        return {
          'result': resultSuccess,
          'photoUrl': photoUrl,
          'message': 'Foto actualizada correctamente',
        };
      } else {
        return {
          'result': resultError,
          'message': updateResponse.message ?? 'Error al actualizar en base de datos',
        };
      }
    } catch (e) {
      return {
        'result': resultError,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
