import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';

/// Pestaña de Contacto del Empleado
class EmployeeContactTab extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeContactTab({
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
          // Sección: Teléfonos
          _buildSectionTitle('TELÉFONOS'),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.phone,
            title: 'Teléfono principal',
            value: employee.phoneNumber,
            color: Colors.green,
            onTap: () => _makeCall(employee.phoneNumber),
            onCopy: () => _copyToClipboard(context, employee.phoneNumber),
          ),
          if (employee.phoneNumber2 != null && employee.phoneNumber2!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.phone_android,
              title: 'Teléfono secundario',
              value: employee.phoneNumber2!,
              color: Colors.blue,
              onTap: () => _makeCall(employee.phoneNumber2!),
              onCopy: () => _copyToClipboard(context, employee.phoneNumber2!),
            ),
          ],
          const SizedBox(height: 24),

          // Sección: Email
          _buildSectionTitle('EMAIL'),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.email,
            title: 'Correo electrónico',
            value: employee.email,
            color: Colors.orange,
            onTap: () => _sendEmail(employee.email),
            onCopy: () => _copyToClipboard(context, employee.email),
          ),
          const SizedBox(height: 24),

          // Sección: Dirección
          _buildSectionTitle('DIRECCIÓN'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Dirección completa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  employee.address,
                  style: const TextStyle(fontSize: 14),
                ),
                if (employee.city != null && employee.city!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ciudad: ${employee.city}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (employee.province != null && employee.province!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Provincia: ${employee.province}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(context, employee.address),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar dirección'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección: Contacto de Emergencia
          if (employee.emergencyContactName != null &&
              employee.emergencyContactName!.isNotEmpty) ...[
            _buildSectionTitle('CONTACTO DE EMERGENCIA'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'CONTACTO DE EMERGENCIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyRow(
                    Icons.person,
                    'Nombre',
                    employee.emergencyContactName!,
                  ),
                  if (employee.emergencyContactPhone != null &&
                      employee.emergencyContactPhone!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEmergencyRow(
                            Icons.phone,
                            'Teléfono',
                            employee.emergencyContactPhone!,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _makeCall(employee.emergencyContactPhone!),
                          icon: const Icon(Icons.call, color: Colors.green),
                          tooltip: 'Llamar',
                        ),
                        IconButton(
                          onPressed: () =>
                              _copyToClipboard(context, employee.emergencyContactPhone!),
                          icon: const Icon(Icons.copy, color: Colors.blue),
                          tooltip: 'Copiar',
                        ),
                      ],
                    ),
                  ],
                  if (employee.emergencyContactRelation != null &&
                      employee.emergencyContactRelation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildEmergencyRow(
                      Icons.family_restroom,
                      'Relación',
                      employee.emergencyContactRelation!,
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    icon == Icons.email ? Icons.send : Icons.call,
                    size: 16,
                  ),
                  label: Text(icon == Icons.email ? 'Enviar email' : 'Llamar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyRow(IconData icon, String label, String value) {
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

  void _makeCall(String phoneNumber) {
    // Copiar al portapapeles (la funcionalidad de llamada requiere url_launcher)
    Clipboard.setData(ClipboardData(text: phoneNumber));
  }

  void _sendEmail(String email) {
    // Copiar al portapapeles (la funcionalidad de email requiere url_launcher)
    Clipboard.setData(ClipboardData(text: email));
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}
