/// Modelo de Nómina para República Dominicana
/// Incluye cálculos de AFP, SFS, SRL, ISR según TSS
class PaySalaryModel {
  final num id;
  final String employeeName;
  final String employeeCedula;
  final num employeeId;
  final num designationId;
  final String designation;
  final String department;

  // Período de pago
  final String year;
  final String month;
  final int? fortnight; // 1 o 2 para quincenas, null para mensual
  final DateTime payingDate;
  final DateTime periodStart;
  final DateTime periodEnd;

  // Ingresos
  final double grossSalary; // Salario bruto
  final double overtime; // Horas extras
  final double bonuses; // Bonificaciones
  final double commissions; // Comisiones
  final double otherIncome; // Otros ingresos
  final double totalIncome; // Total ingresos

  // Deducciones Seguridad Social (TSS)
  final double afpEmployee; // AFP empleado 2.87%
  final double sfsEmployee; // SFS empleado 3.04%
  final double totalTSS; // Total deducciones TSS

  // Aportes Patronales (para reportes)
  final double afpEmployer; // AFP patronal 7.10%
  final double sfsEmployer; // SFS patronal 7.09%
  final double srlEmployer; // SRL patronal 1.00% - 1.40%
  final double infotep; // INFOTEP 1%

  // ISR
  final double taxableIncome; // Ingreso gravable (después de TSS)
  final double isrWithholding; // Retención ISR
  final double isrMonthlyCredit; // Crédito mensual ISR si aplica

  // Otras deducciones
  final double loanDeduction; // Descuento préstamos
  final double advanceDeduction; // Adelantos de salario
  final double otherDeductions; // Otras deducciones
  final double cooperativeDeduction; // Aportes cooperativa

  // Totales
  final double totalDeductions; // Total deducciones
  final double netSalary; // Salario neto

  // Información de pago
  final String paymentType; // Transferencia, Cheque, Efectivo
  final String? paymentReference; // Número de transferencia/cheque
  final String status; // Pendiente, Pagado, Cancelado

  // Notas y observaciones
  final String? note;

  PaySalaryModel({
    required this.id,
    required this.employeeName,
    required this.employeeCedula,
    required this.employeeId,
    required this.designationId,
    required this.designation,
    required this.department,
    required this.year,
    required this.month,
    this.fortnight,
    required this.payingDate,
    required this.periodStart,
    required this.periodEnd,
    required this.grossSalary,
    this.overtime = 0,
    this.bonuses = 0,
    this.commissions = 0,
    this.otherIncome = 0,
    required this.totalIncome,
    required this.afpEmployee,
    required this.sfsEmployee,
    required this.totalTSS,
    required this.afpEmployer,
    required this.sfsEmployer,
    required this.srlEmployer,
    required this.infotep,
    required this.taxableIncome,
    required this.isrWithholding,
    this.isrMonthlyCredit = 0,
    this.loanDeduction = 0,
    this.advanceDeduction = 0,
    this.otherDeductions = 0,
    this.cooperativeDeduction = 0,
    required this.totalDeductions,
    required this.netSalary,
    required this.paymentType,
    this.paymentReference,
    required this.status,
    this.note,
  });

  factory PaySalaryModel.fromJson(Map<String, dynamic> json) {
    return PaySalaryModel(
      id: json['id'],
      employeeName: json['employeeName'],
      employeeCedula: json['employeeCedula'] ?? '',
      employeeId: json['employeeId'] ?? json['employmentId'],
      designationId: json['designationId'],
      designation: json['designation'],
      department: json['department'] ?? 'General',
      year: json['year'],
      month: json['month'],
      fortnight: json['fortnight'],
      payingDate: DateTime.parse(json['payingDate']),
      periodStart: json['periodStart'] != null
          ? DateTime.parse(json['periodStart'])
          : DateTime.now(),
      periodEnd: json['periodEnd'] != null
          ? DateTime.parse(json['periodEnd'])
          : DateTime.now(),
      grossSalary: (json['grossSalary'] ?? json['paySalary'] ?? 0).toDouble(),
      overtime: (json['overtime'] ?? 0).toDouble(),
      bonuses: (json['bonuses'] ?? 0).toDouble(),
      commissions: (json['commissions'] ?? 0).toDouble(),
      otherIncome: (json['otherIncome'] ?? 0).toDouble(),
      totalIncome: (json['totalIncome'] ?? json['paySalary'] ?? 0).toDouble(),
      afpEmployee: (json['afpEmployee'] ?? 0).toDouble(),
      sfsEmployee: (json['sfsEmployee'] ?? 0).toDouble(),
      totalTSS: (json['totalTSS'] ?? 0).toDouble(),
      afpEmployer: (json['afpEmployer'] ?? 0).toDouble(),
      sfsEmployer: (json['sfsEmployer'] ?? 0).toDouble(),
      srlEmployer: (json['srlEmployer'] ?? 0).toDouble(),
      infotep: (json['infotep'] ?? 0).toDouble(),
      taxableIncome: (json['taxableIncome'] ?? 0).toDouble(),
      isrWithholding: (json['isrWithholding'] ?? 0).toDouble(),
      isrMonthlyCredit: (json['isrMonthlyCredit'] ?? 0).toDouble(),
      loanDeduction: (json['loanDeduction'] ?? 0).toDouble(),
      advanceDeduction: (json['advanceDeduction'] ?? 0).toDouble(),
      otherDeductions: (json['otherDeductions'] ?? 0).toDouble(),
      cooperativeDeduction: (json['cooperativeDeduction'] ?? 0).toDouble(),
      totalDeductions: (json['totalDeductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      paymentType: json['paymentType'] ?? 'Transferencia',
      paymentReference: json['paymentReference'],
      status: json['status'] ?? 'Pendiente',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeName': employeeName,
      'employeeCedula': employeeCedula,
      'employeeId': employeeId,
      'designationId': designationId,
      'designation': designation,
      'department': department,
      'year': year,
      'month': month,
      'fortnight': fortnight,
      'payingDate': payingDate.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'grossSalary': grossSalary,
      'overtime': overtime,
      'bonuses': bonuses,
      'commissions': commissions,
      'otherIncome': otherIncome,
      'totalIncome': totalIncome,
      'afpEmployee': afpEmployee,
      'sfsEmployee': sfsEmployee,
      'totalTSS': totalTSS,
      'afpEmployer': afpEmployer,
      'sfsEmployer': sfsEmployer,
      'srlEmployer': srlEmployer,
      'infotep': infotep,
      'taxableIncome': taxableIncome,
      'isrWithholding': isrWithholding,
      'isrMonthlyCredit': isrMonthlyCredit,
      'loanDeduction': loanDeduction,
      'advanceDeduction': advanceDeduction,
      'otherDeductions': otherDeductions,
      'cooperativeDeduction': cooperativeDeduction,
      'totalDeductions': totalDeductions,
      'netSalary': netSalary,
      'paymentType': paymentType,
      'paymentReference': paymentReference,
      'status': status,
      'note': note,
    };
  }
}

/// Calculadora de Nómina para República Dominicana
/// Tasas actualizadas según TSS 2024
class PayrollCalculatorRD {
  // Tasas de AFP (Fondo de Pensiones)
  static const double afpEmployeeRate = 0.0287; // 2.87%
  static const double afpEmployerRate = 0.0710; // 7.10%

  // Tasas de SFS (Seguro Familiar de Salud)
  static const double sfsEmployeeRate = 0.0304; // 3.04%
  static const double sfsEmployerRate = 0.0709; // 7.09%

  // Tasa de SRL (Seguro de Riesgos Laborales) - varía según actividad
  static const double srlEmployerRateMin = 0.0100; // 1.00%
  static const double srlEmployerRateMax = 0.0140; // 1.40%
  static const double srlEmployerRateDefault = 0.0110; // 1.10% promedio

  // INFOTEP
  static const double infotepRate = 0.01; // 1%

  // Tope cotizable mensual (actualizar según TSS)
  static const double topeCotizableAFP = 472950.00; // 10 salarios mínimos sector privado no sectorizado
  static const double topeCotizableSFS = 472950.00; // Mismo tope

  // Salario mínimo (actualizar anualmente)
  static const double salarioMinimoNoSectorizado = 21000.00;
  static const double salarioMinimoSectorizado = 19250.00;
  static const double salarioMinimoMicroempresa = 12900.00;

  // Tabla ISR 2024 (mensual)
  static const List<ISRBracket> isrBrackets = [
    ISRBracket(from: 0, to: 34685, rate: 0, fixedAmount: 0),
    ISRBracket(from: 34685.01, to: 52027.42, rate: 0.15, fixedAmount: 0),
    ISRBracket(from: 52027.43, to: 72260.25, rate: 0.20, fixedAmount: 2601.37),
    ISRBracket(from: 72260.26, to: double.infinity, rate: 0.25, fixedAmount: 6647.93),
  ];

  /// Calcular deducciones de nómina
  static PayrollDeductions calculateDeductions({
    required double grossSalary,
    required double overtime,
    required double bonuses,
    required double commissions,
    required double otherIncome,
    double loanDeduction = 0,
    double advanceDeduction = 0,
    double otherDeductions = 0,
    double cooperativeDeduction = 0,
    double srlRate = srlEmployerRateDefault,
  }) {
    final totalIncome = grossSalary + overtime + bonuses + commissions + otherIncome;

    // Calcular base cotizable (con tope)
    final baseCotizableAFP = totalIncome > topeCotizableAFP ? topeCotizableAFP : totalIncome;
    final baseCotizableSFS = totalIncome > topeCotizableSFS ? topeCotizableSFS : totalIncome;

    // Calcular deducciones TSS empleado
    final afpEmployee = baseCotizableAFP * afpEmployeeRate;
    final sfsEmployee = baseCotizableSFS * sfsEmployeeRate;
    final totalTSS = afpEmployee + sfsEmployee;

    // Calcular aportes patronales
    final afpEmployer = baseCotizableAFP * afpEmployerRate;
    final sfsEmployer = baseCotizableSFS * sfsEmployerRate;
    final srlEmployer = totalIncome * srlRate;
    final infotep = totalIncome * infotepRate;

    // Calcular ISR
    final taxableIncome = totalIncome - totalTSS;
    final isrWithholding = calculateISR(taxableIncome);

    // Total deducciones
    final totalDeductions = totalTSS +
        isrWithholding +
        loanDeduction +
        advanceDeduction +
        otherDeductions +
        cooperativeDeduction;

    // Salario neto
    final netSalary = totalIncome - totalDeductions;

    return PayrollDeductions(
      totalIncome: totalIncome,
      afpEmployee: afpEmployee,
      sfsEmployee: sfsEmployee,
      totalTSS: totalTSS,
      afpEmployer: afpEmployer,
      sfsEmployer: sfsEmployer,
      srlEmployer: srlEmployer,
      infotep: infotep,
      taxableIncome: taxableIncome,
      isrWithholding: isrWithholding,
      loanDeduction: loanDeduction,
      advanceDeduction: advanceDeduction,
      otherDeductions: otherDeductions,
      cooperativeDeduction: cooperativeDeduction,
      totalDeductions: totalDeductions,
      netSalary: netSalary,
    );
  }

  /// Calcular ISR mensual según tabla 2024
  static double calculateISR(double taxableIncome) {
    for (final bracket in isrBrackets) {
      if (taxableIncome >= bracket.from && taxableIncome <= bracket.to) {
        if (bracket.rate == 0) return 0;
        final excess = taxableIncome - bracket.from;
        return bracket.fixedAmount + (excess * bracket.rate);
      }
    }
    return 0;
  }

  /// Calcular Regalía Pascual (Salario Navidad)
  /// 1/12 del salario anual, pagadero en diciembre
  static double calculateRegaliaPascual(double monthlySalary, int monthsWorked) {
    if (monthsWorked < 1) return 0;
    final monthsForCalculation = monthsWorked > 12 ? 12 : monthsWorked;
    return (monthlySalary * monthsForCalculation) / 12;
  }

  /// Calcular días de vacaciones según Ley 16-92
  /// 14 días laborables después de 1 año de trabajo
  static int calculateVacationDays(int monthsOfService) {
    if (monthsOfService < 12) return 0;
    final years = monthsOfService ~/ 12;
    // 14 días base + días adicionales según antigüedad
    if (years >= 5) return 18;
    if (years >= 1) return 14;
    return 0;
  }

  /// Calcular valor de vacaciones
  static double calculateVacationPay(double dailySalary, int vacationDays) {
    return dailySalary * vacationDays;
  }

  /// Calcular prestaciones laborales (cesantía)
  /// Según Ley 16-92 Arts. 80-86
  static double calculateSeverancePay({
    required double monthlySalary,
    required int monthsOfService,
    required String terminationType, // 'despido', 'renuncia', 'mutuo_acuerdo'
  }) {
    if (terminationType == 'despido') {
      // Auxilio de cesantía según años de servicio
      final years = monthsOfService / 12;
      double severance = 0;

      if (years >= 0 && years < 1) {
        severance = (monthlySalary / 23.83) * 6 * (monthsOfService / 12);
      } else if (years >= 1 && years < 5) {
        severance = (monthlySalary / 23.83) * 13 * years;
      } else if (years >= 5) {
        severance = (monthlySalary / 23.83) * 21 * years;
      }

      return severance;
    }
    return 0;
  }

  /// Calcular preaviso según Ley 16-92 Art. 76
  static double calculateNoticePay({
    required double monthlySalary,
    required int monthsOfService,
  }) {
    final dailySalary = monthlySalary / 23.83;

    if (monthsOfService >= 3 && monthsOfService < 6) {
      return dailySalary * 7; // 7 días
    } else if (monthsOfService >= 6 && monthsOfService < 12) {
      return dailySalary * 14; // 14 días
    } else if (monthsOfService >= 12) {
      return dailySalary * 28; // 28 días
    }
    return 0;
  }

  /// Calcular horas extras (35% adicional normal, 100% nocturno/feriado)
  static double calculateOvertime({
    required double hourlyRate,
    required double normalOvertimeHours,
    required double nightOvertimeHours,
  }) {
    final normalOvertime = hourlyRate * 1.35 * normalOvertimeHours;
    final nightOvertime = hourlyRate * 2.0 * nightOvertimeHours;
    return normalOvertime + nightOvertime;
  }
}

/// Tramo de ISR
class ISRBracket {
  final double from;
  final double to;
  final double rate;
  final double fixedAmount;

  const ISRBracket({
    required this.from,
    required this.to,
    required this.rate,
    required this.fixedAmount,
  });
}

/// Resultado del cálculo de deducciones
class PayrollDeductions {
  final double totalIncome;
  final double afpEmployee;
  final double sfsEmployee;
  final double totalTSS;
  final double afpEmployer;
  final double sfsEmployer;
  final double srlEmployer;
  final double infotep;
  final double taxableIncome;
  final double isrWithholding;
  final double loanDeduction;
  final double advanceDeduction;
  final double otherDeductions;
  final double cooperativeDeduction;
  final double totalDeductions;
  final double netSalary;

  PayrollDeductions({
    required this.totalIncome,
    required this.afpEmployee,
    required this.sfsEmployee,
    required this.totalTSS,
    required this.afpEmployer,
    required this.sfsEmployer,
    required this.srlEmployer,
    required this.infotep,
    required this.taxableIncome,
    required this.isrWithholding,
    required this.loanDeduction,
    required this.advanceDeduction,
    required this.otherDeductions,
    required this.cooperativeDeduction,
    required this.totalDeductions,
    required this.netSalary,
  });

  /// Costo total para el empleador
  double get totalEmployerCost =>
      totalIncome + afpEmployer + sfsEmployer + srlEmployer + infotep;
}
