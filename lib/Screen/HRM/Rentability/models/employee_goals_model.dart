/// Modelo para Metas/Objetivos Mensuales de Empleados
class EmployeeGoal {
  final String id;
  final String employeeId;
  final String employeeName;
  final int year;
  final int month;
  final double targetRevenue;
  final int targetReservations;
  final double targetCommission;
  final double actualRevenue;
  final int actualReservations;
  final double actualCommission;
  final String status; // 'pending', 'in_progress', 'achieved', 'not_achieved'
  final DateTime createdAt;
  final DateTime? achievedAt;

  EmployeeGoal({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.month,
    required this.targetRevenue,
    required this.targetReservations,
    required this.targetCommission,
    this.actualRevenue = 0.0,
    this.actualReservations = 0,
    this.actualCommission = 0.0,
    this.status = 'pending',
    required this.createdAt,
    this.achievedAt,
  });

  /// Progreso de ingresos (0.0 - 1.0)
  double get revenueProgress {
    if (targetRevenue == 0) return 0.0;
    return (actualRevenue / targetRevenue).clamp(0.0, 1.0);
  }

  /// Progreso de reservas (0.0 - 1.0)
  double get reservationsProgress {
    if (targetReservations == 0) return 0.0;
    return (actualReservations / targetReservations).clamp(0.0, 1.0);
  }

  /// Progreso de comisiones (0.0 - 1.0)
  double get commissionProgress {
    if (targetCommission == 0) return 0.0;
    return (actualCommission / targetCommission).clamp(0.0, 1.0);
  }

  /// Progreso general (promedio ponderado)
  double get overallProgress {
    return (revenueProgress * 0.5) +
           (reservationsProgress * 0.3) +
           (commissionProgress * 0.2);
  }

  /// ¿Meta cumplida?
  bool get isAchieved {
    return revenueProgress >= 1.0 &&
           reservationsProgress >= 1.0 &&
           commissionProgress >= 1.0;
  }

  /// Días restantes en el mes
  int get daysRemaining {
    final now = DateTime.now();
    final endOfMonth = DateTime(year, month + 1, 0);
    if (now.isAfter(endOfMonth)) return 0;
    return endOfMonth.difference(now).inDays;
  }

  factory EmployeeGoal.fromMap(Map<String, dynamic> map) {
    return EmployeeGoal(
      id: map['id']?.toString() ?? '',
      employeeId: map['employee_id']?.toString() ?? '',
      employeeName: map['employee_name']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (map['month'] as num?)?.toInt() ?? DateTime.now().month,
      targetRevenue: (map['target_revenue'] as num?)?.toDouble() ?? 0.0,
      targetReservations: (map['target_reservations'] as num?)?.toInt() ?? 0,
      targetCommission: (map['target_commission'] as num?)?.toDouble() ?? 0.0,
      actualRevenue: (map['actual_revenue'] as num?)?.toDouble() ?? 0.0,
      actualReservations: (map['actual_reservations'] as num?)?.toInt() ?? 0,
      actualCommission: (map['actual_commission'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'pending',
      createdAt: _parseDateTime(map['created_at']),
      achievedAt: map['achieved_at'] != null ? _parseDateTime(map['achieved_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'year': year,
      'month': month,
      'target_revenue': targetRevenue,
      'target_reservations': targetReservations,
      'target_commission': targetCommission,
      'actual_revenue': actualRevenue,
      'actual_reservations': actualReservations,
      'actual_commission': actualCommission,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'achieved_at': achievedAt?.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  EmployeeGoal copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    int? year,
    int? month,
    double? targetRevenue,
    int? targetReservations,
    double? targetCommission,
    double? actualRevenue,
    int? actualReservations,
    double? actualCommission,
    String? status,
    DateTime? createdAt,
    DateTime? achievedAt,
  }) {
    return EmployeeGoal(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      year: year ?? this.year,
      month: month ?? this.month,
      targetRevenue: targetRevenue ?? this.targetRevenue,
      targetReservations: targetReservations ?? this.targetReservations,
      targetCommission: targetCommission ?? this.targetCommission,
      actualRevenue: actualRevenue ?? this.actualRevenue,
      actualReservations: actualReservations ?? this.actualReservations,
      actualCommission: actualCommission ?? this.actualCommission,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }
}

/// Plantilla de Meta (para crear metas masivamente)
class GoalTemplate {
  final double defaultTargetRevenue;
  final int defaultTargetReservations;
  final double defaultTargetCommission;

  GoalTemplate({
    required this.defaultTargetRevenue,
    required this.defaultTargetReservations,
    required this.defaultTargetCommission,
  });

  factory GoalTemplate.standard() {
    return GoalTemplate(
      defaultTargetRevenue: 50000.0,
      defaultTargetReservations: 10,
      defaultTargetCommission: 2500.0,
    );
  }

  factory GoalTemplate.fromMap(Map<String, dynamic> map) {
    return GoalTemplate(
      defaultTargetRevenue: (map['default_target_revenue'] as num?)?.toDouble() ?? 50000.0,
      defaultTargetReservations: (map['default_target_reservations'] as num?)?.toInt() ?? 10,
      defaultTargetCommission: (map['default_target_commission'] as num?)?.toDouble() ?? 2500.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default_target_revenue': defaultTargetRevenue,
      'default_target_reservations': defaultTargetReservations,
      'default_target_commission': defaultTargetCommission,
    };
  }
}
