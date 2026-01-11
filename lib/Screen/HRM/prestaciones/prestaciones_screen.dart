import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/HRM/prestaciones/model/prestaciones_model.dart';
import 'package:salespro_admin/Screen/HRM/prestaciones/repo/prestaciones_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../Widgets/Constant Data/constant.dart';

class PrestacionesScreen extends StatefulWidget {
  const PrestacionesScreen({super.key});

  static const String route = '/hrm/prestaciones';

  @override
  State<PrestacionesScreen> createState() => _PrestacionesScreenState();
}

class _PrestacionesScreenState extends State<PrestacionesScreen> {
  List<PrestacionesLaboralesModel> allPrestaciones = [];
  List<EmployeeModel> employees = [];
  Map<String, dynamic> summary = {};
  bool isLoading = true;
  String filterStatus = 'Todos';

  final PrestacionesRepository _prestacionesRepo = PrestacionesRepository();
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  final List<String> statusOptions = [
    'Todos',
    'Calculado',
    'Aprobado',
    'Pagado',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final empList = await _employeeRepo.getAllEmployees();
      final prestList = await _prestacionesRepo.getAllPrestaciones();
      final summaryData = await _prestacionesRepo.getPrestacionesSummary();

      setState(() {
        employees = empList;
        allPrestaciones = prestList;
        summary = summaryData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast('Error al cargar datos: $e');
    }
  }

  List<PrestacionesLaboralesModel> get filteredPrestaciones {
    if (filterStatus == 'Todos') return allPrestaciones;
    return allPrestaciones.where((p) => p.status == filterStatus).toList();
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lista de liquidaciones
                  Expanded(
                    flex: 3,
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
                          _buildFilters(),
                          Expanded(child: _buildPrestacionesList()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Panel de resumen
                  Expanded(
                    flex: 1,
                    child: _buildSummaryPanel(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCalculateDialog(),
        backgroundColor: kMainColor,
        icon: const Icon(Icons.calculate, color: Colors.white),
        label: const Text('Calcular Liquidación',
            style: TextStyle(color: Colors.white)),
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
          const Icon(Icons.gavel, color: kMainColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prestaciones Laborales',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Cálculo según Código de Trabajo RD (Ley 16-92)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Info legal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Art. 76, 80, 177, 219',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            'Estado:',
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
            '${filteredPrestaciones.length} registros',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPrestacionesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredPrestaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay liquidaciones registradas',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCalculateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Calcular Nueva Liquidación'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPrestaciones.length,
      itemBuilder: (context, index) {
        return _buildPrestacionCard(filteredPrestaciones[index]);
      },
    );
  }

  Widget _buildPrestacionCard(PrestacionesLaboralesModel prestacion) {
    Color statusColor;
    IconData statusIcon;

    switch (prestacion.status) {
      case 'Calculado':
        statusColor = Colors.orange;
        statusIcon = Icons.calculate;
        break;
      case 'Aprobado':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'Pagado':
        statusColor = Colors.green;
        statusIcon = Icons.payments;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: kMainColor.withValues(alpha: 0.1),
                  child: Text(
                    prestacion.employeeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: kMainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prestacion.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${prestacion.designation} - ${prestacion.department}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tipo de terminación
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prestacion.terminationType,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        prestacion.status,
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
            // Información de servicio
            Row(
              children: [
                _buildInfoItem(
                  'Tiempo Servicio',
                  '${prestacion.yearsOfService} años, ${prestacion.monthsOfService % 12} meses',
                  Icons.work_history,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  'Fecha Ingreso',
                  DateFormat('dd/MM/yyyy').format(prestacion.joiningDate),
                  Icons.login,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  'Fecha Terminación',
                  DateFormat('dd/MM/yyyy').format(prestacion.terminationDate),
                  Icons.logout,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  'Salario',
                  currencyFormat.format(prestacion.lastMonthlySalary),
                  Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Desglose de prestaciones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildAmountItem('Cesantía', prestacion.cesantia),
                  _buildAmountItem('Preaviso', prestacion.preaviso),
                  _buildAmountItem('Vacaciones', prestacion.vacacionesPendientes),
                  _buildAmountItem('Regalía', prestacion.regaliaProporcional),
                  _buildAmountItem(
                      'Deducciones', -prestacion.totalDeducciones,
                      isNegative: true),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TOTAL NETO',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        currencyFormat.format(prestacion.totalNeto),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kMainColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDetails(prestacion),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Ver Detalles'),
                ),
                if (prestacion.status == 'Calculado') ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approvePrestacion(prestacion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                ],
                if (prestacion.status == 'Aprobado') ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _markAsPaid(prestacion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.payments, size: 18),
                    label: const Text('Registrar Pago'),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deletePrestacion(prestacion),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountItem(String label, double amount,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isNegative ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: kMainColor),
                SizedBox(width: 8),
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryItem(
                    'Total Liquidaciones',
                    '${summary['total'] ?? 0}',
                    Icons.folder,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    'Por Aprobar',
                    '${summary['pending'] ?? 0}',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    'Aprobadas',
                    '${summary['approved'] ?? 0}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    'Pagadas',
                    '${summary['paid'] ?? 0}',
                    Icons.payments,
                    Colors.green,
                  ),
                  const Divider(height: 32),
                  _buildSummaryItem(
                    'Total Monto',
                    currencyFormat.format(summary['totalAmount'] ?? 0),
                    Icons.account_balance,
                    Colors.purple,
                    isLarge: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    'Total Pagado',
                    currencyFormat.format(summary['totalPaid'] ?? 0),
                    Icons.check,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    'Pendiente Pago',
                    currencyFormat.format(summary['totalPending'] ?? 0),
                    Icons.schedule,
                    Colors.red,
                  ),
                  const Divider(height: 32),
                  // Información legal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel, size: 16, color: Colors.blue),
                            SizedBox(width: 6),
                            Text(
                              'Marco Legal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Art. 80 - Cesantía\n'
                          'Art. 76 - Preaviso\n'
                          'Art. 177 - Vacaciones\n'
                          'Art. 219 - Regalía Pascual',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color,
      {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isLarge ? 28 : 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculateDialog() {
    if (employees.isEmpty) {
      toast('No hay empleados registrados');
      return;
    }

    EmployeeModel? selectedEmployee;
    String selectedType = TerminationTypes.renuncia;
    DateTime terminationDate = DateTime.now();
    bool preavisoOmitido = false;
    final vacDaysController = TextEditingController(text: '0');
    final bonusController = TextEditingController(text: '0');
    final horasController = TextEditingController(text: '0');
    final otrasController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    PrestacionesResult? calculatedResult;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void calculate() {
            if (selectedEmployee != null) {
              final result = PrestacionesCalculator.calcularPrestacionesCompletas(
                salarioMensual: selectedEmployee!.salary,
                fechaIngreso: selectedEmployee!.joiningDate,
                fechaTerminacion: terminationDate,
                tipoTerminacion: selectedType,
                preavisoOmitido: preavisoOmitido,
                diasVacacionesTomados: int.tryParse(vacDaysController.text) ?? 0,
                bonificacionesPendientes: double.tryParse(bonusController.text) ?? 0,
                horasExtrasPendientes: double.tryParse(horasController.text) ?? 0,
                otrasDeduccciones: double.tryParse(otrasController.text) ?? 0,
              );
              setState(() => calculatedResult = result);
            }
          }

          return AlertDialog(
            title: const Text('Calcular Prestaciones Laborales'),
            content: SizedBox(
              width: 600,
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
                          child: Text('${e.fullName} - ${e.designation}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedEmployee = value);
                        calculate();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Terminación',
                              border: OutlineInputBorder(),
                            ),
                            items: TerminationTypes.all.map((type) {
                              return DropdownMenuItem(
                                  value: type, child: Text(type));
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedType = value!);
                              calculate();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: terminationDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => terminationDate = date);
                                calculate();
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Terminación',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(terminationDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Preaviso omitido
                    CheckboxListTile(
                      title: const Text('Preaviso Omitido'),
                      subtitle: const Text(
                          'Marcar si no se dio preaviso correspondiente'),
                      value: preavisoOmitido,
                      onChanged: (value) {
                        setState(() => preavisoOmitido = value!);
                        calculate();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: vacDaysController,
                            decoration: const InputDecoration(
                              labelText: 'Días Vacaciones Tomados',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculate(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: bonusController,
                            decoration: const InputDecoration(
                              labelText: 'Bonificaciones Pendientes',
                              border: OutlineInputBorder(),
                              prefixText: 'RD\$ ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: horasController,
                            decoration: const InputDecoration(
                              labelText: 'Horas Extras Pendientes (RD\$)',
                              border: OutlineInputBorder(),
                              prefixText: 'RD\$ ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculate(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: otrasController,
                            decoration: const InputDecoration(
                              labelText: 'Otras Deducciones',
                              border: OutlineInputBorder(),
                              prefixText: 'RD\$ ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    // Resultado del cálculo
                    if (calculatedResult != null) ...[
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RESULTADO DEL CÁLCULO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Divider(),
                            _buildResultRow('Tiempo de servicio',
                                '${calculatedResult!.anosServicio} años, ${calculatedResult!.mesesServicio % 12} meses'),
                            _buildResultRow('Cesantía (Art. 80)',
                                currencyFormat.format(calculatedResult!.cesantia)),
                            _buildResultRow('Preaviso (Art. 76)',
                                currencyFormat.format(calculatedResult!.preaviso)),
                            _buildResultRow('Vacaciones (Art. 177)',
                                currencyFormat.format(calculatedResult!.vacacionesPendientes)),
                            _buildResultRow('Salario Pendiente',
                                currencyFormat.format(calculatedResult!.salarioPendiente)),
                            _buildResultRow('Regalía Proporcional',
                                currencyFormat.format(calculatedResult!.regaliaProporcional)),
                            const Divider(),
                            _buildResultRow('Total Devengado',
                                currencyFormat.format(calculatedResult!.totalDevengado)),
                            _buildResultRow('Total Deducciones',
                                '-${currencyFormat.format(calculatedResult!.totalDeducciones)}',
                                isNegative: true),
                            const Divider(),
                            _buildResultRow('TOTAL NETO',
                                currencyFormat.format(calculatedResult!.totalNeto),
                                isBold: true),
                          ],
                        ),
                      ),
                    ],
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
                onPressed: selectedEmployee != null && calculatedResult != null
                    ? () async {
                        Navigator.pop(context);
                        final prestacion =
                            await _prestacionesRepo.calcularPrestaciones(
                          employee: selectedEmployee!,
                          fechaTerminacion: terminationDate,
                          tipoTerminacion: selectedType,
                          preavisoOmitido: preavisoOmitido,
                          diasVacacionesTomados:
                              int.tryParse(vacDaysController.text) ?? 0,
                          bonificacionesPendientes:
                              double.tryParse(bonusController.text) ?? 0,
                          horasExtrasPendientes:
                              double.tryParse(horasController.text) ?? 0,
                          otrasDeduccciones:
                              double.tryParse(otrasController.text) ?? 0,
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                        );
                        await _prestacionesRepo.savePrestaciones(
                            prestaciones: prestacion);
                        _loadData();
                      }
                    : null,
                child: const Text('Guardar Liquidación'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultRow(String label, String value,
      {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isNegative ? Colors.red : (isBold ? kMainColor : null),
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(PrestacionesLaboralesModel prestacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles - ${prestacion.employeeName}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('Información del Empleado', [
                  _buildDetailRow('Cédula', prestacion.employeeCedula),
                  _buildDetailRow('Cargo', prestacion.designation),
                  _buildDetailRow('Departamento', prestacion.department),
                  _buildDetailRow('Salario',
                      currencyFormat.format(prestacion.lastMonthlySalary)),
                ]),
                _buildDetailSection('Tiempo de Servicio', [
                  _buildDetailRow('Fecha Ingreso',
                      DateFormat('dd/MM/yyyy').format(prestacion.joiningDate)),
                  _buildDetailRow(
                      'Fecha Terminación',
                      DateFormat('dd/MM/yyyy')
                          .format(prestacion.terminationDate)),
                  _buildDetailRow('Tiempo Servicio',
                      '${prestacion.yearsOfService} años, ${prestacion.monthsOfService % 12} meses'),
                  _buildDetailRow(
                      'Tipo Terminación', prestacion.terminationType),
                ]),
                _buildDetailSection('Conceptos a Pagar', [
                  _buildDetailRow(
                      'Cesantía', currencyFormat.format(prestacion.cesantia)),
                  _buildDetailRow(
                      'Preaviso', currencyFormat.format(prestacion.preaviso)),
                  _buildDetailRow('Vacaciones',
                      currencyFormat.format(prestacion.vacacionesPendientes)),
                  _buildDetailRow('Salario Pendiente',
                      currencyFormat.format(prestacion.salarioPendiente)),
                  _buildDetailRow('Regalía',
                      currencyFormat.format(prestacion.regaliaProporcional)),
                  _buildDetailRow('Total Devengado',
                      currencyFormat.format(prestacion.totalDevengado),
                      isBold: true),
                ]),
                _buildDetailSection('Deducciones', [
                  _buildDetailRow('Préstamos',
                      currencyFormat.format(prestacion.deduccionPrestamos)),
                  _buildDetailRow('Adelantos',
                      currencyFormat.format(prestacion.deduccionAdelantos)),
                  _buildDetailRow('Otras',
                      currencyFormat.format(prestacion.otrasDeduccciones)),
                  _buildDetailRow('Total Deducciones',
                      currencyFormat.format(prestacion.totalDeducciones),
                      isBold: true),
                ]),
                const Divider(),
                _buildDetailRow(
                    'TOTAL NETO', currencyFormat.format(prestacion.totalNeto),
                    isBold: true, isLarge: true),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kMainColor,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isLarge ? 18 : 14,
              color: isLarge ? kMainColor : null,
            ),
          ),
        ],
      ),
    );
  }

  void _approvePrestacion(PrestacionesLaboralesModel prestacion) async {
    await _prestacionesRepo.approvePrestaciones(
      prestacionesId: prestacion.id,
      approvedBy: 'Administrador',
    );
    _loadData();
  }

  void _markAsPaid(PrestacionesLaboralesModel prestacion) {
    String paymentMethod = 'Transferencia';
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Monto a pagar: ${currencyFormat.format(prestacion.totalNeto)}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
              ],
              onChanged: (value) => paymentMethod = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Referencia de Pago',
                border: OutlineInputBorder(),
              ),
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
              await _prestacionesRepo.markAsPaid(
                prestacionesId: prestacion.id,
                paymentMethod: paymentMethod,
                paymentReference: referenceController.text.isNotEmpty
                    ? referenceController.text
                    : null,
              );
              _loadData();
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }

  void _deletePrestacion(PrestacionesLaboralesModel prestacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Liquidación'),
        content:
            Text('¿Está seguro de eliminar la liquidación de ${prestacion.employeeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _prestacionesRepo.deletePrestaciones(
                  prestacionesId: prestacion.id);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
