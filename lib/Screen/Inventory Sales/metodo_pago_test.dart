// Utilidad para verificar que el método de pago se guarda correctamente
// en la transacción al realizar un pago desde Inventory Sales.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

// Para usar este archivo, ejecutar:
// flutter run -d chrome --web-renderer html --target=lib/Screen/Inventory\ Sales/metodo_pago_test.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initialize();
  
  runApp(const MaterialApp(
    home: MetodoPagoTest(),
  ));
}

class MetodoPagoTest extends StatefulWidget {
  const MetodoPagoTest({Key? key}) : super(key: key);

  @override
  State<MetodoPagoTest> createState() => _MetodoPagoTestState();
}

class _MetodoPagoTestState extends State<MetodoPagoTest> {
  final TextEditingController _invoiceController = TextEditingController();
  bool isLoading = false;
  Map<String, dynamic>? transaccion;
  String? mensajeError;
  
  Future<String> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }
  
  Future<void> _buscarTransaccion() async {
    final invoiceNumber = _invoiceController.text.trim();
    
    if (invoiceNumber.isEmpty) {
      setState(() {
        mensajeError = 'Por favor, ingrese un número de factura';
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      mensajeError = null;
      transaccion = null;
    });
    
    try {
      final userId = await getUserID();
      final ref = FirebaseDatabase.instance.ref("$userId/Sales Transition");
      
      // Buscar la transacción por número de factura
      final snapshot = await ref.orderByChild('invoiceNumber').equalTo(invoiceNumber).get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Tomar la primera coincidencia (debería ser única por número de factura)
        final entry = data.entries.first;
        final transaccionData = Map<String, dynamic>.from(entry.value as Map);
        transaccionData['id'] = entry.key;
        
        setState(() {
          transaccion = transaccionData;
          isLoading = false;
        });
      } else {
        setState(() {
          mensajeError = 'No se encontró ninguna transacción con el número de factura $invoiceNumber';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        mensajeError = 'Error al buscar la transacción: $e';
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Método de Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verificador de Método de Pago',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta herramienta verifica que el método de pago seleccionado durante una venta se guarda correctamente en la base de datos.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Buscador por número de factura
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invoiceController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Factura',
                      hintText: 'Ingrese el número de factura a verificar',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _buscarTransaccion,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Buscar'),
                ),
              ],
            ),
            
            if (mensajeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  mensajeError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            if (transaccion != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles de la Transacción',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildDetailRow('Factura N°', transaccion!['invoiceNumber']?.toString()),
                      _buildDetailRow('Cliente', transaccion!['customerName']),
                      _buildDetailRow('Fecha', DateTime.parse(transaccion!['purchaseDate'] ?? '').toLocal().toString()),
                      const SizedBox(height: 8),
                      
                      // Destacar el método de pago
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForPaymentType(transaccion!['paymentType']),
                              color: _getColorForPaymentType(transaccion!['paymentType']),
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Método de Pago:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    transaccion!['paymentType'] ?? 'No especificado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getColorForPaymentType(transaccion!['paymentType']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      _buildDetailRow('Monto Total', transaccion!['totalAmount']?.toString()),
                      _buildDetailRow('Monto Pendiente', transaccion!['dueAmount']?.toString()),
                      _buildDetailRow('Estado', transaccion!['isPaid'] == true ? 'Pagado' : 'Pendiente'),
                      _buildDetailRow('Vendedor', transaccion!['sellerName']),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'No especificado'),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconForPaymentType(String? paymentType) {
    switch (paymentType) {
      case 'Cash':
        return Icons.attach_money;
      case 'Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Mobile Payment':
        return Icons.phone_android;
      case 'Crypto':
        return Icons.currency_bitcoin;
      default:
        return Icons.payment;
    }
  }

  Color _getColorForPaymentType(String? paymentType) {
    switch (paymentType) {
      case 'Cash':
        return Colors.green;
      case 'Card':
        return Colors.blue;
      case 'Bank Transfer':
        return Colors.purple;
      case 'Mobile Payment':
        return Colors.orange;
      case 'Crypto':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
