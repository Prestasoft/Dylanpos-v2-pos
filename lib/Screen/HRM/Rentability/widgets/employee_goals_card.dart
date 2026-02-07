import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';
import '../models/employee_goals_model.dart';
import '../providers/goals_provider.dart';

/// Widget para mostrar y gestionar las metas de un empleado
class EmployeeGoalsCard extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeGoalsCard({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  ConsumerState<EmployeeGoalsCard> createState() => _EmployeeGoalsCardState();
}

class _EmployeeGoalsCardState extends ConsumerState<EmployeeGoalsCard> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(
      employeeGoalsProvider({
        'employee_id': widget.employeeId,
        'year': _selectedYear,
        'month': _selectedMonth,
      }),
    );

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
          // Header con selector de período
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    'Metas del Mes',
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
                  _buildMonthSelector(),
                  const SizedBox(width: 8),
                  _buildYearSelector(),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Crear nueva meta',
                    onPressed: () => _showCreateGoalDialog(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contenido
          goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return _buildEmptyState();
              }

              final goal = goals.first; // Una meta por empleado por mes
              return _buildGoalProgress(goal);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error cargando metas: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(128)),
      ),
      child: DropdownButton<int>(
        value: _selectedMonth,
        underline: const SizedBox(),
        items: List.generate(12, (index) {
          final month = index + 1;
          return DropdownMenuItem(
            value: month,
            child: Text(
              DateFormat.MMMM('es').format(DateTime(2000, month)),
              style: const TextStyle(fontSize: 13),
            ),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedMonth = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(3, (index) => currentYear - 1 + index);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(128)),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        underline: const SizedBox(),
        items: years.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(
              year.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedYear = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay metas definidas para este período',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showCreateGoalDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Meta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress(EmployeeGoal goal) {
    return Column(
      children: [
        // Progreso general
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getProgressColor(goal.overallProgress).withAlpha(25),
                _getProgressColor(goal.overallProgress).withAlpha(51),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getProgressColor(goal.overallProgress).withAlpha(128),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso General',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(goal.overallProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(goal.overallProgress),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.overallProgress,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(
                    _getProgressColor(goal.overallProgress),
                  ),
                ),
              ),
              if (goal.daysRemaining > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Días restantes: ${goal.daysRemaining}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Desglose de metas
        _buildGoalMetric(
          'Ingresos',
          goal.actualRevenue,
          goal.targetRevenue,
          goal.revenueProgress,
          Icons.attach_money,
          Colors.green,
          isCurrency: true,
        ),
        const SizedBox(height: 12),
        _buildGoalMetric(
          'Reservas',
          goal.actualReservations.toDouble(),
          goal.targetReservations.toDouble(),
          goal.reservationsProgress,
          Icons.event,
          Colors.blue,
          isCurrency: false,
        ),
        const SizedBox(height: 12),
        _buildGoalMetric(
          'Comisiones',
          goal.actualCommission,
          goal.targetCommission,
          goal.commissionProgress,
          Icons.star,
          Colors.purple,
          isCurrency: true,
        ),
        const SizedBox(height: 20),

        // Acciones
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _syncGoalProgress(goal.id),
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Actualizar Progreso'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showEditGoalDialog(goal),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar Meta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalMetric(
    String label,
    double actual,
    double target,
    double progress,
    IconData icon,
    Color color, {
    bool isCurrency = false,
  }) {
    final formatter = isCurrency
        ? myFormat
        : NumberFormat('#,##0', 'es');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${formatter.format(actual)} / ${formatter.format(target)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showCreateGoalDialog() async {
    final revenueController = TextEditingController();
    final reservationsController = TextEditingController();
    final commissionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Meta'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: revenueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta de Ingresos (\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reservationsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta de Reservas (#)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commissionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta de Comisiones (\$)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await ref.read(goalsRepositoryProvider).createGoal(
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          year: _selectedYear,
          month: _selectedMonth,
          targetRevenue: double.tryParse(revenueController.text) ?? 0,
          targetReservations: int.tryParse(reservationsController.text) ?? 0,
          targetCommission: double.tryParse(commissionController.text) ?? 0,
        );

        // Refrescar datos
        ref.invalidate(employeeGoalsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meta creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creando meta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditGoalDialog(EmployeeGoal goal) async {
    final revenueController = TextEditingController(text: goal.targetRevenue.toString());
    final reservationsController = TextEditingController(text: goal.targetReservations.toString());
    final commissionController = TextEditingController(text: goal.targetCommission.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Meta'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: revenueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta de Ingresos (\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reservationsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta de Reservas (#)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commissionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta de Comisiones (\$)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await ref.read(goalsRepositoryProvider).updateGoal(
          id: goal.id,
          targetRevenue: double.tryParse(revenueController.text),
          targetReservations: int.tryParse(reservationsController.text),
          targetCommission: double.tryParse(commissionController.text),
        );

        // Refrescar datos
        ref.invalidate(employeeGoalsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meta actualizada exitosamente'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error actualizando meta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _syncGoalProgress(String goalId) async {
    try {
      await ref.read(goalsRepositoryProvider).syncGoalsProgress();

      // Refrescar datos
      ref.invalidate(employeeGoalsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progreso actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando progreso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
