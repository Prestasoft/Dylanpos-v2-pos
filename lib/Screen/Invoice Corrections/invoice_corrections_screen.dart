// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/general_setting_provider.dart';
import '../../commas.dart';
import '../../model/sale_transaction_model.dart';
import '../../model/add_to_cart_model.dart';
import '../../services/api_service.dart';

class InvoiceCorrectionsScreen extends StatefulWidget {
  const InvoiceCorrectionsScreen({super.key});

  @override
  State<InvoiceCorrectionsScreen> createState() => _InvoiceCorrectionsScreenState();
}

class _InvoiceCorrectionsScreenState extends State<InvoiceCorrectionsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get('invoice-corrections');

      if (response.success && response.data != null) {
        final invoicesList = response.data['invoices'] as List<dynamic>? ?? [];
        setState(() {
          _invoices = invoicesList.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar facturas';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showPdfAndCorrect(Map<String, dynamic> invoice) async {
    try {
      EasyLoading.show(status: 'Cargando factura...');

      // Obtener datos completos de la venta
      final response = await _apiService.get('invoice-corrections/${invoice['id']}/sale');

      if (!response.success || response.data == null) {
        EasyLoading.showError('Error al cargar datos de la factura');
        return;
      }

      final saleData = response.data['sale'];
      EasyLoading.dismiss();

      // Mostrar diálogo con PDF y campos de corrección
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CorrectionDialog(
          invoice: invoice,
          saleData: saleData,
          onCorrected: () {
            _loadInvoices(); // Recargar lista
          },
        ),
      );
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Corrección de Facturas'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoices,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
            const SizedBox(height: 16),
            const Text(
              '¡Todas las facturas están correctas!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay facturas con datos inconsistentes',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con contador
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_invoices.length} facturas con datos inconsistentes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de facturas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _invoices.length,
            itemBuilder: (context, index) {
              final invoice = _invoices[index];
              return _buildInvoiceCard(invoice);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final total = invoice['total'] ?? 0.0;
    final paidAmount = invoice['paidAmount'] ?? 0.0;
    final dueAmount = invoice['dueAmount'] ?? 0.0;
    final createdAt = invoice['createdAt'] != null
        ? DateTime.tryParse(invoice['createdAt'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPdfAndCorrect(invoice),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${invoice['invoiceNumber']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invoice['customerName'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Problema detectado
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos inconsistentes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Total: ${myFormat.format(total)} | Pagado: ${myFormat.format(paidAmount)} | Pendiente: ${myFormat.format(dueAmount)}',
                            style: TextStyle(color: Colors.red[700], fontSize: 12),
                          ),
                          Text(
                            'isPaid = false pero paidAmount = total',
                            style: TextStyle(color: Colors.red[600], fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Botón
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPdfAndCorrect(invoice),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Ver PDF y Corregir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Diálogo de corrección con PDF
class _CorrectionDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> invoice;
  final Map<String, dynamic> saleData;
  final VoidCallback onCorrected;

  const _CorrectionDialog({
    required this.invoice,
    required this.saleData,
    required this.onCorrected,
  });

  @override
  ConsumerState<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends ConsumerState<_CorrectionDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _dueAmountController = TextEditingController();
  bool _isLoading = false;

  double get _total => (widget.saleData['totalAmount'] ?? 0.0).toDouble();

  @override
  void initState() {
    super.initState();
    // Inicializar con valores actuales (incorrectos)
    _paidAmountController.text = '0';
    _dueAmountController.text = _total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _dueAmountController.dispose();
    super.dispose();
  }

  void _updateDueAmount() {
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    final due = _total - paid;
    _dueAmountController.text = due.toStringAsFixed(2);
  }

  Future<void> _generatePdf() async {
    try {
      EasyLoading.show(status: 'Generando PDF...');

      final personalData = await ref.read(profileDetailsProvider.future);
      final settings = await ref.read(generalSettingProvider.future);

      // Convertir saleData a SaleTransactionModel
      final sale = _convertToSaleModel(widget.saleData);

      await GeneratePdfAndPrint().printSaleInvoice(
        personalInformationModel: personalData,
        saleTransactionModel: sale,
        context: context,
        setting: settings,
      );

      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.showError('Error al generar PDF: $e');
    }
  }

  SaleTransactionModel _convertToSaleModel(Map<String, dynamic> data) {
    // Convertir productList
    List<AddToCartModel> productList = [];
    if (data['productList'] != null) {
      final rawList = data['productList'];
      if (rawList is List) {
        for (var item in rawList) {
          if (item is String) {
            // Es un string JSON, usar fromJson que acepta String
            try {
              if (item.startsWith('{')) {
                productList.add(AddToCartModel.fromJson(item));
              }
            } catch (e) {
              debugPrint('Error parsing product: $e');
            }
          } else if (item is Map) {
            // Es un Map, usar fromMap
            productList.add(AddToCartModel.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    return SaleTransactionModel(
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      customerGst: data['customerGst'] ?? '',
      customerType: data['customerType'] ?? 'Retail',
      customerImage: data['customerImage'] ?? '',
      invoiceNumber: data['invoiceNumber']?.toString() ?? '',
      purchaseDate: data['purchaseDate']?.toString() ?? DateTime.now().toIso8601String(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      dueAmount: (data['dueAmount'] ?? 0.0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0.0).toDouble(),
      vat: (data['vat'] ?? 0.0).toDouble(),
      isPaid: data['isPaid'] ?? false,
      paymentType: data['paymentType'] ?? 'Efectivo',
      sellerName: data['sellerName'] ?? '',
      productList: productList,
      saleType: data['saleType'],
      ncfType: data['ncfType'],
      ncfNumber: data['ncfNumber'],
    );
  }

  Future<void> _saveCorrection() async {
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    final due = double.tryParse(_dueAmountController.text) ?? 0;

    if (paid < 0 || due < 0) {
      EasyLoading.showError('Los montos no pueden ser negativos');
      return;
    }

    if ((paid + due).toStringAsFixed(2) != _total.toStringAsFixed(2)) {
      // Mostrar advertencia pero permitir continuar
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Advertencia'),
          content: Text(
            'La suma de Pagado (\$${myFormat.format(paid)}) + Pendiente (\$${myFormat.format(due)}) = \$${myFormat.format(paid + due)}\n\n'
            'No coincide con el Total: \$${myFormat.format(_total)}\n\n'
            '¿Desea continuar de todos modos?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.put(
        'invoice-corrections/${widget.invoice['id']}',
        {
          'paidAmount': paid,
          'dueAmount': due,
        },
      );

      if (response.success) {
        EasyLoading.showSuccess('Factura corregida');
        widget.onCorrected();
        if (mounted) Navigator.pop(context);
      } else {
        EasyLoading.showError('Error al guardar');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return Dialog(
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_document, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Corregir Factura #${widget.invoice['invoiceNumber']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info del cliente
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.invoice['customerName'] ?? 'Sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (widget.invoice['customerPhone'] != null)
                              Text('Tel: ${widget.invoice['customerPhone']}'),
                            Text('Vendedor: ${widget.invoice['sellerName'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botón ver PDF
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        label: const Text('Ver PDF Original'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Valores actuales (incorrectos)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valores actuales (incorrectos):',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
                          ),
                          const SizedBox(height: 4),
                          Text('Total: \$${myFormat.format(_total)}'),
                          Text('Pagado: \$${myFormat.format(widget.invoice['paidAmount'] ?? 0)}'),
                          Text('Pendiente: \$${myFormat.format(widget.invoice['dueAmount'] ?? 0)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campos de corrección
                    Text(
                      'Ingrese los valores correctos:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900]),
                    ),
                    const SizedBox(height: 8),
                    // Total (solo lectura)
                    TextFormField(
                      initialValue: _total.toStringAsFixed(2),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Total',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: Color(0xFFEEEEEE),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Monto pagado
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto Pagado',
                        prefixText: '\$ ',
                        border: const OutlineInputBorder(),
                        helperText: 'Ingrese el monto que realmente pagó el cliente',
                        helperStyle: TextStyle(color: Colors.green[700]),
                      ),
                      onChanged: (_) => _updateDueAmount(),
                    ),
                    const SizedBox(height: 12),
                    // Monto pendiente
                    TextFormField(
                      controller: _dueAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto Pendiente',
                        prefixText: '\$ ',
                        border: const OutlineInputBorder(),
                        helperText: 'Se calcula automáticamente (Total - Pagado)',
                        helperStyle: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCorrection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar Corrección'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
