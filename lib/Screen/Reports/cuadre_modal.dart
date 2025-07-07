import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';
import 'widget/cuadre_report_provider.dart';
import 'widget/send_report.dart';

class CuadreModal extends StatefulWidget {
  final List<SaleTransactionModel> ventasDelDia;
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
  double _totalVentasDia = 0.0; // Total de ventas del día
  double _totalVentasDiaPagado = 0.0; // Total de ventas del día
  double _totalPendiente = 0.0; // Total de montos pendientes del día

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
    debugPrint('totalPendiente:    $totalPendiente');
    debugPrint('totalNetoPorDia:   $totalNetoPorDia');
    debugPrint('totalContado:      $totalContado');
    debugPrint('cantidades:        $cantidades');
    debugPrint('--------------------------------');
  }

  /// Función utilitaria para categorizar métodos de pago de forma robusta (idéntica a report_screen.dart)
  String categorizarMetodoPago(String? paymentType) {
    final tipo = (paymentType ?? '').toLowerCase();
    if (tipo.contains('cash') || tipo.contains('efectivo')) return 'Efectivo';
    if (tipo.contains('card') ||
        tipo.contains('tarjeta') ||
        tipo.contains('bank')) {
      return 'Tarjeta';
    }
    if (tipo.contains('transfer') ||
        tipo.contains('transferencia') ||
        tipo.contains('mobile')) {
      return 'Transferencia';
    }
    return 'Otro';
  }

  // Denominaciones de RD$
  final List<int> billetes = [2000, 1000, 500, 200, 100, 50];
  final List<int> monedas = [25, 10, 5, 1];
  final Map<int, String> imagenesBilletes = {
    2000: 'images/billete_2000.svg',
    1000: 'images/billete_1000.svg',
    500: 'images/billete_500.svg',
    200: 'images/billete_200.svg',
    100: 'images/billete_100.svg',
    50: 'images/billete_50.svg',
  };
  final Map<int, String> imagenesMonedas = {
    25: 'images/moneda_25.svg',
    10: 'images/moneda_10.svg',
    5: 'images/moneda_5.svg',
    1: 'images/moneda_1.svg',
  };
  Map<int, int> cantidades = {};

  @override
  void initState() {
    super.initState();
    _hoy =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    debugPrint(
        '[CuadreModal] initState ejecutado. ventasDelDia: \\${widget.ventasDelDia.length}');
    for (var d in [...billetes, ...monedas]) {
      cantidades[d] = 0;
    }

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
    double ventasDia = 0.0; // Variable temporal para el total de ventas del día
    double ventasTotal = 0.0;
    double totalPendiente = 0.0; // Variable temporal para el total pendiente

    debugPrint('[CuadreModal] INICIANDO CÁLCULO DE TOTALES DESDE VENTAS');
    debugPrint(
        '[CuadreModal] Total de ventas a procesar: ${widget.ventasDelDia.length}');

    for (var venta in widget.ventasDelDia) {
      final paymentType = venta.paymentType;
      final amount = venta.totalAmount; // Importe total de la venta
      final pendiente = venta.dueAmount ?? 0; // Importe pendiente
      final tipo = venta.paymentType; // Para distinguir entre ventas y pagos
      final id = venta.invoiceNumber;

      debugPrint('[CuadreModal] Procesando venta/pago ID: $id');
      debugPrint(
          '[CuadreModal]   - Tipo: $tipo, Método Pago: $paymentType, Total: $amount, Pendiente: $pendiente');

      if (amount != null) {
        final double montoTotal = amount;
        final double montoPendiente = pendiente;

        // Calculamos el monto realmente pagado (total - pendiente)
        final double montoPagado = montoTotal - montoPendiente;

        debugPrint(
            '[CuadreModal]   - Monto calculado real pagado: $montoPagado');
        debugPrint('[CuadreModal]   - Monto pendiente: $montoPendiente');

        final metodoPago = categorizarMetodoPago(paymentType);

        // Si es un pago (salida de dinero)
        if (tipo != null && tipo.toString().toLowerCase() == 'payment') {
          pagos += montoTotal;

          // Desglosar el pago por método
          if (metodoPago == 'Efectivo') {
            pagoEfectivo += montoTotal;
            debugPrint(
                '[CuadreModal] ✓ Pago en Efectivo: $montoTotal, Total Acumulado: $pagoEfectivo');
          } else if (metodoPago == 'Tarjeta') {
            pagoTarjeta += montoTotal;
            debugPrint(
                '[CuadreModal] ✓ Pago con Tarjeta: $montoTotal, Total Acumulado: $pagoTarjeta');
          } else if (metodoPago == 'Transferencia') {
            pagoTransferencia += montoTotal;
            debugPrint(
                '[CuadreModal] ✓ Pago por Transferencia: $montoTotal, Total Acumulado: $pagoTransferencia');
          }

          continue;
        }

        // Primero sumamos al total de ventas del día y acumulamos pendientes
        ventasDia += montoPagado; // Sumamos sólo lo realmente pagado
        ventasTotal += montoTotal;

        if (montoPendiente > 0) {
          totalPendiente += montoPendiente; // Acumulamos los montos pendientes
          debugPrint(
              '[CuadreModal] ✓ Pendiente detectado: $montoPendiente, Total Acumulado: $totalPendiente');
        }

        // Luego distribuimos por método de pago
        if (metodoPago == 'Efectivo') {
          efectivo += montoPagado; // Restamos el monto pendiente
          debugPrint(
              '[CuadreModal] ✓ Venta en Efectivo - Total: $montoTotal, Pendiente: $montoPendiente, Pagado: $montoPagado, Acumulado: $efectivo');
        } else if (metodoPago == 'Tarjeta') {
          tarjeta += montoPagado; // Restamos el monto pendiente
          debugPrint(
              '[CuadreModal] ✓ Venta con Tarjeta - Total: $montoTotal, Pendiente: $montoPendiente, Pagado: $montoPagado, Acumulado: $tarjeta');
        } else if (metodoPago == 'Transferencia') {
          transferencia += montoPagado; // Restamos el monto pendiente
          debugPrint(
              '[CuadreModal] ✓ Venta por Transferencia - Total: $montoTotal, Pendiente: $montoPendiente, Pagado: $montoPagado, Acumulado: $transferencia');
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
      _totalVentasDia = ventasTotal; // Actualiza el total de ventas del día
      _totalVentasDiaPagado = ventasDia;
      _totalPendiente = totalPendiente; // Actualiza el total pendiente
    });

    // Imprimir resumen final para depuración
    debugPrint('=================================================');
    debugPrint('[CuadreModal] RESUMEN DE TOTALES CALCULADOS:');
    debugPrint('    - Total Ventas del Día: $_totalVentasDia');
    debugPrint('    - Total Pendiente: $_totalPendiente');
    debugPrint('    - Efectivo: $_totalEfectivo');
    debugPrint('    - Tarjeta: $_totalTarjeta');
    debugPrint('    - Transferencia: $_totalTransferencia');
    debugPrint('    - Total Pagos: $_totalPagos');
    debugPrint('    - Pagos Efectivo: $_pagoEfectivo');
    debugPrint('    - Pagos Tarjeta: $_pagoTarjeta');
    debugPrint('    - Pagos Transferencia: $_pagoTransferencia');
    debugPrint('  Efectivo Neto: ${_totalEfectivo - _pagoEfectivo}');
    debugPrint('=================================================');
  }

  Future<void> _fetchPagosDesdeFirebase() async {
    setState(() => _loadingPagos = true);
    try {
      final ref = FirebaseDatabase.instance
          .ref(await getUserID())
          .child('Daily Transaction');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<String, dynamic> allDailyTransactions =
            Map<String, dynamic>.from(snapshot.value as Map);

        // Filtrar por IDs
        Map<String, dynamic> filteredTransactions = {};

        for (var transaction in widget.ventasDelDia) {
          final matchingEntries = allDailyTransactions.entries
              .where((entry) => entry.value['id'] == transaction.invoiceNumber);

          for (var entry in matchingEntries) {
            filteredTransactions[entry.key] = entry.value;
          }
        }

        // Si encontramos movimientos en Firebase, usar esos totales
        if (filteredTransactions.isNotEmpty) {
          _dailyTransactions = filteredTransactions;

          // Solo sobrescribimos los valores si encontramos algo en Firebase
          debugPrint(
              '[CuadreModal] =================================================');
          debugPrint(
              '[CuadreModal] INICIANDO CÁLCULO DE TOTALES DESDE FIREBASE');
          double efectivoFB = calculateTotalMoney(_dailyTransactions);
          double tarjetaFB = calculateTotalCard(_dailyTransactions);
          double transferenciaFB = calculateTotalTransfer(_dailyTransactions);
          double pagosFB = _calculateTotalPayments(_dailyTransactions);

          debugPrint('[CuadreModal] COMPARACIÓN DE TOTALES:');
          debugPrint(
              '[CuadreModal]   Efectivo - Directo: $_totalEfectivo, Firebase: $efectivoFB');
          debugPrint(
              '[CuadreModal]   Tarjeta - Directo: $_totalTarjeta, Firebase: $tarjetaFB');
          debugPrint(
              '[CuadreModal]   Transferencia - Directo: $_totalTransferencia, Firebase: $transferenciaFB');
          debugPrint(
              '[CuadreModal]   Pagos - Directo: $_totalPagos, Firebase: $pagosFB');

          if (efectivoFB > 0 ||
              tarjetaFB > 0 ||
              transferenciaFB > 0 ||
              pagosFB > 0) {
            setState(() {
              _totalEfectivo = efectivoFB;
              _totalTarjeta = tarjetaFB;
              _totalTransferencia = transferenciaFB;
              _totalPagos = pagosFB;
              // Mantener el valor de totalPendiente calculado previamente
              // _totalPendiente no se modifica desde Firebase
            });

            debugPrint('[CuadreModal] Totales actualizados desde Firebase:');
            debugPrint('  Efectivo: $_totalEfectivo');
            debugPrint('  Tarjeta: $_totalTarjeta');
            debugPrint('  Transferencia: $_totalTransferencia');
            debugPrint('  Pagos: $_totalPagos');
            debugPrint('  Total Pendiente (mantenido): $_totalPendiente');
          } else {
            debugPrint(
                '[CuadreModal] Todos los totales de Firebase son 0, manteniendo totales directos');
          }
        } else {
          debugPrint(
              '[CuadreModal] No se encontraron transacciones en Firebase que coincidan con las ventas');
        }
      } else {
        debugPrint(
            '[CuadreModal] No existen transacciones en Firebase para este usuario');
      }
    } catch (e) {
      debugPrint('Error al consultar pagos desde Firebase: $e');
    }
    setState(() => _loadingPagos = false);
  }

  double calculateTotalMoney(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      final paymentType =
          value[type == 'Sale' ? 'saleTransactionModel' : 'dueTransactionModel']
              ?['paymentType'];
      if (categorizarMetodoPago(paymentType) == 'Efectivo') {
        total += (value['paymentIn'] as num).toDouble();
      }
    });
    return total;
  }

  double calculateTotalTransfer(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      final paymentType =
          value[type == 'Sale' ? 'saleTransactionModel' : 'dueTransactionModel']
              ?['paymentType'];
      if (categorizarMetodoPago(paymentType) == 'Transferencia') {
        total += (value['paymentIn'] as num).toDouble();
      }
    });
    return total;
  }

  double calculateTotalCard(Map<String, dynamic> dailyTransactions) {
    double total = 0.0;
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      final paymentType =
          value[type == 'Sale' ? 'saleTransactionModel' : 'dueTransactionModel']
              ?['paymentType'];
      if (categorizarMetodoPago(paymentType) == 'Tarjeta') {
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

    debugPrint('[CuadreModal] CALCULANDO PAGOS (SALIDAS) DESDE FIREBASE:');

    dailyTransactions.forEach((key, value) {
      final type = value['type']?.toString().toLowerCase() ?? '';
      final id = value['id'] ?? value['invoiceNumber'];

      if (type == 'payment') {
        final double monto = (value['paymentOut'] as num? ?? 0).toDouble();
        total += monto;

        // Desglosar por método de pago
        final paymentType = value['paymentTransactionModel']?['paymentType'];
        final metodoPago = categorizarMetodoPago(paymentType);

        if (metodoPago == 'Efectivo') {
          efectivo += monto;
          debugPrint(
              '[CuadreModal] Firebase - Pago Efectivo ID $id: $monto, Acumulado=$efectivo');
        } else if (metodoPago == 'Tarjeta') {
          tarjeta += monto;
          debugPrint(
              '[CuadreModal] Firebase - Pago Tarjeta ID $id: $monto, Acumulado=$tarjeta');
        } else if (metodoPago == 'Transferencia') {
          transferencia += monto;
          debugPrint(
              '[CuadreModal] Firebase - Pago Transferencia ID $id: $monto, Acumulado=$transferencia');
        }
      }
    });

    // Guardar los desgloses
    setState(() {
      _pagoEfectivo = efectivo;
      _pagoTarjeta = tarjeta;
      _pagoTransferencia = transferencia;
    });

    debugPrint('[CuadreModal] RESUMEN PAGOS DESDE FIREBASE:');
    debugPrint('  Total Pagos: $total');
    debugPrint('  - Efectivo: $efectivo');
    debugPrint('  - Tarjeta: $tarjeta');
    debugPrint('  - Transferencia: $transferencia');

    return total;
  }

  double get totalEfectivo => _totalEfectivo;
  double get totalTarjeta => _totalTarjeta;
  double get totalTransferencia => _totalTransferencia;
  double get totalPagos => _totalPagos;
  double get pagoEfectivo => _pagoEfectivo;
  double get pagoTarjeta => _pagoTarjeta;
  double get pagoTransferencia => _pagoTransferencia;
  double get totalPendiente => _totalPendiente;
  double get totalVentasDia => _totalVentasDia;
  double get totalVentasDiaPagado => _totalVentasDiaPagado;

  double get totalVentasDelDia => _totalVentasDia;

  double get totalVentasNetoDelDia =>
      totalVentasDelDia - totalPendiente - widget.totalGastos - totalPagos;

  // Efectivo neto = ingreso efectivo - pagos en efectivo
  double get efectivoNeto => totalEfectivo - pagoEfectivo;

  // Nuevos getters para el cuadre
  double get diferenciaCuadre => totalContado - efectivoNeto;
  bool get cuadreOk => diferenciaCuadre.abs() < 0.01; // Tolerancia de 1 centavo

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
    logDebugData();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen de ventas
                    _buildVentasResumen(),
                    const SizedBox(height: 20),

                    // Métodos de pago
                    _buildMetodosPago(),
                    const SizedBox(height: 20),

                    // Balance del día
                    _buildBalanceDelDia(),
                    const SizedBox(height: 20),

                    // Contador de efectivo
                    _buildContadorEfectivo(),
                    const SizedBox(height: 20),

                    // Verificación de cuadre
                    _buildVerificacionCuadre(),
                  ],
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 20),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.dashboard,
            color: Colors.blue.shade600,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuadre de Caja',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Panel de control diario',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildVentasResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Resumen de Ventas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Ventas',
                  'RD\$${formatCurrency(totalVentasDia)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Pendiente',
                  'RD\$${formatCurrency(totalPendiente)}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetodosPago() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Métodos de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodRow(
            'Efectivo',
            totalEfectivo,
            Icons.money,
            Colors.green,
            showSubItems: pagoEfectivo > 0,
          ),
          if (pagoEfectivo > 0) ...[
            const SizedBox(height: 8),
            _buildPaymentSubItem(
              'Salida efectivo',
              pagoEfectivo,
              Icons.remove_circle_outline,
              Colors.red,
              isNegative: true,
            ),
            const SizedBox(height: 8),
            _buildPaymentSubItem(
              'Efectivo neto',
              efectivoNeto,
              Icons.check_circle,
              Colors.teal,
            ),
          ],
          const SizedBox(height: 12),
          _buildPaymentMethodRow(
            'Tarjeta',
            totalTarjeta,
            Icons.credit_card,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodRow(
            'Transferencia',
            totalTransferencia,
            Icons.swap_horiz,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDelDia() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance,
                  color: Colors.teal.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Balance del Día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBalanceRow(
            'Entradas',
            totalVentasDiaPagado,
            Icons.arrow_upward,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Salidas',
            totalPagos,
            Icons.arrow_downward,
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Gastos',
            widget.totalGastos,
            Icons.shopping_cart,
            Colors.red,
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 2),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: totalVentasNetoDelDia >= 0
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: totalVentasNetoDelDia >= 0
                    ? Colors.green.shade300
                    : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  totalVentasNetoDelDia >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: totalVentasNetoDelDia >= 0 ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance Neto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'RD\$${formatCurrency(totalVentasNetoDelDia)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: totalVentasNetoDelDia >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContadorEfectivo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.indigo.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Contador de Efectivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Billetes
          _buildDenominationSection('Billetes', billetes, imagenesBilletes),
          const SizedBox(height: 16),

          // Monedas
          _buildDenominationSection('Monedas', monedas, imagenesMonedas),
          const SizedBox(height: 16),

          // Total contado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Contado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'RD\$${formatCurrency(totalContado)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificacionCuadre() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cuadreOk ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cuadreOk ? Colors.green.shade300 : Colors.red.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                cuadreOk ? Icons.check_circle : Icons.warning,
                color: cuadreOk ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cuadreOk ? 'Cuadre Perfecto' : 'Diferencia Detectada',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cuadreOk ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      cuadreOk
                          ? 'El efectivo contado coincide con el sistema.'
                          : 'Diferencia: RD\$${formatCurrency(diferenciaCuadre.abs())}',
                      style: TextStyle(
                        fontSize: 14,
                        color: cuadreOk
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // 1. Crear el objeto CuadreData con toda la información
              final cuadreData = CuadreReportProvider.createCuadreDataFromModal(
                fecha: _hoy,
                totalVentasDia: totalVentasDia,
                totalPendiente: totalPendiente,
                totalEfectivo: totalEfectivo,
                totalTarjeta: totalTarjeta,
                totalTransferencia: totalTransferencia,
                totalPagos: totalPagos,
                pagoEfectivo: pagoEfectivo,
                pagoTarjeta: pagoTarjeta,
                pagoTransferencia: pagoTransferencia,
                totalGastos: widget.totalGastos,
                totalContado: totalContado,
                ventasDelDia: widget.ventasDelDia,
                cantidadesDenominaciones: cantidades,
              );

              // 2. Mostrar el diálogo para enviar el reporte
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SendReportDialog(cuadreData: cuadreData);
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmar Cuadre',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

// Métodos auxiliares para construir componentes
  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(
      String method, double amount, IconData icon, Color color,
      {bool showSubItems = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            'RD\$${formatCurrency(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSubItem(
      String label, double amount, IconData icon, Color color,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}RD\$${formatCurrency(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(
      String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          'RD\$${formatCurrency(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDenInputCompacto(int denominacion, String tipo, String? imagen) {
    final cantidad = cantidades[denominacion] ?? 0;
    final valor = denominacion * cantidad;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen de la denominación
            if (imagen != null)
              Container(
                width: 120,
                height: 80,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SvgPicture.asset(
                    imagen,
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => Icon(
                      tipo == 'Billete' ? Icons.money : Icons.monetization_on,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Denominación
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'RD\$$denominacion',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Input de cantidad
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                initialValue: cantidad.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                onChanged: (val) {
                  final newValue = int.tryParse(val) ?? 0;
                  if (mounted) {
                    setState(() {
                      cantidades[denominacion] = newValue;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 6),

            // Valor calculado
            if (valor > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'RD\$${formatCurrency(valor.toDouble())}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              )
            else
              Container(
                height: 16,
                child: Text(
                  'RD\$0',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Actualización para el método _buildDenominationSection
  Widget _buildDenominationSection(
      String title, List<dynamic> denominations, Map<dynamic, String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Opción 1: Grid layout (recomendado para billetes)
        if (title == 'Billetes')
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: denominations
                .map((denominacion) => SizedBox(
                    width: 250,
                    child: _buildDenInputCompacto(
                        denominacion,
                        title.substring(0, title.length - 1),
                        images[denominacion])))
                .toList(),
          )
        else
          // Opción 2: Horizontal layout (para monedas)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: denominations
                .map((denominacion) => SizedBox(
                      width: 90,
                      child: _buildDenInputCompacto(
                          denominacion,
                          title.substring(0, title.length - 1),
                          images[denominacion]),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
