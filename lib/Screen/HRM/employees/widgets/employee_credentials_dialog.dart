import 'dart:math';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../model/employee_model.dart';
import '../services/employee_credentials_service.dart';

/// Diálogo para crear las credenciales de acceso de un empleado.
/// Pide email + contraseña + confirmación + rol (empleado o encargado).
class EmployeeCredentialsDialog extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeCredentialsDialog({super.key, required this.employee});

  @override
  State<EmployeeCredentialsDialog> createState() =>
      _EmployeeCredentialsDialogState();
}

class _EmployeeCredentialsDialogState extends State<EmployeeCredentialsDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isDepartmentHead = false;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.employee.email);
    final suggested = _generatePassword();
    _passwordCtrl = TextEditingController(text: suggested);
    _confirmCtrl = TextEditingController(text: suggested);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(10, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  String? _readBranchId() {
    try {
      return html.window.localStorage['selected_tenant_id'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final branchId = _readBranchId();
    if (branchId == null || branchId.isEmpty) {
      EasyLoading.showError('No se pudo determinar la sucursal actual');
      return;
    }

    setState(() => _saving = true);
    EasyLoading.show(status: 'Creando credenciales...');

    final result = await EmployeeCredentialsService().createCredentials(
      employee: widget.employee,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      isDepartmentHead: _isDepartmentHead,
      branchId: branchId,
    );

    EasyLoading.dismiss();

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.ok) {
      EasyLoading.showSuccess('Credenciales creadas');
      Navigator.of(context).pop(true);
      _showCredentialsReady();
    } else {
      EasyLoading.showError(result.errorMessage ?? 'Error desconocido');
    }
  }

  void _showCredentialsReady() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Credenciales listas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comparte estos datos con el empleado:'),
            const SizedBox(height: 12),
            _credentialsRow('Usuario', email),
            const SizedBox(height: 8),
            _credentialsRow('Contraseña', password),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Guárdala: no se mostrará de nuevo.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Usuario: $email\nContraseña: $password'));
              EasyLoading.showToast('Copiado');
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  Widget _credentialsRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.vpn_key, color: Colors.indigo),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Acceso para ${widget.employee.fullName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email / Usuario',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Generar nueva',
                          onPressed: () {
                            final pw = _generatePassword();
                            setState(() {
                              _passwordCtrl.text = pw;
                              _confirmCtrl.text = pw;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ],
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 4) return 'Mínimo 4 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'No coincide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Es Encargado del departamento'),
                    subtitle: Text(
                      _isDepartmentHead
                          ? 'Podrá ver y asignar tareas a su equipo'
                          : 'Solo verá sus tareas asignadas',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isDepartmentHead,
                    onChanged: (v) => setState(() => _isDepartmentHead = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Crear credenciales'),
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
