import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/transfer_verification_model.dart';
import '../services/api_service.dart';

/// Repositorio para transferencias bancarias
class TransferVerificationRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todas las transferencias
  Future<List<TransferVerificationModel>> getTransfers({String? status}) async {
    try {
      final queryParams = <String, String>{'limit': '500'};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get('transfer-verifications', queryParams: queryParams);

      if (response.success && response.data != null) {
        final transfers = response.data['transfers'] as List<dynamic>? ?? [];
        return transfers.map((t) => TransferVerificationModel.fromJson(t as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo transferencias: $e');
      return [];
    }
  }

  /// Obtener conteo de pendientes
  Future<int> getPendingCount() async {
    try {
      final response = await _apiService.get('transfer-verifications/pending-count');
      if (response.success && response.data != null) {
        return response.data['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error obteniendo conteo pendientes: $e');
      return 0;
    }
  }

  /// Obtener una transferencia por ID
  Future<TransferVerificationModel?> getTransferById(String id) async {
    try {
      final response = await _apiService.get('transfer-verifications/$id');
      if (response.success && response.data != null) {
        return TransferVerificationModel.fromJson(response.data['transfer'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error obteniendo transferencia: $e');
      return null;
    }
  }

  /// Crear nueva transferencia
  Future<TransferVerificationModel?> createTransfer(TransferVerificationModel transfer) async {
    try {
      print('DEBUG TransferRepo: Enviando datos al API...');
      print('DEBUG TransferRepo: JSON a enviar: ${transfer.toJson()}');

      final response = await _apiService.post('transfer-verifications', transfer.toJson());

      print('DEBUG TransferRepo: Response success: ${response.success}');
      print('DEBUG TransferRepo: Response data: ${response.data}');
      print('DEBUG TransferRepo: Response message: ${response.message}');

      if (response.success && response.data != null) {
        final transferData = response.data['transfer'] ?? response.data;
        print('DEBUG TransferRepo: Transfer data received: $transferData');
        return TransferVerificationModel.fromJson(transferData as Map<String, dynamic>);
      }
      print('DEBUG TransferRepo: Response not successful or data is null');
      return null;
    } catch (e, stackTrace) {
      print('Error creando transferencia: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Aprobar transferencia
  Future<bool> approveTransfer(String id, {String? operatorNotes, String? verifiedBy}) async {
    try {
      final response = await _apiService.put('transfer-verifications/$id/approve', {
        'operatorNotes': operatorNotes,
        'verifiedBy': verifiedBy,
      });
      return response.success;
    } catch (e) {
      print('Error aprobando transferencia: $e');
      return false;
    }
  }

  /// Rechazar transferencia
  Future<bool> rejectTransfer(String id, {required String rejectionReason, String? operatorNotes, String? verifiedBy}) async {
    try {
      final response = await _apiService.put('transfer-verifications/$id/reject', {
        'rejectionReason': rejectionReason,
        'operatorNotes': operatorNotes,
        'verifiedBy': verifiedBy,
      });
      return response.success;
    } catch (e) {
      print('Error rechazando transferencia: $e');
      return false;
    }
  }

  /// Eliminar transferencia
  Future<bool> deleteTransfer(String id) async {
    try {
      final response = await _apiService.delete('transfer-verifications/$id');
      return response.success;
    } catch (e) {
      print('Error eliminando transferencia: $e');
      return false;
    }
  }
}

/// Instancia global del repositorio
final transferVerificationRepository = TransferVerificationRepository();

/// Provider para la lista de transferencias
final transferVerificationsProvider = FutureProvider.autoDispose<List<TransferVerificationModel>>((ref) async {
  return transferVerificationRepository.getTransfers();
});

/// Provider para transferencias pendientes
final pendingTransfersProvider = FutureProvider.autoDispose<List<TransferVerificationModel>>((ref) async {
  return transferVerificationRepository.getTransfers(status: 'pending');
});

/// Provider para transferencias aprobadas
final approvedTransfersProvider = FutureProvider.autoDispose<List<TransferVerificationModel>>((ref) async {
  return transferVerificationRepository.getTransfers(status: 'approved');
});

/// Provider para transferencias rechazadas
final rejectedTransfersProvider = FutureProvider.autoDispose<List<TransferVerificationModel>>((ref) async {
  return transferVerificationRepository.getTransfers(status: 'rejected');
});

/// Provider para conteo de pendientes (con refresh automático)
final pendingTransferCountProvider = StreamProvider.autoDispose<int>((ref) {
  final controller = StreamController<int>();

  Future<void> fetchCount() async {
    try {
      final count = await transferVerificationRepository.getPendingCount();
      if (!controller.isClosed) {
        controller.add(count);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add(0);
      }
    }
  }

  // Fetch inicial
  fetchCount();

  // Refresh cada 30 segundos
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchCount());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider para filtro de estado actual
final transferStatusFilterProvider = StateProvider<String>((ref) => 'pending');

/// Provider para transferencias filtradas
final filteredTransfersProvider = FutureProvider.autoDispose<List<TransferVerificationModel>>((ref) async {
  final status = ref.watch(transferStatusFilterProvider);
  if (status == 'all') {
    return transferVerificationRepository.getTransfers();
  }
  return transferVerificationRepository.getTransfers(status: status);
});
