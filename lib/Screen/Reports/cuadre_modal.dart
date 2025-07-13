import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../../commas.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';

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

class _CuadreModalState extends State<CuadreModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // --- Estado para transacciones diarias ---
  Map<String, dynamic> _dailyTransactions = {};
  bool _loading = true;
  
  // Totales generales
  double _totalEfectivo = 0.0;
  double _totalTarjeta = 0.0;
  double _totalTransferencia = 0.0;
  double _totalPagos = 0.0;
  double _totalVentas = 0.0;
  double _totalCobros = 0.0;
  double _totalPendiente = 0.0;
  
  // Desglose de pagos por método
  double _pagoEfectivo = 0.0;
  double _pagoTarjeta = 0.0;
  double _pagoTransferencia = 0.0;

  // Filtros
  late DateTime _hoy;
  late String _hoyFormatted;

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
    _tabController = TabController(length: 2, vsync: this);
    
    _hoy = DateTime.now();
    _hoyFormatted = '${_hoy.year}-${_hoy.month.toString().padLeft(2, '0')}-${_hoy.day.toString().padLeft(2, '0')}';
    
    for (var d in [...billetes, ...monedas]) {
      cantidades[d] = 0;
    }
    
    _fetchDailyTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDailyTransactions() async {
    setState(() => _loading = true);
    try {
      final ref = FirebaseDatabase.instance
          .ref(await getUserID())
          .child('Daily Transaction');
      
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        Map<String, dynamic> allTransactions = 
            Map<String, dynamic>.from(snapshot.value as Map);
        
        // Filtrar por fecha de hoy
       _dailyTransactions = Map.fromEntries(
          allTransactions.entries.where((entry) {
            final date = entry.value['date']?.toString() ?? '';
            return date.contains(_hoyFormatted);
          }),
        );
        
        _calcularTotales();
      }
    } catch (e) {
      debugPrint('Error al cargar transacciones diarias: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _calcularTotales() {
    double efectivo = 0.0;
    double tarjeta = 0.0;
    double transferencia = 0.0;
    double pagos = 0.0;
    double ventas = 0.0;
    double cobros = 0.0;
    double pendiente = 0.0;
    
    double pagoEfectivo = 0.0;
    double pagoTarjeta = 0.0;
    double pagoTransferencia = 0.0;

    _dailyTransactions.forEach((key, value) {
      final type = value['type']?.toString().toLowerCase() ?? '';
      final paymentIn = (value['paymentIn'] as num?)?.toDouble() ?? 0.0;
      final paymentOut = (value['paymentOut'] as num?)?.toDouble() ?? 0.0;
      final total = (value['total'] as num?)?.toDouble() ?? 0.0;
      final remainingBalance = (value['remainingBalance'] as num?)?.toDouble() ?? 0.0;
      
      // Determinar método de pago
      String paymentType = '';
      if (value['saleTransactionModel'] != null) {
        paymentType = value['saleTransactionModel']['paymentType'] ?? '';
      } else if (value['dueTransactionModel'] != null) {
        paymentType = value['dueTransactionModel']['paymentType'] ?? '';
      } else if (value['paymentTransactionModel'] != null) {
        paymentType = value['paymentTransactionModel']['paymentType'] ?? '';
      }
      
      final metodoPago = _categorizarMetodoPago(paymentType);

      if (type == 'sale') {
        ventas += total;
        pendiente += remainingBalance;
        
        if (metodoPago == 'Efectivo') {
          efectivo += paymentIn;
        } else if (metodoPago == 'Tarjeta') {
          tarjeta += paymentIn;
        } else if (metodoPago == 'Transferencia') {
          transferencia += paymentIn;
        }
      } 
      else if (type == 'due collection') {
        cobros += paymentIn;
        
        if (metodoPago == 'Efectivo') {
          efectivo += paymentIn;
        } else if (metodoPago == 'Tarjeta') {
          tarjeta += paymentIn;
        } else if (metodoPago == 'Transferencia') {
          transferencia += paymentIn;
        }
      }
      else if (type == 'payment') {
        pagos += paymentOut;
        
        if (metodoPago == 'Efectivo') {
          pagoEfectivo += paymentOut;
        } else if (metodoPago == 'Tarjeta') {
          pagoTarjeta += paymentOut;
        } else if (metodoPago == 'Transferencia') {
          pagoTransferencia += paymentOut;
        }
      }
    });

    setState(() {
      _totalEfectivo = efectivo;
      _totalTarjeta = tarjeta;
      _totalTransferencia = transferencia;
      _totalPagos = pagos;
      _totalVentas = ventas;
      _totalCobros = cobros;
      _totalPendiente = pendiente;
      _pagoEfectivo = pagoEfectivo;
      _pagoTarjeta = pagoTarjeta;
      _pagoTransferencia = pagoTransferencia;
    });
  }

  String _categorizarMetodoPago(String? paymentType) {
    final tipo = (paymentType ?? '').toLowerCase();
    if (tipo.contains('cash') || tipo.contains('efectivo')) return 'Efectivo';
    if (tipo.contains('card') || tipo.contains('tarjeta') || tipo.contains('bank')) {
      return 'Tarjeta';
    }
    if (tipo.contains('transfer') || tipo.contains('transferencia') || tipo.contains('mobile')) {
      return 'Transferencia';
    }
    return 'Otro';
  }

  String formatCurrency(double amount) {
    return myFormat.format(amount);
  }

  double get totalEfectivo => _totalEfectivo;
  double get totalTarjeta => _totalTarjeta;
  double get totalTransferencia => _totalTransferencia;
  double get totalPagos => _totalPagos;
  double get totalVentas => _totalVentas;
  double get totalCobros => _totalCobros;
  double get totalPendiente => _totalPendiente;
  double get pagoEfectivo => _pagoEfectivo;
  double get pagoTarjeta => _pagoTarjeta;
  double get pagoTransferencia => _pagoTransferencia;

  double get efectivoNeto => totalEfectivo - pagoEfectivo;

  double get totalContado {
    double total = 0;
    cantidades.forEach((den, cant) {
      total += den * cant;
    });
    return total;
  }

  double get totalNetoPorDia {
    return (totalVentas + totalCobros) - (totalPagos + widget.totalGastos);
  }

  String _generateReportText() {
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final bool cuadreOk = totalContado == efectivoNeto;
    final diferencia = (totalContado - efectivoNeto).abs();
    
    return '''🏪 CUADRE DE CAJA
📅 ${_getFormattedDate(now)}

📊 RESUMEN DEL DÍA
💰 Total Ventas: \$${formatCurrency(totalVentas)} RD\$
💵 Total Cobros: \$${formatCurrency(totalCobros)} RD\$
⏰ Pendiente: \$${formatCurrency(totalPendiente)} RD\$
💵 Efectivo Neto: \$${formatCurrency(efectivoNeto)} RD\$
🛒 Total Gastos: \$${formatCurrency(widget.totalGastos)} RD\$

💳 MÉTODOS DE PAGO
💵 Efectivo: \$${formatCurrency(totalEfectivo)} RD\$
💳 Tarjeta: \$${formatCurrency(totalTarjeta)} RD\$
🔄 Transferencia: \$${formatCurrency(totalTransferencia)} RD\$

💰 EFECTIVO FÍSICO
📦 Total Contado: \$${formatCurrency(totalContado)} RD\$
${cuadreOk ? '✅ Cuadre Perfecto' : '⚠️ Diferencia: \$${formatCurrency(diferencia)} RD\$'}

📈 BALANCE FINAL
💰 Balance Neto: \$${formatCurrency(totalNetoPorDia)} RD\$

---
Generado: $formattedDate
Sistema: VICTOR GUZMAN FOTOGRAFIA''';
  }

  String _getFormattedDate(DateTime date) {
    final days = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    
    return '${days[date.weekday]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _sendReportViaWhatsApp(BuildContext context) async {
    try {
      EasyLoading.show(status: 'Enviando reporte de cuadre...');

      final message = _generateReportText();
      const phoneNumber = '+59168774551';

      final body = {
        'token': '5i36w829nb1ljkj7', //token santo domingo
        'to': phoneNumber,
        'body': message,
      };

      final url = Uri.parse('https://api.ultramsg.com/instance127004/messages/chat'); //instancia santo domingo
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Reporte de cuadre enviado');
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cuadre Confirmado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Ventas: RD\$${formatCurrency(totalVentas)}'),
                Text('Cobros: RD\$${formatCurrency(totalCobros)}'),
                Text('Pendientes: RD\$${formatCurrency(totalPendiente)}'),
                Text('Efectivo: RD\$${formatCurrency(totalContado)}'),
              ],
            ),
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        throw Exception('Error en WhatsApp API: ${response.body}');
      }
    } catch (e) {
      EasyLoading.showError('Error al enviar reporte: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width < 600 ? 0.98 : 0.95),
        height: MediaQuery.of(context).size.height * (MediaQuery.of(context).size.width < 600 ? 0.95 : 0.9),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color.fromARGB(255, 219, 127, 21),
                tabs: const [
                  Tab(text: 'Ventas del Día'),
                  Tab(text: 'Cuentas por Cobrar'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab de Ventas
                  _buildVentasTab(),
                  
                  // Tab de Cuentas por Cobrar
                  _buildCuentasPorCobrarTab(),
                ],
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
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.dashboard,
            color: Colors.blue.shade600,
            size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuadre de Caja',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Panel de control diario',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
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

  Widget _buildVentasTab() {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildCuentasPorCobrarTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de cuentas por cobrar
          _buildCuentasPorCobrarResumen(),
          const SizedBox(height: 20),

          // Métodos de pago (cobros)
          _buildMetodosPagoCobros(),
          const SizedBox(height: 20),

          // Pendientes
          _buildPendientesResumen(),
        ],
      ),
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
                  'RD\$${formatCurrency(totalVentas)}',
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

  Widget _buildCuentasPorCobrarResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Cuentas por Cobrar',
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
                  'Total Cobrado',
                  'RD\$${formatCurrency(totalCobros)}',
                  Icons.money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Por Cobrar',
                  'RD\$${formatCurrency(totalPendiente)}',
                  Icons.pending_actions,
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
                'Métodos de Pago (Ventas)',
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

  Widget _buildMetodosPagoCobros() {
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
                'Métodos de Pago (Cobros)',
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
          ),
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
            'Ventas',
            totalVentas,
            Icons.arrow_upward,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Cobros',
            totalCobros,
            Icons.arrow_upward,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Pagos',
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
              color: totalNetoPorDia >= 0
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: totalNetoPorDia >= 0
                    ? Colors.green.shade300
                    : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  totalNetoPorDia >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: totalNetoPorDia >= 0 ? Colors.green : Colors.red,
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
                      'RD\$${formatCurrency(totalNetoPorDia)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: totalNetoPorDia >= 0
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

  Widget _buildPendientesResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Pendientes por Cobrar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ), // ← ✅ cierre correcto del BoxShadow
              ],
            ),
            child: Column(
              children: [
                _buildPendienteRow(
                  'Total Pendiente',
                  totalPendiente,
                  Icons.money_off,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildPendienteRowInt(
                  'Clientes con Saldo',
                  _countClientsWithBalance(),
                  Icons.people,
                  Colors.blue,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  int _countClientsWithBalance() {
    final Set<String> clients = {};
    for (final entry in _dailyTransactions.entries) {
      final value = entry.value;
      final remaining = (value['remainingBalance'] as num?)?.toDouble() ?? 0;
      final clientId = value['id']?.toString() ?? '';
      if (remaining > 0 && clientId.isNotEmpty) {
        clients.add(clientId);
      }
    }
    return clients.length;
  }

  Widget _buildContadorEfectivo() {
  final isMobile = MediaQuery.of(context).size.width < 600;
  return Container(
    padding: EdgeInsets.all(isMobile ? 16 : 20),
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
            Icon(Icons.calculate, color: Colors.indigo.shade600, size: isMobile ? 20 : 24),
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
    final bool cuadreOk = totalContado == efectivoNeto;
    final double diferencia = totalContado - efectivoNeto;

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
                          ? 'El efectivo contado coincide con el sistema'
                          : 'Diferencia: RD\$${formatCurrency(diferencia.abs())}',
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
            onPressed: () => _sendReportViaWhatsApp(context),
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
  String title,
  String value,
  IconData icon,
  Color color,
) {
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
        ), // ✅ cierre correcto del BoxShadow
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 16 : 32),
      child: Row(
        children: [
          Icon(icon, color: color, size: isMobile ? 14 : 16),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}RD\$${formatCurrency(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
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

  Widget _buildPendienteRow(
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
          label.contains('RD') ? 'RD\$${formatCurrency(amount)}' : amount.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPendienteRowInt(
      String label, int amount, IconData icon, Color color) {
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
          amount.toString(),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

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
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen de la denominación
            if (imagen != null)
              Container(
                width: isMobile ? 90 : 120,
                height: isMobile ? 60 : 80,
                margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
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
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.width < 600 ? 6 : 8, 
                    horizontal: MediaQuery.of(context).size.width < 600 ? 2 : 4
                  ),
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