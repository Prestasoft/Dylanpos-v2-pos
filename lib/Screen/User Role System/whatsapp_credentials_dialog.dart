import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/services/whatsapp_credentials_service.dart';
import '../Widgets/Constant Data/constant.dart';

class WhatsAppCredentialsDialog extends StatefulWidget {
  const WhatsAppCredentialsDialog({Key? key}) : super(key: key);

  @override
  State<WhatsAppCredentialsDialog> createState() => _WhatsAppCredentialsDialogState();
}

class _WhatsAppCredentialsDialogState extends State<WhatsAppCredentialsDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _instanceIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _instanceIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    setState(() => _isLoading = true);

    try {
      final credentials = await WhatsAppCredentialsService.getCredentials();

      setState(() {
        _tokenController.text = credentials.token;
        _instanceIdController.text = credentials.instanceId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      EasyLoading.showError('Error al cargar credenciales: ${e.toString()}');
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      EasyLoading.show(status: 'Guardando credenciales...');

      final success = await WhatsAppCredentialsService.updateCredentials(
        token: _tokenController.text,
        instanceId: _instanceIdController.text,
      );

      if (success) {
        EasyLoading.showSuccess('Credenciales guardadas exitosamente');
        Navigator.of(context).pop();
      } else {
        EasyLoading.showError('Error al guardar credenciales');
      }
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Credenciales'),
        content: const Text(
          '¿Estás seguro de restablecer las credenciales a los valores por defecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        EasyLoading.show(status: 'Restableciendo...');

        final success = await WhatsAppCredentialsService.resetToDefaults();

        if (success) {
          await _loadCredentials();
          EasyLoading.showSuccess('Credenciales restablecidas');
        } else {
          EasyLoading.showError('Error al restablecer');
        }
      } catch (e) {
        EasyLoading.showError('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _testCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Token: ${_tokenController.text}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(
              'Instance ID: ${_instanceIdController.text}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            Text(
              'URL Chat: https://api.ultramsg.com/${_instanceIdController.text}/messages/chat',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'URL Documentos: https://api.ultramsg.com/${_instanceIdController.text}/messages/document',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.api, color: kMainColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Configuración WhatsApp API',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kMainColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configura las credenciales de UltraMsg para el envío de mensajes de WhatsApp',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Obtén estas credenciales desde tu panel de UltraMsg (https://ultramsg.com)',
                              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Token field
                    Text(
                      'Token API',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      decoration: InputDecoration(
                        hintText: 'Ej: 5i36w829nb1ljkj7',
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _obscureToken = !_obscureToken);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El token es requerido';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                          return 'Token inválido (solo letras y números)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Instance ID field
                    Text(
                      'Instance ID',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _instanceIdController,
                      decoration: InputDecoration(
                        hintText: 'Ej: instance127004',
                        prefixIcon: const Icon(Icons.cloud),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El Instance ID es requerido';
                        }
                        if (!RegExp(r'^instance\d+$').hasMatch(value)) {
                          return 'Formato inválido (debe ser: instanceXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Test button
                    OutlinedButton.icon(
                      onPressed: _testCredentials,
                      icon: const Icon(Icons.preview, size: 18),
                      label: const Text('Ver Configuración'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 32),

            // Footer buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restablecer por Defecto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[700]!),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveCredentials,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
