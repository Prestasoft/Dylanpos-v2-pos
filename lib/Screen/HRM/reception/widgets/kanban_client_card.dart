import 'package:flutter/material.dart';
import '../client_tracking_model.dart';

/// Card compacta de cliente para vista Kanban.
/// Muestra: nombre, plan, fecha, mini-indicadores de departamentos.
class KanbanClientCard extends StatelessWidget {
  final ClientTrackingModel client;

  const KanbanClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final groups = client.departmentGroups;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                child: Text(
                  client.customerName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Plan + Fecha
          if (client.serviceName.isNotEmpty)
            Text(
              client.serviceName,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                _formatDate(client.reservationDate),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              if (client.reservationTime.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  client.reservationTime,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          // Mini indicadores de departamentos
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: groups.map((g) {
                final color = _statusColor(g.status);
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Tooltip(
                    message: '${g.label}: ${_statusLabel(g.status)}',
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
                        g.label[0],
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
