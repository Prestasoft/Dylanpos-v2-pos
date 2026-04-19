import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/model/reservation_model.dart';

import 'models/employee_performance_model.dart';
import 'providers/rentability_provider.dart';

/// Pantalla de Reservas Pendientes de Facturar
class PendingInvoicesScreen extends ConsumerStatefulWidget {
  const PendingInvoicesScreen({super.key});

  @override
  ConsumerState<PendingInvoicesScreen> createState() => _PendingInvoicesScreenState();
}

class _PendingInvoicesScreenState extends ConsumerState<PendingInvoicesScreen> {
  String _selectedEmployeeFilter = 'all';
  String _selectedUrgencyFilter = 'all';

  @override
  Widget build(BuildContext context) {
    // Cargar datos reales del provider
    final pendingAsync = ref.watch(pendingInvoicesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kMainColor,
        foregroundColor: Colors.white,
        title: const Text('Reservas Pendientes de Facturar'),
        elevation: 0,
      ),
      body: pendingAsync.when(
        data: (pendingData) {
          // Convertir de Map<String, dynamic> a PendingReservation
          final allPending = pendingData.map((data) {
            final reservation = data['reservation'] as Map<String, dynamic>;
            final employeeName = data['employee_name']?.toString() ?? '';
            return PendingReservation(
              reservationId: reservation['reservation_id'] ?? '',
              customerName: reservation['customer_name'] ?? '',
              customerPhone: reservation['customer_phone']?.toString() ?? '',
              employeeName: employeeName,
              reservationDate: DateTime.parse(reservation['reservation_date']),
              eventDate: DateTime.parse(reservation['event_date']),
              estimatedAmount: (reservation['estimated_amount'] as num).toDouble(),
              daysWithoutInvoice: (reservation['days_without_invoice'] as num).toInt(),
              serviceName: reservation['service_name']?.toString() ?? '',
              place: reservation['place']?.toString() ?? '',
              reservationTime: reservation['reservation_time']?.toString() ?? '',
              dressIds: reservation['dress_ids'],
              estado: reservation['estado']?.toString() ?? 'pendiente',
              nota: reservation['nota']?.toString() ?? '',
            );
          }).toList();

          final filtered = _applyFilters(allPending);
          final stats = _calculateStats(filtered);

          return _buildContent(context, filtered, stats, allPending);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Error cargando reservas pendientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<PendingReservation> filtered, Map<String, dynamic> stats, List<PendingReservation> allPending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Cards de resumen
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Pendientes',
                    filtered.length.toString(),
                    Colors.orange,
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Valor Estimado',
                    myFormat.format(stats['totalEstimated']),
                    Colors.purple,
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Urgentes (>10 dias)',
                    stats['urgent'].toString(),
                    Colors.red,
                    Icons.warning_amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabla de reservas pendientes
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pending_actions, color: Colors.orange),
                          const SizedBox(width: 12),
                          const Text(
                            'LISTADO DE PENDIENTES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kMainColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildEmployeeFilter(allPending),
                          const SizedBox(width: 12),
                          _buildUrgencyFilter(),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _notifyEmployees,
                            icon: const Icon(Icons.notifications, size: 18),
                            label: const Text('Notificar Empleados'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPendingTable(filtered),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(25), color.withAlpha(51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
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

  Widget _buildEmployeeFilter(List<PendingReservation> allPending) {
    // Extraer nombres únicos de empleados
    final uniqueEmployees = <String>{};
    for (var reservation in allPending) {
      if (reservation.employeeName.isNotEmpty) {
        uniqueEmployees.add(reservation.employeeName);
      }
    }

    // Ordenar alfabéticamente
    final sortedEmployees = uniqueEmployees.toList()..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(128)),
      ),
      child: DropdownButton<String>(
        value: _selectedEmployeeFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.person, size: 18),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('Todos los empleados')),
          ...sortedEmployees.map((employee) {
            return DropdownMenuItem(
              value: employee,
              child: Text(employee),
            );
          }),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedEmployeeFilter = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildUrgencyFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(128)),
      ),
      child: DropdownButton<String>(
        value: _selectedUrgencyFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_alt, size: 18),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Todas las urgencias')),
          DropdownMenuItem(value: 'high', child: Text('Urgentes (>10 dias)')),
          DropdownMenuItem(value: 'medium', child: Text('Pronto (5-10 dias)')),
          DropdownMenuItem(value: 'low', child: Text('OK (<5 dias)')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedUrgencyFilter = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildPendingTable(List<PendingReservation> pending) {
    if (pending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.withAlpha(128)),
              const SizedBox(height: 16),
              const Text(
                'No hay reservas pendientes de facturar',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('Reserva', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Servicio', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Fecha Evento', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Dias sin Fact.', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Monto Est.', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Urgencia', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Accion', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: pending.map((reservation) {
          return DataRow(
            color: WidgetStateProperty.all(
              reservation.urgencyLevel == 'high'
                  ? Colors.red.withAlpha(13)
                  : reservation.urgencyLevel == 'medium'
                      ? Colors.orange.withAlpha(13)
                      : null,
            ),
            cells: [
              // Boton "Ver Detalle" en lugar del UUID
              DataCell(
                InkWell(
                  onTap: () => _showReservationDetail(reservation),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kMainColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kMainColor.withAlpha(100)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, size: 16, color: kMainColor),
                        SizedBox(width: 6),
                        Text(
                          'Ver Detalle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kMainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      reservation.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (reservation.customerPhone.isNotEmpty)
                      Text(
                        reservation.customerPhone,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  reservation.serviceName.isNotEmpty ? reservation.serviceName : '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reservation.employeeName.isNotEmpty ? reservation.employeeName : 'N/A',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(reservation.eventDate))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(reservation.urgencyLevel).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.daysWithoutInvoice.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getUrgencyColor(reservation.urgencyLevel),
                    ),
                  ),
                ),
              ),
              DataCell(Text(myFormat.format(reservation.estimatedAmount))),
              DataCell(_buildUrgencyBadge(reservation.urgencyLevel, reservation.daysWithoutInvoice)),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _goToInvoice(reservation.reservationId),
                  icon: const Icon(Icons.receipt, size: 16),
                  label: const Text('Facturar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Muestra dialogo con el detalle completo de la reserva
  void _showReservationDetail(PendingReservation reservation) {
    // Parsear vestidos desde dress_ids
    List<String> dressNames = [];
    if (reservation.dressIds != null && reservation.dressIds is List) {
      for (var item in (reservation.dressIds as List)) {
        if (item is Map) {
          final name = item['dress_name']?.toString() ?? '';
          if (name.isNotEmpty) {
            dressNames.add(name);
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kMainColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_note, color: kMainColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalle de Reserva',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          _buildUrgencyBadge(reservation.urgencyLevel, reservation.daysWithoutInvoice),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Cliente
                _buildDetailRow(Icons.person, 'Cliente', reservation.customerName),
                if (reservation.customerPhone.isNotEmpty)
                  _buildDetailRow(Icons.phone, 'Telefono', reservation.customerPhone),

                const SizedBox(height: 12),

                // Servicio
                if (reservation.serviceName.isNotEmpty)
                  _buildDetailRow(Icons.camera_alt, 'Servicio', reservation.serviceName),

                // Lugar
                if (reservation.place.isNotEmpty)
                  _buildDetailRow(Icons.location_on, 'Lugar', reservation.place),

                const SizedBox(height: 12),

                // Fechas
                _buildDetailRow(
                  Icons.calendar_today,
                  'Fecha del Evento',
                  '${DateFormat('dd/MM/yyyy').format(reservation.eventDate)}${reservation.reservationTime.isNotEmpty ? ' a las ${reservation.reservationTime}' : ''}',
                ),
                _buildDetailRow(
                  Icons.date_range,
                  'Fecha de Reserva',
                  DateFormat('dd/MM/yyyy').format(reservation.reservationDate),
                ),

                const SizedBox(height: 12),

                // Empleado y Monto
                _buildDetailRow(Icons.badge, 'Empleado', reservation.employeeName.isNotEmpty ? reservation.employeeName : 'N/A'),
                _buildDetailRow(Icons.attach_money, 'Monto Estimado', myFormat.format(reservation.estimatedAmount)),

                // Estado
                _buildDetailRow(Icons.info_outline, 'Estado', reservation.estado.toUpperCase()),

                // Nota
                if (ReservationModel.cleanNotaText(reservation.nota).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.notes, 'Nota', ReservationModel.cleanNotaText(reservation.nota)),
                ],

                // Vestidos
                if (dressNames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.checkroom, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Vestidos (${dressNames.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: dressNames.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.withAlpha(80)),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Dias sin facturar
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(reservation.urgencyLevel).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getUrgencyColor(reservation.urgencyLevel).withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, size: 18, color: _getUrgencyColor(reservation.urgencyLevel)),
                      const SizedBox(width: 8),
                      Text(
                        '${reservation.daysWithoutInvoice} dias sin facturar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getUrgencyColor(reservation.urgencyLevel),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botones de accion
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _goToInvoice(reservation.reservationId);
                        },
                        icon: const Icon(Icons.receipt, size: 18),
                        label: const Text('Facturar Ahora'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(String level, int days) {
    Color color = _getUrgencyColor(level);
    IconData icon;
    String label;

    switch (level) {
      case 'high':
        icon = Icons.warning;
        label = 'URGENTE';
        break;
      case 'medium':
        icon = Icons.alarm;
        label = 'PRONTO';
        break;
      default:
        icon = Icons.check;
        label = 'OK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String level) {
    switch (level) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  List<PendingReservation> _applyFilters(List<PendingReservation> pending) {
    var filtered = pending;

    // Aplicar filtro de urgencia
    if (_selectedUrgencyFilter != 'all') {
      filtered = filtered.where((reservation) {
        return reservation.urgencyLevel == _selectedUrgencyFilter;
      }).toList();
    }

    // Aplicar filtro de empleado
    if (_selectedEmployeeFilter != 'all') {
      filtered = filtered.where((reservation) {
        return reservation.employeeName == _selectedEmployeeFilter;
      }).toList();
    }

    return filtered;
  }

  Map<String, dynamic> _calculateStats(List<PendingReservation> pending) {
    double totalEstimated = 0;
    int urgent = 0;

    for (var reservation in pending) {
      totalEstimated += reservation.estimatedAmount;
      if (reservation.urgencyLevel == 'high') urgent++;
    }

    return {
      'totalEstimated': totalEstimated,
      'urgent': urgent,
    };
  }

  void _notifyEmployees() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificaciones enviadas a los empleados'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _goToInvoice(String reservationId) {
    context.go(
      '/sales/inventory-sales',
      extra: {'reservationId': reservationId},
    );
  }

}
