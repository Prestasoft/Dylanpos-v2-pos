// delete_invoice_functions.dart - Migrado a PostgreSQL API
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';

import 'model/sale_transaction_model.dart';
import 'services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

class DeleteInvoice {
  /// Editar stock y serial para ventas - Usa PostgreSQL API
  Future<void> editStockAndSerial({
    required SaleTransactionModel saleTransactionModel,
  }) async {
    for (var product in saleTransactionModel.productList!) {
      try {
        // Obtener producto actual
        final response = await _apiService.get('products/${product.productId}');

        if (!response.success || response.data == null) {
          // Buscar por código de producto
          final searchResponse = await _apiService.get('products', queryParams: {
            'productCode': product.productId,
            'limit': '1',
          });

          if (!searchResponse.success || searchResponse.data == null) {
            continue;
          }

          final products = searchResponse.data['products'] as List<dynamic>? ?? [];
          if (products.isEmpty) continue;

          final productData = Map<String, dynamic>.from(products.first);
          final productId = productData['id']?.toString();
          if (productId == null) continue;

          // Actualizar stock
          int currentStock = int.tryParse(productData['productStock']?.toString() ?? '0') ?? 0;
          int updatedStock = currentStock + int.tryParse(product.quantity.toString())!;

          // Actualizar serial numbers
          List<dynamic> serialNumbers = productData['serialNumber'] as List<dynamic>? ?? [];
          for (var serial in product.serialNumber ?? []) {
            if (!serialNumbers.contains(serial)) {
              serialNumbers.add(serial);
            }
          }

          await _apiService.put('products/$productId', {
            'productStock': updatedStock.toString(),
            'serialNumber': serialNumbers,
          });
        } else {
          final productData = response.data['product'] ?? response.data;
          final productId = productData['id']?.toString() ?? product.productId;

          int currentStock = int.tryParse(productData['productStock']?.toString() ?? '0') ?? 0;
          int updatedStock = currentStock + int.tryParse(product.quantity.toString())!;

          List<dynamic> serialNumbers = productData['serialNumber'] as List<dynamic>? ?? [];
          for (var serial in product.serialNumber ?? []) {
            if (!serialNumbers.contains(serial)) {
              serialNumbers.add(serial);
            }
          }

          await _apiService.put('products/$productId', {
            'productStock': updatedStock.toString(),
            'serialNumber': serialNumbers,
          });
        }
      } catch (e) {
        print('Error actualizando stock para producto ${product.productId}: $e');
        continue;
      }
    }
  }

  /// Editar stock y serial para compras - Usa PostgreSQL API
  Future<void> editStockAndSerialForPurchase({required PurchaseTransactionModel saleTransactionModel}) async {
    for (var element in saleTransactionModel.productList!) {
      try {
        // Buscar producto por código
        final searchResponse = await _apiService.get('products', queryParams: {
          'productCode': element.productCode,
          'limit': '1',
        });

        if (!searchResponse.success || searchResponse.data == null) {
          continue;
        }

        final products = searchResponse.data['products'] as List<dynamic>? ?? [];
        if (products.isEmpty) continue;

        final productData = Map<String, dynamic>.from(products.first);
        final productId = productData['id']?.toString();
        if (productId == null) continue;

        int currentStock = int.tryParse(productData['productStock']?.toString() ?? '0') ?? 0;
        int remainStock = currentStock - int.parse(element.productStock.toString());

        // Remover serial numbers
        List<dynamic> serialNumbers = List.from(productData['serialNumber'] as List<dynamic>? ?? []);
        for (var serial in element.serialNumber) {
          serialNumbers.remove(serial);
        }

        await _apiService.put('products/$productId', {
          'productStock': remainStock.toString(),
          'serialNumber': serialNumbers,
        });
      } catch (e) {
        print('Error actualizando stock para producto ${element.productCode}: $e');
        continue;
      }
    }
  }

  /// Actualizar deuda del cliente - Usa PostgreSQL API
  Future<void> customerDueUpdate({required String phone, required num due}) async {
    if (due > 0) {
      try {
        // Buscar cliente por teléfono
        final searchResponse = await _apiService.get('customers', queryParams: {
          'phoneNumber': phone,
          'limit': '1',
        });

        if (!searchResponse.success || searchResponse.data == null) {
          print('Customer not found with phone: $phone');
          return;
        }

        final customers = searchResponse.data['customers'] as List<dynamic>? ?? [];
        if (customers.isEmpty) {
          print('Customer not found with phone: $phone');
          return;
        }

        final customerData = Map<String, dynamic>.from(customers.first);
        final customerId = customerData['id']?.toString();
        if (customerId == null) return;

        int previousDue = int.tryParse(customerData['due']?.toString() ?? '0') ?? 0;
        int totalDue = previousDue - due.toInt();

        await _apiService.put('customers/$customerId', {
          'due': totalDue.toString(),
        });
      } catch (e) {
        print('Error actualizando deuda del cliente: $e');
      }
    }
  }

  /// Actualizar balance de la tienda - Usa PostgreSQL API
  Future<void> updateFromShopRemainBalance({required num paidAmount, required bool isFromPurchase}) async {
    if (paidAmount > 0) {
      try {
        final response = await _apiService.get('settings/personal-information');

        if (response.success && response.data != null) {
          final data = response.data['personalInformation'] ?? response.data;
          num previousBalance = num.tryParse(data['remainingShopBalance']?.toString() ?? '0') ?? 0;
          num newBalance = isFromPurchase ? previousBalance + paidAmount : previousBalance - paidAmount;

          await _apiService.put('settings/personal-information', {
            'remainingShopBalance': newBalance,
          });
        }
      } catch (e) {
        print('Error actualizando balance de tienda: $e');
      }
    }
  }

  /// Eliminar transacción diaria - Usa PostgreSQL API
  Future<void> deleteDailyTransaction({required String invoice, required String status, required String field}) async {
    try {
      // Buscar transacción por invoice y tipo
      final response = await _apiService.get('daily-transactions', queryParams: {
        'type': status,
        'invoiceNumber': invoice,
        'limit': '100',
      });

      if (!response.success || response.data == null) {
        log('No transaction found for invoice: $invoice with status: $status');
        return;
      }

      final transactions = response.data['daily_transactions'] as List<dynamic>? ??
                          response.data['transactions'] as List<dynamic>? ?? [];

      for (var transaction in transactions) {
        try {
          final transactionData = Map<String, dynamic>.from(transaction);
          final transactionId = transactionData['id']?.toString();

          if (transactionId != null) {
            // Verificar que el campo coincide
            final fieldData = transactionData[field];
            if (fieldData is Map && fieldData['invoiceNumber'] == invoice) {
              await _apiService.delete('daily-transactions/$transactionId');
            }
          }
        } catch (e) {
          print('Error procesando transacción: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error eliminando transacción diaria: $e');
    }
  }

  /// Eliminar todas las Due Collections de una factura - Usa PostgreSQL API
  Future<void> deleteAllDueCollections({required String invoice}) async {
    try {
      final response = await _apiService.get('daily-transactions', queryParams: {
        'type': 'Due Collection',
        'invoiceNumber': invoice,
        'limit': '1000',
      });

      if (!response.success || response.data == null) {
        return;
      }

      final transactions = response.data['daily_transactions'] as List<dynamic>? ??
                          response.data['transactions'] as List<dynamic>? ?? [];

      int deletedCount = 0;
      for (var transaction in transactions) {
        try {
          final transactionData = Map<String, dynamic>.from(transaction);
          final transactionId = transactionData['id']?.toString();
          final transactionType = transactionData['type']?.toString() ?? '';

          // CRÍTICO: NO eliminar registros de tipo 'Deleted' - estos son tracking de eliminaciones
          if (transactionType.toLowerCase() == 'deleted') {
            print('⚠️ Saltando registro Deleted (tracking) - id: $transactionId');
            continue;
          }

          if (transactionId != null) {
            await _apiService.delete('daily-transactions/$transactionId');
            print('🗑️ Eliminada Due Collection para factura $invoice, id: $transactionId');
            deletedCount++;
          }
        } catch (e) {
          print('Error eliminando Due Collection: $e');
          continue;
        }
      }

      print('🗑️ Total Due Collections eliminadas para factura $invoice: $deletedCount');
    } catch (e) {
      print('Error en deleteAllDueCollections: $e');
    }
  }

  /// Eliminar todos los Due Transactions de una factura - Usa PostgreSQL API
  Future<void> deleteAllDueTransactions({required String invoice}) async {
    try {
      final response = await _apiService.get('due-transactions', queryParams: {
        'invoiceNumber': invoice,
        'limit': '1000',
      });

      if (!response.success || response.data == null) {
        return;
      }

      final transactions = response.data['due_transactions'] as List<dynamic>? ??
                          response.data['transactions'] as List<dynamic>? ?? [];

      int deletedCount = 0;
      for (var transaction in transactions) {
        try {
          final transactionData = Map<String, dynamic>.from(transaction);
          final transactionId = transactionData['id']?.toString();

          if (transactionId != null) {
            await _apiService.delete('due-transactions/$transactionId');
            print('🗑️ Eliminado Due Transaction para factura $invoice, id: $transactionId');
            deletedCount++;
          }
        } catch (e) {
          print('Error eliminando Due Transaction: $e');
          continue;
        }
      }

      print('🗑️ Total Due Transactions eliminados para factura $invoice: $deletedCount');
    } catch (e) {
      print('Error en deleteAllDueTransactions: $e');
    }
  }

  /// Limpiar facturas huérfanas - Usa PostgreSQL API
  Future<void> cleanOrphanInvoicePayments({required String invoice}) async {
    print('🧹 === LIMPIEZA DE FACTURA HUÉRFANA $invoice ===');

    // Eliminar Due Collections
    await deleteAllDueCollections(invoice: invoice);

    // Eliminar Due Transactions
    await deleteAllDueTransactions(invoice: invoice);

    print('🧹 === LIMPIEZA COMPLETA DE FACTURA $invoice ===');
  }

  /// Corregir saldos negativos en clientes - Usa PostgreSQL API
  Future<void> fixNegativeCustomerBalances() async {
    print('🔧 === INICIANDO CORRECCIÓN DE SALDOS NEGATIVOS ===');

    try {
      final response = await _apiService.get('customers', queryParams: {'limit': '5000'});

      if (!response.success || response.data == null) {
        print('❌ Error obteniendo clientes');
        return;
      }

      final customers = response.data['customers'] as List<dynamic>? ?? [];
      List<Map<String, dynamic>> customersToFix = [];

      for (var customer in customers) {
        try {
          final customerData = Map<String, dynamic>.from(customer);
          int dueAmount = int.tryParse(customerData['due']?.toString() ?? '0') ?? 0;

          if (dueAmount < 0) {
            customersToFix.add({
              'id': customerData['id']?.toString(),
              'name': customerData['customerName'] ?? 'Sin nombre',
              'phone': customerData['phoneNumber'] ?? 'Sin teléfono',
              'negativeDue': dueAmount,
            });
          }
        } catch (e) {
          print('Error procesando cliente: $e');
          continue;
        }
      }

      print('📊 Clientes con saldos negativos encontrados: ${customersToFix.length}');

      int correctedCount = 0;
      for (var customer in customersToFix) {
        try {
          if (customer['id'] != null) {
            await _apiService.put('customers/${customer['id']}', {'due': '0'});
            print('✅ Corregido: ${customer['name']} (${customer['phone']}) - Era: ${customer['negativeDue']} → Ahora: 0');
            correctedCount++;
          }
        } catch (e) {
          print('❌ Error corrigiendo ${customer['name']}: $e');
        }
      }

      print('🎉 === CORRECCIÓN COMPLETA: $correctedCount clientes corregidos ===');
    } catch (e) {
      print('Error en fixNegativeCustomerBalances: $e');
    }
  }

  /// Corregir un cliente específico por teléfono - Usa PostgreSQL API
  Future<void> fixSpecificCustomer({required String phone, required int correctAmount}) async {
    print('🔧 Corrigiendo cliente específico: $phone');

    try {
      final searchResponse = await _apiService.get('customers', queryParams: {
        'phoneNumber': phone,
        'limit': '1',
      });

      if (!searchResponse.success || searchResponse.data == null) {
        print('❌ Cliente no encontrado con teléfono: $phone');
        return;
      }

      final customers = searchResponse.data['customers'] as List<dynamic>? ?? [];
      if (customers.isEmpty) {
        print('❌ Cliente no encontrado con teléfono: $phone');
        return;
      }

      final customerData = Map<String, dynamic>.from(customers.first);
      final customerId = customerData['id']?.toString();
      if (customerId == null) {
        print('❌ ID de cliente no encontrado');
        return;
      }

      int previousDue = int.tryParse(customerData['due']?.toString() ?? '0') ?? 0;

      await _apiService.put('customers/$customerId', {'due': correctAmount.toString()});
      print('✅ Cliente $phone corregido: $previousDue → $correctAmount');
    } catch (e) {
      print('Error en fixSpecificCustomer: $e');
    }
  }
}
