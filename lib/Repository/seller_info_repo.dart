import '../model/seller_info_model.dart';
import '../services/api_service.dart';

/// Repositorio de información de vendedores - Usa PostgreSQL API
class SellerInfoRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los vendedores desde PostgreSQL
  Future<List<SellerInfoModel>> getAllSeller() async {
    try {
      final response = await _apiService.get('sellers', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        final sellersData = response.data['sellers'] as List<dynamic>? ?? [];

        return sellersData.map((data) {
          return SellerInfoModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting sellers: $e');
      return [];
    }
  }

  /// Obtener información del vendedor actual
  Future<SellerInfoModel?> getCurrentSellerInfo() async {
    try {
      final response = await _apiService.get('sellers/current');

      if (response.success && response.data != null) {
        return SellerInfoModel.fromJson(response.data['seller']);
      }
      return null;
    } catch (e) {
      print('Error getting current seller: $e');
      return null;
    }
  }

  /// Actualizar información del vendedor
  Future<bool> updateSellerInfo(SellerInfoModel seller) async {
    try {
      final sellerData = Map<String, dynamic>.from(seller.toJson());
      final response = await _apiService.put('sellers/current', sellerData);
      return response.success;
    } catch (e) {
      print('Error updating seller: $e');
      return false;
    }
  }
}
