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
      print('🔍 [deleteDailyTransaction] Buscando transacciones tipo: $status, invoice: $invoice');

      // ESTRATEGIA: Buscar primero con invoiceNumber en query, si no encuentra, buscar por tipo y filtrar
      var response = await _apiService.get('daily-transactions', queryParams: {
        'type': status,
        'invoiceNumber': invoice,
        'limit': '100',
      });

      var transactions = <dynamic>[];

      if (response.success && response.data != null) {
        transactions = response.data['daily_transactions'] as List<dynamic>? ??
                       response.data['transactions'] as List<dynamic>? ?? [];
      }

      print('🔍 [deleteDailyTransaction] Búsqueda con invoiceNumber encontró: ${transactions.length}');

      // Si no encontró nada, buscar solo por tipo y filtrar manualmente
      if (transactions.isEmpty) {
        print('🔍 [deleteDailyTransaction] Buscando solo por tipo: $status');
        response = await _apiService.get('daily-transactions', queryParams: {
          'type': status,
          'limit': '500',  // Traer más para encontrar la transacción
        });

        if (response.success && response.data != null) {
          transactions = response.data['daily_transactions'] as List<dynamic>? ??
                         response.data['transactions'] as List<dynamic>? ?? [];
        }
        print('🔍 [deleteDailyTransaction] Búsqueda por tipo encontró: ${transactions.length} transacciones totales');
      }

      int deletedCount = 0;
      for (var transaction in transactions) {
        try {
          final transactionData = Map<String, dynamic>.from(transaction);
          final transactionId = transactionData['id']?.toString();

          if (transactionId != null) {
            // Verificar que el invoice coincide - buscar en MÚLTIPLES ubicaciones
            final rootInvoice = transactionData['invoiceNumber']?.toString() ??
                               transactionData['invoice_number']?.toString();

            // Buscar en el campo específico (ej: saleTransactionModel)
            final fieldData = transactionData[field];
            final fieldInvoice = fieldData is Map
                ? (fieldData['invoiceNumber']?.toString() ?? fieldData['invoice_number']?.toString())
                : null;

            // Buscar en el campo 'data' (donde se almacenan los datos extra)
            final dataField = transactionData['data'];
            String? dataInvoice;
            String? dataNestedInvoice;
            if (dataField is Map) {
              dataInvoice = dataField['invoiceNumber']?.toString() ?? dataField['invoice_number']?.toString();
              // También buscar dentro de saleTransactionModel en data
              final nestedModel = dataField['saleTransactionModel'] ?? dataField['sale_transaction_model'];
              if (nestedModel is Map) {
                dataNestedInvoice = nestedModel['invoiceNumber']?.toString() ?? nestedModel['invoice_number']?.toString();
              }
            }

            // También buscar en firebase_id (que a veces contiene el invoice number)
            final firebaseId = transactionData['firebase_id']?.toString();

            // Eliminar si coincide el invoice en CUALQUIER ubicación
            if (rootInvoice == invoice ||
                fieldInvoice == invoice ||
                dataInvoice == invoice ||
                dataNestedInvoice == invoice ||
                firebaseId == invoice) {
              print('🗑️ Eliminando daily_transaction $transactionId con invoice: $invoice');
              await _apiService.delete('daily-transactions/$transactionId');
              deletedCount++;
            }
          }
        } catch (e) {
          print('Error procesando transacción: $e');
          continue;
        }
      }

      print('✅ [deleteDailyTransaction] Eliminadas $deletedCount transacciones para invoice: $invoice');
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

  /// LIMPIEZA: Eliminar transacciones huérfanas de facturas ya eliminadas
  /// Esta función busca todos los registros "Deleted" y elimina las transacciones
  /// de tipo Sale/Adicionales/Impresiones que tengan el mismo invoiceNumber
  Future<Map<String, int>> cleanOrphanDailyTransactions() async {
    print('🧹 === INICIANDO LIMPIEZA DE TRANSACCIONES HUÉRFANAS ===');

    int deletedSales = 0;
    int deletedDueCollections = 0;
    int deletedDueTransactions = 0;
    List<String> cleanedInvoices = [];

    try {
      // Paso 1: Obtener todos los registros de tipo "Deleted"
      final deletedResponse = await _apiService.get('daily-transactions', queryParams: {
        'type': 'Deleted',
        'limit': '1000',
      });

      if (!deletedResponse.success || deletedResponse.data == null) {
        print('⚠️ No se encontraron registros de facturas eliminadas');
        return {'sales': 0, 'dueCollections': 0, 'dueTransactions': 0};
      }

      final deletedTransactions = deletedResponse.data['daily_transactions'] as List<dynamic>? ?? [];
      print('📋 Encontradas ${deletedTransactions.length} facturas marcadas como eliminadas');

      // Paso 2: Extraer todos los invoiceNumbers de las facturas eliminadas
      Set<String> deletedInvoiceNumbers = {};
      for (var deleted in deletedTransactions) {
        final data = Map<String, dynamic>.from(deleted);

        // Buscar invoiceNumber en múltiples ubicaciones
        String? invoiceNum = data['invoiceNumber']?.toString() ??
                            data['invoice_number']?.toString();

        // Buscar en firebase_id
        if (invoiceNum == null || invoiceNum.isEmpty) {
          invoiceNum = data['firebase_id']?.toString();
        }

        // Buscar en campo data
        if ((invoiceNum == null || invoiceNum.isEmpty) && data['data'] is Map) {
          final dataField = data['data'] as Map;
          invoiceNum = dataField['invoiceNumber']?.toString() ??
                      dataField['invoice_number']?.toString();

          // Buscar en saleTransactionModel dentro de data
          if ((invoiceNum == null || invoiceNum.isEmpty) && dataField['saleTransactionModel'] is Map) {
            final saleModel = dataField['saleTransactionModel'] as Map;
            invoiceNum = saleModel['invoiceNumber']?.toString() ??
                        saleModel['invoice_number']?.toString();
          }
        }

        if (invoiceNum != null && invoiceNum.isNotEmpty) {
          deletedInvoiceNumbers.add(invoiceNum);
        }
      }

      print('🔍 Invoice numbers de facturas eliminadas: $deletedInvoiceNumbers');

      // Paso 3: Para cada tipo de transacción (Sale, Adicionales, Impresiones, Reserva),
      // buscar y eliminar las que tengan invoiceNumber en la lista de eliminadas
      for (String type in ['Sale', 'Adicionales', 'Impresiones', 'Reserva']) {
        print('🔍 Buscando transacciones huérfanas tipo: $type');

        final typeResponse = await _apiService.get('daily-transactions', queryParams: {
          'type': type,
          'limit': '1000',
        });

        if (!typeResponse.success || typeResponse.data == null) continue;

        final transactions = typeResponse.data['daily_transactions'] as List<dynamic>? ?? [];
        print('📋 Encontradas ${transactions.length} transacciones tipo $type');

        for (var transaction in transactions) {
          final transData = Map<String, dynamic>.from(transaction);
          final transactionId = transData['id']?.toString();

          // Extraer invoiceNumber de la transacción
          String? transInvoice = transData['invoiceNumber']?.toString() ??
                                transData['invoice_number']?.toString() ??
                                transData['firebase_id']?.toString();

          // Buscar en campo data
          if ((transInvoice == null || transInvoice.isEmpty) && transData['data'] is Map) {
            final dataField = transData['data'] as Map;
            transInvoice = dataField['invoiceNumber']?.toString() ??
                          dataField['invoice_number']?.toString();

            if ((transInvoice == null || transInvoice.isEmpty) && dataField['saleTransactionModel'] is Map) {
              final saleModel = dataField['saleTransactionModel'] as Map;
              transInvoice = saleModel['invoiceNumber']?.toString() ??
                            saleModel['invoice_number']?.toString();
            }
          }

          // Si el invoiceNumber está en la lista de eliminadas, eliminar esta transacción
          if (transInvoice != null && deletedInvoiceNumbers.contains(transInvoice) && transactionId != null) {
            print('🗑️ Eliminando transacción huérfana tipo $type, invoice: $transInvoice, id: $transactionId');
            await _apiService.delete('daily-transactions/$transactionId');
            deletedSales++;
            cleanedInvoices.add(transInvoice);
          }
        }
      }

      // Paso 4: También limpiar Due Collections y Due Transactions huérfanas
      for (String invoiceNum in deletedInvoiceNumbers) {
        // Limpiar Due Collections
        final dueCollResponse = await _apiService.get('daily-transactions', queryParams: {
          'type': 'Due Collection',
          'limit': '100',
        });

        if (dueCollResponse.success && dueCollResponse.data != null) {
          final dueColl = dueCollResponse.data['daily_transactions'] as List<dynamic>? ?? [];
          for (var dc in dueColl) {
            final dcData = Map<String, dynamic>.from(dc);
            final dcId = dcData['id']?.toString();

            // Verificar si corresponde a la factura eliminada
            String? dcInvoice;
            if (dcData['data'] is Map) {
              final dataField = dcData['data'] as Map;
              if (dataField['dueTransactionModel'] is Map) {
                dcInvoice = (dataField['dueTransactionModel'] as Map)['invoiceNumber']?.toString();
              }
            }

            if (dcInvoice == invoiceNum && dcId != null) {
              print('🗑️ Eliminando Due Collection huérfana, invoice: $invoiceNum');
              await _apiService.delete('daily-transactions/$dcId');
              deletedDueCollections++;
            }
          }
        }
      }

      print('🧹 === LIMPIEZA COMPLETADA ===');
      print('✅ Transacciones de venta eliminadas: $deletedSales');
      print('✅ Due Collections eliminadas: $deletedDueCollections');
      print('✅ Due Transactions eliminadas: $deletedDueTransactions');
      print('📋 Facturas limpiadas: ${cleanedInvoices.toSet().toList()}');

      return {
        'sales': deletedSales,
        'dueCollections': deletedDueCollections,
        'dueTransactions': deletedDueTransactions,
      };
    } catch (e) {
      print('❌ Error en cleanOrphanDailyTransactions: $e');
      return {'sales': deletedSales, 'dueCollections': deletedDueCollections, 'dueTransactions': deletedDueTransactions};
    }
  }
}
