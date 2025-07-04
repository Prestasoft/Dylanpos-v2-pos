import 'package:flutter/material.dart';

class CuadreModal extends StatefulWidget {
  final double totalEfectivo;
  final double totalTarjeta;
  final double totalTransferencia;
  final double totalGastos;
  CuadreModal({
    required this.totalEfectivo,
    required this.totalTarjeta,
    required this.totalTransferencia,
    required this.totalGastos,
  });

  @override
  State<CuadreModal> createState() => _CuadreModalState();
}

class _CuadreModalState extends State<CuadreModal> {
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
    for (var d in [...billetes, ...monedas]) {
      cantidades[d] = 0;
    }
    
    // Debug: Imprimir los valores recibidos con más detalle
    print('🎯 ===== CUADRE MODAL INICIADO =====');
    print('📊 Valores recibidos del servidor:');
    print('💵 Efectivo: RD${widget.totalEfectivo.toStringAsFixed(2)}');
    print('💳 Tarjeta: RD${widget.totalTarjeta.toStringAsFixed(2)}');
    print('📱 Transferencia: RD${widget.totalTransferencia.toStringAsFixed(2)}');
    print('💸 Gastos: RD${widget.totalGastos.toStringAsFixed(2)}');
    
    final calculatedTotalVentas = widget.totalEfectivo + widget.totalTarjeta + widget.totalTransferencia;
    final calculatedBalanceNeto = calculatedTotalVentas - widget.totalGastos;
    
    print('📈 Cálculos automáticos:');
    print('🏦 Total Ventas: RD${calculatedTotalVentas.toStringAsFixed(2)}');
    print('🏆 Balance Neto: RD${calculatedBalanceNeto.toStringAsFixed(2)} ${calculatedBalanceNeto >= 0 ? '✅' : '❌'}');
    print('');
    
    // Test temporal: Si todos los valores son 0, usar datos de prueba
    if (widget.totalEfectivo == 0 && widget.totalTarjeta == 0 && widget.totalTransferencia == 0 && widget.totalGastos == 0) {
      print('⚠️ ADVERTENCIA: No hay ventas ni gastos del día detectados');
      print('🔍 Verificar que existan transacciones en Firebase para hoy');
      print('📅 Fecha actual: ${DateTime.now().toString()}');
    } else {
      print('✅ Datos válidos recibidos - Modal listo para mostrar');
    }
    print('🎯 ===================================');
  }

  double get totalContado {
    double total = 0;
    cantidades.forEach((den, cant) {
      total += den * cant;
    });
    return total;
  }

  double get totalVentasDelDia {
    return widget.totalEfectivo + widget.totalTarjeta + widget.totalTransferencia;
  }

  double get totalNetoPorDia {
    return totalVentasDelDia - widget.totalGastos;
  }

  @override
  Widget build(BuildContext context) {
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
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green),
                        const SizedBox(width: 6),
                        Text('Pagos en Efectivo: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('RD${widget.totalEfectivo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text('Pagos con Tarjeta: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('RD${widget.totalTarjeta.toStringAsFixed(2)}', style: const TextStyle(color: Colors.deepPurple)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('Pagos por Transferencia: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('RD${widget.totalTransferencia.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Text('Total Ventas del Día: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('RD${totalVentasDelDia.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.remove_circle, color: Colors.red),
                        const SizedBox(width: 6),
                        Text('Total Gastos del Día: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('RD${widget.totalGastos.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 2, color: Colors.green),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.green),
                        const SizedBox(width: 6),
                        Text('Balance Neto del Día: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                        Text('RD${totalNetoPorDia.toStringAsFixed(2)}', style: TextStyle(color: totalNetoPorDia >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  Text('Total contado en efectivo: RD${totalContado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('(Solo se cuenta el efectivo físico)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: totalContado == widget.totalEfectivo ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      totalContado == widget.totalEfectivo
                          ? '¡El cuadre de efectivo coincide!'
                          : 'Diferencia en efectivo: RD${(totalContado - widget.totalEfectivo).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: totalContado == widget.totalEfectivo ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            // Aquí puedes agregar la lógica de "cuadrar" si se requiere
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Cuadre de Caja Realizado', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('💰 Total ventas del día: RD${totalVentasDelDia.toStringAsFixed(2)}'),
                    Text('� Total gastos del día: RD${widget.totalGastos.toStringAsFixed(2)}'),
                    Text('🏆 Balance neto del día: RD${totalNetoPorDia.toStringAsFixed(2)}'),
                    Text('�💵 Efectivo contado: RD${totalContado.toStringAsFixed(2)}'),
                    Text('💳 Tarjetas + Transferencias: RD${(widget.totalTarjeta + widget.totalTransferencia).toStringAsFixed(2)}'),
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
                    color: Colors.grey.withOpacity(0.1),
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
