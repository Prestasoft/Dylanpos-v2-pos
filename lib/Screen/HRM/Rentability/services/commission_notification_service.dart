import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/services/api_service.dart';
import 'dart:html' as html;

/// Servicio para notificar a empleados sobre comisiones pagadas
class CommissionNotificationService {
  final ApiService _apiService = ApiService();

  /// Enviar notificación de comisión pagada por WhatsApp
  Future<bool> sendWhatsAppNotification({
    required String employeeName,
    required String employeePhone,
    required double commissionAmount,
    required double commissionPercentage,
    required double totalRevenue,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String paymentMethod,
  }) async {
    try {
      if (employeePhone.isEmpty) {
        debugPrint('⚠️ No hay teléfono registrado para $employeeName');
        return false;
      }

      // Formatear el mensaje
      final message = _buildWhatsAppMessage(
        employeeName: employeeName,
        commissionAmount: commissionAmount,
        commissionPercentage: commissionPercentage,
        totalRevenue: totalRevenue,
        periodStart: periodStart,
        periodEnd: periodEnd,
        paymentMethod: paymentMethod,
      );

      // Limpiar número de teléfono (solo dígitos)
      final cleanPhone = employeePhone.replaceAll(RegExp(r'[^\d]'), '');

      // Construir URL de WhatsApp
      final whatsappUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

      // Abrir WhatsApp en nueva ventana
      html.window.open(whatsappUrl, '_blank');

      debugPrint('✅ WhatsApp abierto para $employeeName - $cleanPhone');
      return true;
    } catch (e) {
      debugPrint('❌ Error enviando notificación WhatsApp: $e');
      return false;
    }
  }

  /// Enviar notificación por email (requiere backend)
  Future<bool> sendEmailNotification({
    required String employeeName,
    required String employeeEmail,
    required double commissionAmount,
    required double commissionPercentage,
    required double totalRevenue,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String paymentMethod,
    required String paidBy,
  }) async {
    try {
      if (employeeEmail.isEmpty) {
        debugPrint('⚠️ No hay email registrado para $employeeName');
        return false;
      }

      final response = await _apiService.post('rentability/send-commission-email', {
        'employee_name': employeeName,
        'employee_email': employeeEmail,
        'commission_amount': commissionAmount,
        'commission_percentage': commissionPercentage,
        'total_revenue': totalRevenue,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'payment_method': paymentMethod,
        'paid_by': paidBy,
      });

      if (response.success) {
        debugPrint('✅ Email enviado a $employeeEmail');
        return true;
      } else {
        debugPrint('⚠️ Error enviando email: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error enviando email: $e');
      return false;
    }
  }

  /// Construir mensaje de WhatsApp
  String _buildWhatsAppMessage({
    required String employeeName,
    required double commissionAmount,
    required double commissionPercentage,
    required double totalRevenue,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String paymentMethod,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return '''
🎉 *COMISIÓN PAGADA* 🎉

Hola *$employeeName*,

Te informamos que tu comisión del período *${dateFormat.format(periodStart)}* al *${dateFormat.format(periodEnd)}* ha sido procesada exitosamente.

📊 *DETALLE DE TU COMISIÓN:*
━━━━━━━━━━━━━━━━━━━━━
💰 Monto Comisión: *${currencyFormat.format(commissionAmount)}*
📈 Porcentaje: *${commissionPercentage.toStringAsFixed(1)}%*
💵 Total Facturado: ${currencyFormat.format(totalRevenue)}
💳 Método de Pago: *$paymentMethod*

¡Felicitaciones por tu excelente desempeño! 🌟

_Mensaje generado automáticamente por Victor Guzmán POS_
''';
  }

  /// Obtener datos del empleado desde el API
  Future<Map<String, dynamic>?> getEmployeeContactInfo(String employeeId) async {
    try {
      final response = await _apiService.get('employees/$employeeId');

      if (response.success && response.data != null) {
        final employee = response.data['employee'];
        return {
          'name': employee['full_name'] ?? '',
          'phone': employee['phone_number'] ?? '',
          'email': employee['email'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo contacto del empleado: $e');
      return null;
    }
  }
}
