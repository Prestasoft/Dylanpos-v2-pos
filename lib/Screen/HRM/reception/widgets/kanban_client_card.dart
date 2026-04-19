import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../assignments/widgets/task_theme.dart';
import '../client_tracking_model.dart';

/// Card compacta de cliente para vista Kanban.
/// Muestra: nombre, plan, fecha, mini-indicadores de departamentos.
class KanbanClientCard extends StatelessWidget {
  final ClientTrackingModel client;
  final String? currentColumn;

  const KanbanClientCard({super.key, required this.client, this.currentColumn});

  static final _fixedDepts = [
    {'key': 'maquillaje', 'initial': 'M', 'label': 'Makeup', 'color': const Color(0xFFEC4899)},
    {'key': 'sesion', 'initial': 'F', 'label': 'Fotografía', 'color': const Color(0xFFF59E0B)},
    {'key': 'edicion', 'initial': 'E', 'label': 'Edición', 'color': const Color(0xFF3B82F6)},
    {'key': 'impresion', 'initial': 'I', 'label': 'Impresión', 'color': const Color(0xFFEF4444)},
  ];

  @override
  Widget build(BuildContext context) {
    final groups = client.departmentGroups;
    final tc = TaskColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: tc.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del cliente
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A84B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  client.customerName.isNotEmpty ? client.customerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.customerName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tc.textPrimary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (client.invoiceNumber != null && client.invoiceNumber!.isNotEmpty && client.invoiceNumber != 'null')
                      Text(
                        'Factura #${client.invoiceNumber}',
                        style: TextStyle(fontSize: 9, color: tc.textHint),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Badge Pre-Quince/Fiesta si aplica
          if (client.serviceName.toLowerCase().contains('pre') &&
              (client.serviceName.toLowerCase().contains('quince') || client.serviceName.toLowerCase().contains('boda')))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Text('Pre-Quince y Fiesta', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.blue)),
              ),
            ),
          // Teléfono
          if (client.customerPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 10, color: tc.textHint),
                  const SizedBox(width: 4),
                  Text(client.customerPhone, style: TextStyle(fontSize: 10, color: tc.textSecondary)),
                ],
              ),
            ),
          // Plan
          if (client.serviceName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 10, color: tc.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(client.serviceName, style: TextStyle(fontSize: 10, color: tc.textSecondary), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ],
              ),
            ),
          // Fecha + Hora
          Row(
            children: [
              Icon(Icons.calendar_today, size: 10, color: tc.textHint),
              const SizedBox(width: 4),
              Text(_formatDate(client.reservationDate), style: TextStyle(fontSize: 10, color: tc.textHint)),
              if (client.reservationTime.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.schedule, size: 10, color: tc.textHint),
                const SizedBox(width: 2),
                Text(client.reservationTime, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tc.textSecondary)),
              ],
            ],
          ),
          // Mini indicadores de departamentos
          ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ..._fixedDepts.map((dept) {
                  final group = groups.where((g) => g.key == dept['key']).firstOrNull;
                  final initial = dept['initial'] as String;
                  final deptColor = dept['color'] as Color;
                  final isCompleted = group != null && group.isCompleted;
                  final color = isCompleted ? Colors.green : (group != null && group.tasks.isNotEmpty ? deptColor : Colors.grey);
                  final statusText = group == null || group.tasks.isEmpty
                      ? 'Pendiente'
                      : isCompleted ? 'Completado' : 'En proceso';
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: GestureDetector(
                      onTap: () => _showDeptDetailModal(context, dept, group),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Responsable del departamento actual
                if (_getResponsableName() != null)
                  Text(
                    _getResponsableName()!,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tc.textPrimary),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Obtiene el nombre del responsable del departamento donde está el cliente
  String? _getResponsableName() {
    if (currentColumn == null) return null;
    final groups = client.departmentGroups;
    for (final g in groups) {
      if (g.key == currentColumn && g.employeeNames.isNotEmpty) {
        return g.employeeNames.first;
      }
    }
    return null;
  }

  /// Modal con detalle del departamento para este cliente
  void _showDeptDetailModal(BuildContext context, Map<String, dynamic> dept, DepartmentGroup? group) {
    final deptLabel = dept['label'] as String;
    final deptColor = dept['color'] as Color;
    final tasks = group?.tasks ?? [];
    final isCompleted = group != null && group.isCompleted;
    final hasActive = group != null && group.hasActive;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isCompleted ? Colors.green : deptColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                dept['initial'] as String,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isCompleted ? Colors.green : deptColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deptLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    client.customerName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withValues(alpha: 0.12)
                    : hasActive ? deptColor.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCompleted ? '✅ Completado' : hasActive ? '🔵 En proceso' : '⚪ Pendiente',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.green : hasActive ? deptColor : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Sin actividad en este departamento',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: tasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final task = entry.value;
                    final hasStarted = task.assignedAt != null;
                    final hasCompleted = task.completedAt != null;
                    final hasDue = task.dueAt != null;

                    // Calcular duración y resultado
                    int? durationMin;
                    bool? onTime;
                    if (hasStarted && hasCompleted) {
                      final start = task.assignedAt!;
                      final end = task.completedAt!;
                      durationMin = end.difference(start).inMinutes;
                      if (hasDue) onTime = task.completedAt!.isBefore(task.dueAt!) || task.completedAt!.isAtSameMomentAs(task.dueAt!);
                    }

                    int? slaMin;
                    if (hasStarted && hasDue) {
                      slaMin = task.dueAt!.difference(task.assignedAt!).inMinutes;
                    }

                    final taskColor = hasCompleted
                        ? (onTime == true ? Colors.green : Colors.red)
                        : task.isOverdue ? Colors.orange
                        : task.isActive ? deptColor
                        : Colors.grey;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: taskColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: taskColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: número + empleado + resultado
                          Row(
                            children: [
                              Icon(
                                hasCompleted ? Icons.check_circle : task.isOverdue ? Icons.warning_amber : task.isActive ? Icons.play_circle : Icons.circle_outlined,
                                size: 16,
                                color: taskColor,
                              ),
                              const SizedBox(width: 8),
                              if (tasks.length > 1)
                                Text('${deptLabel} ${idx + 1}  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                              Expanded(
                                child: Text(
                                  task.employeeName ?? 'Sin asignar',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onTime != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (onTime ? Colors.green : Colors.red).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    onTime ? '✅ A tiempo' : '❌ Con atraso',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: onTime ? Colors.green : Colors.red),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Detalle de tiempos
                          _detailRow('SLA asignado', slaMin != null ? '$slaMin min' : '—'),
                          if (hasStarted)
                            _detailRow('Inicio', DateFormat('dd/MM HH:mm').format(task.assignedAt!)),
                          if (hasCompleted)
                            _detailRow('Completado', DateFormat('dd/MM HH:mm').format(task.completedAt!)),
                          if (durationMin != null)
                            _detailRow('Duración real', '$durationMin min'),
                          if (onTime != null && slaMin != null && durationMin != null) ...[
                            const Divider(height: 12),
                            Row(
                              children: [
                                Icon(onTime ? Icons.thumb_up : Icons.thumb_down, size: 14, color: onTime ? Colors.green : Colors.red),
                                const SizedBox(width: 6),
                                Text(
                                  onTime
                                      ? 'Terminó ${slaMin - durationMin} min antes del SLA'
                                      : 'Se pasó ${durationMin - slaMin} min del SLA',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onTime ? Colors.green : Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _getDeptInitial(String key) {
    switch (key) {
      case 'maquillaje': return 'M';
      case 'sesion': return 'F';
      case 'edicion': return 'E';
      case 'impresion': return 'I';
      default: return key.isNotEmpty ? key[0].toUpperCase() : '?';
    }
  }

  Color _getDeptColor(String key) {
    switch (key) {
      case 'maquillaje': return const Color(0xFFEC4899); // Rosa
      case 'sesion': return const Color(0xFFF59E0B); // Amarillo
      case 'edicion': return const Color(0xFF3B82F6); // Azul
      case 'impresion': return const Color(0xFFEF4444); // Rojo
      default: return Colors.grey;
    }
  }

  Color _statusColor(DepartmentStatus status) {
    switch (status) {
      case DepartmentStatus.completed: return Colors.green;
      case DepartmentStatus.inProgress: return const Color(0xFF3B82F6);
      case DepartmentStatus.overdue: return Colors.orange;
      case DepartmentStatus.waiting: return const Color(0xFFF59E0B);
      case DepartmentStatus.pending: return Colors.grey;
    }
  }

  String _statusLabel(DepartmentStatus status) {
    switch (status) {
      case DepartmentStatus.completed: return 'Completado';
      case DepartmentStatus.inProgress: return 'Atendiendo';
      case DepartmentStatus.overdue: return 'Vencida';
      case DepartmentStatus.waiting: return 'Esperando';
      case DepartmentStatus.pending: return 'Pendiente';
    }
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return date;
    }
  }
}
