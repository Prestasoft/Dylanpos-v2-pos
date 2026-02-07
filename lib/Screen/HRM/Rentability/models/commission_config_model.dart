/// Modelo de Configuración de Comisiones
class CommissionConfig {
  final String id;
  final String branchId;

  // Niveles de comisión
  final CommissionTier goldTier;    // Top 20%
  final CommissionTier silverTier;  // Top 50%
  final CommissionTier bronzeTier;  // Resto

  // Reglas
  final bool onlyPaidInvoices;
  final bool excludeCancellations;
  final int gracePeriodDays;        // Días antes de contar comisión

  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionConfig({
    required this.id,
    required this.branchId,
    required this.goldTier,
    required this.silverTier,
    required this.bronzeTier,
    this.onlyPaidInvoices = true,
    this.excludeCancellations = true,
    this.gracePeriodDays = 7,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Configuración por defecto
  factory CommissionConfig.defaultConfig(String branchId) {
    return CommissionConfig(
      id: '',
      branchId: branchId,
      goldTier: CommissionTier(
        name: 'Oro',
        percentage: 5.0,
        minMonthlyRevenue: 30000.0,
        minMonthlyReservations: 15,
        color: 0xFFFFD700, // Dorado
      ),
      silverTier: CommissionTier(
        name: 'Plata',
        percentage: 3.0,
        minMonthlyRevenue: 20000.0,
        minMonthlyReservations: 10,
        color: 0xFFC0C0C0, // Plateado
      ),
      bronzeTier: CommissionTier(
        name: 'Bronce',
        percentage: 1.5,
        minMonthlyRevenue: 10000.0,
        minMonthlyReservations: 5,
        color: 0xFFCD7F32, // Bronce
      ),
    );
  }

  factory CommissionConfig.fromMap(Map<String, dynamic> map, String id) {
    return CommissionConfig(
      id: id,
      branchId: map['branch_id']?.toString() ?? '',
      goldTier: CommissionTier.fromMap(map['gold_tier'] ?? {}),
      silverTier: CommissionTier.fromMap(map['silver_tier'] ?? {}),
      bronzeTier: CommissionTier.fromMap(map['bronze_tier'] ?? {}),
      onlyPaidInvoices: map['only_paid_invoices'] ?? true,
      excludeCancellations: map['exclude_cancellations'] ?? true,
      gracePeriodDays: map['grace_period_days'] ?? 7,
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'branch_id': branchId,
      'gold_tier': goldTier.toMap(),
      'silver_tier': silverTier.toMap(),
      'bronze_tier': bronzeTier.toMap(),
      'only_paid_invoices': onlyPaidInvoices,
      'exclude_cancellations': excludeCancellations,
      'grace_period_days': gracePeriodDays,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}

/// Nivel de Comisión (Tier)
class CommissionTier {
  final String name;              // "Oro", "Plata", "Bronce"
  final double percentage;        // 5.0, 3.0, 1.5
  final double minMonthlyRevenue; // 30000, 20000, 10000
  final int minMonthlyReservations; // 15, 10, 5
  final int color;                // Color hex para UI

  CommissionTier({
    required this.name,
    required this.percentage,
    required this.minMonthlyRevenue,
    required this.minMonthlyReservations,
    this.color = 0xFF9E9E9E, // Gris por defecto
  });

  factory CommissionTier.fromMap(Map<String, dynamic> map) {
    return CommissionTier(
      name: map['name']?.toString() ?? '',
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      minMonthlyRevenue: (map['min_monthly_revenue'] ?? 0.0).toDouble(),
      minMonthlyReservations: map['min_monthly_reservations'] ?? 0,
      color: map['color'] ?? 0xFF9E9E9E,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percentage': percentage,
      'min_monthly_revenue': minMonthlyRevenue,
      'min_monthly_reservations': minMonthlyReservations,
      'color': color,
    };
  }

  /// Verifica si un empleado cumple los requisitos para este tier
  bool meetsRequirements(double revenue, int reservations) {
    return revenue >= minMonthlyRevenue && reservations >= minMonthlyReservations;
  }
}
