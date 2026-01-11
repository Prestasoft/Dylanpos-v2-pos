import '../model/daily_transaction_model.dart';
import '../services/api_service.dart';

/// Repositorio de transacciones diarias - Usa PostgreSQL API
class DailyTransactionRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las transacciones diarias desde PostgreSQL
  Future<List<DailyTransactionModel>> getAllDailyTransition() async {
    try {
      final response = await _apiService.get('daily-transactions', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final transactionsData = response.data['daily_transactions'] as List<dynamic>? ?? [];

        return transactionsData.map((data) {
          return DailyTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener transacciones diarias por fecha
  Future<List<DailyTransactionModel>> getDailyTransactionsByDate(String date) async {
    try {
      final response = await _apiService.get('daily-transactions', queryParams: {
        'date': date,
        'limit': '100',
      });

      if (response.success && response.data != null) {
        final transactionsData = response.data['daily_transactions'] as List<dynamic>? ?? [];

        return transactionsData.map((data) {
          return DailyTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva transacción diaria
  Future<DailyTransactionModel?> createDailyTransaction(DailyTransactionModel transaction) async {
    try {
      final transactionData = Map<String, dynamic>.from(transaction.toJson());
      final response = await _apiService.post('daily-transactions', transactionData);

      if (response.success && response.data != null) {
        return DailyTransactionModel.fromJson(response.data['daily_transaction']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar una transacción diaria
  Future<DailyTransactionModel?> updateDailyTransaction(String id, DailyTransactionModel transaction) async {
    try {
      final transactionData = Map<String, dynamic>.from(transaction.toJson());
      final response = await _apiService.put('daily-transactions/$id', transactionData);

      if (response.success && response.data != null) {
        return DailyTransactionModel.fromJson(response.data['daily_transaction']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
