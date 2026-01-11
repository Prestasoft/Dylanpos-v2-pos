import 'dart:async';
import '../model/bank_model.dart';
import '../services/api_service.dart';

/// Repositorio de bancos - Usa PostgreSQL API
class BankRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todos los bancos activos desde PostgreSQL
  Future<List<BankModel>> getAllBanks() async {
    try {
      final response = await _apiService.get('banks', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        final banksData = response.data['banks'] as List<dynamic>? ?? [];
        final banks = <BankModel>[];

        for (var data in banksData) {
          if (data is Map<String, dynamic>) {
            final isActive = data['isActive'] ?? true;
            if (isActive) {
              final bank = BankModel.fromJson(data);
              bank.bankId = data['id']?.toString();
              banks.add(bank);
            }
          }
        }

        // Ordenar por nombre
        banks.sort((a, b) => (a.bankName ?? '').compareTo(b.bankName ?? ''));
        return banks;
      }
      return [];
    } catch (e) {
      print('Error getting banks: $e');
      return [];
    }
  }

  /// Stream de bancos (simulado para compatibilidad)
  Stream<List<BankModel>> getBanksStream() {
    // Crear un StreamController para emitir actualizaciones
    final controller = StreamController<List<BankModel>>();

    // Obtener datos iniciales
    getAllBanks().then((banks) {
      controller.add(banks);
    }).catchError((e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  /// Obtener un banco por ID
  Future<BankModel?> getBankById(String bankId) async {
    try {
      final response = await _apiService.get('banks/$bankId');

      if (response.success && response.data != null) {
        final bank = BankModel.fromJson(response.data['bank']);
        bank.bankId = bankId;
        return bank;
      }
      return null;
    } catch (e) {
      print('Error getting bank: $e');
      return null;
    }
  }

  /// Agregar un nuevo banco
  Future<String> addBank(BankModel bank) async {
    try {
      bank.createdAt = DateTime.now();
      bank.updatedAt = DateTime.now();

      final bankData = Map<String, dynamic>.from(bank.toJson());
      final response = await _apiService.post('banks', bankData);

      if (response.success && response.data != null) {
        return response.data['bank']['id']?.toString() ?? '';
      }
      throw Exception('Error creating bank');
    } catch (e) {
      print('Error adding bank: $e');
      rethrow;
    }
  }

  /// Actualizar un banco existente
  Future<void> updateBank(BankModel bank) async {
    try {
      bank.updatedAt = DateTime.now();
      final bankData = Map<String, dynamic>.from(bank.toJson());
      await _apiService.put('banks/${bank.bankId}', bankData);
    } catch (e) {
      print('Error updating bank: $e');
      rethrow;
    }
  }

  /// Eliminar un banco (hard delete)
  Future<void> deleteBank(String bankId) async {
    try {
      await _apiService.delete('banks/$bankId');
    } catch (e) {
      print('Error deleting bank: $e');
      rethrow;
    }
  }

  /// Verificar si existe un banco con el mismo nombre
  Future<bool> isBankNameExists(String bankName, {String? excludeBankId}) async {
    try {
      final banks = await getAllBanks();
      return banks.any((bank) =>
        bank.bankName?.toLowerCase() == bankName.toLowerCase() &&
        bank.bankId != excludeBankId
      );
    } catch (e) {
      print('Error checking bank name: $e');
      return false;
    }
  }
}
