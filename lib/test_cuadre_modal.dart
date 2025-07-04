import 'package:flutter/material.dart';
import 'Screen/Reports/cuadre_modal.dart';

/// Este archivo es para probar el funcionamiento del modal de cuadre
/// sin tener que navegar por toda la aplicación.
void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Cuadre Modal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Datos de prueba
    final List<Map<String, dynamic>> ventasEjemplo = [
      {
        'invoiceNumber': '001',
        'amount': 500.0,
        'paymentType': 'Efectivo',
        'date': DateTime.now().toIso8601String(),
        'userID': 'testUser'
      },
      {
        'invoiceNumber': '002',
        'amount': 300.0,
        'paymentType': 'Tarjeta',
        'date': DateTime.now().toIso8601String(),
        'userID': 'testUser'
      },
      {
        'invoiceNumber': '003',
        'amount': 200.0,
        'paymentType': 'Transferencia',
        'date': DateTime.now().toIso8601String(),
        'userID': 'testUser'
      },
      {
        'invoiceNumber': '004',
        'amount': 100.0,
        'paymentType': 'Efectivo',
        'type': 'payment',
        'date': DateTime.now().toIso8601String(),
        'userID': 'testUser'
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Test Cuadre Modal'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => CuadreModal(
                ventasDelDia: ventasEjemplo,
                totalGastos: 50.0,
              ),
            );
          },
          child: Text('Abrir Modal de Cuadre'),
        ),
      ),
    );
  }
}
