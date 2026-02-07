import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Buscar RNC exacto
  /// Retorna los datos del contribuyente si existe
  /// Usa http directo para evitar problemas de autenticación
  Future<RncData?> lookupRnc(String rnc) async {
    try {
      // Limpiar RNC
      final cleanRnc = rnc.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanRnc.length < 9) {
        return null;
      }

      // Usar http directo para el endpoint RNC (no requiere auth)
      final uri = Uri.parse('${ApiService.baseUrl}/rnc/lookup/$cleanRnc');
      print('[RncLookupRepository] Consultando RNC: $uri');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      print('[RncLookupRepository] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return RncData.fromJson(data['data'] as Map<String, dynamic>);
        }
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

      // Usar http directo para el endpoint RNC (no requiere auth)
      final uri = Uri.parse('${ApiService.baseUrl}/rnc/search').replace(
        queryParameters: {'q': query, 'limit': limit.toString()},
      );

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['results'] != null) {
          final results = data['results'] as List<dynamic>;
          return results.map((r) => RncData.fromJson(r as Map<String, dynamic>)).toList();
        }
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
      // Usar http directo para el endpoint RNC (no requiere auth)
      final uri = Uri.parse('${ApiService.baseUrl}/rnc/stats');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['stats'] != null) {
          final stats = data['stats'] as Map<String, dynamic>;
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
