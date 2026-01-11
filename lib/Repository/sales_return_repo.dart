import '../model/sale_transaction_model.dart';
import '../services/api_service.dart';

/// Repositorio de devoluciones de ventas - Usa PostgreSQL API
class SalesReturnRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las devoluciones de ventas desde PostgreSQL
  Future<List<SaleTransactionModel>> getAllTransition() async {
    try {
      final response = await _apiService.get('sales-returns', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final returnsData = response.data['sales_returns'] as List<dynamic>? ?? [];

        return returnsData.map((data) {
          return SaleTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva devolución de venta
  Future<SaleTransactionModel?> createSalesReturn(SaleTransactionModel salesReturn) async {
    try {
      final returnData = Map<String, dynamic>.from(salesReturn.toJson());
      final response = await _apiService.post('sales-returns', returnData);

      if (response.success && response.data != null) {
        return SaleTransactionModel.fromJson(response.data['sales_return']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una devolución de venta
  Future<bool> deleteSalesReturn(String id) async {
    try {
      final response = await _apiService.delete('sales-returns/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
