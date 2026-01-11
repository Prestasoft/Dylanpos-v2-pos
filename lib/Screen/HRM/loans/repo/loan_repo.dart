import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/loans/model/loan_model.dart';

import '../../../../services/api_service.dart';

/// Repositorio de préstamos de empleados - Usa PostgreSQL API
class LoanRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los préstamos desde PostgreSQL
  Future<List<EmployeeLoanModel>> getAllLoans() async {
    List<EmployeeLoanModel> loans = [];

    try {
      final response = await _apiService.get('employee-loans', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final loansData = response.data['employee_loans'] as List<dynamic>? ?? [];

        for (var element in loansData) {
          final data = Map<String, dynamic>.from(element as Map);
          data['id'] = data['id'] ?? data['loan_id'];
          loans.add(EmployeeLoanModel.fromJson(data));
        }
      }
    } catch (e) {
      // Error silencioso
    }

    return loans;
  }

  /// Obtener préstamos por empleado
  Future<List<EmployeeLoanModel>> getLoansByEmployee(num employeeId) async {
    final all = await getAllLoans();
    return all.where((l) => l.employeeId == employeeId).toList();
  }

  /// Obtener préstamos activos
  Future<List<EmployeeLoanModel>> getActiveLoans() async {
    final all = await getAllLoans();
    return all.where((l) => l.status == LoanStatus.activo).toList();
  }

  /// Obtener préstamos pendientes de aprobación
  Future<List<EmployeeLoanModel>> getPendingLoans() async {
    final all = await getAllLoans();
    return all.where((l) => l.status == LoanStatus.pendiente).toList();
  }

  /// Obtener préstamos activos de un empleado
  Future<List<EmployeeLoanModel>> getActiveLoansForEmployee(num employeeId) async {
    final all = await getLoansByEmployee(employeeId);
    return all.where((l) => l.status == LoanStatus.activo).toList();
  }

  /// Crear solicitud de préstamo
  Future<bool> createLoanRequest({required EmployeeLoanModel loan}) async {
    try {
      EasyLoading.show(status: 'Guardando solicitud...', dismissOnTap: false);

      final loanData = Map<String, dynamic>.from(loan.toJson());
      final response = await _apiService.post('employee-loans', loanData);

      if (response.success) {
        EasyLoading.showSuccess('Solicitud creada exitosamente');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al crear solicitud');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Aprobar préstamo
  Future<bool> approveLoan({
    required num loanId,
    required String approvedBy,
  }) async {
    try {
      EasyLoading.show(status: 'Aprobando...', dismissOnTap: false);

      final response = await _apiService.put('employee-loans/$loanId', {
        'status': LoanStatus.activo,
        'approvedBy': approvedBy,
        'approvalDate': DateTime.now().toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Préstamo aprobado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al aprobar préstamo');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Rechazar préstamo
  Future<bool> rejectLoan({
    required num loanId,
    required String rejectedBy,
    String? reason,
  }) async {
    try {
      EasyLoading.show(status: 'Procesando...', dismissOnTap: false);

      final response = await _apiService.put('employee-loans/$loanId', {
        'status': LoanStatus.rechazado,
        'approvedBy': rejectedBy,
        'approvalDate': DateTime.now().toIso8601String(),
        'notes': reason,
      });

      if (response.success) {
        EasyLoading.showSuccess('Préstamo rechazado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al rechazar préstamo');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Registrar pago de cuota
  Future<bool> registerPayment({
    required EmployeeLoanModel loan,
    required double paymentAmount,
    required String paymentMethod,
    String? payrollPeriod,
    String? reference,
    String? notes,
  }) async {
    try {
      EasyLoading.show(status: 'Registrando pago...', dismissOnTap: false);

      // Crear registro de pago
      final paymentId = DateTime.now().millisecondsSinceEpoch;
      final payment = LoanPaymentModel(
        id: paymentId,
        loanId: loan.id,
        employeeId: loan.employeeId,
        installmentNumber: loan.paidInstallments + 1,
        amount: paymentAmount,
        paymentDate: DateTime.now(),
        paymentMethod: paymentMethod,
        payrollPeriod: payrollPeriod,
        reference: reference,
        notes: notes,
      );

      // Guardar pago
      final paymentData = Map<String, dynamic>.from(payment.toJson());
      final paymentResponse = await _apiService.post('loan-payments', paymentData);

      if (!paymentResponse.success) {
        EasyLoading.showError(paymentResponse.message ?? 'Error al registrar pago');
        return false;
      }

      // Actualizar préstamo
      final newPaidInstallments = loan.paidInstallments + 1;
      final newAmountPaid = loan.amountPaid + paymentAmount;
      final newAmountPending = loan.amount - newAmountPaid;
      final newStatus = newPaidInstallments >= loan.totalInstallments
          ? LoanStatus.completado
          : LoanStatus.activo;

      final loanUpdateData = {
        'paidInstallments': newPaidInstallments,
        'amountPaid': newAmountPaid,
        'amountPending': newAmountPending,
        'status': newStatus,
      };

      if (newStatus == LoanStatus.completado) {
        loanUpdateData['endDate'] = DateTime.now().toIso8601String();
      }

      final loanResponse = await _apiService.put('employee-loans/${loan.id}', loanUpdateData);

      if (loanResponse.success) {
        EasyLoading.showSuccess('Pago registrado exitosamente');
        return true;
      }

      EasyLoading.showError(loanResponse.message ?? 'Error al actualizar préstamo');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Obtener historial de pagos de un préstamo
  Future<List<LoanPaymentModel>> getLoanPayments(num loanId) async {
    List<LoanPaymentModel> payments = [];

    try {
      final response = await _apiService.get('loan-payments', queryParams: {
        'loan_id': loanId.toString(),
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final paymentsData = response.data['loan_payments'] as List<dynamic>? ?? [];

        for (var element in paymentsData) {
          final data = Map<String, dynamic>.from(element as Map);
          data['id'] = data['id'] ?? data['payment_id'];
          payments.add(LoanPaymentModel.fromJson(data));
        }

        payments.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
      }
    } catch (e) {
      // Error silencioso
    }

    return payments;
  }

  /// Cancelar préstamo
  Future<bool> cancelLoan({required num loanId, String? reason}) async {
    try {
      EasyLoading.show(status: 'Cancelando...', dismissOnTap: false);

      final response = await _apiService.put('employee-loans/$loanId', {
        'status': LoanStatus.cancelado,
        'notes': reason,
        'endDate': DateTime.now().toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Préstamo cancelado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al cancelar préstamo');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Eliminar préstamo
  Future<bool> deleteLoan({required num loanId}) async {
    try {
      EasyLoading.show(status: 'Eliminando...', dismissOnTap: false);

      final response = await _apiService.delete('employee-loans/$loanId');

      if (response.success) {
        EasyLoading.showSuccess('Préstamo eliminado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al eliminar préstamo');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Obtener total de deuda por empleado
  Future<double> getTotalDebtByEmployee(num employeeId) async {
    final activeLoans = await getActiveLoansForEmployee(employeeId);
    double total = 0.0;
    for (var loan in activeLoans) {
      total += loan.amountPending;
    }
    return total;
  }

  /// Obtener cuotas pendientes para próxima nómina
  Future<List<Map<String, dynamic>>> getPendingInstallmentsForPayroll() async {
    List<Map<String, dynamic>> installments = [];

    try {
      final activeLoans = await getActiveLoans();

      for (var loan in activeLoans) {
        if (loan.deductFromPayroll && loan.remainingInstallments > 0) {
          installments.add({
            'loan': loan,
            'installmentAmount': loan.installmentAmount,
            'installmentNumber': loan.paidInstallments + 1,
          });
        }
      }
    } catch (e) {
      // Error silencioso
    }

    return installments;
  }

  /// Calcular cuota mensual (con o sin interés)
  static double calculateInstallment({
    required double amount,
    required int installments,
    double interestRate = 0,
  }) {
    if (interestRate == 0) {
      return amount / installments;
    }

    // Fórmula de cuota fija con interés
    final monthlyRate = interestRate / 12 / 100;
    final factor = (monthlyRate * pow(1 + monthlyRate, installments)) /
        (pow(1 + monthlyRate, installments) - 1);
    return amount * factor;
  }

  /// Función auxiliar para potencia
  static double pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  /// Obtener resumen de préstamos
  Future<Map<String, dynamic>> getLoansSummary() async {
    final allLoans = await getAllLoans();
    final activeLoans = allLoans.where((l) => l.status == LoanStatus.activo).toList();
    final pendingLoans = allLoans.where((l) => l.status == LoanStatus.pendiente).toList();
    final completedLoans = allLoans.where((l) => l.status == LoanStatus.completado).toList();

    double totalActiveAmount = 0.0;
    double totalPendingAmount = 0.0;
    double totalPaidAmount = 0.0;

    for (var l in activeLoans) {
      totalActiveAmount += l.amount;
      totalPendingAmount += l.amountPending;
      totalPaidAmount += l.amountPaid;
    }

    return {
      'totalLoans': allLoans.length,
      'activeLoans': activeLoans.length,
      'pendingApproval': pendingLoans.length,
      'completedLoans': completedLoans.length,
      'totalActiveAmount': totalActiveAmount,
      'totalPendingAmount': totalPendingAmount,
      'totalPaidAmount': totalPaidAmount,
    };
  }
}
