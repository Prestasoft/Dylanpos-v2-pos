import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';
import 'package:salespro_admin/commas.dart';

/// Provider de empleados
final employeesProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  return EmployeeRepository().getAllEmployees();
});

/// Dashboard de HRM con estadísticas generales
class HRMDashboardScreen extends ConsumerWidget {
  const HRMDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: kAppSurfaceBg,
      body: employeesAsync.when(
        data: (employees) => _buildDashboard(context, employees),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(employeesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<EmployeeModel> employees) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1240;

    // Calcular estadísticas
    final stats = _calculateStatistics(employees);

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
                    'RECURSOS HUMANOS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kMainColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Panel General de Empleados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/hrm/employee-list'),
                icon: const Icon(Icons.list),
                label: const Text('Ver Lista Completa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards de estadísticas principales
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.people,
                title: 'Total Empleados',
                value: employees.length.toString(),
                color: Colors.blue,
                width: isDesktop ? 280 : null,
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                title: 'Activos',
                value: stats['activeCount'].toString(),
                color: Colors.green,
                width: isDesktop ? 280 : null,
              ),
              _buildStatCard(
                icon: Icons.cancel,
                title: 'Inactivos',
                value: stats['inactiveCount'].toString(),
                color: Colors.grey,
                width: isDesktop ? 280 : null,
              ),
              _buildStatCard(
                icon: Icons.attach_money,
                title: 'Nómina Mensual',
                value: myFormat.format(stats['totalSalary']),
                color: Colors.purple,
                width: isDesktop ? 280 : null,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Distribución por Departamento
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
                  children: [
                    const Icon(Icons.bar_chart, color: kMainColor),
                    const SizedBox(width: 12),
                    const Text(
                      'DISTRIBUCIÓN POR DEPARTAMENTO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kMainColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDepartmentDistribution(stats['departmentDistribution']),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Estadísticas adicionales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas generales
              Expanded(
                child: Container(
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
                        children: [
                          const Icon(Icons.analytics, color: kMainColor),
                          const SizedBox(width: 12),
                          const Text(
                            'ESTADÍSTICAS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kMainColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildStatRow('Antigüedad promedio', '${stats['avgYearsOfService'].toStringAsFixed(1)} años'),
                      const Divider(height: 24),
                      _buildStatRow('Salario promedio', myFormat.format(stats['avgSalary'])),
                      const Divider(height: 24),
                      _buildStatRow('Días de vacaciones pendientes', '${stats['totalVacationDays']} días'),
                      const Divider(height: 24),
                      _buildStatRow('Empleados con más de 5 años', stats['employeesOver5Years'].toString()),
                    ],
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                // Tipos de contrato
                Expanded(
                  child: Container(
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
                          children: [
                            const Icon(Icons.assignment, color: kMainColor),
                            const SizedBox(width: 12),
                            const Text(
                              'TIPOS DE CONTRATO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kMainColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildContractTypeDistribution(stats['contractDistribution']),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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

  Widget _buildDepartmentDistribution(Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        final percentage = (entry.value / total * 100).toStringAsFixed(0);
        final progress = entry.value / total;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${entry.value} ($percentage%)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(kMainColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContractTypeDistribution(Map<String, int> distribution) {
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getContractColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Text(
                entry.value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getContractColor(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'indefinido':
        return Colors.green;
      case 'temporal':
        return Colors.orange;
      case 'por obra':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _calculateStatistics(List<EmployeeModel> employees) {
    final activeEmployees = employees.where((e) => e.status.toLowerCase() == 'activo').toList();
    final inactiveEmployees = employees.where((e) => e.status.toLowerCase() != 'activo').toList();

    // Distribución por departamento
    final departmentDistribution = <String, int>{};
    for (var employee in employees) {
      final dept = employee.department;
      departmentDistribution[dept] = (departmentDistribution[dept] ?? 0) + 1;
    }

    // Distribución por tipo de contrato
    final contractDistribution = <String, int>{};
    for (var employee in employees) {
      final contract = employee.contractType;
      contractDistribution[contract] = (contractDistribution[contract] ?? 0) + 1;
    }

    // Salarios
    final totalSalary = employees.fold<double>(0.0, (sum, e) => sum + e.salary);
    final avgSalary = employees.isNotEmpty ? totalSalary / employees.length : 0.0;

    // Antigüedad
    final totalYears = employees.fold<int>(0, (sum, e) => sum + e.yearsOfService);
    final avgYearsOfService = employees.isNotEmpty ? totalYears / employees.length : 0.0;

    // Vacaciones
    final totalVacationDays = employees.fold<int>(0, (sum, e) => sum + e.vacationDaysAvailable);

    // Empleados con más de 5 años
    final employeesOver5Years = employees.where((e) => e.yearsOfService >= 5).length;

    return {
      'activeCount': activeEmployees.length,
      'inactiveCount': inactiveEmployees.length,
      'totalSalary': totalSalary,
      'avgSalary': avgSalary,
      'avgYearsOfService': avgYearsOfService,
      'totalVacationDays': totalVacationDays,
      'employeesOver5Years': employeesOver5Years,
      'departmentDistribution': departmentDistribution,
      'contractDistribution': contractDistribution,
    };
  }
}
