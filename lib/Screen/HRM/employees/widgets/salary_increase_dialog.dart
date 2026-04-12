import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';

class SalaryIncreaseDialog extends StatefulWidget {
  final EmployeeModel employee;

  const SalaryIncreaseDialog({
    super.key,
    required this.employee,
  });

  @override
  State<SalaryIncreaseDialog> createState() => _SalaryIncreaseDialogState();
}

class _SalaryIncreaseDialogState extends State<SalaryIncreaseDialog> {
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final EmployeeRepository _repo = EmployeeRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _salaryController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newSalaryText = _salaryController.text.replaceAll(',', '');
    final newSalary = double.tryParse(newSalaryText) ?? 0.0;

    if (newSalary <= widget.employee.salary) {
      EasyLoading.showError('El nuevo salario debe ser mayor al actual');
      return;
    }

    setState(() => _isLoading = true);
    EasyLoading.show(status: 'Guardando...', dismissOnTap: false);

    final reason = _reasonController.text.trim();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Preparar el nuevo historial inyectado en notas
    String currentNotes = widget.employee.notes ?? '';
    if (currentNotes.isNotEmpty && !currentNotes.endsWith('\n')) {
      currentNotes += '\n';
    }
    
    final noteString = '[Aumento] $todayStr: Sueldo aumentado de ${myFormat.format(widget.employee.salary)} a ${myFormat.format(newSalary)} - Motivo: ${reason.isNotEmpty ? reason : "Revisión salarial"}';
    final newNotes = currentNotes + noteString;

    try {
      final success = await _repo.updateEmployeePartial(
        id: widget.employee.id,
        data: {
          'salary': newSalary,
          'notes': newNotes,
        },
      );

      if (success) {
        EasyLoading.showSuccess('Sueldo aumentado exitosamente');
        if (mounted) {
          // Send back the updated notes and salary to manually update UI if needed
          Navigator.pop(context, {'salary': newSalary, 'notes': newNotes});
        }
      } else {
        EasyLoading.showError('Error al guardar incremento');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      EasyLoading.showError('Error de red: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.trending_up, color: Colors.green),
          SizedBox(width: 8),
          Text('Aumentar Sueldo', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empleado: ${widget.employee.fullName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Salario Actual:'),
                    Text(
                      myFormat.format(widget.employee.salary),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Nuevo Salario Bruto (\$)',
                  hintText: 'Ej: 50000.00',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                  filled: true,
                  fillColor: Colors.green.shade50,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nuevo salario';
                  }
                  final cleanStr = value.replaceAll(',', '');
                  final parsed = double.tryParse(cleanStr);
                  if (parsed == null || parsed <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  if (parsed <= widget.employee.salary) {
                    return 'Debe ser mayor al salario actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo del Aumento (Opcional)',
                  hintText: 'Ej: Evaluación de desempeño, Ascenso...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: const Text('Confirmar Aumento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
