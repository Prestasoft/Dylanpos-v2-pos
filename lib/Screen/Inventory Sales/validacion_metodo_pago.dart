import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

// Ruta de ejecución: Ejecutar este script después de realizar una venta con un método de pago específico
// para verificar que se guarda correctamente en la base de datos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initialize();
  
  runApp(const MaterialApp(
    home: ValidacionMetodoPago(),
  ));
}

class ValidacionMetodoPago extends StatefulWidget {
  const ValidacionMetodoPago({Key? key}) : super(key: key);

  @override
  State<ValidacionMetodoPago> createState() => _ValidacionMetodoPagoState();
}

class _ValidacionMetodoPagoState extends State<ValidacionMetodoPago> {
  bool isLoading = true;
  List<Map<String, dynamic>> transacciones = [];
  String? ultimoTipoPago;
  String? ultimaTransaccionID;
  
  // Obtener el ID de usuario desde SharedPreferences
  Future<String> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }
  
  @override
  void initState() {
    super.initState();
    _cargarTransacciones();
  }

  Future<void> _cargarTransacciones() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Obtener referencia a las transacciones de venta
      final userId = await getUserID();
      final ref = FirebaseDatabase.instance.ref("$userId/Sales Transition");
      
      // Consultar las últimas 5 transacciones, ordenadas por fecha
      final snapshot = await ref.limitToLast(5).get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Convertir los datos a una lista de mapas
        List<Map<String, dynamic>> listaTransacciones = [];
        
        data.forEach((key, value) {
          final transaccion = Map<String, dynamic>.from(value as Map);
          transaccion['id'] = key;
          listaTransacciones.add(transaccion);
        });
        
        // Ordenar por fecha de compra (de más reciente a más antigua)
        listaTransacciones.sort((a, b) {
          final fechaA = DateTime.parse(a['purchaseDate'] ?? '');
          final fechaB = DateTime.parse(b['purchaseDate'] ?? '');
          return fechaB.compareTo(fechaA);
        });
        
        if (listaTransacciones.isNotEmpty) {
          ultimoTipoPago = listaTransacciones.first['paymentType'];
          ultimaTransaccionID = listaTransacciones.first['invoiceNumber']?.toString();
        }
        
        setState(() {
          transacciones = listaTransacciones;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar transacciones: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validación de Método de Pago'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTransacciones,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transacciones.isEmpty
              ? const Center(child: Text('No se encontraron transacciones'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Última transacción',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('ID: $ultimaTransaccionID'),
                          Text(
                            'Método de pago: ${ultimoTipoPago ?? "No especificado"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: transacciones.length,
                        itemBuilder: (context, index) {
                          final transaccion = transacciones[index];
                          final fechaCompra = DateTime.parse(transaccion['purchaseDate'] ?? '');
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                'Factura #${transaccion['invoiceNumber']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cliente: ${transaccion['customerName']}'),
                                  Text('Fecha: ${fechaCompra.toLocal()}'),
                                  Text('Método de pago: ${transaccion['paymentType'] ?? "No especificado"}'),
                                  Text('Monto: ${transaccion['totalAmount']}'),
                                ],
                              ),
                              trailing: Icon(
                                _getIconForPaymentType(transaccion['paymentType']),
                                color: _getColorForPaymentType(transaccion['paymentType']),
                              ),
                              onTap: () {
                                _mostrarDetallesTransaccion(transaccion);
                              },
                            ),
                          );
                        },
                      ),
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

  void _mostrarDetallesTransaccion(Map<String, dynamic> transaccion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles de la Transacción',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildDetailItem('ID de Factura', transaccion['invoiceNumber']?.toString()),
                    _buildDetailItem('Cliente', transaccion['customerName']),
                    _buildDetailItem('Teléfono', transaccion['customerPhone']),
                    _buildDetailItem('Método de Pago', transaccion['paymentType']),
                    _buildDetailItem('Monto Total', '${transaccion['totalAmount']}'),
                    _buildDetailItem('Monto Pendiente', '${transaccion['dueAmount']}'),
                    _buildDetailItem('Fecha', DateTime.parse(transaccion['purchaseDate']).toLocal().toString()),
                    _buildDetailItem('Estado', transaccion['isPaid'] == true ? 'Pagado' : 'Pendiente'),
                    _buildDetailItem('Vendedor', transaccion['sellerName']),
                    const Divider(),
                    const Text(
                      'Productos',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (transaccion['productList'] != null)
                      ...List.from(transaccion['productList']).map((producto) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Producto: ${producto['productName']}'),
                                Text('Cantidad: ${producto['quantity']}'),
                                Text('Precio: ${producto['subTotal']}'),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String? value) {
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
}
