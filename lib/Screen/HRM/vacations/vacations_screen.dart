import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/HRM/vacations/model/vacation_model.dart';
import 'package:salespro_admin/Screen/HRM/vacations/repo/vacation_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../Widgets/Constant Data/constant.dart';

class VacationsScreen extends StatefulWidget {
  const VacationsScreen({super.key});

  static const String route = '/hrm/vacations';

  @override
  State<VacationsScreen> createState() => _VacationsScreenState();
}

class _VacationsScreenState extends State<VacationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VacationModel> allVacations = [];
  List<VacationModel> pendingVacations = [];
  List<VacationBalance> balances = [];
  List<EmployeeModel> employees = [];
  List<VacationEligibility> eligibilities = [];
  bool isLoading = true;
  String selectedYear = DateTime.now().year.toString();
  String filterStatus = 'Todos';
  late DateTime selectedMonth;

  final VacationRepository _vacationRepo = VacationRepository();
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  final List<String> statusOptions = [
    'Todos',
    'Pendiente',
    'Aprobado',
    'Rechazado',
    'Cancelado',
    'Completado',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
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
      final vacList = await _vacationRepo.getAllVacations();
      final pending = await _vacationRepo.getPendingVacations();
      final balanceList = await _vacationRepo.getAllEmployeesVacationBalance();
      final eligList = await _vacationRepo.getUpcomingVacationEligibility(daysAhead: 180);

      setState(() {
        employees = empList;
        allVacations = vacList;
        pendingVacations = pending;
        balances = balanceList;
        eligibilities = eligList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast('Error al cargar datos: $e');
    }
  }

  List<VacationModel> get filteredVacations {
    var filtered = allVacations.where((v) {
      return v.startDate.year.toString() == selectedYear ||
          v.endDate.year.toString() == selectedYear;
    }).toList();

    if (filterStatus != 'Todos') {
      filtered = filtered.where((v) => v.status == filterStatus).toList();
    }

    filtered.sort((a, b) => b.requestDate.compareTo(a.requestDate));
    return filtered;
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
                          _buildRequestsTab(),
                          _buildBalanceTab(),
                          _buildCalendarTab(),
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
        onPressed: () => _showNewRequestDialog(),
        backgroundColor: kMainColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Solicitud', style: TextStyle(color: Colors.white)),
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
          const Icon(Icons.beach_access, color: kMainColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vacaciones y Licencias',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Gestión de permisos según Ley 16-92',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Badges informativos
          // Empleados en vacaciones hoy
          Builder(builder: (_) {
            final now = DateTime.now();
            final onVacationToday = allVacations.where((v) =>
                v.status == 'Aprobado' &&
                now.isAfter(v.startDate.subtract(const Duration(days: 1))) &&
                now.isBefore(v.endDate.add(const Duration(days: 1)))).length;
            if (onVacationToday > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.beach_access, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      '$onVacationToday hoy',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          // Vacaciones vencidas
          if (eligibilities.where((e) => e.urgencyLevel == 'VENCIDO').isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    '${eligibilities.where((e) => e.urgencyLevel == 'VENCIDO').length} Vencidas',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          // Vacaciones próximas
          if (eligibilities.where((e) => e.urgencyLevel == 'URGENTE' || e.urgencyLevel == 'PRÓXIMO').isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber[700]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 6),
                  Text(
                    '${eligibilities.where((e) => e.urgencyLevel == 'URGENTE' || e.urgencyLevel == 'PRÓXIMO').length} Próximas',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          // Solicitudes pendientes
          if (pendingVacations.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${pendingVacations.length} Pendientes',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
          // Selector de año
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: kMainColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                items: List.generate(5, (index) {
                  final year = (DateTime.now().year - 2 + index).toString();
                  return DropdownMenuItem(value: year, child: Text(year));
                }),
                onChanged: (value) {
                  setState(() => selectedYear = value!);
                },
              ),
            ),
          ),
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
            text: 'Solicitudes',
          ),
          Tab(
            icon: Icon(Icons.account_balance_wallet),
            text: 'Balance de Días',
          ),
          Tab(
            icon: Icon(Icons.calendar_month),
            text: 'Calendario',
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filtros y estadísticas
        _buildFilters(),
        // Lista de solicitudes
        Expanded(
          child: filteredVacations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay solicitudes',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredVacations.length,
                  itemBuilder: (context, index) {
                    return _buildVacationCard(filteredVacations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final approved = allVacations.where((v) => v.status == 'Aprobado').length;
    final pending = allVacations.where((v) => v.status == 'Pendiente').length;
    final rejected = allVacations.where((v) => v.status == 'Rechazado').length;

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
          // Filtro por estado
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
          const SizedBox(width: 24),
          _buildStatChip('Pendientes', pending, Colors.orange),
          const SizedBox(width: 16),
          _buildStatChip('Aprobadas', approved, Colors.green),
          const SizedBox(width: 16),
          _buildStatChip('Rechazadas', rejected, Colors.red),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacationCard(VacationModel vacation) {
    Color statusColor;
    IconData statusIcon;

    switch (vacation.status) {
      case 'Aprobado':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
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
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
    }

    IconData typeIcon;
    switch (vacation.type) {
      case 'Vacaciones':
        typeIcon = Icons.beach_access;
        break;
      case 'Licencia Maternidad':
        typeIcon = Icons.pregnant_woman;
        break;
      case 'Licencia Paternidad':
        typeIcon = Icons.child_care;
        break;
      case 'Licencia Médica':
        typeIcon = Icons.medical_services;
        break;
      default:
        typeIcon = Icons.event_note;
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
                  child: Icon(typeIcon, color: kMainColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Info del empleado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vacation.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${vacation.designation} - ${vacation.department}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        vacation.status,
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
            const Divider(height: 24),
            // Detalles
            Row(
              children: [
                _buildDetailItem(
                  'Tipo',
                  vacation.type,
                  Icons.category,
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  'Desde',
                  DateFormat('dd/MM/yyyy').format(vacation.startDate),
                  Icons.calendar_today,
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  'Hasta',
                  DateFormat('dd/MM/yyyy').format(vacation.endDate),
                  Icons.event,
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  'Días',
                  vacation.status == 'Aprobado'
                      ? '${vacation.daysApproved}'
                      : '${vacation.daysRequested}',
                  Icons.today,
                ),
                const Spacer(),
                // Acciones
                if (vacation.status == 'Pendiente') ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveVacation(vacation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _rejectVacation(vacation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                  ),
                ],
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleAction(value, vacation),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Ver Detalles'),
                        ],
                      ),
                    ),
                    if (vacation.status == 'Pendiente')
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Cancelar'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (vacation.reason != null && vacation.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vacation.reason!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
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
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: kMainColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance de Vacaciones por Empleado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Según Ley 16-92: 14 días laborables después de 1 año de servicio',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Años Servicio')),
                  DataColumn(label: Text('Días Derecho')),
                  DataColumn(label: Text('Días Usados')),
                  DataColumn(label: Text('Días Pendientes')),
                  DataColumn(label: Text('Días Disponibles')),
                  DataColumn(label: Text('Último Permiso')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: balances.map((balance) {
                  final hasVacation = balance.yearsOfService >= 1;
                  return DataRow(
                    cells: [
                      DataCell(Text(balance.employeeName)),
                      DataCell(Text('${balance.yearsOfService}')),
                      DataCell(
                        Text(
                          '${balance.daysEntitled}',
                          style: TextStyle(
                            color: hasVacation ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text('${balance.daysUsed}')),
                      DataCell(
                        balance.daysPending > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${balance.daysPending}',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              )
                            : const Text('0'),
                      ),
                      DataCell(
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: balance.daysAvailable > 0
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${balance.daysAvailable}',
                            style: TextStyle(
                              color: balance.daysAvailable > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          balance.lastVacationDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(balance.lastVacationDate!)
                              : 'N/A',
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: kMainColor),
                          tooltip: 'Nueva solicitud',
                          onPressed: hasVacation && balance.daysAvailable > 0
                              ? () => _showNewRequestDialogForEmployee(
                                  balance.employeeId)
                              : null,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Panel de Alertas - Próximas Vacaciones
        if (eligibilities.isNotEmpty) _buildEligibilityPanel(),
        // Calendario
        Expanded(child: _buildCalendarGrid()),
      ],
    );
  }

  /// Panel de alertas de próximas vacaciones
  Widget _buildEligibilityPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: kMainColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Próximas Vacaciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${eligibilities.length} empleados',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: eligibilities.length,
              itemBuilder: (context, index) {
                final e = eligibilities[index];
                return _buildEligibilityRow(e);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityRow(VacationEligibility e) {
    Color urgencyColor;
    IconData urgencyIcon;
    String urgencyLabel;

    switch (e.urgencyLevel) {
      case 'VENCIDO':
        urgencyColor = Colors.red;
        urgencyIcon = Icons.error;
        urgencyLabel = 'VENCIDO';
        break;
      case 'URGENTE':
        urgencyColor = Colors.orange;
        urgencyIcon = Icons.warning_amber;
        urgencyLabel = '${e.daysUntilAnniversary}d';
        break;
      case 'PRÓXIMO':
        urgencyColor = Colors.amber[700]!;
        urgencyIcon = Icons.schedule;
        urgencyLabel = '${e.daysUntilAnniversary}d';
        break;
      default:
        urgencyColor = Colors.green;
        urgencyIcon = Icons.check_circle_outline;
        urgencyLabel = '${e.daysUntilAnniversary}d';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Urgency badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: urgencyColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(urgencyIcon, size: 14, color: urgencyColor),
                const SizedBox(width: 4),
                Text(
                  urgencyLabel,
                  style: TextStyle(
                    color: urgencyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Employee info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${e.designation} • ${e.yearsOfService} años',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          // Anniversary date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Aniversario: ${DateFormat('dd/MM/yyyy').format(e.nextAnniversary)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                'Disponibles: ${e.daysAvailable} de ${e.daysEntitled} días',
                style: TextStyle(
                  fontSize: 11,
                  color: e.daysAvailable > 0 ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Last vacation
          if (e.lastVacationDate != null)
            Tooltip(
              message: 'Último permiso: ${DateFormat('dd/MM/yyyy').format(e.lastVacationDate!)}',
              child: Icon(Icons.history, size: 16, color: Colors.grey[400]),
            )
          else
            Tooltip(
              message: 'Nunca ha tomado vacaciones',
              child: Icon(Icons.warning, size: 16, color: Colors.red[300]),
            ),
          const SizedBox(width: 8),
          // Botón de solicitar vacaciones
          if (e.daysAvailable > 0)
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                onPressed: () => _showNewRequestDialogForEmployee(e.employeeId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Solicitar'),
              ),
            ),
        ],
      ),
    );
  }

  /// Calendario grilla mensual
  Widget _buildCalendarGrid() {
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = monthEnd.day;

    // Día de la semana del primer día (1=lunes, 7=domingo)
    final firstWeekday = monthStart.weekday;

    // Vacaciones del mes seleccionado
    final monthVacations = allVacations.where((v) =>
        (v.status == 'Aprobado' || v.status == 'Completado') &&
        !(v.endDate.isBefore(monthStart) || v.startDate.isAfter(monthEnd))).toList();

    // Aniversarios del mes
    final monthAnniversaries = eligibilities.where((e) =>
        e.nextAnniversary.month == selectedMonth.month &&
        e.nextAnniversary.year == selectedMonth.year).toList();

    // También buscar aniversarios de todos los empleados (no solo los de 90 días)
    final allAnniversaries = <int, List<String>>{};
    for (var emp in employees) {
      if (emp.joiningDate.month == selectedMonth.month && emp.yearsOfService >= 1) {
        final day = emp.joiningDate.day;
        allAnniversaries.putIfAbsent(day, () => []);
        allAnniversaries[day]!.add(emp.fullName);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                  });
                },
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'es').format(selectedMonth).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                  });
                },
              ),
              const SizedBox(width: 16),
              // Leyenda
              _buildLegendItem('Vacaciones', Colors.blue),
              const SizedBox(width: 8),
              _buildLegendItem('Médica', Colors.red),
              const SizedBox(width: 8),
              _buildLegendItem('Mat./Pat.', Colors.purple),
              const SizedBox(width: 8),
              _buildLegendItem('Aniversario', kMainColor),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday headers
          Row(
            children: ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM']
                .map((day) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: kMainColor.withValues(alpha: 0.1),
                          border: Border.all(color: kMainColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kMainColor,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: (firstWeekday - 1) + daysInMonth,
              itemBuilder: (context, index) {
                // Empty cells before first day
                if (index < firstWeekday - 1) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                  );
                }

                final day = index - (firstWeekday - 1) + 1;
                if (day > daysInMonth) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                  );
                }

                final date = DateTime(selectedMonth.year, selectedMonth.month, day);
                final isToday = DateTime.now().day == day &&
                    DateTime.now().month == selectedMonth.month &&
                    DateTime.now().year == selectedMonth.year;
                final isWeekend = date.weekday == DateTime.saturday ||
                    date.weekday == DateTime.sunday;

                // Vacations on this day
                final dayVacations = monthVacations.where((v) =>
                    !date.isBefore(v.startDate) && !date.isAfter(v.endDate)).toList();

                // Anniversary on this day
                final hasAnniversary = allAnniversaries.containsKey(day);

                return InkWell(
                  onTap: (dayVacations.isNotEmpty || hasAnniversary)
                      ? () => _showDayDetails(date, dayVacations,
                          hasAnniversary ? allAnniversaries[day]! : [])
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? kMainColor.withValues(alpha: 0.08)
                          : isWeekend
                              ? Colors.grey[50]
                              : Colors.white,
                      border: Border.all(
                        color: isToday ? kMainColor : Colors.grey[200]!,
                        width: isToday ? 2 : 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Day number
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasAnniversary)
                                const Icon(Icons.star, size: 12, color: kMainColor),
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday
                                      ? kMainColor
                                      : isWeekend
                                          ? Colors.grey[400]
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vacation dots
                        if (dayVacations.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: dayVacations.take(3).map((v) {
                                  Color dotColor;
                                  switch (v.type) {
                                    case 'Vacaciones':
                                      dotColor = Colors.blue;
                                      break;
                                    case 'Licencia Médica':
                                      dotColor = Colors.red;
                                      break;
                                    case 'Licencia Maternidad':
                                    case 'Licencia Paternidad':
                                      dotColor = Colors.purple;
                                      break;
                                    default:
                                      dotColor = Colors.orange;
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 1),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        if (dayVacations.length > 3)
                          Text(
                            '+${dayVacations.length - 3}',
                            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar detalles de un día
  void _showDayDetails(DateTime date, List<VacationModel> vacations, List<String> anniversaries) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calendar_today, color: kMainColor),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMMM yyyy', 'es').format(date)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (anniversaries.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kMainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kMainColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star, color: kMainColor, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Aniversarios Laborales',
                            style: TextStyle(fontWeight: FontWeight.bold, color: kMainColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...anniversaries.map((name) => Padding(
                            padding: const EdgeInsets.only(left: 24, bottom: 2),
                            child: Text('• $name', style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (vacations.isNotEmpty) ...[
                const Text(
                  'Empleados de permiso:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...vacations.map((v) {
                  Color color;
                  switch (v.type) {
                    case 'Vacaciones':
                      color = Colors.blue;
                      break;
                    case 'Licencia Médica':
                      color = Colors.red;
                      break;
                    case 'Licencia Maternidad':
                    case 'Licencia Paternidad':
                      color = Colors.purple;
                      break;
                    default:
                      color = Colors.orange;
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.employeeName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${v.type} • ${DateFormat('dd/MM').format(v.startDate)} - ${DateFormat('dd/MM').format(v.endDate)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${v.daysApproved}d',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (vacations.isEmpty && anniversaries.isEmpty)
                const Text('No hay eventos para este día'),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showNewRequestDialog({EmployeeModel? preSelectedEmployee}) {
    if (employees.isEmpty) {
      toast('No hay empleados disponibles');
      return;
    }

    EmployeeModel? selectedEmployee = preSelectedEmployee;
    String selectedType = LeaveTypes.vacaciones;
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 15));
    final reasonController = TextEditingController();
    final daysDeductController = TextEditingController();
    int? customDays; // Días personalizados (para descontar menos)

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final maxDays = LeaveTypes.getMaxDays(selectedType);
          final businessDays = VacationModel.calculateBusinessDays(startDate, endDate);
          final effectiveDays = customDays ?? businessDays;

          // Calcular balance del empleado seleccionado
          VacationBalance? empBalance;
          if (selectedEmployee != null) {
            final empId = selectedEmployee!.id;
            final matchingBalances = balances.where((b) => b.employeeId == empId);
            if (matchingBalances.isNotEmpty) {
              empBalance = matchingBalances.first;
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.beach_access, color: kMainColor),
                SizedBox(width: 8),
                Text('Nueva Solicitud de Vacaciones'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Empleado
                    DropdownButtonFormField<EmployeeModel>(
                      value: selectedEmployee,
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
                    // Mostrar balance del empleado
                    if (empBalance != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kMainColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kMainColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('${empBalance!.daysEntitled}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kMainColor)),
                                Text('Derecho', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                            Column(
                              children: [
                                Text('${empBalance!.daysUsed}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                                Text('Usados', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                            Column(
                              children: [
                                Text('${empBalance!.daysAvailable}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: empBalance!.daysAvailable > 0 ? Colors.green : Colors.red)),
                                Text('Disponibles', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Tipo de licencia
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Solicitud',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: LeaveTypes.all.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text('$type (máx. ${LeaveTypes.getMaxDays(type)} días)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Fechas
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  startDate = date;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate.add(Duration(days: maxDays - 1));
                                  }
                                  customDays = null;
                                  daysDeductController.clear();
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Inicio',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  endDate = date;
                                  customDays = null;
                                  daysDeductController.clear();
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Fin',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event),
                              ),
                              child: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Días calculados + campo de ajuste
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: effectiveDays > maxDays
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Días laborables del rango:',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              Text(
                                '$businessDays días',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Días a descontar:',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                height: 36,
                                child: TextFormField(
                                  controller: daysDeductController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '$businessDays',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      final parsed = int.tryParse(value);
                                      if (parsed != null && parsed > 0 && parsed <= businessDays) {
                                        customDays = parsed;
                                      } else if (value.isEmpty) {
                                        customDays = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (customDays != null && customDays != businessDays)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Se descontarán $customDays de $businessDays días laborables',
                                style: TextStyle(color: Colors.blue[700], fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (effectiveDays > maxDays)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Excede el máximo permitido de $maxDays días',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Motivo
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        hintText: 'Describa el motivo de la solicitud...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
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
              ElevatedButton.icon(
                onPressed: selectedEmployee != null
                    ? () async {
                        Navigator.pop(context);
                        final vacation = VacationModel(
                          id: DateTime.now().millisecondsSinceEpoch,
                          employeeId: selectedEmployee!.id,
                          employeeName: selectedEmployee!.fullName,
                          employeeCedula: selectedEmployee!.cedula,
                          designation: selectedEmployee!.designation,
                          department: selectedEmployee!.department,
                          type: selectedType,
                          startDate: startDate,
                          endDate: endDate,
                          daysRequested: effectiveDays,
                          status: 'Pendiente',
                          reason: reasonController.text.isNotEmpty
                              ? reasonController.text
                              : null,
                          requestDate: DateTime.now(),
                          isPaid: LeaveTypes.isPaid(selectedType),
                        );
                        await _vacationRepo.createVacationRequest(
                            vacation: vacation);
                        _loadData();
                      }
                    : null,
                icon: const Icon(Icons.send),
                label: const Text('Crear Solicitud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNewRequestDialogForEmployee(dynamic employeeId) {
    final emp = employees.where((e) => e.id == employeeId);
    if (emp.isNotEmpty) {
      _showNewRequestDialog(preSelectedEmployee: emp.first);
    } else {
      _showNewRequestDialog();
    }
  }

  void _approveVacation(VacationModel vacation) async {
    await _vacationRepo.approveVacation(
      vacationId: vacation.id,
      approvedBy: 'Administrador',
      daysApproved: vacation.daysRequested,
    );
    _loadData();
  }

  void _rejectVacation(VacationModel vacation) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Está seguro de rechazar la solicitud de ${vacation.employeeName}?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              await _vacationRepo.rejectVacation(
                vacationId: vacation.id,
                rejectedBy: 'Administrador',
                reason: reasonController.text,
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

  void _handleAction(String action, VacationModel vacation) async {
    switch (action) {
      case 'view':
        _showVacationDetails(vacation);
        break;
      case 'cancel':
        await _vacationRepo.cancelVacation(vacationId: vacation.id);
        _loadData();
        break;
      case 'delete':
        await _vacationRepo.deleteVacation(vacationId: vacation.id);
        _loadData();
        break;
    }
  }

  void _showVacationDetails(VacationModel vacation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles - ${vacation.employeeName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tipo', vacation.type),
              _buildDetailRow('Estado', vacation.status),
              _buildDetailRow('Desde', DateFormat('dd/MM/yyyy').format(vacation.startDate)),
              _buildDetailRow('Hasta', DateFormat('dd/MM/yyyy').format(vacation.endDate)),
              _buildDetailRow('Días Solicitados', '${vacation.daysRequested}'),
              if (vacation.daysApproved > 0)
                _buildDetailRow('Días Aprobados', '${vacation.daysApproved}'),
              _buildDetailRow('Fecha Solicitud',
                  DateFormat('dd/MM/yyyy HH:mm').format(vacation.requestDate)),
              if (vacation.approvedBy != null)
                _buildDetailRow('Aprobado por', vacation.approvedBy!),
              if (vacation.reason != null)
                _buildDetailRow('Motivo', vacation.reason!),
              if (vacation.rejectionReason != null)
                _buildDetailRow('Razón Rechazo', vacation.rejectionReason!),
              if (vacation.isPaid && vacation.vacationPay != null)
                _buildDetailRow(
                    'Pago Vacaciones', currencyFormat.format(vacation.vacationPay)),
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
