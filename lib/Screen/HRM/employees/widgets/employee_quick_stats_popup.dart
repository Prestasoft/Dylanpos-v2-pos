import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';
import 'package:salespro_admin/commas.dart';

/// Popup de Estadísticas Rápidas del Empleado
class EmployeeQuickStatsPopup extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback? onViewFullProfile;

  const EmployeeQuickStatsPopup({
    super.key,
    required this.employee,
    this.onViewFullProfile,
  });

  static void show(BuildContext context, EmployeeModel employee, {VoidCallback? onViewFullProfile}) {
    showDialog(
      context: context,
      builder: (context) => EmployeeQuickStatsPopup(
        employee: employee,
        onViewFullProfile: onViewFullProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = employee.yearsOfService;
    final months = employee.monthsOfService % 12;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con foto y nombre
              Row(
                children: [
                  // Foto
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kMainColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kMainColor, width: 2),
                    ),
                    child: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              employee.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 30, color: kMainColor),
                            ),
                          )
                        : const Icon(Icons.person, size: 30, color: kMainColor),
                  ),
                  const SizedBox(width: 12),
                  // Nombre y cargo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee.designation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estado
                  _buildStatusBadge(employee.status),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Sección: Información General
              _buildSectionTitle(Icons.info_outline, 'INFORMACIÓN GENERAL'),
              const SizedBox(height: 12),
              _buildInfoRow('Cargo', employee.designation),
              const SizedBox(height: 8),
              _buildInfoRow('Departamento', employee.department),
              const SizedBox(height: 8),
              _buildInfoRow('Antigüedad', '$years ${years == 1 ? 'año' : 'años'} y $months ${months == 1 ? 'mes' : 'meses'}'),
              const SizedBox(height: 16),

              // Sección: Salario
              _buildSectionTitle(Icons.attach_money, 'SALARIO'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(76)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Mensual', myFormat.format(employee.salary), isBold: true),
                    const SizedBox(height: 8),
                    _buildInfoRow('Anual', myFormat.format(employee.salary * 12)),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Último ingreso',
                      DateFormat('dd/MM/yyyy').format(employee.joiningDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sección: Vacaciones
              _buildSectionTitle(Icons.beach_access, 'VACACIONES'),
              const SizedBox(height: 12),
              _buildInfoRow('Acumulados', '${employee.vacationDaysAccrued} días'),
              const SizedBox(height: 8),
              _buildInfoRow('Tomados', '${employee.vacationDaysTaken} días'),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Disponibles',
                '${employee.vacationDaysAvailable} días',
                isBold: true,
                valueColor: Colors.green,
              ),
              const SizedBox(height: 16),

              // Sección: Otros
              _buildSectionTitle(Icons.assignment, 'OTROS'),
              const SizedBox(height: 12),
              _buildInfoRow('AFP', employee.afpProvider),
              const SizedBox(height: 8),
              _buildInfoRow('ARS', employee.sfsProvider),
              const SizedBox(height: 8),
              _buildInfoRow('Forma de pago', employee.paymentMethod),
              const SizedBox(height: 24),

              // Botón: Ver Perfil Completo
              if (onViewFullProfile != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onViewFullProfile!();
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Ver Perfil Completo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Botón: Cerrar
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inactivo':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case 'suspendido':
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      case 'licencia':
        color = Colors.blue;
        icon = Icons.beach_access;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kMainColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kMainColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
