import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';

import 'models/commission_config_model.dart';
import 'models/employee_performance_model.dart';
import 'providers/rentability_provider.dart';
import 'providers/urgent_reservations_notification_provider.dart';
import 'services/commission_export_service.dart';
import 'services/commission_notification_service.dart';
import 'widgets/commission_trends_chart.dart';

/// Dashboard Principal de Rentabilidad
class RentabilityDashboardScreen extends ConsumerStatefulWidget {
  const RentabilityDashboardScreen({super.key});

  @override
  ConsumerState<RentabilityDashboardScreen> createState() => _RentabilityDashboardScreenState();
}

class _RentabilityDashboardScreenState extends ConsumerState<RentabilityDashboardScreen> {
  // Ya no necesitamos state local porque usamos el provider
  // DateTime _selectedPeriodStart, _selectedPeriodEnd, String _selectedFilter se eliminan

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1240;

    // Cargar datos reales de empleados (usa periodProvider internamente)
    final performancesAsync = ref.watch(employeesPerformanceProvider2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: performancesAsync.when(
        data: (performances) => _buildDashboardContent(context, performances, isDesktop),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error cargando datos de rentabilidad',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildDashboardContent(BuildContext context, List<EmployeePerformance> performances, bool isDesktop) {
    final stats = _calculateDashboardStats(performances);
    final periodState = ref.watch(periodProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RENTABILIDAD',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kMainColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comisiones y Desempeño de Empleados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Filtro de período
                    _buildPeriodFilter(),
                    const SizedBox(width: 12),
                    // Botones de exportación
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.download),
                      tooltip: 'Exportar Reporte',
                      onSelected: (value) {
                        if (value == 'pdf') {
                          _exportToPDF(performances);
                        } else if (value == 'excel') {
                          _exportToExcel(performances);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Exportar a PDF'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Exportar a Excel'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Botón Configurar Comisiones
                    ElevatedButton.icon(
                      onPressed: () => context.go('/hrm/rentability/settings'),
                      icon: const Icon(Icons.settings),
                      label: const Text('Configurar Comisiones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cards de resumen
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  icon: Icons.attach_money,
                  title: 'Facturado Este Mes',
                  value: myFormat.format(stats['totalRevenue']),
                  color: Colors.green,
                  width: isDesktop ? 280 : null,
                ),
                _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'Comisiones Generadas',
                  value: myFormat.format(stats['totalCommissions']),
                  color: Colors.purple,
                  width: isDesktop ? 280 : null,
                ),
                _buildStatCard(
                  icon: Icons.pending_actions,
                  title: 'Reservas Pendientes',
                  value: stats['pendingReservations'].toString(),
                  color: Colors.orange,
                  width: isDesktop ? 280 : null,
                ),
                _buildStatCard(
                  icon: Icons.people,
                  title: 'Empleados Activos',
                  value: performances.length.toString(),
                  color: Colors.blue,
                  width: isDesktop ? 280 : null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Alertas de Reservas Urgentes
            _buildUrgentReservationsAlert(),
            const SizedBox(height: 24),

            // Gráficas de Tendencias
            if (isDesktop) ...[
              Row(
                children: [
                  Expanded(
                    child: CommissionTrendsChart(
                      performances: performances,
                      title: 'Top 10 - Comisiones',
                      primaryColor: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RevenueTrendChart(
                      performances: performances,
                      title: 'Top 10 - Ingresos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else ...[
              CommissionTrendsChart(
                performances: performances,
                title: 'Top 10 - Comisiones',
                primaryColor: Colors.purple,
              ),
              const SizedBox(height: 16),
              RevenueTrendChart(
                performances: performances,
                title: 'Top 10 - Ingresos',
              ),
              const SizedBox(height: 24),
            ],

            // Ranking de Empleados
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
                          const Icon(Icons.emoji_events, color: kMainColor),
                          const SizedBox(width: 12),
                          const Text(
                            'RANKING DE EMPLEADOS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kMainColor,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/hrm/rentability/pending-invoices'),
                        icon: const Icon(Icons.warning, size: 18),
                        label: Text('Ver Pendientes (${stats['pendingReservations']})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildRankingTable(performances, isDesktop),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildPeriodFilter() {
    final periodState = ref.watch(periodProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(128)),
      ),
      child: DropdownButton<String>(
        value: periodState.filter,
        underline: const SizedBox(),
        icon: const Icon(Icons.calendar_month, size: 18),
        items: const [
          DropdownMenuItem(value: 'month', child: Text('Este Mes')),
          DropdownMenuItem(value: 'quarter', child: Text('Último Trimestre')),
          DropdownMenuItem(value: 'year', child: Text('Año Actual')),
          DropdownMenuItem(value: 'custom', child: Text('Personalizado')),
        ],
        onChanged: (value) {
          if (value != null) {
            // Actualizar el período usando el provider
            ref.read(periodProvider.notifier).setFilter(value);
          }
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(25), color.withAlpha(51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTable(List<EmployeePerformance> performances, bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Total Reservas', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Facturadas', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Pendientes', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Monto Total', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Comisión %', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Comisión \$', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: performances.asMap().entries.map((entry) {
          final index = entry.key;
          final perf = entry.value;
          return DataRow(
            cells: [
              // Ranking con medallas
              DataCell(_buildRankingBadge(index + 1)),
              // Empleado con foto
              DataCell(_buildEmployeeCell(perf)),
              // Total Reservas
              DataCell(Text(perf.totalReservations.toString())),
              // Facturadas
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    perf.invoicedReservations.toString(),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Pendientes
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    perf.pendingReservations.toString(),
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Monto Total
              DataCell(Text(
                myFormat.format(perf.totalRevenue),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              // Comisión %
              DataCell(_buildTierBadge(perf.assignedTier)),
              // Comisión $
              DataCell(Text(
                myFormat.format(perf.commissionEarned),
                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
              )),
              // Acciones
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                      onPressed: () => context.go('/hrm/rentability/employee/${perf.employeeId}'),
                      tooltip: 'Ver Detalles',
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_money, size: 20, color: Colors.green),
                      onPressed: () => _markCommissionsAsPaid(perf),
                      tooltip: 'Marcar Pagadas',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankingBadge(int ranking) {
    String emoji = '';
    Color color = Colors.grey;

    if (ranking == 1) {
      emoji = '🥇';
      color = const Color(0xFFFFD700);
    } else if (ranking == 2) {
      emoji = '🥈';
      color = const Color(0xFFC0C0C0);
    } else if (ranking == 3) {
      emoji = '🥉';
      color = const Color(0xFFCD7F32);
    }

    return Row(
      children: [
        if (emoji.isNotEmpty) ...[
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
        ],
        Text(
          '#$ranking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCell(EmployeePerformance perf) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: kMainColor.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kMainColor, width: 1.5),
          ),
          child: perf.photoUrl != null && perf.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    perf.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 18, color: kMainColor),
                  ),
                )
              : const Icon(Icons.person, size: 18, color: kMainColor),
        ),
        const SizedBox(width: 8),
        Text(
          perf.employeeName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTierBadge(CommissionTier? tier) {
    if (tier == null) {
      return const Text('N/A');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(tier.color).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(tier.color).withAlpha(128)),
      ),
      child: Text(
        '${tier.percentage}%',
        style: TextStyle(
          color: Color(tier.color),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _markCommissionsAsPaid(EmployeePerformance perf) async {
    final periodState = ref.watch(periodProvider);

    // Controladores para el formulario
    final TextEditingController paidByController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedPaymentMethod = 'Efectivo';
    DateTime selectedPaidDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Marcar Comisiones Como Pagadas',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del empleado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withAlpha(128)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              perf.employeeName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Período: ${DateFormat('dd/MM/yyyy').format(periodState.startDate)} - ${DateFormat('dd/MM/yyyy').format(periodState.endDate)}'),
                            Text('Total Facturado: ${myFormat.format(perf.totalRevenue)}'),
                            Text('Comisión (${perf.commissionPercentage}%): ${myFormat.format(perf.commissionEarned)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fecha de pago
                      ListTile(
                        title: const Text('Fecha de Pago'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedPaidDate)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedPaidDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                selectedPaidDate = date;
                              });
                            }
                          },
                        ),
                      ),

                      // Método de pago
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Efectivo', 'Transferencia', 'Cheque', 'Depósito']
                            .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedPaymentMethod = value;
                            });
                          }
                        },
                      ),

                      // Pagado por
                      const SizedBox(height: 16),
                      TextField(
                        controller: paidByController,
                        decoration: const InputDecoration(
                          labelText: 'Pagado por (Nombre)',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: Gerente Financiero',
                        ),
                      ),

                      // Notas
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas (Opcional)',
                          border: OutlineInputBorder(),
                          hintText: 'Detalles adicionales del pago...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // Guardar el pago de comisiones
      try {
        final repo = ref.read(rentabilityRepositoryProvider);
        final success = await repo.markCommissionsAsPaid(
          employeeId: perf.employeeId,
          periodStart: periodState.startDate,
          periodEnd: periodState.endDate,
          paidDate: selectedPaidDate,
          commissionAmount: perf.commissionEarned,
          commissionPercentage: perf.commissionPercentage,
          totalRevenue: perf.totalRevenue,
          paidBy: paidByController.text.isEmpty ? 'Admin' : paidByController.text,
          paymentMethod: selectedPaymentMethod,
          notes: notesController.text,
        );

        if (success && mounted) {
          // Preguntar si desea notificar al empleado
          final shouldNotify = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Notificar Empleado'),
                ],
              ),
              content: Text('¿Deseas enviar una notificación por WhatsApp a ${perf.employeeName}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No, gracias'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.send),
                  label: const Text('Sí, enviar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );

          // Si acepta, enviar notificación
          if (shouldNotify == true && mounted) {
            final notificationService = CommissionNotificationService();
            final contactInfo = await notificationService.getEmployeeContactInfo(perf.employeeId);

            if (contactInfo != null && contactInfo['phone']?.isNotEmpty == true) {
              await notificationService.sendWhatsAppNotification(
                employeeName: perf.employeeName,
                employeePhone: contactInfo['phone'] ?? '',
                commissionAmount: perf.commissionEarned,
                commissionPercentage: perf.commissionPercentage,
                totalRevenue: perf.totalRevenue,
                periodStart: periodState.startDate,
                periodEnd: periodState.endDate,
                paymentMethod: selectedPaymentMethod,
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ No hay teléfono registrado para ${perf.employeeName}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Comisiones de ${perf.employeeName} marcadas como pagadas'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Refrescar datos
          ref.invalidate(employeesPerformanceProvider2);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al marcar comisiones como pagadas'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    paidByController.dispose();
    notesController.dispose();
  }

  Widget _buildUrgentReservationsAlert() {
    final urgentAsync = ref.watch(urgentReservationsProvider);

    return urgentAsync.when(
      data: (urgentReservations) {
        if (urgentReservations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withAlpha(25), Colors.orange.withAlpha(51)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withAlpha(128), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡ALERTA! ${urgentReservations.length} Reservas Urgentes Sin Facturar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/hrm/rentability/pending-invoices'),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Ver Todas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Estas reservas tienen más de 10 días sin facturar y requieren atención inmediata:',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              ...urgentReservations.take(3).map((reservation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${reservation.daysWithoutInvoice} días',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${reservation.customerName} - ${reservation.sellerName}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      myFormat.format(reservation.estimatedAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              )),
              if (urgentReservations.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '... y ${urgentReservations.length - 3} más',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Map<String, dynamic> _calculateDashboardStats(List<EmployeePerformance> performances) {
    double totalRevenue = 0;
    double totalCommissions = 0;
    int pendingReservations = 0;

    for (var perf in performances) {
      totalRevenue += perf.totalRevenue;
      totalCommissions += perf.commissionEarned;
      pendingReservations += perf.pendingReservations;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCommissions': totalCommissions,
      'pendingReservations': pendingReservations,
    };
  }

  /// Exportar reporte de comisiones a PDF
  Future<void> _exportToPDF(List<EmployeePerformance> performances) async {
    try {
      final periodState = ref.watch(periodProvider);
      final exportService = CommissionExportService();

      // Obtener nombre de sucursal
      final branchId = html.window.localStorage['selected_tenant_id'] ?? 'stg';
      final branchNames = {
        'stg': 'Victor Guzmán Santiago',
        'sde': 'Victor Guzmán Santo Domingo Este',
        'sdo': 'Victor Guzmán Santo Domingo',
        'rom': 'Victor Guzmán La Romana',
      };
      final branchName = branchNames[branchId] ?? 'Victor Guzmán';

      // Generar PDF
      final pdfData = await exportService.generateCommissionsPDF(
        performances: performances,
        periodStart: periodState.startDate,
        periodEnd: periodState.endDate,
        branchName: branchName,
      );

      // Descargar archivo
      final blob = html.Blob([pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
          'Comisiones_${DateFormat('yyyyMMdd').format(periodState.startDate)}_${DateFormat('yyyyMMdd').format(periodState.endDate)}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte PDF generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generando PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Exportar reporte de comisiones a Excel
  Future<void> _exportToExcel(List<EmployeePerformance> performances) async {
    try {
      final periodState = ref.watch(periodProvider);
      final exportService = CommissionExportService();

      // Obtener nombre de sucursal
      final branchId = html.window.localStorage['selected_tenant_id'] ?? 'stg';
      final branchNames = {
        'stg': 'Victor Guzmán Santiago',
        'sde': 'Victor Guzmán Santo Domingo Este',
        'sdo': 'Victor Guzmán Santo Domingo',
        'rom': 'Victor Guzmán La Romana',
      };
      final branchName = branchNames[branchId] ?? 'Victor Guzmán';

      // Generar Excel
      final excelData = await exportService.generateCommissionsExcel(
        performances: performances,
        periodStart: periodState.startDate,
        periodEnd: periodState.endDate,
        branchName: branchName,
      );

      // Descargar archivo
      final blob = html.Blob([excelData], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
          'Comisiones_${DateFormat('yyyyMMdd').format(periodState.startDate)}_${DateFormat('yyyyMMdd').format(periodState.endDate)}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte Excel generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generando Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
