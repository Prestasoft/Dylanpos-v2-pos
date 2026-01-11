import 'package:intl/intl.dart';

import '../model/due_transaction_model.dart';
import '../model/purchase_transation_model.dart';
import '../model/sale_transaction_model.dart';
import '../services/api_service.dart';

/// Repositorio de transacciones de venta - Usa PostgreSQL API
class TransitionRepo {
  final ApiService _apiService = ApiService();

  /// Parsear fecha desde string
  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
    } catch (e) {
      try {
        // Intentar formato ISO
        return DateTime.parse(dateStr);
      } catch (e2) {
        try {
          // Intentar formato dd/MM/yyyy
          return DateFormat('dd/MM/yyyy').parse(dateStr);
        } catch (e3) {
          // Si falla el parseo, devolver fecha mínima
          return DateTime(1970);
        }
      }
    }
  }

  /// Obtener todas las transacciones de venta desde PostgreSQL
  Future<List<SaleTransactionModel>> getAllTransition() async {
    try {
      // Asegurar que el servicio esté inicializado
      if (!_apiService.isAuthenticated) {
        print('[TransitionRepo] Servicio no autenticado, inicializando...');
        await _apiService.init();
      }

      print('[TransitionRepo] Iniciando getSales...');
      print('[TransitionRepo] BranchId actual: ${_apiService.branchId}');
      print('[TransitionRepo] Token presente: ${_apiService.token != null}');

      final response = await _apiService.getSales(limit: 1000);

      print('[TransitionRepo] Response success: ${response.success}');
      print('[TransitionRepo] Response error: ${response.error}');
      print('[TransitionRepo] Response data null: ${response.data == null}');

      if (response.success && response.data != null) {
        final salesData = response.data['sales'] as List<dynamic>? ?? [];
        print('[TransitionRepo] Total sales recibidas: ${salesData.length}');

        final List<SaleTransactionModel> result = [];
        for (int i = 0; i < salesData.length; i++) {
          try {
            final data = salesData[i] as Map<String, dynamic>;
            final sale = SaleTransactionModel.fromJson(data);
            sale.key = data['id']?.toString();
            result.add(sale);
          } catch (e) {
            print('[TransitionRepo] Error parseando venta $i: $e');
          }
        }

        print('[TransitionRepo] Ventas parseadas exitosamente: ${result.length}');

        // Ordenar por fecha de compra descendente (más reciente primero)
        result.sort((a, b) {
          // Primero intentar ordenar por invoiceNumber (número de factura)
          final invA = int.tryParse(a.invoiceNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final invB = int.tryParse(b.invoiceNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (invA != invB) {
            return invB.compareTo(invA); // Descendente
          }

          // Si los números de factura son iguales, ordenar por fecha
          final dateA = _parseDate(a.purchaseDate);
          final dateB = _parseDate(b.purchaseDate);
          return dateB.compareTo(dateA); // Descendente
        });

        return result;
      }
      print('[TransitionRepo] Retornando lista vacía - response no exitosa');
      return [];
    } catch (e) {
      print('[TransitionRepo] Error en getAllTransition: $e');
      rethrow;
    }
  }

  /// Crear una nueva venta
  Future<SaleTransactionModel?> createSale(SaleTransactionModel sale) async {
    try {
      final saleData = Map<String, dynamic>.from(sale.toJson());
      final response = await _apiService.createSale(saleData);

      if (response.success && response.data != null) {
        return SaleTransactionModel.fromJson(response.data['sale']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}

/// Repositorio de transacciones de compra - Usa PostgreSQL API
class PurchaseTransitionRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las transacciones de compra
  Future<List<dynamic>> getAllTransition() async {
    try {
      final response = await _apiService.get('purchases', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final purchasesData = response.data['purchases'] as List<dynamic>? ?? [];

        return purchasesData.map((data) {
          final purchase = PurchaseTransactionModel.fromJson(data as Map<String, dynamic>);
          purchase.key = data['id']?.toString();
          return purchase;
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener todas las transacciones de compra como modelo
  Future<List<PurchaseTransactionModel>> getAllTransitionSingle() async {
    try {
      final response = await _apiService.get('purchases', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final purchasesData = response.data['purchases'] as List<dynamic>? ?? [];

        return purchasesData.map((data) {
          return PurchaseTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

/// Repositorio de transacciones pendientes (deudas) - Usa PostgreSQL API
class DueTransitionRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las transacciones pendientes
  Future<List<DueTransactionModel>> getAllTransition() async {
    try {
      final response = await _apiService.get('due-transactions', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final dueData = response.data['due_transactions'] as List<dynamic>? ?? [];

        return dueData.map((data) {
          return DueTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

/// Repositorio de cotizaciones - Usa PostgreSQL API
class QuotationRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las cotizaciones
  Future<List<SaleTransactionModel>> getAllQuotation() async {
    try {
      final response = await _apiService.get('quotations', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final quotationsData = response.data['quotations'] as List<dynamic>? ?? [];

        return quotationsData.map((data) {
          return SaleTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

/// Repositorio de historial de cotizaciones - Usa PostgreSQL API
class QuotationHistoryRepo {
  final ApiService _apiService = ApiService();

  /// Obtener historial de cotizaciones convertidas
  Future<List<SaleTransactionModel>> getAllQuotationHistory() async {
    try {
      final response = await _apiService.get('quotation-history', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final historyData = response.data['quotation_history'] as List<dynamic>? ?? [];

        return historyData.map((data) {
          return SaleTransactionModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
