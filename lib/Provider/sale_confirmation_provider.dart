// sale_confirmation_provider.dart - Migrado a PostgreSQL API
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/sale_confirmation_model.dart';
import '../services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Provider de confirmaciones de venta - Usa PostgreSQL API
final saleConfirmationsProvider = AsyncNotifierProvider<SaleConfirmationsNotifier, List<SaleConfirmationModel>>(
  SaleConfirmationsNotifier.new,
);

class SaleConfirmationsNotifier extends AsyncNotifier<List<SaleConfirmationModel>> {
  bool _forceRefresh = false;

  @override
  Future<List<SaleConfirmationModel>> build() async {
    if (_forceRefresh) {
      _forceRefresh = false;
      state = await AsyncValue.guard(_fetchConfirmations);
    }
    return _fetchConfirmations();
  }

  /// Obtener todas las confirmaciones desde PostgreSQL
  Future<List<SaleConfirmationModel>> _fetchConfirmations() async {
    try {
      final response = await _apiService.get('sale-confirmations', queryParams: {'limit': '5000'});

      if (!response.success || response.data == null) {
        return [];
      }

      final List<SaleConfirmationModel> confirmations = [];
      final confirmationsData = response.data['sale_confirmations'] as List<dynamic>? ?? [];

      for (var item in confirmationsData) {
        try {
          if (item is Map) {
            final confirmationData = Map<String, dynamic>.from(item);
            final confirmation = SaleConfirmationModel.fromJson(confirmationData);
            confirmations.add(confirmation);
          }
        } catch (e) {
          // Error silencioso para elementos inválidos
        }
      }

      return confirmations;
    } catch (e) {
      rethrow;
    }
  }

  /// Refrescar lista de confirmaciones
  Future<void> refreshConfirmations() async {
    _forceRefresh = true;
    ref.invalidateSelf();
  }

  /// Actualizar una confirmación - Usa PostgreSQL API
  Future<void> updateConfirmation(SaleConfirmationModel confirmation) async {
    try {
      final response = await _apiService.put(
        'sale-confirmations/${confirmation.token}',
        confirmation.toJson(),
      );

      if (response.success) {
        await refreshConfirmations();
      } else {
        throw Exception(response.message ?? 'Error al actualizar confirmación');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una confirmación - Usa PostgreSQL API
  Future<void> deleteConfirmation(String token) async {
    try {
      final response = await _apiService.delete('sale-confirmations/$token');

      if (response.success) {
        await refreshConfirmations();
      } else {
        throw Exception(response.message ?? 'Error al eliminar confirmación');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva confirmación - Usa PostgreSQL API
  Future<void> createConfirmation(SaleConfirmationModel confirmation) async {
    try {
      final response = await _apiService.post(
        'sale-confirmations',
        confirmation.toJson(),
      );

      if (response.success) {
        await refreshConfirmations();
      } else {
        throw Exception(response.message ?? 'Error al crear confirmación');
      }
    } catch (e) {
      rethrow;
    }
  }
}
