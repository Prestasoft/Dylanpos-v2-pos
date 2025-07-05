import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../../model/sale_transaction_model.dart';
import '../../const.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(VerificadorMetodoPago());
}

class VerificadorMetodoPago extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verificador de Método de Pago',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: VerificadorMetodoPagoScreen(),
    );
  }
}

class VerificadorMetodoPagoScreen extends StatefulWidget {
  @override
  _VerificadorMetodoPagoScreenState createState() => _VerificadorMetodoPagoScreenState();
}

class _VerificadorMetodoPagoScreenState extends State<VerificadorMetodoPagoScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> ventas = [];
  DateTime fechaInicio = DateTime.now().subtract(Duration(days: 7));
  DateTime fechaFin = DateTime.now();
  String? filtroMetodoPago;
  bool mostrarSoloProblematicas = false;

  final formatoFecha = DateFormat('dd/MM/yyyy');
  final formatoMonto = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    setState(() {
      isLoading = true;
      ventas = [];
    });

    try {
      final userId = await getUserID();
      final ref = FirebaseDatabase.instance.ref("$userId/Sales Transition");
      
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          try {
            // Convertir a formato estándar
            final venta = SaleTransactionModel.fromJson(value);
            final fechaVenta = DateTime.parse(venta.purchaseDate);
            
            // Filtrar por fecha
            if (fechaVenta.isAfter(fechaInicio) && 
                fechaVenta.isBefore(fechaFin.add(Duration(days: 1)))) {
              
              // Verificar si el método de pago está establecido correctamente
              bool esProblematica = venta.paymentType == null || 
                                    venta.paymentType == 'Unknown' || 
                                    venta.paymentType!.isEmpty;
              
              // Aplicar filtro de método de pago si está activo
              if (filtroMetodoPago != null && venta.paymentType != filtroMetodoPago) {
                return;
              }
              
              // Aplicar filtro de solo problemáticas si está activo
              if (mostrarSoloProblematicas && !esProblematica) {
                return;
              }
              
              ventas.add({
                'id': key,
                'factura': venta.invoiceNumber,
                'cliente': venta.customerName,
                'fecha': fechaVenta,
                'monto': venta.totalAmount ?? 0.0,
                'metodoPago': venta.paymentType ?? 'No definido',
                'esProblematica': esProblematica,
              });
            }
          } catch (e) {
            print('Error al procesar venta $key: $e');
          }
        });
        
        // Ordenar por fecha descendente (más reciente primero)
        ventas.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
      }
    } catch (e) {
      print('Error al cargar ventas: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void cambiarFiltroFecha(DateTime inicio, DateTime fin) {
    setState(() {
      fechaInicio = inicio;
      fechaFin = fin;
    });
    cargarVentas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verificador de Método de Pago'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: cargarVentas,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de filtros
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha inicio:'),
                          InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: fechaInicio,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) {
                                cambiarFiltroFecha(fecha, fechaFin);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(formatoFecha.format(fechaInicio)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha fin:'),
                          InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: fechaFin,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) {
                                cambiarFiltroFecha(fechaInicio, fecha);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(formatoFecha.format(fechaFin)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Método de pago:'),
                          DropdownButtonFormField<String?>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: filtroMetodoPago,
                            onChanged: (value) {
                              setState(() {
                                filtroMetodoPago = value;
                              });
                              cargarVentas();
                            },
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...['Efectivo', 'Tarjeta', 'Transferencia', 'Mixto', 'Unknown', 'No definido'].map((metodo) => 
                                DropdownMenuItem<String>(
                                  value: metodo,
                                  child: Text(metodo),
                                )
                              ).toList(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Solo ventas problemáticas'),
                        value: mostrarSoloProblematicas,
                        onChanged: (value) {
                          setState(() {
                            mostrarSoloProblematicas = value ?? false;
                          });
                          cargarVentas();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Resumen
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de ventas: ${ventas.length}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ventas sin método de pago: ${ventas.where((v) => v['esProblematica']).length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ventas.any((v) => v['esProblematica']) ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de ventas
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator())
              : ventas.isEmpty 
                ? Center(child: Text('No se encontraron ventas con los filtros aplicados'))
                : ListView.builder(
                    itemCount: ventas.length,
                    itemBuilder: (context, index) {
                      final venta = ventas[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: venta['esProblematica'] ? Colors.red[50] : null,
                        child: ListTile(
                          title: Text(
                            'Factura #${venta['factura']} - ${venta['cliente']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha: ${formatoFecha.format(venta['fecha'])}'),
                              Text('Monto: ${formatoMonto.format(venta['monto'])}'),
                              Text(
                                'Método de pago: ${venta['metodoPago']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: venta['esProblematica'] ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            venta['esProblematica'] 
                              ? Icons.error_outline 
                              : Icons.check_circle_outline,
                            color: venta['esProblematica'] ? Colors.red : Colors.green,
                          ),
                          onTap: () {
                            // Mostrar detalles completos
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Detalles de Venta #${venta['factura']}'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      infoRow('ID', venta['id']),
                                      infoRow('Factura', venta['factura']),
                                      infoRow('Cliente', venta['cliente']),
                                      infoRow('Fecha', formatoFecha.format(venta['fecha'])),
                                      infoRow('Monto', formatoMonto.format(venta['monto'])),
                                      infoRow('Método de pago', venta['metodoPago'], 
                                        isError: venta['esProblematica']),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
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
  
  Widget infoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
                fontWeight: isError ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
