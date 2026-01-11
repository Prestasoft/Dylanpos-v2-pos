/// Modelo de Préstamos y Adelantos a Empleados
class EmployeeLoanModel {
  final num id;
  final num employeeId;
  final String employeeName;
  final String employeeCedula;
  final String designation;
  final String department;
  final String loanType; // Préstamo, Adelanto de Salario, Adelanto de Regalía
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

  factory EmployeeLoanModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLoanModel(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeCedula: json['employeeCedula'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'General',
      loanType: json['loanType'] ?? 'Préstamo',
      amount: (json['amount'] ?? 0).toDouble(),
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      totalInstallments: json['totalInstallments'] ?? 1,
      paidInstallments: json['paidInstallments'] ?? 0,
      installmentAmount: (json['installmentAmount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      amountPending: (json['amountPending'] ?? 0).toDouble(),
      requestDate: DateTime.parse(json['requestDate']),
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'])
          : null,
      startDate: DateTime.parse(json['startDate']),
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? 'Pendiente',
      approvedBy: json['approvedBy'],
      reason: json['reason'],
      notes: json['notes'],
      deductFromPayroll: json['deductFromPayroll'] ?? true,
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
    };
  }
}

/// Tipos de préstamos
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
      loanId: json['loanId'],
      employeeId: json['employeeId'],
      installmentNumber: json['installmentNumber'] ?? 1,
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentMethod: json['paymentMethod'] ?? 'Descuento Nómina',
      payrollPeriod: json['payrollPeriod'],
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
