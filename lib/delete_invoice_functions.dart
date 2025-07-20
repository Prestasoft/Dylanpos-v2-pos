import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';

import 'const.dart';
import 'model/product_model.dart';
import 'model/sale_transaction_model.dart';

class DeleteInvoice {
  Future<void> editStockAndSerial({
    required SaleTransactionModel saleTransactionModel,
  }) async {
    for (var product in saleTransactionModel.productList!) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');
      String? productPath;

      // Intentar acceso directo primero (más eficiente)
      try {
        final directData = await ref.child(product.productId).get();
        if (directData.exists) {
          productPath = product.productId;
        }
      } catch (e) {
        // Si falla, usar consulta por productCode
        final data = await ref.orderByChild('productCode').equalTo(product.productId).once();
        if (data.snapshot.value != null) {
          final dataMap = Map.from(data.snapshot.value as Map);
          productPath = dataMap.keys.first;
        }
      }

      if (productPath == null) {
        continue; // No se encontró el producto
      }

      // Obtener el stock actual
      var stockSnap = await ref.child('$productPath/productStock').get();
      int currentStock = int.tryParse(stockSnap.value.toString()) ?? 0;
      int updatedStock = currentStock + int.tryParse(product.quantity.toString())!;

      // Actualizar el stock
      await ref.child(productPath).update({'productStock': '$updatedStock'});

      /// Agregar los números de serie nuevamente
      ProductModel? productData;
      final serialRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/$productPath');

      await serialRef.orderByKey().get().then((value) {
        productData = ProductModel.fromJson(jsonDecode(jsonEncode(value.value)));
      });

      for (var serial in product.serialNumber ?? []) {
        if (!productData!.serialNumber.contains(serial)) {
          productData!.serialNumber.add(serial);
        }
      }

      await serialRef.child('serialNumber').set(productData!.serialNumber);
    }
  }

  Future<void> editStockAndSerialForPurchase({required PurchaseTransactionModel saleTransactionModel}) async {
    for (var element in saleTransactionModel.productList!) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');
      String? productPath;

      // Intentar acceso directo primero (más eficiente)
      try {
        final directData = await ref.child(element.productCode).get();
        if (directData.exists) {
          productPath = element.productCode;
        }
      } catch (e) {
        // Si falla, usar consulta por productCode
        final data = await ref.orderByChild('productCode').equalTo(element.productCode).once();
        if (data.snapshot.value != null) {
          final dataMap = Map.from(data.snapshot.value as Map);
          productPath = dataMap.keys.first;
        }
      }

      if (productPath == null) {
        continue; // No se encontró el producto
      }

      var data1 = await ref.child('$productPath/productStock').get();
      int stock = int.parse(data1.value.toString());
      int remainStock = stock - int.parse(element.productStock.toString());

      await ref.child(productPath).update({'productStock': '$remainStock'});

      ///_____serial_remove________________________________
      ProductModel? productData;

      final serialRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/$productPath');
      await serialRef.orderByKey().get().then((value) {
        productData = ProductModel.fromJson(jsonDecode(jsonEncode(value.value)));
      });

      for (var serial in element.serialNumber) {
        productData!.serialNumber.remove(serial);
      }

      await serialRef.child('serialNumber').set(productData!.serialNumber.map((e) => e).toList());
    }
  }

  Future<void> customerDueUpdate({required String phone, required num due}) async {
    if (due > 0) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
      String? key;

      await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
        for (var element in value.children) {
          try {
            var data = jsonDecode(jsonEncode(element.value));
            
            // Validación null-safe
            if (data == null) continue;
            if (data['phoneNumber'] == null) continue;
            
            if (data['phoneNumber'] == phone) {
              key = element.key;
              break; // Salir del loop una vez encontrado
            }
          } catch (e) {
            // Si hay error al procesar este elemento, continuar con el siguiente
            print('Error processing customer element: $e');
            continue;
          }
        }
      });
      
      if (key == null) {
        print('Customer not found with phone: $phone');
        return; // Salir si no se encuentra el cliente
      }
      
      var data1 = await ref.child('$key/due').get();
      int previousDue = int.tryParse(data1.value?.toString() ?? '0') ?? 0;

      int totalDue = previousDue - due.toInt();
      await ref.child(key!).update({'due': '$totalDue'});
    }
  }

  Future<void> updateFromShopRemainBalance({required num paidAmount, required bool isFromPurchase}) async {
    if (paidAmount > 0) {
      final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Personal Information');
      var data1 = await ref.child("remainingShopBalance").get();
      num previousBalance = data1.value.toString().toInt();
      await ref.update({'remainingShopBalance': isFromPurchase ? previousBalance + paidAmount : previousBalance - paidAmount});
    }
  }

  Future<void> deleteDailyTransaction({required String invoice, required String status, required String field}) async {
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Daily Transaction');
    String? key;

    await FirebaseDatabase.instance.ref(await getUserID()).child('Daily Transaction').orderByKey().get().then((value) {
      for (var element in value.children) {
        try {
          var data = jsonDecode(jsonEncode(element.value));
          
          // Validaciones null-safe
          if (data == null) continue;
          if (data['type'] != status) continue;
          
          // Verificar que el campo existe y no es null
          if (data[field] == null) continue;
          
          // Verificar que invoiceNumber existe en el subcampo
          var fieldData = data[field];
          if (fieldData is Map && fieldData['invoiceNumber'] == invoice) {
            key = element.key;
            break; // Salir del loop una vez encontrado
          }
        } catch (e) {
          // Si hay error al procesar este elemento, continuar con el siguiente
          print('Error processing transaction element: $e');
          continue;
        }
      }
    });
    if (key == null) {
      log('No transaction found for invoice: $invoice with status: $status');
      return;
    }
    await ref.child(key!).remove();
  }

  // NUEVO: Función para eliminar TODAS las transacciones Due Collection de una factura
  Future<void> deleteAllDueCollections({required String invoice}) async {
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Daily Transaction');
    List<String> keysToDelete = [];

    await FirebaseDatabase.instance.ref(await getUserID()).child('Daily Transaction').orderByKey().get().then((value) {
      for (var element in value.children) {
        try {
          var data = jsonDecode(jsonEncode(element.value));
          
          // Validaciones null-safe
          if (data == null) continue;
          if (data['type'] != 'Due Collection') continue;
          if (data['dueTransactionModel'] == null) continue;
          
          // Verificar que invoiceNumber coincide
          var fieldData = data['dueTransactionModel'];
          if (fieldData is Map && fieldData['invoiceNumber'] == invoice) {
            keysToDelete.add(element.key!);
          }
        } catch (e) {
          print('Error processing Due Collection element: $e');
          continue;
        }
      }
    });

    // Eliminar todas las transacciones encontradas
    for (String key in keysToDelete) {
      await ref.child(key).remove();
      print('🗑️ Eliminada Due Collection para factura $invoice, key: $key');
    }
    
    print('🗑️ Total Due Collections eliminadas para factura $invoice: ${keysToDelete.length}');
  }

  // NUEVO: Función para eliminar TODOS los registros Due Transaction de una factura
  Future<void> deleteAllDueTransactions({required String invoice}) async {
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Due Transaction');
    List<String> keysToDelete = [];

    await FirebaseDatabase.instance.ref(await getUserID()).child('Due Transaction').orderByKey().get().then((value) {
      for (var element in value.children) {
        try {
          var data = jsonDecode(jsonEncode(element.value));
          
          // Validaciones null-safe
          if (data == null) continue;
          if (data['invoiceNumber'] != invoice) continue;
          
          keysToDelete.add(element.key!);
        } catch (e) {
          print('Error processing Due Transaction element: $e');
          continue;
        }
      }
    });

    // Eliminar todos los registros encontrados
    for (String key in keysToDelete) {
      await ref.child(key).remove();
      print('🗑️ Eliminado Due Transaction para factura $invoice, key: $key');
    }
    
    print('🗑️ Total Due Transactions eliminados para factura $invoice: ${keysToDelete.length}');
  }

  // NUEVO: Función para limpiar facturas huérfanas (que ya no existen en Sales pero siguen en Daily)
  Future<void> cleanOrphanInvoicePayments({required String invoice}) async {
    print('🧹 === LIMPIEZA DE FACTURA HUÉRFANA $invoice ===');
    
    // Eliminar Due Collections
    await deleteAllDueCollections(invoice: invoice);
    
    // Eliminar Due Transactions  
    await deleteAllDueTransactions(invoice: invoice);
    
    print('🧹 === LIMPIEZA COMPLETA DE FACTURA $invoice ===');
  }

  // NUEVO: Función para corregir saldos negativos en clientes
  Future<void> fixNegativeCustomerBalances() async {
    print('🔧 === INICIANDO CORRECCIÓN DE SALDOS NEGATIVOS ===');
    
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
    List<Map<String, dynamic>> customersToFix = [];
    
    // Buscar clientes con saldos negativos
    await ref.orderByKey().get().then((value) {
      for (var element in value.children) {
        try {
          var data = jsonDecode(jsonEncode(element.value));
          
          if (data == null) continue;
          
          int dueAmount = int.tryParse(data['due']?.toString() ?? '0') ?? 0;
          
          if (dueAmount < 0) {
            customersToFix.add({
              'key': element.key,
              'name': data['customerName'] ?? 'Sin nombre',
              'phone': data['phoneNumber'] ?? 'Sin teléfono',
              'negativeDue': dueAmount,
            });
          }
        } catch (e) {
          print('Error procesando cliente: $e');
          continue;
        }
      }
    });
    
    print('📊 Clientes con saldos negativos encontrados: ${customersToFix.length}');
    
    // Corregir cada cliente
    int correctedCount = 0;
    for (var customer in customersToFix) {
      try {
        await ref.child(customer['key']).update({'due': '0'});
        print('✅ Corregido: ${customer['name']} (${customer['phone']}) - Era: ${customer['negativeDue']} → Ahora: 0');
        correctedCount++;
      } catch (e) {
        print('❌ Error corrigiendo ${customer['name']}: $e');
      }
    }
    
    print('🎉 === CORRECCIÓN COMPLETA: $correctedCount clientes corregidos ===');
  }

  // NUEVO: Función para corregir un cliente específico por teléfono
  Future<void> fixSpecificCustomer({required String phone, required int correctAmount}) async {
    print('🔧 Corrigiendo cliente específico: $phone');
    
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
    String? key;

    await ref.orderByKey().get().then((value) {
      for (var element in value.children) {
        try {
          var data = jsonDecode(jsonEncode(element.value));
          
          if (data == null) continue;
          if (data['phoneNumber'] == phone) {
            key = element.key;
            break;
          }
        } catch (e) {
          print('Error processing customer element: $e');
          continue;
        }
      }
    });
    
    if (key == null) {
      print('❌ Cliente no encontrado con teléfono: $phone');
      return;
    }
    
    var data1 = await ref.child('$key/due').get();
    int previousDue = int.tryParse(data1.value?.toString() ?? '0') ?? 0;
    
    await ref.child(key!).update({'due': '$correctAmount'});
    print('✅ Cliente $phone corregido: $previousDue → $correctAmount');
  }
}
