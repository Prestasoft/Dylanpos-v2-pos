/// Modelo de Préstamos, Adelantos y Penalidades a Empleados
class EmployeeLoanModel {
  final num id;
  final num employeeId;
  final String employeeName;
  final String employeeCedula;
  final String designation;
  final String department;
  final String loanType; // Préstamo, Adelanto de Salario, Adelanto de Regalía, Penalidad
  final double amount; // Monto total del préstamo
  final double interestRate; // Tasa de interés (0 si no aplica)
  final int totalInstallments; // Número total de cuotas
  final int paidInstallments; // Cuotas pagadas
  final double installmentAmount; // Monto de cada cuota
  final double amountPaid; // Monto total pagado
  final double amountPending; // Monto pendiente
  final DateTime requestDate;
  final DateTime? approvalDate;
  final DateTime startDate; // Fecha inicio de descuentos
  final DateTime? endDate; // Fecha estimada de fin
  final String status; // Pendiente, Aprobado, Activo, Completado, Cancelado
  final String? approvedBy;
  final String? reason;
  final String? notes;
  final bool deductFromPayroll; // Si se descuenta automáticamente de nómina

  // Nuevos campos para frecuencia de pago
  final String paymentFrequency; // 'Mensual', 'Quincenal'

  // Campos para penalidades
  final bool isPenalty; // true = penalidad, false = préstamo/adelanto
  final String? penaltyType; // Tipo de penalidad
  final String? incidentDescription; // Descripción del incidente
  final DateTime? incidentDate; // Fecha del incidente
  final String? affectedItem; // Equipo/producto afectado
  final double? originalItemValue; // Valor original del equipo
  final double? penaltyPercentage; // Porcentaje cobrado (100, 75, 50, 25)

  EmployeeLoanModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCedula,
    required this.designation,
    required this.department,
    required this.loanType,
    required this.amount,
    this.interestRate = 0,
    required this.totalInstallments,
    this.paidInstallments = 0,
    required this.installmentAmount,
    this.amountPaid = 0,
    required this.amountPending,
    required this.requestDate,
    this.approvalDate,
    required this.startDate,
    this.endDate,
    required this.status,
    this.approvedBy,
    this.reason,
    this.notes,
    this.deductFromPayroll = true,
    this.paymentFrequency = 'Mensual',
    this.isPenalty = false,
    this.penaltyType,
    this.incidentDescription,
    this.incidentDate,
    this.affectedItem,
    this.originalItemValue,
    this.penaltyPercentage,
  });

  /// Calcular monto pendiente
  double calculatePending() {
    return amount - amountPaid;
  }

  /// Calcular cuotas restantes
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// Porcentaje de avance
  double get progressPercentage =>
      totalInstallments > 0 ? (paidInstallments / totalInstallments) * 100 : 0;

  /// Obtener texto de frecuencia
  String get frequencyText {
    switch (paymentFrequency) {
      case 'Quincenal':
        return 'Cuota Quincenal';
      case 'Mensual':
      default:
        return 'Cuota Mensual';
    }
  }

  factory EmployeeLoanModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLoanModel(
      id: json['id'],
      employeeId: json['employeeId'] ?? json['employee_id'],
      employeeName: json['employeeName'] ?? json['employee_name'] ?? '',
      employeeCedula: json['employeeCedula'] ?? json['employee_cedula'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'General',
      loanType: json['loanType'] ?? json['loan_type'] ?? 'Préstamo',
      amount: (json['amount'] ?? 0).toDouble(),
      interestRate: (json['interestRate'] ?? json['interest_rate'] ?? 0).toDouble(),
      totalInstallments: json['totalInstallments'] ?? json['total_installments'] ?? 1,
      paidInstallments: json['paidInstallments'] ?? json['paid_installments'] ?? 0,
      installmentAmount: (json['installmentAmount'] ?? json['installment_amount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? json['amount_paid'] ?? 0).toDouble(),
      amountPending: (json['amountPending'] ?? json['amount_pending'] ?? 0).toDouble(),
      requestDate: _parseDate(json['requestDate'] ?? json['request_date']) ?? DateTime.now(),
      approvalDate: _parseDate(json['approvalDate'] ?? json['approval_date']),
      startDate: _parseDate(json['startDate'] ?? json['start_date']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate'] ?? json['end_date']),
      status: json['status'] ?? 'Pendiente',
      approvedBy: json['approvedBy'] ?? json['approved_by'],
      reason: json['reason'],
      notes: json['notes'],
      deductFromPayroll: json['deductFromPayroll'] ?? json['deduct_from_payroll'] ?? true,
      paymentFrequency: json['paymentFrequency'] ?? json['payment_frequency'] ?? 'Mensual',
      isPenalty: json['isPenalty'] ?? json['is_penalty'] ?? false,
      penaltyType: json['penaltyType'] ?? json['penalty_type'],
      incidentDescription: json['incidentDescription'] ?? json['incident_description'],
      incidentDate: _parseDate(json['incidentDate'] ?? json['incident_date']),
      affectedItem: json['affectedItem'] ?? json['affected_item'],
      originalItemValue: (json['originalItemValue'] ?? json['original_item_value'])?.toDouble(),
      penaltyPercentage: (json['penaltyPercentage'] ?? json['penalty_percentage'])?.toDouble(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCedula': employeeCedula,
      'designation': designation,
      'department': department,
      'loanType': loanType,
      'amount': amount,
      'interestRate': interestRate,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'installmentAmount': installmentAmount,
      'amountPaid': amountPaid,
      'amountPending': amountPending,
      'requestDate': requestDate.toIso8601String(),
      'approvalDate': approvalDate?.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'approvedBy': approvedBy,
      'reason': reason,
      'notes': notes,
      'deductFromPayroll': deductFromPayroll,
      'paymentFrequency': paymentFrequency,
      'isPenalty': isPenalty,
      'penaltyType': penaltyType,
      'incidentDescription': incidentDescription,
      'incidentDate': incidentDate?.toIso8601String(),
      'affectedItem': affectedItem,
      'originalItemValue': originalItemValue,
      'penaltyPercentage': penaltyPercentage,
    };
  }

  /// Crear copia con modificaciones
  EmployeeLoanModel copyWith({
    num? id,
    num? employeeId,
    String? employeeName,
    String? employeeCedula,
    String? designation,
    String? department,
    String? loanType,
    double? amount,
    double? interestRate,
    int? totalInstallments,
    int? paidInstallments,
    double? installmentAmount,
    double? amountPaid,
    double? amountPending,
    DateTime? requestDate,
    DateTime? approvalDate,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? approvedBy,
    String? reason,
    String? notes,
    bool? deductFromPayroll,
    String? paymentFrequency,
    bool? isPenalty,
    String? penaltyType,
    String? incidentDescription,
    DateTime? incidentDate,
    String? affectedItem,
    double? originalItemValue,
    double? penaltyPercentage,
  }) {
    return EmployeeLoanModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCedula: employeeCedula ?? this.employeeCedula,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      loanType: loanType ?? this.loanType,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      amountPending: amountPending ?? this.amountPending,
      requestDate: requestDate ?? this.requestDate,
      approvalDate: approvalDate ?? this.approvalDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      deductFromPayroll: deductFromPayroll ?? this.deductFromPayroll,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      isPenalty: isPenalty ?? this.isPenalty,
      penaltyType: penaltyType ?? this.penaltyType,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      incidentDate: incidentDate ?? this.incidentDate,
      affectedItem: affectedItem ?? this.affectedItem,
      originalItemValue: originalItemValue ?? this.originalItemValue,
      penaltyPercentage: penaltyPercentage ?? this.penaltyPercentage,
    );
  }
}

/// Tipos de préstamos y adelantos
class LoanTypes {
  static const String prestamo = 'Préstamo';
  static const String adelantoSalario = 'Adelanto de Salario';
  static const String adelantoRegalia = 'Adelanto de Regalía';
  static const String prestamoEmergencia = 'Préstamo de Emergencia';
  static const String prestamoEducativo = 'Préstamo Educativo';

  static List<String> get all => [
        prestamo,
        adelantoSalario,
        adelantoRegalia,
        prestamoEmergencia,
        prestamoEducativo,
      ];
}

/// Tipos de penalidades
class PenaltyTypes {
  static const String danoEquipo = 'Daño a Equipo';
  static const String incumplimientoEntrega = 'Incumplimiento de Entrega';
  static const String faltanteCaja = 'Faltante de Caja';
  static const String perdidaInventario = 'Pérdida de Inventario';
  static const String incumplimientoMeta = 'Incumplimiento de Meta';
  static const String otroDescuento = 'Otro Descuento';

  static List<String> get all => [
        danoEquipo,
        incumplimientoEntrega,
        faltanteCaja,
        perdidaInventario,
        incumplimientoMeta,
        otroDescuento,
      ];

  /// Obtener icono para cada tipo de penalidad
  static String getIcon(String type) {
    switch (type) {
      case danoEquipo:
        return '🔧';
      case incumplimientoEntrega:
        return '📦';
      case faltanteCaja:
        return '💰';
      case perdidaInventario:
        return '📋';
      case incumplimientoMeta:
        return '🎯';
      case otroDescuento:
      default:
        return '📌';
    }
  }
}

/// Frecuencias de pago
class PaymentFrequency {
  static const String mensual = 'Mensual';
  static const String quincenal = 'Quincenal';

  static List<String> get all => [mensual, quincenal];

  /// Obtener número de pagos por año según frecuencia
  static int getPaymentsPerYear(String frequency) {
    switch (frequency) {
      case quincenal:
        return 24; // 2 pagos por mes
      case mensual:
      default:
        return 12;
    }
  }
}

/// Porcentajes de penalidad disponibles
class PenaltyPercentages {
  static const double percent100 = 100.0;
  static const double percent75 = 75.0;
  static const double percent50 = 50.0;
  static const double percent25 = 25.0;

  static List<double> get all => [percent100, percent75, percent50, percent25];

  static String getLabel(double percentage) {
    return '${percentage.toInt()}%';
  }
}

/// Estado de préstamos
class LoanStatus {
  static const String pendiente = 'Pendiente';
  static const String aprobado = 'Aprobado';
  static const String activo = 'Activo';
  static const String completado = 'Completado';
  static const String cancelado = 'Cancelado';
  static const String rechazado = 'Rechazado';

  static List<String> get all => [
        pendiente,
        aprobado,
        activo,
        completado,
        cancelado,
        rechazado,
      ];
}

/// Registro de pago de cuota
class LoanPaymentModel {
  final num id;
  final num loanId;
  final num employeeId;
  final int installmentNumber;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // Descuento Nómina, Efectivo, Transferencia
  final String? payrollPeriod; // Período de nómina si aplica
  final String? reference;
  final String? notes;

  LoanPaymentModel({
    required this.id,
    required this.loanId,
    required this.employeeId,
    required this.installmentNumber,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.payrollPeriod,
    this.reference,
    this.notes,
  });

  factory LoanPaymentModel.fromJson(Map<String, dynamic> json) {
    return LoanPaymentModel(
      id: json['id'],
      loanId: json['loanId'] ?? json['loan_id'],
      employeeId: json['employeeId'] ?? json['employee_id'],
      installmentNumber: json['installmentNumber'] ?? json['installment_number'] ?? 1,
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] ?? json['payment_date']),
      paymentMethod: json['paymentMethod'] ?? json['payment_method'] ?? 'Descuento Nómina',
      payrollPeriod: json['payrollPeriod'] ?? json['payroll_period'],
      reference: json['reference'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'employeeId': employeeId,
      'installmentNumber': installmentNumber,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'payrollPeriod': payrollPeriod,
      'reference': reference,
      'notes': notes,
    };
  }
}
