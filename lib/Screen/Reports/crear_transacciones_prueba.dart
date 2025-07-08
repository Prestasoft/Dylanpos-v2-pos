import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/model/daily_transaction_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';

class CrearTransaccionesPrueba extends StatefulWidget {
  const CrearTransaccionesPrueba({super.key});

  @override
  State<CrearTransaccionesPrueba> createState() => _CrearTransaccionesPruebaState();
}

class _CrearTransaccionesPruebaState extends State<CrearTransaccionesPrueba> {
  bool isLoading = false;
  String statusMessage = '';
  
  Future<void> _crearTransaccionesPrueba() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Creando transacciones de prueba...';
    });
    
    try {
      // Crear 3 transacciones de prueba con diferentes tipos
      final ahora = DateTime.now();
      final transacciones = [
        DailyTransactionModel(
          name: 'Transacción de Venta de Hoy',
          date: DateTime(ahora.year, ahora.month, ahora.day, ahora.hour, ahora.minute, ahora.second).toString(),
          type: 'Sale',
          total: 1500.0,
          paymentIn: 1500.0,
          paymentOut: 0.0,
          remainingBalance: 1500.0,
          id: 'prueba-${DateTime.now().millisecondsSinceEpoch}',
        ),
        DailyTransactionModel(
          name: 'Transacción de Cobro de Ayer',
          date: DateTime.now().subtract(Duration(days: 1)).toString(),
          type: 'Due Collection',
          total: 800.0,
          paymentIn: 800.0,
          paymentOut: 0.0,
          remainingBalance: 2300.0,
          id: 'prueba-${DateTime.now().millisecondsSinceEpoch + 1}',
        ),
        DailyTransactionModel(
          name: 'Transacción de Gasto de Anteayer',
          date: DateTime.now().subtract(Duration(days: 2)).toString(),
          type: 'Expense',
          total: 500.0,
          paymentIn: 0.0,
          paymentOut: 500.0,
          remainingBalance: 1800.0,
          id: 'prueba-${DateTime.now().millisecondsSinceEpoch + 2}',
        ),
      ];
      
      // Guardar cada transacción
      for (var transaccion in transacciones) {
        await postDailyTransaction(dailyTransactionModel: transaccion);
      }
      
      setState(() {
        statusMessage = '¡Transacciones de prueba creadas con éxito!';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error al crear transacciones: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Herramienta de Diagnóstico', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            
            // Botón para crear transacciones de prueba
            ElevatedButton(
              onPressed: isLoading ? null : _crearTransaccionesPrueba,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Crear Transacciones de Prueba', style: TextStyle(fontSize: 16)),
            ),
            
            SizedBox(height: 20),
            
            // Mensaje de estado
            if (statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: statusMessage.contains('Error') 
                      ? Colors.red.shade100 
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: statusMessage.contains('Error') ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
              
            SizedBox(height: 30),
            
            // Instrucciones
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instrucciones:', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('1. Haga clic en el botón para crear transacciones de prueba.'),
                  Text('2. Vuelva a la pestaña "Transaccion Diaria" para ver los resultados.'),
                  Text('3. Compruebe si las transacciones aparecen en la lista.'),
                  SizedBox(height: 10),
                  Text('Nota: Las transacciones de prueba se guardarán en la base de datos real.',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
