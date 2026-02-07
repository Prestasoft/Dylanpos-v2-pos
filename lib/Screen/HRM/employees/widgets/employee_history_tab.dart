import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';

/// Pestaña de Historial del Empleado (Timeline)
class EmployeeHistoryTab extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeHistoryTab({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final events = _buildTimelineEvents();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.timeline, color: kMainColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'LÍNEA DE TIEMPO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Historial completo del empleado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Timeline
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay eventos registrados',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isLast = index == events.length - 1;
                return _buildTimelineItem(event, isLast);
              },
            ),
        ],
      ),
    );
  }

  List<_TimelineEvent> _buildTimelineEvents() {
    final events = <_TimelineEvent>[];

    // Evento: Contratación
    events.add(_TimelineEvent(
      icon: Icons.login,
      title: 'Contratación',
      description: 'Ingreso como ${employee.designation}',
      date: employee.joiningDate,
      color: Colors.green,
      details: [
        'Cargo: ${employee.designation}',
        'Departamento: ${employee.department}',
        'Tipo: ${employee.employmentType}',
        'Contrato: ${employee.contractType}',
      ],
    ));

    // Evento: Fin de contrato (si aplica)
    if (employee.contractEndDate != null) {
      events.add(_TimelineEvent(
        icon: Icons.event,
        title: 'Fin de contrato programado',
        description: 'Fecha de finalización del contrato temporal',
        date: employee.contractEndDate!,
        color: Colors.orange,
      ));
    }

    // Evento: Terminación (si aplica)
    if (employee.terminationDate != null) {
      events.add(_TimelineEvent(
        icon: Icons.logout,
        title: 'Terminación de empleo',
        description: employee.terminationReason ?? 'Empleado dado de baja',
        date: employee.terminationDate!,
        color: Colors.red,
        details: employee.terminationReason != null
            ? ['Razón: ${employee.terminationReason}']
            : null,
      ));
    }

    // Ordenar por fecha (más reciente primero)
    events.sort((a, b) => b.date.compareTo(a.date));

    return events;
  }

  Widget _buildTimelineItem(_TimelineEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea vertical y círculo
          Column(
            children: [
              // Círculo con icono
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: event.color.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: event.color, width: 3),
                ),
                child: Icon(
                  event.icon,
                  color: event.color,
                  size: 24,
                ),
              ),
              // Línea vertical (si no es el último)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenido del evento
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha
                  Text(
                    DateFormat('dd MMM yyyy').format(event.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Título
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: event.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Descripción
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  // Detalles adicionales
                  if (event.details != null && event.details!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: event.color.withAlpha(13),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: event.color.withAlpha(51)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: event.details!.map((detail) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_right,
                                  size: 16,
                                  color: event.color,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final IconData icon;
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<String>? details;

  _TimelineEvent({
    required this.icon,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.details,
  });
}
