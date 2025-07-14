import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../Provider/dashboard_transaction_provider.dart';
import '../../model/daily_summary_model.dart';
import '../Widgets/dashboard_summary_card.dart';
import '../Widgets/Constant Data/constant.dart';

class DailyTransactionDashboard extends ConsumerStatefulWidget {
  const DailyTransactionDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyTransactionDashboard> createState() => _DailyTransactionDashboardState();
}

class _DailyTransactionDashboardState extends ConsumerState<DailyTransactionDashboard> {
  DateTime selectedDate = DateTime.now();
  
  String get formattedSelectedDate {
    return '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider(formattedSelectedDate));
    final transactionsAsync = ref.watch(dashboardTransactionsProvider(formattedSelectedDate));

    return Scaffold(
      backgroundColor: kMainColor.withValues(alpha: 0.1),
      appBar: AppBar(
        title: const Text(
          'Dashboard Transacciones Diarias',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(dashboardTransactionsProvider(formattedSelectedDate));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: kMainColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha Seleccionada',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMMM yyyy', 'es_ES').format(selectedDate),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary Cards Section
            summaryAsync.when(
              data: (summary) => _buildSummaryCards(summary),
              loading: () => _buildLoadingCards(),
              error: (error, stackTrace) => _buildErrorCard(error.toString()),
            ),

            const SizedBox(height: 20),

            // Transaction Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: kMainColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Transacciones del Día',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  transactionsAsync.when(
                    data: (transactions) => _buildTransactionsList(transactions),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error al cargar transacciones: $error',
                          style: TextStyle(color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DailySummaryModel summary) {
    final cards = [
      DashboardCardConfigs.totalFacturado(amount: summary.totalFacturado),
      DashboardCardConfigs.totalPagado(amount: summary.totalPagado),
      DashboardCardConfigs.totalPendiente(amount: summary.totalPendiente),
      DashboardCardConfigs.pagoEfectivo(amount: summary.pagoEfectivo),
      DashboardCardConfigs.pagoTransferencia(amount: summary.pagoTransferencia),
      DashboardCardConfigs.pagoTarjetas(amount: summary.pagoTarjetas),
    ];

    return DashboardSummaryGrid(
      cards: cards,
      crossAxisCount: context.width() > 800 ? 3 : 2,
    );
  }

  Widget _buildLoadingCards() {
    final loadingCards = [
      DashboardCardConfigs.totalFacturado(amount: 0, isLoading: true),
      DashboardCardConfigs.totalPagado(amount: 0, isLoading: true),
      DashboardCardConfigs.totalPendiente(amount: 0, isLoading: true),
      DashboardCardConfigs.pagoEfectivo(amount: 0, isLoading: true),
      DashboardCardConfigs.pagoTransferencia(amount: 0, isLoading: true),
      DashboardCardConfigs.pagoTarjetas(amount: 0, isLoading: true),
    ];

    return DashboardSummaryGrid(
      cards: loadingCards,
      crossAxisCount: context.width() > 800 ? 3 : 2,
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Error al cargar resumen',
            style: TextStyle(
              color: Colors.red[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay transacciones para esta fecha',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona otra fecha para ver las transacciones',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Total: ${transactions.length} transacciones',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.take(5).map((transaction) => _buildTransactionItem(transaction)),
        if (transactions.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '+ ${transactions.length - 5} transacciones más',
              style: TextStyle(
                color: kMainColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    IconData getTypeIcon(String type) {
      switch (type.toLowerCase()) {
        case 'sale':
          return Icons.point_of_sale;
        case 'purchase':
          return Icons.shopping_cart;
        case 'expense':
          return Icons.money_off;
        case 'income':
          return Icons.attach_money;
        default:
          return Icons.receipt;
      }
    }

    Color getTypeColor(String type) {
      switch (type.toLowerCase()) {
        case 'sale':
          return Colors.green;
        case 'purchase':
          return Colors.blue;
        case 'expense':
          return Colors.red;
        case 'income':
          return Colors.teal;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getTypeColor(transaction.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              getTypeIcon(transaction.type),
              color: getTypeColor(transaction.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  transaction.type,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${transaction.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: getTypeColor(transaction.type),
            ),
          ),
        ],
      ),
    );
  }
}