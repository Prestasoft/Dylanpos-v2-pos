import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../../../model/daily_transaction_model.dart';
import '../../../../services/api_service.dart';
import '../../../Widgets/Constant Data/constant.dart';

/// Repositorio de nómina/salarios - Usa PostgreSQL API
class SalaryRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los registros de nómina desde PostgreSQL
  Future<List<PaySalaryModel>> getAllPaidSalary() async {
    List<PaySalaryModel> salaries = [];

    try {
      final response = await _apiService.get('paid-salaries', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final salariesData = response.data['paid_salaries'] as List<dynamic>? ?? [];

        for (var element in salariesData) {
          final data = Map<String, dynamic>.from(element as Map);
          data['id'] = data['id'] ?? data['salary_id'];
          salaries.add(PaySalaryModel.fromJson(data));
        }
      }
    } catch (e) {
      // Error silencioso
    }

    return salaries;
  }

  /// Obtener nóminas por período (año y mes)
  Future<List<PaySalaryModel>> getSalariesByPeriod(String year, String month) async {
    final all = await getAllPaidSalary();
    return all.where((s) => s.year == year && s.month == month).toList();
  }

  /// Obtener nóminas por empleado
  Future<List<PaySalaryModel>> getSalariesByEmployee(num employeeId) async {
    final all = await getAllPaidSalary();
    return all.where((s) => s.employeeId == employeeId).toList();
  }

  /// Obtener última nómina de un empleado
  Future<PaySalaryModel?> getLastSalaryByEmployee(num employeeId) async {
    final salaries = await getSalariesByEmployee(employeeId);
    if (salaries.isEmpty) return null;
    salaries.sort((a, b) => b.payingDate.compareTo(a.payingDate));
    return salaries.first;
  }

  /// Guardar registro de nómina con transacción diaria
  Future<bool> paySalary({required PaySalaryModel salary}) async {
    try {
      EasyLoading.show(status: 'Guardando nómina...', dismissOnTap: false);

      final salaryData = salary.toJson();
      final response = await _apiService.post('paid-salaries', salaryData);

      if (response.success) {
        // Registrar transacción diaria
        DailyTransactionModel dailyTransaction = DailyTransactionModel(
          name: salary.employeeName,
          date: salary.payingDate.toString(),
          type: 'Pago Nómina',
          total: salary.netSalary,
          paymentIn: 0,
          paymentOut: salary.netSalary,
          remainingBalance: 0,
          id: salary.id.toString(),
          paySalary: salary,
        );
        await postDailyTransaction(dailyTransactionModel: dailyTransaction);

        EasyLoading.showSuccess('Nómina pagada exitosamente');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al pagar nómina');
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Error al pagar nómina: ${e.toString()}');
    }
  }

  /// Actualizar registro de nómina
  Future<bool> updateSalary({required PaySalaryModel salary}) async {
    try {
      EasyLoading.show(status: 'Actualizando...', dismissOnTap: false);

      final salaryData = salary.toJson();
      final response = await _apiService.put('paid-salaries/${salary.id}', salaryData);

      if (response.success) {
        EasyLoading.showSuccess('Nómina actualizada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al actualizar nómina');
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Error al actualizar nómina: ${e.toString()}');
    }
  }

  /// Eliminar registro de nómina
  Future<bool> deletePaidSalary({required num id}) async {
    try {
      EasyLoading.show(status: 'Eliminando...');

      final response = await _apiService.delete('paid-salaries/$id');

      if (response.success) {
        EasyLoading.showSuccess('Registro eliminado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al eliminar registro');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Generar nómina para todos los empleados activos
  Future<List<PaySalaryModel>> generatePayrollForPeriod({
    required String year,
    required String month,
    int? fortnight,
    required DateTime payingDate,
  }) async {
    List<PaySalaryModel> generatedPayroll = [];

    try {
      EasyLoading.show(status: 'Generando nómina...', dismissOnTap: false);

      // Obtener empleados activos
      final employees = await EmployeeRepository().getActiveEmployees();

      // Calcular período
      final monthNum = int.parse(month);
      final yearNum = int.parse(year);
      DateTime periodStart;
      DateTime periodEnd;

      if (fortnight != null) {
        if (fortnight == 1) {
          periodStart = DateTime(yearNum, monthNum, 1);
          periodEnd = DateTime(yearNum, monthNum, 15);
        } else {
          periodStart = DateTime(yearNum, monthNum, 16);
          periodEnd = DateTime(yearNum, monthNum + 1, 0);
        }
      } else {
        periodStart = DateTime(yearNum, monthNum, 1);
        periodEnd = DateTime(yearNum, monthNum + 1, 0);
      }

      for (var employee in employees) {
        // Calcular salario proporcional si es quincenal
        double grossSalary = employee.salary;
        if (fortnight != null) {
          grossSalary = employee.salary / 2;
        }

        // Calcular deducciones
        final deductions = PayrollCalculatorRD.calculateDeductions(
          grossSalary: grossSalary,
          overtime: 0,
          bonuses: 0,
          commissions: 0,
          otherIncome: 0,
        );

        final payrollId = DateTime.now().millisecondsSinceEpoch + employee.id.toInt();

        final payroll = PaySalaryModel(
          id: payrollId,
          employeeName: employee.fullName,
          employeeCedula: employee.cedula,
          employeeId: employee.id,
          designationId: employee.designationId,
          designation: employee.designation,
          department: employee.department,
          year: year,
          month: month,
          fortnight: fortnight,
          payingDate: payingDate,
          periodStart: periodStart,
          periodEnd: periodEnd,
          grossSalary: grossSalary,
          totalIncome: deductions.totalIncome,
          afpEmployee: deductions.afpEmployee,
          sfsEmployee: deductions.sfsEmployee,
          totalTSS: deductions.totalTSS,
          afpEmployer: deductions.afpEmployer,
          sfsEmployer: deductions.sfsEmployer,
          srlEmployer: deductions.srlEmployer,
          infotep: deductions.infotep,
          taxableIncome: deductions.taxableIncome,
          isrWithholding: deductions.isrWithholding,
          totalDeductions: deductions.totalDeductions,
          netSalary: deductions.netSalary,
          paymentType: employee.paymentMethod,
          status: 'Pendiente',
        );

        generatedPayroll.add(payroll);
      }

      EasyLoading.showSuccess('Nómina generada: ${generatedPayroll.length} empleados');
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
    }

    return generatedPayroll;
  }

  /// Guardar nómina completa (múltiples registros)
  Future<bool> savePayrollBatch(List<PaySalaryModel> payrollList) async {
    try {
      EasyLoading.show(status: 'Guardando nómina...', dismissOnTap: false);

      for (var payroll in payrollList) {
        final salaryData = payroll.toJson();
        await _apiService.post('paid-salaries', salaryData);
      }

      EasyLoading.showSuccess('Nómina guardada: ${payrollList.length} registros');
      return true;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Obtener resumen de nómina por período
  Future<PayrollSummary> getPayrollSummary(String year, String month) async {
    final payroll = await getSalariesByPeriod(year, month);

    double totalGross = 0;
    double totalNet = 0;
    double totalAFPEmployee = 0;
    double totalSFSEmployee = 0;
    double totalISR = 0;
    double totalAFPEmployer = 0;
    double totalSFSEmployer = 0;
    double totalSRL = 0;
    double totalINFOTEP = 0;

    for (var p in payroll) {
      totalGross += p.grossSalary;
      totalNet += p.netSalary;
      totalAFPEmployee += p.afpEmployee;
      totalSFSEmployee += p.sfsEmployee;
      totalISR += p.isrWithholding;
      totalAFPEmployer += p.afpEmployer;
      totalSFSEmployer += p.sfsEmployer;
      totalSRL += p.srlEmployer;
      totalINFOTEP += p.infotep;
    }

    return PayrollSummary(
      year: year,
      month: month,
      employeeCount: payroll.length,
      totalGrossSalary: totalGross,
      totalNetSalary: totalNet,
      totalAFPEmployee: totalAFPEmployee,
      totalSFSEmployee: totalSFSEmployee,
      totalISR: totalISR,
      totalAFPEmployer: totalAFPEmployer,
      totalSFSEmployer: totalSFSEmployer,
      totalSRL: totalSRL,
      totalINFOTEP: totalINFOTEP,
    );
  }
}

/// Resumen de nómina
class PayrollSummary {
  final String year;
  final String month;
  final int employeeCount;
  final double totalGrossSalary;
  final double totalNetSalary;
  final double totalAFPEmployee;
  final double totalSFSEmployee;
  final double totalISR;
  final double totalAFPEmployer;
  final double totalSFSEmployer;
  final double totalSRL;
  final double totalINFOTEP;

  PayrollSummary({
    required this.year,
    required this.month,
    required this.employeeCount,
    required this.totalGrossSalary,
    required this.totalNetSalary,
    required this.totalAFPEmployee,
    required this.totalSFSEmployee,
    required this.totalISR,
    required this.totalAFPEmployer,
    required this.totalSFSEmployer,
    required this.totalSRL,
    required this.totalINFOTEP,
  });

  /// Total deducciones TSS (empleado)
  double get totalTSSEmployee => totalAFPEmployee + totalSFSEmployee;

  /// Total aportes patronales
  double get totalEmployerContributions =>
      totalAFPEmployer + totalSFSEmployer + totalSRL + totalINFOTEP;

  /// Costo total de nómina para el empleador
  double get totalPayrollCost => totalGrossSalary + totalEmployerContributions;

  /// Total a pagar a TSS
  double get totalTSSPayment =>
      totalAFPEmployee + totalAFPEmployer + totalSFSEmployee + totalSFSEmployer + totalSRL;
}
