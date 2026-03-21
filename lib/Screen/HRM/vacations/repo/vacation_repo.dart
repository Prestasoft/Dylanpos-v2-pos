import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/vacations/model/vacation_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../../../services/api_service.dart';

/// Repositorio de vacaciones y licencias - Usa PostgreSQL API
class VacationRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todas las solicitudes de vacaciones/licencias desde PostgreSQL
  Future<List<VacationModel>> getAllVacations() async {
    List<VacationModel> vacations = [];

    try {
      final response = await _apiService.get('vacations', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final vacationsData = response.data['vacations'] as List<dynamic>? ?? [];

        for (var element in vacationsData) {
          final data = Map<String, dynamic>.from(element as Map);
          data['id'] = data['id'] ?? data['vacation_id'];
          vacations.add(VacationModel.fromJson(data));
        }
      }
    } catch (e) {
      // Error silencioso
    }

    return vacations;
  }

  /// Obtener vacaciones por empleado
  Future<List<VacationModel>> getVacationsByEmployee(num employeeId) async {
    final all = await getAllVacations();
    return all.where((v) => v.employeeId == employeeId).toList();
  }

  /// Obtener vacaciones por estado
  Future<List<VacationModel>> getVacationsByStatus(String status) async {
    final all = await getAllVacations();
    return all.where((v) => v.status == status).toList();
  }

  /// Obtener vacaciones pendientes de aprobación
  Future<List<VacationModel>> getPendingVacations() async {
    return getVacationsByStatus('Pendiente');
  }

  /// Obtener vacaciones en un rango de fechas
  Future<List<VacationModel>> getVacationsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final all = await getAllVacations();
    return all.where((v) =>
        (v.startDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            v.startDate.isBefore(endDate.add(const Duration(days: 1)))) ||
        (v.endDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            v.endDate.isBefore(endDate.add(const Duration(days: 1))))).toList();
  }

  /// Crear solicitud de vacaciones/licencia
  Future<bool> createVacationRequest({required VacationModel vacation}) async {
    try {
      EasyLoading.show(status: 'Guardando solicitud...', dismissOnTap: false);

      final vacationData = Map<String, dynamic>.from(vacation.toJson());
      final response = await _apiService.post('vacations', vacationData);

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

  /// Aprobar solicitud de vacaciones
  Future<bool> approveVacation({
    required num vacationId,
    required String approvedBy,
    required int daysApproved,
  }) async {
    try {
      EasyLoading.show(status: 'Aprobando...', dismissOnTap: false);

      final response = await _apiService.put('vacations/$vacationId', {
        'status': 'Aprobado',
        'daysApproved': daysApproved,
        'approvedBy': approvedBy,
        'approvalDate': DateTime.now().toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Solicitud aprobada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al aprobar solicitud');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Rechazar solicitud de vacaciones
  Future<bool> rejectVacation({
    required num vacationId,
    required String rejectedBy,
    required String reason,
  }) async {
    try {
      EasyLoading.show(status: 'Procesando...', dismissOnTap: false);

      final response = await _apiService.put('vacations/$vacationId', {
        'status': 'Rechazado',
        'approvedBy': rejectedBy,
        'approvalDate': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
      });

      if (response.success) {
        EasyLoading.showSuccess('Solicitud rechazada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al rechazar solicitud');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Cancelar solicitud de vacaciones
  Future<bool> cancelVacation({required num vacationId}) async {
    try {
      EasyLoading.show(status: 'Cancelando...', dismissOnTap: false);

      final response = await _apiService.put('vacations/$vacationId', {
        'status': 'Cancelado',
      });

      if (response.success) {
        EasyLoading.showSuccess('Solicitud cancelada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al cancelar solicitud');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Eliminar solicitud de vacaciones
  Future<bool> deleteVacation({required num vacationId}) async {
    try {
      EasyLoading.show(status: 'Eliminando...', dismissOnTap: false);

      final response = await _apiService.delete('vacations/$vacationId');

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

  /// Obtener balance de vacaciones de un empleado
  Future<VacationBalance> getEmployeeVacationBalance(EmployeeModel employee) async {
    final vacations = await getVacationsByEmployee(employee.id);
    final now = DateTime.now();

    // Período de vacaciones (desde fecha de ingreso)
    final periodStart = DateTime(
      now.year - 1,
      employee.joiningDate.month,
      employee.joiningDate.day,
    );
    final periodEnd = DateTime(
      now.year,
      employee.joiningDate.month,
      employee.joiningDate.day,
    ).subtract(const Duration(days: 1));

    // Calcular días usados en el período actual
    int daysUsed = 0;
    int daysPending = 0;
    DateTime? lastVacationDate;

    for (var v in vacations) {
      if (v.type == LeaveTypes.vacaciones) {
        if (v.startDate.isAfter(periodStart) && v.startDate.isBefore(periodEnd)) {
          if (v.status == 'Aprobado' || v.status == 'Completado') {
            daysUsed += v.daysApproved;
            if (lastVacationDate == null || v.endDate.isAfter(lastVacationDate)) {
              lastVacationDate = v.endDate;
            }
          } else if (v.status == 'Pendiente') {
            daysPending += v.daysRequested;
          }
        }
      }
    }

    // Días a los que tiene derecho según Ley 16-92
    int daysEntitled = 0;
    if (employee.yearsOfService >= 1) {
      daysEntitled = 14; // 14 días laborables después de 1 año
    }

    // Días disponibles
    final daysAvailable = daysEntitled - daysUsed;

    return VacationBalance(
      employeeId: employee.id,
      employeeName: employee.fullName,
      yearsOfService: employee.yearsOfService,
      daysEntitled: daysEntitled,
      daysUsed: daysUsed,
      daysPending: daysPending,
      daysAvailable: daysAvailable > 0 ? daysAvailable : 0,
      periodStart: periodStart,
      periodEnd: periodEnd,
      lastVacationDate: lastVacationDate,
    );
  }

  /// Obtener balance de vacaciones de todos los empleados
  Future<List<VacationBalance>> getAllEmployeesVacationBalance() async {
    List<VacationBalance> balances = [];

    try {
      final employees = await EmployeeRepository().getActiveEmployees();

      for (var employee in employees) {
        final balance = await getEmployeeVacationBalance(employee);
        balances.add(balance);
      }
    } catch (e) {
      // Error silencioso
    }

    return balances;
  }

  /// Calcular pago de vacaciones según Ley 16-92
  /// Art. 177: El salario de vacaciones comprende la remuneración habitual
  /// Se calcula dividiendo el salario mensual entre 23.83 días laborables
  static double calculateVacationPay({
    required double monthlySalary,
    required int vacationDays,
  }) {
    const double workDaysPerMonth = 23.83;
    final dailySalary = monthlySalary / workDaysPerMonth;
    return dailySalary * vacationDays;
  }

  /// Verificar si hay conflicto de fechas con otras vacaciones aprobadas
  Future<bool> hasDateConflict({
    required num employeeId,
    required DateTime startDate,
    required DateTime endDate,
    num? excludeVacationId,
  }) async {
    final vacations = await getVacationsByEmployee(employeeId);

    for (var v in vacations) {
      if (v.status == 'Aprobado' &&
          (excludeVacationId == null || v.id != excludeVacationId)) {
        // Verificar si hay solapamiento
        if (!(endDate.isBefore(v.startDate) || startDate.isAfter(v.endDate))) {
          return true;
        }
      }
    }

    return false;
  }

  /// Obtener resumen de licencias por tipo
  Future<Map<String, int>> getLeaveSummaryByType(String year) async {
    final all = await getAllVacations();
    final yearInt = int.parse(year);

    Map<String, int> summary = {};
    for (var type in LeaveTypes.all) {
      summary[type] = 0;
    }

    for (var v in all) {
      if (v.startDate.year == yearInt &&
          (v.status == 'Aprobado' || v.status == 'Completado')) {
        summary[v.type] = (summary[v.type] ?? 0) + v.daysApproved;
      }
    }

    return summary;
  }

  /// Obtener elegibilidad de vacaciones para todos los empleados
  /// Calcula cuáles empleados están próximos a su aniversario laboral
  Future<List<VacationEligibility>> getUpcomingVacationEligibility({
    int daysAhead = 90,
  }) async {
    List<VacationEligibility> eligibilities = [];

    try {
      final employees = await EmployeeRepository().getActiveEmployees();
      final vacations = await getAllVacations();
      final now = DateTime.now();

      for (var employee in employees) {
        // Solo empleados con >= 1 año de servicio o que están por cumplir
        final monthsOfService = now.difference(employee.joiningDate).inDays / 30;
        if (monthsOfService < 9) continue; // Ignorar empleados muy nuevos

        // Calcular próximo aniversario laboral
        int nextYear = employee.yearsOfService + 1;
        DateTime nextAnniversary = DateTime(
          employee.joiningDate.year + nextYear,
          employee.joiningDate.month,
          employee.joiningDate.day,
        );

        // Si el aniversario ya pasó este año, calcular el siguiente
        if (nextAnniversary.isBefore(now.subtract(const Duration(days: 30)))) {
          nextYear++;
          nextAnniversary = DateTime(
            employee.joiningDate.year + nextYear,
            employee.joiningDate.month,
            employee.joiningDate.day,
          );
        }

        final daysUntil = nextAnniversary.difference(now).inDays;

        // Calcular balance actual
        final balance = await getEmployeeVacationBalance(employee);

        // Buscar última fecha de vacaciones
        DateTime? lastVacDate;
        final empVacations = vacations.where((v) =>
            v.employeeId == employee.id &&
            v.type == LeaveTypes.vacaciones &&
            (v.status == 'Aprobado' || v.status == 'Completado'));
        if (empVacations.isNotEmpty) {
          lastVacDate = empVacations
              .reduce((a, b) => a.endDate.isAfter(b.endDate) ? a : b)
              .endDate;
        }

        final hasNeverTaken = lastVacDate == null && employee.yearsOfService >= 1;

        final urgency = VacationEligibility.calculateUrgency(
          daysUntilAnniversary: daysUntil,
          daysAvailable: balance.daysAvailable,
          hasNeverTakenVacation: hasNeverTaken,
        );

        // Incluir si está dentro del rango solicitado o tiene vacaciones vencidas
        if (daysUntil <= daysAhead || urgency == 'VENCIDO') {
          eligibilities.add(VacationEligibility(
            employeeId: employee.id,
            employeeName: employee.fullName,
            designation: employee.designation,
            department: employee.department,
            joiningDate: employee.joiningDate,
            yearsOfService: employee.yearsOfService,
            nextAnniversary: nextAnniversary,
            daysUntilAnniversary: daysUntil,
            daysAvailable: balance.daysAvailable,
            daysUsed: balance.daysUsed,
            daysEntitled: balance.daysEntitled,
            lastVacationDate: lastVacDate,
            urgencyLevel: urgency,
          ));
        }
      }

      // Ordenar por urgencia: VENCIDO > URGENTE > PRÓXIMO > OK
      final urgencyOrder = {'VENCIDO': 0, 'URGENTE': 1, 'PRÓXIMO': 2, 'OK': 3};
      eligibilities.sort((a, b) {
        final cmp = (urgencyOrder[a.urgencyLevel] ?? 4)
            .compareTo(urgencyOrder[b.urgencyLevel] ?? 4);
        if (cmp != 0) return cmp;
        return a.daysUntilAnniversary.compareTo(b.daysUntilAnniversary);
      });
    } catch (e) {
      // Error silencioso
    }

    return eligibilities;
  }

  /// Obtener empleados con vacaciones vencidas (tienen días disponibles sin usar)
  Future<List<VacationEligibility>> getOverdueVacations() async {
    final all = await getUpcomingVacationEligibility(daysAhead: 365);
    return all.where((e) => e.urgencyLevel == 'VENCIDO').toList();
  }
}
