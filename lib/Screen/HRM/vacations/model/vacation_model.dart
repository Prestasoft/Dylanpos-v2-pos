/// Modelo de Vacaciones y Licencias según Ley 16-92 RD
class VacationModel {
  final num id;
  final num employeeId;
  final String employeeName;
  final String employeeCedula;
  final String designation;
  final String department;
  final String type; // Vacaciones, Licencia Médica, Maternidad, Paternidad, Personal
  final DateTime startDate;
  final DateTime endDate;
  final int daysRequested;
  final int daysApproved;
  final String status; // Pendiente, Aprobado, Rechazado, Cancelado, Completado
  final String? reason;
  final String? medicalCertificate; // URL del certificado médico si aplica
  final DateTime requestDate;
  final String? approvedBy;
  final DateTime? approvalDate;
  final String? rejectionReason;
  final String? notes;
  final bool isPaid; // Si las vacaciones son pagadas
  final double? vacationPay; // Monto de vacaciones si aplica

  VacationModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCedula,
    required this.designation,
    required this.department,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.daysRequested,
    this.daysApproved = 0,
    required this.status,
    this.reason,
    this.medicalCertificate,
    required this.requestDate,
    this.approvedBy,
    this.approvalDate,
    this.rejectionReason,
    this.notes,
    this.isPaid = true,
    this.vacationPay,
  });

  /// Calcular días entre fechas (solo días laborables)
  static int calculateBusinessDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  factory VacationModel.fromJson(Map<String, dynamic> json) {
    return VacationModel(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeCedula: json['employeeCedula'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'General',
      type: json['type'] ?? 'Vacaciones',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      daysRequested: json['daysRequested'] ?? 0,
      daysApproved: json['daysApproved'] ?? 0,
      status: json['status'] ?? 'Pendiente',
      reason: json['reason'],
      medicalCertificate: json['medicalCertificate'],
      requestDate: json['requestDate'] != null
          ? DateTime.parse(json['requestDate'])
          : DateTime.now(),
      approvedBy: json['approvedBy'],
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'])
          : null,
      rejectionReason: json['rejectionReason'],
      notes: json['notes'],
      isPaid: json['isPaid'] ?? true,
      vacationPay: json['vacationPay']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCedula': employeeCedula,
      'designation': designation,
      'department': department,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'daysRequested': daysRequested,
      'daysApproved': daysApproved,
      'status': status,
      'reason': reason,
      'medicalCertificate': medicalCertificate,
      'requestDate': requestDate.toIso8601String(),
      'approvedBy': approvedBy,
      'approvalDate': approvalDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'notes': notes,
      'isPaid': isPaid,
      'vacationPay': vacationPay,
    };
  }
}

/// Tipos de licencias según legislación dominicana
class LeaveTypes {
  static const String vacaciones = 'Vacaciones';
  static const String licenciaMedica = 'Licencia Médica';
  static const String licenciaMaternidad = 'Licencia Maternidad';
  static const String licenciaPaternidad = 'Licencia Paternidad';
  static const String permisoPersonal = 'Permiso Personal';
  static const String permisoPorDefuncion = 'Permiso por Defunción';
  static const String permisoMatrimonio = 'Permiso por Matrimonio';
  static const String licenciaSinSueldo = 'Licencia Sin Sueldo';
  static const String permisoEstudios = 'Permiso por Estudios';

  static List<String> get all => [
        vacaciones,
        licenciaMedica,
        licenciaMaternidad,
        licenciaPaternidad,
        permisoPersonal,
        permisoPorDefuncion,
        permisoMatrimonio,
        licenciaSinSueldo,
        permisoEstudios,
      ];

  /// Días por tipo de licencia según Ley 16-92
  static int getMaxDays(String type) {
    switch (type) {
      case vacaciones:
        return 14; // 14 días laborables después de 1 año
      case licenciaMedica:
        return 26; // Máximo con certificado médico (puede extenderse)
      case licenciaMaternidad:
        return 84; // 12 semanas (84 días)
      case licenciaPaternidad:
        return 2; // 2 días
      case permisoPorDefuncion:
        return 3; // 3 días para familiar directo
      case permisoMatrimonio:
        return 5; // 5 días
      default:
        return 0;
    }
  }

  /// Indica si el tipo de licencia es pagada
  static bool isPaid(String type) {
    switch (type) {
      case vacaciones:
      case licenciaMaternidad:
      case licenciaPaternidad:
      case permisoPorDefuncion:
      case permisoMatrimonio:
        return true;
      case licenciaSinSueldo:
        return false;
      case licenciaMedica:
        return true; // Los primeros 26 días son pagados (parcialmente por SDSS)
      default:
        return false;
    }
  }
}

/// Balance de vacaciones del empleado
class VacationBalance {
  final num employeeId;
  final String employeeName;
  final int yearsOfService;
  final int daysEntitled; // Días a los que tiene derecho
  final int daysUsed; // Días utilizados
  final int daysPending; // Días pendientes de aprobar
  final int daysAvailable; // Días disponibles
  final int daysCarriedOver; // Días del período anterior
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime? lastVacationDate;

  VacationBalance({
    required this.employeeId,
    required this.employeeName,
    required this.yearsOfService,
    required this.daysEntitled,
    required this.daysUsed,
    required this.daysPending,
    required this.daysAvailable,
    this.daysCarriedOver = 0,
    required this.periodStart,
    required this.periodEnd,
    this.lastVacationDate,
  });

  factory VacationBalance.fromJson(Map<String, dynamic> json) {
    return VacationBalance(
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      yearsOfService: json['yearsOfService'] ?? 0,
      daysEntitled: json['daysEntitled'] ?? 0,
      daysUsed: json['daysUsed'] ?? 0,
      daysPending: json['daysPending'] ?? 0,
      daysAvailable: json['daysAvailable'] ?? 0,
      daysCarriedOver: json['daysCarriedOver'] ?? 0,
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      lastVacationDate: json['lastVacationDate'] != null
          ? DateTime.parse(json['lastVacationDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'yearsOfService': yearsOfService,
      'daysEntitled': daysEntitled,
      'daysUsed': daysUsed,
      'daysPending': daysPending,
      'daysAvailable': daysAvailable,
      'daysCarriedOver': daysCarriedOver,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'lastVacationDate': lastVacationDate?.toIso8601String(),
    };
  }
}

/// Elegibilidad de vacaciones de un empleado (cálculo automático)
class VacationEligibility {
  final dynamic employeeId;
  final String employeeName;
  final String designation;
  final String department;
  final DateTime joiningDate;
  final int yearsOfService;
  final DateTime nextAnniversary;
  final int daysUntilAnniversary;
  final int daysAvailable;
  final int daysUsed;
  final int daysEntitled;
  final DateTime? lastVacationDate;
  final String urgencyLevel; // VENCIDO, URGENTE, PRÓXIMO, OK

  VacationEligibility({
    required this.employeeId,
    required this.employeeName,
    required this.designation,
    required this.department,
    required this.joiningDate,
    required this.yearsOfService,
    required this.nextAnniversary,
    required this.daysUntilAnniversary,
    required this.daysAvailable,
    required this.daysUsed,
    required this.daysEntitled,
    this.lastVacationDate,
    required this.urgencyLevel,
  });

  /// Determinar nivel de urgencia basado en días restantes y vacaciones disponibles
  static String calculateUrgency({
    required int daysUntilAnniversary,
    required int daysAvailable,
    required bool hasNeverTakenVacation,
  }) {
    // Tiene vacaciones vencidas (días disponibles > 0 y aniversario ya pasó o es inminente)
    if (daysAvailable >= 14 && hasNeverTakenVacation) return 'VENCIDO';
    if (daysUntilAnniversary <= 0 && daysAvailable > 0) return 'VENCIDO';
    if (daysUntilAnniversary <= 30) return 'URGENTE';
    if (daysUntilAnniversary <= 90) return 'PRÓXIMO';
    return 'OK';
  }
}
