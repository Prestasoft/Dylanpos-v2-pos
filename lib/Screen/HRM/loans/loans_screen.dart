import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/HRM/loans/model/loan_model.dart';
import 'package:salespro_admin/Screen/HRM/loans/repo/loan_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../Widgets/Constant Data/constant.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  static const String route = '/hrm/loans';

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EmployeeLoanModel> allLoans = [];
  List<EmployeeLoanModel> pendingLoans = [];
  List<EmployeeModel> employees = [];
  Map<String, dynamic> summary = {};
  bool isLoading = true;
  String filterStatus = 'Todos';

  final LoanRepository _loanRepo = LoanRepository();
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  final List<String> statusOptions = [
    'Todos',
    ...LoanStatus.all,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final empList = await _employeeRepo.getActiveEmployees();
      final loanList = await _loanRepo.getAllLoans();
      final pending = await _loanRepo.getPendingLoans();
      final summaryData = await _loanRepo.getLoansSummary();

      setState(() {
        employees = empList;
        allLoans = loanList;
        pendingLoans = pending;
        summary = summaryData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast('Error al cargar datos: $e');
    }
  }

  List<EmployeeLoanModel> get filteredLoans {
    if (filterStatus == 'Todos') return allLoans;
    return allLoans.where((l) => l.status == filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor.withValues(alpha: 0.02),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLoansListTab(),
                          _buildSummaryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewLoanDialog(),
        backgroundColor: kMainColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Préstamo', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: kMainColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Préstamos y Adelantos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Gestión de préstamos a empleados',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Indicadores rápidos
          if (!isLoading) ...[
            _buildQuickStat(
              'Activos',
              '${summary['activeLoans'] ?? 0}',
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildQuickStat(
              'Pendientes',
              '${summary['pendingApproval'] ?? 0}',
              Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildQuickStat(
              'Total Cartera',
              currencyFormat.format(summary['totalPendingAmount'] ?? 0),
              Colors.blue,
            ),
          ],
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: kMainColor),
            tooltip: 'Refrescar',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: kMainColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: kMainColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt),
            text: 'Lista de Préstamos',
          ),
          Tab(
            icon: Icon(Icons.bar_chart),
            text: 'Resumen',
          ),
        ],
      ),
    );
  }

  Widget _buildLoansListTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filtros
        _buildFilters(),
        // Lista
        Expanded(
          child: filteredLoans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay préstamos registrados',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLoans.length,
                  itemBuilder: (context, index) {
                    return _buildLoanCard(filteredLoans[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Filtrar por estado:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterStatus,
                items: statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  setState(() => filterStatus = value!);
                },
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Mostrando ${filteredLoans.length} préstamos',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(EmployeeLoanModel loan) {
    Color statusColor;
    IconData statusIcon;

    switch (loan.status) {
      case 'Activo':
        statusColor = Colors.green;
        statusIcon = Icons.play_circle;
        break;
      case 'Pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'Completado':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'Rechazado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Cancelado':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    // Determinar color e icono según si es penalidad
    final isPenalty = loan.isPenalty;
    final cardColor = isPenalty ? Colors.red : kMainColor;
    final IconData typeIcon = isPenalty
        ? Icons.warning_amber
        : loan.loanType.contains('Adelanto')
            ? Icons.fast_forward
            : Icons.account_balance;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPenalty
            ? BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono del tipo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    typeIcon,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Info del empleado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${loan.designation} - ${loan.department}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      // Mostrar tipo de penalidad si aplica
                      if (isPenalty && loan.penaltyType != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            '${PenaltyTypes.getIcon(loan.penaltyType!)} ${loan.penaltyType}',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Monto
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(loan.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: cardColor,
                      ),
                    ),
                    Text(
                      isPenalty ? 'Penalidad' : loan.loanType,
                      style: TextStyle(
                        color: isPenalty ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isPenalty ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    // Mostrar frecuencia de pago
                    Text(
                      loan.paymentFrequency,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        loan.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (loan.status == LoanStatus.activo) ...[
              const SizedBox(height: 16),
              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso: ${loan.paidInstallments}/${loan.totalInstallments} cuotas (${loan.paymentFrequency})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        '${loan.progressPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: loan.progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Detalles de pago
              Row(
                children: [
                  _buildLoanDetail(
                    loan.paymentFrequency == 'Quincenal'
                        ? 'Cuota Quinc.'
                        : 'Cuota Mensual',
                    currencyFormat.format(loan.installmentAmount),
                  ),
                  const SizedBox(width: 24),
                  _buildLoanDetail('Pagado', currencyFormat.format(loan.amountPaid)),
                  const SizedBox(width: 24),
                  _buildLoanDetail(
                    'Pendiente',
                    currencyFormat.format(loan.amountPending),
                    color: Colors.red,
                  ),
                  const Spacer(),
                  // Botón de registrar pago
                  ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(loan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Registrar Pago'),
                  ),
                ],
              ),
            ],
            if (loan.status == LoanStatus.pendiente) ...[
              const SizedBox(height: 16),
              // Mostrar info de penalidad si aplica
              if (isPenalty && loan.incidentDescription != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loan.affectedItem != null)
                        Text(
                          'Equipo: ${loan.affectedItem}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      if (loan.incidentDate != null)
                        Text(
                          'Fecha incidente: ${DateFormat('dd/MM/yyyy').format(loan.incidentDate!)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      if (loan.incidentDescription!.isNotEmpty)
                        Text(
                          loan.incidentDescription!,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  _buildLoanDetail('Cuotas', '${loan.totalInstallments}'),
                  const SizedBox(width: 24),
                  _buildLoanDetail(
                    loan.paymentFrequency == 'Quincenal'
                        ? 'Cuota Quinc.'
                        : 'Cuota Mensual',
                    currencyFormat.format(loan.installmentAmount),
                  ),
                  const SizedBox(width: 24),
                  _buildLoanDetail(
                    'Inicio',
                    DateFormat('dd/MM/yyyy').format(loan.startDate),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _approveLoan(loan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _rejectLoan(loan),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                  ),
                ],
              ),
            ],
            // Menú de acciones
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showLoanDetails(loan),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Ver Detalles'),
                ),
                if (loan.status == LoanStatus.activo)
                  TextButton.icon(
                    onPressed: () => _showPaymentHistory(loan),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Historial'),
                  ),
                if (loan.status == LoanStatus.pendiente ||
                    loan.status == LoanStatus.activo)
                  TextButton.icon(
                    onPressed: () => _cancelLoan(loan),
                    icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetail(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Préstamos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Cards de resumen
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryCard(
                'Total Préstamos',
                '${summary['totalLoans'] ?? 0}',
                Icons.folder,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Préstamos Activos',
                '${summary['activeLoans'] ?? 0}',
                Icons.play_circle,
                Colors.green,
              ),
              _buildSummaryCard(
                'Pendientes Aprobación',
                '${summary['pendingApproval'] ?? 0}',
                Icons.pending,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Completados',
                '${summary['completedLoans'] ?? 0}',
                Icons.check_circle,
                Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Montos
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryCard(
                'Total Cartera Activa',
                currencyFormat.format(summary['totalActiveAmount'] ?? 0),
                Icons.account_balance,
                Colors.purple,
              ),
              _buildSummaryCard(
                'Total Pendiente Cobro',
                currencyFormat.format(summary['totalPendingAmount'] ?? 0),
                Icons.pending_actions,
                Colors.red,
              ),
              _buildSummaryCard(
                'Total Recuperado',
                currencyFormat.format(summary['totalPaidAmount'] ?? 0),
                Icons.savings,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tabla de préstamos por empleado
          const Text(
            'Préstamos Activos por Empleado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Monto Total')),
                  DataColumn(label: Text('Pendiente')),
                  DataColumn(label: Text('Cuotas Rest.')),
                  DataColumn(label: Text('Próx. Cuota')),
                ],
                rows: allLoans
                    .where((l) => l.status == LoanStatus.activo)
                    .map((loan) {
                  return DataRow(cells: [
                    DataCell(Text(loan.employeeName)),
                    DataCell(Text(loan.loanType)),
                    DataCell(Text(currencyFormat.format(loan.amount))),
                    DataCell(
                      Text(
                        currencyFormat.format(loan.amountPending),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    DataCell(Text('${loan.remainingInstallments}')),
                    DataCell(Text(currencyFormat.format(loan.installmentAmount))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewLoanDialog() {
    if (employees.isEmpty) {
      toast('No hay empleados disponibles');
      return;
    }

    EmployeeModel? selectedEmployee;
    String selectedType = LoanTypes.prestamo;
    String selectedFrequency = PaymentFrequency.mensual;
    String selectedPenaltyType = PenaltyTypes.danoEquipo;
    bool isPenalty = false;
    bool calculateByInstallments = true; // true = por número de cuotas, false = por monto de cuota

    final amountController = TextEditingController();
    final installmentsController = TextEditingController(text: '12');
    final installmentAmountController = TextEditingController();
    final reasonController = TextEditingController();
    final incidentDescriptionController = TextEditingController();
    final affectedItemController = TextEditingController();
    final originalValueController = TextEditingController();

    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime incidentDate = DateTime.now();
    double installmentAmount = 0;
    int calculatedInstallments = 0;
    double selectedPenaltyPercentage = 100.0;
    double penaltyAmount = 0;

    void calculateInstallment() {
      final amount = isPenalty ? penaltyAmount : (double.tryParse(amountController.text) ?? 0);

      if (calculateByInstallments) {
        // Calcular monto de cuota basado en número de cuotas
        final installments = int.tryParse(installmentsController.text) ?? 1;
        if (amount > 0 && installments > 0) {
          installmentAmount = LoanRepository.calculateInstallment(
            amount: amount,
            installments: installments,
          );
          calculatedInstallments = installments;
        }
      } else {
        // Calcular número de cuotas basado en monto de cuota
        final cuotaAmount = double.tryParse(installmentAmountController.text) ?? 0;
        if (amount > 0 && cuotaAmount > 0) {
          calculatedInstallments = (amount / cuotaAmount).ceil();
          installmentAmount = cuotaAmount;
          // Ajustar si la última cuota sería diferente
          final totalWithFullInstallments = cuotaAmount * calculatedInstallments;
          if (totalWithFullInstallments > amount) {
            // La última cuota será menor
          }
        }
      }
    }

    void calculatePenaltyAmount() {
      final originalValue = double.tryParse(originalValueController.text) ?? 0;
      penaltyAmount = originalValue * (selectedPenaltyPercentage / 100);
      amountController.text = penaltyAmount.toStringAsFixed(2);
      calculateInstallment();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isPenalty ? Icons.warning_amber : Icons.account_balance_wallet,
                  color: isPenalty ? Colors.red : kMainColor,
                ),
                const SizedBox(width: 8),
                Text(isPenalty ? 'Nueva Penalidad/Descuento' : 'Nuevo Préstamo/Adelanto'),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de tipo: Préstamo o Penalidad
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPenalty = false;
                                  calculateInstallment();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isPenalty ? kMainColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      size: 18,
                                      color: !isPenalty ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Préstamo/Adelanto',
                                      style: TextStyle(
                                        color: !isPenalty ? Colors.white : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPenalty = true;
                                  calculatePenaltyAmount();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isPenalty ? Colors.red : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      size: 18,
                                      color: isPenalty ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Penalidad/Descuento',
                                      style: TextStyle(
                                        color: isPenalty ? Colors.white : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Empleado
                    DropdownButtonFormField<EmployeeModel>(
                      decoration: const InputDecoration(
                        labelText: 'Empleado',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: employees.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedEmployee = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ═══════════ SECCIÓN PRÉSTAMO/ADELANTO ═══════════
                    if (!isPenalty) ...[
                      // Tipo de préstamo
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Préstamo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: LoanTypes.all.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedType = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Monto total
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Total (RD\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'RD\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          calculateInstallment();
                          setState(() {});
                        },
                      ),
                    ],

                    // ═══════════ SECCIÓN PENALIDAD ═══════════
                    if (isPenalty) ...[
                      // Tipo de penalidad
                      DropdownButtonFormField<String>(
                        value: selectedPenaltyType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Penalidad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning, color: Colors.red),
                        ),
                        items: PenaltyTypes.all.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text('${PenaltyTypes.getIcon(type)} $type'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedPenaltyType = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fecha del incidente
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: incidentDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => incidentDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha del Incidente',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event, color: Colors.red),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(incidentDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Equipo/Producto afectado
                      TextFormField(
                        controller: affectedItemController,
                        decoration: const InputDecoration(
                          labelText: 'Equipo/Producto Afectado',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.devices),
                          hintText: 'Ej: Canon EOS R5 + Lente 24-70mm',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Valor original del equipo
                      TextFormField(
                        controller: originalValueController,
                        decoration: const InputDecoration(
                          labelText: 'Valor del Daño/Pérdida (RD\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.price_change),
                          prefixText: 'RD\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          calculatePenaltyAmount();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      // Porcentaje a cobrar
                      DropdownButtonFormField<double>(
                        value: selectedPenaltyPercentage,
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje a Cobrar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.percent),
                        ),
                        items: PenaltyPercentages.all.map((pct) {
                          final originalValue = double.tryParse(originalValueController.text) ?? 0;
                          final calculatedAmount = originalValue * (pct / 100);
                          return DropdownMenuItem(
                            value: pct,
                            child: Text(
                              '${pct.toInt()}% ${originalValue > 0 ? '- ${currencyFormat.format(calculatedAmount)}' : ''}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPenaltyPercentage = value!;
                            calculatePenaltyAmount();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Monto calculado de penalidad
                      if (penaltyAmount > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total a Descontar:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                currencyFormat.format(penaltyAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Descripción del incidente
                      TextFormField(
                        controller: incidentDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del Incidente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Detalle qué sucedió...',
                        ),
                        maxLines: 3,
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ═══════════ CONFIGURACIÓN DE PAGO ═══════════
                    Text(
                      'Configuración de Pago',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Frecuencia de pago
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia de Pago',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      items: PaymentFrequency.all.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(freq),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFrequency = value!;
                          calculateInstallment();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selector de modo de cálculo
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 8),
                            child: Text(
                              'Calcular por:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Número de Cuotas', style: TextStyle(fontSize: 13)),
                                  value: true,
                                  groupValue: calculateByInstallments,
                                  onChanged: (value) {
                                    setState(() {
                                      calculateByInstallments = value!;
                                      calculateInstallment();
                                    });
                                  },
                                  dense: true,
                                  activeColor: kMainColor,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Monto de Cuota', style: TextStyle(fontSize: 13)),
                                  value: false,
                                  groupValue: calculateByInstallments,
                                  onChanged: (value) {
                                    setState(() {
                                      calculateByInstallments = value!;
                                      calculateInstallment();
                                    });
                                  },
                                  dense: true,
                                  activeColor: kMainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo según modo de cálculo
                    if (calculateByInstallments)
                      TextFormField(
                        controller: installmentsController,
                        decoration: InputDecoration(
                          labelText: 'Número de Cuotas',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.format_list_numbered),
                          suffixText: selectedFrequency == 'Quincenal' ? 'quincenas' : 'meses',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          calculateInstallment();
                          setState(() {});
                        },
                      )
                    else
                      TextFormField(
                        controller: installmentAmountController,
                        decoration: InputDecoration(
                          labelText: 'Monto por Cuota (RD\$)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.payments),
                          prefixText: 'RD\$ ',
                          suffixText: selectedFrequency == 'Quincenal' ? '/quincena' : '/mes',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          calculateInstallment();
                          setState(() {});
                        },
                      ),
                    const SizedBox(height: 16),

                    // Fecha inicio descuentos
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => startDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha Inicio Descuentos',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event_available),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resumen de cálculo
                    if (installmentAmount > 0 || calculatedInstallments > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.payments, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedFrequency == 'Quincenal'
                                          ? 'Cuota Quincenal:'
                                          : 'Cuota Mensual:',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Text(
                                  currencyFormat.format(installmentAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_list_numbered, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Total de Cuotas:'),
                                  ],
                                ),
                                Text(
                                  '$calculatedInstallments ${selectedFrequency == 'Quincenal' ? 'quincenas' : 'meses'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Fin Estimado:'),
                                  ],
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(
                                    startDate.add(Duration(
                                      days: selectedFrequency == 'Quincenal'
                                          ? calculatedInstallments * 15
                                          : calculatedInstallments * 30,
                                    )),
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Motivo/Notas
                    if (!isPenalty)
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Motivo/Notas (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPenalty ? Colors.red : kMainColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedEmployee != null &&
                        (installmentAmount > 0 || calculatedInstallments > 0)
                    ? () async {
                        Navigator.pop(context);
                        final amount = isPenalty
                            ? penaltyAmount
                            : double.parse(amountController.text);
                        final installments = calculateByInstallments
                            ? int.parse(installmentsController.text)
                            : calculatedInstallments;

                        final loan = EmployeeLoanModel(
                          id: DateTime.now().millisecondsSinceEpoch,
                          employeeId: selectedEmployee!.id,
                          employeeName: selectedEmployee!.fullName,
                          employeeCedula: selectedEmployee!.cedula,
                          designation: selectedEmployee!.designation,
                          department: selectedEmployee!.department,
                          loanType: isPenalty ? 'Penalidad' : selectedType,
                          amount: amount,
                          totalInstallments: installments,
                          installmentAmount: installmentAmount,
                          amountPending: amount,
                          requestDate: DateTime.now(),
                          startDate: startDate,
                          status: LoanStatus.pendiente,
                          reason: isPenalty
                              ? incidentDescriptionController.text
                              : reasonController.text.isNotEmpty
                                  ? reasonController.text
                                  : null,
                          paymentFrequency: selectedFrequency,
                          isPenalty: isPenalty,
                          penaltyType: isPenalty ? selectedPenaltyType : null,
                          incidentDescription: isPenalty
                              ? incidentDescriptionController.text
                              : null,
                          incidentDate: isPenalty ? incidentDate : null,
                          affectedItem: isPenalty
                              ? affectedItemController.text.isNotEmpty
                                  ? affectedItemController.text
                                  : null
                              : null,
                          originalItemValue: isPenalty
                              ? double.tryParse(originalValueController.text)
                              : null,
                          penaltyPercentage:
                              isPenalty ? selectedPenaltyPercentage : null,
                        );

                        await _loanRepo.createLoanRequest(loan: loan);
                        _loadData();
                      }
                    : null,
                child: Text(isPenalty ? 'Crear Penalidad' : 'Crear Solicitud'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentDialog(EmployeeLoanModel loan) {
    final amountController = TextEditingController(
      text: loan.installmentAmount.toStringAsFixed(2),
    );
    String paymentMethod = 'Descuento Nómina';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Pago - ${loan.employeeName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cuota #${loan.paidInstallments + 1} de ${loan.totalInstallments}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Monto del Pago',
                border: OutlineInputBorder(),
                prefixText: 'RD\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Descuento Nómina', child: Text('Descuento Nómina')),
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
              ],
              onChanged: (value) => paymentMethod = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await _loanRepo.registerPayment(
                  loan: loan,
                  paymentAmount: amount,
                  paymentMethod: paymentMethod,
                );
                _loadData();
              }
            },
            child: const Text('Registrar Pago'),
          ),
        ],
      ),
    );
  }

  void _approveLoan(EmployeeLoanModel loan) async {
    await _loanRepo.approveLoan(
      loanId: loan.id,
      approvedBy: 'Administrador',
    );
    _loadData();
  }

  void _rejectLoan(EmployeeLoanModel loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Préstamo'),
        content: Text('¿Está seguro de rechazar el préstamo de ${loan.employeeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _loanRepo.rejectLoan(
                loanId: loan.id,
                rejectedBy: 'Administrador',
              );
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cancelLoan(EmployeeLoanModel loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Préstamo'),
        content: Text('¿Está seguro de cancelar el préstamo de ${loan.employeeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _loanRepo.cancelLoan(loanId: loan.id);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLoanDetails(EmployeeLoanModel loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              loan.isPenalty ? Icons.warning_amber : Icons.account_balance_wallet,
              color: loan.isPenalty ? Colors.red : kMainColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detalles - ${loan.employeeName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección: Información General
                _buildDetailSection('INFORMACIÓN GENERAL'),
                _buildDetailRow('Tipo', loan.isPenalty ? 'Penalidad' : loan.loanType),
                _buildDetailRow('Monto Total', currencyFormat.format(loan.amount)),
                _buildDetailRow('Frecuencia de Pago', loan.paymentFrequency),
                _buildDetailRow('Estado', loan.status),

                const SizedBox(height: 16),
                _buildDetailSection('PLAN DE PAGOS'),
                _buildDetailRow('Total de Cuotas', '${loan.totalInstallments}'),
                _buildDetailRow(
                  loan.paymentFrequency == 'Quincenal'
                      ? 'Cuota Quincenal'
                      : 'Cuota Mensual',
                  currencyFormat.format(loan.installmentAmount),
                ),
                _buildDetailRow('Cuotas Pagadas', '${loan.paidInstallments}'),
                _buildDetailRow('Cuotas Pendientes', '${loan.remainingInstallments}'),
                _buildDetailRow('Monto Pagado', currencyFormat.format(loan.amountPaid)),
                _buildDetailRow('Monto Pendiente', currencyFormat.format(loan.amountPending)),

                const SizedBox(height: 16),
                _buildDetailSection('FECHAS'),
                _buildDetailRow(
                  'Fecha Solicitud',
                  DateFormat('dd/MM/yyyy').format(loan.requestDate),
                ),
                _buildDetailRow(
                  'Fecha Inicio Descuentos',
                  DateFormat('dd/MM/yyyy').format(loan.startDate),
                ),
                if (loan.endDate != null)
                  _buildDetailRow(
                    'Fecha Fin Estimada',
                    DateFormat('dd/MM/yyyy').format(loan.endDate!),
                  ),
                if (loan.approvalDate != null)
                  _buildDetailRow(
                    'Fecha Aprobación',
                    DateFormat('dd/MM/yyyy').format(loan.approvalDate!),
                  ),

                // Sección de Penalidad (si aplica)
                if (loan.isPenalty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'INFORMACIÓN DE PENALIDAD',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (loan.penaltyType != null)
                          _buildDetailRow(
                            'Tipo de Penalidad',
                            '${PenaltyTypes.getIcon(loan.penaltyType!)} ${loan.penaltyType}',
                          ),
                        if (loan.incidentDate != null)
                          _buildDetailRow(
                            'Fecha del Incidente',
                            DateFormat('dd/MM/yyyy').format(loan.incidentDate!),
                          ),
                        if (loan.affectedItem != null)
                          _buildDetailRow('Equipo Afectado', loan.affectedItem!),
                        if (loan.originalItemValue != null)
                          _buildDetailRow(
                            'Valor Original',
                            currencyFormat.format(loan.originalItemValue),
                          ),
                        if (loan.penaltyPercentage != null)
                          _buildDetailRow(
                            'Porcentaje Cobrado',
                            '${loan.penaltyPercentage!.toInt()}%',
                          ),
                        if (loan.incidentDescription != null &&
                            loan.incidentDescription!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Descripción:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loan.incidentDescription!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Aprobación y notas
                if (loan.approvedBy != null || loan.reason != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection('NOTAS'),
                  if (loan.approvedBy != null)
                    _buildDetailRow('Aprobado por', loan.approvedBy!),
                  if (loan.reason != null && !loan.isPenalty)
                    _buildDetailRow('Motivo', loan.reason!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: kMainColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showPaymentHistory(EmployeeLoanModel loan) async {
    final payments = await _loanRepo.getLoanPayments(loan.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial de Pagos - ${loan.employeeName}'),
        content: SizedBox(
          width: 500,
          height: 300,
          child: payments.isEmpty
              ? const Center(child: Text('No hay pagos registrados'))
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kMainColor,
                        child: Text(
                          '${payment.installmentNumber}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(currencyFormat.format(payment.amount)),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yyyy').format(payment.paymentDate)} - ${payment.paymentMethod}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
