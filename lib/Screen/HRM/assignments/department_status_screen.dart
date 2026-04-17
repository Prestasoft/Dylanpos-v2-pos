import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Repository/task_repo.dart';
import 'package:salespro_admin/model/task_model.dart';
import 'package:salespro_admin/services/api_service.dart';
import '../employees/repo/employee_repo.dart';
import 'widgets/task_theme.dart';

/// Panel del Encargado: vista general de su equipo con KPIs y semáforo.
///
/// El encargado ve cuántas tareas tiene cada empleado al día / por vencer /
/// atrasadas / completadas hoy. Auto-refresca cada 30 segundos.
class DepartmentStatusScreen extends ConsumerStatefulWidget {
  const DepartmentStatusScreen({super.key});

  @override
  ConsumerState<DepartmentStatusScreen> createState() => _DepartmentStatusScreenState();
}

class _DepartmentStatusScreenState extends ConsumerState<DepartmentStatusScreen> {
  final _taskRepo = TaskRepository();
  Timer? _refreshTimer;

  bool _loading = true;
  List<dynamic> _employees = [];
  Map<String, dynamic> _totals = {};
  num? _scopedDesignationId;

  @override
  void initState() {
    super.initState();
    _loadScope().then((_) {
      _loadData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadScope() async {
    try {
      final user = ApiService().currentUser;
      if (user == null) return;
      final scope = user['scoped_designation_id'];
      if (scope is num) {
        _scopedDesignationId = scope;
      } else if (scope is String && scope.isNotEmpty) {
        _scopedDesignationId = num.tryParse(scope);
      }

      // Fallback: si no hay scope, buscar por linked_employee_id
      if (_scopedDesignationId == null) {
        final linkedId = user['linked_employee_id']?.toString();
        if (linkedId != null && linkedId.isNotEmpty) {
          final allEmployees = await EmployeeRepository().getActiveEmployees();
          final linked = allEmployees.where((e) => e.id.toString() == linkedId).firstOrNull;
          if (linked != null) {
            _scopedDesignationId = linked.designationId;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadEmployeesFallback() async {
    try {
      final allEmployees = await EmployeeRepository().getActiveEmployees();
      final filtered = _scopedDesignationId != null
          ? allEmployees.where((e) => e.designationId == _scopedDesignationId).toList()
          : allEmployees;
      if (!mounted) return;
      setState(() {
        _employees = filtered.map((e) => {
          'employee_id': e.id.toString(),
          'employee_name': '${e.name} ${e.lastName}',
          'user_id': e.userId,
          'can_login': e.canLogin,
          'pendientes': 0,
          'en_progreso': 0,
          'vencidas': 0,
          'completadas_hoy': 0,
          'estado': 'sin_tareas',
        }).toList();
        _totals = {};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadData() async {
    try {
      // Si no hay scope, cargar todos los empleados como fallback
      if (_scopedDesignationId == null) {
        await _loadEmployeesFallback();
        return;
      }

      // Intentar cargar del endpoint de tasks primero
      Map<String, dynamic> data = {};
      List taskEmployees = [];
      try {
        data = await _taskRepo.getDepartmentStatus(
          designationId: _scopedDesignationId,
        );
        taskEmployees = (data['employees'] as List?) ?? [];
      } catch (_) {
        // Si el endpoint de tasks falla, ir directo al fallback
      }

      // Si el endpoint de tasks no devolvió empleados, cargar directamente
      // del repo de empleados filtrados por designation_id
      if (taskEmployees.isEmpty && _scopedDesignationId != null) {
        final allEmployees = await EmployeeRepository().getActiveEmployees();
        final filtered = allEmployees
            .where((e) => e.designationId == _scopedDesignationId)
            .toList();

        if (!mounted) return;
        setState(() {
          _employees = filtered.map((e) => {
            'employee_id': e.id.toString(),
            'employee_name': '${e.name} ${e.lastName}',
            'user_id': e.userId,
            'can_login': e.canLogin,
            'pendientes': 0,
            'en_progreso': 0,
            'vencidas': 0,
            'completadas_hoy': 0,
            'estado': 'sin_tareas',
          }).toList();
          _totals = {};
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _employees = taskEmployees;
        _totals = (data['totals'] as Map<String, dynamic>?) ?? {};
        _loading = false;
      });
    } catch (e) {
      // Fallback: cargar empleados directamente si el endpoint de tasks falla
      try {
        if (_scopedDesignationId != null) {
          final allEmployees = await EmployeeRepository().getActiveEmployees();
          final filtered = allEmployees
              .where((emp) => emp.designationId == _scopedDesignationId)
              .toList();
          if (!mounted) return;
          setState(() {
            _employees = filtered.map((emp) => {
              'employee_id': emp.id.toString(),
              'employee_name': '${emp.name} ${emp.lastName}',
              'user_id': emp.userId,
              'can_login': emp.canLogin,
              'pendientes': 0,
              'en_progreso': 0,
              'vencidas': 0,
              'completadas_hoy': 0,
              'estado': 'sin_tareas',
            }).toList();
            _totals = {};
            _loading = false;
          });
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        title: Text('Mi Equipo', style: TextStyle(color: tc.appBarTitle)),
        backgroundColor: tc.appBar,
        iconTheme: tc.appBarIconTheme,
        elevation: 0.5,
        actions: [
          const TaskThemeToggle(),
          IconButton(
            icon: Icon(Icons.refresh, color: tc.appBarIcon),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildKpiRow()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Empleados (${_employees.length})',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tc.textPrimary),
                      ),
                    ),
                  ),
                  _employees.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 64, color: tc.textHint),
                                const SizedBox(height: 16),
                                Text(
                                  'Sin empleados en este departamento',
                                  style: TextStyle(color: tc.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildEmployeeCard(_employees[i]),
                            childCount: _employees.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow() {
    final tc = TaskColors.read(context);
    final pendientes = _toInt(_totals['total_pendientes']);
    final enProgreso = _toInt(_totals['total_en_progreso']);
    final vencidas = _toInt(_totals['total_vencidas']);
    final completadas = _toInt(_totals['total_completadas_hoy']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: tc.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _kpiItem('Al día', pendientes + enProgreso, const Color(0xFF10B981), Icons.check_circle_outline, tc),
          _kpiDivider(tc),
          _kpiItem('Vencidas', vencidas, const Color(0xFFEF4444), Icons.warning_amber_rounded, tc),
          _kpiDivider(tc),
          _kpiItem('Completadas', completadas, const Color(0xFF3B82F6), Icons.task_alt, tc),
        ],
      ),
    );
  }

  Widget _kpiItem(String label, int value, Color color, IconData icon, TaskColors tc) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tc.textPrimary),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: tc.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _kpiDivider(TaskColors tc) {
    return Container(width: 1, height: 50, color: tc.divider);
  }

  Widget _buildEmployeeCard(dynamic emp) {
    final name = emp['employee_name']?.toString() ?? 'Desconocido';
    final estado = emp['estado']?.toString() ?? 'sin_tareas';
    final pendientes = _toInt(emp['pendientes']);
    final enProgreso = _toInt(emp['en_progreso']);
    final vencidas = _toInt(emp['vencidas']);
    final completadasHoy = _toInt(emp['completadas_hoy']);
    final canLogin = emp['can_login'] == true;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (estado) {
      case 'atrasado':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusLabel = 'Atrasado';
        break;
      case 'por_vencer':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Por vencer';
        break;
      case 'al_dia':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Al día';
        break;
      case 'sin_tareas':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
        statusLabel = 'Sin tareas';
    }

    final tc = TaskColors.read(context);

    return GestureDetector(
      onTap: () => _showEmployeeTasks(emp),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.border.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: tc.shadow, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Avatar + Nombre + Estado
            Row(
              children: [
                // Inicial del nombre con color de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
                const SizedBox(width: 12),
                // Nombre + badge sin acceso
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tc.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!canLogin)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('Sin acceso al sistema', style: TextStyle(fontSize: 11, color: tc.textHint)),
                        ),
                    ],
                  ),
                ),
                // Chip de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            // Fila 2: Stats en barra horizontal
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _statChip(pendientes, 'Pendientes', const Color(0xFFF59E0B), tc),
                  const SizedBox(width: 6),
                  _statChip(enProgreso, 'En progreso', const Color(0xFF3B82F6), tc),
                  const SizedBox(width: 6),
                  _statChip(vencidas, 'Vencidas', const Color(0xFFEF4444), tc),
                  const SizedBox(width: 6),
                  _statChip(completadasHoy, 'Hoy', const Color(0xFF10B981), tc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre un bottom sheet con las tareas del empleado seleccionado
  Future<void> _showEmployeeTasks(dynamic emp) async {
    final employeeId = emp['employee_id']?.toString();
    final employeeName = emp['employee_name']?.toString() ?? 'Empleado';
    final userId = emp['user_id']?.toString();

    if (employeeId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmployeeTasksSheet(
        employeeId: employeeId,
        userId: userId,
        employeeName: employeeName,
        taskRepo: _taskRepo,
      ),
    );
  }

  Widget _statChip(int value, String label, Color color, TaskColors tc) {
    final isActive = value > 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.10) : tc.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.25) : tc.border.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? color : tc.textHint,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 8, color: tc.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet que muestra las tareas de un empleado específico
class _EmployeeTasksSheet extends StatefulWidget {
  final String employeeId;
  final String? userId;
  final String employeeName;
  final TaskRepository taskRepo;

  const _EmployeeTasksSheet({
    required this.employeeId,
    this.userId,
    required this.employeeName,
    required this.taskRepo,
  });

  @override
  State<_EmployeeTasksSheet> createState() => _EmployeeTasksSheetState();
}

class _EmployeeTasksSheetState extends State<_EmployeeTasksSheet> {
  List<TaskModel> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final allTasks = await widget.taskRepo.getTasks();
      final filtered = allTasks.where((t) =>
        t.assignedToEmployeeId == widget.employeeId ||
        (widget.userId != null && t.assignedToUserId == widget.userId)
      ).toList();
      filtered.sort((a, b) => a.dueAt.compareTo(b.dueAt));
      if (!mounted) return;
      setState(() {
        _tasks = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _urgencyColor(TaskModel t) {
    final u = t.urgency;
    switch (u) {
      case TaskUrgency.normal: return Colors.green;
      case TaskUrgency.warning: return Colors.orange;
      case TaskUrgency.critical: return Colors.red;
      case TaskUrgency.overdue: return const Color(0xFF991B1B);
      case TaskUrgency.done: return Colors.grey;
    }
  }

  String _timeLabel(TaskModel t) {
    if (t.status == TaskStatus.completada) return 'Completada';
    final r = t.timeRemaining();
    if (r.isNegative) {
      final o = r.abs();
      if (o.inHours > 0) return 'Vencida hace ${o.inHours}h ${o.inMinutes % 60}m';
      return 'Vencida hace ${o.inMinutes}m';
    }
    final h = r.inHours;
    final m = r.inMinutes % 60;
    return '${h}h ${m}m restantes';
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                    child: Text(
                      widget.employeeName.isNotEmpty ? widget.employeeName[0] : '?',
                      style: TextStyle(color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.employeeName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tc.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_tasks.length} tarea${_tasks.length == 1 ? '' : 's'}',
                          style: TextStyle(color: tc.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: tc.appBarIcon),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tc.divider),
            // Lista de tareas
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 48, color: tc.textHint),
                              const SizedBox(height: 12),
                              Text('Sin tareas asignadas', style: TextStyle(color: tc.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          itemBuilder: (_, i) => _buildTaskTile(_tasks[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(TaskModel task) {
    final tc = TaskColors.read(context);
    final color = _urgencyColor(task);
    final progress = task.progress().clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: tc.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cliente + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  task.customerName ?? 'Cliente',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tc.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.status.label,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progreso + Tiempo
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: tc.progressBg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _timeLabel(task),
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
