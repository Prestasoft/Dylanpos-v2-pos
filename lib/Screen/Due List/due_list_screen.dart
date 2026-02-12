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

import '../../Provider/customer_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../services/api_service.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';
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
  String searchItem = '';

  // Controller para mantener el texto de búsqueda cuando se reconstruye la UI
  final TextEditingController _searchController = TextEditingController();

  // Timer para debounce de búsqueda
  Timer? _debounceTimer;

  // Función de búsqueda con debounce (espera 500ms después de dejar de escribir)
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          searchItem = value;
        });
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
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Factura #${factura.invoiceNumber}'),
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

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
          backgroundColor: kDarkWhite,
          body: Consumer(builder: (_, ref, watch) {
            // Si hay búsqueda, usar el provider de búsqueda directa del API (sin límite de 100)
            // Si no hay búsqueda, usar el provider normal con límite de 100
            final bool isSearching = searchItem.trim().isNotEmpty;

            // Usamos salesWithDueProvider o searchSalesWithDueProvider según si hay búsqueda
            AsyncValue<List<SaleTransactionModel>> salesAsync = isSearching
                ? ref.watch(searchSalesWithDueProvider(searchItem.trim()))
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

                final search = searchItem.toLowerCase();

                if ((name.contains(search) || phone.contains(search))) {
                  if (_filterByDate(element)) {
                    showAbleCustomer.add(element);
                    showAbleCustomerDueInfo.add(dueInfo);
                  }
                } else if (searchItem == '' && _filterByDate(element)) {
                  showAbleCustomer.add(element);
                  showAbleCustomerDueInfo.add(dueInfo);
                }
              }

              ///___________Suppiler_filter______________________________________________________
              for (int i = 0; i < supplierList.length; i++) {
                final element = supplierList[i];
                final dueInfo = supplierDueInfoList[i];
                if ((element.customerName
                        .removeAllWhiteSpace()
                        .toLowerCase()
                        .contains(searchItem.toLowerCase()) ||
                    element.phoneNumber.contains(searchItem))) {
                  if (_filterByDate(element)) {
                    showAbleSupplier.add(element);
                    showAbleSupplierDueInfo.add(dueInfo);
                  }
                } else if (searchItem == '' && _filterByDate(element)) {
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
                                  // Campo de búsqueda
                                  ResponsiveGridCol(
                                      xs: 100,
                                      md: 60,
                                      lg: 35,
                                      child: TextFormField(
                                        controller: _searchController,
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        onChanged: (value) {
                                          // Usar debounce para evitar búsquedas en cada tecla
                                          _debounceTimer?.cancel();
                                          _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                                            if (mounted) {
                                              setState(() {
                                                searchItem = value;
                                                _currentPage = 1; // Reset to first page when searching
                                              });
                                            }
                                          });
                                        },
                                        keyboardType: TextInputType.name,
                                        decoration: kInputDecoration.copyWith(
                                          contentPadding:
                                              const EdgeInsets.all(10.0),
                                          hintText:
                                              (lang.S.of(context).searchByName),
                                          suffixIcon: const Icon(
                                            FeatherIcons.search,
                                            color: kNeutral400,
                                          ),
                                        ),
                                      )),
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
                                                                  color: kGreenTextColor.withOpacity(0.2),
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
          })),
    );
  }
}