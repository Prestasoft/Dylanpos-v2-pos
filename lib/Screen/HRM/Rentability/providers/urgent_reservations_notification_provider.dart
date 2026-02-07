import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:salespro_admin/services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Modelo simple para reservas urgentes sin facturar
class UrgentReservationNotification {
  final String reservationId;
  final String customerName;
  final String sellerName;
  final int daysWithoutInvoice;
  final double estimatedAmount;
  final DateTime eventDate;

  UrgentReservationNotification({
    required this.reservationId,
    required this.customerName,
    required this.sellerName,
    required this.daysWithoutInvoice,
    required this.estimatedAmount,
    required this.eventDate,
  });

  factory UrgentReservationNotification.fromJson(Map<String, dynamic> json) {
    final reservation = json['reservation'] as Map<String, dynamic>;
    return UrgentReservationNotification(
      reservationId: reservation['reservation_id'] ?? '',
      customerName: reservation['customer_name'] ?? '',
      sellerName: json['employee_name'] ?? '',
      daysWithoutInvoice: (reservation['days_without_invoice'] as num?)?.toInt() ?? 0,
      estimatedAmount: (reservation['estimated_amount'] as num?)?.toDouble() ?? 0.0,
      eventDate: DateTime.parse(reservation['event_date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Stream de reservas urgentes (>10 días sin facturar)
/// Actualiza cada 30 minutos para no sobrecargar el servidor
final urgentReservationsProvider = StreamProvider<List<UrgentReservationNotification>>((ref) {
  final controller = StreamController<List<UrgentReservationNotification>>();

  Future<void> fetchUrgentReservations() async {
    try {
      final response = await _apiService.get('rentability/pending-invoices');

      if (!response.success || response.data == null) {
        if (!controller.isClosed) {
          controller.add([]);
        }
        return;
      }

      final pendingData = response.data['pending'] as List<dynamic>? ?? [];
      final urgentNotifications = <UrgentReservationNotification>[];

      for (var item in pendingData) {
        try {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            final reservation = data['reservation'] as Map<String, dynamic>;
            final daysWithoutInvoice = (reservation['days_without_invoice'] as num?)?.toInt() ?? 0;

            // Solo incluir reservas urgentes (>10 días)
            if (daysWithoutInvoice > 10) {
              urgentNotifications.add(UrgentReservationNotification.fromJson(data));
            }
          }
        } catch (e) {
          debugPrint('Error procesando reserva urgente: $e');
        }
      }

      if (!controller.isClosed) {
        controller.add(urgentNotifications);
      }
    } catch (e) {
      debugPrint('Error obteniendo reservas urgentes: $e');
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
  }

  // Fetch inicial
  fetchUrgentReservations();

  // Refresh periódico cada 30 minutos (para notificaciones urgentes)
  final timer = Timer.periodic(const Duration(minutes: 30), (_) => fetchUrgentReservations());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider para contar reservas urgentes sin procesar
final urgentReservationsCountProvider = Provider<AsyncValue<int>>((ref) {
  final urgentAsync = ref.watch(urgentReservationsProvider);
  return urgentAsync.whenData((list) => list.length);
});
