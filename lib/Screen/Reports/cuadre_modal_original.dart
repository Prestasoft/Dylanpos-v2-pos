import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../commas.dart';

class CuadreModal extends StatefulWidget {
  final List<Map<String, dynamic>> ventasDelDia;
  final double totalGastos;

  const CuadreModal({
    Key? key,
    required this.ventasDelDia,
    required this.totalGastos,
  }) : super(key: key);

  @override
  State<CuadreModal> createState() => _CuadreModalState();
}

class _CuadreModalState extends State<CuadreModal> {
  // --- Estado para totales de métodos de pago desde Firebase ---
  Map<String, dynamic> _dailyTransactions = {};
  bool _loadingPagos = false;
  double _totalEfectivo = 0.0;
  double _totalTarjeta = 0.0;
  double _totalTransferencia = 0.0;
  double _totalPagos = 0.0; // Total de pagos (salidas de dinero)
  
  // Desglose de pagos por método
  double _pagoEfectivo = 0.0;
  double _pagoTarjeta = 0.0; 
  double _pagoTransferencia = 0.0;
  
  // Eliminados filtros de fecha y variables asociadas, solo se usará la fecha de hoy
  late DateTime _hoy;

  // Función helper para formatear montos con comas de millar
  String formatCurrency(double amount) {
    return myFormat.format(amount);
  }

  // Log de depuración para validar los datos en tiempo real
  void logDebugData() {
    debugPrint('--- [CuadreModal] Debug Data ---');
    debugPrint('totalEfectivo: \t$totalEfectivo');
    debugPrint('totalTarjeta: \t$totalTarjeta');
    debugPrint('totalTransferencia: $totalTransferencia');
    debugPrint('totalPagos: \t$_totalPagos');
    debugPrint('  - Pagos Efectivo: \t$_pagoEfectivo');
    debugPrint('  - Pagos Tarjeta: \t$_pagoTarjeta');
    debugPrint('  - Pagos Transferencia: \t$_pagoTransferencia');
    debugPrint('totalGastos:     ${widget.totalGastos}');
    debugPrint('totalVentasDelDia: $totalVentasDelDia');
    debugPrint('totalNetoPorDia:   $totalNetoPorDia');
    debugPrint('totalContado:      $totalContado');
    debugPrint('cantidades:        $cantidades');
    debugPrint('--------------------------------');
  }

  /// Función utilitaria para categorizar métodos de pago de forma robusta (idéntica a report_screen.dart)
  String categorizarMetodoPago(String? paymentType) {
    final tipo = (paymentType ?? '').toLowerCase();
    if (tipo.contains('cash') || tipo.contains('efectivo')) return 'Efectivo';
    if (tipo.contains('card') || tipo.contains('tarjeta') || tipo.contains('bank')) return 'Tarjeta';
    if (tipo.contains('transfer') || tipo.contains('transferencia') || tipo.contains('mobile')) return 'Transferencia';
    return 'Otro';
  }

  List<Map<String, dynamic>> _ventasFiltradas = [];

  // Denominaciones de RD$
  final List<int> billetes = [2000, 1000, 500, 200, 100, 50];
  final List<int> monedas = [25, 10, 5, 1];
  final Map<int, String> imagenesBilletes = {
    2000: 'images/billete_2000.png',
    1000: 'images/billete_1000.png',
    500: 'images/billete_500.png',
    200: 'images/billete_200.png',
    100: 'images/billete_100.png',
    50: 'images/billete_50.png',
  };
  final Map<int, String> imagenesMonedas = {
    25: 'images/moneda_25.png',
    10: 'images/moneda_10.png',
    5: 'images/moneda_5.png',
    1: 'images/moneda_1.png',
  };
  Map<int, int> cantidades = {};

  @override
  void initState() {
    super.initState();
    _hoy = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    debugPrint('[CuadreModal] initState ejecutado. ventasDelDia: \\${widget.ventasDelDia.length}');
    for (var d in [...billetes, ...monedas]) {
      cantidades[d] = 0;
    }
    
    // IMPORTANTE: Asumimos que todas las ventas son de hoy si no tienen fecha
    _ventasFiltradas = widget.ventasDelDia.where((v) {
      final fechaStr = v['date'];
      if (fechaStr == null || fechaStr is! String || fechaStr.isEmpty) {
        // Asumimos que ventas sin fecha son de hoy
        debugPrint('[CuadreModal] Venta sin fecha incluida: $v');
        return true;
      }
      
      DateTime? fecha;
      bool coincideHoy = false;
      try {
        fecha = DateTime.parse(fechaStr);
        final fechaVenta = DateTime(fecha.year, fecha.month, fecha.day);
        coincideHoy = fechaVenta == _hoy;
      } catch (e) {
        // Intentar parseo solo yyyy-MM-dd
        try {
          final partes = fechaStr.split('T')[0].split('-');
          if (partes.length == 3) {
            fecha = DateTime(int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
            coincideHoy = fecha == _hoy;
          }
        } catch (e2) {
          debugPrint('[CuadreModal] Venta ignorada por error de parseo: fechaStr=$fechaStr, venta=$v');
        }
      }
      if (!coincideHoy) {
        debugPrint('[CuadreModal] Venta ignorada por no ser de hoy: fechaStr=$fechaStr, venta=$v');
      }
      return coincideHoy;
    }).toList();
    
    // Usar directamente las ventas sin filtrar para calcular los totales
    _calcularTotalesDirectamente();
    
    // Obtener datos adicionales de Firebase
    _fetchPagosDesdeFirebase();
  }

  // Calcular totales directamente de las ventas sin depender de Firebase
  void _calcularTotalesDirectamente() {
    double efectivo = 0.0;
    double tarjeta = 0.0;
    double transferencia = 0.0;
    double pagos = 0.0;
    double pagoEfectivo = 0.0;
    double pagoTarjeta = 0.0;
    double pagoTransferencia = 0.0;
    
    for (var venta in widget.ventasDelDia) {
      final paymentType = venta['paymentType'];
      final amount = venta['amount'];
      final tipo = venta['type']; // Para distinguir entre ventas y pagos
      
      if (amount != null) {
        final double monto = amount is int ? amount.toDouble() : (amount is double ? amount : 0.0);
        final metodoPago = categorizarMetodoPago(paymentType);
        
        // Si es un pago (salida de dinero)
        if (tipo != null && tipo.toString().toLowerCase() == 'payment') {
          pagos += monto;
          
          // Desglosar el pago por método
          if (metodoPago == 'Efectivo') {
            pagoEfectivo += monto;
            debugPrint('[CuadreModal] Pago en Efectivo: $monto');
          } else if (metodoPago == 'Tarjeta') {
            pagoTarjeta += monto;
            debugPrint('[CuadreModal] Pago con Tarjeta: $monto');
          } else if (metodoPago == 'Transferencia') {
            pagoTransferencia += monto;
            debugPrint('[CuadreModal] Pago por Transferencia: $monto');
          }
          
          continue;
        }
        
        // Si es una venta normal, usar la misma lógica de categorización
        if (metodoPago == 'Efectivo') {
          efectivo += monto;
        } else if (metodoPago == 'Tarjeta') {
          tarjeta += monto;
        } else if (metodoPago == 'Transferencia') {
          transferencia += monto;
        }
      }
    }
    
    // Actualizar los totales
    setState(() {
      _totalEfectivo = efectivo;
      _totalTarjeta = tarjeta;
      _totalTransferencia = transferencia;
      _totalPagos = pagos;
      _pagoEfectivo = pagoEfectivo;
      _pagoTarjeta = pagoTarjeta;
      _pagoTransferencia = pagoTransferencia;
    });
    
    // Imprimir para depuración
    debugPrint('[CuadreModal] Totales calculados directamente:');
    debugPrint('  Efectivo: $_totalEfectivo');
    debugPrint('  Tarjeta: $_totalTarjeta');
    debugPrint('  Transferencia: $_totalTransferencia');
    debugPrint('  Pagos (salidas): $_totalPagos');
    debugPrint('    - Pagos Efectivo: $_pagoEfectivo');
    debugPrint('    - Pagos Tarjeta: $_pagoTarjeta');
    debugPrint('    - Pagos Transferencia: $_pagoTransferencia');
  }

  Future<void> _fetchPagosDesdeFirebase() async {
    setState(() => _loadingPagos = true);
    try {
      // Obtener el userID desde ventasDelDia (asume que todas las ventas son del mismo usuario)
      String? userID;
      if (widget.ventasDelDia.isNotEmpty && widget.ventasDelDia.first['userID'] != null) {
        userID = widget.ventasDelDia.first['userID'].toString();
      } else {
        debugPrint('[CuadreModal] No se pudo obtener userID de las ventas');
        setState(() => _loadingPagos = false);
        return;
      }
      
      final ref = FirebaseDatabase.instance.ref(userID).child('Daily Transaction');
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        Map<String, dynamic> allDailyTransactions = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Obtener los invoiceNumbers de las ventas del día (todas, no solo las filtradas)
        final Set<dynamic> invoiceNumbers = widget.ventasDelDia.map((v) => v['invoiceNumber'] ?? v['id']).toSet();
        
        int totalRegistros = 0;
        int usadosPorId = 0;
        
        // Si no hay IDs para filtrar, usar directamente los totales ya calculados
        if (invoiceNumbers.isEmpty) {
          debugPrint('[CuadreModal] No hay IDs para filtrar en Firebase, usando totales directos');
          setState(() => _loadingPagos = false);
          return;
        }
        
        // Filtrar por IDs
        Map<String, dynamic> filteredTransactions = {};
        for (var entry in allDailyTransactions.entries) {
          totalRegistros++;
          final value = entry.value;
          final id = value['id'] ?? value['invoiceNumber'];
          if (id != null && invoiceNumbers.contains(id)) {
            filteredTransactions[entry.key] = value;
            usadosPorId++;
          }
        }
        
        debugPrint('[CuadreModal] Total registros en Firebase: $totalRegistros, usados por id: $usadosPorId');
        
        // Si encontramos movimientos en Firebase, usar esos totales
        if (filteredTransactions.isNotEmpty) {
          _dailyTransactions = filteredTransactions;
          
          // Solo sobrescribimos los valores si encontramos algo en Firebase
          double efectivoFB = _calculateTotalMoney(_dailyTransactions);
          double tarjetaFB = _calculateTotalCard(_dailyTransactions);
          double transferenciaFB = _calculateTotalTransfer(_dailyTransactions);
          double pagosFB = _calculateTotalPayments(_dailyTransactions);
          
          if (efectivoFB > 0 || tarjetaFB > 0 || transferenciaFB > 0 || pagosFB > 0) {
            setState(() {
              _totalEfectivo = efectivoFB;
              _totalTarjeta = tarjetaFB;
              _totalTransferencia = transferenciaFB;
              _totalPagos = pagosFB;
            });
            
            debugPrint('[CuadreModal] Totales actualizados desde Firebase:');
            debugPrint('  Efectivo: $_totalEfectivo');
            debugPrint('  Tarjeta: $_totalTarjeta');
            debugPrint('  Transferencia: $_totalTransferencia');
            debugPrint('  Pagos: $_totalPagos');
          } else {
            debugPrint('[CuadreModal] Todos los totales de Firebase son 0, manteniendo totales directos');
          }
        } else {
          debugPrint('[CuadreModal] No se encontraron transacciones en Firebase que coincidan con las ventas');
        }
      } else {
        debugPrint('[CuadreModal] No existen transacciones en Firebase para este usuario');
      }
    } catch (e) {
      debugPrint('Error al consultar pagos desde Firebase: $e');
    }
    setState(() => _loadingPagos = false);
  }

  double _calculateTotalMoney(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      final paymentType = value[type == 'Sale' ? 'saleTransactionModel' : 'dueTransactionModel']?['paymentType'];
      if (categorizarMetodoPago(paymentType) == 'Efectivo') {
        total += (value['paymentIn'] as num).toDouble();
      }
    });
    return total;
  }

  double _calculateTotalCard(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      final paymentType = value[type == 'Sale' ? 'saleTransactionModel' : 'dueTransactionModel']?['paymentType'];
      if (categorizarMetodoPago(paymentType) == 'Tarjeta') {
        total += (value['paymentIn'] as num).toDouble();
      }
    });
    return total;
  }

  double _calculateTotalTransfer(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      final paymentType = value[type == 'Sale' ? 'saleTransactionModel' : 'dueTransactionModel']?['paymentType'];
      if (categorizarMetodoPago(paymentType) == 'Transferencia') {
        total += (value['paymentIn'] as num).toDouble();
      }
    });
    return total;
  }


  double _calculateTotalPayments(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    double efectivo = 0.0;
    double tarjeta = 0.0;
    double transferencia = 0.0;
    
    dailyTransactions.forEach((key, value) {
      final type = value['type']?.toString().toLowerCase() ?? '';
      if (type == 'payment') {
        final double monto = (value['paymentOut'] as num? ?? 0).toDouble();
        total += monto;
        
        // Desglosar por método de pago
        final paymentType = value['paymentTransactionModel']?['paymentType'];
        final metodoPago = categorizarMetodoPago(paymentType);
        
        if (metodoPago == 'Efectivo') {
          efectivo += monto;
        } else if (metodoPago == 'Tarjeta') {
          tarjeta += monto;
        } else if (metodoPago == 'Transferencia') {
          transferencia += monto;
        }
      }
    });
    
    // Guardar los desgloses
    setState(() {
      _pagoEfectivo = efectivo;
      _pagoTarjeta = tarjeta;
      _pagoTransferencia = transferencia;
    });
    
    return total;
  }

  double get totalEfectivo => _totalEfectivo;
  double get totalTarjeta => _totalTarjeta;
  double get totalTransferencia => _totalTransferencia;
  double get totalPagos => _totalPagos;
  double get pagoEfectivo => _pagoEfectivo;
  double get pagoTarjeta => _pagoTarjeta;
  double get pagoTransferencia => _pagoTransferencia;


  double get totalVentasDelDia {
    return totalEfectivo + totalTarjeta + totalTransferencia;
  }
  
  double get totalVentasNetoDelDia {
    return totalVentasDelDia - totalPagos;
  }
  
  // Efectivo neto = ingreso efectivo - pagos en efectivo
  double get efectivoNeto {
    return totalEfectivo - pagoEfectivo;
  }

  double get totalContado {
    double total = 0;
    cantidades.forEach((den, cant) {
      total += den * cant;
    });
    return total;
  }

  double get totalNetoPorDia {
    return totalVentasNetoDelDia - widget.totalGastos;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[CuadreModal] build ejecutado. ventasFiltradas: \\${_ventasFiltradas.length}');
    logDebugData(); // Log en cada build para ver los datos en tiempo real
    // Filtro visual y mensajes de ventas vacías eliminados para limpiar la UI
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.calculate, color: Colors.blueAccent),
          const SizedBox(width: 8),
          const Text('Cuadre de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtro de rango de fechas eliminado
            // Detalle de ventas filtradas eliminado
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: _loadingPagos
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_money, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('Pagos en Efectivo: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('RD\$${formatCurrency(totalEfectivo)}', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                          if (pagoEfectivo > 0)
                            Row(
                              children: [
                                const SizedBox(width: 24),  // Indentación para mostrar que es un subítem
                                const Icon(Icons.arrow_circle_down_outlined, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 6),
                                Text('Pagos salida efectivo: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Text('-RD\$${formatCurrency(pagoEfectivo)}', style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                              ],
                            ),
                          if (pagoEfectivo > 0)
                            Row(
                              children: [
                                const SizedBox(width: 24),  // Indentación para mostrar que es un subítem
                                const Icon(Icons.check_circle_outline, color: Colors.teal, size: 18),
                                const SizedBox(width: 6),
                                Text('Efectivo neto: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('RD\$${formatCurrency(efectivoNeto)}', style: const TextStyle(color: Colors.teal, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          Row(
                            children: [
                              const Icon(Icons.credit_card, color: Colors.deepPurple),
                              const SizedBox(width: 6),
                              Text('Pagos con Tarjeta: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('RD\$${formatCurrency(totalTarjeta)}', style: const TextStyle(color: Colors.deepPurple)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.swap_horiz, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text('Pagos por Transferencia: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('RD\$${formatCurrency(totalTransferencia)}', style: const TextStyle(color: Colors.orange)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(thickness: 1, color: Colors.grey),
                          
                          // Resumen de Entradas y Salidas
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('Resumen de Movimientos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.arrow_circle_up, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('Entradas Totales: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('RD\$${formatCurrency(totalVentasDelDia)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.arrow_circle_down, color: Colors.red),
                              const SizedBox(width: 6),
                              Text('Salidas (Pagos): ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('RD\$${formatCurrency(totalPagos)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.account_balance, color: Colors.teal),
                              const SizedBox(width: 6),
                              Text('Total Neto de Ventas: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('RD\$${formatCurrency(totalVentasNetoDelDia)}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.remove_circle, color: Colors.red),
                              const SizedBox(width: 6),
                              Text('Total Gastos del Día: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('RD\$${formatCurrency(widget.totalGastos)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(thickness: 2, color: Colors.green),
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('Balance Neto del Día: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                              Text('RD\$${formatCurrency(totalNetoPorDia)}', style: TextStyle(color: totalNetoPorDia >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Ingrese la cantidad de cada denominación:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...billetes.map((den) => _buildDenInput(den, 'Billete', imagenesBilletes[den])).toList(),
                  ...monedas.map((den) => _buildDenInput(den, 'Moneda', imagenesMonedas[den])).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('Total contado en efectivo: RD\$${formatCurrency(totalContado)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('(Solo se cuenta el efectivo físico)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: totalContado == efectivoNeto ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      totalContado == efectivoNeto
                          ? '¡El cuadre de efectivo coincide!'
                          : 'Diferencia en efectivo: RD\$${formatCurrency(totalContado - efectivoNeto)}',
                      style: TextStyle(
                        color: totalContado == efectivoNeto ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Mensaje de ventas vacías eliminado
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            // Log extra al presionar "Cuadrar"
            logDebugData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Cuadre de Caja Realizado', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('💰 Entradas Totales: RD\$${formatCurrency(totalVentasDelDia)}'),
                    Text('🔄 Salidas (Pagos): RD\$${formatCurrency(totalPagos)}'),
                    if (pagoEfectivo > 0) 
                      Text('💵 Efectivo: Entradas RD\$${formatCurrency(totalEfectivo)} - Salidas RD\$${formatCurrency(pagoEfectivo)} = Neto RD\$${formatCurrency(efectivoNeto)}'),
                    Text('💸 Total gastos del día: RD\$${formatCurrency(widget.totalGastos)}'),
                    Text('🏆 Balance neto del día: RD\$${formatCurrency(totalNetoPorDia)}'),
                    Text('💵 Efectivo contado: RD\$${formatCurrency(totalContado)}'),
                    Text('💳 Tarjetas + Transferencias: RD\$${formatCurrency(totalTarjeta + totalTransferencia)}'),
                  ],
                ),
                backgroundColor: totalNetoPorDia >= 0 ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          },
          child: const Text('Cuadrar'),
        ),
      ],
    );
  }

  Widget _buildDenInput(int denominacion, String tipo, String? imagen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          if (imagen != null)
            Container(
              width: 48,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  imagen,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.money, color: Colors.grey),
                ),
              ),
            ),
          Text('$tipo RD$denominacion', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: cantidades[denominacion]?.toString() ?? '0',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
              onChanged: (val) {
                setState(() {
                  cantidades[denominacion] = int.tryParse(val) ?? 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
