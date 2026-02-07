import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/services/api_service.dart';

/// Provider para obtener resumen mensual
final monthlyReportProvider = FutureProvider.family<Map<String, dynamic>?, Map<String, int>>((ref, params) async {
  final apiService = ApiService();
  try {
    final response = await apiService.get('rentability/monthly-summary', queryParams: {
      'year': params['year'].toString(),
      'month': params['month'].toString(),
    });

    if (response.success && response.data != null) {
      return response.data['summary'];
    }
    return null;
  } catch (e) {
    debugPrint('Error obteniendo reporte mensual: $e');
    return null;
  }
});

/// Widget de tarjeta de reporte mensual
class MonthlyReportCard extends ConsumerWidget {
  final int year;
  final int month;

  const MonthlyReportCard({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(monthlyReportProvider({'year': year, 'month': month}));

    return Container(
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
                  const Icon(Icons.calendar_month, color: kMainColor),
                  const SizedBox(width: 12),
                  Text(
                    'REPORTE MENSUAL - ${DateFormat.MMMM('es').format(DateTime(year, month))} $year',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadReport(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Descargar PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          reportAsync.when(
            data: (summary) {
              if (summary == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay datos para este mes'),
                  ),
                );
              }

              return Column(
                children: [
                  // Métricas principales
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          'Total Empleados',
                          summary['total_employees'].toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetric(
                          'Reservas Totales',
                          summary['total_reservations'].toString(),
                          Icons.event,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetric(
                          'Facturadas',
                          summary['invoiced_reservations'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetric(
                          'Pendientes',
                          summary['pending_reservations'].toString(),
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          'Ingresos Totales',
                          myFormat.format(summary['total_revenue']),
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetric(
                          'Comisiones Estimadas',
                          myFormat.format(summary['estimated_commissions']),
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Top 5 performers
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TOP 5 EMPLEADOS DEL MES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    (summary['top_5_performers'] as List).length,
                    (index) {
                      final performer = (summary['top_5_performers'] as List)[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _getRankColor(index),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                performer['employee_name'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              myFormat.format(performer['revenue']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Error cargando reporte: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blue;
    }
  }

  void _downloadReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Generando reporte PDF...'),
        backgroundColor: Colors.blue,
      ),
    );

    // TODO: Implementar generación y descarga de PDF del reporte mensual
  }
}
