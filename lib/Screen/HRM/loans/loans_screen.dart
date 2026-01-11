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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: kMainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    loan.loanType.contains('Adelanto')
                        ? Icons.fast_forward
                        : Icons.account_balance,
                    color: kMainColor,
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
                    ],
                  ),
                ),
                // Monto
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(loan.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kMainColor,
                      ),
                    ),
                    Text(
                      loan.loanType,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
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
                        'Progreso: ${loan.paidInstallments}/${loan.totalInstallments} cuotas',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        '${loan.progressPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kMainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: loan.progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(kMainColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Detalles de pago
              Row(
                children: [
                  _buildLoanDetail('Cuota', currencyFormat.format(loan.installmentAmount)),
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
              Row(
                children: [
                  _buildLoanDetail('Cuotas', '${loan.totalInstallments}'),
                  const SizedBox(width: 24),
                  _buildLoanDetail('Cuota Mensual', currencyFormat.format(loan.installmentAmount)),
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
    final amountController = TextEditingController();
    final installmentsController = TextEditingController(text: '12');
    final reasonController = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    double installmentAmount = 0;

    void calculateInstallment() {
      final amount = double.tryParse(amountController.text) ?? 0;
      final installments = int.tryParse(installmentsController.text) ?? 1;
      if (amount > 0 && installments > 0) {
        installmentAmount = LoanRepository.calculateInstallment(
          amount: amount,
          installments: installments,
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nuevo Préstamo/Adelanto'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Empleado
                    DropdownButtonFormField<EmployeeModel>(
                      decoration: const InputDecoration(
                        labelText: 'Empleado',
                        border: OutlineInputBorder(),
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
                    // Tipo
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: LoanTypes.all.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Monto
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Monto Total (RD\$)',
                        border: OutlineInputBorder(),
                        prefixText: 'RD\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        calculateInstallment();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Cuotas
                    TextFormField(
                      controller: installmentsController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Cuotas',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        calculateInstallment();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Fecha inicio
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
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cuota calculada
                    if (installmentAmount > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cuota Mensual:',
                              style: TextStyle(fontWeight: FontWeight.w500),
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
                      ),
                    const SizedBox(height: 16),
                    // Motivo
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (opcional)',
                        border: OutlineInputBorder(),
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
                onPressed: selectedEmployee != null && installmentAmount > 0
                    ? () async {
                        Navigator.pop(context);
                        final amount = double.parse(amountController.text);
                        final installments = int.parse(installmentsController.text);

                        final loan = EmployeeLoanModel(
                          id: DateTime.now().millisecondsSinceEpoch,
                          employeeId: selectedEmployee!.id,
                          employeeName: selectedEmployee!.fullName,
                          employeeCedula: selectedEmployee!.cedula,
                          designation: selectedEmployee!.designation,
                          department: selectedEmployee!.department,
                          loanType: selectedType,
                          amount: amount,
                          totalInstallments: installments,
                          installmentAmount: installmentAmount,
                          amountPending: amount,
                          requestDate: DateTime.now(),
                          startDate: startDate,
                          status: LoanStatus.pendiente,
                          reason: reasonController.text.isNotEmpty
                              ? reasonController.text
                              : null,
                        );

                        await _loanRepo.createLoanRequest(loan: loan);
                        _loadData();
                      }
                    : null,
                child: const Text('Crear Solicitud'),
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
        title: Text('Detalles - ${loan.employeeName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tipo', loan.loanType),
              _buildDetailRow('Monto Total', currencyFormat.format(loan.amount)),
              _buildDetailRow('Cuotas', '${loan.totalInstallments}'),
              _buildDetailRow('Cuota Mensual', currencyFormat.format(loan.installmentAmount)),
              _buildDetailRow('Pagado', currencyFormat.format(loan.amountPaid)),
              _buildDetailRow('Pendiente', currencyFormat.format(loan.amountPending)),
              _buildDetailRow('Cuotas Pagadas', '${loan.paidInstallments}'),
              _buildDetailRow('Estado', loan.status),
              _buildDetailRow('Fecha Solicitud',
                  DateFormat('dd/MM/yyyy').format(loan.requestDate)),
              _buildDetailRow('Fecha Inicio',
                  DateFormat('dd/MM/yyyy').format(loan.startDate)),
              if (loan.approvedBy != null)
                _buildDetailRow('Aprobado por', loan.approvedBy!),
              if (loan.reason != null) _buildDetailRow('Motivo', loan.reason!),
            ],
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
