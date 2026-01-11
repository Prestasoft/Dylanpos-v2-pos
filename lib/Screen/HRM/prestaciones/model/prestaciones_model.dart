/// Modelo de Prestaciones Laborales según Código de Trabajo RD (Ley 16-92)
/// Incluye cálculo de cesantía, preaviso, vacaciones y regalía pascual
class PrestacionesLaboralesModel {
  final num id;
  final num employeeId;
  final String employeeName;
  final String employeeCedula;
  final String designation;
  final String department;
  final DateTime joiningDate;
  final DateTime terminationDate;
  final String terminationType; // Despido, Renuncia, Mutuo Acuerdo, Desahucio
  final double lastMonthlySalary;
  final double averageSalary; // Promedio últimos 6 meses si aplica
  final int monthsOfService;
  final int yearsOfService;

  // Componentes de prestaciones
  final double cesantia; // Auxilio de cesantía
  final double preaviso; // Indemnización por preaviso
  final double vacacionesPendientes; // Vacaciones no disfrutadas
  final double salarioPendiente; // Días de salario pendientes
  final double regaliaProporcional; // Regalía pascual proporcional
  final double bonificacionesAcumuladas; // Bonificaciones pendientes
  final double horasExtrasPendientes; // Horas extras no pagadas
  final double otrosConceptos; // Otros conceptos a pagar

  // Deducciones
  final double deduccionPrestamos; // Saldo de préstamos
  final double deduccionAdelantos; // Adelantos pendientes
  final double otrasDeduccciones; // Otras deducciones

  // Totales
  final double totalDevengado;
  final double totalDeducciones;
  final double totalNeto;

  // Estado y aprobación
  final String status; // Pendiente, Calculado, Aprobado, Pagado
  final DateTime calculationDate;
  final String? approvedBy;
  final DateTime? approvalDate;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? paymentReference;
  final String? notes;

  PrestacionesLaboralesModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCedula,
    required this.designation,
    required this.department,
    required this.joiningDate,
    required this.terminationDate,
    required this.terminationType,
    required this.lastMonthlySalary,
    required this.averageSalary,
    required this.monthsOfService,
    required this.yearsOfService,
    required this.cesantia,
    required this.preaviso,
    required this.vacacionesPendientes,
    required this.salarioPendiente,
    required this.regaliaProporcional,
    this.bonificacionesAcumuladas = 0,
    this.horasExtrasPendientes = 0,
    this.otrosConceptos = 0,
    this.deduccionPrestamos = 0,
    this.deduccionAdelantos = 0,
    this.otrasDeduccciones = 0,
    required this.totalDevengado,
    required this.totalDeducciones,
    required this.totalNeto,
    required this.status,
    required this.calculationDate,
    this.approvedBy,
    this.approvalDate,
    this.paymentDate,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
  });

  factory PrestacionesLaboralesModel.fromJson(Map<String, dynamic> json) {
    return PrestacionesLaboralesModel(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeCedula: json['employeeCedula'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'General',
      joiningDate: DateTime.parse(json['joiningDate']),
      terminationDate: DateTime.parse(json['terminationDate']),
      terminationType: json['terminationType'] ?? 'Renuncia',
      lastMonthlySalary: (json['lastMonthlySalary'] ?? 0).toDouble(),
      averageSalary: (json['averageSalary'] ?? 0).toDouble(),
      monthsOfService: json['monthsOfService'] ?? 0,
      yearsOfService: json['yearsOfService'] ?? 0,
      cesantia: (json['cesantia'] ?? 0).toDouble(),
      preaviso: (json['preaviso'] ?? 0).toDouble(),
      vacacionesPendientes: (json['vacacionesPendientes'] ?? 0).toDouble(),
      salarioPendiente: (json['salarioPendiente'] ?? 0).toDouble(),
      regaliaProporcional: (json['regaliaProporcional'] ?? 0).toDouble(),
      bonificacionesAcumuladas:
          (json['bonificacionesAcumuladas'] ?? 0).toDouble(),
      horasExtrasPendientes: (json['horasExtrasPendientes'] ?? 0).toDouble(),
      otrosConceptos: (json['otrosConceptos'] ?? 0).toDouble(),
      deduccionPrestamos: (json['deduccionPrestamos'] ?? 0).toDouble(),
      deduccionAdelantos: (json['deduccionAdelantos'] ?? 0).toDouble(),
      otrasDeduccciones: (json['otrasDeduccciones'] ?? 0).toDouble(),
      totalDevengado: (json['totalDevengado'] ?? 0).toDouble(),
      totalDeducciones: (json['totalDeducciones'] ?? 0).toDouble(),
      totalNeto: (json['totalNeto'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pendiente',
      calculationDate: json['calculationDate'] != null
          ? DateTime.parse(json['calculationDate'])
          : DateTime.now(),
      approvedBy: json['approvedBy'],
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'])
          : null,
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      paymentMethod: json['paymentMethod'],
      paymentReference: json['paymentReference'],
      notes: json['notes'],
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
      'joiningDate': joiningDate.toIso8601String(),
      'terminationDate': terminationDate.toIso8601String(),
      'terminationType': terminationType,
      'lastMonthlySalary': lastMonthlySalary,
      'averageSalary': averageSalary,
      'monthsOfService': monthsOfService,
      'yearsOfService': yearsOfService,
      'cesantia': cesantia,
      'preaviso': preaviso,
      'vacacionesPendientes': vacacionesPendientes,
      'salarioPendiente': salarioPendiente,
      'regaliaProporcional': regaliaProporcional,
      'bonificacionesAcumuladas': bonificacionesAcumuladas,
      'horasExtrasPendientes': horasExtrasPendientes,
      'otrosConceptos': otrosConceptos,
      'deduccionPrestamos': deduccionPrestamos,
      'deduccionAdelantos': deduccionAdelantos,
      'otrasDeduccciones': otrasDeduccciones,
      'totalDevengado': totalDevengado,
      'totalDeducciones': totalDeducciones,
      'totalNeto': totalNeto,
      'status': status,
      'calculationDate': calculationDate.toIso8601String(),
      'approvedBy': approvedBy,
      'approvalDate': approvalDate?.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'notes': notes,
    };
  }
}

/// Calculadora de Prestaciones Laborales según Ley 16-92
class PrestacionesCalculator {
  // Días laborables por mes según Código de Trabajo
  static const double diasLaborablesMes = 23.83;

  /// Calcular salario diario
  static double calcularSalarioDiario(double salarioMensual) {
    return salarioMensual / diasLaborablesMes;
  }

  /// Calcular auxilio de cesantía (Art. 80 Ley 16-92)
  /// Solo aplica para despido injustificado y desahucio
  static double calcularCesantia({
    required double salarioMensual,
    required int mesesServicio,
    required String tipoTerminacion,
  }) {
    // Solo aplica si es despido o desahucio del empleador
    if (tipoTerminacion != 'Despido' && tipoTerminacion != 'Desahucio') {
      return 0;
    }

    final salarioDiario = calcularSalarioDiario(salarioMensual);
    final anos = mesesServicio / 12;

    // Tabla de cesantía según Art. 80
    if (mesesServicio >= 3 && mesesServicio < 6) {
      return salarioDiario * 6; // 6 días de salario
    } else if (mesesServicio >= 6 && mesesServicio < 12) {
      return salarioDiario * 13; // 13 días de salario
    } else if (anos >= 1 && anos < 5) {
      return salarioDiario * 21 * anos; // 21 días por año
    } else if (anos >= 5) {
      return salarioDiario * 23 * anos; // 23 días por año (máximo 23)
    }

    return 0;
  }

  /// Calcular indemnización por preaviso omitido (Art. 76 Ley 16-92)
  static double calcularPreaviso({
    required double salarioMensual,
    required int mesesServicio,
    required String tipoTerminacion,
    required bool preavisoOmitido,
  }) {
    if (!preavisoOmitido) return 0;

    final salarioDiario = calcularSalarioDiario(salarioMensual);

    // Tabla de preaviso según tiempo de servicio
    if (mesesServicio >= 3 && mesesServicio < 6) {
      return salarioDiario * 7; // 7 días
    } else if (mesesServicio >= 6 && mesesServicio < 12) {
      return salarioDiario * 14; // 14 días
    } else if (mesesServicio >= 12) {
      return salarioDiario * 28; // 28 días
    }

    return 0;
  }

  /// Calcular vacaciones proporcionales (Art. 177 Ley 16-92)
  static double calcularVacacionesProporcionales({
    required double salarioMensual,
    required int mesesServicio,
    required int diasVacacionesTomados,
  }) {
    // 14 días de vacaciones por año después del primer año
    // Proporcional si no ha cumplido el año
    final salarioDiario = calcularSalarioDiario(salarioMensual);

    int diasVacacionesCorrespondientes;
    if (mesesServicio < 12) {
      // Proporcional al tiempo trabajado
      diasVacacionesCorrespondientes = ((mesesServicio / 12) * 14).round();
    } else {
      // Años completos
      final anos = mesesServicio ~/ 12;
      final mesesRestantes = mesesServicio % 12;
      diasVacacionesCorrespondientes =
          (anos * 14) + ((mesesRestantes / 12) * 14).round();
    }

    final diasPendientes = diasVacacionesCorrespondientes - diasVacacionesTomados;
    if (diasPendientes <= 0) return 0;

    return salarioDiario * diasPendientes;
  }

  /// Calcular regalía pascual proporcional (Art. 219 Ley 16-92)
  static double calcularRegaliaProporcional({
    required double salarioMensual,
    required int mesesTrabajadasEnAno,
  }) {
    // 1/12 del salario anual, proporcional a meses trabajados
    return (salarioMensual * mesesTrabajadasEnAno) / 12;
  }

  /// Calcular todas las prestaciones
  static PrestacionesResult calcularPrestacionesCompletas({
    required double salarioMensual,
    required DateTime fechaIngreso,
    required DateTime fechaTerminacion,
    required String tipoTerminacion,
    required bool preavisoOmitido,
    required int diasVacacionesTomados,
    double saldoPrestamos = 0,
    double saldoAdelantos = 0,
    double otrasDeduccciones = 0,
    double bonificacionesPendientes = 0,
    double horasExtrasPendientes = 0,
  }) {
    final diferencia = fechaTerminacion.difference(fechaIngreso);
    final mesesServicio = diferencia.inDays ~/ 30;
    final anosServicio = mesesServicio ~/ 12;

    // Meses trabajados en el año actual (para regalía proporcional)
    final mesActual = fechaTerminacion.month;

    // Calcular componentes
    final cesantia = calcularCesantia(
      salarioMensual: salarioMensual,
      mesesServicio: mesesServicio,
      tipoTerminacion: tipoTerminacion,
    );

    final preaviso = calcularPreaviso(
      salarioMensual: salarioMensual,
      mesesServicio: mesesServicio,
      tipoTerminacion: tipoTerminacion,
      preavisoOmitido: preavisoOmitido,
    );

    final vacaciones = calcularVacacionesProporcionales(
      salarioMensual: salarioMensual,
      mesesServicio: mesesServicio,
      diasVacacionesTomados: diasVacacionesTomados,
    );

    final regalia = calcularRegaliaProporcional(
      salarioMensual: salarioMensual,
      mesesTrabajadasEnAno: mesActual,
    );

    // Calcular días pendientes de salario
    final diasPendientes = fechaTerminacion.day;
    final salarioPendiente =
        calcularSalarioDiario(salarioMensual) * diasPendientes;

    // Totales
    final totalDevengado = cesantia +
        preaviso +
        vacaciones +
        salarioPendiente +
        regalia +
        bonificacionesPendientes +
        horasExtrasPendientes;

    final totalDeducciones =
        saldoPrestamos + saldoAdelantos + otrasDeduccciones;

    final totalNeto = totalDevengado - totalDeducciones;

    return PrestacionesResult(
      mesesServicio: mesesServicio,
      anosServicio: anosServicio,
      cesantia: cesantia,
      preaviso: preaviso,
      vacacionesPendientes: vacaciones,
      salarioPendiente: salarioPendiente,
      regaliaProporcional: regalia,
      bonificacionesPendientes: bonificacionesPendientes,
      horasExtrasPendientes: horasExtrasPendientes,
      totalDevengado: totalDevengado,
      totalDeducciones: totalDeducciones,
      totalNeto: totalNeto,
    );
  }
}

/// Resultado del cálculo de prestaciones
class PrestacionesResult {
  final int mesesServicio;
  final int anosServicio;
  final double cesantia;
  final double preaviso;
  final double vacacionesPendientes;
  final double salarioPendiente;
  final double regaliaProporcional;
  final double bonificacionesPendientes;
  final double horasExtrasPendientes;
  final double totalDevengado;
  final double totalDeducciones;
  final double totalNeto;

  PrestacionesResult({
    required this.mesesServicio,
    required this.anosServicio,
    required this.cesantia,
    required this.preaviso,
    required this.vacacionesPendientes,
    required this.salarioPendiente,
    required this.regaliaProporcional,
    required this.bonificacionesPendientes,
    required this.horasExtrasPendientes,
    required this.totalDevengado,
    required this.totalDeducciones,
    required this.totalNeto,
  });
}

/// Tipos de terminación laboral
class TerminationTypes {
  static const String despido = 'Despido';
  static const String renuncia = 'Renuncia';
  static const String mutuoAcuerdo = 'Mutuo Acuerdo';
  static const String desahucio = 'Desahucio';
  static const String finContrato = 'Fin de Contrato';
  static const String jubilacion = 'Jubilación';
  static const String fallecimiento = 'Fallecimiento';

  static List<String> get all => [
        despido,
        renuncia,
        mutuoAcuerdo,
        desahucio,
        finContrato,
        jubilacion,
        fallecimiento,
      ];

  /// Indica si aplica cesantía según tipo de terminación
  static bool apliciaCesantia(String tipo) {
    return tipo == despido || tipo == desahucio;
  }

  /// Indica si aplica preaviso según tipo de terminación
  static bool aplicaPreaviso(String tipo) {
    return tipo == despido || tipo == desahucio || tipo == renuncia;
  }
}
