import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

/// Script de limpieza para eliminar rastros de facturas huérfanas
/// Ejecutar una sola vez para limpiar facturas 517 y 514
class OrphanInvoiceCleanup {
  
  // CAMBIAR ESTE USER ID POR EL TUYO
  static const String USER_ID = "TU_USER_ID_AQUI";
  
  static Future<void> cleanInvoices() async {
    List<String> invoicesToClean = ["517", "514"];
    
    for (String invoice in invoicesToClean) {
      print('🧹 === LIMPIANDO FACTURA $invoice ===');
      
      await _cleanDueCollections(invoice);
      await _cleanDueTransactions(invoice);
      
      print('✅ === FACTURA $invoice LIMPIADA ===\n');
    }
    
    print('🎉 === LIMPIEZA COMPLETA ===');
  }
  
  static Future<void> _cleanDueCollections(String invoice) async {
    final ref = FirebaseDatabase.instance.ref('$USER_ID/Daily Transaction');
    List<String> keysToDelete = [];

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      for (var entry in data.entries) {
        try {
          final key = entry.key;
          final value = entry.value as Map<dynamic, dynamic>;
          
          if (value['type'] == 'Due Collection' && 
              value['dueTransactionModel'] != null) {
            
            var fieldData = value['dueTransactionModel'];
            if (fieldData is Map && fieldData['invoiceNumber'] == invoice) {
              keysToDelete.add(key);
            }
          }
        } catch (e) {
          print('Error procesando Due Collection: $e');
          continue;
        }
      }
    }

    // Eliminar registros encontrados
    for (String key in keysToDelete) {
      await ref.child(key).remove();
      print('🗑️ Eliminada Due Collection para factura $invoice, key: $key');
    }
    
    print('📊 Total Due Collections eliminadas para factura $invoice: ${keysToDelete.length}');
  }
  
  static Future<void> _cleanDueTransactions(String invoice) async {
    final ref = FirebaseDatabase.instance.ref('$USER_ID/Due Transaction');
    List<String> keysToDelete = [];

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      for (var entry in data.entries) {
        try {
          final key = entry.key;
          final value = entry.value as Map<dynamic, dynamic>;
          
          if (value['invoiceNumber'] == invoice) {
            keysToDelete.add(key);
          }
        } catch (e) {
          print('Error procesando Due Transaction: $e');
          continue;
        }
      }
    }

    // Eliminar registros encontrados
    for (String key in keysToDelete) {
      await ref.child(key).remove();
      print('🗑️ Eliminado Due Transaction para factura $invoice, key: $key');
    }
    
    print('📊 Total Due Transactions eliminados para factura $invoice: ${keysToDelete.length}');
  }
}

// Para ejecutar el script:
void main() async {
  await OrphanInvoiceCleanup.cleanInvoices();
}