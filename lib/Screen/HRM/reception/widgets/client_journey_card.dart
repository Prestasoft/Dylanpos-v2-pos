import 'package:flutter/material.dart';
import '../client_tracking_model.dart';

/// Card de seguimiento de cliente con vista agrupada por departamento.
///
/// Muestra el recorrido del cliente de forma clara:
///   🟢 Maquillaje    Completado    Dehiri (2/2)
///   🔵 Sesión        Atendiendo    Abel
///   ⚪ Edición       Pendiente     Sin asignar
///   ⚪ Impresión     Pendiente     Sin asignar
class ClientJourneyCard extends StatelessWidget {
  final ClientTrackingModel client;
  final VoidCallback? onAssign;

  const ClientJourneyCard({
    super.key,
    required this.client,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final groups = client.departmentGroups;
    final completedDepts = groups.where((g) => g.isCompleted).length;
    final totalDepts = groups.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: nombre + servicio + fecha
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A84B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    client.customerName.isNotEmpty ? client.customerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (client.serviceName.isNotEmpty)
                        Text(
                          client.serviceName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(client.reservationDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (client.reservationTime.isNotEmpty)
                      Text(
                        client.reservationTime,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Pipeline por departamento
            if (groups.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pendiente de asignación a departamentos',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...groups.map((group) => _buildDepartmentRow(group)),

            // Barra de progreso
            if (groups.isNotEmpty && !client.isUnassigned) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalDepts > 0 ? completedDepts / totalDepts : 0,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          client.isFullyCompleted ? Colors.green : const Color(0xFFD4A84B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedDepts/$totalDepts',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            // Botón asignar (solo si no tiene recepcionista)
            if (onAssign != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Asignar recepcionista', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4A84B),
                    side: const BorderSide(color: Color(0xFFD4A84B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Fila de un departamento con indicador, nombre, estado y empleados
  Widget _buildDepartmentRow(DepartmentGroup group) {
    final color = _statusColor(group.status);
    final icon = _statusIcon(group.status);
    final label = _statusLabel(group.status);
    final employees = group.employeeNames;
    final hasMultiple = group.totalTasks > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Indicador de estado
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            // Nombre del departamento
            SizedBox(
              width: 80,
              child: Text(
                group.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            // Estado
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            // Empleados + conteo
            if (employees.isNotEmpty)
              Text(
                employees.join(', '),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            if (hasMultiple) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${group.completedTasks}/${group.totalTasks}',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  IconData _statusIcon(DepartmentStatus status) {
    switch (status) {
      case DepartmentStatus.completed: return Icons.check_circle;
      case DepartmentStatus.inProgress: return Icons.play_circle;
      case DepartmentStatus.overdue: return Icons.warning_amber;
      case DepartmentStatus.waiting: return Icons.schedule;
      case DepartmentStatus.pending: return Icons.circle_outlined;
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
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }
}
