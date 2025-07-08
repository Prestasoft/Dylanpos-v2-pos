import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';
import 'package:salespro_admin/model/daily_transaction_model.dart';

import '../const.dart';

class DailyTransactionRepo {
  Future<List<DailyTransactionModel>> getAllDailyTransition() async {
    List<DailyTransactionModel> dailyTransactionLists = [];
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance
          .ref(userId)
          .child('Daily Transaction')
          .orderByKey()
          .get();
          
      if (snapshot.exists) {
        print('Encontradas ${snapshot.children.length} transacciones en Firebase');
        
        for (var element in snapshot.children) {
          try {
            final data = jsonDecode(jsonEncode(element.value));
            
            // Imprimir fecha original para diagnóstico
            if (data['date'] != null) {
              print('Fecha original: ${data['date']}');
            }
            
            dailyTransactionLists.add(DailyTransactionModel.fromJson(data));
          } catch (e) {
            print('Error al procesar transacción diaria: ${e.toString()}');
            // Continuar con la siguiente transacción
          }
        }
      } else {
        print('No se encontraron transacciones diarias en Firebase');
      }
    } catch (e) {
      print('Error al obtener transacciones diarias: ${e.toString()}');
    }
    
    // Verificar si hay datos y registrar el resultado
    print('Total de transacciones diarias recuperadas: ${dailyTransactionLists.length}');
    
    // Mostrar fechas de las transacciones recuperadas para diagnóstico
    if (dailyTransactionLists.isNotEmpty) {
      print('Ejemplo de fechas de transacciones:');
      for (int i = 0; i < math.min(3, dailyTransactionLists.length); i++) {
        print('Transacción ${i+1}: ${dailyTransactionLists[i].name} - Fecha: ${dailyTransactionLists[i].date}');
      }
    }
    
    return dailyTransactionLists;
  }
}
