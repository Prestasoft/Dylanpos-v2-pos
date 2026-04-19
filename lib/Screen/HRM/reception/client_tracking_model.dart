/// Modelo de seguimiento de cliente a través de los departamentos.
///
/// Cada cliente (reservación) tiene un pipeline de etapas (stages)
/// que corresponden a los departamentos por donde pasa.
class ClientTrackingModel {
  final String reservationId;
  final String customerName;
  final String customerPhone;
  final String? invoiceNumber;
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
    this.customerPhone = '',
    this.invoiceNumber,
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
      customerPhone: json['customer_phone']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString(),
      serviceName: json['service_name']?.toString() ?? '',
      reservationDate: json['reservation_date']?.toString() ?? '',
      reservationTime: json['reservation_time']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      bookedById: _cleanNull(json['booked_by_id']),
      bookedByName: _cleanNull(json['booked_by_name']),
      stages: stages,
    );
  }

  static String? _cleanNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  bool get isUnassigned => bookedById == null || bookedById!.isEmpty;

  bool get isFullyCompleted =>
      stages.isNotEmpty && stages.every((s) => s.status == 'completada');

  int get completedCount => stages.where((s) => s.status == 'completada').length;

  /// Agrupa stages por departamento para vista de seguimiento
  List<DepartmentGroup> get departmentGroups {
    final order = ['maquillaje', 'sesion', 'edicion', 'impresion'];
    final groups = <String, DepartmentGroup>{};

    for (final stage in stages) {
      final deptKey = _getDeptKey(stage.designationName);
      final deptLabel = _getDeptLabel(deptKey);

      groups.putIfAbsent(deptKey, () => DepartmentGroup(
        key: deptKey,
        label: deptLabel,
        tasks: [],
      ));
      groups[deptKey]!.tasks.add(stage);
    }

    // Ordenar según el flujo natural
    final sorted = <DepartmentGroup>[];
    for (final key in order) {
      if (groups.containsKey(key)) sorted.add(groups[key]!);
    }
    // Agregar departamentos no estándar al final
    for (final entry in groups.entries) {
      if (!order.contains(entry.key)) sorted.add(entry.value);
    }
    return sorted;
  }

  /// Determina en qué departamento está actualmente el cliente
  String get currentDepartment {
    final groups = departmentGroups;
    for (final g in groups) {
      if (g.hasActive) return g.key;
    }
    if (groups.isNotEmpty && groups.every((g) => g.isCompleted)) return 'completado';
    return 'seguimiento';
  }

  static String _getDeptKey(String designationName) {
    final lower = designationName.toLowerCase();
    if (lower.contains('maquill') || lower.contains('makeup') || lower.contains('belleza')) return 'maquillaje';
    if (lower.contains('fotograf') || lower.contains('photo') || lower.contains('film') || lower.contains('video') || lower.contains('cine')) return 'sesion';
    if (lower.contains('edic') || lower.contains('editor') || lower.contains('seleccion')) return 'edicion';
    if (lower.contains('impres') || lower.contains('enmarc')) return 'impresion';
    if (lower.contains('recepcion') || lower.contains('vendedor') || lower.contains('tienda')) return 'seguimiento';
    return lower.isNotEmpty ? lower : 'otro';
  }

  static String _getDeptLabel(String key) {
    switch (key) {
      case 'maquillaje': return 'Maquillaje';
      case 'sesion': return 'Sesión';
      case 'edicion': return 'Edición';
      case 'impresion': return 'Impresión';
      case 'seguimiento': return 'Seguimiento';
      default: return key[0].toUpperCase() + key.substring(1);
    }
  }
}

/// Grupo de tasks por departamento
class DepartmentGroup {
  final String key;
  final String label;
  final List<StageStatus> tasks;

  DepartmentGroup({required this.key, required this.label, required this.tasks});

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.status == 'completada').length;
  bool get isCompleted => tasks.isNotEmpty && tasks.every((t) => t.status == 'completada');
  bool get hasActive => tasks.any((t) => t.status == 'pendiente' || t.status == 'en_progreso' || t.status == 'vencida');
  bool get hasOverdue => tasks.any((t) => t.status == 'vencida');
  bool get hasInProgress => tasks.any((t) => t.status == 'en_progreso');
  bool get isEmpty => tasks.isEmpty;

  /// Nombres de empleados únicos asignados
  List<String> get employeeNames {
    final names = <String>{};
    for (final t in tasks) {
      if (t.employeeName != null && t.employeeName!.trim().isNotEmpty) {
        names.add(t.employeeName!.trim().split(' ').first);
      }
    }
    return names.toList();
  }

  /// Estado general del grupo
  DepartmentStatus get status {
    if (isEmpty) return DepartmentStatus.pending;
    if (isCompleted) return DepartmentStatus.completed;
    if (hasOverdue) return DepartmentStatus.overdue;
    if (hasInProgress) return DepartmentStatus.inProgress;
    if (hasActive) return DepartmentStatus.waiting;
    return DepartmentStatus.pending;
  }
}

enum DepartmentStatus { pending, waiting, inProgress, overdue, completed }

/// Estado de una etapa (departamento) en el pipeline del cliente.
class StageStatus {
  final String? taskId;
  final num? designationId;
  final String designationName;
  final String? status;
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

  bool get isCompleted => status == 'completada';
  bool get isActive => status == 'pendiente' || status == 'en_progreso' || status == 'vencida';
  bool get isOverdue => status == 'vencida';

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
