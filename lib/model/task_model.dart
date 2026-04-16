/// Modelo de Tarea asignada a un empleado con SLA.
///
/// Fuente de verdad del sistema de tareas por departamento. Una reserva
/// puede generar múltiples tasks (fotógrafo + maquillista + editor + vendedor),
/// cada uno con su propio reloj y due_at.
class TaskModel {
  final String id;
  final String reservationId;
  final num designationId;
  final String? designationName;
  final String? designationColor;
  final String? reservationNota;

  final String? assignedToUserId;
  final String? assignedToEmployeeId;
  final String? assignedByUserId;

  final DateTime assignedAt;
  final DateTime dueAt;
  final TaskStatus status;
  final DateTime? completedAt;
  final String? completionNote;

  final String branchId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.reservationId,
    required this.designationId,
    this.designationName,
    this.designationColor,
    this.reservationNota,
    this.assignedToUserId,
    this.assignedToEmployeeId,
    this.assignedByUserId,
    required this.assignedAt,
    required this.dueAt,
    required this.status,
    this.completedAt,
    this.completionNote,
    required this.branchId,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      reservationId: json['reservation_id']?.toString() ?? '',
      designationId: _parseNum(json['designation_id']),
      designationName: json['designation_name']?.toString(),
      designationColor: json['designation_color']?.toString(),
      reservationNota: json['reservation_nota']?.toString(),
      assignedToUserId: json['assigned_to_user_id']?.toString(),
      assignedToEmployeeId: json['assigned_to_employee_id']?.toString(),
      assignedByUserId: json['assigned_by_user_id']?.toString(),
      assignedAt: _parseDate(json['assigned_at']) ?? DateTime.now(),
      dueAt: _parseDate(json['due_at']) ?? DateTime.now(),
      status: _parseStatus(json['status']?.toString()),
      completedAt: _parseDate(json['completed_at']),
      completionNote: json['completion_note']?.toString(),
      branchId: json['branch_id']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  /// Tiempo total del SLA originalmente asignado
  Duration get totalSlaDuration => dueAt.difference(assignedAt);

  /// Tiempo restante hasta el vencimiento (negativo si ya venció)
  Duration timeRemaining([DateTime? now]) =>
      dueAt.difference(now ?? DateTime.now());

  /// Porcentaje del tiempo consumido (0.0 a 1.0+ donde >1.0 = vencida)
  double progress([DateTime? now]) {
    final total = totalSlaDuration.inMilliseconds;
    if (total <= 0) return 1.0;
    final elapsed =
        (now ?? DateTime.now()).difference(assignedAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 2.0);
  }

  /// Estado visual basado en % consumido + status real
  TaskUrgency get urgency {
    if (status == TaskStatus.completada) return TaskUrgency.done;
    if (status == TaskStatus.vencida || progress() >= 1.0) {
      return TaskUrgency.overdue;
    }
    final p = progress();
    if (p >= 0.8) return TaskUrgency.critical;
    if (p >= 0.5) return TaskUrgency.warning;
    return TaskUrgency.normal;
  }

  static num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static TaskStatus _parseStatus(String? s) {
    switch (s) {
      case 'en_progreso':
        return TaskStatus.enProgreso;
      case 'completada':
        return TaskStatus.completada;
      case 'vencida':
        return TaskStatus.vencida;
      case 'pendiente':
      default:
        return TaskStatus.pendiente;
    }
  }
}

enum TaskStatus { pendiente, enProgreso, completada, vencida }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pendiente:
        return 'Pendiente';
      case TaskStatus.enProgreso:
        return 'En progreso';
      case TaskStatus.completada:
        return 'Completada';
      case TaskStatus.vencida:
        return 'Vencida';
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.pendiente:
        return 'pendiente';
      case TaskStatus.enProgreso:
        return 'en_progreso';
      case TaskStatus.completada:
        return 'completada';
      case TaskStatus.vencida:
        return 'vencida';
    }
  }
}

/// Urgencia visual para el TaskCountdownCard
enum TaskUrgency { normal, warning, critical, overdue, done }
