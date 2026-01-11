import '../model/ncf_model.dart';
import '../services/api_service.dart';

/// Repositorio para operaciones de DGII (Comprobantes Fiscales)
class DgiiRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los tipos de NCF activos
  Future<List<NcfTypeModel>> getNcfTypes() async {
    try {
      final response = await _apiService.get('dgii/ncf-types');
      if (response.success && response.data != null) {
        final types = response.data['ncfTypes'] as List<dynamic>? ?? [];
        return types.map((t) => NcfTypeModel.fromJson(t as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo tipos NCF: $e');
      return [];
    }
  }

  /// Obtener secuencias NCF de la sucursal
  Future<List<NcfSequenceModel>> getNcfSequences() async {
    try {
      final response = await _apiService.get('dgii/ncf-sequences');
      if (response.success && response.data != null) {
        final sequences = response.data['sequences'] as List<dynamic>? ?? [];
        return sequences.map((s) => NcfSequenceModel.fromJson(s as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo secuencias NCF: $e');
      return [];
    }
  }

  /// Generar nuevo número de NCF (solo devuelve el número)
  Future<String?> generateNcf(String ncfType) async {
    final result = await generateNcfWithExpiration(ncfType);
    return result?['ncfNumber'];
  }

  /// Generar nuevo número de NCF con fecha de vencimiento
  /// Devuelve un Map con 'ncfNumber' y 'expirationDate'
  Future<Map<String, String?>?> generateNcfWithExpiration(String ncfType) async {
    try {
      if (ncfType == 'SIN') return null;

      final response = await _apiService.post('dgii/generate-ncf', {
        'ncfType': ncfType,
      });

      if (response.success && response.data != null) {
        return {
          'ncfNumber': response.data['ncfNumber'] as String?,
          'expirationDate': response.data['expirationDate'] as String?,
        };
      }
      return null;
    } catch (e) {
      print('Error generando NCF: $e');
      return null;
    }
  }

  /// Obtener ventas filtradas por tipo NCF
  Future<Map<String, dynamic>> getSalesByNcf({
    String? ncfType,
    String? startDate,
    String? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (ncfType != null) queryParams['ncfType'] = ncfType;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiService.get('dgii/sales-by-ncf', queryParams: queryParams);

      if (response.success && response.data != null) {
        return {
          'sales': response.data['sales'] as List<dynamic>? ?? [],
          'total': response.data['total'] as int? ?? 0,
          'limit': response.data['limit'] as int? ?? limit,
          'offset': response.data['offset'] as int? ?? offset,
        };
      }
      return {'sales': [], 'total': 0, 'limit': limit, 'offset': offset};
    } catch (e) {
      print('Error obteniendo ventas por NCF: $e');
      return {'sales': [], 'total': 0, 'limit': limit, 'offset': offset};
    }
  }

  /// Obtener resumen de ventas por tipo NCF
  Future<List<NcfSalesSummaryModel>> getSummaryByNcf({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiService.get('dgii/summary-by-ncf', queryParams: queryParams);

      if (response.success && response.data != null) {
        final summary = response.data['summary'] as List<dynamic>? ?? [];
        return summary.map((s) => NcfSalesSummaryModel.fromJson(s as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo resumen NCF: $e');
      return [];
    }
  }

  /// Generar reporte 607 (ventas)
  Future<Map<String, dynamic>> getReport607(int year, int month) async {
    try {
      final response = await _apiService.get('dgii/report-607', queryParams: {
        'year': year.toString(),
        'month': month.toString(),
      });

      if (response.success && response.data != null) {
        return {
          'success': true,
          'period': response.data['period'],
          'totalRecords': response.data['totalRecords'] as int? ?? 0,
          'report': (response.data['report'] as List<dynamic>? ?? [])
              .map((r) => Report607RecordModel.fromJson(r as Map<String, dynamic>))
              .toList(),
        };
      }
      return {'success': false, 'report': []};
    } catch (e) {
      print('Error generando reporte 607: $e');
      return {'success': false, 'error': e.toString(), 'report': []};
    }
  }

  /// Actualizar configuración de secuencia NCF
  Future<bool> updateNcfSequence(String id, {
    String? serie,
    int? currentSequence,
    int? maxSequence,
    String? prefix,
    String? authorizationDate,
    String? expirationDate,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (serie != null) body['serie'] = serie;
      if (currentSequence != null) body['currentSequence'] = currentSequence;
      if (maxSequence != null) body['maxSequence'] = maxSequence;
      if (prefix != null) body['prefix'] = prefix;
      if (authorizationDate != null) body['authorizationDate'] = authorizationDate;
      if (expirationDate != null) body['expirationDate'] = expirationDate;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiService.put('dgii/ncf-sequences/$id', body);
      return response.success;
    } catch (e) {
      print('Error actualizando secuencia NCF: $e');
      return false;
    }
  }

  /// Crear nueva secuencia NCF
  Future<NcfSequenceModel?> createNcfSequence({
    required String ncfTypeCode,
    required String serie,
    required int maxSequence,
    String? prefix,
    String? authorizationDate,
    String? expirationDate,
  }) async {
    try {
      final response = await _apiService.post('dgii/ncf-sequences', {
        'ncfTypeCode': ncfTypeCode,
        'serie': serie,
        'maxSequence': maxSequence,
        'prefix': prefix,
        'authorizationDate': authorizationDate,
        'expirationDate': expirationDate,
      });

      if (response.success && response.data != null) {
        return NcfSequenceModel.fromJson(response.data['sequence'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error creando secuencia NCF: $e');
      return null;
    }
  }
}

/// Instancia global del repositorio DGII
final dgiiRepository = DgiiRepository();
