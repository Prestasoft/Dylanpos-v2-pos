import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import 'client_tracking_model.dart';

/// Repositorio de seguimiento de clientes — lee reservaciones + tasks agregadas.
class ClientTrackingRepository {
  final _api = ApiService();

  /// Obtener clientes con su pipeline de etapas por rango de fechas.
  Future<List<ClientTrackingModel>> getClients({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final resp = await _api.get('hrm/client-tracking', queryParams: {
        'date_from': dateFrom,
        'date_to': dateTo,
      });

      if (resp.success && resp.data != null) {
        // resp.data puede ser { success, data: { clients } } o { clients } directamente
        final rawData = resp.data is Map ? resp.data as Map<String, dynamic> : <String, dynamic>{};
        final clientsData = rawData['clients'] ?? rawData['data']?['clients'];
        final list = clientsData as List<dynamic>? ?? [];
        debugPrint('[ClientTracking] Clientes recibidos: ${list.length}');
        return list
            .map((e) => ClientTrackingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error en ClientTrackingRepository.getClients: $e');
    }
    return [];
  }
}
