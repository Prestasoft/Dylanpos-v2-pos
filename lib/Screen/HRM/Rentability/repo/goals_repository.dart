import 'package:flutter/foundation.dart';
import 'package:salespro_admin/services/api_service.dart';
import '../models/employee_goals_model.dart';

/// Repository para gestionar metas/objetivos de empleados
class GoalsRepository {
  final ApiService _apiService = ApiService();

  /// Obtener metas de un empleado en un período específico
  Future<List<EmployeeGoal>> getEmployeeGoals({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiService.get('rentability/goals', queryParams: {
        'employee_id': employeeId,
        'year': year.toString(),
        'month': month.toString(),
      });

      if (response.success && response.data != null) {
        final goalsData = response.data['goals'] as List<dynamic>? ?? [];
        return goalsData
            .map((data) => EmployeeGoal.fromMap(Map<String, dynamic>.from(data)))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo metas del empleado: $e');
      rethrow;
    }
  }

  /// Obtener todas las metas de un período (para todos los empleados)
  Future<List<EmployeeGoal>> getAllGoals({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiService.get('rentability/goals', queryParams: {
        'year': year.toString(),
        'month': month.toString(),
      });

      if (response.success && response.data != null) {
        final goalsData = response.data['goals'] as List<dynamic>? ?? [];
        return goalsData
            .map((data) => EmployeeGoal.fromMap(Map<String, dynamic>.from(data)))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo todas las metas: $e');
      rethrow;
    }
  }

  /// Crear nueva meta para un empleado
  Future<EmployeeGoal> createGoal({
    required String employeeId,
    required String employeeName,
    required int year,
    required int month,
    required double targetRevenue,
    required int targetReservations,
    required double targetCommission,
  }) async {
    try {
      final response = await _apiService.post(
        'rentability/goals',
        {
          'employee_id': employeeId,
          'employee_name': employeeName,
          'year': year,
          'month': month,
          'target_revenue': targetRevenue,
          'target_reservations': targetReservations,
          'target_commission': targetCommission,
        },
      );

      if (response.success && response.data != null) {
        final goalData = response.data['goal'] as Map<String, dynamic>;
        return EmployeeGoal.fromMap(goalData);
      }

      throw Exception('Error creando meta: ${response.message}');
    } catch (e) {
      debugPrint('Error creando meta: $e');
      rethrow;
    }
  }

  /// Actualizar meta existente
  Future<EmployeeGoal> updateGoal({
    required String id,
    double? targetRevenue,
    int? targetReservations,
    double? targetCommission,
    double? actualRevenue,
    int? actualReservations,
    double? actualCommission,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (targetRevenue != null) updateData['target_revenue'] = targetRevenue;
      if (targetReservations != null) updateData['target_reservations'] = targetReservations;
      if (targetCommission != null) updateData['target_commission'] = targetCommission;
      if (actualRevenue != null) updateData['actual_revenue'] = actualRevenue;
      if (actualReservations != null) updateData['actual_reservations'] = actualReservations;
      if (actualCommission != null) updateData['actual_commission'] = actualCommission;
      if (status != null) updateData['status'] = status;

      final response = await _apiService.put('rentability/goals/$id', updateData);

      if (response.success && response.data != null) {
        final goalData = response.data['goal'] as Map<String, dynamic>;
        return EmployeeGoal.fromMap(goalData);
      }

      throw Exception('Error actualizando meta: ${response.message}');
    } catch (e) {
      debugPrint('Error actualizando meta: $e');
      rethrow;
    }
  }

  /// Eliminar meta
  Future<void> deleteGoal(String id) async {
    try {
      final response = await _apiService.delete('rentability/goals/$id');

      if (!response.success) {
        throw Exception('Error eliminando meta: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error eliminando meta: $e');
      rethrow;
    }
  }

  /// Sincronizar progreso de metas con datos reales
  Future<void> syncGoalsProgress() async {
    try {
      final response = await _apiService.post('rentability/goals/sync', {});

      if (!response.success) {
        throw Exception('Error sincronizando metas: ${response.message}');
      }

      debugPrint('Metas sincronizadas correctamente');
    } catch (e) {
      debugPrint('Error sincronizando metas: $e');
      rethrow;
    }
  }
}
