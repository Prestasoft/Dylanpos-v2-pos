import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/attendance/model/attendance_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../../../services/api_service.dart';

/// Repositorio de asistencia - Usa PostgreSQL API
class AttendanceRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los registros de asistencia desde PostgreSQL
  Future<List<AttendanceModel>> getAllAttendance() async {
    List<AttendanceModel> attendanceList = [];

    try {
      final response = await _apiService.get('attendance', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final attendanceData = response.data['attendance'] as List<dynamic>? ?? [];

        for (var element in attendanceData) {
          final data = Map<String, dynamic>.from(element as Map);
          data['id'] = data['id'] ?? data['attendance_id'];
          attendanceList.add(AttendanceModel.fromJson(data));
        }
      }
    } catch (e) {
      // Error silencioso
    }

    return attendanceList;
  }

  /// Obtener asistencia por fecha
  Future<List<AttendanceModel>> getAttendanceByDate(DateTime date) async {
    final all = await getAllAttendance();
    return all.where((a) =>
        a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day).toList();
  }

  /// Obtener asistencia por empleado
  Future<List<AttendanceModel>> getAttendanceByEmployee(num employeeId) async {
    final all = await getAllAttendance();
    return all.where((a) => a.employeeId == employeeId).toList();
  }

  /// Obtener asistencia por rango de fechas
  Future<List<AttendanceModel>> getAttendanceByDateRange(
      DateTime startDate, DateTime endDate) async {
    final all = await getAllAttendance();
    return all.where((a) =>
        a.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        a.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
  }

  /// Obtener asistencia de un empleado en un período
  Future<List<AttendanceModel>> getEmployeeAttendanceByPeriod(
      num employeeId, DateTime startDate, DateTime endDate) async {
    final all = await getAttendanceByEmployee(employeeId);
    return all.where((a) =>
        a.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        a.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
  }

  /// Registrar entrada (Check-in)
  Future<bool> checkIn({
    required EmployeeModel employee,
    String? notes,
    String checkInMethod = 'Manual',
    String? location,
  }) async {
    try {
      EasyLoading.show(status: 'Registrando entrada...', dismissOnTap: false);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Verificar si ya tiene registro hoy
      final existingRecords = await getAttendanceByDate(today);
      final hasRecord = existingRecords.any((r) => r.employeeId == employee.id);

      if (hasRecord) {
        EasyLoading.showError('El empleado ya tiene registro de entrada hoy');
        return false;
      }

      // Determinar estado (tardanza si es después de las 8:00 AM)
      String status = AttendanceStatus.presente;
      double lateMinutes = 0;
      final expectedTime = DateTime(now.year, now.month, now.day, 8, 0);

      if (now.isAfter(expectedTime)) {
        status = AttendanceStatus.tardanza;
        lateMinutes = now.difference(expectedTime).inMinutes.toDouble();
      }

      final attendanceId = DateTime.now().millisecondsSinceEpoch;
      final attendance = AttendanceModel(
        id: attendanceId,
        employeeId: employee.id,
        employeeName: employee.fullName,
        employeeCedula: employee.cedula,
        designation: employee.designation,
        department: employee.department,
        date: today,
        checkInTime: now,
        status: status,
        lateMinutes: lateMinutes,
        checkInMethod: checkInMethod,
        location: location,
        notes: notes,
      );

      final attendanceData = Map<String, dynamic>.from(attendance.toJson());
      final response = await _apiService.post('attendance', attendanceData);

      if (response.success) {
        EasyLoading.showSuccess('Entrada registrada: ${_formatTime(now)}');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al registrar entrada');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Registrar salida (Check-out)
  Future<bool> checkOut({
    required num employeeId,
    String? notes,
    String checkOutMethod = 'Manual',
    String? location,
  }) async {
    try {
      EasyLoading.show(status: 'Registrando salida...', dismissOnTap: false);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Buscar registro de hoy
      final todayRecords = await getAttendanceByDate(today);
      final existingRecord = todayRecords
          .where((r) => r.employeeId == employeeId)
          .firstOrNull;

      if (existingRecord == null) {
        EasyLoading.showError('No hay registro de entrada para hoy');
        return false;
      }

      if (existingRecord.checkOutTime != null) {
        EasyLoading.showError('Ya tiene registro de salida hoy');
        return false;
      }

      // Calcular horas trabajadas
      final hoursWorked = now.difference(existingRecord.checkInTime!).inMinutes / 60;

      // Calcular horas extras (más de 8 horas)
      double overtimeHours = 0;
      if (hoursWorked > 8) {
        overtimeHours = hoursWorked - 8;
      }

      // Calcular salida temprana (antes de las 5:00 PM)
      double earlyDepartureMinutes = 0;
      final expectedEndTime = DateTime(now.year, now.month, now.day, 17, 0);
      if (now.isBefore(expectedEndTime)) {
        earlyDepartureMinutes = expectedEndTime.difference(now).inMinutes.toDouble();
      }

      // Actualizar registro
      final updatedAttendance = AttendanceModel(
        id: existingRecord.id,
        employeeId: existingRecord.employeeId,
        employeeName: existingRecord.employeeName,
        employeeCedula: existingRecord.employeeCedula,
        designation: existingRecord.designation,
        department: existingRecord.department,
        date: existingRecord.date,
        checkInTime: existingRecord.checkInTime,
        checkOutTime: now,
        breakStartTime: existingRecord.breakStartTime,
        breakEndTime: existingRecord.breakEndTime,
        status: existingRecord.status,
        hoursWorked: hoursWorked,
        overtimeHours: overtimeHours,
        lateMinutes: existingRecord.lateMinutes,
        earlyDepartureMinutes: earlyDepartureMinutes,
        checkInMethod: existingRecord.checkInMethod,
        checkOutMethod: checkOutMethod,
        location: location ?? existingRecord.location,
        notes: notes ?? existingRecord.notes,
        isApproved: existingRecord.isApproved,
        approvedBy: existingRecord.approvedBy,
        approvedAt: existingRecord.approvedAt,
      );

      final attendanceData = Map<String, dynamic>.from(updatedAttendance.toJson());
      final response = await _apiService.put('attendance/${existingRecord.id}', attendanceData);

      if (response.success) {
        EasyLoading.showSuccess('Salida registrada: ${_formatTime(now)}');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al registrar salida');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Registrar inicio de descanso
  Future<bool> startBreak({required num employeeId}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayRecords = await getAttendanceByDate(today);
      final existingRecord = todayRecords
          .where((r) => r.employeeId == employeeId)
          .firstOrNull;

      if (existingRecord == null || existingRecord.checkInTime == null) {
        EasyLoading.showError('Debe registrar entrada primero');
        return false;
      }

      final response = await _apiService.put('attendance/${existingRecord.id}', {
        'breakStartTime': now.toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Inicio de descanso: ${_formatTime(now)}');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al registrar descanso');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Registrar fin de descanso
  Future<bool> endBreak({required num employeeId}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayRecords = await getAttendanceByDate(today);
      final existingRecord = todayRecords
          .where((r) => r.employeeId == employeeId)
          .firstOrNull;

      if (existingRecord == null || existingRecord.breakStartTime == null) {
        EasyLoading.showError('Debe iniciar descanso primero');
        return false;
      }

      final response = await _apiService.put('attendance/${existingRecord.id}', {
        'breakEndTime': now.toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Fin de descanso: ${_formatTime(now)}');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al registrar fin de descanso');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Registrar asistencia manual
  Future<bool> saveManualAttendance({required AttendanceModel attendance}) async {
    try {
      EasyLoading.show(status: 'Guardando...', dismissOnTap: false);

      final attendanceData = Map<String, dynamic>.from(attendance.toJson());
      final response = await _apiService.post('attendance', attendanceData);

      if (response.success) {
        EasyLoading.showSuccess('Asistencia guardada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al guardar asistencia');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Actualizar asistencia
  Future<bool> updateAttendance({required AttendanceModel attendance}) async {
    try {
      EasyLoading.show(status: 'Actualizando...', dismissOnTap: false);

      final attendanceData = Map<String, dynamic>.from(attendance.toJson());
      final response = await _apiService.put('attendance/${attendance.id}', attendanceData);

      if (response.success) {
        EasyLoading.showSuccess('Asistencia actualizada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al actualizar asistencia');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Eliminar registro de asistencia
  Future<bool> deleteAttendance({required num id}) async {
    try {
      EasyLoading.show(status: 'Eliminando...');

      final response = await _apiService.delete('attendance/$id');

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

  /// Aprobar asistencia
  Future<bool> approveAttendance({required num id, required String approvedBy}) async {
    try {
      final response = await _apiService.put('attendance/$id', {
        'isApproved': true,
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now().toIso8601String(),
      });

      if (response.success) {
        EasyLoading.showSuccess('Asistencia aprobada');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al aprobar asistencia');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  /// Generar registros de asistencia para todos los empleados activos (para un día)
  Future<List<AttendanceModel>> generateDailyAttendance(DateTime date) async {
    List<AttendanceModel> generatedRecords = [];

    try {
      EasyLoading.show(status: 'Generando registros...', dismissOnTap: false);

      // Verificar si es feriado
      if (HolidaysRD.isHoliday(date)) {
        EasyLoading.showInfo('El día seleccionado es feriado');
        return generatedRecords;
      }

      // Verificar si es fin de semana
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        EasyLoading.showInfo('El día seleccionado es fin de semana');
        return generatedRecords;
      }

      // Obtener empleados activos
      final employees = await EmployeeRepository().getActiveEmployees();

      // Obtener registros existentes para ese día
      final existingRecords = await getAttendanceByDate(date);
      final existingEmployeeIds = existingRecords.map((r) => r.employeeId).toSet();

      for (var employee in employees) {
        if (!existingEmployeeIds.contains(employee.id)) {
          final attendanceId = DateTime.now().millisecondsSinceEpoch + employee.id.toInt();
          final record = AttendanceModel(
            id: attendanceId,
            employeeId: employee.id,
            employeeName: employee.fullName,
            employeeCedula: employee.cedula,
            designation: employee.designation,
            department: employee.department,
            date: date,
            status: AttendanceStatus.ausente, // Por defecto ausente hasta que registren
          );
          generatedRecords.add(record);
        }
      }

      EasyLoading.showSuccess('Registros generados: ${generatedRecords.length}');
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
    }

    return generatedRecords;
  }

  /// Obtener resumen de asistencia por empleado y período
  Future<AttendanceSummary> getEmployeeSummary(
      num employeeId, String employeeName, String year, String month) async {
    final yearNum = int.parse(year);
    final monthNum = int.parse(month);
    final startDate = DateTime(yearNum, monthNum, 1);
    final endDate = DateTime(yearNum, monthNum + 1, 0);

    final records = await getEmployeeAttendanceByPeriod(employeeId, startDate, endDate);

    int daysPresent = 0;
    int daysAbsent = 0;
    int daysLate = 0;
    int daysOnLeave = 0;
    int daysOnVacation = 0;
    double totalHoursWorked = 0;
    double totalOvertimeHours = 0;
    double totalLateMinutes = 0;

    for (var record in records) {
      switch (record.status) {
        case AttendanceStatus.presente:
          daysPresent++;
          break;
        case AttendanceStatus.ausente:
          daysAbsent++;
          break;
        case AttendanceStatus.tardanza:
          daysLate++;
          daysPresent++; // Tardanza cuenta como presente
          break;
        case AttendanceStatus.permiso:
        case AttendanceStatus.licenciaMedica:
        case AttendanceStatus.licenciaMaternidad:
        case AttendanceStatus.licenciaPaternidad:
          daysOnLeave++;
          break;
        case AttendanceStatus.vacaciones:
          daysOnVacation++;
          break;
      }
      totalHoursWorked += record.hoursWorked;
      totalOvertimeHours += record.overtimeHours;
      totalLateMinutes += record.lateMinutes;
    }

    // Calcular días laborables en el mes (excluyendo fines de semana y feriados)
    int totalWorkDays = 0;
    for (var day = startDate; day.isBefore(endDate.add(const Duration(days: 1)));
         day = day.add(const Duration(days: 1))) {
      if (day.weekday != DateTime.saturday &&
          day.weekday != DateTime.sunday &&
          !HolidaysRD.isHoliday(day)) {
        totalWorkDays++;
      }
    }

    final attendancePercentage = totalWorkDays > 0
        ? ((daysPresent + daysOnLeave + daysOnVacation) / totalWorkDays) * 100
        : 0.0;

    return AttendanceSummary(
      employeeId: employeeId,
      employeeName: employeeName,
      month: month,
      year: year,
      totalDays: totalWorkDays,
      daysPresent: daysPresent,
      daysAbsent: daysAbsent,
      daysLate: daysLate,
      daysOnLeave: daysOnLeave,
      daysOnVacation: daysOnVacation,
      totalHoursWorked: totalHoursWorked,
      totalOvertimeHours: totalOvertimeHours,
      totalLateMinutes: totalLateMinutes,
      attendancePercentage: attendancePercentage,
    );
  }

  /// Obtener resumen de asistencia del día para todos los empleados
  Future<Map<String, int>> getDailySummary(DateTime date) async {
    final records = await getAttendanceByDate(date);

    int present = 0;
    int absent = 0;
    int late = 0;
    int onLeave = 0;

    for (var record in records) {
      switch (record.status) {
        case AttendanceStatus.presente:
          present++;
          break;
        case AttendanceStatus.ausente:
          absent++;
          break;
        case AttendanceStatus.tardanza:
          late++;
          break;
        default:
          onLeave++;
      }
    }

    return {
      'total': records.length,
      'present': present,
      'absent': absent,
      'late': late,
      'onLeave': onLeave,
    };
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
