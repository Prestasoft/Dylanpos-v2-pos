import 'package:salespro_admin/model/expense_category_model.dart';
import 'package:salespro_admin/model/income_catehory_model.dart';

import '../services/api_service.dart';

/// Repositorio de categorías de gastos - Usa PostgreSQL API
class ExpenseCategoryRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las categorías de gastos desde PostgreSQL
  Future<List<ExpenseCategoryModel>> getAllExpenseCategory() async {
    try {
      // Usa el endpoint categories/expenses
      final response = await _apiService.get('categories/expenses', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        // La API devuelve 'categories', no 'expense_categories'
        final categoriesData = response.data['categories'] as List<dynamic>? ?? [];

        return categoriesData.map((data) {
          return ExpenseCategoryModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva categoría de gastos
  Future<ExpenseCategoryModel?> createExpenseCategory(ExpenseCategoryModel category) async {
    try {
      final categoryData = Map<String, dynamic>.from(category.toJson());
      // Usa el endpoint categories/expenses
      final response = await _apiService.post('categories/expenses', categoryData);

      if (response.success && response.data != null) {
        return ExpenseCategoryModel.fromJson(response.data['category']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una categoría de gastos
  Future<bool> deleteExpenseCategory(String id) async {
    try {
      // Necesitamos crear endpoint DELETE para categories/expenses
      final response = await _apiService.delete('categories/expenses/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}

/// Repositorio de categorías de ingresos - Usa PostgreSQL API
class IncomeCategoryRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las categorías de ingresos desde PostgreSQL
  Future<List<IncomeCategoryModel>> getAllIncomeCategory() async {
    try {
      // Usa el endpoint categories/incomes
      final response = await _apiService.get('categories/incomes', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        // La API devuelve 'categories', no 'income_categories'
        final categoriesData = response.data['categories'] as List<dynamic>? ?? [];

        return categoriesData.map((data) {
          return IncomeCategoryModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear una nueva categoría de ingresos
  Future<IncomeCategoryModel?> createIncomeCategory(IncomeCategoryModel category) async {
    try {
      final categoryData = Map<String, dynamic>.from(category.toJson());
      // Usa el endpoint categories/incomes
      final response = await _apiService.post('categories/incomes', categoryData);

      if (response.success && response.data != null) {
        return IncomeCategoryModel.fromJson(response.data['category']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una categoría de ingresos
  Future<bool> deleteIncomeCategory(String id) async {
    try {
      final response = await _apiService.delete('categories/incomes/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
