import 'package:flutter/material.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';
import 'package:salespro_admin/commas.dart';

import 'package:salespro_admin/Screen/HRM/employees/widgets/salary_increase_dialog.dart';

/// Pestaña de Salario y Beneficios del Empleado
class EmployeeSalaryTab extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeSalaryTab({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeSalaryTab> createState() => _EmployeeSalaryTabState();
}

class _EmployeeSalaryTabState extends State<EmployeeSalaryTab> {
  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    // Calcular deducciones aproximadas (esto debería venir de la nómina real)
    final afpDeduction = employee.salary * 0.0287; // 2.87% AFP empleado
    final sfsDeduction = employee.salary * 0.0304; // 3.04% SFS empleado
    final totalDeductions = afpDeduction + sfsDeduction;
    final netSalary = employee.salary - totalDeductions;
    final annualSalary = employee.salary * 12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección: Salario Bruto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('SALARIO BRUTO'),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => SalaryIncreaseDialog(employee: widget.employee),
                  );
                  if (result != null && result is Map) {
                    setState(() {
                      widget.employee.salary = result['salary'];
                      widget.employee.notes = result['notes'];
                    });
                  }
                },
                icon: const Icon(Icons.trending_up, size: 18),
                label: const Text('Modificar Sueldo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade800,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: Colors.green.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.attach_money, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  myFormat.format(employee.salary),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  employee.salaryType,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.green.shade300),
                const SizedBox(height: 16),
                _buildSalaryRow('Salario anual', myFormat.format(annualSalary)),
                const SizedBox(height: 8),
                _buildSalaryRow('Salario neto (aprox.)', myFormat.format(netSalary)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección: Método de Pago
          _buildSectionTitle('MÉTODO DE PAGO'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.payment,
                  label: 'Forma de pago',
                  value: employee.paymentMethod,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.calendar_today,
                  label: 'Frecuencia',
                  value: employee.salaryType,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección: Datos Bancarios
          if (employee.paymentMethod.toLowerCase().contains('transferencia')) ...[
            _buildSectionTitle('DATOS BANCARIOS'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  _buildBankInfoRow(
                    Icons.account_balance,
                    'Banco',
                    employee.bankName ?? 'No especificado',
                  ),
                  const SizedBox(height: 12),
                  _buildBankInfoRow(
                    Icons.credit_card,
                    'Número de cuenta',
                    employee.bankAccountNumber ?? 'No especificado',
                  ),
                  const SizedBox(height: 12),
                  _buildBankInfoRow(
                    Icons.account_balance_wallet,
                    'Tipo de cuenta',
                    employee.bankAccountType ?? 'No especificado',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Sección: Seguridad Social
          _buildSectionTitle('SEGURIDAD SOCIAL'),
          const SizedBox(height: 16),

          // AFP
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.savings, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'AFP (Administradora de Fondos de Pensiones)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSSRow('Proveedor', employee.afpProvider),
                const SizedBox(height: 8),
                _buildSSRow('Número de afiliado', employee.afpNumber ?? 'No registrado'),
                const SizedBox(height: 8),
                _buildSSRow('Aporte mensual (aprox.)', '${myFormat.format(afpDeduction)} (2.87%)'),
              ],
            ),
          ),

          // ARS/SFS
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_hospital, color: Colors.teal.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'ARS/SFS (Seguro Familiar de Salud)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSSRow('Proveedor', employee.sfsProvider),
                const SizedBox(height: 8),
                _buildSSRow('Número de afiliado', employee.sfsNumber ?? 'No registrado'),
                const SizedBox(height: 8),
                _buildSSRow('Aporte mensual (aprox.)', '${myFormat.format(sfsDeduction)} (3.04%)'),
              ],
            ),
          ),

          // NSS
          if (employee.nss != null && employee.nss!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge, color: Colors.indigo.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'NSS:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(employee.nss!),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Sección: Resumen de Deducciones
          _buildSectionTitle('RESUMEN DE DEDUCCIONES'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildDeductionRow('Salario bruto', employee.salary, isBold: true),
                const Divider(height: 24),
                _buildDeductionRow('AFP (2.87%)', -afpDeduction),
                const SizedBox(height: 8),
                _buildDeductionRow('SFS (3.04%)', -sfsDeduction),
                const Divider(height: 24),
                _buildDeductionRow('Total deducciones', -totalDeductions, color: Colors.red),
                const SizedBox(height: 8),
                _buildDeductionRow('Salario neto (aprox.)', netSalary,
                  isBold: true, color: Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nota: Las deducciones mostradas son aproximadas. Consulte la nómina oficial para valores exactos.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
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

  Widget _buildSalaryRow(String label, String value) {
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
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

  Widget _buildSSRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          myFormat.format(amount.abs()),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (amount < 0 ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }
}
