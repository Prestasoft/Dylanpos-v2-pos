import 'package:flutter/material.dart';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.customerName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (client.invoiceNumber != null && client.invoiceNumber!.isNotEmpty && client.invoiceNumber != 'null')
                      Text(
                        'Factura #${client.invoiceNumber}',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Teléfono
          if (client.customerPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 10, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    client.customerPhone,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          // Plan
          if (client.serviceName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 10, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client.serviceName,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          // Fecha + Hora
          Row(
            children: [
              Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                _formatDate(client.reservationDate),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              if (client.reservationTime.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.schedule, size: 10, color: Colors.grey.shade400),
                const SizedBox(width: 2),
                Text(
                  client.reservationTime,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
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
                    child: Tooltip(
                      message: '${dept['label']}: $statusText',
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
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
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
