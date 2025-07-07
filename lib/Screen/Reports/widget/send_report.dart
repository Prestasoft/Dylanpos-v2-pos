// send_report_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cuadre_report_provider.dart';

class SendReportDialog extends StatefulWidget {
  final CuadreData cuadreData;

  const SendReportDialog({
    Key? key,
    required this.cuadreData,
  }) : super(key: key);

  @override
  State<SendReportDialog> createState() => _SendReportDialogState();
}

class _SendReportDialogState extends State<SendReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController =
      TextEditingController(text: "miguelcastillo@hotmail.com");
  final _nameController = TextEditingController(text: "Miguel Castillo");

  final _phoneController = TextEditingController(text: "+18492220819");
  final _subjectController = TextEditingController();

  bool _sendByEmail = true;
  bool _sendByWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _subjectController.text =
        'Reporte de Cuadre de Caja - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_sendByEmail && !_sendByWhatsApp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un método de envío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = Provider.of<CuadreReportProvider>(context, listen: false);

    try {
      if (_sendByEmail) {
        await provider.sendReportByEmail(
          cuadreData: widget.cuadreData,
          recipientEmail: _emailController.text.trim(),
          recipientName: _nameController.text.trim(),
          subject: _subjectController.text.trim(),
        );
      }

      if (_sendByWhatsApp) {
        await provider.sendReportByWhatsApp(
          cuadreData: widget.cuadreData,
          phoneNumber: _phoneController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CuadreReportProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Enviar Reporte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opciones de envío
                  const Text(
                    'Seleccionar método de envío:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Checkbox para Email
                  CheckboxListTile(
                    value: _sendByEmail,
                    onChanged: (value) {
                      setState(() {
                        _sendByEmail = value ?? false;
                      });
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.email, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Email'),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  // Checkbox para WhatsApp
                  CheckboxListTile(
                    value: _sendByWhatsApp,
                    onChanged: (value) {
                      setState(() {
                        _sendByWhatsApp = value ?? false;
                      });
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.message, color: Colors.green),
                        SizedBox(width: 8),
                        Text('WhatsApp'),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 20),

                  // Campos para email
                  if (_sendByEmail) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📧 Configuración de Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email del destinatario',
                              hintText: 'ejemplo@correo.com',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (_sendByEmail &&
                                  (value == null || value.isEmpty)) {
                                return 'El email es requerido';
                              }
                              if (_sendByEmail && !value!.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del destinatario',
                              hintText: 'Juan Pérez',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (_sendByEmail &&
                                  (value == null || value.isEmpty)) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Asunto',
                              prefixIcon: Icon(Icons.subject),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (_sendByEmail &&
                                  (value == null || value.isEmpty)) {
                                return 'El asunto es requerido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Campos para WhatsApp
                  if (_sendByWhatsApp) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📱 Configuración de WhatsApp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Número de teléfono',
                              hintText: '+1-XXX-XXX-XXXX',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (_sendByWhatsApp &&
                                  (value == null || value.isEmpty)) {
                                return 'El número de teléfono es requerido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Mostrar error si no se selecciona ningún método
                  if (!_sendByEmail && !_sendByWhatsApp)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selecciona al menos un método de envío',
                              style: TextStyle(color: Colors.orange),
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
              onPressed:
                  provider.isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: provider.isLoading ? null : _sendReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Enviar Reporte'),
            ),
          ],
        );
      },
    );
  }
}
