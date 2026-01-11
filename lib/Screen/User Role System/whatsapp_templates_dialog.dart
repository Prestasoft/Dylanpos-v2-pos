import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/services/whatsapp_template_service.dart';
import '../Widgets/Constant Data/constant.dart';

class WhatsAppTemplatesDialog extends StatefulWidget {
  const WhatsAppTemplatesDialog({Key? key}) : super(key: key);

  @override
  State<WhatsAppTemplatesDialog> createState() => _WhatsAppTemplatesDialogState();
}

class _WhatsAppTemplatesDialogState extends State<WhatsAppTemplatesDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _templates = {};
  bool _isLoading = true;
  String _selectedTemplate = 'invoice_caption';

  final List<String> _templateKeys = [
    'invoice_caption',
    'reservation_confirmation',
    'payment_receipt',
    'confirmation_link',
    'daily_report',
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final templates = await WhatsAppTemplateService.getAllTemplates();

      setState(() {
        _templates.addAll(templates);

        // Initialize controllers
        _templateKeys.forEach((key) {
          _controllers[key] = TextEditingController(
            text: _templates[key] ?? '',
          );
        });

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      EasyLoading.showError('Error al cargar plantillas: ${e.toString()}');
    }
  }

  Future<void> _saveTemplates() async {
    try {
      EasyLoading.show(status: 'Guardando plantillas...');

      // Collect all template values from controllers
      final Map<String, String> updatedTemplates = {};
      _controllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          updatedTemplates[key] = controller.text.trim();
        }
      });

      final success = await WhatsAppTemplateService.updateTemplates(updatedTemplates);

      if (success) {
        EasyLoading.showSuccess('Plantillas guardadas exitosamente');
        Navigator.of(context).pop();
      } else {
        EasyLoading.showError('Error al guardar plantillas');
      }
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Plantillas'),
        content: const Text(
          '¿Estás seguro de restablecer todas las plantillas a sus valores por defecto?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        EasyLoading.show(status: 'Restableciendo...');

        final success = await WhatsAppTemplateService.resetToDefaults();

        if (success) {
          await _loadTemplates();
          EasyLoading.showSuccess('Plantillas restablecidas');
        } else {
          EasyLoading.showError('Error al restablecer');
        }
      } catch (e) {
        EasyLoading.showError('Error: ${e.toString()}');
      }
    }
  }

  Widget _buildVariableChips(String templateKey) {
    final variables = WhatsAppTemplateService.getAvailableVariables(templateKey);

    if (variables.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: variables.map((variable) {
        return ActionChip(
          label: Text(
            '{$variable}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          backgroundColor: kMainColor.withOpacity(0.1),
          labelStyle: TextStyle(color: kMainColor),
          onPressed: () {
            final controller = _controllers[templateKey];
            if (controller != null) {
              final text = controller.text;
              final selection = controller.selection;
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                '{$variable}',
              );
              controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: selection.start + variable.length + 2,
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenSize.width * 0.8,
        height: screenSize.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.message, color: kMainColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Plantillas de WhatsApp',
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
              'Gestiona las plantillas de mensajes automáticos enviados por WhatsApp',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            // Content
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left sidebar - Template list
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Plantilla',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _templateKeys.length,
                              itemBuilder: (context, index) {
                                final key = _templateKeys[index];
                                final isSelected = _selectedTemplate == key;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? kMainColor.withOpacity(0.1) : null,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? kMainColor : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    selected: isSelected,
                                    title: Text(
                                      WhatsAppTemplateService.getTemplateDisplayName(key),
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? kMainColor : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      WhatsAppTemplateService.getTemplateDescription(key),
                                      style: TextStyle(fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      setState(() => _selectedTemplate = key);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 32),

                    // Right side - Template editor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Template name and description
                          Text(
                            WhatsAppTemplateService.getTemplateDisplayName(_selectedTemplate),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            WhatsAppTemplateService.getTemplateDescription(_selectedTemplate),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),

                          // Variables section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Variables disponibles (clic para insertar):',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildVariableChips(_selectedTemplate),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Template editor
                          Text(
                            'Contenido del mensaje:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: kBorderColorTextField),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: _controllers[_selectedTemplate],
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Escribe aquí el contenido del mensaje...',
                                ),
                              ),
                            ),
                          ),
                        ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveTemplates,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
