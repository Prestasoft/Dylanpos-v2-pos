import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/prestaciones/model/prestaciones_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/loans/repo/loan_repo.dart';

import '../../../../services/api_service.dart';

/// Repositorio de prestaciones laborales - Usa PostgreSQL API
class PrestacionesRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todas las liquidaciones desde PostgreSQL
  Future<List<PrestacionesLaboralesModel>> getAllPrestaciones() async {
    List<PrestacionesLaboralesModel> prestaciones = [];

    try {
      final response = await _apiService.get('prestaciones', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final prestacionesData = response.data['prestaciones'] as List<dynamic>? ?? [];

        for (var element in prestacionesData) {
          final data = Map<String, dynamic>.from(element as Map);
          data['id'] = data['id'] ?? data['prestaciones_id'];
          prestaciones.add(PrestacionesLaboralesModel.fromJson(data));
        }
      }
    } catch (e) {
      // Error silencioso
    }

    return prestaciones;
  }

  /// Obtener liquidación por empleado
  Future<PrestacionesLaboralesModel?> getPrestacionesByEmployee(
      num employeeId) async {
    final all = await getAllPrestaciones();
    return all.where((p) => p.employeeId == employeeId).firstOrNull;
  }

  /// Obtener liquidaciones por estado
  Future<List<PrestacionesLaboralesModel>> getPrestacionesByStatus(
      String status) async {
    final all = await getAllPrestaciones();
    return all.where((p) => p.status == status).toList();
  }

  /// Calcular prestaciones para un empleado
  Future<PrestacionesLaboralesModel> calcularPrestaciones({
    required EmployeeModel employee,
    required DateTime fechaTerminacion,
    required String tipoTerminacion,
    required bool preavisoOmitido,
    int diasVacacionesTomados = 0,
    double bonificacionesPendientes = 0,
    double horasExtrasPendientes = 0,
    double otrasDeduccciones = 0,
    String? notes,
  }) async {
    // Obtener saldo de préstamos
    final loanRepo = LoanRepository();
    final saldoPrestamos = await loanRepo.getTotalDebtByEmployee(employee.id);

    // Calcular prestaciones
    final result = PrestacionesCalculator.calcularPrestacionesCompletas(
      salarioMensual: employee.salary,
      fechaIngreso: employee.joiningDate,
      fechaTerminacion: fechaTerminacion,
      tipoTerminacion: tipoTerminacion,
      preavisoOmitido: preavisoOmitido,
      diasVacacionesTomados: diasVacacionesTomados,
      saldoPrestamos: saldoPrestamos,
      bonificacionesPendientes: bonificacionesPendientes,
      horasExtrasPendientes: horasExtrasPendientes,
      otrasDeduccciones: otrasDeduccciones,
    );

    return PrestacionesLaboralesModel(
      id: DateTime.now().millisecondsSinceEpoch,
      employeeId: employee.id,
      employeeName: employee.fullName,
      employeeCedula: employee.cedula,
      designation: employee.designation,
      department: employee.department,
      joiningDate: employee.joiningDate,
      terminationDate: fechaTerminacion,
      terminationType: tipoTerminacion,
      lastMonthlySalary: employee.salary,
      averageSalary: employee.salary, // Simplificado
      monthsOfService: result.mesesServicio,
      yearsOfService: result.anosServicio,
      cesantia: result.cesantia,
      preaviso: result.preaviso,
      vacacionesPendientes: result.vacacionesPendientes,
      salarioPendiente: result.salarioPendiente,
      regaliaProporcional: result.regaliaProporcional,
      bonificacionesAcumuladas: bonificacionesPendientes,
      horasExtrasPendientes: horasExtrasPendientes,
      deduccionPrestamos: saldoPrestamos,
      otrasDeduccciones: otrasDeduccciones,
      totalDevengado: result.totalDevengado,
      totalDeducciones: result.totalDeducciones,
      totalNeto: result.totalNeto,
      status: 'Calculado',
      calculationDate: DateTime.now(),
      notes: notes,
    );
  }

  /// Guardar liquidación
  Future<bool> savePrestaciones(
      {required PrestacionesLaboralesModel prestaciones}) async {
    try {
      EasyLoading.show(status: 'Guardando...', dismissOnTap: false);

      final prestacionesData = Map<String, dynamic>.from(prestaciones.toJson());
      final response = await _apiService.post('prestaciones', prestacionesData);

      if (response.success) {
        EasyLoading.showSuccess('Liquidación guardada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al guardar liquidación');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Aprobar liquidación
  Future<bool> approvePrestaciones({
    required num prestacionesId,
    required String approvedBy,
  }) async {
    try {
      EasyLoading.show(status: 'Aprobando...', dismissOnTap: false);

      final response = await _apiService.put('prestaciones/$prestacionesId', {
        'status': 'Aprobado',
        'approvedBy': approvedBy,
        'approvalDate': DateTime.now().toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Liquidación aprobada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al aprobar liquidación');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Marcar como pagada
  Future<bool> markAsPaid({
    required num prestacionesId,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    try {
      EasyLoading.show(status: 'Procesando...', dismissOnTap: false);

      final response = await _apiService.put('prestaciones/$prestacionesId', {
        'status': 'Pagado',
        'paymentDate': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
      });

      if (response.success) {
        EasyLoading.showSuccess('Pago registrado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al registrar pago');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Eliminar liquidación
  Future<bool> deletePrestaciones({required num prestacionesId}) async {
    try {
      EasyLoading.show(status: 'Eliminando...', dismissOnTap: false);

      final response = await _apiService.delete('prestaciones/$prestacionesId');

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

  /// Obtener resumen de liquidaciones
  Future<Map<String, dynamic>> getPrestacionesSummary() async {
    final all = await getAllPrestaciones();

    int total = all.length;
    int pending = all.where((p) => p.status == 'Calculado').length;
    int approved = all.where((p) => p.status == 'Aprobado').length;
    int paid = all.where((p) => p.status == 'Pagado').length;

    double totalAmount = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;

    for (var p in all) {
      totalAmount += p.totalNeto;
      if (p.status == 'Pagado') {
        totalPaid += p.totalNeto;
      } else {
        totalPending += p.totalNeto;
      }
    }

    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'paid': paid,
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
    };
  }
}
