import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/api_service.dart';

class ChangeUserPasswordDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const ChangeUserPasswordDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ChangeUserPasswordDialog> createState() => _ChangeUserPasswordDialogState();
}

class _ChangeUserPasswordDialogState extends State<ChangeUserPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    EasyLoading.show(status: 'Cambiando contraseña...');

    try {
      final apiService = ApiService();

      // Debug: verificar que el userId no esté vacío
      print('[ChangePassword] userId: ${widget.userId}');
      print('[ChangePassword] userName: ${widget.userName}');
      print('[ChangePassword] isAuthenticated: ${apiService.isAuthenticated}');

      if (widget.userId.isEmpty) {
        EasyLoading.dismiss();
        EasyLoading.showError('Error: ID de usuario vacío');
        return;
      }

      final response = await apiService.put(
        'auth/users/${widget.userId}/reset-password',
        {'newPassword': _passwordController.text},
      );

      print('[ChangePassword] Response success: ${response.success}');
      print('[ChangePassword] Response message: ${response.message}');
      print('[ChangePassword] Response error: ${response.error}');

      EasyLoading.dismiss();

      if (response.success) {
        EasyLoading.showSuccess('Contraseña actualizada');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        EasyLoading.showError(response.message ?? response.error ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      print('[ChangePassword] Exception: $e');
      EasyLoading.dismiss();
      EasyLoading.showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_reset, color: Colors.orange[700]),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cambiar Contraseña',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info del usuario
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.userEmail,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nueva contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la nueva contraseña';
                  }
                  if (value.length < 4) {
                    return 'Mínimo 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Advertencia
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El usuario deberá iniciar sesión nuevamente con la nueva contraseña.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _changePassword,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
