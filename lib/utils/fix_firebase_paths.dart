// /lib/utils/fix_firebase_paths.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:salespro_admin/model/daily_transaction_model.dart';
import 'package:salespro_admin/utils/firebase_key_util.dart';

import '../const.dart';

// Esta función corrige cualquier camino en Firebase que use fechas no sanitizadas
class FirebasePathFixer {
  static Future<void> ensureSafePaths() async {
    // Obtener UserID una sola vez
    final userId = await getUserID();

    // Sanitizar DailyTransaction
    await _sanitizeDailyTransactions(userId);
  }

  // Sanitiza las transacciones diarias
  static Future<void> _sanitizeDailyTransactions(String userId) async {
    try {
      final dailyTransactionRef = FirebaseDatabase.instance.ref('$userId/Daily Transaction');
      final snapshot = await dailyTransactionRef.get();
      
      if (!snapshot.exists) return;
      
      // Verificar si algún hijo usa una fecha como clave
      final transactions = snapshot.children;
      for (var transaction in transactions) {
        // Obtener el modelo
        try {
          final model = DailyTransactionModel.fromJson(
            Map<String, dynamic>.from(transaction.value as Map)
          );
          
          // Verificar si la fecha tiene caracteres no permitidos
          if (model.date.contains('.') || model.date.contains('#') || 
              model.date.contains('\$') || model.date.contains('[') || 
              model.date.contains(']')) {
              
            // Sanitizar la fecha
            String safeDateKey;
            try {
              final parsedDate = DateTime.parse(model.date);
              safeDateKey = FirebaseKeyUtil.dateToSafeKey(parsedDate);
            } catch (e) {
              safeDateKey = FirebaseKeyUtil.sanitizeKey(model.date);
            }
            
            // Actualizar la fecha en el modelo
            model.date = safeDateKey;
            
            // Actualizar en Firebase con la fecha sanitizada
            await transaction.ref.update({'date': safeDateKey});
            
            print('🔧 Fecha corregida en DailyTransaction: ${model.date}');
          }
        } catch (e) {
          print('Error procesando transacción: $e');
        }
      }
    } catch (e) {
      print('Error en _sanitizeDailyTransactions: $e');
    }
  }
  
  // Verifica la estructura completa de Firebase para identificar caminos problemáticos
  static Future<void> scanForInvalidPaths() async {
    try {
      print('🔍 Escaneando Firebase en busca de rutas inválidas...');
      final rootRef = FirebaseDatabase.instance.ref();
      await _scanNodeForInvalidPaths(rootRef, '');
      print('✅ Escaneo completado');
    } catch (e) {
      print('❌ Error escaneando Firebase: $e');
    }
  }
  
  static Future<void> _scanNodeForInvalidPaths(DatabaseReference ref, String path) async {
    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) return;
      
      // Verificar si la clave actual contiene caracteres no permitidos
      final currentKey = ref.key ?? '';
      if (_containsInvalidChars(currentKey)) {
        print('⚠️ Clave inválida detectada: $path/$currentKey');
      }
      
      // Verificar hijos
      for (var child in snapshot.children) {
        final childKey = child.key ?? '';
        final childPath = path.isEmpty ? childKey : '$path/$childKey';
        
        if (_containsInvalidChars(childKey)) {
          print('⚠️ Clave inválida detectada: $childPath');
        }
        
        // Recursivamente verificar hijos, pero limitar la profundidad para evitar problemas
        if (childPath.split('/').length < 5) {
          await _scanNodeForInvalidPaths(child.ref, childPath);
        }
      }
    } catch (e) {
      print('❌ Error escaneando nodo $path: $e');
    }
  }
  
  static bool _containsInvalidChars(String key) {
    return key.contains('.') || key.contains('#') || 
           key.contains('\$') || key.contains('[') || 
           key.contains(']');
  }
}
