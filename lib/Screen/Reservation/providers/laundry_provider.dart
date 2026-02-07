import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:salespro_admin/services/api_service.dart';
import '../models/dress_laundry_status.dart';

/// Repository para gestionar estados de lavandería
class LaundryRepository {
  final ApiService _apiService = ApiService();

  /// Obtener estado de lavandería de un vestido
  Future<DressLaundryStatus?> getLaundryStatus(String dressId) async {
    try {
      final response = await _apiService.get('laundry/status/$dressId');

      if (response.success && response.data != null) {
        final statusData = response.data['status'] as Map<String, dynamic>;
        return DressLaundryStatus.fromMap(statusData);
      }

      return null;
    } catch (e) {
      debugPrint('Error obteniendo estado de lavandería: $e');
      return null;
    }
  }

  /// Obtener estados de múltiples vestidos
  Future<Map<String, DressLaundryStatus>> getBatchLaundryStatus(
      List<String> dressIds) async {
    try {
      final response = await _apiService.post(
        'laundry/batch-status',
        {'dress_ids': dressIds},
      );

      if (response.success && response.data != null) {
        final statusesData = response.data['statuses'] as List<dynamic>;
        final Map<String, DressLaundryStatus> statusMap = {};

        for (var statusData in statusesData) {
          final status = DressLaundryStatus.fromMap(
              Map<String, dynamic>.from(statusData));
          statusMap[status.dressId] = status;
        }

        return statusMap;
      }

      return {};
    } catch (e) {
      debugPrint('Error obteniendo estados batch: $e');
      return {};
    }
  }

  /// Marcar vestido como en lavandería
  Future<bool> markInLaundry(String dressId,
      {int estimatedDays = 3, String? notes}) async {
    try {
      final response = await _apiService.post(
        'laundry/mark-in-laundry',
        {
          'dress_id': dressId,
          'estimated_days': estimatedDays,
          'notes': notes ?? '',
        },
      );

      return response.success;
    } catch (e) {
      debugPrint('Error marcando en lavandería: $e');
      return false;
    }
  }

  /// Marcar vestido como listo
  Future<bool> markReady(String dressId) async {
    try {
      final response = await _apiService.post(
        'laundry/mark-ready',
        {'dress_id': dressId},
      );

      return response.success;
    } catch (e) {
      debugPrint('Error marcando listo: $e');
      return false;
    }
  }
}

/// Repository provider
final laundryRepositoryProvider = Provider<LaundryRepository>((ref) {
  return LaundryRepository();
});

/// Provider de estado de lavandería de un vestido específico
/// IMPORTANTE: autoDispose garantiza que se recargue al cambiar de sucursal
final dressLaundryStatusProvider =
    FutureProvider.family.autoDispose<DressLaundryStatus?, String>(
  (ref, dressId) async {
    final repo = ref.read(laundryRepositoryProvider);
    return await repo.getLaundryStatus(dressId);
  },
);

/// Provider de estados batch (múltiples vestidos)
/// IMPORTANTE: autoDispose garantiza que se recargue al cambiar de sucursal
final batchLaundryStatusProvider = FutureProvider.family.autoDispose<
    Map<String, DressLaundryStatus>, List<String>>(
  (ref, dressIds) async {
    final repo = ref.read(laundryRepositoryProvider);
    return await repo.getBatchLaundryStatus(dressIds);
  },
);
