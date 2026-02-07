import 'package:flutter/foundation.dart';
import 'package:salespro_admin/services/api_service.dart';
import '../models/commission_config_model.dart';
import '../models/employee_performance_model.dart';

/// Repository para datos de Rentabilidad
class RentabilityRepository {
  final ApiService _apiService = ApiService();

  /// Obtener desempeño de todos los empleados en un período
  Future<List<EmployeePerformance>> getEmployeesPerformance({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.get(
        'rentability/employees-performance',
        queryParams: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data['performances'] ?? [];
        return data.map((json) => EmployeePerformance.fromMap(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo desempeño de empleados: $e');
      return [];
    }
  }

  /// Obtener desempeño de un empleado específico
  Future<EmployeePerformance?> getEmployeePerformance({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.get(
        'rentability/employee-performance/$employeeId',
        queryParams: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        return EmployeePerformance.fromMap(response.data['performance']);
      }

      return null;
    } catch (e) {
      debugPrint('Error obteniendo desempeño del empleado: $e');
      return null;
    }
  }

  /// Obtener todas las reservas pendientes de facturar
  Future<List<Map<String, dynamic>>> getPendingInvoices() async {
    try {
      final response = await _apiService.get('rentability/pending-invoices');

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data['pending'] ?? [];
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo reservas pendientes: $e');
      return [];
    }
  }

  /// Obtener configuración de comisiones
  Future<CommissionConfig?> getCommissionConfig() async {
    try {
      final response = await _apiService.get('rentability/commission-config');

      if (response.success && response.data != null) {
        final configData = response.data['config'];
        if (configData != null) {
          return CommissionConfig.fromMap(configData, configData['id'] ?? '');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error obteniendo configuración de comisiones: $e');
      return null;
    }
  }

  /// Guardar configuración de comisiones
  Future<bool> saveCommissionConfig(CommissionConfig config) async {
    try {
      final response = await _apiService.post(
        'rentability/commission-config',
        config.toMap(),
      );

      return response.success;
    } catch (e) {
      debugPrint('Error guardando configuración de comisiones: $e');
      return false;
    }
  }

  /// Marcar comisiones de un empleado como pagadas
  Future<bool> markCommissionsAsPaid({
    required String employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime paidDate,
    required double commissionAmount,
    required double commissionPercentage,
    required double totalRevenue,
    required String paidBy,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final response = await _apiService.put(
        'rentability/mark-commissions-paid',
        {
          'employee_id': employeeId,
          'period_start': periodStart.toIso8601String(),
          'period_end': periodEnd.toIso8601String(),
          'paid_date': paidDate.toIso8601String(),
          'commission_amount': commissionAmount,
          'commission_percentage': commissionPercentage,
          'total_revenue': totalRevenue,
          'paid_by': paidBy,
          'payment_method': paymentMethod,
          'notes': notes ?? '',
        },
      );

      return response.success;
    } catch (e) {
      debugPrint('Error marcando comisiones como pagadas: $e');
      return false;
    }
  }
}
