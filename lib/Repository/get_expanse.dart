import '../model/expense_model.dart';
import '../services/api_service.dart';

/// Repositorio de gastos - Usa PostgreSQL API
class ExpenseRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los gastos desde PostgreSQL
  Future<List<ExpenseModel>> getAllExpense() async {
    try {
      final response = await _apiService.getExpenses(limit: 1000);

      if (response.success && response.data != null) {
        final expensesData = response.data['expenses'] as List<dynamic>? ?? [];

        return expensesData.map((data) {
          return ExpenseModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear un nuevo gasto
  Future<ExpenseModel?> createExpense(ExpenseModel expense) async {
    try {
      final expenseData = Map<String, dynamic>.from(expense.toJson());
      final response = await _apiService.createExpense(expenseData);

      if (response.success && response.data != null) {
        return ExpenseModel.fromJson(response.data['expense']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar un gasto existente
  Future<ExpenseModel?> updateExpense(String id, ExpenseModel expense) async {
    try {
      final expenseData = Map<String, dynamic>.from(expense.toJson());
      final response = await _apiService.put('expenses/$id', expenseData);

      if (response.success && response.data != null) {
        return ExpenseModel.fromJson(response.data['expense']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar un gasto
  Future<bool> deleteExpense(String id) async {
    try {
      final response = await _apiService.delete('expenses/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
