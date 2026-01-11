/// Modelo de Asistencia para control de empleados
class AttendanceModel {
  final num id;
  final num employeeId;
  final String employeeName;
  final String employeeCedula;
  final String designation;
  final String department;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime? breakStartTime;
  final DateTime? breakEndTime;
  final String status; // Presente, Ausente, Tardanza, Permiso, Vacaciones, Licencia
  final double hoursWorked;
  final double overtimeHours;
  final double lateMinutes;
  final double earlyDepartureMinutes;
  final String? checkInMethod; // Manual, Biometrico, App, Tarjeta
  final String? checkOutMethod;
  final String? location; // Ubicación si es registro móvil
  final String? notes;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCedula,
    required this.designation,
    required this.department,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.breakStartTime,
    this.breakEndTime,
    required this.status,
    this.hoursWorked = 0,
    this.overtimeHours = 0,
    this.lateMinutes = 0,
    this.earlyDepartureMinutes = 0,
    this.checkInMethod,
    this.checkOutMethod,
    this.location,
    this.notes,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  });

  /// Calcular horas trabajadas
  double calculateHoursWorked() {
    if (checkInTime == null || checkOutTime == null) return 0;

    final totalMinutes = checkOutTime!.difference(checkInTime!).inMinutes;
    double breakMinutes = 0;

    if (breakStartTime != null && breakEndTime != null) {
      breakMinutes = breakEndTime!.difference(breakStartTime!).inMinutes.toDouble();
    }

    return (totalMinutes - breakMinutes) / 60;
  }

  /// Verificar si llegó tarde (después de las 8:00 AM por defecto)
  bool isLate({int expectedHour = 8, int expectedMinute = 0}) {
    if (checkInTime == null) return false;
    final expected = DateTime(
      checkInTime!.year,
      checkInTime!.month,
      checkInTime!.day,
      expectedHour,
      expectedMinute,
    );
    return checkInTime!.isAfter(expected);
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeCedula: json['employeeCedula'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'General',
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      breakStartTime: json['breakStartTime'] != null
          ? DateTime.parse(json['breakStartTime'])
          : null,
      breakEndTime: json['breakEndTime'] != null
          ? DateTime.parse(json['breakEndTime'])
          : null,
      status: json['status'] ?? 'Presente',
      hoursWorked: (json['hoursWorked'] ?? 0).toDouble(),
      overtimeHours: (json['overtimeHours'] ?? 0).toDouble(),
      lateMinutes: (json['lateMinutes'] ?? 0).toDouble(),
      earlyDepartureMinutes: (json['earlyDepartureMinutes'] ?? 0).toDouble(),
      checkInMethod: json['checkInMethod'],
      checkOutMethod: json['checkOutMethod'],
      location: json['location'],
      notes: json['notes'],
      isApproved: json['isApproved'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
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
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'breakStartTime': breakStartTime?.toIso8601String(),
      'breakEndTime': breakEndTime?.toIso8601String(),
      'status': status,
      'hoursWorked': hoursWorked,
      'overtimeHours': overtimeHours,
      'lateMinutes': lateMinutes,
      'earlyDepartureMinutes': earlyDepartureMinutes,
      'checkInMethod': checkInMethod,
      'checkOutMethod': checkOutMethod,
      'location': location,
      'notes': notes,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}

/// Estados de asistencia
class AttendanceStatus {
  static const String presente = 'Presente';
  static const String ausente = 'Ausente';
  static const String tardanza = 'Tardanza';
  static const String permiso = 'Permiso';
  static const String vacaciones = 'Vacaciones';
  static const String licenciaMedica = 'Licencia Médica';
  static const String licenciaMaternidad = 'Licencia Maternidad';
  static const String licenciaPaternidad = 'Licencia Paternidad';
  static const String diaLibre = 'Día Libre';
  static const String feriado = 'Feriado';
  static const String suspendido = 'Suspendido';

  static List<String> get all => [
        presente,
        ausente,
        tardanza,
        permiso,
        vacaciones,
        licenciaMedica,
        licenciaMaternidad,
        licenciaPaternidad,
        diaLibre,
        feriado,
        suspendido,
      ];
}

/// Resumen mensual de asistencia
class AttendanceSummary {
  final num employeeId;
  final String employeeName;
  final String month;
  final String year;
  final int totalDays;
  final int daysPresent;
  final int daysAbsent;
  final int daysLate;
  final int daysOnLeave;
  final int daysOnVacation;
  final double totalHoursWorked;
  final double totalOvertimeHours;
  final double totalLateMinutes;
  final double attendancePercentage;

  AttendanceSummary({
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.daysPresent,
    required this.daysAbsent,
    required this.daysLate,
    required this.daysOnLeave,
    required this.daysOnVacation,
    required this.totalHoursWorked,
    required this.totalOvertimeHours,
    required this.totalLateMinutes,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      month: json['month'],
      year: json['year'],
      totalDays: json['totalDays'] ?? 0,
      daysPresent: json['daysPresent'] ?? 0,
      daysAbsent: json['daysAbsent'] ?? 0,
      daysLate: json['daysLate'] ?? 0,
      daysOnLeave: json['daysOnLeave'] ?? 0,
      daysOnVacation: json['daysOnVacation'] ?? 0,
      totalHoursWorked: (json['totalHoursWorked'] ?? 0).toDouble(),
      totalOvertimeHours: (json['totalOvertimeHours'] ?? 0).toDouble(),
      totalLateMinutes: (json['totalLateMinutes'] ?? 0).toDouble(),
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'month': month,
      'year': year,
      'totalDays': totalDays,
      'daysPresent': daysPresent,
      'daysAbsent': daysAbsent,
      'daysLate': daysLate,
      'daysOnLeave': daysOnLeave,
      'daysOnVacation': daysOnVacation,
      'totalHoursWorked': totalHoursWorked,
      'totalOvertimeHours': totalOvertimeHours,
      'totalLateMinutes': totalLateMinutes,
      'attendancePercentage': attendancePercentage,
    };
  }
}

/// Feriados de República Dominicana (actualizables por año)
class HolidaysRD {
  static List<DateTime> getHolidays(int year) {
    return [
      DateTime(year, 1, 1), // Año Nuevo
      DateTime(year, 1, 6), // Día de Reyes
      DateTime(year, 1, 21), // Día de la Altagracia
      DateTime(year, 1, 26), // Día de Duarte
      DateTime(year, 2, 27), // Día de la Independencia
      // Viernes Santo - variable, calcular
      DateTime(year, 5, 1), // Día del Trabajo
      // Corpus Christi - variable, calcular
      DateTime(year, 8, 16), // Día de la Restauración
      DateTime(year, 9, 24), // Día de las Mercedes
      DateTime(year, 11, 6), // Día de la Constitución
      DateTime(year, 12, 25), // Navidad
    ];
  }

  static bool isHoliday(DateTime date) {
    final holidays = getHolidays(date.year);
    return holidays.any((holiday) =>
        holiday.year == date.year &&
        holiday.month == date.month &&
        holiday.day == date.day);
  }
}
