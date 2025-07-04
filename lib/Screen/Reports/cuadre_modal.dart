import 'package:flutter/material.dart';

class CuadreModal extends StatefulWidget {
  final double totalEfectivo;
  final double totalTarjeta;
  final double totalTransferencia;
  CuadreModal({
    required this.totalEfectivo,
    required this.totalTarjeta,
    required this.totalTransferencia,
  });

  @override
  State<CuadreModal> createState() => _CuadreModalState();
}

class _CuadreModalState extends State<CuadreModal> {
  // Denominaciones de RD$
  final List<int> billetes = [2000, 1000, 500, 200, 100, 50];
  final List<int> monedas = [25, 10, 5, 1];
  Map<int, int> cantidades = {};

  @override
  void initState() {
    super.initState();
    for (var d in [...billetes, ...monedas]) {
      cantidades[d] = 0;
    }
  }

  double get totalContado {
    double total = 0;
    cantidades.forEach((den, cant) {
      total += den * cant;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cuadre de Caja'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pagos en Efectivo: RD${widget.totalEfectivo.toStringAsFixed(2)}'),
            Text('Pagos con Tarjeta: RD${widget.totalTarjeta.toStringAsFixed(2)}'),
            Text('Pagos por Transferencia: RD${widget.totalTransferencia.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Ingrese la cantidad de cada denominación:'),
            ...billetes.map((den) => _buildDenInput(den, 'Billete')).toList(),
            ...monedas.map((den) => _buildDenInput(den, 'Moneda')).toList(),
            const SizedBox(height: 16),
            Text('Total contado: RD${totalContado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              totalContado == widget.totalEfectivo
                  ? '¡El cuadre coincide!'
                  : 'Diferencia: RD${(totalContado - widget.totalEfectivo).toStringAsFixed(2)}',
              style: TextStyle(
                color: totalContado == widget.totalEfectivo ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildDenInput(int denominacion, String tipo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$tipo RD$denominacion'),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: cantidades[denominacion]?.toString() ?? '0',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                border: OutlineInputBorder(),
              ),
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
