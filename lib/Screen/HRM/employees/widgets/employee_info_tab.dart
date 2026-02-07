import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_photo_widget.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';

/// Pestaña de Información Personal del Empleado
class EmployeeInfoTab extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeInfoTab({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(employee.birthDate).inDays ~/ 365;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto y datos básicos - Contenedor blanco para evitar fondo negro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto del empleado (soporta URLs y base64)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kMainColor, width: 2),
                  ),
                  child: EmployeePhotoWidget(
                    photoUrl: employee.photoUrl,
                    size: 120,
                    borderRadius: 10,
                    backgroundColor: Colors.grey[100],
                    fallbackIconSize: 60,
                    fallbackIconColor: kMainColor,
                  ),
                ),
                const SizedBox(width: 20),
                // Datos básicos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusBadge(employee.status),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              employee.designation,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${employee.cedula}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Sección: Información Personal
          _buildSectionTitle('INFORMACIÓN PERSONAL'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _InfoItem('Nombre completo', employee.fullName),
            _InfoItem('Cédula', EmployeeModel.formatCedula(employee.cedula)),
            _InfoItem(
              'Fecha de nacimiento',
              '${DateFormat('dd/MM/yyyy').format(employee.birthDate)} ($age años)',
            ),
            _InfoItem('Género', employee.gender),
            _InfoItem('Estado civil', employee.maritalStatus),
            _InfoItem('Dependientes', employee.dependents.toString()),
          ]),
          const SizedBox(height: 24),

          // Sección: Contacto
          _buildSectionTitle('CONTACTO'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _InfoItem('Teléfono principal', employee.phoneNumber),
            if (employee.phoneNumber2 != null && employee.phoneNumber2!.isNotEmpty)
              _InfoItem('Teléfono secundario', employee.phoneNumber2!),
            _InfoItem('Email', employee.email),
            _InfoItem('Dirección', employee.address),
            if (employee.city != null && employee.city!.isNotEmpty)
              _InfoItem('Ciudad', employee.city!),
            if (employee.province != null && employee.province!.isNotEmpty)
              _InfoItem('Provincia', employee.province!),
          ]),
          const SizedBox(height: 24),

          // Sección: Contacto de Emergencia
          if (employee.emergencyContactName != null &&
              employee.emergencyContactName!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('CONTACTO DE EMERGENCIA'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.person_outline,
                        'Nombre',
                        employee.emergencyContactName!,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Teléfono',
                        employee.emergencyContactPhone ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.family_restroom,
                        'Relación',
                        employee.emergencyContactRelation ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Notas
          if (employee.notes != null && employee.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('NOTAS'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                employee.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ],
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
        icon = Icons.medical_services;
        break;
      case 'vacaciones':
        color = Colors.teal;
        icon = Icons.beach_access;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.red.shade700),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
