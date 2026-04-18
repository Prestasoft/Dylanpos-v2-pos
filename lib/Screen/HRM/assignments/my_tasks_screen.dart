import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Repository/task_repo.dart';
import 'package:salespro_admin/model/task_model.dart';

import 'widgets/task_countdown_card.dart';
import 'widgets/task_theme.dart';

/// Pantalla "Mis Tareas" — home del empleado.
///
/// Muestra las tareas asignadas con contadores animados en vivo.
/// Secciones:
///   1. Banner rojo si hay vencidas
///   2. Por vencer (urgencia critical/warning, ordenadas por due_at ASC)
///   3. Con tiempo (urgencia normal)
///   4. Completadas hoy (colapsable, gris)
class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final _taskRepo = TaskRepository();
  Timer? _refreshTimer;

  List<TaskModel> _tasks = [];
  bool _loading = true;
  bool _completedExpanded = false;
  String _userName = 'Empleado';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadTasks();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadTasks());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final name = getStringAsync('subUserTitle');
    if (name.isNotEmpty && mounted) {
      setState(() => _userName = name);
    }
  }

  Future<void> _loadTasks() async {
    try {
      // Primero marca vencidas en el backend
      await _taskRepo.markOverdue().catchError((_) => 0);
      debugPrint('🔵 [MyTasks._loadTasks] Llamando getMyTasks...');
      final tasks = await _taskRepo.getMyTasks();
      debugPrint('🔵 [MyTasks._loadTasks] Resultado: ${tasks.length} tasks');
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      debugPrint('🔴 [MyTasks._loadTasks] Error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _startTask(TaskModel task) async {
    EasyLoading.show(status: 'Iniciando...');
    final result = await _taskRepo.startTask(taskId: task.id);
    EasyLoading.dismiss();
    if (result != null) {
      EasyLoading.showSuccess('Tarea iniciada — ¡a trabajar!');
      _loadTasks();
    } else {
      EasyLoading.showError('Error al iniciar');
    }
  }

  Future<void> _completeTask(TaskModel task) async {
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => _CompletionDialog(),
    );
    if (note == null) return; // cancelado

    EasyLoading.show(status: 'Completando...');
    final result = await _taskRepo.completeTask(
      taskId: task.id,
      completionNote: note.isEmpty ? null : note,
    );
    EasyLoading.dismiss();

    if (result != null) {
      EasyLoading.showSuccess('Tarea completada');
      _loadTasks();
    } else {
      EasyLoading.showError('Error al completar');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clasificar tareas
    final overdue = _tasks.where((t) => t.urgency == TaskUrgency.overdue).toList();
    final critical = _tasks.where((t) => t.urgency == TaskUrgency.critical).toList();
    final warning = _tasks.where((t) => t.urgency == TaskUrgency.warning).toList();
    final normal = _tasks.where((t) => t.urgency == TaskUrgency.normal).toList();
    final pending = _tasks.where((t) => t.urgency == TaskUrgency.pending).toList();
    final done = _tasks.where((t) => t.urgency == TaskUrgency.done).toList();

    final urgentTasks = [...overdue, ...critical, ...warning];
    final pendingCount = overdue.length + critical.length + warning.length + normal.length + pending.length;

    final tc = TaskColors.of(context);

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        backgroundColor: tc.appBar,
        elevation: 0.5,
        iconTheme: tc.appBarIconTheme,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, $_userName', style: TextStyle(color: tc.appBarTitle, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '$pendingCount tarea${pendingCount == 1 ? '' : 's'} pendiente${pendingCount == 1 ? '' : 's'}',
              style: TextStyle(color: tc.appBarSubtitle, fontSize: 12),
            ),
          ],
        ),
        actions: [
          const TaskThemeToggle(),
          IconButton(
            icon: Icon(Icons.refresh, color: tc.appBarIcon),
            tooltip: 'Refrescar',
            onPressed: () {
              setState(() => _loading = true);
              _loadTasks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: tc.dialogBg,
                  title: Text('Cerrar sesión', style: TextStyle(color: tc.textPrimary)),
                  content: Text('¿Deseas salir del sistema?', style: TextStyle(color: tc.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sí, salir'),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                context.go('/');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Banner de vencidas
                      if (overdue.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tienes ${overdue.length} tarea${overdue.length == 1 ? '' : 's'} vencida${overdue.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sección urgentes (ya iniciadas, con countdown activo)
                      if (urgentTasks.isNotEmpty) ...[
                        _sectionHeader('Por vencer', Icons.schedule, const Color(0xFFEF4444)),
                        ...urgentTasks.map((t) => TaskCountdownCard(
                              task: t,
                              customerName: t.customerName ?? 'Cliente',
                              serviceName: t.serviceName ?? t.designationName,
                              onComplete: () => _completeTask(t),
                            )),
                      ],

                      // Sección sin iniciar (pendientes, esperando que el empleado presione INICIAR)
                      if (pending.isNotEmpty) ...[
                        _sectionHeader('Sin iniciar', Icons.play_circle_outline, const Color(0xFF3B82F6)),
                        ...pending.map((t) => TaskCountdownCard(
                              task: t,
                              customerName: t.customerName ?? 'Cliente',
                              serviceName: t.serviceName ?? t.designationName,
                              onStart: () => _startTask(t),
                              onComplete: () => _completeTask(t),
                            )),
                      ],

                      // Sección con tiempo (ya iniciadas, sin urgencia)
                      if (normal.isNotEmpty) ...[
                        _sectionHeader('Con tiempo', Icons.check_circle_outline, const Color(0xFF10B981)),
                        ...normal.map((t) => TaskCountdownCard(
                              task: t,
                              customerName: t.customerName ?? 'Cliente',
                              serviceName: t.serviceName ?? t.designationName,
                              onComplete: () => _completeTask(t),
                            )),
                      ],

                      // Sección completadas hoy (colapsable)
                      if (done.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => setState(() => _completedExpanded = !_completedExpanded),
                          child: Row(
                            children: [
                              Icon(
                                _completedExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                color: tc.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completadas hoy (${done.length})',
                                style: TextStyle(
                                  color: tc.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_completedExpanded) ...[
                          const SizedBox(height: 8),
                          ...done.map((t) => _buildCompletedCard(t)),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final tc = TaskColors.read(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 72, color: Colors.green[200]),
          const SizedBox(height: 16),
          Text(
            'Sin tareas pendientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tc.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando te asignen una tarea, aparecerá aquí.',
            style: TextStyle(color: tc.textHint),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(TaskModel t) {
    final tc = TaskColors.read(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tc.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.customerName ?? 'Cliente',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: tc.textPrimary),
                ),
                if (t.completionNote != null && t.completionNote!.isNotEmpty)
                  Text(t.completionNote!, style: TextStyle(fontSize: 11, color: tc.textSecondary)),
              ],
            ),
          ),
          if (t.designationName != null)
            Text(t.designationName!, style: TextStyle(fontSize: 10, color: tc.textHint)),
        ],
      ),
    );
  }

}

/// Diálogo de confirmación para completar tarea
class _CompletionDialog extends StatefulWidget {
  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    return AlertDialog(
      backgroundColor: tc.dialogBg,
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text('Completar tarea', style: TextStyle(color: tc.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nota de completado (opcional):', style: TextStyle(color: tc.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: TextStyle(color: tc.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ej: Fotos editadas y entregadas',
              hintStyle: TextStyle(color: tc.textHint),
              border: OutlineInputBorder(borderSide: BorderSide(color: tc.border)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: tc.border)),
              filled: tc.isDark,
              fillColor: tc.surface,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Completar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => Navigator.of(context).pop(_noteCtrl.text),
        ),
      ],
    );
  }
}
