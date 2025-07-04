import 'package:firebase_database/firebase_database.dart';

// Script de prueba para agregar ventas de hoy para verificar el cuadre de caja
Future<void> addTestSalesToday() async {
  final userId = "1sNp9iHiGKRxpmqgNsr2S5712uw2"; // ID del usuario actual
  final databaseRef = FirebaseDatabase.instance.ref("$userId/Sales Transition");
  
  final today = DateTime.now();
  
  // Venta 1: Efectivo (Cash)
  await databaseRef.push().set({
    'customerName': 'Cliente Test 1',
    'customerPhone': '8091234567',
    'customerAddress': 'Dirección Test',
    'customerGst': '',
    'customerType': 'Guest',
    'customerImage': '',
    'invoiceNumber': '10001',
    'purchaseDate': today.toString(),
    'totalAmount': 1500.0,
    'paymentType': 'Cash',
    'isPaid': true,
    'dueAmount': 0.0,
    'returnAmount': 0.0,
    'discountAmount': 0.0,
    'serviceCharge': 0.0,
    'vat': 0.0,
    'productList': []
  });
  
  // Venta 2: Tarjeta (Bank)
  await databaseRef.push().set({
    'customerName': 'Cliente Test 2',
    'customerPhone': '8097654321',
    'customerAddress': 'Dirección Test 2',
    'customerGst': '',
    'customerType': 'Guest',
    'customerImage': '',
    'invoiceNumber': '10002',
    'purchaseDate': today.toString(),
    'totalAmount': 2500.0,
    'paymentType': 'Bank',
    'isPaid': true,
    'dueAmount': 0.0,
    'returnAmount': 0.0,
    'discountAmount': 0.0,
    'serviceCharge': 0.0,
    'vat': 0.0,
    'productList': []
  });
  
  // Venta 3: Transferencia (Mobile Pay)
  await databaseRef.push().set({
    'customerName': 'Cliente Test 3',
    'customerPhone': '8098765432',
    'customerAddress': 'Dirección Test 3',
    'customerGst': '',
    'customerType': 'Guest',
    'customerImage': '',
    'invoiceNumber': '10003',
    'purchaseDate': today.toString(),
    'totalAmount': 800.0,
    'paymentType': 'Mobile Pay',
    'isPaid': true,
    'dueAmount': 0.0,
    'returnAmount': 0.0,
    'discountAmount': 0.0,
    'serviceCharge': 0.0,
    'vat': 0.0,
    'productList': []
  });
  
  print('✅ Ventas de prueba agregadas para hoy:');
  print('💵 Efectivo: RD\$1,500.00');
  print('💳 Tarjeta: RD\$2,500.00');
  print('📱 Transferencia: RD\$800.00');
  print('💰 Total: RD\$4,800.00');
}
