import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/model/FullReservation.dart';

class ReservationUtils {
  /// Formatea una fecha ISO 8601 a formato legible (yyyy-MM-dd)
  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      if (dateStr.contains('T')) {
        final parsedDate = DateTime.parse(dateStr);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  /// Retorna una descripción legible de la reserva completa
  static String formatFullReservation(FullReservation full) {
    final reservation = full.reservation;
    final dress = full.dress;
    final service = full.service;

    final buffer = StringBuffer();

    buffer.writeln(
        '📅 Fecha: ${_formatDate(reservation['reservation_date']?.toString())} a las ${reservation['reservation_time']}');
    buffer.writeln('🏬 Sucursal: ${reservation['branch_id']}');
    buffer.writeln('👗 Vestido: ${dress?['name'] ?? '-'}');
    buffer.writeln('🔖 Categoría: ${dress?['category'] ?? '-'}');
    buffer.writeln('🛎️ Servicio: ${service?['name'] ?? '-'}');
    buffer.writeln('💰 Precio: \$${formatPrice(service?['price'])}');
    buffer.writeln('⏱️ Duración: ${formatDuration(service?['duration'])}');
    buffer.writeln('📝 Descripción:\n${service?['description'] ?? '-'}');

    // Nuevos campos útiles
    buffer.writeln('🔢 Código Vestido: ${dress?['code'] ?? '-'}');
    buffer.writeln('📦 Código Paquete: ${service?['package_code'] ?? '-'}');
    buffer.writeln(
        '📆 Fecha de Reserva: ${reservation['reservation_date'] ?? '-'}');

    return buffer.toString();
  }

  /// Imprime la reserva con formato en consola
  static void debugPrintFullReservation(FullReservation full) {
    final formatted = formatFullReservation(full);
    debugPrint(
        '=== FULL RESERVATION ===\n$formatted\n=========================');
  }

  static String formatPrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is num) return price.toStringAsFixed(2);
    return double.tryParse(price.toString())?.toStringAsFixed(2) ?? '0.00';
  }

  static String formatDuration(dynamic duration) {
    if (duration is Map &&
        duration.containsKey('unit') &&
        duration.containsKey('value')) {
      return '${duration['value']} ${duration['unit']}';
    }
    return '-';
  }
}
