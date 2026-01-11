import '../model/bank_info_model.dart';
import '../services/api_service.dart';

/// Repositorio de información bancaria - Usa PostgreSQL API
class BankInfoRepo {
  final ApiService _apiService = ApiService();

  /// Obtener información bancaria desde PostgreSQL
  Future<BankInfoModel> getPaypalInfo() async {
    BankInfoModel defaultModel = BankInfoModel(
      bankName: '',
      branchName: '',
      accountName: '',
      accountNumber: '',
      swiftCode: '',
      bankAccountCurrency: 'DOP',
      isActive: false,
    );

    try {
      final response = await _apiService.get('bank-info');

      if (response.success && response.data != null) {
        final bankData = response.data['bank_info'] ?? response.data;
        if (bankData != null) {
          return BankInfoModel.fromJson(bankData as Map<String, dynamic>);
        }
      }
      return defaultModel;
    } catch (e) {
      return defaultModel;
    }
  }

  /// Actualizar información bancaria
  Future<bool> updateBankInfo(BankInfoModel bankInfo) async {
    try {
      final bankData = Map<String, dynamic>.from(bankInfo.toJson());
      final response = await _apiService.put('bank-info', bankData);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
