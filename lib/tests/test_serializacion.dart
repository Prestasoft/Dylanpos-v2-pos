import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/add_to_cart_model.dart';
import '../model/sale_transaction_model.dart';
import '../model/sale_confirmation_model.dart';
import '../Screen/tax rates/tax_model.dart';

/// Test de serialización para detectar problemas de conversión JSON
/// Ejecutar este archivo para validar que los modelos se serializan correctamente
void main() {
  runApp(const SerializationTestApp());
}

class SerializationTestApp extends StatelessWidget {
  const SerializationTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test de Serialización',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SerializationTestScreen(),
    );
  }
}

class SerializationTestScreen extends StatefulWidget {
  const SerializationTestScreen({Key? key}) : super(key: key);

  @override
  State<SerializationTestScreen> createState() => _SerializationTestScreenState();
}

class _SerializationTestScreenState extends State<SerializationTestScreen> {
  final List<String> _logs = [];
  bool _testComplete = false;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    // Ejecutar tests automáticamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runTests();
    });
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
    print(log);
  }

  Future<void> _runTests() async {
    _addLog('📋 Iniciando tests de serialización...');
    
    bool allTestsPassed = true;
    
    try {
      // 1. Test de TaxModel
      _addLog('\n📌 TEST 1: Serialización TaxModel');
      final taxModel = TaxModel(name: 'IVA', taxRate: 18, id: '1');
      final taxJson = taxModel.toJson();
      _addLog('TaxModel serializado: $taxJson');
      _validateJson(taxJson);
      _addLog('✅ Test TaxModel completado');
      
      // 2. Test de AddToCartModel
      _addLog('\n📌 TEST 2: Serialización AddToCartModel básico');
      final cartModel = AddToCartModel(
        productId: '123',
        productName: 'Producto test',
        warehouseName: 'Almacén Principal',
        warehouseId: 'A1',
        unitPrice: 100.0,
        quantity: 2,
        productPurchasePrice: 80.0,
        productImage: 'assets/images/blank_image.svg',
        taxType: 'IVA',
        margin: 20,
        excTax: 0,
        incTax: 18,
        groupTaxName: 'IVA',
        groupTaxRate: 18,
        subTaxes: [taxModel],
      );
      final cartJson = cartModel.toJson();
      _addLog('AddToCartModel serializado: $cartJson');
      _validateJson(cartJson);
      _addLog('✅ Test AddToCartModel básico completado');
      
      // 3. Test de AddToCartModel con datos problemáticos
      _addLog('\n📌 TEST 3: Serialización AddToCartModel con datos problemáticos');
      final problematicCartModel = AddToCartModel(
        productId: '123',
        productName: 'Producto test',
        warehouseName: 'Almacén Principal',
        warehouseId: 'A1',
        unitPrice: 100.0,
        quantity: 2,
        productPurchasePrice: 80.0,
        productImage: 'assets/images/blank_image.svg',
        taxType: 'IVA',
        margin: 20,
        excTax: 0,
        incTax: 18,
        groupTaxName: 'IVA',
        groupTaxRate: 18,
        subTaxes: [taxModel],
        // Agregar datos problemáticos
        productDetails: {'key': 'value', 'nested': {'test': true}},
        reservationId: 'reserva.con.puntos',
        dressId: 'vestido#con#caracteres#especiales',
      );
      final problematicCartJson = problematicCartModel.toJson();
      _addLog('AddToCartModel problemático serializado: $problematicCartJson');
      _validateJson(problematicCartJson);
      _addLog('✅ Test AddToCartModel problemático completado');
      
      // 4. Test de SaleTransactionModel
      _addLog('\n📌 TEST 4: Serialización SaleTransactionModel');
      final transactionModel = SaleTransactionModel(
        customerName: 'Cliente Prueba',
        customerType: 'Regular',
        customerPhone: '123456789',
        invoiceNumber: '101',
        purchaseDate: DateTime.now().toIso8601String(),
        customerAddress: 'Calle Test 123',
        customerImage: 'assets/images/default_user.png',
        customerGst: '',
        productList: [cartModel, problematicCartModel],
        totalAmount: 200.0,
        discountAmount: 10.0,
        serviceCharge: 5.0,
        vat: 18.0,
        isPaid: true,
        paymentType: 'Efectivo',
        reservationIds: ['res1', 'res.2', 'res#3'],
      );
      final transactionJson = transactionModel.toJson();
      _addLog('SaleTransactionModel serializado: $transactionJson');
      _validateJson(transactionJson);
      _addLog('✅ Test SaleTransactionModel completado');
      
      // 5. Test de SaleConfirmationModel
      _addLog('\n📌 TEST 5: Serialización SaleConfirmationModel');
      final confirmationModel = SaleConfirmationModel(
        token: 'token123',
        saleId: 'sale123',
        userId: 'user123',
        confirmed: false,
        createdAt: DateTime.now().toIso8601String(),
        expiresAt: DateTime.now().add(Duration(days: 1)).toIso8601String(),
        saleData: transactionModel,
      );
      final confirmationJson = confirmationModel.toJson();
      _addLog('SaleConfirmationModel serializado: $confirmationJson');
      _validateJson(confirmationJson);
      _addLog('✅ Test SaleConfirmationModel completado');
      
      // 6. Test de deserialización y re-serialización
      _addLog('\n📌 TEST 6: Ciclo completo de deserialización y re-serialización');
      // Convertir a string JSON y luego nuevamente a objeto
      final jsonString = jsonEncode(transactionJson);
      _addLog('JSON String: ${jsonString.substring(0, min(100, jsonString.length))}...');
      
      final decodedJson = jsonDecode(jsonString);
      final recreatedModel = SaleTransactionModel.fromJson(decodedJson);
      final reserializedJson = recreatedModel.toJson();
      _addLog('Modelo re-serializado: $reserializedJson');
      _validateJson(reserializedJson);
      _addLog('✅ Test ciclo completo completado');
      
    } catch (e, stackTrace) {
      allTestsPassed = false;
      _addLog('\n❌ ERROR EN TESTS: $e');
      _addLog('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _testComplete = true;
        _testSuccess = allTestsPassed;
      });
      
      _addLog('\n==============================================');
      if (allTestsPassed) {
        _addLog('✅ TODOS LOS TESTS COMPLETADOS EXITOSAMENTE');
      } else {
        _addLog('❌ ALGUNOS TESTS FALLARON');
      }
      _addLog('==============================================');
    }
  }
  
  void _validateJson(dynamic json) {
    // Validar que el objeto se pueda codificar a JSON
    try {
      final encoded = jsonEncode(json);
      _addLog('Codificación JSON exitosa: ${encoded.substring(0, min(50, encoded.length))}...');
    } catch (e) {
      _addLog('❌ ERROR: No se pudo codificar a JSON: $e');
      throw e;
    }
  }
  
  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Serialización'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _testComplete
                ? (_testSuccess ? Colors.green.shade100 : Colors.red.shade100)
                : Colors.grey.shade100,
            child: Row(
              children: [
                Icon(
                  _testComplete
                      ? (_testSuccess ? Icons.check_circle : Icons.error)
                      : Icons.hourglass_empty,
                  color: _testComplete
                      ? (_testSuccess ? Colors.green : Colors.red)
                      : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _testComplete
                        ? (_testSuccess
                            ? 'Tests completados exitosamente'
                            : 'Algunos tests fallaron')
                        : 'Ejecutando tests...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _testComplete
                          ? (_testSuccess ? Colors.green.shade800 : Colors.red.shade800)
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (_testComplete)
                  TextButton(
                    onPressed: _runTests,
                    child: const Text('Ejecutar nuevamente'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black;
                
                if (log.contains('ERROR')) {
                  textColor = Colors.red;
                } else if (log.contains('✅')) {
                  textColor = Colors.green;
                } else if (log.contains('📌')) {
                  textColor = Colors.blue;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
