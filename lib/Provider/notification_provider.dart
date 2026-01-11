// notification_provider.dart - Migrado a PostgreSQL API
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/sale_confirmation_model.dart';
import '../services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// 🧠 Stream de confirmaciones confirmadas pero aún no notificadas - Usa PostgreSQL API
final unnotifiedConfirmationsProvider = StreamProvider<List<SaleConfirmationModel>>((ref) {
  final controller = StreamController<List<SaleConfirmationModel>>();

  Future<void> fetchUnnotifiedConfirmations() async {
    try {
      final response = await _apiService.get('sale-confirmations', queryParams: {
        'confirmed': 'true',
        'notified': 'false',
        'limit': '100',
      });

      if (!response.success || response.data == null) {
        if (!controller.isClosed) {
          controller.add([]);
        }
        return;
      }

      final confirmationsData = response.data['sale_confirmations'] as List<dynamic>? ?? [];
      final notifications = <SaleConfirmationModel>[];

      for (var item in confirmationsData) {
        try {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            // Filtrar: confirmadas pero no notificadas
            if (data['confirmed'] == true &&
                (data['notified'] == null || data['notified'] == false)) {
              notifications.add(SaleConfirmationModel.fromJson(data));
            }
          }
        } catch (e) {
          // Error silencioso para elementos inválidos
        }
      }

      if (!controller.isClosed) {
        controller.add(notifications);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
  }

  // Fetch inicial
  fetchUnnotifiedConfirmations();

  // Refresh periódico cada 15 segundos para notificaciones más responsivas
  final timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchUnnotifiedConfirmations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Marcar una confirmación como notificada - Usa PostgreSQL API
Future<bool> markAsNotified(String token) async {
  try {
    final response = await _apiService.put('sale-confirmations/$token', {
      'notified': true,
    });
    return response.success;
  } catch (e) {
    return false;
  }
}

/// Provider para marcar confirmación como notificada
final markNotifiedProvider = FutureProvider.family<bool, String>((ref, token) async {
  return markAsNotified(token);
});
