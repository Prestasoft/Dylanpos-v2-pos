import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:printing/printing.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/model/photo_invoice_model.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:salespro_admin/Repository/photo_invoice_repository.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/bank_provider.dart';
import 'package:salespro_admin/PDF/photo_invoice_pdf_pro.dart';
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/services/api_service.dart';
import 'package:salespro_admin/services/audit_service.dart';
import 'package:salespro_admin/model/audit_model.dart';

// Provider temporal para las ventas (después se conectará con Firebase)
final photoSalesListProvider = StateProvider<List<PhotoInvoiceModel>>((ref) => []);

// Provider para el stream de ventas
final photoInvoicesStreamProvider = StreamProvider<List<PhotoInvoiceModel>>((ref) async* {
  try {
    print('Iniciando photoInvoicesStreamProvider...');
    print('constUserId actual: $constUserId');
    
    final personalInfo = await ref.watch(profileDetailsProvider.future);
    print('Personal info obtenida: ${personalInfo.phoneNumber}');
    
    if (personalInfo.phoneNumber.isEmpty || personalInfo.phoneNumber == 'Loading...') {
      print('Error: Número de teléfono vacío o cargando');
      throw Exception('Usuario no autenticado correctamente');
    }
    
    // IMPORTANTE: Usar siempre phoneNumber para consistencia con las facturas guardadas
    String userIdToUse = personalInfo.phoneNumber;
    
    if (userIdToUse.isEmpty) {
      print('ERROR: No se pudo obtener un userId válido');
      throw Exception('No se pudo obtener el ID del usuario');
    }
    
    print('Usando userId: $userIdToUse (phoneNumber para consistencia)');
    
    final repository = PhotoInvoiceRepository(userId: userIdToUse);
    print('Repository creado, obteniendo facturas...');
    yield* repository.getInvoices();
  } catch (e) {
    print('Error en photoInvoicesStreamProvider: $e');
    print('Stack trace: ${StackTrace.current}');
    throw e;
  }
});

class PhotoSalesListScreen extends ConsumerStatefulWidget {
  const PhotoSalesListScreen({super.key});

  static const String route = '/photo-sales-list';

  @override
  ConsumerState<PhotoSalesListScreen> createState() => _PhotoSalesListScreenState();
}

class _PhotoSalesListScreenState extends ConsumerState<PhotoSalesListScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? selectedDate;
  String selectedStatus = 'Todos';
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(photoInvoicesStreamProvider);
    
    return Scaffold(
      body: salesAsync.when(
        data: (sales) => _buildContent(sales),
        loading: () => Container(
          decoration: const BoxDecoration(color: kDarkWhite),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Cargando ventas...',
                  style: kTextStyle.copyWith(
                    color: kGreyTextColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (error, stack) => Container(
          decoration: const BoxDecoration(color: kDarkWhite),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.alertCircleOutline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar ventas',
                  style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    error.toString().contains('Usuario no autenticado')
                        ? 'Por favor, cierre sesión e inicie sesión nuevamente'
                        : 'Error: ${error.toString()}',
                    style: kTextStyle.copyWith(
                      color: kGreyTextColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(photoInvoicesStreamProvider),
                  icon: const Icon(FeatherIcons.refreshCw),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent(List<PhotoInvoiceModel> sales) {
    
    // Filtrar ventas
    final filteredSales = sales.where((sale) {
      // Búsqueda por texto
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!sale.invoiceNumber.toLowerCase().contains(query) &&
            !sale.customer.customerName.toLowerCase().contains(query) &&
            !sale.customer.phoneNumber.contains(query)) {
          return false;
        }
      }
      
      // Filtro por fecha
      if (selectedDate != null) {
        if (sale.invoiceDate.day != selectedDate!.day ||
            sale.invoiceDate.month != selectedDate!.month ||
            sale.invoiceDate.year != selectedDate!.year) {
          return false;
        }
      }
      
      // Filtro por estado
      if (selectedStatus != 'Todos') {
        if (selectedStatus == 'Pagado' && !sale.isPaid) return false;
        if (selectedStatus == 'Pendiente' && sale.isPaid) return false;
      }
      
      return true;
    }).toList();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: kDarkWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              color: kWhite,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 4.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: kMainColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        MdiIcons.formatListBulleted,
                        color: kMainColor,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lista de Ventas',
                          style: kTextStyle.copyWith(
                            color: kTitleColor,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Impresión y Enmarcado',
                          style: kTextStyle.copyWith(
                            color: kGreyTextColor,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Resumen
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: kDarkWhite,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Ventas',
                                style: kTextStyle.copyWith(
                                  color: kGreyTextColor,
                                  fontSize: 12.0,
                                ),
                              ),
                              Text(
                                '$currency${_calculateTotal(filteredSales).toStringAsFixed(2)}',
                                style: kTextStyle.copyWith(
                                  color: kTitleColor,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 30.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pendiente',
                                style: kTextStyle.copyWith(
                                  color: kGreyTextColor,
                                  fontSize: 12.0,
                                ),
                              ),
                              Text(
                                '$currency${_calculatePending(filteredSales).toStringAsFixed(2)}',
                                style: kTextStyle.copyWith(
                                  color: Colors.orange,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Filtros
                Row(
                  children: [
                    // Búsqueda
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kDarkWhite,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar por factura, cliente o teléfono...',
                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                            prefixIcon: Icon(FeatherIcons.search, color: kGreyTextColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Filtro de fecha
                    Container(
                      decoration: BoxDecoration(
                        color: kDarkWhite,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          setState(() {
                            selectedDate = date;
                          });
                        },
                        borderRadius: BorderRadius.circular(8.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(FeatherIcons.calendar, color: kGreyTextColor, size: 18.0),
                              const SizedBox(width: 8.0),
                              Text(
                                selectedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                    : 'Fecha',
                                style: kTextStyle.copyWith(color: kGreyTextColor),
                              ),
                              if (selectedDate != null) ...[
                                const SizedBox(width: 8.0),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedDate = null;
                                    });
                                  },
                                  child: Icon(FeatherIcons.x, color: kGreyTextColor, size: 16.0),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Filtro de estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: kDarkWhite,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        underline: const SizedBox(),
                        icon: Icon(FeatherIcons.chevronDown, color: kGreyTextColor, size: 18.0),
                        items: ['Todos', 'Pagado', 'Pendiente']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.receiptTextOutline,
                          size: 64.0,
                          color: kGreyTextColor.withAlpha(100),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'No hay ventas registradas',
                          style: kTextStyle.copyWith(
                            color: kGreyTextColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return _buildSaleCard(sale);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(PhotoInvoiceModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Factura #${sale.invoiceNumber}',
                            style: kTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: kTitleColor,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: sale.isPaid
                                  ? Colors.green.withAlpha(20)
                                  : Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              sale.isPaid ? 'Pagado' : 'Pendiente',
                              style: kTextStyle.copyWith(
                                color: sale.isPaid ? Colors.green : Colors.orange,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(FeatherIcons.user, size: 14.0, color: kGreyTextColor),
                          const SizedBox(width: 6.0),
                          Text(
                            sale.customer.customerName,
                            style: kTextStyle.copyWith(color: kGreyTextColor),
                          ),
                          const SizedBox(width: 16.0),
                          Icon(FeatherIcons.phone, size: 14.0, color: kGreyTextColor),
                          const SizedBox(width: 6.0),
                          Text(
                            sale.customer.phoneNumber,
                            style: kTextStyle.copyWith(color: kGreyTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(FeatherIcons.calendar, size: 14.0, color: kGreyTextColor),
                          const SizedBox(width: 6.0),
                          Text(
                            DateFormat('dd/MM/yyyy hh:mm a').format(sale.invoiceDate),
                            style: kTextStyle.copyWith(color: kGreyTextColor, fontSize: 12.0),
                          ),
                          const SizedBox(width: 16.0),
                          Icon(FeatherIcons.creditCard, size: 14.0, color: kGreyTextColor),
                          const SizedBox(width: 6.0),
                          Text(
                            sale.paymentMethod == 'Transferencia' && sale.selectedBank != null
                                ? '${sale.paymentMethod} - ${sale.selectedBank}'
                                : sale.paymentMethod,
                            style: kTextStyle.copyWith(color: kGreyTextColor, fontSize: 12.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Montos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency${sale.totalAmount.toStringAsFixed(2)}',
                      style: kTextStyle.copyWith(
                        color: kTitleColor,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!sale.isPaid) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'Debe: $currency${sale.dueAmount.toStringAsFixed(2)}',
                        style: kTextStyle.copyWith(
                          color: Colors.red,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 16.0),
                // Acciones
                PopupMenuButton<String>(
                  icon: Icon(FeatherIcons.moreVertical, color: kGreyTextColor),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(FeatherIcons.eye, size: 16.0),
                          const SizedBox(width: 8.0),
                          Text('Ver Detalles'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'print',
                      child: Row(
                        children: [
                          Icon(FeatherIcons.printer, size: 16.0),
                          const SizedBox(width: 8.0),
                          Text('Reimprimir'),
                        ],
                      ),
                    ),
                    if (!sale.isPaid)
                      PopupMenuItem(
                        value: 'pay',
                        child: Row(
                          children: [
                            Icon(FeatherIcons.dollarSign, size: 16.0),
                            const SizedBox(width: 8.0),
                            Text('Registrar Pago'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(FeatherIcons.trash2, size: 16.0, color: Colors.red),
                          const SizedBox(width: 8.0),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _showInvoiceDetails(sale);
                        break;
                      case 'print':
                        _reprintInvoice(sale);
                        break;
                      case 'pay':
                        _showPaymentDialog(sale);
                        break;
                      case 'delete':
                        _confirmDeleteInvoice(sale);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
          // Resumen de items
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              children: [
                if (sale.products.isNotEmpty) ...[
                  Icon(MdiIcons.imageFrame, size: 16.0, color: Colors.orange),
                  const SizedBox(width: 6.0),
                  Text(
                    '${sale.products.length} productos',
                    style: kTextStyle.copyWith(
                      color: kGreyTextColor,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                ],
                if (sale.services.isNotEmpty) ...[
                  Icon(MdiIcons.camera, size: 16.0, color: Colors.blue),
                  const SizedBox(width: 6.0),
                  Text(
                    '${sale.services.length} servicios',
                    style: kTextStyle.copyWith(
                      color: kGreyTextColor,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal(List<PhotoInvoiceModel> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.totalAmount);
  }

  double _calculatePending(List<PhotoInvoiceModel> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.dueAmount);
  }

  // Mostrar detalles de la factura
  void _showInvoiceDetails(PhotoInvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kMainColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(FeatherIcons.fileText, color: kWhite),
                    const SizedBox(width: 12),
                    Text(
                      'Detalles de Factura #${invoice.invoiceNumber}',
                      style: kTextStyle.copyWith(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(FeatherIcons.x, color: kWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del cliente
                      _buildSection(
                        'Información del Cliente',
                        [
                          _buildDetailRow('Nombre:', invoice.customer.customerName),
                          _buildDetailRow('Teléfono:', invoice.customer.phoneNumber),
                          if (invoice.customer.emailAddress.isNotEmpty)
                            _buildDetailRow('Email:', invoice.customer.emailAddress),
                          if (invoice.customer.customerAddress.isNotEmpty)
                            _buildDetailRow('Dirección:', invoice.customer.customerAddress),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Productos
                      if (invoice.products.isNotEmpty) ...[
                        _buildSection(
                          'Productos',
                          invoice.products.map((p) => _buildItemRow(
                            p.productName,
                            p.quantity,
                            p.productPrice,
                            p.subtotal,
                          )).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Servicios
                      if (invoice.services.isNotEmpty) ...[
                        _buildSection(
                          'Servicios',
                          invoice.services.map((s) => _buildItemRow(
                            s.serviceName,
                            s.quantity,
                            s.servicePrice,
                            s.subtotal,
                          )).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Resumen
                      _buildSection(
                        'Resumen de Pago',
                        [
                          _buildDetailRow('Subtotal:', '$currency${invoice.subtotal.toStringAsFixed(2)}'),
                          if (invoice.discountAmount > 0)
                            _buildDetailRow('Descuento:', '-$currency${invoice.discountAmount.toStringAsFixed(2)}'),
                          if (invoice.taxAmount > 0)
                            _buildDetailRow('ITBIS (${invoice.taxRate}%):', '$currency${invoice.taxAmount.toStringAsFixed(2)}'),
                          const Divider(),
                          _buildDetailRow('Total:', '$currency${invoice.totalAmount.toStringAsFixed(2)}', bold: true),
                          _buildDetailRow('Pagado:', '$currency${invoice.paidAmount.toStringAsFixed(2)}'),
                          if (invoice.dueAmount > 0)
                            _buildDetailRow('Pendiente:', '$currency${invoice.dueAmount.toStringAsFixed(2)}', color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Información de pago
                      _buildSection(
                        'Información de Pago',
                        [
                          _buildDetailRow('Método:', invoice.paymentMethod),
                          if (invoice.paymentMethod == 'Transferencia' && invoice.selectedBank != null)
                            _buildDetailRow('Banco:', invoice.selectedBank!),
                          _buildDetailRow('Estado:', invoice.isPaid ? 'Pagado' : 'Pendiente'),
                          _buildDetailRow('Fecha:', DateFormat('dd/MM/yyyy hh:mm a').format(invoice.invoiceDate)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Acciones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kDarkWhite,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: kTitleColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Cerrar',
                        style: kTextStyle.copyWith(
                          color: kTitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _reprintInvoice(invoice);
                      },
                      icon: const Icon(FeatherIcons.printer, size: 18),
                      label: Text(
                        'Imprimir',
                        style: kTextStyle.copyWith(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kMainColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                title.contains('Cliente') ? FeatherIcons.user :
                title.contains('Producto') ? MdiIcons.imageFrame :
                title.contains('Servicio') ? MdiIcons.camera :
                title.contains('Pago') ? FeatherIcons.dollarSign :
                FeatherIcons.info,
                size: 18,
                color: kMainColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWhite,
            border: Border.all(color: kBorderColorTextField.withValues(alpha: 0.3)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: kDarkWhite.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: kTextStyle.copyWith(
              color: kTitleColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: kTextStyle.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? kTitleColor,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, int quantity, double price, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBorderColorTextField.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: kTextStyle.copyWith(
                fontSize: 14,
                color: kTitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x$quantity',
              style: kTextStyle.copyWith(
                fontSize: 12,
                color: kMainColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '@$currency${price.toStringAsFixed(2)}',
            style: kTextStyle.copyWith(
              fontSize: 13,
              color: kTitleColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: Text(
              '$currency${total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: kTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reimprimir factura
  Future<void> _reprintInvoice(PhotoInvoiceModel invoice) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener información necesaria
      final personalInfo = await ref.read(profileDetailsProvider.future);
      final generalSetting = await ref.read(generalSettingProvider.future);

      if (generalSetting == null) {
        throw Exception('No se pudo cargar la información necesaria');
      }

      // Buscar la transacción en la API PostgreSQL
      final apiService = ApiService();
      SaleTransactionModel? saleTransaction;

      try {
        final response = await apiService.get('sales', queryParams: {
          'invoiceNumber': invoice.invoiceId ?? '',
          'limit': '1',
        });

        if (response.success && response.data != null) {
          final data = response.data;
          List<dynamic> sales = [];
          if (data is Map && data['sales'] != null) {
            sales = data['sales'] as List<dynamic>;
          } else if (data is List) {
            sales = data;
          }

          if (sales.isNotEmpty) {
            final saleData = Map<String, dynamic>.from(sales.first);
            saleTransaction = SaleTransactionModel.fromJson(saleData);
          }
        }
      } catch (e) {
        debugPrint('Error buscando transacción: $e');
      }

      if (saleTransaction == null) {
        // Si no encuentra en API, usar el método anterior como fallback
        final pdfData = await generatePhotoInvoiceDocumentPro(
          invoice: invoice,
          personalInformation: personalInfo,
          generalSetting: generalSetting,
        );

        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          name: 'Factura_${invoice.invoiceNumber}',
        );
      } else {
        // Si encuentra la transacción, usar GeneratePdfAndPrint
        await GeneratePdfAndPrint().printSaleInvoice(
          personalInformationModel: personalInfo,
          saleTransactionModel: saleTransaction,
          context: context,
          setting: generalSetting,
          fromInventorySale: true,
        );
      }

      
      // Registrar reimpresión en auditoría
      try {
        await AuditService().logPrint(
          module: AuditModule.sales,
          documentType: 'Factura Photo Invoice (Reimpresión)',
          documentId: invoice.invoiceNumber,
        );
      } catch (auditError) {
        print('Error al registrar reimpresión en auditoría: $auditError');
      }
      
      Navigator.pop(context); // Cerrar loading
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reimprimir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostrar diálogo de pago
  void _showPaymentDialog(PhotoInvoiceModel invoice) {
    final paymentController = TextEditingController();
    String selectedPaymentMethod = 'Efectivo';
    String? selectedBank;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Registrar Pago - Factura #${invoice.invoiceNumber}'),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de deuda
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.alertCircle, color: Colors.red),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monto Pendiente',
                            style: kTextStyle.copyWith(color: Colors.red),
                          ),
                          Text(
                            '$currency${invoice.dueAmount.toStringAsFixed(2)}',
                            style: kTextStyle.copyWith(
                              color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Monto a pagar
                TextField(
                  controller: paymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto a Pagar',
                    prefixText: currency,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Método de pago
                Text('Método de Pago', style: kTextStyle.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...['Efectivo', 'Transferencia', 'Tarjeta'].map((method) {
                  return RadioListTile<String>(
                    title: Text(method),
                    value: method,
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                        if (value != 'Transferencia') {
                          selectedBank = null;
                        }
                      });
                    },
                  );
                }),
                // Selector de banco si es transferencia
                if (selectedPaymentMethod == 'Transferencia') ...[
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, child) {
                      final banksAsync = ref.watch(allBanksProvider);
                      return banksAsync.when(
                        data: (banks) => DropdownButtonFormField<String>(
                          value: selectedBank,
                          decoration: InputDecoration(
                            labelText: 'Banco',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: banks.map((bank) => DropdownMenuItem(
                            value: bank.bankName ?? '',
                            child: Text(bank.bankName ?? ''),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedBank = value;
                            });
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error al cargar bancos'),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(paymentController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingrese un monto válido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (amount > invoice.dueAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El monto no puede ser mayor a $currency${invoice.dueAmount.toStringAsFixed(2)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Obtener referencias antes de cualquier operación async
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // Implementar actualización en Firebase
                try {
                  print('Iniciando registro de pago...');
                  print('Invoice ID: ${invoice.invoiceId}');
                  print('Monto: $amount');
                  print('Método: $selectedPaymentMethod');
                  print('Banco: $selectedBank');
                  
                  // Validar que tenemos un ID de factura
                  if (invoice.invoiceId == null || invoice.invoiceId!.isEmpty) {
                    throw Exception('ID de factura no válido');
                  }
                  
                  // Validar método de pago y banco
                  if (selectedPaymentMethod == 'Transferencia' && (selectedBank == null || selectedBank == '')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor seleccione un banco'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  
                  // Cerrar el diálogo de pago primero
                  navigator.pop();
                  
                  // Mostrar loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => PopScope(
                      canPop: false,
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                Text(
                                  'Registrando pago...',
                                  style: kTextStyle.copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  // Obtener información del usuario
                  final personalInfo = await ref.read(profileDetailsProvider.future);
                  print('Usuario: ${personalInfo.phoneNumber}');
                  
                  // Validar que tenemos un usuario válido
                  if (personalInfo.phoneNumber.isEmpty || personalInfo.phoneNumber == 'Loading...') {
                    throw Exception('Usuario no autenticado correctamente');
                  }
                  
                  // IMPORTANTE: Usar siempre phoneNumber para consistencia
                  String userIdToUse = personalInfo.phoneNumber;
                  print('Registrando pago con userId: $userIdToUse');
                  
                  final repository = PhotoInvoiceRepository(userId: userIdToUse);
                  
                  // Actualizar el mensaje de loading con más información
                  EasyLoading.show(
                    status: 'Procesando pago...\nNo cierre esta ventana',
                    dismissOnTap: false,
                  );
                  
                  // Registrar el pago con timeout más largo
                  print('Registrando pago en Firebase...');
                  await repository.registerPayment(
                    invoiceId: invoice.invoiceId!,
                    paymentAmount: amount,
                    paymentMethod: selectedPaymentMethod,
                    selectedBank: selectedBank,
                  ).timeout(
                    const Duration(seconds: 60), // Aumentar a 60 segundos
                    onTimeout: () {
                      throw Exception('La conexión con el servidor está tardando demasiado. Por favor verifique su conexión a internet e intente nuevamente.');
                    },
                  );
                  print('Pago registrado exitosamente');
                  
                  // Registrar en auditoría
                  try {
                    await AuditService().logUpdate(
                      module: AuditModule.sales,
                      itemName: 'Pago Photo Invoice',
                      itemId: invoice.invoiceNumber,
                      beforeData: {
                        'paidAmount': invoice.paidAmount,
                        'dueAmount': invoice.dueAmount,
                        'isPaid': invoice.isPaid,
                      },
                      afterData: {
                        'paidAmount': invoice.paidAmount + amount,
                        'dueAmount': invoice.dueAmount - amount,
                        'isPaid': (invoice.dueAmount - amount) <= 0,
                        'paymentAmount': amount,
                        'paymentMethod': selectedPaymentMethod,
                        'bankName': selectedBank,
                        'paymentDate': DateTime.now().toIso8601String(),
                      },
                    );
                  } catch (auditError) {
                    print('Error al registrar en auditoría: $auditError');
                  }
                  
                  // Ocultar loading de EasyLoading
                  EasyLoading.dismiss();

                  // Cerrar loading
                  navigator.pop();
                  
                  // Mostrar mensaje de éxito
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Pago de $currency${amount.toStringAsFixed(2)} registrado exitosamente'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  
                  // La lista se actualizará automáticamente por el StreamProvider
                  
                } catch (e) {
                  print('Error al registrar pago: $e');
                  // Cerrar loading si hay error
                  try {
                    navigator.pop();
                  } catch (_) {
                    // Ignorar si no se puede cerrar
                  }
                  
                  // Mostrar error
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al registrar el pago: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
              ),
              child: const Text('Registrar Pago'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Confirmar eliminación de factura
  Future<void> _confirmDeleteInvoice(PhotoInvoiceModel invoice) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro que desea eliminar la factura #${invoice.invoiceNumber}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(FeatherIcons.alertTriangle, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      invoice.isPaid 
                        ? 'Esta factura ya fue pagada. La eliminación no afectará los registros contables.'
                        : 'Esta factura tiene un saldo pendiente de $currency${invoice.dueAmount.toStringAsFixed(2)}.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        EasyLoading.show(status: 'Eliminando factura...');
        
        // Obtener el repositorio
        final personalInfo = await ref.read(profileDetailsProvider.future);
        final repository = PhotoInvoiceRepository(userId: personalInfo.phoneNumber);
        
        // Eliminar la factura
        await repository.deleteInvoice(invoice.invoiceId!);
        
        // Registrar en auditoría
        try {
          await AuditService().logDelete(
            module: AuditModule.sales,
            itemName: 'Factura Photo Invoice',
            itemId: invoice.invoiceNumber,
            data: {
              'invoiceNumber': invoice.invoiceNumber,
              'customerName': invoice.customer.customerName,
              'customerPhone': invoice.customer.phoneNumber,
              'totalAmount': invoice.totalAmount,
              'paidAmount': invoice.paidAmount,
              'dueAmount': invoice.dueAmount,
              'isPaid': invoice.isPaid,
              'paymentMethod': invoice.paymentMethod,
              'deletedAt': DateTime.now().toIso8601String(),
              'reason': 'Eliminación manual por usuario',
            },
          );
        } catch (auditError) {
          print('Error al registrar eliminación en auditoría: $auditError');
        }
        
        EasyLoading.dismiss();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        EasyLoading.dismiss();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}