import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';

import 'models/commission_config_model.dart';
import 'models/employee_performance_model.dart';
import 'providers/rentability_provider.dart';

/// Pantalla de Desempeño Individual por Empleado
class EmployeePerformanceScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeePerformanceScreen({
    super.key,
    required this.employeeId,
  });

  @override
  ConsumerState<EmployeePerformanceScreen> createState() => _EmployeePerformanceScreenState();
}

class _EmployeePerformanceScreenState extends ConsumerState<EmployeePerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cargar datos reales del empleado (usa periodProvider internamente)
    final performanceAsync = ref.watch(employeePerformanceByIdProvider(widget.employeeId));

    return Scaffold(
      backgroundColor: kAppSurfaceBg,
      appBar: AppBar(
        backgroundColor: kMainColor,
        foregroundColor: Colors.white,
        title: const Text('Desempeño del Empleado'),
        elevation: 0,
      ),
      body: performanceAsync.when(
        data: (performance) {
          if (performance == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No se encontró información del empleado',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return _buildContent(context, performance);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Error cargando datos del empleado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmployeePerformance performance) {
    return Column(
      children: [
        // Header con foto y stats principales
        _buildHeader(performance),

        // Cards de métricas
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildMetricsCards(performance),
        ),

        // TabBar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: kMainColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kMainColor,
            tabs: const [
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Facturadas',
              ),
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Pendientes',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Historial',
              ),
            ],
          ),
        ),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInvoicedTab(performance),
              _buildPendingTab(performance),
              _buildHistoryTab(performance),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(EmployeePerformance performance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColor, kMainColor.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Foto del empleado
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: performance.photoUrl != null && performance.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(37),
                    child: Image.network(
                      performance.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 40, color: kMainColor),
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: kMainColor),
          ),
          const SizedBox(width: 20),
          // Info del empleado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.employeeName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Agente de Reservaciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildHeaderStat(
                      'Comisión',
                      '${performance.commissionPercentage.toStringAsFixed(1)}%',
                      Icons.percent,
                    ),
                    const SizedBox(width: 24),
                    _buildHeaderStat(
                      'Total Ganado',
                      myFormat.format(performance.commissionEarned),
                      Icons.attach_money,
                    ),
                    const SizedBox(width: 24),
                    _buildHeaderStat(
                      'Ranking',
                      '#${performance.ranking}',
                      Icons.emoji_events,
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

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsCards(EmployeePerformance performance) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricCard(
          '📋 Total Reservas',
          performance.totalReservations.toString(),
          Colors.blue,
        ),
        _buildMetricCard(
          '✅ Facturadas',
          '${performance.invoicedReservations} (${performance.conversionRate.toStringAsFixed(0)}%)',
          Colors.green,
        ),
        _buildMetricCard(
          '⏳ Pendientes',
          '${performance.pendingReservations} (${(100 - performance.conversionRate).toStringAsFixed(0)}%)',
          Colors.orange,
        ),
        _buildMetricCard(
          '💵 Valor Facturado',
          myFormat.format(performance.totalRevenue),
          Colors.purple,
        ),
        _buildMetricCard(
          '💰 Comisiones',
          myFormat.format(performance.commissionEarned),
          Colors.teal,
        ),
        _buildMetricCard(
          '📊 Promedio/Reserva',
          myFormat.format(performance.averageRevenuePerReservation),
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Reservas Facturadas
  Widget _buildInvoicedTab(EmployeePerformance performance) {
    return Container(
      color: kDarkWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
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
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text(
                    'RESERVAS FACTURADAS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInvoicedTable(performance.invoicedDetails),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicedTable(List<ReservationCommission> invoiced) {
    if (invoiced.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No hay reservas facturadas en este período'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('# Reserva', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Factura', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Fecha Reserva', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Fecha Factura', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Com. %', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Com. \$', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Estado Pago', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: invoiced.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.reservationId)),
              DataCell(Text(item.invoiceNumber ?? 'N/A')),
              DataCell(Text(item.customerName)),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(item.reservationDate))),
              DataCell(Text(item.invoiceDate != null ? DateFormat('dd/MM/yyyy').format(item.invoiceDate!) : 'N/A')),
              DataCell(Text(myFormat.format(item.amount))),
              DataCell(Text('${item.commissionRate.toStringAsFixed(1)}%')),
              DataCell(Text(
                myFormat.format(item.commissionAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
              )),
              DataCell(_buildPaymentStatusBadge(item.commissionPaid, item.paidDate)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(bool isPaid, DateTime? paidDate) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Pagada ${paidDate != null ? DateFormat('dd/MM').format(paidDate) : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, size: 14, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'Pendiente',
              style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }

  // TAB 2: Reservas Pendientes de Facturar
  Widget _buildPendingTab(EmployeePerformance performance) {
    return Container(
      color: kDarkWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
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
                  const Icon(Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text(
                    'RESERVAS PENDIENTES DE FACTURAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPendingTable(performance.pendingDetails),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTable(List<PendingReservation> pending) {
    if (pending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.withAlpha(128)),
              const SizedBox(height: 16),
              const Text(
                '¡Excelente! No hay reservas pendientes de facturar',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('# Reserva', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Fecha Reserva', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Fecha Evento', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Monto Est.', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Días sin Fact.', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Urgencia', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: pending.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.reservationId)),
              DataCell(Text(item.customerName)),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(item.reservationDate))),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(item.eventDate))),
              DataCell(Text(myFormat.format(item.estimatedAmount))),
              DataCell(Text(item.daysWithoutInvoice.toString())),
              DataCell(_buildUrgencyBadge(item.urgencyLevel, item.daysWithoutInvoice)),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _goToInvoice(item.reservationId),
                  icon: const Icon(Icons.receipt, size: 16),
                  label: const Text('Facturar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUrgencyBadge(String level, int days) {
    Color color;
    IconData icon;
    String label;

    switch (level) {
      case 'high':
        color = Colors.red;
        icon = Icons.warning;
        label = 'URGENTE';
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.alarm;
        label = 'PRONTO';
        break;
      default:
        color = Colors.green;
        icon = Icons.check;
        label = 'OK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // TAB 3: Historial de Comisiones
  Widget _buildHistoryTab(EmployeePerformance performance) {
    return Container(
      color: kDarkWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
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
                  const Icon(Icons.history, color: kMainColor),
                  const SizedBox(width: 12),
                  const Text(
                    'HISTORIAL DE COMISIONES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHistoryTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    // Mock data histórico
    final history = [
      {'month': 'Enero 2026', 'reservations': 22, 'amount': 50000.0, 'commission': 5.0, 'earned': 2500.0, 'paid': true},
      {'month': 'Diciembre 2025', 'reservations': 18, 'amount': 42000.0, 'commission': 5.0, 'earned': 2100.0, 'paid': true},
      {'month': 'Noviembre 2025', 'reservations': 15, 'amount': 35000.0, 'commission': 3.0, 'earned': 1050.0, 'paid': true},
      {'month': 'Octubre 2025', 'reservations': 12, 'amount': 28000.0, 'commission': 3.0, 'earned': 840.0, 'paid': true},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('Mes', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Reservas Fact.', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Monto Total', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('% Comisión', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Comisión Gen.', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Estado Pago', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: history.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['month'] as String)),
              DataCell(Text(item['reservations'].toString())),
              DataCell(Text(myFormat.format(item['amount']))),
              DataCell(Text('${item['commission']}%')),
              DataCell(Text(
                myFormat.format(item['earned']),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
              )),
              DataCell(_buildPaymentStatusBadge(item['paid'] as bool, null)),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _goToInvoice(String reservationId) {
    // TODO: Navegar a pantalla de facturación con la reserva
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ir a facturar reserva $reservationId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

}
