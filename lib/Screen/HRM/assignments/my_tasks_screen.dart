import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Repository/task_repo.dart';
import 'package:salespro_admin/model/task_model.dart';

import 'widgets/task_countdown_card.dart';

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
      final tasks = await _taskRepo.getMyTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    final done = _tasks.where((t) => t.urgency == TaskUrgency.done).toList();

    final urgentTasks = [...overdue, ...critical, ...warning];
    final pendingCount = overdue.length + critical.length + warning.length + normal.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, $_userName', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '$pendingCount tarea${pendingCount == 1 ? '' : 's'} pendiente${pendingCount == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              setState(() => _loading = true);
              _loadTasks();
            },
          ),
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

                      // Sección urgentes
                      if (urgentTasks.isNotEmpty) ...[
                        _sectionHeader('Por vencer', Icons.schedule, const Color(0xFFEF4444)),
                        ...urgentTasks.map((t) => TaskCountdownCard(
                              task: t,
                              customerName: _extractCustomerName(t),
                              serviceName: t.designationName,
                              onComplete: () => _completeTask(t),
                            )),
                      ],

                      // Sección con tiempo
                      if (normal.isNotEmpty) ...[
                        _sectionHeader('Con tiempo', Icons.check_circle_outline, const Color(0xFF10B981)),
                        ...normal.map((t) => TaskCountdownCard(
                              task: t,
                              customerName: _extractCustomerName(t),
                              serviceName: t.designationName,
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
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completadas hoy (${done.length})',
                                style: TextStyle(
                                  color: Colors.grey[600],
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 72, color: Colors.green[200]),
          const SizedBox(height: 16),
          const Text(
            'Sin tareas pendientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando te asignen una tarea, aparecerá aquí.',
            style: TextStyle(color: Colors.grey[500]),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
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
                  _extractCustomerName(t),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                if (t.completionNote != null && t.completionNote!.isNotEmpty)
                  Text(t.completionNote!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          if (t.designationName != null)
            Text(t.designationName!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _extractCustomerName(TaskModel t) {
    final nota = t.reservationNota;
    if (nota == null || nota.isEmpty) return 'Cliente';
    // La nota puede tener formato "Nota visible ||| {json}", solo usar la parte visible
    final parts = nota.split('|||');
    return parts.first.trim().isNotEmpty ? parts.first.trim() : 'Cliente';
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Completar tarea'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nota de completado (opcional):'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ej: Fotos editadas y entregadas',
              border: OutlineInputBorder(),
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
