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
  List<Map<String, dynamic>> _dailyTransactions = [];
  List<Map<String, dynamic>> _ventasDelDia = [];
  List<Map<String, dynamic>> _cobrosDelDia = [];
  List<Map<String, dynamic>> _pagosDelDia = [];
  bool _loading = true;
  
  // Totales
  double _totalEfectivoVentas = 0.0;
  double _totalTarjetaVentas = 0.0;
  double _totalTransferenciaVentas = 0.0;
  double _totalEfectivoCobros = 0.0;
  double _totalTarjetaCobros = 0.0;
  double _totalTransferenciaCobros = 0.0;
  double _totalPagos = 0.0;
  double _totalVentasDia = 0.0;
  double _totalCobrosDia = 0.0;
  double _totalPendiente = 0.0;
  
  // Desglose de pagos por método
  double _pagoEfectivo = 0.0;
  double _pagoTarjeta = 0.0;
  double _pagoTransferencia = 0.0;

  // Fecha actual
  late DateTime _hoy;
  late DateTime _inicioDia;
  late DateTime _finDia;

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
    _inicioDia = DateTime(_hoy.year, _hoy.month, _hoy.day);
    _finDia = _inicioDia.add(const Duration(days: 1));
    
    for (var d in [...billetes, ...monedas]) {
      cantidades[d] = 0;
    }

    _cargarDailyTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDailyTransactions() async {
    setState(() => _loading = true);
    try {
      final ref = FirebaseDatabase.instance
          .ref(await getUserID())
          .child('Daily Transaction');
      
      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        _dailyTransactions = [];
        
        values.forEach((key, value) {
          Map<String, dynamic> transaction = {
            'key': key,
            ...Map<String, dynamic>.from(value)
          };
          
          if (transaction['date'] != null) {
            try {
              final dateStr = transaction['date'] as String;
              final date = DateTime.parse(dateStr);
              
              if (date.isAfter(_inicioDia) && date.isBefore(_finDia)) {
                _dailyTransactions.add(transaction);
              }
            } catch (e) {
              debugPrint('Error al parsear fecha: ${transaction['date']}');
            }
          }
        });

        debugPrint('Transacciones del día encontradas: ${_dailyTransactions.length}');
        
        _clasificarTransacciones();
        _calcularTotales();
      } else {
        debugPrint('No se encontraron transacciones en Daily Transaction');
      }
    } catch (e) {
      debugPrint('Error al cargar Daily Transactions: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _clasificarTransacciones() {
    _ventasDelDia = [];
    _cobrosDelDia = [];
    _pagosDelDia = [];
    
    for (var transaction in _dailyTransactions) {
      final type = transaction['type']?.toString().toLowerCase();
      
      if (type == 'sale') {
        _ventasDelDia.add(transaction);
      } else if (type == 'due collection') {
        _cobrosDelDia.add(transaction);
      } else if (type == 'payment') {
        _pagosDelDia.add(transaction);
      }
    }
    
    debugPrint('Ventas: ${_ventasDelDia.length}');
    debugPrint('Cobros: ${_cobrosDelDia.length}');
    debugPrint('Pagos: ${_pagosDelDia.length}');
  }

  void _calcularTotales() {
    double efectivoVentas = 0.0;
    double tarjetaVentas = 0.0;
    double transferenciaVentas = 0.0;
    double efectivoCobros = 0.0;
    double tarjetaCobros = 0.0;
    double transferenciaCobros = 0.0;
    double pagos = 0.0;
    double pagoEfectivo = 0.0;
    double pagoTarjeta = 0.0;
    double pagoTransferencia = 0.0;
    double ventasDia = 0.0;
    double cobrosDia = 0.0;
    double pendiente = 0.0;

    // Procesar ventas - Solo sumamos paymentIn
    for (var venta in _ventasDelDia) {
      final paymentIn = (venta['paymentIn'] as num?)?.toDouble() ?? 0;
      final remainingBalance = (venta['remainingBalance'] as num?)?.toDouble() ?? 0;
      
      ventasDia += paymentIn;
      pendiente += remainingBalance;
      
      final paymentType = venta['paymentType']?.toString().toLowerCase() ?? 'cash';
      
      if (paymentType.contains('cash') || paymentType.contains('efectivo')) {
        efectivoVentas += paymentIn;
      } else if (paymentType.contains('card') || paymentType.contains('tarjeta')) {
        tarjetaVentas += paymentIn;
      } else if (paymentType.contains('transfer') || paymentType.contains('transferencia')) {
        transferenciaVentas += paymentIn;
      }
    }

    // Procesar cobros - Solo sumamos paymentIn
    for (var cobro in _cobrosDelDia) {
      final paymentIn = (cobro['paymentIn'] as num?)?.toDouble() ?? 0;
      cobrosDia += paymentIn;
      
      final paymentType = cobro['paymentType']?.toString().toLowerCase() ?? 'cash';
      
      if (paymentType.contains('cash') || paymentType.contains('efectivo')) {
        efectivoCobros += paymentIn;
      } else if (paymentType.contains('card') || paymentType.contains('tarjeta')) {
        tarjetaCobros += paymentIn;
      } else if (paymentType.contains('transfer') || paymentType.contains('transferencia')) {
        transferenciaCobros += paymentIn;
      }
    }

    // Procesar pagos (salidas)
    for (var pago in _pagosDelDia) {
      final paymentOut = (pago['paymentOut'] as num?)?.toDouble() ?? 0;
      pagos += paymentOut;
      
      final paymentType = pago['paymentType']?.toString().toLowerCase() ?? 'cash';
      
      if (paymentType.contains('cash') || paymentType.contains('efectivo')) {
        pagoEfectivo += paymentOut;
      } else if (paymentType.contains('card') || paymentType.contains('tarjeta')) {
        pagoTarjeta += paymentOut;
      } else if (paymentType.contains('transfer') || paymentType.contains('transferencia')) {
        pagoTransferencia += paymentOut;
      }
    }

    setState(() {
      _totalEfectivoVentas = efectivoVentas;
      _totalTarjetaVentas = tarjetaVentas;
      _totalTransferenciaVentas = transferenciaVentas;
      _totalEfectivoCobros = efectivoCobros;
      _totalTarjetaCobros = tarjetaCobros;
      _totalTransferenciaCobros = transferenciaCobros;
      _totalPagos = pagos;
      _pagoEfectivo = pagoEfectivo;
      _pagoTarjeta = pagoTarjeta;
      _pagoTransferencia = pagoTransferencia;
      _totalVentasDia = ventasDia;
      _totalCobrosDia = cobrosDia;
      _totalPendiente = pendiente;
    });

    debugPrint('''
    Totales calculados:
    - Efectivo Ventas: $_totalEfectivoVentas
    - Tarjeta Ventas: $_totalTarjetaVentas
    - Transferencia Ventas: $_totalTransferenciaVentas
    - Efectivo Cobros: $_totalEfectivoCobros
    - Tarjeta Cobros: $_totalTarjetaCobros
    - Transferencia Cobros: $_totalTransferenciaCobros
    - Pagos: $_totalPagos
    - Ventas: $_totalVentasDia
    - Cobros: $_totalCobrosDia
    - Pendiente: $_totalPendiente
    ''');
  }

  String formatCurrency(double amount) {
    return myFormat.format(amount);
  }

  String _getFormattedDate(DateTime date) {
    final days = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    
    // Asegurarse de que el índice del día de la semana esté en el rango correcto (0-6)
    int weekday = date.weekday % 7;
    // Asegurarse de que el índice del mes esté en el rango correcto (0-11)
    int month = date.month - 1;
    
    return '${days[weekday]}, ${date.day} ${months[month]} ${date.year}';
  }

  String _generateReportText() {
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final bool cuadreOk = totalContado == efectivoNeto;
    final diferencia = (totalContado - efectivoNeto).abs();
    
    return '''🏪 CUADRE DE CAJA
📅 ${_getFormattedDate(now)}

📊 RESUMEN DEL DÍA
💰 Total Ventas: \$${formatCurrency(_totalVentasDia)} RD\$
💵 Cobros del día: \$${formatCurrency(_totalCobrosDia)} RD\$
⏰ Pendiente: \$${formatCurrency(_totalPendiente)} RD\$
💵 Efectivo Neto: \$${formatCurrency(efectivoNeto)} RD\$
🛒 Total Gastos: \$${formatCurrency(widget.totalGastos)} RD\$

💳 MÉTODOS DE PAGO
💵 Efectivo: \$${formatCurrency(_totalEfectivoVentas + _totalEfectivoCobros)} RD\$
💳 Tarjeta: \$${formatCurrency(_totalTarjetaVentas + _totalTarjetaCobros)} RD\$
🔄 Transferencia: \$${formatCurrency(_totalTransferenciaVentas + _totalTransferenciaCobros)} RD\$

💰 EFECTIVO FÍSICO
📦 Total Contado: \$${formatCurrency(totalContado)} RD\$
${cuadreOk ? '✅ Cuadre Perfecto' : '⚠️ Diferencia: \$${formatCurrency(diferencia)} RD\$'}

📈 BALANCE FINAL
💰 Balance Neto: \$${formatCurrency(totalNetoPorDia)} RD\$

---
Generado: $formattedDate
Sistema: VICTOR GUZMAN FOTOGRAFIA''';
  }

  Future<void> _sendReportViaWhatsApp(BuildContext context) async {
    try {
      EasyLoading.show(status: 'Enviando reporte de cuadre...');

      final message = _generateReportText();
      const phoneNumber = '+59168774551';

      final body = {
        'token': '5i36w829nb1ljkj7',
        'to': phoneNumber,
        'body': message,
      };

      final url = Uri.parse('https://api.ultramsg.com/instance127004/messages/chat');
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Reporte de cuadre enviado');
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (mounted) {
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
                  Text('Ventas: RD\$${formatCurrency(_totalVentasDia)}'),
                  Text('Cobros: RD\$${formatCurrency(_totalCobrosDia)}'),
                  Text('Pendientes: RD\$${formatCurrency(_totalPendiente)}'),
                  Text('Efectivo: RD\$${formatCurrency(totalContado)}'),
                ],
              ),
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        throw Exception('Error en WhatsApp API: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        EasyLoading.showError('Error al enviar reporte: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        EasyLoading.dismiss();
      }
    }
  }

  // Getters para los totales
  double get efectivoNeto => (_totalEfectivoVentas + _totalEfectivoCobros) - _pagoEfectivo;
  double get totalContado {
    double total = 0;
    cantidades.forEach((den, cant) {
      total += den * cant;
    });
    return total;
  }
  double get totalNetoPorDia => (_totalVentasDia + _totalCobrosDia - _totalPagos) - widget.totalGastos;

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
            _buildHeader(),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color.fromARGB(255, 194, 131, 16),
                tabs: const [
                  Tab(text: 'Reservas y Adicionales'),
                  Tab(text: 'Cuentas por Cobrar'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVentasTab(),
                  _buildCobrosTab(),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVentasResumen(),
          const SizedBox(height: 20),
          _buildMetodosPagoVentas(),
          const SizedBox(height: 20),
          _buildBalanceDelDia(),
          const SizedBox(height: 20),
          _buildContadorEfectivo(),
          const SizedBox(height: 20),
          _buildVerificacionCuadre(),
        ],
      ),
    );
  }

  Widget _buildCobrosTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCobrosResumen(),
          const SizedBox(height: 20),
          _buildListaCobros(),
          const SizedBox(height: 20),
          _buildMetodosPagoCobros(),
        ],
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
                  'RD\$${formatCurrency(_totalVentasDia)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Pendiente',
                  'RD\$${formatCurrency(_totalPendiente)}',
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

  Widget _buildCobrosResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.money, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Resumen de Cobros',
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
                  'RD\$${formatCurrency(_totalCobrosDia)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Por Cobrar',
                  'RD\$${formatCurrency(_totalPendiente)}',
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

  Widget _buildListaCobros() {
    if (_cobrosDelDia.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No hay cobros registrados hoy',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Detalle de Cobros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._cobrosDelDia.map((cobro) => _buildCobroItem(cobro)).toList(),
        ],
      ),
    );
  }

  Widget _buildCobroItem(Map<String, dynamic> cobro) {
    final id = cobro['id']?.toString() ?? 'N/A';
    final nombre = cobro['name']?.toString() ?? 'Cliente no identificado';
    final monto = (cobro['paymentIn'] as num?)?.toDouble() ?? 0;
    final fecha = cobro['date']?.toString() ?? 'Fecha no disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.money, color: Colors.green.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: $id',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  fecha,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RD\$${formatCurrency(monto)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodosPagoVentas() {
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
            _totalEfectivoVentas,
            Icons.money,
            Colors.green,
            showSubItems: _pagoEfectivo > 0,
          ),
          if (_pagoEfectivo > 0) ...[
            const SizedBox(height: 8),
            _buildPaymentSubItem(
              'Salida efectivo',
              _pagoEfectivo,
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
            _totalTarjetaVentas,
            Icons.credit_card,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodRow(
            'Transferencia',
            _totalTransferenciaVentas,
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
              Icon(Icons.payment, color: Colors.green.shade600, size: 24),
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
            _totalEfectivoCobros,
            Icons.money,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodRow(
            'Tarjeta',
            _totalTarjetaCobros,
            Icons.credit_card,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodRow(
            'Transferencia',
            _totalTransferenciaCobros,
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
            'Entradas (Ventas)',
            _totalVentasDia,
            Icons.arrow_upward,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Entradas (Cobros)',
            _totalCobrosDia,
            Icons.arrow_upward,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Salidas (Pagos)',
            _totalPagos,
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
            onPressed: () {
              _sendReportViaWhatsApp(context);
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