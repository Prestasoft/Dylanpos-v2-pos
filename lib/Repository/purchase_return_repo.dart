import 'package:salespro_admin/model/purchase_transation_model.dart';

import '../services/api_service.dart';

/// Repositorio de devoluciones de compras - Usa PostgreSQL API
class PurchaseReturnRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las devoluciones de compras desde PostgreSQL
  Future<List<PurchaseTransactionModel>> getAllTransition() async {
    try {
      final response = await _apiService.get('purchase-returns', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final returnsData = response.data['purchase_returns'] as List<dynamic>? ?? [];

        return returnsData.map((data) {
          return PurchaseTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva devolución de compra
  Future<PurchaseTransactionModel?> createPurchaseReturn(PurchaseTransactionModel purchaseReturn) async {
    try {
      final returnData = Map<String, dynamic>.from(purchaseReturn.toJson());
      final response = await _apiService.post('purchase-returns', returnData);

      if (response.success && response.data != null) {
        return PurchaseTransactionModel.fromJson(response.data['purchase_return']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una devolución de compra
  Future<bool> deletePurchaseReturn(String id) async {
    try {
      final response = await _apiService.delete('purchase-returns/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
