import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
// Firebase Auth deshabilitado - Usando PostgreSQL API
// import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/ReservationProductModel.dart';
import 'package:salespro_admin/utils/ReservationUtils.dart';
import 'package:intl/intl.dart';
import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Repository/customer_repo.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../services/whatsapp_template_service.dart';
import '../../services/whatsapp_credentials_service.dart';
import '../../Provider/transactions_provider.dart';
import '../../Repository/product_repo.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/customer_model.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/product_model.dart';
import '../../model/reservation_model.dart';
import '../../model/sale_transaction_model.dart';
import '../../model/dress_model.dart';
import '../../subscription.dart';
import '../Product/WarebasedProduct.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';
import 'package:uuid/uuid.dart';
import '../../model/sale_confirmation_model.dart';
import '../../services/audit_service.dart';
import '../../model/audit_model.dart';
import '../../Provider/bank_provider.dart';
import '../../model/bank_model.dart';
import '../../services/deletion_password_service.dart';
import '../../model/transfer_verification_model.dart';
import '../../Provider/transfer_verification_provider.dart';
import '../../model/ncf_model.dart';
import '../../Repository/dgii_repo.dart';

class InventorySales extends StatefulWidget {
  const InventorySales({super.key, this.quotation, this.reservationId});

  final SaleTransactionModel? quotation;
  final String? reservationId;  // ID de la reservación para cargar automáticamente

  @override
  State<InventorySales> createState() => _InventorySalesState();
}

class _InventorySalesState extends State<InventorySales> {
  List<AddToCartModel> cartList = [];
  List<FocusNode> productFocusNode = [];
  bool saleButtonClicked = false;
  double serviceCharge = 0;
  double discountAmount = 0;
  double vatGst = 0;
  bool discountFieldsEnabled = false;
  DateTime selectedDueDate = DateTime.now();
  bool _hasVestimentasFromDialog = false; // NUEVO: detectar si hay vestimentas del diálogo
  bool _hasImpresionEnmarcado = false; // NUEVO: detectar si hay productos impresión/enmarcado

  // NUEVO: Función para determinar el tipo de venta
  String _getSaleType() {
    if (_hasVestimentasFromDialog) {
      return 'adicionales';
    } else if (_hasImpresionEnmarcado) {
      return 'impresiones';
    } else {
      return 'normal';
    }
  }

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();
  TextEditingController discountAmountEditingController = TextEditingController();
  TextEditingController discountPercentageEditingController = TextEditingController();
  TextEditingController nameCodeCategoryController = TextEditingController();

  FocusNode nameFocus = FocusNode();
  final ScrollController horizontalScroll = ScrollController();

  String? selectedUserId;
  String? clientename;

  CustomerModel? selectedUserName;
  String? invoiceNumber;
  String previousDue = "0";
  late String selectedCustomerType = customerType.first;
  late String selectedPaymentOption = paymentItem.first;
  String? selectedBankId;
  String? selectedBankName;

  // Campos para verificación de transferencia
  final TextEditingController transferHolderNameController = TextEditingController();
  final TextEditingController transferReferenceController = TextEditingController();
  String? transferReceiptUrl;
  bool isUploadingReceipt = false;

  // Campos para NCF (Comprobante Fiscal DGII)
  String selectedNcfType = 'SIN';
  final TextEditingController customerRncController = TextEditingController();
  List<NcfTypeModel> ncfTypes = [];
  bool isLoadingNcfTypes = false;

  WareHouseModel? selectedWareHouse;
  String? _lastKnownBranchId; // Para detectar cambios de sucursal
  int i = 0;

  List<String> get paymentItem => ['Efectivo', 'Transferencia', 'Tarjeta'];
  List<String> get customerType => ['Regular', 'Frecuente', 'Corporativo'];

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    payingAmountController.text = '0';
    checkInternet();
    // NOTA: updateDueAmount() se llama después en addPostFrameCallback para asegurar que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateDueAmount();
    });

    if (widget.quotation != null) {
      for (var element in widget.quotation!.productList!) {
        cartList.add(element);
        addFocus();
      }
      discountAmountEditingController.text = widget.quotation!.discountAmount!.toStringAsFixed(2);
      discountAmount = widget.quotation!.discountAmount!;
      serviceCharge = widget.quotation!.discountAmount!;
      selectedUserName?.customerName = widget.quotation!.customerName;
      selectedUserName?.phoneNumber = widget.quotation!.customerPhone;
      selectedUserName?.type = widget.quotation!.customerType;
      // CRÍTICO: Actualizar dueAmount después de cargar cotización
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateDueAmount();
      });
    }

    // Si viene un reservationId, cargar la reservación automáticamente
    if (widget.reservationId != null) {
      debugPrint('🎯 [InventorySales] reservationId recibido: ${widget.reservationId}');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        debugPrint('🚀 [InventorySales] Ejecutando addPostFrameCallback para cargar reservación');
        try {
          await _loadReservationById(widget.reservationId!);
        } catch (e, stack) {
          debugPrint('❌ [InventorySales] Error al cargar reservación: $e');
          debugPrint('❌ [InventorySales] Stack: $stack');
        }
      });
    } else {
      debugPrint('⚠️ [InventorySales] NO se recibió reservationId');
    }

    // Cargar tipos de NCF
    _loadNcfTypes();
  }

  /// Carga los tipos de NCF desde la API
  Future<void> _loadNcfTypes() async {
    setState(() => isLoadingNcfTypes = true);
    try {
      final dgiiRepo = DgiiRepository();
      final types = await dgiiRepo.getNcfTypes();
      setState(() {
        ncfTypes = types;
        isLoadingNcfTypes = false;
      });
    } catch (e) {
      debugPrint('Error cargando tipos NCF: $e');
      // Usar tipos por defecto si falla la carga
      setState(() {
        ncfTypes = [
          NcfTypeModel(code: 'SIN', name: 'Sin Comprobante', requiresRnc: false, appliesItbis: false),
          NcfTypeModel(code: 'B01', name: 'Crédito Fiscal', requiresRnc: true, appliesItbis: true),
          NcfTypeModel(code: 'B02', name: 'Consumidor Final', requiresRnc: false, appliesItbis: true),
          NcfTypeModel(code: 'B14', name: 'Regímenes Especiales', requiresRnc: true, appliesItbis: true),
          NcfTypeModel(code: 'B15', name: 'Gubernamental', requiresRnc: true, appliesItbis: true),
        ];
        isLoadingNcfTypes = false;
      });
    }
  }

  /// Verifica si el tipo de NCF seleccionado requiere RNC
  bool get ncfRequiresRnc {
    final type = ncfTypes.firstWhere(
      (t) => t.code == selectedNcfType,
      orElse: () => NcfTypeModel(code: 'SIN', name: 'Sin Comprobante'),
    );
    return type.requiresRnc;
  }

  /// Obtiene la tasa de ITBIS del tipo de NCF seleccionado
  double get ncfItbisRate {
    final type = ncfTypes.firstWhere(
      (t) => t.code == selectedNcfType,
      orElse: () => NcfTypeModel(code: 'SIN', name: 'Sin Comprobante'),
    );
    return type.appliesItbis ? type.itbisRate : 0.0;
  }

  /// Carga una reservación por ID desde la API y la agrega al carrito
  Future<void> _loadReservationById(String reservationId) async {
    debugPrint('🔄 [_loadReservationById] Iniciando carga de reservación: $reservationId');
    try {
      EasyLoading.show(status: 'Cargando reservación...');

      final apiService = ApiService();
      debugPrint('🌐 [_loadReservationById] Llamando API: reservations/$reservationId');
      final response = await apiService.get('reservations/$reservationId');
      debugPrint('📥 [_loadReservationById] Response success: ${response.success}');
      debugPrint('📥 [_loadReservationById] Response data: ${response.data}');

      if (!response.success || response.data == null) {
        EasyLoading.showError('No se pudo cargar la reservación');
        return;
      }

      final rawData = Map<String, dynamic>.from(response.data);
      // La API devuelve los datos anidados en 'reservation'
      final reservation = rawData.containsKey('reservation')
          ? Map<String, dynamic>.from(rawData['reservation'])
          : rawData;

      final service = reservation['service'] as Map<String, dynamic>?;
      // Buscar vestidos en múltiples lugares posibles (la API usa diferentes campos)
      List<dynamic> dresses = [];
      if ((reservation['dresses_data'] as List<dynamic>?)?.isNotEmpty == true) {
        dresses = reservation['dresses_data'] as List<dynamic>;
      } else if ((reservation['dresses_full'] as List<dynamic>?)?.isNotEmpty == true) {
        dresses = reservation['dresses_full'] as List<dynamic>;
      } else if ((reservation['dress_ids'] as List<dynamic>?)?.isNotEmpty == true) {
        dresses = reservation['dress_ids'] as List<dynamic>;
      } else if ((reservation['multiple_dress'] as List<dynamic>?)?.isNotEmpty == true) {
        dresses = reservation['multiple_dress'] as List<dynamic>;
      }
      final aditionals = reservation['aditionals'] as List<dynamic>? ?? [];

      // Debug: Mostrar datos completos de la reservación
      debugPrint('📦 [_loadReservationById] rawData keys: ${rawData.keys.toList()}');
      debugPrint('📦 [_loadReservationById] reservation keys: ${reservation.keys.toList()}');
      debugPrint('👗 [_loadReservationById] dresses encontrados (${dresses.length}): $dresses');
      debugPrint('🎁 [_loadReservationById] service: $service');
      debugPrint('💰 [_loadReservationById] package_price: ${reservation['package_price']}');
      debugPrint('👤 [_loadReservationById] client_id: ${reservation['client_id']}');
      debugPrint('👤 [_loadReservationById] customer_id: ${reservation['customer_id']}');

      // Crear el modelo de reservación para el carrito
      // Si hay múltiples vestidos, usar el formato compuesto
      if (dresses.length > 1) {
        // Múltiples vestidos - usar ReservationProductCompositeModel
        final multipleDress = dresses.map((d) {
          if (d is Map) {
            return {
              'dress_id': d['dress_id'] ?? d['id'],
              'dress_name': d['dress_name'] ?? d['name'],
              'dress_price': d['dress_price'] ?? d['price'] ?? d['rental_price'],
            };
          }
          return d;
        }).toList();

        // Calcular precio total de todos los vestidos
        double totalDressPrice = 0.0;
        for (var d in dresses) {
          if (d is Map) {
            final dPrice = double.tryParse(d['dress_price']?.toString() ?? '0') ?? 0.0;
            totalDressPrice += dPrice;
          }
        }
        debugPrint('💵 [_loadReservationById] Total dress price (multiple): $totalDressPrice');

        final compositeModel = ReservationProductCompositeModel.fromMap({
          'id': reservationId,
          'service_id': service?['id'] ?? reservation['service_id'] ?? '',
          'service_name': 'Renta de Vestimenta', // Nombre genérico para renta
          'client_id': reservation['client_id'] ?? reservation['customer_id'] ?? '',
          'multiple_dress': multipleDress,
          'branch_id': reservation['branch_id'] ?? '',
          'reservation_date': reservation['reservation_date'] ?? '',
          'reservation_time': reservation['reservation_time'] ?? '',
          'price': totalDressPrice > 0 ? totalDressPrice : double.tryParse(reservation['package_price']?.toString() ?? '0') ?? 0.0,
          'created_at': reservation['created_at'],
          'updated_at': reservation['updated_at'],
          'duration': service?['duration'] ?? {},
          'package_price': totalDressPrice > 0 ? totalDressPrice : double.tryParse(reservation['package_price']?.toString() ?? '0.0'),
          'descricpion': service?['description'] ?? reservation['notes'] ?? '',
        });

        _addReservationCompositeToCart(compositeModel);
      } else {
        // Un solo vestido o ninguno - usar ReservationProductModel
        final firstDress = dresses.isNotEmpty ? dresses.first : null;

        // Obtener el precio del vestido desde dresses_data o package_price
        double dressPrice = 0.0;
        if (firstDress != null) {
          dressPrice = double.tryParse(firstDress['dress_price']?.toString() ?? '') ??
                       double.tryParse(firstDress['price']?.toString() ?? '') ??
                       double.tryParse(firstDress['rental_price']?.toString() ?? '') ?? 0.0;
        }
        // Fallback al package_price si no hay precio en el vestido
        if (dressPrice == 0.0) {
          dressPrice = double.tryParse(reservation['package_price']?.toString() ?? '0') ?? 0.0;
        }

        final dressName = firstDress?['dress_name'] ?? firstDress?['name'] ?? reservation['dress_name'] ?? 'Vestido';

        debugPrint('👗 [_loadReservationById] firstDress: $firstDress');
        debugPrint('💵 [_loadReservationById] dressPrice: $dressPrice');
        debugPrint('📝 [_loadReservationById] dressName: $dressName');

        final reservationModel = ReservationProductModel.fromMap({
          'id': reservationId,
          'service_id': service?['id'] ?? reservation['service_id'] ?? '',
          'service_name': 'Renta', // Prefijo corto
          'client_id': reservation['client_id'] ?? reservation['customer_id'] ?? '',
          'dress_id': firstDress?['dress_id'] ?? firstDress?['id'] ?? reservation['dress_id'] ?? '',
          'dress_name': dressName,
          'branch_id': reservation['branch_id'] ?? '',
          'reservation_date': reservation['reservation_date'] ?? '',
          'reservation_time': reservation['reservation_time'] ?? '',
          'price': dressPrice, // Usar el precio del vestido
          'created_at': reservation['created_at'],
          'updated_at': reservation['updated_at'],
          'duration': service?['duration'] ?? {},
          'package_price': dressPrice, // Usar el precio del vestido
          'descricpion': service?['description'] ?? reservation['notes'] ?? '',
        });

        debugPrint('🛒 [_loadReservationById] Agregando al carrito: ${reservationModel.serviceName} - ${reservationModel.dressName} @ ${reservationModel.packagePrice}');

        _addReservationToCart(reservationModel);
      }

      // Cargar adicionales si los hay
      if (aditionals.isNotEmpty) {
        await _addReservationAdditionalsToCart(reservationId);
      }

      // Cargar información del cliente si está disponible
      // IMPORTANTE: Buscar primero en client_id porque customer_id a veces viene null
      final customerId = reservation['client_id'] ?? reservation['customer_id'];
      debugPrint('👤 [_loadReservationById] customerId final: $customerId');
      if (customerId != null && customerId.toString().isNotEmpty) {
        try {
          debugPrint('🌐 [_loadReservationById] Llamando API: customers/$customerId');
          final customerResponse = await apiService.get('customers/$customerId');
          debugPrint('📥 [_loadReservationById] Customer response: ${customerResponse.success}');
          if (customerResponse.success && customerResponse.data != null) {
            final customerData = Map<String, dynamic>.from(customerResponse.data['customer'] ?? customerResponse.data);
            debugPrint('✅ [_loadReservationById] Cliente cargado: ${customerData['customer_name'] ?? customerData['name']}');
            setState(() {
              selectedUserId = customerId;
              selectedUserName = CustomerModel.fromJson(customerData);
              clientename = selectedUserName?.customerName;
            });
          }
        } catch (e) {
          debugPrint('❌ [_loadReservationById] Error al cargar cliente: $e');
        }
      } else {
        debugPrint('⚠️ [_loadReservationById] No hay customerId en la reservación');
      }

      EasyLoading.dismiss();
      EasyLoading.showSuccess('Reservación cargada');
      debugPrint('✅ [_loadReservationById] Reservación cargada completamente');

    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error al cargar reservación: ${e.toString()}');
      print('Error en _loadReservationById: $e');
    }
  }

  Future<List<DressModel>> _fetchDresses() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('dresses', queryParams: {
        'limit': '1000',
      });

      if (!response.success || response.data == null) {
        return [];
      }

      final dressesList = response.data['dresses'] as List<dynamic>? ?? [];
      final List<DressModel> dresses = [];

      for (var data in dressesList) {
        try {
          final dressData = Map<String, dynamic>.from(data);
          if (dressData.containsKey('name')) {
            dresses.add(DressModel.fromRealtimeDB(dressData, dressData['id']?.toString() ?? ''));
          }
        } catch (e) {
          print('Error al parsear vestido: $e');
        }
      }

      return dresses;
    } on TimeoutException {
      EasyLoading.showError('Tiempo de espera agotado al cargar vestidos');
      return [];
    } catch (e) {
      print('Error al cargar vestidos: $e');
      EasyLoading.showError('Error al cargar vestidos');
      return [];
    }
  }

  void _addDressToCart(DressModel dress) {
  final existingIndex = cartList.indexWhere(
    (item) => item.productId == dress.id && item.isDress == true
  );

  setState(() {
    if (existingIndex >= 0) {
      cartList[existingIndex].quantity += 1;
      cartList[existingIndex].subTotal = 
          (cartList[existingIndex].quantity * dress.price).toString();
      _hasVestimentasFromDialog = true; // MARCAR: se agregó vestimenta desde diálogo
    } else {
      cartList.add(dress.toCartItem());
      productFocusNode.add(FocusNode());
      _hasVestimentasFromDialog = true; // MARCAR: se agregó vestimenta desde diálogo
    }
    updateDueAmount();
  });
}

  Future<void> _showDressSelectionDialog() async {
  EasyLoading.show(status: 'Cargando vestidos...');
  
  try {
    final allDresses = await _fetchDresses();
    EasyLoading.dismiss();

    if (allDresses.isEmpty) {
      EasyLoading.showInfo('No se encontraron vestidos disponibles');
      return;
    }

    // Variable para manejar la búsqueda
    String searchQuery = '';
    List<DressModel> filteredDresses = List.from(allDresses);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: 600,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seleccionar Vestido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, categoría o estado...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      searchQuery = '';
                                      filteredDresses = List.from(allDresses);
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                            filteredDresses = allDresses.where((dress) {
                              return dress.name.toLowerCase().contains(searchQuery) ||
                                  dress.category.toLowerCase().contains(searchQuery) ||
                                  dress.state.toLowerCase().contains(searchQuery) ||
                                  dress.subcategory.toLowerCase().contains(searchQuery);
                            }).toList();
                          });
                        },
                      ),
                    ),

                    // Filtros rápidos
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Disponibles'),
                            selected: false,
                            onSelected: (selected) {
                              setState(() {
                                filteredDresses = allDresses
                                    .where((dress) => dress.available)
                                    .toList();
                              });
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              'Todos',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                            selectedColor: const Color.fromARGB(255, 204, 109, 26),
                            selected: true,
                            onSelected: (selected) {
                              setState(() {
                                filteredDresses = List.from(allDresses);
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Lista de vestidos
                    Expanded(
                      child: filteredDresses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 50, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No se encontraron vestidos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (searchQuery.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          searchQuery = '';
                                          filteredDresses = List.from(allDresses);
                                        });
                                      },
                                      child: Text('Limpiar búsqueda'),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: filteredDresses.length,
                              itemBuilder: (context, index) {
                                final dress = filteredDresses[index];
                                final primaryImage = dress.images.isNotEmpty
                                    ? dress.images.first
                                    : 'https://via.placeholder.com/150';

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        primaryImage,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: Icon(Icons.image_not_supported),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      dress.name,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '\$${dress.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: dress.available
                                                    ? Colors.green[50]
                                                    : Colors.red[50],
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: dress.available
                                                      ? Colors.green
                                                      : Colors.red,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                dress.available
                                                    ? 'Disponible'
                                                    : 'No disponible',
                                                style: TextStyle(
                                                  color: dress.available
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        if (dress.category.isNotEmpty)
                                          Text(
                                            'Categoría: ${dress.category}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        if (dress.subcategory.isNotEmpty)
                                          Text(
                                            'Subcategoría: ${dress.subcategory}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        Text(
                                          'Estado: ${dress.state}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.add_shopping_cart,
                                          color: Theme.of(context).primaryColor),
                                      onPressed: dress.available
                                          ? () {
                                              _addDressToCart(dress);
                                              Navigator.pop(context);
                                            }
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } catch (e) {
    EasyLoading.dismiss();
    print('Error en diálogo de vestidos: $e');
    EasyLoading.showError('Error al cargar vestidos');
  }
}

  Future<void> _sendPdfViaWhatsApp({
    required String phoneNumber,
    required Uint8List pdfData,
    required String invoiceNumber,
    required String customerName,
  }) async {
    try {
      // Validar número de teléfono
      // final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      // if (!cleanedPhone.startsWith('+')) {
      //   throw Exception('El número debe incluir código de país (ej: +1...)');
      // }

      EasyLoading.show(status: 'Preparando envío...');

      // Codificar PDF en Base64
      final pdfBase64 = base64Encode(pdfData);

      // Crear mensaje usando plantilla de WhatsApp
      final template = await WhatsAppTemplateService.getTemplate('invoice_caption');
      final safeMessage = WhatsAppTemplateService.replaceVariables(template, {
        'nombre': customerName,
        'factura': invoiceNumber,
      });

      // Obtener credenciales dinámicas de WhatsApp
      final credentials = await WhatsAppCredentialsService.getCredentials();

      final body = {
        'token': credentials.token,
        'to': phoneNumber,
        'filename': 'Comprobante_${invoiceNumber}.pdf',
        'document': pdfBase64,
        'caption': safeMessage,
      };

      final url = Uri.parse(credentials.getApiUrl('messages/document'));
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
      
      EasyLoading.show(status: 'Enviando...');
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Enviado exitosamente');
      } else {
        throw Exception('Error en API: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      EasyLoading.showError('Error al enviar: ${e.toString().replaceAll('\n', ' ')}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      EasyLoading.dismiss();
    }
  }

  Future<void> _sendConfirmationLinkViaWhatsApp({
    required String phoneNumber,
    required String customerName,
    required String confirmationLink,
  }) async {
    try {
      EasyLoading.show(status: 'Enviando confirmación...');

      // Crear mensaje usando plantilla de WhatsApp
      final template = await WhatsAppTemplateService.getTemplate('confirmation_link');
      final message = WhatsAppTemplateService.replaceVariables(template, {
        'nombre': customerName,
        'link': confirmationLink,
      });

      // Obtener credenciales dinámicas de WhatsApp
      final credentials = await WhatsAppCredentialsService.getCredentials();

      final body = {
        'token': credentials.token,
        'to': phoneNumber,
        'body': message,
      };

      final url = Uri.parse(credentials.getApiUrl('messages/chat'));
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Mensaje de confirmación enviado');
      } else {
        throw Exception('Error en WhatsApp API: ${response.body}');
      }
    } catch (e) {
      EasyLoading.showError('Error al enviar link: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      EasyLoading.dismiss();
    }
  }

  void updateDueAmount() {
    setState(() {
      double total = double.parse(
        (double.parse(getTotalAmount()) + serviceCharge - discountAmount + vatGst).toStringAsFixed(1),
      );
      double paidAmount = double.tryParse(payingAmountController.text) ?? 0;
      if (paidAmount > total) {
        changeAmountController.text = (paidAmount - total).toString();
        dueAmountController.text = '0';
      } else {
        dueAmountController.text = (total - paidAmount).abs().toString();
        changeAmountController.text = '0';
      }
    });
  }

  void showReservationSelection(String clientId) {
  final TextStyle smallGreyTextStyle = TextStyle(
    fontSize: 13,
    color: Colors.grey[700],
  );

  final TextStyle smallGreyTextStyleBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final reservations = ref.watch(ReservaPendientProvider(clientId));
          return reservations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (reservations) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: 500,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Seleccionar Reserva',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                              ),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: reservations.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final full = reservations[index];
                            final reservation = full.reservation;
                            final dress = full.dress;
                            final service = full.service;
                            final hasAdditionals = reservation['aditionals'] != null && 
                                (reservation['aditionals'] as List).isNotEmpty;

                            final rawImages = dress?['images'] ?? '';
                            final dressImageUrl = rawImages.toString().split(',').first.trim().replaceAll(RegExp(r'[\[\]"]'), '');

                            bool isCommonReservation = full.multipleDress.isEmpty;

                            if (isCommonReservation) {
                              final reservationModel = ReservationProductModel.fromMap({
                                'id': full.id,
                                'service_id': service?['id'] ?? '',
                                'service_name': service?['name'] ?? 'Servicio',
                                'client_id': clientId,
                                'dress_id': dress?['id'] ?? '',
                                'dress_name': dress?['name'] ?? 'Vestido',
                                'branch_id': reservation['branch_id'] ?? '',
                                'reservation_date': reservation['reservation_date'] ?? '',
                                'reservation_time': reservation['reservation_time'] ?? '',
                                'price': service != null && service['price'] != null ? 
                                    (service['price'] is num ? (service['price'] as num).toDouble() : 0.0) : 0.0,
                                'created_at': reservation['created_at'],
                                'updated_at': reservation['updated_at'],
                                'duration': service?['duration'] ?? {},
                                'package_price': double.tryParse(reservation['package_price'] ?? '0.0'),
                                'descricpion': service?['description'] ?? '',
                              });

                              return InkWell(
                                onTap: () {
                                  _addReservationToCart(reservationModel);
                                  if (hasAdditionals) {
                                    _addReservationAdditionalsToCart(full.id);
                                  }
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  child: Row(
                                    children: [
                                      // Dress image
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            dressImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${service?['name'] ?? 'Servicio'} - ${dress?['name'] ?? 'Vestido'}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasAdditionals)
                                                  Container(
                                                    margin: EdgeInsets.only(left: 8),
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[100],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Con adicionales',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange[800],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('📅 Fecha: ${reservation['reservation_date']} a las ${reservation['reservation_time']}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('🏬 Sucursal: ${reservation['branch_id']}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('👗 Vestido: ${dress?['name'] ?? 'Sin Vestimenta'}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('🔖 Categoría: ${dress?['category'] ?? '-'}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('🛎️ Servicio: ${service?['name'] ?? '-'}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('⏱️ Duración: ${ReservationUtils.formatDuration(service?['duration'])}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('📝 Descripción:\n${service?['description'] ?? '-'}', style: smallGreyTextStyle),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            reservationModel.packagePrice > 0 ? 
                                                '\$${reservationModel.packagePrice.toStringAsFixed(2)}' : 
                                                '\$${reservationModel.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.add_shopping_cart,
                                              size: 18,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              final reservationModel = ReservationProductCompositeModel.fromMap({
                                'id': full.id,
                                'service_id': service?['id'] ?? '',
                                'service_name': service?['name'] ?? 'Servicio',
                                'client_id': clientId,
                                'reservation_date': reservation['reservation_date'] ?? '',
                                'reservation_time': reservation['reservation_time'] ?? '',
                                'price': service != null && service['price'] != null ? 
                                    (service['price'] is num ? (service['price'] as num).toDouble() : 0.0) : 0.0,
                                'created_at': reservation['created_at'],
                                'updated_at': reservation['updated_at'],
                                'duration': service?['duration'] ?? {},
                                'dress_info': full.multipleDress,
                                'package_price': double.tryParse(reservation['package_price'] ?? '0.0'),
                                'descricpion': service?['description'] ?? '',
                              });

                              return InkWell(
                                onTap: () {
                                  _addReservationCompositeToCart(reservationModel);
                                  if (hasAdditionals) {
                                    _addReservationAdditionalsToCart(full.id);
                                  }
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            dressImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${service?['name'] ?? 'Servicio'} - ${dress?['name'] ?? 'Combo de Vestimentas'}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasAdditionals)
                                                  Container(
                                                    margin: EdgeInsets.only(left: 8),
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[100],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Con adicionales',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange[800],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('📅 Fecha: ${reservation['reservation_date']} a las ${reservation['reservation_time']}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('👗 Vestimentas Reservadas:', style: smallGreyTextStyleBold),
                                            const SizedBox(height: 2),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8, right: 8),
                                              child: _showDressesOption(full.multipleDress),
                                            ),
                                            Text('🔖 Categoría: ${service?['category'] ?? '-'}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('🛎️ Servicio: ${service?['name'] ?? '-'}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('⏱️ Duración: ${ReservationUtils.formatDuration(service?['duration'])}', style: smallGreyTextStyle),
                                            const SizedBox(height: 2),
                                            Text('📝 Descripción:\n${service?['description'] ?? '-'}', style: smallGreyTextStyle),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            reservationModel.packagePrice > 0 ? 
                                                '\$${reservationModel.packagePrice.toStringAsFixed(2)}' : 
                                                '\$${reservationModel.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.add_shopping_cart,
                                              size: 18,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

  // void _addReservationToCart(ReservationProductModel reservation) {
  //   setState(() {
  //     cartList.add(
  //       reservation.toCartItem()..reservationId = reservation.id, // Asignar ID
  //     );
  //     addFocus();
  //     updateDueAmount();
  //   });
  // }

  // void _addReservationCompositeToCart(ReservationProductCompositeModel reservation) {
  //   setState(() {
  //     cartList.add(
  //       reservation.toCartCompositeItem()..reservationId = reservation.id, // Asignar ID
  //     );
  //     addFocus();
  //     updateDueAmount();
  //   });
  // }
  void _addReservationToCart(ReservationProductModel reservation) {
  setState(() {
    cartList.add(
      reservation.toCartItem()..reservationId = reservation.id,
    );
    // Agregar un nuevo FocusNode para el nuevo item
    productFocusNode.add(FocusNode());
    addFocus();
    updateDueAmount();
  });
}

void _addReservationCompositeToCart(ReservationProductCompositeModel reservation) {
  setState(() {
    cartList.add(
      reservation.toCartCompositeItem()..reservationId = reservation.id,
    );
    // Agregar un nuevo FocusNode para el nuevo item
    productFocusNode.add(FocusNode());
    addFocus();
    updateDueAmount();
  });
}

Future<void> _addReservationAdditionalsToCart(String reservationId) async {
  try {
    final apiService = ApiService();
    final response = await apiService.get('reservations/$reservationId');

    if (response.success && response.data != null) {
      final reservationData = Map<String, dynamic>.from(response.data);
      final aditionals = reservationData['aditionals'] as List<dynamic>?;

      if (aditionals != null && aditionals.isNotEmpty) {
        setState(() {
          for (var additional in aditionals) {
            if (additional is Map) {
              final additionalModel = _createAdditionalModel(additional, reservationId);
              cartList.add(additionalModel);
              // Agregar un FocusNode por cada adicional
              productFocusNode.add(FocusNode());
            }
          }
          updateDueAmount();
        });
      }
    }
  } catch (e) {
    print('Error al cargar adicionales: $e');
  }
}

AddToCartModel _createAdditionalModel(Map additionalData, String mainReservationId) {
  // Obtener información del vestido
  String dressName = 'Vestido adicional';
  String dressId = '';

  // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
  final dressData = additionalData['multiple_dress'] ?? additionalData['dress_ids'];
  if (dressData is List && dressData.isNotEmpty) {
    final firstDress = dressData.first;
    dressName = firstDress['dress_name'] ?? dressName;
    dressId = firstDress['dress_id'] ?? dressId;
  } else if (additionalData['dress_id'] != null) {
    dressId = additionalData['dress_id'].toString();
    dressName = additionalData['dress_name']?.toString() ?? 'Vestido adicional';
  }

  return AddToCartModel(
    productName: 'Adicional - $dressName',
    productId: mainReservationId, // Usamos el ID de la reserva principal como productId
    quantity: 1,
    subTotal: additionalData['package_price']?.toString() ?? '0.0',
    productPurchasePrice: 0,
    warehouseName: additionalData['note']?.toString() ?? '(Item adicional de reserva)',
    warehouseId: 'reserva-warehouse',
    unitPrice: double.tryParse(additionalData['package_price']?.toString() ?? '0.0') ?? 0.0,
    productImage: 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672',
    taxType: 'none',
    margin: 0,
    excTax: 0,
    incTax: 0,
    groupTaxName: 'Sin impuesto',
    groupTaxRate: 0,
    subTaxes: [],
    isReservation: true,
    isAdditional: true,
    mainReservationId: mainReservationId,
    reservationId: mainReservationId,
    dressId: dressId,
    serviceId: additionalData['service_id']?.toString() ?? '',
    descricpion: additionalData['note']?.toString() ?? '(Item adicional de reserva)',
  );
}

  Future<void> checkInternet() async {
    bool isDeviceConnected = await InternetConnection().hasInternetAccess;
    if (!isDeviceConnected) {
      showDialogBox();
      setState(() => isAlertSet = true);
    }
  }

  /// Método para seleccionar y subir comprobante de transferencia
  Future<void> _pickTransferReceipt() async {
    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];

          // Verificar formato (solo formatos web compatibles)
          final fileName = file.name.toLowerCase();
          final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
          final isValidFormat = allowedExtensions.any((ext) => fileName.endsWith(ext));

          if (!isValidFormat) {
            EasyLoading.showError('Formato no soportado. Use JPG, PNG, GIF o WebP.\nArchivos HEIC de iPhone no son compatibles.');
            return;
          }

          // Verificar tamaño (max 5MB)
          if (file.size > 5 * 1024 * 1024) {
            EasyLoading.showError('La imagen no debe superar 5MB');
            return;
          }

          setState(() => isUploadingReceipt = true);

          try {
            final reader = html.FileReader();
            reader.readAsDataUrl(file);

            await reader.onLoad.first;
            final base64Data = reader.result as String;

            // Subir al servidor API (en lugar de Firebase Storage)
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final safeFileName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
            final filename = 'receipt_${timestamp}_$safeFileName';

            final apiService = ApiService();
            final response = await apiService.post('uploads/transfer-receipt', {
              'base64Data': base64Data.split(',').last,
              'filename': filename,
              'contentType': file.type,
            });

            debugPrint('🔵 [Transfer] Respuesta upload: ${response.data}');

            if (response.success && response.data != null) {
              // Manejar ambas estructuras de respuesta:
              // 1. {url: "..."} - directo
              // 2. {success: true, data: {url: "..."}} - anidado
              String? downloadUrl;

              if (response.data['url'] != null) {
                downloadUrl = response.data['url'] as String;
              } else if (response.data['data'] != null && response.data['data']['url'] != null) {
                downloadUrl = response.data['data']['url'] as String;
              }

              if (downloadUrl != null && downloadUrl.isNotEmpty) {
                setState(() {
                  transferReceiptUrl = downloadUrl;
                  isUploadingReceipt = false;
                });
                EasyLoading.showSuccess('Comprobante cargado');
                debugPrint('✅ [Transfer] URL obtenida: $downloadUrl');
              } else {
                throw Exception('URL del comprobante no recibida');
              }
            } else {
              throw Exception(response.message ?? 'Error al subir imagen');
            }
          } catch (e) {
            setState(() => isUploadingReceipt = false);
            EasyLoading.showError('Error al subir imagen: $e');
          }
        }
      });
    } catch (e) {
      EasyLoading.showError('Error al seleccionar imagen');
    }
  }

  /// NOTA: Esta función ahora devuelve un placeholder temporal.
  /// El número de factura REAL se genera atómicamente en el servidor PostgreSQL
  /// para evitar duplicados cuando múltiples usuarios facturan simultáneamente.
  /// El número real se obtiene de la respuesta del API POST /sales
  Future<int> getLastInvoiceNumber() async {
    // Devuelve un placeholder - el servidor genera el número real atómicamente
    print('DEBUG: Generando placeholder para invoiceNumber (el servidor generará el real)');
    return 0; // El servidor asignará el número real
  }

  bool isAlertSet = false;
  void showDialogBox() => showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(lang.S.of(context).noConnection),
          content: Text(lang.S.of(context).pleaseCheckYourInternetConnectivity),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                GoRouter.of(context).pop(lang.S.of(context).cancel);
                setState(() => isAlertSet = false);
                bool isDeviceConnected = await InternetConnection().hasInternetAccess;
                if (!isDeviceConnected && isAlertSet == false) {
                  showDialogBox();
                  setState(() => isAlertSet = true);
                }
              },
              child: Text(lang.S.of(context).tryAgain),
            ),
          ],
        ),
      );

  String getTotalAmount() {
    double total = 0.0;
    for (var item in cartList) {
      final subTotalValue = double.tryParse(item.subTotal?.toString() ?? '0') ?? 0.0;
      total = total + (subTotalValue * item.quantity);
    }
    return total.toStringAsFixed(2);
  }

  bool uniqueCheck(String code) {
    bool isUnique = false;
    for (var item in cartList) {
      if (item.productId == code) {
        if (item.quantity < item.stock!.toInt()) {
          item.quantity += 1;
        } else {
          EasyLoading.showError(lang.S.of(context).outOfStock);
        }
        isUnique = true;
        break;
      }
    }
    return isUnique;
  }

  dynamic productPriceChecker({required ProductModel product, required String customerType}) {
    if (customerType == "Regular") {
      return product.productSalePrice;
    } else if (customerType == "Frecuente") {
      return product.productWholeSalePrice == '' ? '0' : product.productWholeSalePrice;
    } else if (customerType == "Corporativo") {
      return product.productDealerPrice == '' ? '0' : product.productDealerPrice;
    } else if (customerType == "Guest") {
      return product.productSalePrice;
    }
  }

  Future<void> _selectedDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDueDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  void addFocus() {
    FocusNode f = FocusNode();
    f.addListener(() {
      if (!f.hasFocus) {
        updateDueAmount();
      }
    });
    productFocusNode.add(f);
  }

  Widget _showDressesOption(dynamic dress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dress.map<Widget>((item) {
        final dressName = item['dress_name'] ?? 'Sin nombre';
        final branchId = item['branch_id'] ?? 'Sin sucursal';

        return _buildInfoItem(dressName, branchId); // Asegúrate que retorne un Widget
      }).toList(),
    );
  }

  Widget _buildInfoItem(String dress, String branch) {
    return Text('* ' + dress + ' - ' + branch,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700], // Esto no puede ser const
        ));
  }

  DropdownButton<String> getOption() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentItem) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedPaymentOption,
      onChanged: (value) {
        setState(() {
          selectedPaymentOption = value!;
          // Reset bank selection and transfer fields when payment method changes
          if (value != 'Transferencia') {
            selectedBankId = null;
            selectedBankName = null;
            transferHolderNameController.clear();
            transferReferenceController.clear();
            transferReceiptUrl = null;
          }
        });
      },
    );
  }

  // Añade al pubspec.yaml:
  // searchable_dropdown: ^1.1.3

  // Implementation of the search dialog with a modern look
  // AHORA USA BÚSQUEDA API EN LUGAR DE FILTRADO LOCAL
  Future<CustomerModel?> _showCustomerSearchDialog(
    BuildContext context,
    List<CustomerModel> initialCustomers,
    List<ReservationModel> reservations,
  ) async {
    TextEditingController searchController = TextEditingController();
    List<CustomerModel> displayedCustomers = List.from(initialCustomers);
    bool switchValue = false;
    bool isLoading = false;
    Timer? debounceTimer;
    final CustomerRepo customerRepo = CustomerRepo();

    return showDialog<CustomerModel>(
      context: context,
      builder: (BuildContext context) {
        // Obtenemos el tamaño de la pantalla
        final screenSize = MediaQuery.of(context).size;
        return StatefulBuilder(
          builder: (context, setState) {
            // Función para filtrar por reservas pendientes
            List<CustomerModel> filterByReservations(List<CustomerModel> customers) {
              if (!switchValue) return customers;
              return customers.where((customer) {
                return reservations.any(
                  (res) => res.clientId == customer.id || res.clientId == customer.phoneNumber,
                );
              }).toList();
            }

            // Función para buscar clientes via API
            Future<void> searchCustomers(String query) async {
              setState(() => isLoading = true);

              try {
                List<CustomerModel> results;
                if (query.isEmpty) {
                  // Si no hay búsqueda, cargar todos los clientes
                  results = await customerRepo.getAllCustomer();
                } else {
                  // Búsqueda via API
                  results = await customerRepo.searchCustomers(query);
                }

                setState(() {
                  displayedCustomers = filterByReservations(results);
                  isLoading = false;
                });
              } catch (e) {
                debugPrint('❌ Error buscando clientes: $e');
                setState(() => isLoading = false);
              }
            }

            return Dialog(
              // Limitamos el ancho del diálogo
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenSize.width > 600
                    ? (screenSize.width - 700) / 2 // En pantallas grandes, ancho fijo de 400
                    : 20, // En pantallas pequeñas, margen de 20
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                // El ancho máximo del contenido
                constraints: BoxConstraints(
                  maxWidth: 400,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seleccionar Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            debounceTimer?.cancel();
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, teléfono, RNC o cédula...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  debounceTimer?.cancel();
                                  searchCustomers('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        // Debounce de 500ms para evitar muchas llamadas API
                        debounceTimer?.cancel();
                        debounceTimer = Timer(const Duration(milliseconds: 500), () {
                          searchCustomers(value);
                        });
                        setState(() {}); // Actualizar UI inmediatamente para mostrar loading
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                        "Clientes con reservas pendientes",
                        //style: TextStyle(fontSize: 10),
                      ),
                      value: switchValue,
                      onChanged: (value) {
                        setState(() {
                          switchValue = value;
                          // Re-aplicar filtro de reservas
                          searchCustomers(searchController.text);
                        });
                      },
                      activeColor: kMainColor,
                      inactiveThumbColor: kGreyTextColor,
                      inactiveTrackColor: kBorderColor,
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : displayedCustomers.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 36,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No se encontraron clientes',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: displayedCustomers.length,
                                  itemBuilder: (context, index) {
                                    final customer = displayedCustomers[index];
                                    return InkWell(
                                      onTap: () {
                                        debounceTimer?.cancel();
                                        Navigator.pop(context, customer);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.blue.shade50,
                                              child: Text(
                                                customer.customerName.isNotEmpty ? customer.customerName[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    customer.customerName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    customer.phoneNumber,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
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
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  DropdownButton<String> getResult(List<CustomerModel> model) {
    List<DropdownMenuItem<String>> dropDownItems = [DropdownMenuItem(value: 'Guest', child: Text(lang.S.of(context).guest))];
    for (var des in model) {
      var item = DropdownMenuItem(
        alignment: Alignment.centerLeft,
        value: des.phoneNumber,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${des.customerName} ${des.phoneNumber}',
            softWrap: true,
            style: kTextStyle.copyWith(color: kTitleColor, overflow: TextOverflow.ellipsis),
            textAlign: TextAlign.left,
          ),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(Icons.keyboard_arrow_down, color: kNeutral700),
      padding: const EdgeInsets.only(left: 10.0),
      isExpanded: true,
      alignment: Alignment.centerLeft,
      items: dropDownItems,
      value: selectedUserId,
      onChanged: (value) {
        setState(() {
          selectedUserId = value!;
          for (var element in model) {
            if (element.phoneNumber == selectedUserId) {
              selectedUserName = element;
              previousDue = element.dueAmount;
              selectedCustomerType == element.type ? null : {selectedCustomerType = element.type, cartList.clear(), productFocusNode.clear()};
            } else if (selectedUserId == 'Guest') {
              previousDue = '0';
              selectedCustomerType = 'Regular';
            }
          }
          invoiceNumber = '';
        });
      },
    );
  }

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in customerType) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(color: kTitleColor, overflow: TextOverflow.ellipsis),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(Icons.keyboard_arrow_down, color: kGreyTextColor),
      items: dropDownItems,
      value: selectedCustomerType,
      onChanged: (value) {
        setState(() {
          cartList.clear();
          selectedCustomerType = value!;
        });
      },
    );
  }

  DropdownButton<WareHouseModel> getWare({required List<WareHouseModel> list}) {
    List<DropdownMenuItem<WareHouseModel>> dropDownItems = [];

    // Obtener sucursal actual de localStorage
    final currentBranchId = html.window.localStorage['selected_tenant_id'] ?? '';

    // CRÍTICO: Si la sucursal cambió, resetear el warehouse seleccionado
    if (_lastKnownBranchId != null && _lastKnownBranchId != currentBranchId) {
      selectedWareHouse = null;
      debugPrint('🔄 Sucursal cambió de $_lastKnownBranchId a $currentBranchId - Reseteando warehouse');
    }
    _lastKnownBranchId = currentBranchId;

    for (var element in list) {
      dropDownItems.add(DropdownMenuItem(
        value: element,
        child: Text(
          element.warehouseName,
          style: kTextStyle.copyWith(color: kGreyTextColor),
          overflow: TextOverflow.ellipsis,
        ),
      ));

      // Seleccionar warehouse basado en la sucursal actual
      if (selectedWareHouse == null) {
        final warehouseNameUpper = element.warehouseName.toUpperCase();
        bool matches = false;

        // Mapeo de sucursal a warehouse
        switch (currentBranchId) {
          case 'sde':
            matches = warehouseNameUpper.contains('SANTO DOMINGO ESTE') || warehouseNameUpper.contains('SDE');
            break;
          case 'sdo':
            matches = warehouseNameUpper.contains('SANTO DOMINGO OESTE') || warehouseNameUpper.contains('SDO') || warehouseNameUpper.contains('OESTE');
            break;
          case 'stg':
            matches = warehouseNameUpper.contains('SANTIAGO') || warehouseNameUpper.contains('STG');
            break;
          case 'rom':
            matches = warehouseNameUpper.contains('ROMANA') || warehouseNameUpper.contains('ROM');
            break;
        }

        if (matches) {
          selectedWareHouse = element;
          debugPrint('✅ Warehouse seleccionado: ${element.warehouseName} para sucursal $currentBranchId');
        }
      }
      i++;
    }
    // Si no se encontró ninguno basado en la sucursal, seleccionar el primer warehouse disponible
    if (selectedWareHouse == null && list.isNotEmpty) {
      selectedWareHouse = list.first;
      debugPrint('⚠️ No se encontró warehouse específico - usando primero: ${list.first.warehouseName}');
    }
    return DropdownButton(
      icon: const Icon(Icons.keyboard_arrow_down, color: kNeutral700),
      items: dropDownItems,
      isExpanded: true,
      value: selectedWareHouse,
      onChanged: (WareHouseModel? value) {
        setState(() {
          selectedWareHouse = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    List<String> allProductsNameList = [];
    List<String> allProductsCodeList = [];
    List<String> warehouseIdList = [];
    List<WarehouseBasedProductModel> warehouseBasedProductModel = [];

    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (context, consumerRef, __) {
          final wareHouseList = consumerRef.watch(warehouseProvider);
          final customerList = consumerRef.watch(allCustomerProvider);
          final personalData = consumerRef.watch(profileDetailsProvider);
          final settingProvider = consumerRef.watch(generalSettingProvider);
          AsyncValue<List<ProductModel>> productList = consumerRef.watch(productProvider);

          return personalData.when(data: (data) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 12),
                          child: Text(
                            lang.S.of(context).inventorySales,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        const Divider(thickness: 1.0, color: kNeutral300),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showReservationSelection(selectedUserId!),
                                icon: Icon(Icons.event, size: 18), // ícono de calendario
                                label: Text('Agregar Reserva'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple, // Color de fondo
                                  foregroundColor: Colors.white, // Color del texto e ícono
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _showDressSelectionDialog,
                                icon: Icon(Icons.checkroom, size: 18), // ícono de vestimenta
                                label: Text('Agregar Vestimenta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal, // Otro color
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ResponsiveGridRow(rowSegments: 120, children: [
                          ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 30,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextFormField(
                                  readOnly: true,
                                  onTap: () {
                                    _selectedDueDate(context);
                                  },
                                  decoration: InputDecoration(
                                      labelText: lang.S.of(context).date,
                                      hintText: '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                      hintStyle: bTextStyle.copyWith(),
                                      suffixIcon: const Icon(
                                        IconlyLight.calendar,
                                        color: kGreyTextColor,
                                      )),
                                ),
                              )),
                          ResponsiveGridCol(
                            xs: 120,
                            md: 60,
                            lg: 60,
                            child: customerList.when(
                              data: (allCustomers) {
                                List<String> listOfPhoneNumber = [];
                                List<CustomerModel> customersList = [];
                                for (var value1 in allCustomers) {
                                  listOfPhoneNumber.add(value1.phoneNumber.replaceAll(RegExp(r'\s+'), '').toLowerCase());
                                  if (value1.type != 'Supplier') {
                                    customersList.add(value1);
                                  }
                                }

                                // Return the Consumer widget - this was missing before
                                return Consumer(
                                  builder: (context, ref, child) {
                                    final customerListAsyncValue = ref.watch(allCustomerProvider);

                                    return customerListAsyncValue.when(
                                      data: (customerList) {
                                        return GestureDetector(
                                          onTap: () async {
                                            ref.invalidate(reservationsFutureProvider);
                                            ref.invalidate(allCustomerProvider); // Forzar recarga de clientes para mostrar los recién agregados
                                            final reservations = await ref.read(reservationsFutureProvider.future);
                                            final customerList = await ref.read(allCustomerProvider.future);
                                            CustomerModel? selectedCustomer = await _showCustomerSearchDialog(
                                              context,
                                              customerList,
                                              reservations,
                                            );

                                            if (selectedCustomer != null) {
                                              setState(() {
                                                clientename = selectedCustomer.customerName;
                                                selectedUserId = selectedCustomer.phoneNumber;

                                                // Agregando la funcionalidad del DropdownButton original
                                                selectedUserName = selectedCustomer;
                                                previousDue = selectedCustomer.dueAmount;

                                                // Verificar si cambió el tipo de cliente y limpiar el carrito si es necesario
                                                if (selectedCustomerType != selectedCustomer.type) {
                                                  selectedCustomerType = selectedCustomer.type;
                                                  cartList.clear();
                                                  productFocusNode.clear();
                                                }

                                                invoiceNumber = '';

                                                // Auto-completar RNC/Cédula si el cliente ya tiene uno registrado
                                                if (selectedCustomer.gst.isNotEmpty) {
                                                  customerRncController.text = selectedCustomer.gst;
                                                }
                                              });
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.grey.shade300),
                                              color: Colors.white,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedUserId != null ? clientename ?? "--Seleccione Cliente--" : "--Seleccione Cliente--",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: selectedUserId != null ? Colors.black87 : Colors.grey.shade600,
                                                      fontWeight: selectedUserId != null ? FontWeight.w500 : FontWeight.normal,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      loading: () => Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                          color: Colors.white,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      ),
                                      error: (error, stackTrace) => Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade300),
                                          color: Colors.red.shade50,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Error al cargar clientes',
                                                style: TextStyle(color: Colors.red.shade700),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, stack) {
                                return Center(
                                  child: Text(e.toString()),
                                );
                              },
                            ),
                          ),
                          // ResponsiveGridCol(
                          //     xs: 40,
                          //     md: 40,
                          //     lg: 30,
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(10.0),
                          //       child: TextFormField(
                          //         readOnly: true,
                          //         decoration: InputDecoration(labelText: lang.S.of(context).invoice, hintText: widget.quotation == null ? data.saleInvoiceCounter.toString() : widget.quotation!.invoiceNumber, contentPadding: const EdgeInsets.only(left: 10.0)),
                          //         textAlign: TextAlign.center,
                          //       ),
                          //     )),
                          ResponsiveGridCol(
                              xs: 80,
                              md: 80,
                              lg: 30,
                              child: wareHouseList.when(
                                data: (warehouse) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 48.0,
                                      child: FormField(
                                        builder: (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Almacén',
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: getWare(
                                                list: warehouse,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                error: (e, stack) {
                                  return Center(
                                    child: Text(
                                      e.toString(),
                                    ),
                                  );
                                },
                                loading: () {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              )),
                          ResponsiveGridCol(
                            xs: 120,
                            md: screenWidth < 780 ? 120 : 60,
                            lg: 60,
                            child: productList.when(data: (product) {
                              for (var element in product) {
                                allProductsNameList.add(element.productName.replaceAll(RegExp(r'\s+'), '').toLowerCase());
                                allProductsCodeList.add(element.productCode.replaceAll(RegExp(r'\s+'), '').toLowerCase());
                                warehouseIdList.add(element.warehouseId.replaceAll(RegExp(r'\s+'), '').toLowerCase());
                                warehouseBasedProductModel.add(WarehouseBasedProductModel(element.productName, element.warehouseId));
                              }
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TypeAheadField(
                                  hideOnEmpty: true,
                                  hideOnLoading: true,
                                  hideOnError: true,
                                  suggestionsCallback: (pattern) {
                                    // No mostrar sugerencias si el patrón está vacío o es muy corto
                                    if (pattern.isEmpty || pattern.length < 2) {
                                      return Future.value([]);
                                    }
                                    // Verificar que hay un warehouse seleccionado
                                    if (selectedWareHouse == null) {
                                      return Future.value([]);
                                    }
                                    ProductRepo pr = ProductRepo();
                                    return pr.getAllProductByJsonWarehouse(searchData: pattern, warehouseId: selectedWareHouse!);
                                  },
                                  itemBuilder: (context, suggestion) {
                                    ProductModel product = ProductModel.fromJson(
                                      jsonDecode(
                                        jsonEncode(suggestion),
                                      ),
                                    );
                                    return ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(10.0, 5.0, 15.0, 5.0),
                                      horizontalTitleGap: 10.0,
                                      leading: Container(
                                        height: 45.0,
                                        width: 45.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: kBorderColorTextField),
                                          image: DecorationImage(image: NetworkImage(product.productPicture), fit: BoxFit.cover),
                                        ),
                                      ),
                                      title: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: Text(
                                                '${lang.S.of(context).name}: ${product.productName}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(color: kTitleColor, fontSize: 16.0, fontWeight: FontWeight.bold),
                                              )),
                                          const Spacer(),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${lang.S.of(context).purchasePrice}: $globalCurrency${product.productPurchasePrice}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(color: kGreyTextColor, fontSize: 12.0),
                                              )),
                                          const Spacer(),
                                          Expanded(flex: 2, child: Text('${lang.S.of(context).salePrice}: $globalCurrency${product.productSalePrice}', textAlign: TextAlign.start, style: kTextStyle.copyWith(color: kGreyTextColor, fontSize: 12.0))),
                                          const Spacer(),
                                          Expanded(
                                            flex: 0,
                                            child: Text('${lang.S.of(context).stock}: ${product.productStock}', textAlign: TextAlign.start, style: kTextStyle.copyWith(color: kGreyTextColor, fontSize: 12.0)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onSelected: (suggestion) {
                                    // Para Realtime Database
                                    final productData = Map<String, dynamic>.from(suggestion as Map);
                                    
                                    ProductModel product = ProductModel.fromJson(productData);
                                    
                                    AddToCartModel addToCartModel = AddToCartModel(
                                        productName: product.productName,
                                        warehouseName: product.warehouseName,
                                        warehouseId: product.warehouseId,
                                        productId: suggestion['firebaseId'] ?? product.productCode,
                                        quantity: 1,
                                        productImage: product.productPicture,
                                        stock: int.tryParse(product.productStock) ?? 0,
                                        productPurchasePrice: double.tryParse(product.productPurchasePrice) ?? 0.0,
                                        subTotal: productPriceChecker(
                                          product: product,
                                          customerType: selectedCustomerType,
                                        ),
                                        taxType: product.taxType,
                                        margin: product.margin,
                                        incTax: product.incTax,
                                        groupTaxRate: product.groupTaxRate,
                                        groupTaxName: product.groupTaxName,
                                        excTax: product.excTax,
                                        subTaxes: product.subTaxes);
                                    setState(() {
                                      if (!uniqueCheck(product.productCode)) {
                                        cartList.add(addToCartModel);
                                        
                                        // NUEVO: Cualquier producto desde búsqueda = impresión/enmarcado
                                        _hasImpresionEnmarcado = true;
                                        
                                        addFocus();
                                        nameCodeCategoryController.clear();
                                        nameFocus.requestFocus();
                                      } else {
                                        nameCodeCategoryController.clear();
                                        nameFocus.requestFocus();
                                      }
                                      updateDueAmount();
                                    });
                                  },
                                  builder: (context, controller, focusNode) {
                                    return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        autofocus: false,
                                        decoration: InputDecoration(
                                          labelText: lang.S.of(context).selectProduct,
                                          hintText: lang.S.of(context).searchWithProductName,
                                          prefixIcon: Icon(Icons.search, color: kNeutral700),
                                        ));
                                  },
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
                            }),
                          ),
                          ResponsiveGridCol(
                            xs: 120,
                            md: screenWidth < 780 ? 120 : 60,
                            lg: 60,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SizedBox(
                                height: 48,
                                child: FormField(
                                  builder: (FormFieldState<dynamic> field) {
                                    return InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Tipo de cliente',
                                        ),
                                        child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: Colors.transparent, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getCategories())));
                                  },
                                ),
                              ),
                            ),
                          )
                        ]),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final kWidth = constraints.maxWidth - 20;
                            return Scrollbar(
                              controller: horizontalScroll,
                              thickness: 8,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                scrollDirection: Axis.horizontal,
                                controller: horizontalScroll,
                                child: Container(
                                  // height:
                                  //     MediaQuery.of(context).size.height < 720
                                  //         ? 720 - 410
                                  //         : MediaQuery.of(context).size.height -
                                  //             410,
                                  constraints: BoxConstraints(
                                    minWidth: kWidth,
                                  ),
                                  child: Theme(
                                    data: theme.copyWith(dividerColor: Colors.transparent, dividerTheme: const DividerThemeData(color: Colors.transparent)),
                                    child: DataTable(
                                        border: TableBorder.all(
                                          color: kNeutral300,
                                          width: 1.0,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        dividerThickness: 0.0,
                                        dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                        showBottomBorder: false,
                                        headingTextStyle: theme.textTheme.titleMedium,
                                        dataTextStyle: theme.textTheme.bodyLarge,
                                        columns: [
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).productNam,
                                          )),
                                          DataColumn(
                                              headingRowAlignment: MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).quantity,
                                              )),
                                          DataColumn(
                                              headingRowAlignment: MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).price,
                                              )),
                                          DataColumn(
                                              headingRowAlignment: MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).subTotal,
                                              )),
                                          DataColumn(
                                              headingRowAlignment: MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).action,
                                              )),
                                        ],
                                        rows: List.generate(cartList.length, (index) {
                                          TextEditingController quantityController = TextEditingController(text: cartList[index].quantity.toString());
                                          return DataRow(cells: [
                                            DataCell(
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Descripción del producto'),
                                                      content: Text(cartList[index].descricpion ?? 'Sin descripción'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: const Text('Cerrar'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  cartList[index].productName ?? '',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyLarge,
                                                ),
                                              ),
                                            ),
                                            DataCell(Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        cartList[index].quantity > 1 ? cartList[index].quantity-- : cartList[index].quantity = 1;
                                                        updateDueAmount();
                                                      });
                                                    },
                                                    child: const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor)),
                                                Container(
                                                  width: 60,
                                                  height: 35,
                                                  padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(2.0),
                                                    color: Colors.white,
                                                  ),
                                                  child: TextFormField(
                                                    controller: quantityController,
                                                    focusNode: productFocusNode[index],
                                                    textAlign: TextAlign.center,
                                                    onChanged: (value) {
                                                      if ((cartList[index].stock ?? 0) < (num.tryParse(value) ?? 0)) {
                                                        EasyLoading.showError(lang.S.of(context).outOfStock);
                                                        quantityController.clear();
                                                      } else if (value == '') {
                                                        cartList[index].quantity = 1;
                                                      } else if (value == '0') {
                                                        cartList[index].quantity = 1;
                                                      } else {
                                                        cartList[index].quantity = (num.tryParse(value) ?? 1);
                                                      }
                                                    },
                                                    onFieldSubmitted: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index].quantity = 1;
                                                          updateDueAmount();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          cartList[index].quantity = (num.tryParse(value) ?? 1);
                                                          updateDueAmount();
                                                        });
                                                      }
                                                    },
                                                    decoration: const InputDecoration(border: InputBorder.none),
                                                  ),
                                                ),
                                                GestureDetector(
                                                    onTap: () {
                                                      if (cartList[index].quantity < cartList[index].stock!.toInt()) {
                                                        setState(() {
                                                          cartList[index].quantity += 1;
                                                          updateDueAmount();
                                                        });
                                                      } else {
                                                        EasyLoading.showError(lang.S.of(context).outOfStock);
                                                      }
                                                    },
                                                    child: const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor)),
                                              ],
                                            )),
                                            DataCell(
                                              Center(
                                                child: SizedBox(
                                                  width: 70,
                                                  height: 35,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.center,
                                                    initialValue: myFormat.format(double.tryParse(cartList[index].subTotal?.toString() ?? '0') ?? 0),
                                                    onChanged: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index].subTotal = 0.toString();
                                                        });
                                                      } else if (double.tryParse(value) == null) {
                                                        EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                                                      } else {
                                                        setState(() {
                                                          cartList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                                        });
                                                      }
                                                      updateDueAmount();
                                                    },
                                                    onFieldSubmitted: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index].subTotal = 0.toString();
                                                          updateDueAmount();
                                                        });
                                                      } else if (double.tryParse(value) == null) {
                                                        EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                                                      } else {
                                                        setState(() {
                                                          cartList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                                          updateDueAmount();
                                                        });
                                                      }
                                                    },
                                                    decoration: InputDecoration(border: InputBorder.none),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$globalCurrency${myFormat.format(double.tryParse(((double.tryParse(cartList[index].subTotal?.toString() ?? '0') ?? 0) * cartList[index].quantity).toStringAsFixed(2)) ?? 0)}',
                                                  style: theme.textTheme.bodyLarge,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Align(
                                                alignment: Alignment.center,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      // Primero eliminar el FocusNode correspondiente
                                                      productFocusNode.removeAt(index);
                                                      // Luego eliminar el item del carrito
                                                      cartList.removeAt(index);
                                                      updateDueAmount();
                                                    });
                                                  },
                                                  child: const SizedBox(
                                                    width: 50,
                                                    child: Icon(
                                                      Icons.close_sharp,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ]);
                                        })),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        ResponsiveGridRow(children: [
                          ResponsiveGridCol(
                            xs: 12,
                            md: screenWidth < 800 ? 12 : 6,
                            lg: 6,
                            child: ResponsiveGridRow(children: [
                              ResponsiveGridCol(
                                  xs: 12,
                                  md: 6,
                                  lg: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          double total = double.parse((double.parse(getTotalAmount()) + serviceCharge - discountAmount + vatGst).toStringAsFixed(1));

                                          double paidAmount = double.tryParse(value) ?? 0.0;
                                          if (paidAmount > total) {
                                            changeAmountController.text = (paidAmount - total).toString();
                                            dueAmountController.text = '0';
                                          } else {
                                            dueAmountController.text = (total - paidAmount).abs().toStringAsFixed(2);
                                            changeAmountController.text = '0';
                                          }
                                        });
                                      },
                                      controller: payingAmountController,
                                      decoration: InputDecoration(labelText: lang.S.of(context).payingAmount, hintText: lang.S.of(context).enterReceivedAmount),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                  xs: 12,
                                  md: 6,
                                  lg: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextField(
                                      readOnly: true,
                                      controller: dueAmountController,
                                      decoration: InputDecoration(labelText: lang.S.of(context).dueAmount, hintText: lang.S.of(context).enterDueAmount),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                  xs: 12,
                                  md: 6,
                                  lg: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextField(
                                      readOnly: true,
                                      controller: changeAmountController,
                                      decoration: InputDecoration(
                                        labelText: lang.S.of(context).changeReturn,
                                        hintText: lang.S.of(context).enterChangeReturn,
                                      ),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                  xs: 12,
                                  md: 6,
                                  lg: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 48,
                                      child: FormField(
                                        builder: (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).paymentType,
                                              hintText: '',
                                            ),
                                            child: Theme(
                                              data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                              child: DropdownButtonHideUnderline(
                                                child: getOption(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )),
                              // NCF Type selector (Comprobante Fiscal)
                              ResponsiveGridCol(
                                  xs: 12,
                                  md: 6,
                                  lg: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 48,
                                      child: FormField(
                                        builder: (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: const InputDecoration(
                                              labelText: 'Tipo Comprobante (NCF)',
                                              hintText: 'Seleccione tipo',
                                            ),
                                            child: Theme(
                                              data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                              child: DropdownButtonHideUnderline(
                                                child: isLoadingNcfTypes
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : DropdownButton<String>(
                                                        isExpanded: true,
                                                        value: selectedNcfType,
                                                        items: ncfTypes.map((type) {
                                                          return DropdownMenuItem<String>(
                                                            value: type.code,
                                                            child: Text('${type.code} - ${type.name}'),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            selectedNcfType = value ?? 'SIN';
                                                            // Limpiar RNC si el nuevo tipo no lo requiere
                                                            if (!ncfRequiresRnc) {
                                                              customerRncController.clear();
                                                            }
                                                          });
                                                        },
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )),
                              // Campo RNC/Cédula - solo mostrar cuando el NCF lo requiere
                              if (ncfRequiresRnc)
                                ResponsiveGridCol(
                                    xs: 12,
                                    md: 6,
                                    lg: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: TextField(
                                        controller: customerRncController,
                                        decoration: const InputDecoration(
                                          labelText: 'RNC / Cédula *',
                                          hintText: 'Ingrese RNC o Cédula del cliente',
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    )),
                              // Bank selection dropdown - only show when Transferencia is selected
                              if (selectedPaymentOption == 'Transferencia')
                                ResponsiveGridCol(
                                    xs: 12,
                                    md: 6,
                                    lg: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Consumer(
                                        builder: (context, ref, _) {
                                          final banksAsync = ref.watch(allBanksProvider);
                                          return banksAsync.when(
                                            data: (banks) {
                                              return SizedBox(
                                                height: 48,
                                                child: FormField(
                                                  builder: (FormFieldState<dynamic> field) {
                                                    return InputDecorator(
                                                      decoration: InputDecoration(
                                                        labelText: 'Banco *',
                                                        hintText: 'Seleccione un banco',
                                                      ),
                                                      child: Theme(
                                                        data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                        child: DropdownButtonHideUnderline(
                                                          child: DropdownButton<String>(
                                                            isExpanded: true,
                                                            value: selectedBankId,
                                                            items: banks.map((bank) {
                                                              return DropdownMenuItem<String>(
                                                                value: bank.bankId,
                                                                child: Text(bank.bankName ?? ''),
                                                              );
                                                            }).toList(),
                                                            onChanged: (value) {
                                                              setState(() {
                                                                selectedBankId = value;
                                                                selectedBankName = banks.firstWhere((bank) => bank.bankId == value).bankName;
                                                              });
                                                            },
                                                            hint: Text('Seleccione un banco'),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            loading: () => SizedBox(
                                              height: 48,
                                              child: Center(child: CircularProgressIndicator()),
                                            ),
                                            error: (error, stack) => SizedBox(
                                              height: 48,
                                              child: Center(child: Text('Error al cargar bancos')),
                                            ),
                                          );
                                        },
                                      ),
                                    )),
                              // Campo: Nombre del titular (obligatorio)
                              if (selectedPaymentOption == 'Transferencia')
                                ResponsiveGridCol(
                                    xs: 12,
                                    md: 6,
                                    lg: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: TextField(
                                        controller: transferHolderNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre del titular *',
                                          hintText: 'Nombre como aparece en el comprobante',
                                        ),
                                      ),
                                    )),
                              // Campo: Número de referencia (opcional)
                              if (selectedPaymentOption == 'Transferencia')
                                ResponsiveGridCol(
                                    xs: 12,
                                    md: 6,
                                    lg: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: TextField(
                                        controller: transferReferenceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Número de referencia',
                                          hintText: 'Opcional',
                                        ),
                                      ),
                                    )),
                              // Campo: Comprobante de transferencia (obligatorio)
                              if (selectedPaymentOption == 'Transferencia')
                                ResponsiveGridCol(
                                    xs: 12,
                                    md: 12,
                                    lg: 12,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.camera_alt, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Comprobante de Transferencia *', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            if (transferReceiptUrl != null) ...[
                                              Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      transferReceiptUrl!,
                                                      height: 150,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          height: 100,
                                                          color: Colors.grey.shade200,
                                                          child: const Center(child: Icon(Icons.broken_image)),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.red),
                                                      onPressed: () => setState(() => transferReceiptUrl = null),
                                                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              const Text('✓ Comprobante cargado', style: TextStyle(color: Colors.green)),
                                            ] else ...[
                                              if (isUploadingReceipt)
                                                const Center(child: CircularProgressIndicator())
                                              else
                                                InkWell(
                                                  onTap: _pickTransferReceipt,
                                                  child: Container(
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.blue, style: BorderStyle.solid),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.upload_file, size: 40, color: Colors.blue),
                                                          SizedBox(height: 8),
                                                          Text('Subir comprobante', style: TextStyle(color: Colors.blue)),
                                                          Text('Formatos: JPG, PNG (Max 5MB)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )),
                              // Aviso sobre verificación
                              if (selectedPaymentOption == 'Transferencia')
                                ResponsiveGridCol(
                                    xs: 12,
                                    md: 12,
                                    lg: 12,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Este pago quedará PENDIENTE hasta que un operador verifique el comprobante.',
                                                style: TextStyle(color: Colors.orange, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                            ]),
                          ),
                          ResponsiveGridCol(
                              xs: 12,
                              md: screenWidth < 800 ? 12 : 6,
                              lg: 6,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xffF8F1FF)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
                                    child: Column(
                                      children: [
                                        ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: Padding(
                                              padding: EdgeInsets.only(bottom: screenWidth < 577 ? 8 : 0),
                                              child: Text(
                                                lang.S.of(context).totalAmount,
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                          ),
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(color: Color(0xff00AE1C), borderRadius: BorderRadius.all(Radius.circular(8))),
                                              child: Center(
                                                child: Text(
                                                  '$globalCurrency ${myFormat.format(double.tryParse((double.parse(getTotalAmount()) + serviceCharge - discountAmount + vatGst).toStringAsFixed(2)) ?? 0)}',
                                                  style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 10.0),
                                        ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: Padding(
                                              padding: EdgeInsets.only(bottom: screenWidth < 577 ? 8 : 0),
                                              child: Text(
                                                lang.S.of(context).shpingOrServices,
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                          ),
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: SizedBox(
                                              height: 40,
                                              child: TextFormField(
                                                initialValue: serviceCharge.toString(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    serviceCharge = double.parse(value);
                                                    updateDueAmount();
                                                  });
                                                },
                                                decoration: InputDecoration(border: const OutlineInputBorder(), hintText: lang.S.of(context).enterAmount, contentPadding: EdgeInsets.zero),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 10.0),
                                        ListView.builder(
                                          itemCount: getAllTaxFromCartList(cart: cartList).length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: ResponsiveGridRow(children: [
                                                ResponsiveGridCol(
                                                  xs: 12,
                                                  lg: 6,
                                                  md: 6,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(bottom: screenWidth < 577 ? 8 : 0),
                                                    child: Text(
                                                      getAllTaxFromCartList(cart: cartList)[index].name,
                                                      textAlign: TextAlign.start,
                                                      style: theme.textTheme.bodyLarge,
                                                    ),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                  xs: 12,
                                                  lg: 6,
                                                  md: 6,
                                                  child: SizedBox(
                                                    height: 40.0,
                                                    child: Center(
                                                      child: TextFormField(
                                                        initialValue: getAllTaxFromCartList(cart: cartList)[index].taxRate.toString(),
                                                        readOnly: true,
                                                        textAlign: TextAlign.right,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.only(right: 6.0),
                                                          hintText: '0',
                                                          border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                          enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                          disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                          focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                          prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                                          prefixIcon: Container(
                                                            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                                            height: 40,
                                                            decoration: const BoxDecoration(color: Color(0xFFff5f00), borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                                            child: const Text(
                                                              '%',
                                                              style: TextStyle(fontSize: 20.0, color: Colors.white),
                                                            ),
                                                          ),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            );
                                          },
                                        ),
                                        ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: Padding(
                                              padding: EdgeInsets.only(bottom: screenWidth < 577 ? 8 : 0),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    lang.S.of(context).discount,
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                  SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: discountFieldsEnabled ? null : _showDiscountAuthDialog,
                                                    child: Icon(
                                                      discountFieldsEnabled ? Icons.lock_open : Icons.lock,
                                                      size: 16,
                                                      color: discountFieldsEnabled ? Colors.green : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: SizedBox(
                                                    height: 40,
                                                    child: TextFormField(
                                                      controller: discountPercentageEditingController,
                                                      enabled: discountFieldsEnabled,
                                                      onTap: !discountFieldsEnabled ? _showDiscountAuthDialog : null,
                                                      onChanged: (value) {
                                                        if (value == '') {
                                                          setState(() {
                                                            discountAmountEditingController.text = 0.toString();
                                                          });
                                                        } else {
                                                          if (value.toInt() <= 100) {
                                                            setState(() {
                                                              discountAmount = double.parse(((value.toDouble() / 100) * getTotalAmount().toDouble()).toStringAsFixed(1));
                                                              discountAmountEditingController.text = discountAmount.toString();
                                                            });
                                                          } else {
                                                            setState(() {
                                                              discountAmount = 0;
                                                              discountAmountEditingController.clear();
                                                              discountPercentageEditingController.clear();
                                                            });
                                                            EasyLoading.showError(lang.S.of(context).enterAValidDiscount);
                                                          }
                                                        }
                                                        updateDueAmount();
                                                      },
                                                      textAlign: TextAlign.right,
                                                      decoration: InputDecoration(
                                                        contentPadding: const EdgeInsets.only(right: 6.0),
                                                        hintText: '0',
                                                        border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xffFF8C00))),
                                                        enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xffFF8C00))),
                                                        disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xffFF8C00))),
                                                        focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xffFF8C00))),
                                                        prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                                        prefixIcon: Container(
                                                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                                          height: 40,
                                                          decoration: const BoxDecoration(color: Color(0xffFF8C00), borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                                          child: const Text(
                                                            '%',
                                                            style: TextStyle(fontSize: 18.0, color: Colors.white),
                                                          ),
                                                        ),
                                                      ),
                                                      keyboardType: TextInputType.name,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 20.0,
                                                ),
                                                Flexible(
                                                  child: SizedBox(
                                                    height: 40.0,
                                                    child: Center(
                                                      child: AppTextField(
                                                        controller: discountAmountEditingController,
                                                        enabled: discountFieldsEnabled,
                                                        onTap: !discountFieldsEnabled ? _showDiscountAuthDialog : null,
                                                        onChanged: (value) {
                                                          if (value == '') {
                                                            setState(() {
                                                              discountAmount = 0;
                                                              discountPercentageEditingController.text = 0.toString();
                                                            });
                                                          } else {
                                                            if (value.toInt() <= getTotalAmount().toDouble()) {
                                                              setState(() {
                                                                discountAmount = double.parse(value);
                                                                discountPercentageEditingController.text = ((discountAmount * 100) / getTotalAmount().toDouble()).toStringAsFixed(1);
                                                              });
                                                            } else {
                                                              setState(() {
                                                                discountAmount = 0;
                                                                discountPercentageEditingController.clear();
                                                                discountAmountEditingController.clear();
                                                              });
                                                              EasyLoading.showError(lang.S.of(context).enterAValidDiscount);
                                                            }
                                                          }
                                                          updateDueAmount();
                                                        },
                                                        textAlign: TextAlign.right,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.only(right: 6.0),
                                                          hintText: '0',
                                                          border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xff00AE1C))),
                                                          enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xff00AE1C))),
                                                          disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xff00AE1C))),
                                                          focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xff00AE1C))),
                                                          prefixIconConstraints: const BoxConstraints(maxWidth: 40.0, minWidth: 40.0),
                                                          prefixIcon: Container(
                                                            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                                            height: 40,
                                                            decoration: const BoxDecoration(color: Color(0xff00AE1C), borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                                            child: Text(
                                                              currency,
                                                              style: const TextStyle(fontSize: 18.0, color: Colors.white),
                                                            ),
                                                          ),
                                                        ),
                                                        textFieldType: TextFieldType.PHONE,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                        ]),
                        const SizedBox(height: 10),
                        ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          if (screenWidth > 1240) ResponsiveGridCol(lg: 3, xs: 0, md: 0, child: const SizedBox.shrink()),
                          ResponsiveGridCol(
                            xs: 6,
                            md: 4,
                            lg: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  GoRouter.of(context).pop();
                                },
                                child: Text(
                                  lang.S.of(context).cancel,
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                            xs: 6,
                            md: 4,
                            lg: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                ),
                                onPressed: () async {
                                  if (await Subscription.subscriptionChecker(item: 'Ventas')) {
                                    if (cartList.isEmpty) {
                                      EasyLoading.showError(lang.S.of(context).pleaseAddSomeProductFirst);
                                    } else {
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return Padding(
                                              padding: const EdgeInsets.all(10.0),
                                              child: Center(
                                                child: Container(
                                                  width: 500,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.all(
                                                      Radius.circular(15),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(20.0),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          lang.S.of(context).areYouWantToCreateThisQuation,
                                                          style: theme.textTheme.headlineSmall?.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                        const SizedBox(height: 20),
                                                        ResponsiveGridRow(children: [
                                                          ResponsiveGridCol(
                                                            lg: 6,
                                                            md: 6,
                                                            xs: 6,
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(10.0),
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.red,
                                                                ),
                                                                child: Text(
                                                                  lang.S.of(context).cancel,
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.pop(dialogContext);
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                          ResponsiveGridCol(
                                                            lg: 6,
                                                            md: 6,
                                                            xs: 6,
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(10.0),
                                                              child: ElevatedButton(
                                                                child: Text(
                                                                  lang.S.of(context).create,
                                                                ),
                                                                onPressed: () async {
                                                                  var invoice_number_variable = await getLastInvoiceNumber();

                                                                  SaleTransactionModel transitionModel = SaleTransactionModel(
                                                                    customerName: selectedUserName?.customerName ?? '',
                                                                    customerType: selectedUserName?.type ?? '',
                                                                    customerImage: selectedUserName?.profilePicture ?? '',
                                                                    customerAddress: selectedUserName?.customerAddress ?? '',
                                                                    customerPhone: selectedUserName?.phoneNumber ?? '',
                                                                    customerGst: selectedUserName?.gst ?? '',

                                                                    invoiceNumber: invoice_number_variable.toString(),

                                                                    sendWhatsappMessage: selectedUserName?.receiveWhatsappUpdates ?? false,
                                                                    purchaseDate: DateTime.now().toString(),
                                                                    productList: cartList,
                                                                    totalAmount: double.parse((getTotalAmount().toDouble() + serviceCharge - discountAmount + vatGst).toStringAsFixed(1)),
                                                                    discountAmount: discountAmount,
                                                                    serviceCharge: serviceCharge,
                                                                    vat: vatGst,

                                                                    reservationIds: cartList
                                                                        .where((item) => item.reservationId != null) // Filtra items con reserva
                                                                        .map((item) => item.reservationId!) // Extrae IDs
                                                                        .toList(), // Convierte a lista
                                                                    saleType: _getSaleType(), // NUEVO: tipo de venta
                                                                  );

                                                                  try {
                                                                    EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                                                    final apiServiceQuotation = ApiService();

                                                                    transitionModel.isPaid = false;
                                                                    transitionModel.dueAmount = 0;
                                                                    transitionModel.lossProfit = 0;
                                                                    transitionModel.returnAmount = 0;
                                                                    transitionModel.paymentType = 'Just Quotation';
                                                                    // Obtener el nombre real del usuario actual
                                                                    transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';

                                                                    await apiServiceQuotation.post('quotations', Map<String, dynamic>.from(transitionModel.toJson()));
                                                                    
                                                                    // Registrar auditoría de la cotización
                                                                    await AuditService().logCreate(
                                                                      module: AuditModule.sales,
                                                                      itemName: 'Cotización',
                                                                      itemId: transitionModel.invoiceNumber,
                                                                      data: {
                                                                        'customerName': transitionModel.customerName,
                                                                        'totalAmount': transitionModel.totalAmount,
                                                                        'productCount': cartList.length,
                                                                        'discountAmount': transitionModel.discountAmount,
                                                                        'serviceCharge': transitionModel.serviceCharge,
                                                                      },
                                                                    );
                                                                    
                                                                    updateInvoice(typeOfInvoice: 'saleInvoiceCounter', invoice: transitionModel.invoiceNumber.toInt());
                                                                    // ignore: unused_result
                                                                    consumerRef.refresh(profileDetailsProvider);

                                                                    EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully);
                                                                    Navigator.pop(dialogContext);

                                                                    // Mostrar diálogo de selección de formato de impresión
                                                                    await showDialog(
                                                                      context: context,
                                                                      builder: (printDialogContext) {
                                                                        return AlertDialog(
                                                                          title: Text("Selecciona Formato De imprecio Factura"),
                                                                          content: Column(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                              ElevatedButton(
                                                                                onPressed: () async {
                                                                                  Navigator.pop(printDialogContext);
                                                                                  GeneratePdfAndPrint().printQuotationInvoice(
                                                                                    personalInformationModel: data,
                                                                                    saleTransactionModel: transitionModel,
                                                                                    context: context,
                                                                                    isFromInventorySale: true,
                                                                                    printFormat: 'large', // Formato grande
                                                                                  );
                                                                                  
                                                                                  // Registrar auditoría de impresión de cotización
                                                                                  await AuditService().logPrint(
                                                                                    module: AuditModule.sales,
                                                                                    documentType: 'Cotización',
                                                                                    documentId: transitionModel.invoiceNumber,
                                                                                  );
                                                                                },
                                                                                child: Text("Largo"),
                                                                              ),
                                                                              const SizedBox(height: 10),
                                                                              ElevatedButton(
                                                                                onPressed: () async {
                                                                                  Navigator.pop(printDialogContext);
                                                                                  GeneratePdfAndPrint().printQuotationInvoice(
                                                                                    personalInformationModel: data,
                                                                                    saleTransactionModel: transitionModel,
                                                                                    context: context,
                                                                                    isFromInventorySale: true,
                                                                                    printFormat: 'small', // Formato pequeño
                                                                                  );
                                                                                  
                                                                                  // Registrar auditoría de impresión de cotización
                                                                                  await AuditService().logPrint(
                                                                                    module: AuditModule.sales,
                                                                                    documentType: 'Cotización',
                                                                                    documentId: transitionModel.invoiceNumber,
                                                                                  );
                                                                                },
                                                                                child: Text("small"),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(printDialogContext),
                                                                              child: Text(lang.S.of(context).cancel),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );

                                                                    // GeneratePdfAndPrint().printQuotationInvoice(
                                                                    //   personalInformationModel: data,
                                                                    //   saleTransactionModel: transitionModel,
                                                                    //   context: context,
                                                                    //   isFromInventorySale: true,
                                                                    //
                                                                    // );

                                                                    GoRouter.of(dialogContext).pop();
                                                                  } catch (e) {
                                                                    EasyLoading.dismiss();
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ]),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                    }
                                  } else {
                                    EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                  }
                                },
                                child: Text(
                                  lang.S.of(context).quotation,
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                              xs: 12,
                              md: 4,
                              lg: 2,
                              child: settingProvider.when(data: (setting) {
                                return Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kMainColor,
                                    ),
                                    onPressed: () async {
                                      print('════════════════════════════════════════════════════════════════');
                                      print('DEBUG: Botón de pago presionado');
                                      print('DEBUG: Estado actual:');
                                      print('  - saleButtonClicked: $saleButtonClicked');
                                      print('  - selectedPaymentOption: $selectedPaymentOption');
                                      print('  - transferReceiptUrl: $transferReceiptUrl');
                                      print('  - selectedBankId: $selectedBankId');
                                      print('  - cartList.length: ${cartList.length}');
                                      print('  - selectedUserId: $selectedUserId');
                                      print('  - selectedWareHouse: ${selectedWareHouse?.warehouseName}');
                                      print('════════════════════════════════════════════════════════════════');

                                      // Evitar múltiples clics
                                      if (saleButtonClicked) {
                                        print('DEBUG: Botón ya presionado, ignorando clic');
                                        return;
                                      }

                                      final hasPermission = checkUserRoleEditPermissionV2(type: 'sales');
                                      print('DEBUG: checkUserRoleEditPermissionV2 retornó: $hasPermission');

                                      if (hasPermission) {
                                        print('DEBUG: Usuario tiene permisos de venta');
                                        final subscriptionOk = await Subscription.subscriptionChecker(item: 'Sales');
                                        print('DEBUG: Subscription.subscriptionChecker retornó: $subscriptionOk');

                                        if (subscriptionOk) {
                                          print('Carrito actual: ${jsonEncode(cartList)}');
                                          print('DEBUG: Verificación de suscripción exitosa');
                                          if (cartList.isEmpty) {
                                            print('DEBUG: Error - Carrito vacío');
                                            EasyLoading.showError(lang.S.of(context).pleaseAddSomeProductFirst);
                                          } else if (selectedUserId == null) {
                                            print('DEBUG: Error - No se seleccionó cliente');
                                            EasyLoading.showError('Por favor seleccione un cliente');
                                          } else if (selectedWareHouse == null) {
                                            print('DEBUG: Error - No se seleccionó almacén');
                                            EasyLoading.showError('Por favor seleccione un almacén');
                                          } else if (selectedPaymentOption == 'Transferencia' && selectedBankId == null) {
                                            print('DEBUG: Error - No se seleccionó banco para transferencia');
                                            EasyLoading.showError('Por favor seleccione un banco para la transferencia');
                                          } else if (selectedPaymentOption == 'Transferencia' && transferHolderNameController.text.trim().isEmpty) {
                                            print('DEBUG: Error - No se ingresó nombre del titular');
                                            EasyLoading.showError('Por favor ingrese el nombre del titular de la transferencia');
                                          } else if (selectedPaymentOption == 'Transferencia' && transferReceiptUrl == null) {
                                            print('DEBUG: Error - No se subió comprobante de transferencia');
                                            EasyLoading.showError('Por favor suba el comprobante de la transferencia');
                                          } else if (ncfRequiresRnc && customerRncController.text.trim().isEmpty) {
                                            print('DEBUG: Error - NCF requiere RNC pero no se ingresó');
                                            EasyLoading.showError('El tipo de comprobante $selectedNcfType requiere RNC o Cédula');
                                          } else {
                                            print('DEBUG: Intentando obtener número de factura');
                                            var invoice_number_variable = await getLastInvoiceNumber();
                                            print('DEBUG: Número de factura obtenido: $invoice_number_variable');
                                            
                                            // Validar que el monto pagado sea un número válido
                                            if (payingAmountController.text.isEmpty || double.tryParse(payingAmountController.text) == null) {
                                              print('DEBUG: Error - Monto pagado inválido');
                                              EasyLoading.showError('Por favor ingrese un monto pagado válido');
                                              return;
                                            }

                                            // Calcular subtotal e ITBIS si aplica
                                            final subtotalBeforeTax = getTotalAmount().toDouble() + serviceCharge - discountAmount;
                                            final itbisRate = ncfItbisRate;
                                            final itbisAmount = selectedNcfType != 'SIN' && itbisRate > 0
                                                ? subtotalBeforeTax * (itbisRate / 100)
                                                : 0.0;
                                            final totalWithItbis = subtotalBeforeTax + itbisAmount + vatGst;

                                            // Generar NCF si es necesario
                                            String? generatedNcfNumber;
                                            String? ncfExpirationDate;
                                            if (selectedNcfType != 'SIN') {
                                              print('DEBUG: Generando NCF para tipo: $selectedNcfType');
                                              final ncfResult = await dgiiRepository.generateNcfWithExpiration(selectedNcfType);
                                              if (ncfResult != null) {
                                                generatedNcfNumber = ncfResult['ncfNumber'];
                                                ncfExpirationDate = ncfResult['expirationDate'];
                                              }
                                              print('DEBUG: NCF generado: $generatedNcfNumber, Vence: $ncfExpirationDate');
                                              if (generatedNcfNumber == null) {
                                                EasyLoading.showError('Error generando comprobante fiscal. Verifique la configuración de secuencias NCF.');
                                                setState(() => saleButtonClicked = false);
                                                return;
                                              }
                                            }

                                            SaleTransactionModel transitionModel = SaleTransactionModel(
                                              customerName: selectedUserName?.customerName ?? '',
                                              customerType: selectedUserName?.type ?? '',
                                              customerImage: selectedUserName?.profilePicture ?? '',
                                              customerAddress: selectedUserName?.customerAddress ?? '',
                                              customerPhone: selectedUserName?.phoneNumber ?? '',
                                              customerGst: selectedUserName?.gst ?? '',
                                              // Se agrega validador en el momento
                                              invoiceNumber: invoice_number_variable.toString(),

                                              // data
                                              //     .saleInvoiceCounter
                                              //     .toString(),
                                              sendWhatsappMessage: selectedUserName?.receiveWhatsappUpdates ?? false,
                                              purchaseDate: DateTime.now().toString(),
                                              productList: cartList,
                                              totalAmount: double.parse(totalWithItbis.toStringAsFixed(2)),
                                              discountAmount: discountAmount,
                                              serviceCharge: serviceCharge,
                                              vat: vatGst,
                                              reservationIds: cartList.where((item) => item.reservationId != null).map((item) => item.reservationId!).toList(),
                                              saleType: _getSaleType(), // NUEVO: tipo de venta
                                              // Campos NCF / DGII
                                              ncfType: selectedNcfType,
                                              ncfNumber: generatedNcfNumber,
                                              ncfExpirationDate: ncfExpirationDate,
                                              customerRnc: customerRncController.text.trim().isNotEmpty ? customerRncController.text.trim() : null,
                                              itbisAmount: itbisAmount,
                                              subtotalBeforeTax: subtotalBeforeTax,
                                            );

                                            if (transitionModel.customerType == "Guest" && dueAmountController.text.toDouble() > 0) {
                                              print('DEBUG: Error - Cliente Guest no puede tener monto pendiente');
                                              EasyLoading.showError(lang.S.of(context).dueIsNotAvailableForGuest);
                                              setState(() => saleButtonClicked = false);
                                            } else {
                                              try {
                                                setState(() {
                                                  saleButtonClicked = true;
                                                });
                                                print('DEBUG: Mostrando diálogo de formato de impresión');

                                                final printType = await showDialog<String>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text('Seleccionar formato de impresión'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: Icon(Icons.receipt, color: Colors.blue),
                                                          title: Text('Factura térmica'),
                                                          subtitle: Text('Para impresora de 58-80mm'),
                                                          onTap: () => Navigator.pop(context, 'thermal'),
                                                        ),
                                                        Divider(),
                                                        ListTile(
                                                          leading: Icon(Icons.description, color: Colors.green),
                                                          title: Text('Factura normal'),
                                                          subtitle: Text('Formato completo A4/Letter'),
                                                          onTap: () => Navigator.pop(context, 'normal'),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: Text('Cancelar'),
                                                        onPressed: () => Navigator.pop(context),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (printType == null) {
                                                  EasyLoading.dismiss();
                                                  setState(() => saleButtonClicked = false);
                                                  return;
                                                }

                                                final sendWhatsApp = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text('Enviar por WhatsApp'),
                                                    content: Text('¿Desea enviar el comprobante por WhatsApp al cliente?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: Text('No'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: Text('Sí, enviar'),
                                                      ),
                                                    ],
                                                  ),
                                                ) ?? false;

                                                EasyLoading.show(status: 'Procesando...', dismissOnTap: false);

                                                EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                                print('DEBUG: Guardando transacción en PostgreSQL');

                                                // Declarar las variables fuera del bloque try para que estén disponibles en todo el ámbito
                                                final apiServiceSale = ApiService();
                                                SaleTransactionModel post;
                                                String? saleId;

                                                try {
                                                  (double.tryParse(dueAmountController.text) ?? 0) <= 0 ? transitionModel.isPaid = true : transitionModel.isPaid = false;
                                                  (double.tryParse(dueAmountController.text) ?? 0) <= 0 ? transitionModel.dueAmount = 0 : transitionModel.dueAmount = (double.tryParse(dueAmountController.text) ?? 0);
                                                  (double.tryParse(changeAmountController.text) ?? 0) > 0 ? transitionModel.returnAmount = (double.tryParse(changeAmountController.text) ?? 0).abs() : transitionModel.returnAmount = 0;
                                                  transitionModel.paymentType = selectedPaymentOption;
                                                  // Agregar información del banco si es transferencia
                                                  if (selectedPaymentOption == 'Transferencia') {
                                                    transitionModel.bankId = selectedBankId;
                                                    transitionModel.bankName = selectedBankName;
                                                  }
                                                  // Obtener el nombre real del usuario actual
                                                  transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                                                  post = checkLossProfit(transitionModel: transitionModel);
                                                  final saleResponse = await apiServiceSale.post('sales', Map<String, dynamic>.from(post.toJson()));
                                                  saleId = saleResponse.data?['id']?.toString() ?? saleResponse.data?['sale']?['id']?.toString();

                                                  // IMPORTANTE: Extraer número de factura atómico generado por el servidor
                                                  String? serverInvoiceNum;
                                                  final saleData = saleResponse.data;
                                                  if (saleData != null) {
                                                    serverInvoiceNum = saleData['invoice_number']?.toString() ??
                                                                       (saleData['sale'] as Map<String, dynamic>?)?['invoice_number']?.toString() ??
                                                                       saleData['invoiceNumber']?.toString() ??
                                                                       (saleData['sale'] as Map<String, dynamic>?)?['invoiceNumber']?.toString();
                                                  }
                                                  if (serverInvoiceNum != null && serverInvoiceNum.isNotEmpty && serverInvoiceNum != 'null') {
                                                    post.invoiceNumber = serverInvoiceNum;
                                                    transitionModel.invoiceNumber = serverInvoiceNum;
                                                    invoiceNumber = serverInvoiceNum;
                                                  }
                                                  print('DEBUG: Transacción guardada exitosamente');
                                                  
                                                  // Registrar auditoría de la venta
                                                  await AuditService().logSale(
                                                    invoiceNumber: post.invoiceNumber,
                                                    customerName: post.customerName,
                                                    amount: post.totalAmount ?? 0.0,
                                                    products: cartList.map((item) => {
                                                      'productName': item.productName,
                                                      'productId': item.productId,
                                                      'quantity': item.quantity,
                                                      'unitPrice': item.unitPrice,
                                                      'subTotal': item.subTotal,
                                                      'isReservation': item.isReservation ?? false,
                                                    }).toList(),
                                                  );

                                                  // DEBUG: Verificar valores ANTES de la condición
                                                  print('═══════════════════════════════════════════════════════════════');
                                                  print('DEBUG TRANSFER VERIFICATION - ANTES DE CONDICIÓN');
                                                  print('  selectedPaymentOption: "$selectedPaymentOption"');
                                                  print('  transferReceiptUrl: ${transferReceiptUrl ?? "NULL"}');
                                                  print('  Condición evaluada: ${selectedPaymentOption == 'Transferencia' && transferReceiptUrl != null}');
                                                  print('═══════════════════════════════════════════════════════════════');

                                                  // Crear registro de verificación de transferencia si aplica
                                                  if (selectedPaymentOption == 'Transferencia' && transferReceiptUrl != null) {
                                                    try {
                                                      // CORREGIDO: Usar post.totalAmount en lugar de payingAmountController.text
                                                      // porque payingAmountController puede estar vacío o con valor incorrecto
                                                      final transferAmount = post.totalAmount ?? 0.0;

                                                      print('DEBUG: Creando registro de verificación de transferencia...');
                                                      print('DEBUG: branchId: ${ApiService().branchId}');
                                                      print('DEBUG: invoiceNumber: ${post.invoiceNumber}');
                                                      print('DEBUG: customerName: ${post.customerName}');
                                                      print('DEBUG: bankName: $selectedBankName');
                                                      print('DEBUG: holderName: ${transferHolderNameController.text.trim()}');
                                                      print('DEBUG: amount (post.totalAmount): $transferAmount');
                                                      print('DEBUG: receiptUrl: $transferReceiptUrl');

                                                      final transferVerification = TransferVerificationModel(
                                                        branchId: ApiService().branchId ?? 'sdo',
                                                        saleId: saleId,
                                                        invoiceNumber: post.invoiceNumber,
                                                        customerName: post.customerName,
                                                        customerPhone: post.customerPhone,
                                                        customerEmail: selectedUserName?.emailAddress,
                                                        bankName: selectedBankName ?? '',
                                                        holderName: transferHolderNameController.text.trim(),
                                                        referenceNumber: transferReferenceController.text.trim().isNotEmpty
                                                            ? transferReferenceController.text.trim()
                                                            : null,
                                                        transferDate: DateTime.now().toIso8601String(),
                                                        amount: transferAmount,
                                                        receiptUrl: transferReceiptUrl!,
                                                        status: 'pending',
                                                        sellerName: isSubUser ? constSubUserTitle : 'Admin',
                                                        createdAt: DateTime.now().toIso8601String(),
                                                      );

                                                      final result = await transferVerificationRepository.createTransfer(transferVerification);
                                                      if (result != null) {
                                                        print('DEBUG: Registro de verificación de transferencia creado exitosamente - ID: ${result.id}');
                                                        EasyLoading.showInfo('Transferencia registrada para verificación');
                                                      } else {
                                                        print('ERROR: createTransfer retornó null');
                                                      }
                                                    } catch (e, stackTrace) {
                                                      print('ERROR al crear verificación de transferencia: $e');
                                                      print('Stack trace: $stackTrace');
                                                      // No bloquear la venta si falla la creación del registro
                                                    }
                                                  }
                                                } catch (e) {
                                                  print('ERROR al guardar transacción: $e');
                                                  EasyLoading.showError('Error al guardar la venta: ${e.toString()}');
                                                  setState(() => saleButtonClicked = false);
                                                  return;
                                                }

                                                //imprimir factura
                                                print('DEBUG POST-TRANSFER: Iniciando proceso de impresión/WhatsApp');
                                                print('DEBUG POST-TRANSFER: sendWhatsApp=$sendWhatsApp, printType=$printType');

                                                if (sendWhatsApp) {
                                                  try {
                                                    print('DEBUG POST-TRANSFER: Generando PDF para WhatsApp...');
                                                    // Generar PDF para WhatsApp
                                                    final pdfData = await GeneratePdfAndPrint().printSaleInvoice(
                                                      personalInformationModel: data,
                                                      saleTransactionModel: transitionModel,
                                                      context: context,
                                                      fromInventorySale: true,
                                                      setting: setting,
                                                      printType: 'normal',
                                                      post: post,
                                                      returnPdfData: true,
                                                    );
                                                    print('DEBUG POST-TRANSFER: PDF generado, pdfData=${pdfData != null ? "OK" : "NULL"}');

                                                    if (pdfData != null) {
                                                      print('DEBUG POST-TRANSFER: Enviando PDF por WhatsApp...');
                                                      await _sendPdfViaWhatsApp(
                                                        phoneNumber: transitionModel.customerPhone,
                                                        pdfData: pdfData,
                                                        invoiceNumber: transitionModel.invoiceNumber,
                                                        customerName: transitionModel.customerName,
                                                      );
                                                      print('DEBUG POST-TRANSFER: PDF enviado por WhatsApp');
                                                    }
                                                  } catch (e, stackTrace) {
                                                    print('ERROR POST-TRANSFER WhatsApp: $e');
                                                    print('Stack trace: $stackTrace');
                                                    EasyLoading.showError('Error al enviar por WhatsApp: ${e.toString()}');
                                                  }
                                                }

                                                try {
                                                  if (printType == 'normal' || printType == 'both') {
                                                    print('DEBUG POST-TRANSFER: Generando factura normal...');
                                                    await GeneratePdfAndPrint().printSaleInvoice(
                                                      personalInformationModel: data,
                                                      saleTransactionModel: transitionModel,
                                                      context: context,
                                                      fromInventorySale: true,
                                                      setting: setting,
                                                      printType: 'normal',
                                                      post: post
                                                    );
                                                    print('DEBUG POST-TRANSFER: Factura normal generada');

                                                    // Registrar auditoría de impresión
                                                    await AuditService().logPrint(
                                                      module: AuditModule.sales,
                                                      documentType: 'Factura de Venta',
                                                      documentId: post.invoiceNumber,
                                                    );
                                                  }
                                                } catch (e, stackTrace) {
                                                  print('ERROR POST-TRANSFER factura normal: $e');
                                                  print('Stack trace: $stackTrace');
                                                }

                                                try {
                                                  print('DEBUG POST-TRANSFER: Creando confirmación de venta...');
                                                  final token = const Uuid().v4();

                                                  final userId = await getUserID();
                                                  print('DEBUG POST-TRANSFER: userId=$userId');

                                                  final confirmation = SaleConfirmationModel(
                                                    token: token,
                                                    saleId: saleId ?? post.invoiceNumber,
                                                    userId: userId,
                                                    confirmed: false,
                                                    createdAt: DateTime.now().toIso8601String(),
                                                    expiresAt: DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
                                                    saleData: post,
                                                  );

                                                  print('DEBUG POST-TRANSFER: Enviando confirmación al API...');
                                                  await apiServiceSale.post('sale-confirmations', Map<String, dynamic>.from(confirmation.toJson()));
                                                  print('DEBUG POST-TRANSFER: Confirmación enviada');

                                                  final link = 'https://app.victorguzmanfotografia.com/confirmacion/${confirmation.token}'; //santo domingo
                                                  //final link = 'https://stg.victorguzmanfotografia.com/confirmacion/${confirmation.token}'; //santiago

                                                  print('DEBUG POST-TRANSFER: Enviando link de confirmación por WhatsApp...');
                                                  await _sendConfirmationLinkViaWhatsApp(
                                                    phoneNumber: post.customerPhone,
                                                    customerName: post.customerName,
                                                    confirmationLink: link,
                                                  );
                                                  print('DEBUG POST-TRANSFER: Link de confirmación enviado');
                                                } catch (e, stackTrace) {
                                                  print('ERROR POST-TRANSFER confirmación: $e');
                                                  print('Stack trace: $stackTrace');
                                                }

                                                try {
                                                  if (printType == 'thermal' || printType == 'both') {
                                                    print('DEBUG POST-TRANSFER: Generando factura térmica...');
                                                    await GeneratePdfAndPrint().printSaleInvoice(
                                                      personalInformationModel: data,
                                                      saleTransactionModel: transitionModel,
                                                      context: context,
                                                      fromInventorySale: true,
                                                      setting: setting,
                                                      printType: 'thermal',
                                                      post: post,
                                                    );
                                                    print('DEBUG POST-TRANSFER: Factura térmica generada');

                                                    // Registrar auditoría de impresión térmica
                                                    await AuditService().logPrint(
                                                      module: AuditModule.sales,
                                                      documentType: 'Factura Térmica',
                                                      documentId: post.invoiceNumber,
                                                    );
                                                  }
                                                } catch (e, stackTrace) {
                                                  print('ERROR POST-TRANSFER factura térmica: $e');
                                                  print('Stack trace: $stackTrace');
                                                }

                                                limpiarCarro();

                                                // Actualizar stock de productos via API
                                                for (var element in transitionModel.productList!) {
                                                  try {
                                                    // Buscar el producto por código
                                                    final productResponse = await apiServiceSale.get('products', queryParams: {
                                                      'productCode': element.productId,
                                                      'limit': '1',
                                                    });

                                                    if (productResponse.success && productResponse.data != null) {
                                                      final productsList = productResponse.data['products'] as List<dynamic>? ?? [];
                                                      if (productsList.isNotEmpty) {
                                                        final productData = Map<String, dynamic>.from(productsList.first);
                                                        final productId = productData['id']?.toString();
                                                        final currentStock = num.tryParse(productData['productStock']?.toString() ?? '0') ?? 0;
                                                        final remainStock = currentStock - element.quantity;

                                                        if (productId != null) {
                                                          // Actualizar el stock
                                                          Map<String, dynamic> updateData = {'productStock': '$remainStock'};

                                                          // Actualizar serial numbers si es necesario
                                                          if (element.serialNumber?.isNotEmpty ?? false) {
                                                            final oldSerialList = productData['serialNumber'] as List<dynamic>? ?? [];
                                                            final result = oldSerialList.where((item) => !element.serialNumber!.contains(item)).toList();
                                                            updateData['serialNumber'] = result;
                                                          }

                                                          await apiServiceSale.put('products/$productId', updateData);
                                                        }
                                                      }
                                                    }
                                                  } catch (e) {
                                                    print('Error al actualizar stock del producto ${element.productId}: $e');
                                                  }
                                                }

                                                updateInvoice(typeOfInvoice: 'saleInvoiceCounter', invoice: transitionModel.invoiceNumber.toInt());

                                                Subscription.decreaseSubscriptionLimits(itemType: 'saleNumber', context: context);

                                                DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                                  name: post.customerName,
                                                  date: post.purchaseDate,
                                                  type: post.saleType == 'adicionales' ? 'Adicionales' : 
                                                        post.saleType == 'impresiones' ? 'Impresiones' : 'Sale',
                                                  total: post.totalAmount!.toDouble(),
                                                  paymentIn: post.totalAmount!.toDouble() - post.dueAmount!.toDouble(),
                                                  paymentOut: 0,
                                                  remainingBalance: post.totalAmount!.toDouble() - post.dueAmount!.toDouble(),
                                                  id: post.invoiceNumber,
                                                  saleTransactionModel: post,
                                                );
                                                postDailyTransaction(dailyTransactionModel: dailyTransaction);

                                                if (transitionModel.customerName != 'Guest') {
                                                  try {
                                                    // Buscar cliente por teléfono
                                                    final customerResponse = await apiServiceSale.get('customers', queryParams: {
                                                      'phoneNumber': transitionModel.customerPhone,
                                                      'limit': '1',
                                                    });

                                                    if (customerResponse.success && customerResponse.data != null) {
                                                      final customersList = customerResponse.data['customers'] as List<dynamic>? ?? [];
                                                      if (customersList.isNotEmpty) {
                                                        final customerData = Map<String, dynamic>.from(customersList.first);
                                                        final customerId = customerData['id']?.toString();
                                                        int previousDue = int.tryParse(customerData['due']?.toString() ?? '0') ?? 0;
                                                        int totalDue = previousDue + transitionModel.dueAmount!.toInt();

                                                        if (customerId != null) {
                                                          await apiServiceSale.put('customers/$customerId', {
                                                            'due': '$totalDue',
                                                            'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                                                          });
                                                        }
                                                      }
                                                    }
                                                  } catch (e) {
                                                    print('Error al actualizar due del cliente: $e');
                                                  }
                                                }

                                                // ignore: unused_result
                                                consumerRef.refresh(allCustomerProvider);
                                                // ignore: unused_result
                                                consumerRef.refresh(transitionProvider);
                                                // ignore: unused_result
                                                consumerRef.refresh(productProvider);
                                                // ignore: unused_result
                                                consumerRef.refresh(purchaseTransitionProvider);
                                                // ignore: unused_result
                                                consumerRef.refresh(dueTransactionProvider);
                                                // ignore: unused_result
                                                consumerRef.refresh(profileDetailsProvider);
                                                // ignore: unused_result
                                                consumerRef.refresh(dailyTransactionProvider);

                                                EasyLoading.showSuccess(lang.S.of(context).saleSuccessfullyDone);
                                                setState(() => saleButtonClicked = false);
                                              } catch (e) {
                                                print('ERROR durante el proceso de pago: $e');
                                                setState(() {
                                                  saleButtonClicked = false;
                                                });
                                                EasyLoading.dismiss();
                                                EasyLoading.showError('Error: ${e.toString()}');
                                              }
                                            }
                                          }
                                        } else {
                                          print('DEBUG: Suscripción no válida o límite excedido');
                                          EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                        }
                                      } else {
                                        print('DEBUG: Usuario NO tiene permisos de venta (checkUserRoleEditPermissionV2 retornó false)');
                                        EasyLoading.showError('No tiene permisos para realizar ventas');
                                      }
                                    },
                                    child: Text(
                                      lang.S.of(context).payment,
                                    ),
                                  ),
                                );
                              }, error: (e, stack) {
                                return Text(e.toString());
                              }, loading: () {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              })),
                          if (screenWidth > 1240) ResponsiveGridCol(lg: 3, xs: 0, md: 0, child: const SizedBox.shrink()),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            );
          }, error: (e, stack) {
            return Center(child: Text(e.toString()));
          }, loading: () {
            return const Center(child: CircularProgressIndicator());
          });
        }),
      ),
    );
  }

  void limpiarCarro() {
    setState(() {

      cartList.clear(); // Limpia la lista de productos
      productFocusNode.clear(); // Limpia los focus nodes
      _hasVestimentasFromDialog = false; // RESETEAR: limpia el indicador de vestimentas
      _hasImpresionEnmarcado = false; // RESETEAR: limpia el indicador de impresión/enmarcado
      payingAmountController.text = '0'; // Resetea el monto pagado
      changeAmountController.text = '0'; // Resetea el cambio
      dueAmountController.text = '0'; // Resetea el adeudo
      discountAmountEditingController.clear(); // Limpia el descuento en monto
      discountPercentageEditingController.clear(); // Limpia el descuento en porcentaje
      serviceCharge = 0; // Resetea el cargo por servicio
      discountAmount = 0; // Resetea el monto de descuento
      vatGst = 0; // Resetea los impuestos
      discountFieldsEnabled = false; // Resetea la protección de descuentos
      // Resetea campos de transferencia
      transferHolderNameController.clear();
      transferReferenceController.clear();
      transferReceiptUrl = null;
    });
  }

  Future<void> _showDiscountAuthDialog() async {
    TextEditingController passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text('Autenticación Requerida'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingrese la clave para habilitar los campos de descuento:'),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Clave de descuento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.key),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _validatePasswordSafe(dialogContext, value.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  _validatePasswordSafe(dialogContext, password);
                } else {
                  EasyLoading.showError('Ingrese la clave');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  void _validatePasswordSafe(BuildContext dialogContext, String password) async {
    // Validar contraseña con Firebase
    final isValid = await DeletionPasswordService.validatePassword(password);

    if (isValid) {
      // Cerrar el diálogo
      Navigator.of(dialogContext).pop();

      // Actualizar el estado después de un pequeño delay
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            discountFieldsEnabled = true;
          });
          EasyLoading.showSuccess('Campos de descuento habilitados');
        }
      });
    } else {
      EasyLoading.showError('Clave incorrecta');
    }
  }
}