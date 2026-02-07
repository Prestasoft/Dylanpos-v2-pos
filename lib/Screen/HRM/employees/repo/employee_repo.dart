import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';

import '../../../../services/api_service.dart';

/// Repositorio de empleados - Usa PostgreSQL API
class EmployeeRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los empleados desde PostgreSQL
  Future<List<EmployeeModel>> getAllEmployees() async {
    List<EmployeeModel> employees = [];

    try {
      print('🔵 [EmployeeRepo] Obteniendo empleados...');
      final response = await _apiService.get('hrm/employees', queryParams: {'limit': '1000'});

      print('🔵 [EmployeeRepo] Respuesta: success=${response.success}');
      print('🔵 [EmployeeRepo] Data: ${response.data}');

      if (response.success && response.data != null) {
        final employeesData = response.data['employees'] as List<dynamic>? ?? [];
        print('🔵 [EmployeeRepo] Encontrados ${employeesData.length} empleados');

        for (var element in employeesData) {
          try {
            final data = Map<String, dynamic>.from(element as Map);
            data['id'] = data['id'] ?? data['employee_id'];
            print('🔵 [EmployeeRepo] Parseando empleado: ${data['first_name']} ${data['last_name']} (ID: ${data['id']})');
            employees.add(EmployeeModel.fromJson(data));
          } catch (parseError) {
            print('🔴 [EmployeeRepo] Error parseando empleado: $parseError');
          }
        }
        print('🔵 [EmployeeRepo] Total empleados parseados: ${employees.length}');
      }
    } catch (e) {
      print('🔴 [EmployeeRepo] Error obteniendo empleados: $e');
    }

    return employees;
  }

  /// Obtener empleados activos
  Future<List<EmployeeModel>> getActiveEmployees() async {
    final all = await getAllEmployees();
    return all.where((e) => e.status == 'Activo').toList();
  }

  /// Obtener empleado por ID
  Future<EmployeeModel?> getEmployeeById(dynamic id) async {
    try {
      final response = await _apiService.get('employees/$id');

      if (response.success && response.data != null) {
        final employeeData = response.data['employee'];
        if (employeeData != null) {
          final data = Map<String, dynamic>.from(employeeData as Map);
          data['id'] = data['id'] ?? data['employee_id'];
          return EmployeeModel.fromJson(data);
        }
      }
    } catch (e) {
      // Error silencioso
    }
    return null;
  }

  /// Buscar empleado por cédula
  Future<EmployeeModel?> getEmployeeByCedula(String cedula) async {
    final all = await getAllEmployees();
    try {
      return all.firstWhere(
        (e) => e.cedula.replaceAll('-', '') == cedula.replaceAll('-', ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// Agregar nuevo empleado
  Future<bool> addEmployee({required EmployeeModel employee}) async {
    try {
      EasyLoading.show(status: 'Guardando...', dismissOnTap: false);

      final employeeData = employee.toJson();
      print('🔵 [EmployeeRepo] Enviando datos de empleado:');
      print('   $employeeData');

      final response = await _apiService.post('hrm/employees', employeeData);

      print('🔵 [EmployeeRepo] Respuesta del servidor:');
      print('   success: ${response.success}');
      print('   message: ${response.message}');
      print('   data: ${response.data}');

      if (response.success) {
        EasyLoading.showSuccess('Empleado agregado exitosamente',
            duration: const Duration(milliseconds: 500));
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al agregar empleado');
      return false;
    } catch (e) {
      print('🔴 [EmployeeRepo] Error al agregar empleado: $e');
      EasyLoading.dismiss();
      throw Exception('Error al agregar empleado: ${e.toString()}');
    }
  }

  /// Actualizar empleado existente
  Future<bool> updateEmployee({required EmployeeModel employee}) async {
    try {
      EasyLoading.show(status: 'Actualizando...', dismissOnTap: false);

      final employeeData = employee.toJson();
      final response = await _apiService.put('hrm/employees/${employee.id}', employeeData);

      if (response.success) {
        EasyLoading.showSuccess('Empleado actualizado exitosamente');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al actualizar empleado');
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Error al actualizar empleado: ${e.toString()}');
    }
  }

  /// Actualizar estado del empleado
  Future<bool> updateEmployeeStatus({
    required dynamic id,
    required String status,
    DateTime? terminationDate,
    String? terminationReason,
  }) async {
    try {
      EasyLoading.show(status: 'Actualizando...', dismissOnTap: false);

      Map<String, dynamic> updates = {'status': status};

      if (terminationDate != null) {
        updates['terminationDate'] = terminationDate.toIso8601String();
      }
      if (terminationReason != null) {
        updates['terminationReason'] = terminationReason;
      }

      final response = await _apiService.put('hrm/employees/$id', updates);

      if (response.success) {
        EasyLoading.showSuccess('Estado actualizado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al actualizar estado');
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Error al actualizar estado: ${e.toString()}');
    }
  }

  /// Actualizar campos parciales del empleado (para actualización desde Padrón Electoral)
  Future<bool> updateEmployeePartial({
    required dynamic id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiService.put('hrm/employees/$id', data);
      return response.success;
    } catch (e) {
      debugPrint('Error al actualizar empleado parcialmente: $e');
      return false;
    }
  }

  /// Actualizar días de vacaciones
  Future<bool> updateVacationDays({
    required dynamic employeeId,
    int? daysAccrued,
    int? daysTaken,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (daysAccrued != null) {
        updates['vacationDaysAccrued'] = daysAccrued;
      }
      if (daysTaken != null) {
        updates['vacationDaysTaken'] = daysTaken;
      }

      if (updates.isNotEmpty) {
        final response = await _apiService.put('hrm/employees/$employeeId', updates);
        return response.success;
      }

      return true;
    } catch (e) {
      throw Exception('Error al actualizar vacaciones: ${e.toString()}');
    }
  }

  /// Eliminar empleado
  Future<bool> deleteEmployee({required dynamic id}) async {
    try {
      EasyLoading.show(status: 'Eliminando...');

      final response = await _apiService.delete('hrm/employees/$id');

      if (response.success) {
        EasyLoading.showSuccess('Empleado eliminado');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al eliminar empleado');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Obtener resumen de empleados por departamento
  Future<Map<String, int>> getEmployeesByDepartment() async {
    final all = await getActiveEmployees();
    Map<String, int> byDepartment = {};

    for (var employee in all) {
      final dept = employee.department;
      byDepartment[dept] = (byDepartment[dept] ?? 0) + 1;
    }

    return byDepartment;
  }

  /// Obtener empleados con contrato próximo a vencer (30 días)
  Future<List<EmployeeModel>> getEmployeesWithExpiringContracts() async {
    final all = await getActiveEmployees();
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    return all.where((e) {
      if (e.contractEndDate == null) return false;
      return e.contractEndDate!.isAfter(now) &&
          e.contractEndDate!.isBefore(thirtyDaysFromNow);
    }).toList();
  }

  /// Obtener empleados por AFP
  Future<Map<String, List<EmployeeModel>>> getEmployeesByAFP() async {
    final all = await getActiveEmployees();
    Map<String, List<EmployeeModel>> byAFP = {};

    for (var employee in all) {
      final afp = employee.afpProvider;
      byAFP[afp] = [...(byAFP[afp] ?? []), employee];
    }

    return byAFP;
  }

  /// Obtener empleados por ARS
  Future<Map<String, List<EmployeeModel>>> getEmployeesByARS() async {
    final all = await getActiveEmployees();
    Map<String, List<EmployeeModel>> byARS = {};

    for (var employee in all) {
      final ars = employee.sfsProvider;
      byARS[ars] = [...(byARS[ars] ?? []), employee];
    }

    return byARS;
  }
}
