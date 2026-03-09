import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';
import 'package:salespro_admin/model/add_to_cart_model.dart'; // Importar modelo de carrito
import 'package:intl/intl.dart'; // Añadir para manejo de fechas
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';

import '../../Provider/customer_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../services/api_service.dart';
import '../../services/deletion_password_service.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';
import '../../model/due_transaction_model.dart';
import 'due_popUp.dart';

/// Modelo para agrupar las deudas por cliente
class CustomerDueInfo {
  final String customerName;
  final String customerPhone;
  final String customerType;
  final double totalDue;
  final int invoiceCount;
  final List<SaleTransactionModel> pendingSales;

  CustomerDueInfo({
    required this.customerName,
    required this.customerPhone,
    required this.customerType,
    required this.totalDue,
    required this.invoiceCount,
    required this.pendingSales,
  });

  /// Convertir a CustomerModel para compatibilidad con el código existente
  CustomerModel toCustomerModel() {
    return CustomerModel(
      id: customerPhone, // Usar teléfono como ID temporal
      customerName: customerName,
      phoneNumber: customerPhone,
      type: customerType,
      emailAddress: '',
      customerAddress: '',
      dueAmount: totalDue.toString(),
      profilePicture: '',
      openingBalance: '0',
      remainedBalance: '0',
      gst: '',
    );
  }
}

class DueList extends StatefulWidget {
  const DueList({Key? key}) : super(key: key);

  @override
  State<DueList> createState() => _DueListState();
}

class _DueListState extends State<DueList> {
  double totalCustomerDue(
      {required List<CustomerModel> customers,
      required String selectedCustomerType}) {
    double totalDue = 0;
    for (var c in customers) {
      totalDue += double.parse(c.dueAmount);
    }
    return totalDue;
  }

  int selectedItem = 10;
  int itemCount = 10;
  String selectedParties = 'Clientes';
  ScrollController mainScroll = ScrollController();

  // Controller para mantener el texto de búsqueda cuando se reconstruye la UI
  final TextEditingController _searchController = TextEditingController();

  // ValueNotifier para búsqueda (igual que Customer List - NO usa setState)
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  // Timer para debounce de búsqueda
  Timer? _debounceTimer;

  // Función de búsqueda con debounce (500ms como Customer List)
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchQueryNotifier.value != value) {
        _searchQueryNotifier.value = value;
        _currentPage = 1; // Reset a página 1
      }
    });
  }

  // Nuevas variables para el filtro de fecha
  String dateFilter = 'Todos'; // 'Hoy' o 'Todos'
  DateTimeRange? dateRange; // Para el selector de rango de fechas

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _debounceTimer?.cancel();
    mainScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  final _horizontalScroll = ScrollController();
  int _categoryPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  // Función para mostrar el selector de rango de fechas
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: dateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlueTextColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        dateRange = picked;
        dateFilter = 'Rango';
        _currentPage = 1;
      });
    }
  }

  // Función para filtrar por fecha
  bool _filterByDate(CustomerModel customer) {
    if (dateFilter == 'Todos') return true;
    
    if (customer.updatedAt == null || customer.updatedAt!.isEmpty) return false;
    
    try {
      final updatedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(customer.updatedAt!);
      
      if (dateFilter == 'Hoy') {
        final now = DateTime.now();
        return updatedDate.year == now.year &&
               updatedDate.month == now.month &&
               updatedDate.day == now.day;
      } else if (dateFilter == 'Rango' && dateRange != null) {
        return updatedDate.isAfter(dateRange!.start) && 
               updatedDate.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Añadir esta función para mostrar las facturas pendientes del cliente
  void _mostrarFacturasPendientes(BuildContext context, String clienteId, String clienteNombre) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Facturas pendientes de $clienteNombre'),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: FutureBuilder<List<SaleTransactionModel>>(
                  future: _obtenerFacturasPendientes(clienteId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                           final facturas = snapshot.data ?? [];
                  
                  if (facturas.isEmpty) {
                    return const Center(child: Text('No se encontraron facturas pendientes'));
                  }
                    
                    return ListView.builder(
                      itemCount: facturas.length,
                      itemBuilder: (context, index) {
                        final factura = facturas[index];
                        return Consumer(
                          builder: (context, ref, child) {
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  try {
                                    final setting = ref.read(generalSettingProvider).value;
                                    final profileInfo = ref.read(profileDetailsProvider).value;
                                    
                                    if (setting != null && profileInfo != null && context.mounted) {
                                      EasyLoading.show(status: 'Generando factura...');
                                      await GeneratePdfAndPrint().printSaleInvoice(
                                        setting: setting,
                                        personalInformationModel: profileInfo,
                                        saleTransactionModel: factura,
                                        context: context,
                                        printType: 'normal',
                                        fromSaleReports: true,
                                        post: factura,
                                      );
                                      EasyLoading.dismiss();
                                    } else {
                                      EasyLoading.showError('No se pudo cargar la configuración');
                                    }
                                  } catch (error) {
                                    EasyLoading.dismiss();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al generar factura: $error')),
                                      );
                                    }
                                  }
                                },
                                child: ListTile(
                                  title: Text(
                                    'Factura #${factura.invoiceNumber}',
                                    style: const TextStyle(
                                      color: kBlueTextColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Fecha: ${_formatearFecha(factura.purchaseDate)}'),
                                      Text('Monto pendiente: RD\$${_formatearMonto(factura.dueAmount ?? 0)}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: 'Click para generar factura PDF',
                                        child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 24),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: kGreenTextColor),
                                        onPressed: () {
                                          _verDetalleFactura(context, factura);
                                        },
                                        tooltip: 'Ver detalle',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.S.of(context).cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Función para obtener las facturas pendientes del cliente
  Future<List<SaleTransactionModel>> _obtenerFacturasPendientes(String clienteId) async {
    List<SaleTransactionModel> facturasPendientes = [];
    try {
      final apiService = ApiService();
      final response = await apiService.get('sales', queryParams: {
        'customerPhone': clienteId,
        'hasDue': 'true',
      });

      if (response.success && response.data != null) {
        final sales = response.data['sales'] as List<dynamic>? ?? [];
        for (var saleData in sales) {
          final saleMap = Map<String, dynamic>.from(saleData);
          SaleTransactionModel factura = SaleTransactionModel.fromJson(saleMap);
          if (factura.dueAmount != null && factura.dueAmount! > 0) {
            factura.key = saleMap['id']?.toString() ?? '';
            facturasPendientes.add(factura);
          }
        }
      }
    } catch (e) {
      print('Error al obtener facturas pendientes: $e');
    }

    // Ordenar por fecha (más recientes primero)
    facturasPendientes.sort((a, b) {
      DateTime fechaA = DateTime.tryParse(a.purchaseDate) ?? DateTime(1900);
      DateTime fechaB = DateTime.tryParse(b.purchaseDate) ?? DateTime(1900);
      return fechaB.compareTo(fechaA);
    });

    return facturasPendientes;
  }

  // Función para formatear la fecha
  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return fecha;
    }
  }

  // Función para ver el detalle de la factura
  void _verDetalleFactura(BuildContext context, SaleTransactionModel factura) {
    // Calcular el total pagado para usarlo en varios lugares
    final double totalPagado = (factura.totalAmount ?? 0) - (factura.dueAmount ?? 0);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 5,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: kBlueTextColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detalle de Factura #${factura.invoiceNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del cliente
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 20, color: kGreyTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      factura.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 20, color: kGreyTextColor),
                                  const SizedBox(width: 8),
                                  Text(factura.customerPhone),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 20, color: kGreyTextColor),
                                  const SizedBox(width: 8),
                                  Text(_formatearFecha(factura.purchaseDate)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Resumen financiero
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumen Financiero',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monto total:'),
                                  Text(
                                    'RD\$${_formatearMonto(factura.totalAmount ?? 0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total pagado:'),
                                  Text(
                                    'RD\$${_formatearMonto(totalPagado)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: totalPagado > 0 ? Colors.green.shade700 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monto pendiente:'),
                                  Text(
                                    'RD\$${_formatearMonto(factura.dueAmount ?? 0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: (factura.dueAmount ?? 0) > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Lista de productos
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 20, color: kGreyTextColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'Productos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Encabezados de tabla
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          'Producto',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Cantidad',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Precio',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Subtotal',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                ),
                              ),
                              
                              // Lista de productos
                              ...factura.productList?.map((producto) => Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black12,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          producto.productName ?? 'Producto sin nombre',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        producto.quantity.toString(),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'RD\$${_calcularPrecioUnitario(producto)}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'RD\$${_formatearMonto(producto.subTotal)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              )).toList() ?? [],
                              
                              // Total
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'RD\$${_formatearMonto(factura.totalAmount ?? 0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlueTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // No se elimina esta función porque sigue siendo utilizada en otras partes del código
  Widget _detalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Función para calcular el precio unitario de un producto de forma segura
  String _calcularPrecioUnitario(AddToCartModel producto) {
    try {
      // Asegurarse de que tanto subTotal como quantity sean números
      final subTotal = producto.subTotal is num 
          ? producto.subTotal 
          : double.tryParse(producto.subTotal?.toString() ?? '0') ?? 0.0;
      
      // La cantidad ya es de tipo num en el modelo, pero aseguramos que sea > 0
      final quantity = producto.quantity > 0 ? producto.quantity : 1;
      
      // Calcular el precio unitario
      final precioUnitario = subTotal / quantity;
      
      // Formatear el número como String con el formato adecuado
      return NumberFormat("#,##0.00", "es_ES").format(precioUnitario);
    } catch (e) {
      print('Error calculando precio unitario: $e');
      return '0.00';
    }
  }

  // Función para formatear montos de forma segura
  String _formatearMonto(dynamic monto) {
    try {
      // Convertir a número si es string o mantener si ya es número
      final montoNumerico = monto is num
          ? monto
          : double.tryParse(monto?.toString() ?? '0') ?? 0.0;

      // Formatear el número
      return NumberFormat("#,##0.00", "es_ES").format(montoNumerico);
    } catch (e) {
      print('Error formateando monto: $e');
      return '0.00';
    }
  }

  // ============ HISTORIAL DE PAGOS (ABONOS) ============

  /// Mostrar el historial de pagos/abonos de un cliente
  void _mostrarHistorialPagos(BuildContext context, String clientePhone, String clienteNombre, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.history, color: kBlueTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Historial de Pagos - $clienteNombre',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              content: SizedBox(
                width: 700,
                height: 500,
                child: FutureBuilder<List<DueTransactionModel>>(
                  future: _obtenerHistorialPagos(clientePhone),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final pagos = snapshot.data ?? [];

                    if (pagos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay pagos registrados',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: pagos.length,
                      itemBuilder: (context, index) {
                        final pago = pagos[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: kGreenTextColor.withOpacity(0.2),
                              child: const Icon(Icons.payment, color: kGreenTextColor),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  'Factura #${pago.invoiceNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: pago.isPaid == true ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    pago.isPaid == true ? 'Pagado' : 'Abono',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: pago.isPaid == true ? Colors.green.shade800 : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(_formatearFecha(pago.purchaseDate ?? '')),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Monto pagado: RD\$${_formatearMonto(pago.payDueAmount ?? 0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                if (pago.paymentType != null && pago.paymentType!.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.credit_card, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('Método: ${pago.paymentType}'),
                                    ],
                                  ),
                                if (pago.sellerName != null && pago.sellerName!.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('Procesado por: ${pago.sellerName}'),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Eliminar pago',
                              onPressed: () {
                                _confirmarEliminarPago(dialogContext, pago, clientePhone, ref, () {
                                  // Refrescar la lista después de eliminar
                                  setState(() {});
                                });
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Obtener historial de pagos de un cliente desde PostgreSQL
  Future<List<DueTransactionModel>> _obtenerHistorialPagos(String clientePhone) async {
    List<DueTransactionModel> pagos = [];
    try {
      final apiService = ApiService();
      final response = await apiService.get('due-transactions', queryParams: {
        'customerPhone': clientePhone,
        'limit': '500',
      });

      if (response.success && response.data != null) {
        final transactions = response.data['dueTransactions'] as List<dynamic>? ??
                            response.data['due_transactions'] as List<dynamic>? ??
                            response.data as List<dynamic>? ?? [];

        for (var data in transactions) {
          final map = Map<String, dynamic>.from(data);
          final pago = DueTransactionModel.fromJson(map);
          // Guardar el ID para poder eliminar
          pago.id = map['id']?.toString() ?? '';
          pagos.add(pago);
        }
      }
    } catch (e) {
      print('Error al obtener historial de pagos: $e');
    }

    // Ordenar por fecha (más recientes primero)
    pagos.sort((a, b) {
      DateTime fechaA = DateTime.tryParse(a.purchaseDate ?? '') ?? DateTime(1900);
      DateTime fechaB = DateTime.tryParse(b.purchaseDate ?? '') ?? DateTime(1900);
      return fechaB.compareTo(fechaA);
    });

    return pagos;
  }

  /// Confirmar eliminación de pago con clave de autorización
  void _confirmarEliminarPago(
    BuildContext context,
    DueTransactionModel pago,
    String clientePhone,
    WidgetRef ref,
    VoidCallback onSuccess,
  ) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('Eliminar Pago'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Está seguro de eliminar este pago?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text('Factura: #${pago.invoiceNumber}'),
                    Text('Monto: RD\$${_formatearMonto(pago.payDueAmount ?? 0)}'),
                    Text('Fecha: ${_formatearFecha(pago.purchaseDate ?? '')}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta acción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Revertirá el saldo del cliente'),
              const Text('• Actualizará la factura como pendiente'),
              const Text('• Esta acción NO se puede deshacer'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Clave de eliminación',
                  hintText: 'Ingrese la clave de autorización',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  EasyLoading.showError('Ingrese la clave de autorización');
                  return;
                }

                // Validar clave
                final isValid = await DeletionPasswordService.validatePassword(password);

                if (isValid) {
                  Navigator.of(dialogContext).pop();
                  _ejecutarEliminarPago(context, pago, clientePhone, ref, onSuccess);
                } else {
                  EasyLoading.showError('Clave incorrecta');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar Pago'),
            ),
          ],
        );
      },
    );
  }

  /// Ejecutar la eliminación del pago
  void _ejecutarEliminarPago(
    BuildContext context,
    DueTransactionModel pago,
    String clientePhone,
    WidgetRef ref,
    VoidCallback onSuccess,
  ) async {
    try {
      EasyLoading.show(status: 'Eliminando pago...');

      final apiService = ApiService();
      final montoRevertir = pago.payDueAmount ?? 0;

      // 1. Eliminar el registro de due_transactions
      if (pago.id != null && pago.id!.isNotEmpty) {
        final deleteResponse = await apiService.delete('due-transactions/${pago.id}');
        if (!deleteResponse.success) {
          throw Exception('Error al eliminar el pago: ${deleteResponse.message}');
        }
      }

      // 2. Eliminar el registro de daily_transactions asociado
      try {
        // Buscar la transacción diaria con el mismo invoice
        final dailyResponse = await apiService.get('daily-transactions', queryParams: {
          'invoiceNumber': pago.invoiceNumber,
        });

        if (dailyResponse.success && dailyResponse.data != null) {
          final transactions = dailyResponse.data['dailyTransactions'] as List<dynamic>? ?? 
                               dailyResponse.data['daily_transactions'] as List<dynamic>? ?? [];
                               
          for (var tx in transactions) {
            final txId = tx['id']?.toString();
            final type = tx['type']?.toString();
            final paymentIn = double.tryParse(tx['paymentIn']?.toString() ?? tx['payment_in']?.toString() ?? '0') ?? 0;
            final paymentOut = double.tryParse(tx['paymentOut']?.toString() ?? tx['payment_out']?.toString() ?? '0') ?? 0;
            
            bool isMatch = false;
            // Para clientes, buscar en paymentIn
            if (type == 'Due Collection' && paymentIn == montoRevertir) {
              isMatch = true;
            } 
            // Para proveedores, buscar en paymentOut
            else if (type == 'Due Payment' && paymentOut == montoRevertir) {
              isMatch = true;
            }

            if (txId != null && txId.isNotEmpty && isMatch) {
              await apiService.delete('daily-transactions/$txId');
              break; // IMPORTANTE: Solo borrar un registro para no eliminar otros pagos de la misma factura
            }
          }
        }
      } catch (e) {
        print('Warning: No se pudo eliminar daily_transaction: $e');
      }

      // 3. Actualizar el due_amount de la factura original (sumar el monto revertido)
      try {
        // Buscar la factura original
        final salesResponse = await apiService.get('sales', queryParams: {
          'invoiceNumber': pago.invoiceNumber,
        });

        if (salesResponse.success && salesResponse.data != null) {
          final sales = salesResponse.data['sales'] as List<dynamic>? ?? [];
          if (sales.isNotEmpty) {
            final sale = sales.first;
            final saleId = sale['id']?.toString();
            final currentDueAmount = double.tryParse(sale['due_amount']?.toString() ?? '0') ?? 0;
            final currentPaidAmount = double.tryParse(sale['paid_amount']?.toString() ?? '0') ?? 0;
            final newDueAmount = currentDueAmount + montoRevertir;
            final newPaidAmount = currentPaidAmount - montoRevertir;

            if (saleId != null && saleId.isNotEmpty) {
              await apiService.put('sales/$saleId', {
                'due_amount': newDueAmount,
                'paid_amount': newPaidAmount,
                'is_paid': newDueAmount <= 0,
              });
            }
          }
        }
      } catch (e) {
        print('Warning: No se pudo actualizar due_amount de la factura: $e');
      }

      // 4. Actualizar el saldo del cliente (sumar el monto al due)
      try {
        final customerResponse = await apiService.get('customers', queryParams: {
          'phone': clientePhone,
        });

        if (customerResponse.success && customerResponse.data != null) {
          final customers = customerResponse.data['customers'] as List<dynamic>? ?? [];
          if (customers.isNotEmpty) {
            final customer = customers.first;
            final customerId = customer['id']?.toString();
            final currentDue = double.tryParse(customer['due']?.toString() ?? '0') ?? 0;
            final newDue = currentDue + montoRevertir;

            if (customerId != null && customerId.isNotEmpty) {
              await apiService.put('customers/$customerId', {
                'due': newDue,
              });
            }
          }
        }
      } catch (e) {
        print('Warning: No se pudo actualizar saldo del cliente: $e');
      }

      // 5. Refrescar providers
      ref.invalidate(allCustomerProvider);
      ref.invalidate(salesWithDueProvider);

      EasyLoading.dismiss();
      EasyLoading.showSuccess('Pago eliminado correctamente');

      // Llamar callback para refrescar la lista
      onSuccess();

    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: $e');
      print('Error al eliminar pago: $e');
    }
  }

  @override
  // Widget del campo de búsqueda que NO se reconstruye
  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12.0),
          hintText: 'Buscar por nombre, teléfono o # factura...',
          hintStyle: const TextStyle(color: kNeutral400),
          prefixIcon: const Icon(FeatherIcons.search, color: kNeutral400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: kBorderColorTextField),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: kBorderColorTextField),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: kMainColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
          backgroundColor: kDarkWhite,
          body: Column(
            children: [
              // BÚSQUEDA FIJA - No se reconstruye
              _buildSearchField(context),
              // DATOS - Se reconstruyen cuando cambia la búsqueda
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, searchQuery, child) {
                    return Consumer(builder: (_, ref, watch) {
                      // Si hay búsqueda, usar el provider de búsqueda directa del API
                      // Si no hay búsqueda, usar el provider normal
                      final bool isSearching = searchQuery.trim().isNotEmpty;

                // Usamos salesWithDueProvider o searchSalesWithDueProvider según si hay búsqueda
                AsyncValue<List<SaleTransactionModel>> salesAsync = isSearching
                    ? ref.watch(searchSalesWithDueProvider(searchQuery.trim()))
                    : ref.watch(salesWithDueProvider);
                return salesAsync.when(data: (allSales) {
              // Agrupar ventas con dueAmount > 0 por cliente
              Map<String, CustomerDueInfo> customerDuesMap = {};
              Map<String, CustomerDueInfo> supplierDuesMap = {};

              for (var sale in allSales) {
                // Solo procesar ventas con deuda pendiente
                if (sale.dueAmount != null && sale.dueAmount! > 0) {
                  // Usar teléfono como key ya que es más consistente que el nombre
                  final key = sale.customerPhone.isNotEmpty
                      ? sale.customerPhone
                      : sale.customerName;

                  // Determinar si es cliente o proveedor
                  final isSupplier = sale.customerType == 'Proveedores' ||
                                    sale.customerType == 'Proveedor' ||
                                    sale.customerType == 'Supplier';

                  final targetMap = isSupplier ? supplierDuesMap : customerDuesMap;

                  // Determinar el tipo correcto basado en si es proveedor o cliente
                  // Esto corrige el problema de "Unknown" cuando customerType no está definido
                  final correctCustomerType = isSupplier ? 'Proveedor' : 'Cliente';

                  if (targetMap.containsKey(key)) {
                    // Actualizar existente
                    final existing = targetMap[key]!;
                    targetMap[key] = CustomerDueInfo(
                      customerName: existing.customerName,
                      customerPhone: existing.customerPhone,
                      customerType: existing.customerType,
                      totalDue: existing.totalDue + (sale.dueAmount ?? 0),
                      invoiceCount: existing.invoiceCount + 1,
                      pendingSales: [...existing.pendingSales, sale],
                    );
                  } else {
                    // Crear nuevo - usar correctCustomerType en vez de sale.customerType
                    targetMap[key] = CustomerDueInfo(
                      customerName: sale.customerName,
                      customerPhone: sale.customerPhone,
                      customerType: correctCustomerType,
                      totalDue: sale.dueAmount ?? 0,
                      invoiceCount: 1,
                      pendingSales: [sale],
                    );
                  }
                }
              }

              // Convertir a listas de CustomerModel para compatibilidad
              // También mantener la lista de CustomerDueInfo para acceder a pendingSales
              List<CustomerDueInfo> customerDueInfoList = customerDuesMap.values.toList();
              List<CustomerDueInfo> supplierDueInfoList = supplierDuesMap.values.toList();

              List<CustomerModel> customerList = customerDueInfoList
                  .map((info) => info.toCustomerModel())
                  .toList();
              List<CustomerModel> supplierList = supplierDueInfoList
                  .map((info) => info.toCustomerModel())
                  .toList();

              // Ordenar ambas listas por deuda total (mayor a menor)
              // Ordenar CustomerDueInfo
              customerDueInfoList.sort((a, b) => b.totalDue.compareTo(a.totalDue));
              supplierDueInfoList.sort((a, b) => b.totalDue.compareTo(a.totalDue));
              // Ordenar CustomerModel
              customerList.sort((a, b) =>
                  double.parse(b.dueAmount).compareTo(double.parse(a.dueAmount)));
              supplierList.sort((a, b) =>
                  double.parse(b.dueAmount).compareTo(double.parse(a.dueAmount)));

              List<CustomerModel> showAbleCustomer = [];
              List<CustomerModel> showAbleSupplier = [];
              // Listas paralelas de CustomerDueInfo para acceder a pendingSales
              List<CustomerDueInfo> showAbleCustomerDueInfo = [];
              List<CustomerDueInfo> showAbleSupplierDueInfo = [];

              ///___________customer_filter______________________________________________________
              for (int i = 0; i < customerList.length; i++) {
                final element = customerList[i];
                final dueInfo = customerDueInfoList[i];
                final name = element.customerName.replaceAll(' ', '').toLowerCase();
                final phone = element.phoneNumber;

                final search = searchQuery.toLowerCase();

                // Buscar también por # de factura en las pendingSales
                final matchesInvoice = dueInfo.pendingSales.any((sale) =>
                  sale.invoiceNumber.toLowerCase().contains(search));

                if ((name.contains(search) || phone.contains(search) || matchesInvoice)) {
                  if (_filterByDate(element)) {
                    showAbleCustomer.add(element);
                    showAbleCustomerDueInfo.add(dueInfo);
                  }
                } else if (searchQuery == '' && _filterByDate(element)) {
                  showAbleCustomer.add(element);
                  showAbleCustomerDueInfo.add(dueInfo);
                }
              }

              ///___________Suppiler_filter______________________________________________________
              for (int i = 0; i < supplierList.length; i++) {
                final element = supplierList[i];
                final dueInfo = supplierDueInfoList[i];
                final search = searchQuery.toLowerCase();

                // Buscar por nombre, teléfono o # factura
                final matchesInvoice = dueInfo.pendingSales.any((sale) =>
                  sale.invoiceNumber.toLowerCase().contains(search));

                if ((element.customerName
                        .removeAllWhiteSpace()
                        .toLowerCase()
                        .contains(search) ||
                    element.phoneNumber.contains(searchQuery) ||
                    matchesInvoice)) {
                  if (_filterByDate(element)) {
                    showAbleSupplier.add(element);
                    showAbleSupplierDueInfo.add(dueInfo);
                  }
                } else if (searchQuery == '' && _filterByDate(element)) {
                  showAbleSupplier.add(element);
                  showAbleSupplierDueInfo.add(dueInfo);
                }
              }

              // Pagination logic - Updated to handle "All" case
              final List<CustomerModel> paginatedCustomerList;
              final List<CustomerModel> paginatedSupplierList;
              final List<CustomerDueInfo> paginatedCustomerDueInfoList;
              final List<CustomerDueInfo> paginatedSupplierDueInfoList;

              if (_categoryPerPage == -1) {
                // Show all items
                paginatedCustomerList = showAbleCustomer;
                paginatedSupplierList = showAbleSupplier;
                paginatedCustomerDueInfoList = showAbleCustomerDueInfo;
                paginatedSupplierDueInfoList = showAbleSupplierDueInfo;
                _currentPage = 1; // Reset to first page when showing all
              } else {
                // Apply pagination
                final startIndex = (_currentPage - 1) * _categoryPerPage;
                final endIndex = startIndex + _categoryPerPage;
                paginatedCustomerList = showAbleCustomer.sublist(
                  startIndex.clamp(0, showAbleCustomer.length),
                  endIndex.clamp(0, showAbleCustomer.length),
                );
                paginatedSupplierList = showAbleSupplier.sublist(
                  startIndex.clamp(0, showAbleSupplier.length),
                  endIndex.clamp(0, showAbleSupplier.length),
                );
                paginatedCustomerDueInfoList = showAbleCustomerDueInfo.sublist(
                  startIndex.clamp(0, showAbleCustomerDueInfo.length),
                  endIndex.clamp(0, showAbleCustomerDueInfo.length),
                );
                paginatedSupplierDueInfoList = showAbleSupplierDueInfo.sublist(
                  startIndex.clamp(0, showAbleSupplierDueInfo.length),
                  endIndex.clamp(0, showAbleSupplierDueInfo.length),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: kWhite),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              selectedParties == 'Clientes'
                                  ? 'Lista de Cuentas x Cobrar (Clientes)'
                                  : 'Lista de Cuentas x Pagar (Proveedores)',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Divider(
                            thickness: 1.0,
                            color: kNeutral300,
                            height: 1,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ///------------------customer and supplier list----------------------
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: (() {
                                        setState(() {
                                          selectedParties = 'Clientes';
                                          _currentPage =
                                              1; // Reset to first page when switching tabs
                                        });
                                      }),
                                      child: Container(
                                        height: 40,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: selectedParties == 'Clientes'
                                              ? kBlueTextColor
                                              : Colors.white,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(8)),
                                          border: Border.all(
                                              width: 1,
                                              color:
                                                  selectedParties == 'Clientes'
                                                      ? kBlueTextColor
                                                      : Colors.grey),
                                        ),
                                        child: Center(
                                          child: Text(
                                            lang.S.of(context).customers,
                                            style: TextStyle(
                                              color:
                                                  selectedParties == 'Clientes'
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: (() {
                                        setState(() {
                                          selectedParties = 'Proveedores';
                                          _currentPage =
                                              1; // Reset to first page when switching tabs
                                        });
                                      }),
                                      child: Container(
                                        height: 40,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color:
                                              selectedParties == 'Proveedores'
                                                  ? kBlueTextColor
                                                  : Colors.white,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(8)),
                                          border: Border.all(
                                              width: 1,
                                              color: selectedParties ==
                                                      'Proveedores'
                                                  ? kBlueTextColor
                                                  : Colors.grey),
                                        ),
                                        child: Center(
                                          child: Text(
                                            lang.S.of(context).supplier,
                                            style: TextStyle(
                                              color: selectedParties ==
                                                      'Proveedores'
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                ///___________search_and_filters________________________________________________
                                ResponsiveGridRow(rowSegments: 100, children: [
                                  ResponsiveGridCol(
                                    xs: screenWidth < 360
                                        ? 50
                                        : screenWidth > 430
                                            ? 33
                                            : 40,
                                    md: screenWidth < 768
                                        ? 24
                                        : screenWidth < 950
                                            ? 20
                                            : 15,
                                    lg: screenWidth < 1700 ? 15 : 10,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: screenWidth < 570 ? 0 : 10,
                                        bottom: screenWidth < 570 ? 10 : 0,
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 48,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: kNeutral300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                                child: Text(
                                              'Mas-',
                                              style: theme.textTheme.bodyLarge,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                            DropdownButton<int>(
                                              isDense: true,
                                              padding: EdgeInsets.zero,
                                              underline: const SizedBox(),
                                              value: _categoryPerPage,
                                              icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.black,
                                              ),
                                              items: [10, 20, 50, 100, -1]
                                                  .map<DropdownMenuItem<int>>(
                                                      (int value) {
                                                return DropdownMenuItem<int>(
                                                  value: value,
                                                  child: Text(
                                                    value == -1
                                                        ? "Todos"
                                                        : value.toString(),
                                                    style: theme
                                                        .textTheme.bodyLarge,
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  _categoryPerPage =
                                                      newValue ?? 10;
                                                  _currentPage =
                                                      1; // Reset to first page when changing items per page
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Filtro de fecha (Hoy/Todos)
                                  ResponsiveGridCol(
                                    xs: screenWidth < 360
                                        ? 50
                                        : screenWidth > 430
                                            ? 33
                                            : 40,
                                    md: screenWidth < 768
                                        ? 24
                                        : screenWidth < 950
                                            ? 20
                                            : 15,
                                    lg: screenWidth < 1700 ? 15 : 10,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: screenWidth < 570 ? 0 : 10,
                                        bottom: screenWidth < 570 ? 10 : 0,
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 48,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border:
                                              Border.all(color: kNeutral300),
                                        ),
                                        child: DropdownButton<String>(
                                          isDense: true,
                                          padding: EdgeInsets.zero,
                                          underline: const SizedBox(),
                                          value: dateFilter,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.black,
                                          ),
                                          items: ['Todos', 'Hoy']
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              dateFilter = newValue ?? 'Todos';
                                              if (dateFilter != 'Rango') {
                                                dateRange = null;
                                              }
                                              _currentPage = 1;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botón para seleccionar rango de fechas
                                  if (dateFilter == 'Rango')
                                    ResponsiveGridCol(
                                      xs: screenWidth < 360
                                          ? 50
                                          : screenWidth > 430
                                              ? 33
                                              : 40,
                                      md: screenWidth < 768
                                          ? 24
                                          : screenWidth < 950
                                              ? 20
                                              : 15,
                                      lg: screenWidth < 1700 ? 15 : 10,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: screenWidth < 570 ? 0 : 10,
                                          bottom: screenWidth < 570 ? 10 : 0,
                                        ),
                                        child: InkWell(
                                          onTap: () => _selectDateRange(context),
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 48,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              border:
                                                  Border.all(color: kNeutral300),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.calendar_today,
                                                    size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  dateRange != null
                                                      ? '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}'
                                                      : 'Seleccionar rango',
                                                  style:
                                                      theme.textTheme.bodyLarge,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ]),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 20.0,
                                      top: 10.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: const Color(0xFFFEE7CB),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$globalCurrency ${_formatearMonto(totalCustomerDue(customers: selectedParties == 'Clientes' ? showAbleCustomer : showAbleSupplier, selectedCustomerType: selectedParties))}',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        lang.S.of(context).totalDue,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ///__________customer_list_________________________________________________________
                          const SizedBox(height: 20.0),
                          selectedParties == 'Proveedores' &&
                                      showAbleSupplier.isNotEmpty ||
                                  selectedParties != 'Proveedores' &&
                                      showAbleCustomer.isNotEmpty
                              ? Column(
                                  children: [
                                    LayoutBuilder(
                                      builder: (BuildContext context,
                                          BoxConstraints constraints) {
                                        final kWidth = constraints.maxWidth;
                                        return Scrollbar(
                                            controller: _horizontalScroll,
                                            thumbVisibility: true,
                                            radius: const Radius.circular(8),
                                            thickness: 8,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              controller: _horizontalScroll,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth: kWidth,
                                                ),
                                                child: Theme(
                                                  data: theme.copyWith(
                                                    dividerColor:
                                                        Colors.transparent,
                                                    dividerTheme:
                                                        const DividerThemeData(
                                                            color: Colors
                                                                .transparent),
                                                  ),
                                                  child: DataTable(
                                                      border: const TableBorder(
                                                        horizontalInside:
                                                            BorderSide(
                                                          width: 1,
                                                          color: kNeutral300,
                                                        ),
                                                      ),
                                                      dataRowColor:
                                                          const WidgetStatePropertyAll(
                                                              Colors.white),
                                                      headingRowColor:
                                                          WidgetStateProperty
                                                              .all(const Color(
                                                                  0xFFF8F3FF)),
                                                      showBottomBorder: false,
                                                      dividerThickness: 0.0,
                                                      headingTextStyle: theme
                                                          .textTheme
                                                          .titleMedium,
                                                      columns: [
                                                        DataColumn(
                                                            label: Text(lang.S
                                                                .of(context)
                                                                .SL)),
                                                        DataColumn(
                                                            label: Text(lang.S
                                                                .of(context)
                                                                .partyName)),
                                                        DataColumn(
                                                            label: Text(lang.S
                                                                .of(context)
                                                                .partyType)),
                                                        DataColumn(
                                                            label: Text(lang.S
                                                                .of(context)
                                                                .phone)),
                                                        // DataColumn(
                                                        //     label: Text(lang.S
                                                        //         .of(context)
                                                        //         .email)),
                                                        DataColumn(
                                                            label: Text(lang.S
                                                                .of(context)
                                                                .due)),
                                                        DataColumn(
                                                            label: Text(lang.S
                                                                .of(context)
                                                                .collectDue)),
                                                        DataColumn(
                                                            label: Text('Facturas')),
                                                        DataColumn(
                                                            label: Text('Pagos')),
                                                      ],
                                                      rows: List.generate(
                                                          selectedParties ==
                                                                  'Proveedores'
                                                              ? paginatedSupplierList
                                                                  .length
                                                              : paginatedCustomerList
                                                                  .length,
                                                          (index) {
                                                        return DataRow(cells: [
                                                          DataCell(Text(
                                                              (index + 1)
                                                                  .toString())),
                                                          DataCell(Text(
                                                            selectedParties ==
                                                                    'Proveedores'
                                                                ? paginatedSupplierList[
                                                                        index]
                                                                    .customerName
                                                                : paginatedCustomerList[
                                                                        index]
                                                                    .customerName,
                                                          )),
                                                          DataCell(Text(
                                                            selectedParties ==
                                                                    'Proveedores'
                                                                ? paginatedSupplierList[
                                                                        index]
                                                                    .type
                                                                : paginatedCustomerList[
                                                                        index]
                                                                    .type,
                                                          )),
                                                          DataCell(Text(
                                                            selectedParties ==
                                                                    'Proveedores'
                                                                ? paginatedSupplierList[
                                                                        index]
                                                                    .phoneNumber
                                                                : paginatedCustomerList[
                                                                        index]
                                                                    .phoneNumber,
                                                            style: kTextStyle
                                                                .copyWith(
                                                                    color:
                                                                        kGreyTextColor),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          )),
                                                          // DataCell(Text(
                                                          //   selectedParties ==
                                                          //           'Proveedores'
                                                          //       ? paginatedSupplierList[
                                                          //               index]
                                                          //           .emailAddress
                                                          //       : paginatedCustomerList[
                                                          //               index]
                                                          //           .emailAddress,
                                                          //   style: kTextStyle
                                                          //       .copyWith(
                                                          //           color:
                                                          //               kGreyTextColor),
                                                          //   maxLines: 2,
                                                          //   overflow:
                                                          //       TextOverflow
                                                          //           .ellipsis,
                                                          // )),
                                                          DataCell(Text(
                                                            selectedParties ==
                                                                    'Proveedores'
                                                                ? '$globalCurrency${_formatearMonto(paginatedSupplierList[index].dueAmount)}'
                                                                : '$globalCurrency${_formatearMonto(paginatedCustomerList[index].dueAmount)}',
                                                          )),
                                                          DataCell(
                                                            GestureDetector(
                                                              onTap: () async {
                                                                if (await Subscription
                                                                    .subscriptionChecker(
                                                                        item:
                                                                            'Lista de pagos Pendientes')) {
                                                                  showDialog(
                                                                    barrierDismissible:
                                                                        false,
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return StatefulBuilder(
                                                                        builder:
                                                                            (context,
                                                                                setStates) {
                                                                          return Dialog(
                                                                            surfaceTintColor:
                                                                                Colors.white,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                            ),
                                                                            child:
                                                                                ShowDuePaymentPopUp(
                                                                              customerModel: selectedParties == 'Proveedores' ? paginatedSupplierList[index] : paginatedCustomerList[index],
                                                                              pendingSales: selectedParties == 'Proveedores'
                                                                                  ? paginatedSupplierDueInfoList[index].pendingSales
                                                                                  : paginatedCustomerDueInfoList[index].pendingSales,
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  );
                                                                } else {
                                                                  EasyLoading
                                                                      .showError(
                                                                          'Update your plan first,\nDue Collection limit is over.');
                                                                }
                                                              },
                                                              child: const Text(
                                                                'Aplicar pago >',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .blue),
                                                              ),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            GestureDetector(
                                                              onTap: () {
                                                                _mostrarFacturasPendientes(
                                                                    context,
                                                                    selectedParties ==
                                                                            'Proveedores'
                                                                        ? paginatedSupplierList[
                                                                            index]
                                                                            .phoneNumber
                                                                        : paginatedCustomerList[
                                                                            index]
                                                                            .phoneNumber,
                                                                    selectedParties ==
                                                                            'Proveedores'
                                                                        ? paginatedSupplierList[
                                                                            index]
                                                                            .customerName
                                                                        : paginatedCustomerList[
                                                                            index]
                                                                            .customerName);
                                                              },
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: kGreenTextColor.withValues(alpha: 0.2),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: const Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.receipt_long, size: 16, color: kGreenTextColor),
                                                                    SizedBox(width: 4),
                                                                    Text(
                                                                      'Ver facturas',
                                                                      style: TextStyle(
                                                                        color: kGreenTextColor,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Botón Ver Pagos (Historial de abonos)
                                                          DataCell(
                                                            GestureDetector(
                                                              onTap: () {
                                                                final customerPhone = selectedParties == 'Proveedores'
                                                                    ? paginatedSupplierList[index].phoneNumber
                                                                    : paginatedCustomerList[index].phoneNumber;
                                                                final customerName = selectedParties == 'Proveedores'
                                                                    ? paginatedSupplierList[index].customerName
                                                                    : paginatedCustomerList[index].customerName;
                                                                _mostrarHistorialPagos(context, customerPhone, customerName, ref);
                                                              },
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: kBlueTextColor.withValues(alpha: 0.2),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: const Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.history, size: 16, color: kBlueTextColor),
                                                                    SizedBox(width: 4),
                                                                    Text(
                                                                      'Ver pagos',
                                                                      style: TextStyle(
                                                                        color: kBlueTextColor,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ]);
                                                      })),
                                                ),
                                              ),
                                            ));
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _categoryPerPage == -1
                                                  ? '${lang.S.of(context).showing} all ${selectedParties == 'Proveedores' ? showAbleSupplier.length : showAbleCustomer.length} entries'
                                                  : '${lang.S.of(context).showing} ${((_currentPage - 1) * _categoryPerPage + 1).toString()} to ${((_currentPage - 1) * _categoryPerPage + _categoryPerPage).clamp(0, selectedParties == 'Proveedores' ? showAbleSupplier.length : showAbleCustomer.length)} of ${selectedParties == 'Proveedores' ? showAbleSupplier.length : showAbleCustomer.length} entries',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_categoryPerPage !=
                                              -1) // Only show pagination controls when not in "All" mode
                                            Row(
                                              children: [
                                                InkWell(
                                                  overlayColor:
                                                      WidgetStateProperty.all<
                                                          Color>(Colors.grey),
                                                  hoverColor: Colors.grey,
                                                  onTap: _currentPage > 1
                                                      ? () => setState(
                                                          () => _currentPage--)
                                                      : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                4.0),
                                                        topLeft:
                                                            Radius.circular(
                                                                4.0),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(lang.S
                                                          .of(context)
                                                          .previous),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            kBorderColorTextField),
                                                    color: kMainColor,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$_currentPage',
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            kBorderColorTextField),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${(selectedParties == 'Proveedores' ? (showAbleSupplier.length / _categoryPerPage).ceil() : (showAbleCustomer.length / _categoryPerPage).ceil())}',
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  hoverColor: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  overlayColor:
                                                      MaterialStateProperty.all<
                                                          Color>(Colors.blue),
                                                  onTap: _currentPage *
                                                              _categoryPerPage <
                                                          (selectedParties ==
                                                                  'Suppliers'
                                                              ? showAbleSupplier
                                                                  .length
                                                              : showAbleCustomer
                                                                  .length)
                                                      ? () => setState(
                                                          () => _currentPage++)
                                                      : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        bottomRight:
                                                            Radius.circular(
                                                                4.0),
                                                        topRight:
                                                            Radius.circular(
                                                                4.0),
                                                      ),
                                                    ),
                                                    child: const Center(
                                                        child:
                                                            Text('Siguiente')),
                                                  ),
                                                ),
                                              ],
                                            )
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : EmptyWidget(
                                  title:
                                      lang.S.of(context).noDueTransantionFound)
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }, error: (e, stack) {
              return Center(
                child: Text(e.toString()),
              );
            }, loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            });
                    });
                  },
                ),
              ),
            ],
          )),
    );
  }
}

/// Widget separado para el campo de búsqueda que mantiene su propio estado
/// Usa AutomaticKeepAliveClientMixin para evitar que se destruya cuando el padre se reconstruye
class _SearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String hintText;

  const _SearchTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  @override
  State<_SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<_SearchTextField> with AutomaticKeepAliveClientMixin {
  late FocusNode _focusNode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      showCursor: true,
      cursorColor: kTitleColor,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.name,
      decoration: kInputDecoration.copyWith(
        contentPadding: const EdgeInsets.all(10.0),
        hintText: widget.hintText,
        suffixIcon: const Icon(
          FeatherIcons.search,
          color: kNeutral400,
        ),
      ),
    );
  }
}