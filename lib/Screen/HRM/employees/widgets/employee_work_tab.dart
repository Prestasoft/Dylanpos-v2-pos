import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';

/// Pestaña de Información Laboral del Empleado
class EmployeeWorkTab extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeWorkTab({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección: Cargo y Departamento
          _buildSectionTitle('CARGO Y DEPARTAMENTO'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHighlightCard(
                  icon: Icons.work_outline,
                  title: 'Cargo',
                  value: employee.designation,
                  color: kMainColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHighlightCard(
                  icon: Icons.business_center,
                  title: 'Departamento',
                  value: employee.department,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección: Tipo de Empleo
          _buildSectionTitle('TIPO DE EMPLEO'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _InfoItem('Tipo de empleo', employee.employmentType),
            _InfoItem('Tipo de contrato', employee.contractType),
            _InfoItem('Estado', employee.status),
          ]),
          const SizedBox(height: 24),

          // Sección: Fechas Importantes
          _buildSectionTitle('FECHAS IMPORTANTES'),
          const SizedBox(height: 16),
          _buildTimelineCard(),
          const SizedBox(height: 24),

          // Sección: Antigüedad
          _buildSectionTitle('ANTIGÜEDAD'),
          const SizedBox(height: 16),
          _buildAntiquityCard(),

          // Si está inactivo, mostrar razón de terminación
          if (employee.status.toLowerCase() != 'activo') ...[
            const SizedBox(height: 24),
            _buildSectionTitle('INFORMACIÓN DE TERMINACIÓN'),
            const SizedBox(height: 16),
            _buildTerminationCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: kMainColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
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
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        return SizedBox(
          width: 300,
          child: _buildInfoCard(item.label, item.value),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimelineItem(
            icon: Icons.login,
            title: 'Fecha de ingreso',
            date: employee.joiningDate,
            color: Colors.green,
          ),
          if (employee.contractEndDate != null) ...[
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.event,
              title: 'Fin de contrato',
              date: employee.contractEndDate!,
              color: Colors.orange,
            ),
          ],
          if (employee.terminationDate != null) ...[
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.logout,
              title: 'Fecha de terminación',
              date: employee.terminationDate!,
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required DateTime date,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAntiquityCard() {
    final years = employee.yearsOfService;
    final months = employee.monthsOfService % 12;
    final totalDays = employee.monthsOfService * 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.timeline, size: 48, color: Colors.purple),
          const SizedBox(height: 16),
          Text(
            '$years ${years == 1 ? 'año' : 'años'} y $months ${months == 1 ? 'mes' : 'meses'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Aproximadamente $totalDays días de servicio',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Empleado ${employee.status}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (employee.terminationDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Fecha de terminación: ${DateFormat('dd/MM/yyyy').format(employee.terminationDate!)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
          if (employee.terminationReason != null &&
              employee.terminationReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Razón: ${employee.terminationReason}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
