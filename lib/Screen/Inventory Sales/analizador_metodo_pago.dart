import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

// Ejecutar este script después de realizar una venta y comprobar que
// el método de pago fue guardado correctamente.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initialize();
  runApp(const MaterialApp(home: AnalizadorMetodoPago()));
}

class AnalizadorMetodoPago extends StatefulWidget {
  const AnalizadorMetodoPago({Key? key}) : super(key: key);

  @override
  State<AnalizadorMetodoPago> createState() => _AnalizadorMetodoPagoState();
}

class _AnalizadorMetodoPagoState extends State<AnalizadorMetodoPago> {
  final TextEditingController _facturaController = TextEditingController();
  final TextEditingController _metodoPagoController = TextEditingController();
  bool isLoading = false;
  Map<String, dynamic>? transaccion;
  String? error;
  bool transaccionEncontrada = false;
  bool metodoPagoCorrecto = false;
  
  Future<String> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }
  
  Future<void> verificarMetodoPago() async {
    final facturaNumero = _facturaController.text.trim();
    final metodoPagoEsperado = _metodoPagoController.text.trim();
    
    if (facturaNumero.isEmpty || metodoPagoEsperado.isEmpty) {
      setState(() {
        error = 'Por favor ingrese tanto el número de factura como el método de pago esperado.';
        transaccionEncontrada = false;
        metodoPagoCorrecto = false;
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      error = null;
      transaccion = null;
      transaccionEncontrada = false;
      metodoPagoCorrecto = false;
    });
    
    try {
      final userId = await getUserID();
      final ref = FirebaseDatabase.instance.ref("$userId/Sales Transition");
      
      final snapshot = await ref.orderByChild('invoiceNumber').equalTo(facturaNumero).get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final transaccionData = Map<String, dynamic>.from(data.values.first as Map);
        
        setState(() {
          transaccion = transaccionData;
          transaccionEncontrada = true;
          
          // Verificar si el método de pago coincide
          final metodoPagoGuardado = transaccionData['paymentType'] as String?;
          metodoPagoCorrecto = metodoPagoGuardado == metodoPagoEsperado;
          
          if (!metodoPagoCorrecto) {
            error = 'El método de pago guardado ($metodoPagoGuardado) no coincide con el esperado ($metodoPagoEsperado).';
          }
          
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'No se encontró ninguna transacción con el número de factura $facturaNumero.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error al verificar: $e';
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analizador de Método de Pago'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              'Esta herramienta verifica si una transacción específica guardó correctamente el método de pago.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _facturaController,
              decoration: const InputDecoration(
                labelText: 'Número de Factura',
                hintText: 'Ingrese el número de factura a verificar',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _metodoPagoController,
              decoration: const InputDecoration(
                labelText: 'Método de Pago Esperado',
                hintText: 'Ingrese el método de pago que seleccionó (ej: Cash, Card)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : verificarMetodoPago,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Verificar'),
            ),
            
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ),
            
            if (transaccionEncontrada && transaccion != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: metodoPagoCorrecto ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: metodoPagoCorrecto ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          metodoPagoCorrecto ? Icons.check_circle : Icons.warning,
                          color: metodoPagoCorrecto ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          metodoPagoCorrecto
                              ? 'Método de pago guardado correctamente'
                              : 'Método de pago no coincide',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: metodoPagoCorrecto ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Método Esperado:'),
                              const SizedBox(height: 4),
                              Text(
                                _metodoPagoController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Método Guardado:'),
                              const SizedBox(height: 4),
                              Text(
                                transaccion!['paymentType'] ?? 'No especificado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: metodoPagoCorrecto ? Colors.green.shade800 : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Detalles de la transacción:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailItem('Factura N°', transaccion!['invoiceNumber']?.toString()),
              _buildDetailItem('Cliente', transaccion!['customerName']),
              _buildDetailItem('Fecha', DateTime.parse(transaccion!['purchaseDate'] ?? '').toLocal().toString()),
              _buildDetailItem('Monto Total', '${transaccion!['totalAmount']}'),
              _buildDetailItem('Estado', transaccion!['isPaid'] == true ? 'Pagado' : 'Pendiente'),
              
              const SizedBox(height: 24),
              Text(
                'Código responsable del guardado:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '// Asignación del método de pago al modelo',
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'transitionModel.paymentType = selectedPaymentOption;',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '// Preparación para guardado',
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'post = checkLossProfit(transitionModel: transitionModel);',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '// Guardado en Firebase',
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'await ref.push().set(post.toJson());',
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
