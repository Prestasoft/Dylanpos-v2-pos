/// Modelo para el estado de lavandería de un vestido
class DressLaundryStatus {
  final String id;
  final String dressId;
  final bool inLaundry;
  final DateTime? laundryStartDate;
  final DateTime? estimatedReadyDate;
  final String? laundryNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  DressLaundryStatus({
    required this.id,
    required this.dressId,
    required this.inLaundry,
    this.laundryStartDate,
    this.estimatedReadyDate,
    this.laundryNotes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// ¿Cuántos días faltan para que esté listo?
  int get daysUntilReady {
    if (estimatedReadyDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ready = DateTime(
      estimatedReadyDate!.year,
      estimatedReadyDate!.month,
      estimatedReadyDate!.day,
    );

    final diff = ready.difference(today);
    return diff.inDays;
  }

  /// ¿Está listo para agendar en una fecha específica?
  bool isReadyForDate(DateTime targetDate) {
    if (!inLaundry) return true;
    if (estimatedReadyDate == null) return false;

    // Comparar solo fechas (sin hora)
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final ready = DateTime(
      estimatedReadyDate!.year,
      estimatedReadyDate!.month,
      estimatedReadyDate!.day,
    );

    // Está listo si la fecha objetivo es igual o posterior a la fecha estimada
    return target.isAfter(ready) || target.isAtSameMomentAs(ready);
  }

  factory DressLaundryStatus.fromMap(Map<String, dynamic> map) {
    return DressLaundryStatus(
      id: map['id']?.toString() ?? '',
      dressId: map['dress_id']?.toString() ?? '',
      inLaundry: map['in_laundry'] ?? false,
      laundryStartDate: map['laundry_start_date'] != null
          ? _parseDateTime(map['laundry_start_date'])
          : null,
      estimatedReadyDate: map['estimated_ready_date'] != null
          ? _parseDateTime(map['estimated_ready_date'])
          : null,
      laundryNotes: map['laundry_notes']?.toString(),
      createdAt: map['created_at'] != null
          ? _parseDateTime(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? _parseDateTime(map['updated_at'])
          : null,
      createdBy: map['created_by']?.toString(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dress_id': dressId,
      'in_laundry': inLaundry,
      'laundry_start_date': laundryStartDate?.toIso8601String(),
      'estimated_ready_date': estimatedReadyDate?.toIso8601String().split('T')[0],
      'laundry_notes': laundryNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  @override
  String toString() {
    return 'DressLaundryStatus(dressId: $dressId, inLaundry: $inLaundry, estimatedReady: $estimatedReadyDate)';
  }
}
