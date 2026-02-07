import 'commission_config_model.dart';

/// Modelo de Desempeño del Empleado
class EmployeePerformance {
  final String employeeId;
  final String employeeName;
  final String? photoUrl;

  // Período
  final DateTime periodStart;
  final DateTime periodEnd;

  // Métricas
  final int totalReservations;
  final int invoicedReservations;
  final int pendingReservations;

  final double totalRevenue;           // Monto total facturado
  final double commissionPercentage;   // % aplicado
  final double commissionEarned;       // $ ganado

  final CommissionTier? assignedTier;   // Nivel asignado
  final int ranking;                    // Posición en ranking

  // Detalles
  final List<ReservationCommission> invoicedDetails;
  final List<PendingReservation> pendingDetails;

  final DateTime calculatedAt;

  EmployeePerformance({
    required this.employeeId,
    required this.employeeName,
    this.photoUrl,
    required this.periodStart,
    required this.periodEnd,
    this.totalReservations = 0,
    this.invoicedReservations = 0,
    this.pendingReservations = 0,
    this.totalRevenue = 0.0,
    this.commissionPercentage = 0.0,
    this.commissionEarned = 0.0,
    this.assignedTier,
    this.ranking = 0,
    this.invoicedDetails = const [],
    this.pendingDetails = const [],
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  /// Tasa de conversión (% de reservas facturadas)
  double get conversionRate {
    if (totalReservations == 0) return 0.0;
    return (invoicedReservations / totalReservations) * 100;
  }

  /// Promedio por reserva facturada
  double get averageRevenuePerReservation {
    if (invoicedReservations == 0) return 0.0;
    return totalRevenue / invoicedReservations;
  }

  factory EmployeePerformance.fromMap(Map<String, dynamic> map) {
    // Parsear invoiced details
    final invoicedList = <ReservationCommission>[];
    if (map['invoiced_details'] is List) {
      for (var item in map['invoiced_details']) {
        if (item is Map) {
          invoicedList.add(ReservationCommission.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Parsear pending details
    final pendingList = <PendingReservation>[];
    if (map['pending_details'] is List) {
      for (var item in map['pending_details']) {
        if (item is Map) {
          pendingList.add(PendingReservation.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Parsear tier si existe
    CommissionTier? tier;
    if (map['assigned_tier'] != null && map['assigned_tier'] is Map) {
      tier = CommissionTier.fromMap(Map<String, dynamic>.from(map['assigned_tier']));
    }

    return EmployeePerformance(
      employeeId: map['employee_id']?.toString() ?? '',
      employeeName: map['employee_name']?.toString() ?? '',
      photoUrl: map['photo_url']?.toString(),
      periodStart: _parseDateTime(map['period_start']),
      periodEnd: _parseDateTime(map['period_end']),
      totalReservations: map['total_reservations'] ?? 0,
      invoicedReservations: map['invoiced_reservations'] ?? 0,
      pendingReservations: map['pending_reservations'] ?? 0,
      totalRevenue: (map['total_revenue'] ?? 0.0).toDouble(),
      commissionPercentage: (map['commission_percentage'] ?? 0.0).toDouble(),
      commissionEarned: (map['commission_earned'] ?? 0.0).toDouble(),
      assignedTier: tier,
      ranking: map['ranking'] ?? 0,
      invoicedDetails: invoicedList,
      pendingDetails: pendingList,
      calculatedAt: _parseDateTime(map['calculated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'photo_url': photoUrl,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_reservations': totalReservations,
      'invoiced_reservations': invoicedReservations,
      'pending_reservations': pendingReservations,
      'total_revenue': totalRevenue,
      'commission_percentage': commissionPercentage,
      'commission_earned': commissionEarned,
      'assigned_tier': assignedTier?.toMap(),
      'ranking': ranking,
      'invoiced_details': invoicedDetails.map((e) => e.toMap()).toList(),
      'pending_details': pendingDetails.map((e) => e.toMap()).toList(),
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }
}

/// Comisión por Reserva Facturada
class ReservationCommission {
  final String reservationId;
  final String? invoiceNumber;
  final String customerName;
  final DateTime reservationDate;
  final DateTime? invoiceDate;
  final double amount;
  final double commissionRate;
  final double commissionAmount;
  final bool commissionPaid;          // Si ya se pagó al empleado
  final DateTime? paidDate;

  ReservationCommission({
    required this.reservationId,
    this.invoiceNumber,
    required this.customerName,
    required this.reservationDate,
    this.invoiceDate,
    required this.amount,
    required this.commissionRate,
    required this.commissionAmount,
    this.commissionPaid = false,
    this.paidDate,
  });

  factory ReservationCommission.fromMap(Map<String, dynamic> map) {
    return ReservationCommission(
      reservationId: map['reservation_id']?.toString() ?? '',
      invoiceNumber: map['invoice_number']?.toString(),
      customerName: map['customer_name']?.toString() ?? '',
      reservationDate: _parseDateTime(map['reservation_date']),
      invoiceDate: map['invoice_date'] != null ? _parseDateTime(map['invoice_date']) : null,
      amount: (map['amount'] ?? 0.0).toDouble(),
      commissionRate: (map['commission_rate'] ?? 0.0).toDouble(),
      commissionAmount: (map['commission_amount'] ?? 0.0).toDouble(),
      commissionPaid: map['commission_paid'] ?? false,
      paidDate: map['paid_date'] != null ? _parseDateTime(map['paid_date']) : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'reservation_id': reservationId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'reservation_date': reservationDate.toIso8601String(),
      'invoice_date': invoiceDate?.toIso8601String(),
      'amount': amount,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'commission_paid': commissionPaid,
      'paid_date': paidDate?.toIso8601String(),
    };
  }
}

/// Reserva Pendiente de Facturar
class PendingReservation {
  final String reservationId;
  final String customerName;
  final String customerPhone;
  final String employeeName;
  final DateTime reservationDate;
  final DateTime eventDate;
  final double estimatedAmount;
  final int daysWithoutInvoice;
  final String serviceName;
  final String place;
  final String reservationTime;
  final dynamic dressIds;
  final String estado;
  final String nota;

  PendingReservation({
    required this.reservationId,
    required this.customerName,
    this.customerPhone = '',
    required this.employeeName,
    required this.reservationDate,
    required this.eventDate,
    required this.estimatedAmount,
    required this.daysWithoutInvoice,
    this.serviceName = '',
    this.place = '',
    this.reservationTime = '',
    this.dressIds,
    this.estado = 'pendiente',
    this.nota = '',
  });

  /// Nivel de urgencia basado en días sin facturar
  String get urgencyLevel {
    if (daysWithoutInvoice >= 10) return 'high';     // Rojo
    if (daysWithoutInvoice >= 5) return 'medium';    // Naranja
    return 'low';                                     // Verde
  }

  factory PendingReservation.fromMap(Map<String, dynamic> map) {
    return PendingReservation(
      reservationId: map['reservation_id']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString() ?? '',
      employeeName: map['employee_name']?.toString() ?? '',
      reservationDate: _parseDateTime(map['reservation_date']),
      eventDate: _parseDateTime(map['event_date']),
      estimatedAmount: (map['estimated_amount'] ?? 0.0).toDouble(),
      daysWithoutInvoice: map['days_without_invoice'] ?? 0,
      serviceName: map['service_name']?.toString() ?? '',
      place: map['place']?.toString() ?? '',
      reservationTime: map['reservation_time']?.toString() ?? '',
      dressIds: map['dress_ids'],
      estado: map['estado']?.toString() ?? 'pendiente',
      nota: map['nota']?.toString() ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'reservation_id': reservationId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'reservation_date': reservationDate.toIso8601String(),
      'event_date': eventDate.toIso8601String(),
      'estimated_amount': estimatedAmount,
      'days_without_invoice': daysWithoutInvoice,
      'service_name': serviceName,
      'place': place,
      'reservation_time': reservationTime,
      'dress_ids': dressIds,
      'estado': estado,
      'nota': nota,
    };
  }
}
