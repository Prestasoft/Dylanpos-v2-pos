/// Modelo de seguimiento de cliente a través de los departamentos.
///
/// Cada cliente (reservación) tiene un pipeline de etapas (stages)
/// que corresponden a los departamentos por donde pasa.
class ClientTrackingModel {
  final String reservationId;
  final String customerName;
  final String serviceName;
  final String reservationDate;
  final String reservationTime;
  final String estado;
  final String? bookedById;
  final String? bookedByName;
  final List<StageStatus> stages;

  const ClientTrackingModel({
    required this.reservationId,
    required this.customerName,
    required this.serviceName,
    required this.reservationDate,
    required this.reservationTime,
    required this.estado,
    this.bookedById,
    this.bookedByName,
    required this.stages,
  });

  factory ClientTrackingModel.fromJson(Map<String, dynamic> json) {
    final tasksRaw = json['tasks'] as List<dynamic>? ?? [];
    final stages = tasksRaw
        .where((t) => t != null)
        .map((t) => StageStatus.fromJson(Map<String, dynamic>.from(t)))
        .toList();

    return ClientTrackingModel(
      reservationId: json['reservation_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Sin nombre',
      serviceName: json['service_name']?.toString() ?? '',
      reservationDate: json['reservation_date']?.toString() ?? '',
      reservationTime: json['reservation_time']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      bookedById: _cleanNull(json['booked_by_id']),
      bookedByName: _cleanNull(json['booked_by_name']),
      stages: stages,
    );
  }

  /// Limpia valores "null" que vienen como string del JSON
  static String? _cleanNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  /// True si no tiene recepcionista asignada
  bool get isUnassigned => bookedById == null || bookedById!.isEmpty;

  /// True si todas las etapas están completadas
  bool get isFullyCompleted =>
      stages.isNotEmpty && stages.every((s) => s.status == 'completada');

  /// Cantidad de etapas completadas
  int get completedCount => stages.where((s) => s.status == 'completada').length;
}

/// Estado de una etapa (departamento) en el pipeline del cliente.
class StageStatus {
  final String? taskId;
  final num? designationId;
  final String designationName;
  final String? status; // null, pendiente, en_progreso, completada, vencida
  final String? employeeName;
  final DateTime? assignedAt;
  final DateTime? dueAt;
  final DateTime? completedAt;

  const StageStatus({
    this.taskId,
    this.designationId,
    required this.designationName,
    this.status,
    this.employeeName,
    this.assignedAt,
    this.dueAt,
    this.completedAt,
  });

  factory StageStatus.fromJson(Map<String, dynamic> json) {
    return StageStatus(
      taskId: json['task_id']?.toString(),
      designationId: json['designation_id'] is num ? json['designation_id'] : num.tryParse(json['designation_id']?.toString() ?? ''),
      designationName: json['designation_name']?.toString() ?? '',
      status: json['status']?.toString(),
      employeeName: json['employee_name']?.toString(),
      assignedAt: _parseDate(json['assigned_at']),
      dueAt: _parseDate(json['due_at']),
      completedAt: _parseDate(json['completed_at']),
    );
  }

  /// Color indicador: gris=sin task, rojo=activo, amarillo=por vencer, verde=completado
  bool get isCompleted => status == 'completada';
  bool get isActive => status == 'pendiente' || status == 'en_progreso' || status == 'vencida';
  bool get isOverdue => status == 'vencida';

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
