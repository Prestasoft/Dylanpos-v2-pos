import '../model/sales_report.dart';
import '../services/api_service.dart';

/// Repositorio de reportes de ventas - Usa PostgreSQL API
class SalesReportRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los reportes de ventas desde PostgreSQL
  Future<List<SalesReport>> getAllSalesReport() async {
    try {
      final response = await _apiService.get('sales-reports', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final reportsData = response.data['sales_reports'] as List<dynamic>? ?? [];

        return reportsData.map((data) {
          return SalesReport.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener reporte de ventas por fecha
  Future<List<SalesReport>> getSalesReportByDateRange(String startDate, String endDate) async {
    try {
      final response = await _apiService.get('sales-reports', queryParams: {
        'start_date': startDate,
        'end_date': endDate,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final reportsData = response.data['sales_reports'] as List<dynamic>? ?? [];

        return reportsData.map((data) {
          return SalesReport.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear un nuevo reporte de ventas
  Future<SalesReport?> createSalesReport(SalesReport report) async {
    try {
      final reportData = Map<String, dynamic>.from(report.toJson());
      final response = await _apiService.post('sales-reports', reportData);

      if (response.success && response.data != null) {
        return SalesReport.fromJson(response.data['sales_report']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
