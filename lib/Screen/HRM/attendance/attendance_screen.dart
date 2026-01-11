import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/HRM/attendance/model/attendance_model.dart';
import 'package:salespro_admin/Screen/HRM/attendance/repo/attendance_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';

import '../../Widgets/Constant Data/constant.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  static const String route = '/hrm/attendance';

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  List<AttendanceModel> attendanceList = [];
  List<EmployeeModel> employees = [];
  bool isLoading = true;
  String selectedDepartment = 'Todos';
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final EmployeeRepository _employeeRepo = EmployeeRepository();

  final List<String> departments = [
    'Todos',
    'Administración',
    'Ventas',
    'Producción',
    'Recursos Humanos',
    'Contabilidad',
    'Almacén',
    'Servicio al Cliente',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final attList = await _attendanceRepo.getAttendanceByDate(selectedDate);

      setState(() {
        employees = empList;
        attendanceList = attList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast('Error al cargar datos: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadData();
    }
  }

  List<EmployeeModel> get filteredEmployees {
    if (selectedDepartment == 'Todos') return employees;
    return employees.where((e) => e.department == selectedDepartment).toList();
  }

  AttendanceModel? getAttendanceForEmployee(num employeeId) {
    return attendanceList.where((a) => a.employeeId == employeeId).firstOrNull;
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
                          _buildDailyAttendanceTab(),
                          _buildQuickCheckTab(),
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
    );
  }

  Widget _buildHeader() {
    final isHoliday = HolidaysRD.isHoliday(selectedDate);
    final isWeekend = selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;

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
          const Icon(Icons.access_time, color: kMainColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Control de Asistencia',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Gestión de entrada y salida de empleados',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Indicador de feriado o fin de semana
          if (isHoliday || isWeekend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isHoliday ? Colors.red[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHoliday ? Colors.red : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isHoliday ? Icons.celebration : Icons.weekend,
                    size: 16,
                    color: isHoliday ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isHoliday ? 'Día Feriado' : 'Fin de Semana',
                    style: TextStyle(
                      color: isHoliday ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
          // Selector de fecha
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kMainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kMainColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: kMainColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'es').format(selectedDate),
                    style: const TextStyle(
                      color: kMainColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down, color: kMainColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Botón de refrescar
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
            text: 'Asistencia del Día',
          ),
          Tab(
            icon: Icon(Icons.touch_app),
            text: 'Registro Rápido',
          ),
          Tab(
            icon: Icon(Icons.bar_chart),
            text: 'Resumen',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAttendanceTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filtros y estadísticas rápidas
        _buildDailyStats(),
        // Lista de asistencia
        Expanded(
          child: filteredEmployees.isEmpty
              ? const Center(
                  child: Text('No hay empleados para mostrar'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    final attendance = getAttendanceForEmployee(employee.id);
                    return _buildAttendanceCard(employee, attendance);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDailyStats() {
    final present = attendanceList.where((a) =>
        a.status == AttendanceStatus.presente ||
        a.status == AttendanceStatus.tardanza).length;
    final late = attendanceList
        .where((a) => a.status == AttendanceStatus.tardanza)
        .length;
    final absent = employees.length - present - late;
    final onLeave = attendanceList
        .where((a) =>
            a.status == AttendanceStatus.permiso ||
            a.status == AttendanceStatus.vacaciones ||
            a.status.contains('Licencia'))
        .length;

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
          // Filtro por departamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDepartment,
                items: departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedDepartment = value!);
                },
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Estadísticas
          _buildStatChip('Presentes', present, Colors.green),
          const SizedBox(width: 16),
          _buildStatChip('Tardanzas', late, Colors.orange),
          const SizedBox(width: 16),
          _buildStatChip('Ausentes', absent, Colors.red),
          const SizedBox(width: 16),
          _buildStatChip('Con Permiso', onLeave, Colors.blue),
          const Spacer(),
          // Botón para generar registros
          ElevatedButton.icon(
            onPressed: () => _generateDailyRecords(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Generar Registros'),
          ),
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

  Widget _buildAttendanceCard(EmployeeModel employee, AttendanceModel? attendance) {
    final hasCheckedIn = attendance?.checkInTime != null;
    final hasCheckedOut = attendance?.checkOutTime != null;

    Color statusColor = Colors.grey;
    String statusText = 'Sin registro';
    IconData statusIcon = Icons.remove_circle_outline;

    if (attendance != null) {
      switch (attendance.status) {
        case AttendanceStatus.presente:
          statusColor = Colors.green;
          statusText = 'Presente';
          statusIcon = Icons.check_circle;
          break;
        case AttendanceStatus.tardanza:
          statusColor = Colors.orange;
          statusText = 'Tardanza';
          statusIcon = Icons.access_time;
          break;
        case AttendanceStatus.ausente:
          statusColor = Colors.red;
          statusText = 'Ausente';
          statusIcon = Icons.cancel;
          break;
        case AttendanceStatus.permiso:
          statusColor = Colors.blue;
          statusText = 'Con Permiso';
          statusIcon = Icons.event_note;
          break;
        case AttendanceStatus.vacaciones:
          statusColor = Colors.purple;
          statusText = 'Vacaciones';
          statusIcon = Icons.beach_access;
          break;
        default:
          if (attendance.status.contains('Licencia')) {
            statusColor = Colors.teal;
            statusText = attendance.status;
            statusIcon = Icons.medical_services;
          }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: kMainColor.withValues(alpha: 0.1),
              child: Text(
                employee.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: kMainColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info del empleado
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee.designation} - ${employee.department}',
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
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Hora de entrada
            _buildTimeColumn(
              'Entrada',
              hasCheckedIn ? _formatTime(attendance!.checkInTime!) : '--:--',
              hasCheckedIn ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 16),
            // Hora de salida
            _buildTimeColumn(
              'Salida',
              hasCheckedOut ? _formatTime(attendance!.checkOutTime!) : '--:--',
              hasCheckedOut ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 16),
            // Horas trabajadas
            _buildTimeColumn(
              'Horas',
              attendance != null && attendance.hoursWorked > 0
                  ? '${attendance.hoursWorked.toStringAsFixed(1)}h'
                  : '0.0h',
              Colors.purple,
            ),
            const SizedBox(width: 16),
            // Acciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleAction(value, employee, attendance),
              itemBuilder: (context) => [
                if (!hasCheckedIn)
                  const PopupMenuItem(
                    value: 'check_in',
                    child: Row(
                      children: [
                        Icon(Icons.login, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Registrar Entrada'),
                      ],
                    ),
                  ),
                if (hasCheckedIn && !hasCheckedOut)
                  const PopupMenuItem(
                    value: 'check_out',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Registrar Salida'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Editar Registro'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_absent',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Marcar Ausente'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_permission',
                  child: Row(
                    children: [
                      Icon(Icons.event_note, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Marcar Permiso'),
                    ],
                  ),
                ),
                if (attendance != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar Registro'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCheckTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Reloj grande
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Column(
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: kMainColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'es').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Grid de empleados para marcar rápido
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final employee = filteredEmployees[index];
                final attendance = getAttendanceForEmployee(employee.id);
                return _buildQuickCheckCard(employee, attendance);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCheckCard(EmployeeModel employee, AttendanceModel? attendance) {
    final hasCheckedIn = attendance?.checkInTime != null;
    final hasCheckedOut = attendance?.checkOutTime != null;

    Color cardColor = Colors.grey[100]!;
    IconData actionIcon = Icons.login;
    String actionLabel = 'Entrada';

    if (hasCheckedIn && !hasCheckedOut) {
      cardColor = Colors.green[50]!;
      actionIcon = Icons.logout;
      actionLabel = 'Salida';
    } else if (hasCheckedOut) {
      cardColor = Colors.blue[50]!;
      actionIcon = Icons.check_circle;
      actionLabel = 'Completado';
    }

    return InkWell(
      onTap: hasCheckedOut
          ? null
          : () async {
              if (!hasCheckedIn) {
                await _attendanceRepo.checkIn(employee: employee);
              } else {
                await _attendanceRepo.checkOut(employeeId: employee.id);
              }
              _loadData();
            },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCheckedOut
                ? Colors.blue
                : hasCheckedIn
                    ? Colors.green
                    : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: kMainColor.withValues(alpha: 0.1),
              child: Text(
                employee.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: kMainColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              employee.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(actionIcon, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (hasCheckedIn)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Entrada: ${_formatTime(attendance!.checkInTime!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
            if (hasCheckedOut)
              Text(
                'Salida: ${_formatTime(attendance!.checkOutTime!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
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
          Row(
            children: [
              Text(
                'Resumen del ${DateFormat('MMMM yyyy', 'es').format(selectedDate)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _exportSummary(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Cards de resumen
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryCard(
                'Total Empleados',
                employees.length.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Días Laborables',
                _getWorkDaysInMonth().toString(),
                Icons.calendar_today,
                Colors.purple,
              ),
              _buildSummaryCard(
                'Promedio Asistencia',
                '${_getAverageAttendance().toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
              _buildSummaryCard(
                'Horas Extra Acumuladas',
                '${_getTotalOvertimeHours().toStringAsFixed(1)}h',
                Icons.access_time,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tabla de resumen por empleado
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                  columns: const [
                    DataColumn(label: Text('Empleado')),
                    DataColumn(label: Text('Departamento')),
                    DataColumn(label: Text('Días Presente')),
                    DataColumn(label: Text('Tardanzas')),
                    DataColumn(label: Text('Ausencias')),
                    DataColumn(label: Text('Permisos')),
                    DataColumn(label: Text('Horas Trabajadas')),
                    DataColumn(label: Text('Horas Extra')),
                    DataColumn(label: Text('% Asistencia')),
                  ],
                  rows: employees.map((employee) {
                    return DataRow(cells: [
                      DataCell(Text(employee.fullName)),
                      DataCell(Text(employee.department)),
                      DataCell(Text('--')), // Calcular desde datos reales
                      DataCell(Text('--')),
                      DataCell(Text('--')),
                      DataCell(Text('--')),
                      DataCell(Text('--')),
                      DataCell(Text('--')),
                      DataCell(Text('--')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
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

  int _getWorkDaysInMonth() {
    final year = selectedDate.year;
    final month = selectedDate.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    int workDays = 0;
    for (var day = firstDay;
        day.isBefore(lastDay.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      if (day.weekday != DateTime.saturday &&
          day.weekday != DateTime.sunday &&
          !HolidaysRD.isHoliday(day)) {
        workDays++;
      }
    }
    return workDays;
  }

  double _getAverageAttendance() {
    if (attendanceList.isEmpty) return 0;
    final present = attendanceList.where((a) =>
        a.status == AttendanceStatus.presente ||
        a.status == AttendanceStatus.tardanza).length;
    return (present / employees.length) * 100;
  }

  double _getTotalOvertimeHours() {
    return attendanceList.fold(0.0, (sum, a) => sum + a.overtimeHours);
  }

  void _handleAction(String action, EmployeeModel employee, AttendanceModel? attendance) async {
    switch (action) {
      case 'check_in':
        await _attendanceRepo.checkIn(employee: employee);
        break;
      case 'check_out':
        await _attendanceRepo.checkOut(employeeId: employee.id);
        break;
      case 'mark_absent':
        await _markAttendance(employee, AttendanceStatus.ausente);
        break;
      case 'mark_permission':
        await _markAttendance(employee, AttendanceStatus.permiso);
        break;
      case 'edit':
        _showEditDialog(employee, attendance);
        break;
      case 'delete':
        if (attendance != null) {
          await _attendanceRepo.deleteAttendance(id: attendance.id);
        }
        break;
    }
    _loadData();
  }

  Future<void> _markAttendance(EmployeeModel employee, String status) async {
    final attendanceId = DateTime.now().millisecondsSinceEpoch;
    final attendance = AttendanceModel(
      id: attendanceId,
      employeeId: employee.id,
      employeeName: employee.fullName,
      employeeCedula: employee.cedula,
      designation: employee.designation,
      department: employee.department,
      date: selectedDate,
      status: status,
    );
    await _attendanceRepo.saveManualAttendance(attendance: attendance);
  }

  Future<void> _generateDailyRecords() async {
    final records = await _attendanceRepo.generateDailyAttendance(selectedDate);
    for (var record in records) {
      await _attendanceRepo.saveManualAttendance(attendance: record);
    }
    _loadData();
  }

  void _showEditDialog(EmployeeModel employee, AttendanceModel? attendance) {
    TimeOfDay? checkInTime = attendance?.checkInTime != null
        ? TimeOfDay.fromDateTime(attendance!.checkInTime!)
        : null;
    TimeOfDay? checkOutTime = attendance?.checkOutTime != null
        ? TimeOfDay.fromDateTime(attendance!.checkOutTime!)
        : null;
    String selectedStatus = attendance?.status ?? AttendanceStatus.presente;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Asistencia - ${employee.fullName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estado
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: AttendanceStatus.all.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => selectedStatus = value!,
              ),
              const SizedBox(height: 16),
              // Hora de entrada
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: checkInTime ?? const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (time != null) {
                          checkInTime = time;
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora Entrada',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          checkInTime?.format(context) ?? 'Seleccionar',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: checkOutTime ?? const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (time != null) {
                          checkOutTime = time;
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora Salida',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          checkOutTime?.format(context) ?? 'Seleccionar',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              DateTime? checkIn;
              DateTime? checkOut;

              if (checkInTime != null) {
                checkIn = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  checkInTime!.hour,
                  checkInTime!.minute,
                );
              }

              if (checkOutTime != null) {
                checkOut = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  checkOutTime!.hour,
                  checkOutTime!.minute,
                );
              }

              final updatedAttendance = AttendanceModel(
                id: attendance?.id ?? DateTime.now().millisecondsSinceEpoch,
                employeeId: employee.id,
                employeeName: employee.fullName,
                employeeCedula: employee.cedula,
                designation: employee.designation,
                department: employee.department,
                date: selectedDate,
                checkInTime: checkIn,
                checkOutTime: checkOut,
                status: selectedStatus,
                hoursWorked: checkIn != null && checkOut != null
                    ? checkOut.difference(checkIn).inMinutes / 60
                    : 0,
              );

              if (attendance != null) {
                await _attendanceRepo.updateAttendance(attendance: updatedAttendance);
              } else {
                await _attendanceRepo.saveManualAttendance(attendance: updatedAttendance);
              }
              _loadData();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _exportSummary() {
    toast('Función de exportación en desarrollo');
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
