import '../services/api_service.dart';

/// Modelo para datos de RNC de la DGII
class RncData {
  final String rnc;
  final String nombre;
  final String? nombreComercial;
  final String? actividad;
  final String estado;
  final String? regimen;

  RncData({
    required this.rnc,
    required this.nombre,
    this.nombreComercial,
    this.actividad,
    this.estado = 'ACTIVO',
    this.regimen,
  });

  factory RncData.fromJson(Map<String, dynamic> json) {
    return RncData(
      rnc: json['rnc']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      nombreComercial: json['nombreComercial']?.toString(),
      actividad: json['actividad']?.toString(),
      estado: json['estado']?.toString() ?? 'ACTIVO',
      regimen: json['regimen']?.toString(),
    );
  }

  /// Retorna el nombre a mostrar (comercial si existe, sino razón social)
  String get displayName => nombreComercial?.isNotEmpty == true ? nombreComercial! : nombre;

  /// Verifica si está activo
  bool get isActive => estado == 'ACTIVO';
}

/// Repositorio para búsqueda de RNC en el padrón de la DGII
class RncLookupRepository {
  final ApiService _apiService = ApiService();

  /// Buscar RNC exacto
  /// Retorna los datos del contribuyente si existe
  Future<RncData?> lookupRnc(String rnc) async {
    try {
      // Limpiar RNC
      final cleanRnc = rnc.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanRnc.length < 9) {
        return null;
      }

      final response = await _apiService.get('rnc/lookup/$cleanRnc');

      if (response.success && response.data != null && response.data['data'] != null) {
        return RncData.fromJson(response.data['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error buscando RNC: $e');
      return null;
    }
  }

  /// Buscar por nombre o RNC parcial (para autocompletado)
  Future<List<RncData>> searchRnc(String query, {int limit = 10}) async {
    try {
      if (query.length < 3) {
        return [];
      }

      final response = await _apiService.get('rnc/search', queryParams: {
        'q': query,
        'limit': limit.toString(),
      });

      if (response.success && response.data != null) {
        final results = response.data['results'] as List<dynamic>? ?? [];
        return results.map((r) => RncData.fromJson(r as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      print('Error buscando RNC: $e');
      return [];
    }
  }

  /// Obtener estadísticas del padrón
  Future<Map<String, int>> getStats() async {
    try {
      final response = await _apiService.get('rnc/stats');

      if (response.success && response.data != null) {
        final stats = response.data['stats'] as Map<String, dynamic>?;
        if (stats != null) {
          return {
            'total': int.tryParse(stats['total']?.toString() ?? '0') ?? 0,
            'activos': int.tryParse(stats['activos']?.toString() ?? '0') ?? 0,
            'suspendidos': int.tryParse(stats['suspendidos']?.toString() ?? '0') ?? 0,
          };
        }
      }

      return {'total': 0, 'activos': 0, 'suspendidos': 0};
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {'total': 0, 'activos': 0, 'suspendidos': 0};
    }
  }
}

/// Instancia global del repositorio
final rncLookupRepository = RncLookupRepository();
