import '../model/income_modle.dart';
import '../services/api_service.dart';

/// Repositorio de ingresos - Usa PostgreSQL API
class IncomeRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los ingresos desde PostgreSQL
  Future<List<IncomeModel>> getAllIncome() async {
    try {
      final response = await _apiService.get('income', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final incomeData = response.data['income'] as List<dynamic>? ?? [];

        return incomeData.map((data) {
          return IncomeModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Crear un nuevo ingreso
  Future<IncomeModel?> createIncome(IncomeModel income) async {
    try {
      final incomeData = Map<String, dynamic>.from(income.toJson());
      final response = await _apiService.post('income', incomeData);

      if (response.success && response.data != null) {
        return IncomeModel.fromJson(response.data['income']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar un ingreso existente
  Future<IncomeModel?> updateIncome(String id, IncomeModel income) async {
    try {
      final incomeData = Map<String, dynamic>.from(income.toJson());
      final response = await _apiService.put('income/$id', incomeData);

      if (response.success && response.data != null) {
        return IncomeModel.fromJson(response.data['income']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar un ingreso
  Future<bool> deleteIncome(String id) async {
    try {
      final response = await _apiService.delete('income/$id');
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}
