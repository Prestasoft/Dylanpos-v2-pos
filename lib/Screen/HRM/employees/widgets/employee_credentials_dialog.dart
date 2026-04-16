import 'dart:math';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../model/employee_model.dart';
import '../services/employee_credentials_service.dart';

/// Diálogo profesional para crear credenciales de acceso de un empleado.
/// Usa nombre de usuario (no email), y asigna automáticamente la sucursal actual.
class EmployeeCredentialsDialog extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeCredentialsDialog({super.key, required this.employee});

  @override
  State<EmployeeCredentialsDialog> createState() =>
      _EmployeeCredentialsDialogState();
}

class _EmployeeCredentialsDialogState extends State<EmployeeCredentialsDialog> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isDepartmentHead = false;
  bool _obscure = true;
  bool _saving = false;

  String _currentBranchId = '';
  String _currentBranchLabel = '';

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: _suggestUsername());
    final suggested = _generatePassword();
    _passwordCtrl = TextEditingController(text: suggested);
    _confirmCtrl = TextEditingController(text: suggested);
    _loadBranchInfo();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Genera un username sugerido: nombre.apellido en minúsculas sin acentos
  String _suggestUsername() {
    final name = _removeAccents(widget.employee.name.trim().toLowerCase());
    final last = _removeAccents(widget.employee.lastName.trim().toLowerCase());
    final base = last.isNotEmpty ? '$name.$last' : name;
    return base.replaceAll(RegExp(r'[^a-z0-9._]'), '');
  }

  String _removeAccents(String s) {
    const from = 'áéíóúàèìòùâêîôûãõñüÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÑÜ';
    const to = 'aeiouaeiouaeiouaonuAEIOUAEIOUAEIOUAONU';
    var result = s;
    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _loadBranchInfo() {
    try {
      final id = html.window.localStorage['selected_tenant_id'] ?? '';
      _currentBranchId = id;
      _currentBranchLabel = _branchLabel(id);
    } catch (_) {}
  }

  String _branchLabel(String id) {
    switch (id) {
      case 'stg': return 'Santiago';
      case 'sde': return 'Santo Domingo Este';
      case 'sdo': return 'Santo Domingo';
      case 'rom': return 'La Romana';
      default: return id.toUpperCase();
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_currentBranchId.isEmpty) {
      EasyLoading.showError('No se pudo determinar la sucursal actual');
      return;
    }

    setState(() => _saving = true);
    EasyLoading.show(status: 'Creando credenciales...');

    final result = await EmployeeCredentialsService().createCredentials(
      employee: widget.employee,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      isDepartmentHead: _isDepartmentHead,
      branchId: _currentBranchId,
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
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Credenciales listas', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comparte estos datos con el empleado:'),
            const SizedBox(height: 16),
            _credentialTile(Icons.person, 'Usuario', username),
            const SizedBox(height: 8),
            _credentialTile(Icons.lock, 'Contraseña', password),
            const SizedBox(height: 8),
            _credentialTile(Icons.business, 'Sucursal', _currentBranchLabel),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guárdala: la contraseña no se mostrará de nuevo.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar todo'),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Usuario: $username\nContraseña: $password\nSucursal: $_currentBranchLabel',
              ));
              EasyLoading.showToast('Copiado al portapapeles');
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

  Widget _credentialTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vpn_key, color: Colors.indigo, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Crear acceso al sistema',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.normal),
                ),
              ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sucursal (solo lectura, informativa)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Colors.blue, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sucursal', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          Text(
                            _currentBranchLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.lock_outline, color: Colors.grey, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Usuario
                TextFormField(
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    hintText: 'ej: edwin.trinidad',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    helperText: 'Solo letras, números, punto y guión bajo',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Usuario requerido';
                    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                    if (v.contains(' ')) return 'No se permiten espacios';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Contraseña
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
                          icon: const Icon(Icons.refresh, size: 20),
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
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, size: 20),
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
                const SizedBox(height: 14),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Switch encargado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDepartmentHead
                        ? Colors.amber.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.04),
                    border: Border.all(
                      color: _isDepartmentHead
                          ? Colors.amber.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDepartmentHead ? Icons.admin_panel_settings : Icons.person_outline,
                        color: _isDepartmentHead ? Colors.amber[800] : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Es Encargado del departamento',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isDepartmentHead
                                  ? 'Podrá ver y asignar tareas a su equipo'
                                  : 'Solo verá sus tareas asignadas',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isDepartmentHead,
                        onChanged: (v) => setState(() => _isDepartmentHead = v),
                        activeThumbColor: Colors.amber[800],
                      ),
                    ],
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
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: const Text('Crear credenciales'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
