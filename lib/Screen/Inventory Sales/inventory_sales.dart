import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
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
import '../../subscription.dart';
import '../Product/WarebasedProduct.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class InventorySales extends StatefulWidget {
  const InventorySales({super.key, this.quotation});

  final SaleTransactionModel? quotation;

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
  DateTime selectedDueDate = DateTime.now();

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();
  TextEditingController discountAmountEditingController =
      TextEditingController();
  TextEditingController discountPercentageEditingController =
      TextEditingController();
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

  WareHouseModel? selectedWareHouse;
  int i = 0;

  List<String> get paymentItem => ['Efectivo', 'Transferencia', 'Tarjeta'];
  List<String> get customerType => ['Minorista', 'Mayorista', 'Distribuidor'];

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    payingAmountController.text = '0';
    checkInternet();
    updateDueAmount();

    if (widget.quotation != null) {
      for (var element in widget.quotation!.productList!) {
        cartList.add(element);
        addFocus();
      }
      discountAmountEditingController.text =
          widget.quotation!.discountAmount!.toStringAsFixed(2);
      discountAmount = widget.quotation!.discountAmount!;
      serviceCharge = widget.quotation!.discountAmount!;
      selectedUserName?.customerName = widget.quotation!.customerName;
      selectedUserName?.phoneNumber = widget.quotation!.customerPhone;
      selectedUserName?.type = widget.quotation!.customerType;
    }
  }

  void updateDueAmount() {
    setState(() {
      double total = double.parse(
        (double.parse(getTotalAmount()) +
                serviceCharge -
                discountAmount +
                vatGst)
            .toStringAsFixed(1),
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
      color: Colors.grey[700], // Esto no puede ser const
    );

    final TextStyle smallGreyTextStyleBold = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Colors.black, // Esto no puede ser const
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
                      maxWidth: 500, // Limit maximum width
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with close button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .titleLarge
                                      ?.color,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .titleLarge
                                      ?.color,
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
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final full = reservations[index];
                              final reservation = full.reservation;
                              final dress = full.dress;
                              final service = full.service;

                              // Get dress image URL or use default
                              // Obtener la primera imagen del campo 'images'
                              final rawImages = dress?['images'] ?? '';
                              final dressImageUrl = rawImages
                                  .toString()
                                  .split(',')
                                  .first
                                  .trim()
                                  .replaceAll(RegExp(r'[\[\]"]'), '');

                              // Verificar si no es reserva de paquetes compuestos
                              bool isCommonReservation =
                                  full.multipleDress.isEmpty;

                              // Mapeo Nuevo de acuerdo a la estructura de vestidos

                              if (isCommonReservation) {
                                final reservationModel =
                                    ReservationProductModel.fromMap({
                                  'id': full.id,
                                  'service_id': service?['id'] ?? '',
                                  'service_name':
                                      service?['name'] ?? 'Servicio',
                                  'client_id': clientId,
                                  'dress_id': dress?['id'] ?? '',
                                  'dress_name': dress?['name'] ?? 'Vestido',
                                  'branch_id': reservation['branch_id'] ?? '',
                                  'reservation_date':
                                      reservation['reservation_date'] ?? '',
                                  'reservation_time':
                                      reservation['reservation_time'] ?? '',
                                  'price': service != null &&
                                          service['price'] != null
                                      ? (service['price'] is num
                                          ? (service['price'] as num).toDouble()
                                          : 0.0)
                                      : 0.0,
                                  'created_at': reservation['created_at'],
                                  'updated_at': reservation['updated_at'],
                                  'duration': service?['duration'] ?? {},
                                  'package_price': double.tryParse(
                                      reservation['package_price'] ?? '0.0')
                                });

                                // Verifico si es Adicional de Reserva para poner algo que lo identifique y ademas el precio

                                return InkWell(
                                  onTap: () {
                                    _addReservationToCart(reservationModel);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    child: Row(
                                      children: [
                                        // Dress image
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              dressImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[400],
                                                    size: 30),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${service?['name'] ?? 'Servicio'} - ${dress?['name'] ?? 'Vestido'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '📅 Fecha: ${reservation['reservation_date']} a las ${reservation['reservation_time']}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '🏬 Sucursal: ${reservation['branch_id']}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '👗 Vestido: ${dress?['name'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '🔖 Categoría: ${dress?['category'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '🛎️ Servicio: ${service?['name'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '⏱️ Duración: ${ReservationUtils.formatDuration(service?['duration'])}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '📝 Descripción:\n${service?['description'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                            ],
                                          ),
                                        ),

                                        // Price and add icon
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              reservationModel.packagePrice > 0
                                                  ? '\$${reservationModel.packagePrice.toStringAsFixed(2)}'
                                                  : '\$${reservationModel.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                Icons.add_shopping_cart,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                final reservationModel =
                                    ReservationProductCompositeModel.fromMap({
                                  'id': full.id,
                                  'service_id': service?['id'] ?? '',
                                  'service_name':
                                      service?['name'] ?? 'Servicio',
                                  'client_id': clientId,
                                  'reservation_date':
                                      reservation['reservation_date'] ?? '',
                                  'reservation_time':
                                      reservation['reservation_time'] ?? '',
                                  'price': service != null &&
                                          service['price'] != null
                                      ? (service['price'] is num
                                          ? (service['price'] as num).toDouble()
                                          : 0.0)
                                      : 0.0,
                                  'created_at': reservation['created_at'],
                                  'updated_at': reservation['updated_at'],
                                  'duration': service?['duration'] ?? {},
                                  'dress_info': full.multipleDress,
                                  'package_price': double.tryParse(
                                      reservation['package_price'] ?? '0.0')
                                });

                                return InkWell(
                                  onTap: () {
                                    _addReservationCompositeToCart(
                                        reservationModel);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    child: Row(
                                      children: [
                                        // Dress image
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              dressImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[400],
                                                    size: 30),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${service?['name'] ?? 'Servicio'} - ${dress?['name'] ?? 'Combo de Vestimentas'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '📅 Fecha: ${reservation['reservation_date']} a las ${reservation['reservation_time']}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text('👗 Vestimentas Reservadas:',
                                                  style:
                                                      smallGreyTextStyleBold),
                                              const SizedBox(height: 2),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, right: 8),
                                                child: _showDressesOption(
                                                    full.multipleDress),
                                              ),
                                              Text(
                                                  '🔖 Categoría: ${service?['category'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '🛎️ Servicio: ${service?['name'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '⏱️ Duración: ${ReservationUtils.formatDuration(service?['duration'])}',
                                                  style: smallGreyTextStyle),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '📝 Descripción:\n${service?['description'] ?? '-'}',
                                                  style: smallGreyTextStyle),
                                            ],
                                          ),
                                        ),

                                        // Price and add icon
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              reservationModel.packagePrice > 0
                                                  ? '\$${reservationModel.packagePrice.toStringAsFixed(2)}'
                                                  : '\$${reservationModel.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                Icons.add_shopping_cart,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .primaryColor,
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

  void _addReservationToCart(ReservationProductModel reservation) {
    setState(() {
      cartList.add(
        reservation.toCartItem()..reservationId = reservation.id, // Asignar ID
      );
      addFocus();
      updateDueAmount();
    });
  }

  void _addReservationCompositeToCart(
      ReservationProductCompositeModel reservation) {
    setState(() {
      cartList.add(
        reservation.toCartCompositeItem()
          ..reservationId = reservation.id, // Asignar ID
      );
      addFocus();
      updateDueAmount();
    });
  }

  Future<void> checkInternet() async {
    bool isDeviceConnected = await InternetConnection().hasInternetAccess;
    if (!isDeviceConnected) {
      showDialogBox();
      setState(() => isAlertSet = true);
    }
  }

  Future<int> getLastInvoiceNumber() async {
    int lastInvoiceNumber =
        invoiceNumber == null ? 0 : int.tryParse(invoiceNumber!) ?? 0;

    String typeOfInvoice = 'saleInvoiceCounter';

    final DatabaseReference personalInformationRef = FirebaseDatabase.instance
        .ref()
        .child(await getUserID())
        .child('Personal Information');

    // Ver el Nro de Ultima Factura
    final snapshot = await personalInformationRef.child(typeOfInvoice).get();

    lastInvoiceNumber = (snapshot.value != null
        ? int.tryParse(snapshot.value.toString()) ?? 0
        : 0);
    lastInvoiceNumber += 1;

    return lastInvoiceNumber;
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
                bool isDeviceConnected =
                    await InternetConnection().hasInternetAccess;
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
      total = total + (double.parse(item.subTotal) * item.quantity);
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

  dynamic productPriceChecker(
      {required ProductModel product, required String customerType}) {
    if (customerType == "Retailer") {
      return product.productSalePrice;
    } else if (customerType == "Wholesaler") {
      return product.productWholeSalePrice == ''
          ? '0'
          : product.productWholeSalePrice;
    } else if (customerType == "Dealer") {
      return product.productDealerPrice == ''
          ? '0'
          : product.productDealerPrice;
    } else if (customerType == "Guest") {
      return product.productSalePrice;
    }
  }

  Future<void> _selectedDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDueDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
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

        return _buildInfoItem(
            dressName, branchId); // Asegúrate que retorne un Widget
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
        });
      },
    );
  }

// Añade al pubspec.yaml:
// searchable_dropdown: ^1.1.3

// Implementation of the search dialog with a modern look
  Future<CustomerModel?> _showCustomerSearchDialog(
    BuildContext context,
    List<CustomerModel> customers,
    List<ReservationModel> reservations,
  ) async {
    TextEditingController searchController = TextEditingController();
    List<CustomerModel> filteredCustomers = List.from(customers);
    bool switchValue = false;

    return showDialog<CustomerModel>(
      context: context,
      builder: (BuildContext context) {
        // Obtenemos el tamaño de la pantalla
        final screenSize = MediaQuery.of(context).size;
        return StatefulBuilder(
          builder: (context, setState) {
            // Lógica de filtrado dinámica dentro del builder
            filteredCustomers = customers.where((customer) {
              final matchesSearch = searchController.text.isEmpty ||
                  customer.customerName
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase()) ||
                  customer.phoneNumber
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase());

              final hasReservation = reservations.any(
                (res) => res.clientId == customer.phoneNumber,
              );

              return matchesSearch &&
                  (!switchValue ||
                      hasReservation); // si el switch está activo, filtra
            }).toList();

            return Dialog(
              // Limitamos el ancho del diálogo
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenSize.width > 600
                    ? (screenSize.width - 700) /
                        2 // En pantallas grandes, ancho fijo de 400
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
                      color: Colors.black.withOpacity(0.1),
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
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente...',
                        prefixIcon: const Icon(Icons.search, size: 18),
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
                        setState(() {});
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
                      child: filteredCustomers.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
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
                                      style: TextStyle(
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return InkWell(
                                  onTap: () => Navigator.pop(context, customer),
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
                                            customer.customerName.isNotEmpty
                                                ? customer.customerName[0]
                                                    .toUpperCase()
                                                : '?',
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
    List<DropdownMenuItem<String>> dropDownItems = [
      DropdownMenuItem(value: 'Guest', child: Text(lang.S.of(context).guest))
    ];
    for (var des in model) {
      var item = DropdownMenuItem(
        alignment: Alignment.centerLeft,
        value: des.phoneNumber,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${des.customerName} ${des.phoneNumber}',
            softWrap: true,
            style: kTextStyle.copyWith(
                color: kTitleColor, overflow: TextOverflow.ellipsis),
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
              selectedCustomerType == element.type
                  ? null
                  : {
                      selectedCustomerType = element.type,
                      cartList.clear(),
                      productFocusNode.clear()
                    };
            } else if (selectedUserId == 'Guest') {
              previousDue = '0';
              selectedCustomerType = 'Retailer';
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
          style: kTextStyle.copyWith(
              color: kTitleColor, overflow: TextOverflow.ellipsis),
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
    for (var element in list) {
      dropDownItems.add(DropdownMenuItem(
        value: element,
        child: Text(
          element.warehouseName,
          style: kTextStyle.copyWith(color: kGreyTextColor),
          overflow: TextOverflow.ellipsis,
        ),
      ));
      if (element.warehouseName == 'SANTIAGO') {
        selectedWareHouse = element;
      }
      i++;
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
          AsyncValue<List<ProductModel>> productList =
              consumerRef.watch(productProvider);

          return personalData.when(data: (data) {
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
                          padding: const EdgeInsets.only(left: 12, top: 12),
                          child: Text(
                            lang.S.of(context).inventorySales,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        const Divider(thickness: 1.0, color: kNeutral300),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: ElevatedButton(
                            onPressed: () =>
                                showReservationSelection(selectedUserId!),
                            child: Text('Agregar Reserva'),
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
                                      hintText:
                                          '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
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
                                  listOfPhoneNumber.add(value1.phoneNumber
                                      .replaceAll(RegExp(r'\s+'), '')
                                      .toLowerCase());
                                  if (value1.type != 'Supplier') {
                                    customersList.add(value1);
                                  }
                                }

                                // Return the Consumer widget - this was missing before
                                return Consumer(
                                  builder: (context, ref, child) {
                                    final customerListAsyncValue =
                                        ref.watch(allCustomerProvider);

                                    return customerListAsyncValue.when(
                                      data: (customerList) {
                                        return GestureDetector(
                                          onTap: () async {
                                            ref.invalidate(
                                                reservationsFutureProvider);
                                            final reservations = await ref.read(
                                                reservationsFutureProvider
                                                    .future);
                                            CustomerModel? selectedCustomer =
                                                await _showCustomerSearchDialog(
                                              context,
                                              customerList,
                                              reservations,
                                            );

                                            if (selectedCustomer != null) {
                                              setState(() {
                                                clientename = selectedCustomer
                                                    .customerName;
                                                selectedUserId =
                                                    selectedCustomer
                                                        .phoneNumber;

                                                // Agregando la funcionalidad del DropdownButton original
                                                selectedUserName =
                                                    selectedCustomer;
                                                previousDue =
                                                    selectedCustomer.dueAmount;

                                                // Verificar si cambió el tipo de cliente y limpiar el carrito si es necesario
                                                if (selectedCustomerType !=
                                                    selectedCustomer.type) {
                                                  selectedCustomerType =
                                                      selectedCustomer.type;
                                                  cartList.clear();
                                                  productFocusNode.clear();
                                                }

                                                invoiceNumber = '';

                                                invoiceNumber = '';
                                              });
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              color: Colors.white,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 11),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedUserId != null
                                                        ? clientename ??
                                                            "--Seleccione Cliente--"
                                                        : "--Seleccione Cliente--",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          selectedUserId != null
                                                              ? Colors.black87
                                                              : Colors.grey
                                                                  .shade600,
                                                      fontWeight:
                                                          selectedUserId != null
                                                              ? FontWeight.w500
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          color: Colors.white,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        ),
                                      ),
                                      error: (error, stackTrace) => Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.red.shade300),
                                          color: Colors.red.shade50,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.red.shade700,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Error al cargar clientes',
                                                style: TextStyle(
                                                    color: Colors.red.shade700),
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
                                        builder:
                                            (FormFieldState<dynamic> field) {
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
                                allProductsNameList.add(element.productName
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                allProductsCodeList.add(element.productCode
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                warehouseIdList.add(element.warehouseId
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                warehouseBasedProductModel.add(
                                    WarehouseBasedProductModel(
                                        element.productName,
                                        element.warehouseId));
                              }
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TypeAheadField(
                                  suggestionsCallback: (pattern) {
                                    ProductRepo pr = ProductRepo();
                                    return pr.getAllProductByJsonWarehouse(
                                        searchData: pattern,
                                        warehouseId: selectedWareHouse!);
                                  },
                                  itemBuilder: (context, suggestion) {
                                    ProductModel product =
                                        ProductModel.fromJson(
                                      jsonDecode(
                                        jsonEncode(suggestion),
                                      ),
                                    );
                                    return ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          10.0, 5.0, 15.0, 5.0),
                                      horizontalTitleGap: 10.0,
                                      leading: Container(
                                        height: 45.0,
                                        width: 45.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: kBorderColorTextField),
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                  product.productPicture),
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      title: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: Text(
                                                '${lang.S.of(context).name}: ${product.productName}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(
                                                    color: kTitleColor,
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )),
                                          const Spacer(),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${lang.S.of(context).purchasePrice}: $globalCurrency${product.productPurchasePrice}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(
                                                    color: kGreyTextColor,
                                                    fontSize: 12.0),
                                              )),
                                          const Spacer(),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                  '${lang.S.of(context).salePrice}: $globalCurrency${product.productSalePrice}',
                                                  textAlign: TextAlign.start,
                                                  style: kTextStyle.copyWith(
                                                      color: kGreyTextColor,
                                                      fontSize: 12.0))),
                                          const Spacer(),
                                          Expanded(
                                            flex: 0,
                                            child: Text(
                                                '${lang.S.of(context).stock}: ${product.productStock}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(
                                                    color: kGreyTextColor,
                                                    fontSize: 12.0)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onSelected: (suggestion) {
                                    ProductModel product =
                                        ProductModel.fromJson(
                                            jsonDecode(jsonEncode(suggestion)));
                                    AddToCartModel addToCartModel =
                                        AddToCartModel(
                                            productName: product.productName,
                                            warehouseName:
                                                product.warehouseName,
                                            warehouseId: product.warehouseId,
                                            productId: product.productCode,
                                            quantity: 1,
                                            productImage:
                                                product.productPicture,
                                            stock: int.tryParse(
                                                    product.productStock) ??
                                                0,
                                            productPurchasePrice:
                                                double.tryParse(product
                                                        .productPurchasePrice) ??
                                                    0.0,
                                            subTotal: productPriceChecker(
                                              product: product,
                                              customerType:
                                                  selectedCustomerType,
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
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          labelText:
                                              lang.S.of(context).selectProduct,
                                          hintText: lang.S
                                              .of(context)
                                              .searchWithProductName,
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
                                        child: Theme(
                                            data: ThemeData(
                                                highlightColor:
                                                    dropdownItemColor,
                                                focusColor: Colors.transparent,
                                                hoverColor: dropdownItemColor),
                                            child: DropdownButtonHideUnderline(
                                                child: getCategories())));
                                  },
                                ),
                              ),
                            ),
                          )
                        ]),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            final kWidth = constraints.maxWidth - 20;
                            return Scrollbar(
                              controller: horizontalScroll,
                              thickness: 8,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                                    data: theme.copyWith(
                                        dividerColor: Colors.transparent,
                                        dividerTheme: const DividerThemeData(
                                            color: Colors.transparent)),
                                    child: DataTable(
                                        border: TableBorder.all(
                                          color: kNeutral300,
                                          width: 1.0,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        dividerThickness: 0.0,
                                        dataRowColor:
                                            const WidgetStatePropertyAll(
                                                Colors.white),
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                                const Color(0xFFF8F3FF)),
                                        showBottomBorder: false,
                                        headingTextStyle:
                                            theme.textTheme.titleMedium,
                                        dataTextStyle:
                                            theme.textTheme.bodyLarge,
                                        columns: [
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).productNam,
                                          )),
                                          DataColumn(
                                              headingRowAlignment:
                                                  MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).quantity,
                                              )),
                                          DataColumn(
                                              headingRowAlignment:
                                                  MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).price,
                                              )),
                                          DataColumn(
                                              headingRowAlignment:
                                                  MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).subTotal,
                                              )),
                                          DataColumn(
                                              headingRowAlignment:
                                                  MainAxisAlignment.center,
                                              label: Text(
                                                lang.S.of(context).action,
                                              )),
                                        ],
                                        rows: List.generate(cartList.length,
                                            (index) {
                                          TextEditingController
                                              quantityController =
                                              TextEditingController(
                                                  text: cartList[index]
                                                      .quantity
                                                      .toString());
                                          return DataRow(cells: [
                                            DataCell(
                                              Text(
                                                cartList[index].productName ??
                                                    '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                            DataCell(Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        cartList[index]
                                                                    .quantity >
                                                                1
                                                            ? cartList[index]
                                                                .quantity--
                                                            : cartList[index]
                                                                .quantity = 1;
                                                        updateDueAmount();
                                                      });
                                                    },
                                                    child: const Icon(
                                                        FontAwesomeIcons
                                                            .solidSquareMinus,
                                                        color: kBlueTextColor)),
                                                Container(
                                                  width: 60,
                                                  height: 35,
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10.0,
                                                          right: 10.0,
                                                          top: 2.0,
                                                          bottom: 2.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2.0),
                                                    color: Colors.white,
                                                  ),
                                                  child: TextFormField(
                                                    controller:
                                                        quantityController,
                                                    focusNode:
                                                        productFocusNode[index],
                                                    textAlign: TextAlign.center,
                                                    onChanged: (value) {
                                                      if ((cartList[index]
                                                                  .stock ??
                                                              0) <
                                                          (num.tryParse(
                                                                  value) ??
                                                              0)) {
                                                        EasyLoading.showError(
                                                            lang.S
                                                                .of(context)
                                                                .outOfStock);
                                                        quantityController
                                                            .clear();
                                                      } else if (value == '') {
                                                        cartList[index]
                                                            .quantity = 1;
                                                      } else if (value == '0') {
                                                        cartList[index]
                                                            .quantity = 1;
                                                      } else {
                                                        cartList[index]
                                                                .quantity =
                                                            (num.tryParse(
                                                                    value) ??
                                                                1);
                                                      }
                                                    },
                                                    onFieldSubmitted: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index]
                                                              .quantity = 1;
                                                          updateDueAmount();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          cartList[index]
                                                                  .quantity =
                                                              (num.tryParse(
                                                                      value) ??
                                                                  1);
                                                          updateDueAmount();
                                                        });
                                                      }
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                            border: InputBorder
                                                                .none),
                                                  ),
                                                ),
                                                GestureDetector(
                                                    onTap: () {
                                                      if (cartList[index]
                                                              .quantity <
                                                          cartList[index]
                                                              .stock!
                                                              .toInt()) {
                                                        setState(() {
                                                          cartList[index]
                                                              .quantity += 1;
                                                          updateDueAmount();
                                                        });
                                                      } else {
                                                        EasyLoading.showError(
                                                            lang.S
                                                                .of(context)
                                                                .outOfStock);
                                                      }
                                                    },
                                                    child: const Icon(
                                                        FontAwesomeIcons
                                                            .solidSquarePlus,
                                                        color: kBlueTextColor)),
                                              ],
                                            )),
                                            DataCell(
                                              Center(
                                                child: SizedBox(
                                                  width: 70,
                                                  height: 35,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.center,
                                                    initialValue: myFormat
                                                        .format(double.tryParse(
                                                                cartList[index]
                                                                    .subTotal) ??
                                                            0),
                                                    onChanged: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index]
                                                                  .subTotal =
                                                              0.toString();
                                                        });
                                                      } else if (double
                                                              .tryParse(
                                                                  value) ==
                                                          null) {
                                                        EasyLoading.showError(lang
                                                            .S
                                                            .of(context)
                                                            .enterAValidPrice);
                                                      } else {
                                                        setState(() {
                                                          cartList[index]
                                                              .subTotal = double
                                                                  .parse(value)
                                                              .toStringAsFixed(
                                                                  2);
                                                        });
                                                      }
                                                      updateDueAmount();
                                                    },
                                                    onFieldSubmitted: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index]
                                                                  .subTotal =
                                                              0.toString();
                                                          updateDueAmount();
                                                        });
                                                      } else if (double
                                                              .tryParse(
                                                                  value) ==
                                                          null) {
                                                        EasyLoading.showError(lang
                                                            .S
                                                            .of(context)
                                                            .enterAValidPrice);
                                                      } else {
                                                        setState(() {
                                                          cartList[index]
                                                              .subTotal = double
                                                                  .parse(value)
                                                              .toStringAsFixed(
                                                                  2);
                                                          updateDueAmount();
                                                        });
                                                      }
                                                    },
                                                    decoration: InputDecoration(
                                                        border:
                                                            InputBorder.none),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$globalCurrency${myFormat.format(double.tryParse((double.parse(cartList[index].subTotal) * cartList[index].quantity).toStringAsFixed(2)) ?? 0)}',
                                                  style:
                                                      theme.textTheme.bodyLarge,
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
                                                      cartList.removeAt(index);
                                                      productFocusNode
                                                          .removeAt(index);
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
                                          double total = double.parse(
                                              (double.parse(getTotalAmount()) +
                                                      serviceCharge -
                                                      discountAmount +
                                                      vatGst)
                                                  .toStringAsFixed(1));

                                          double paidAmount =
                                              double.parse(value);
                                          if (paidAmount > total) {
                                            changeAmountController.text =
                                                (paidAmount - total).toString();
                                            dueAmountController.text = '0';
                                          } else {
                                            dueAmountController.text =
                                                (total - paidAmount)
                                                    .abs()
                                                    .toStringAsFixed(2);
                                            changeAmountController.text = '0';
                                          }
                                        });
                                      },
                                      controller: payingAmountController,
                                      decoration: InputDecoration(
                                          labelText:
                                              lang.S.of(context).payingAmount,
                                          hintText: lang.S
                                              .of(context)
                                              .enterReceivedAmount),
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
                                      decoration: InputDecoration(
                                          labelText:
                                              lang.S.of(context).dueAmount,
                                          hintText: lang.S
                                              .of(context)
                                              .enterDueAmount),
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
                                        labelText:
                                            lang.S.of(context).changeReturn,
                                        hintText: lang.S
                                            .of(context)
                                            .enterChangeReturn,
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
                                        builder:
                                            (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .paymentType,
                                              hintText: '',
                                            ),
                                            child: Theme(
                                              data: ThemeData(
                                                  highlightColor:
                                                      dropdownItemColor,
                                                  focusColor: dropdownItemColor,
                                                  hoverColor:
                                                      dropdownItemColor),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: getOption(),
                                              ),
                                            ),
                                          );
                                        },
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
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: const Color(0xffF8F1FF)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 19),
                                    child: Column(
                                      children: [
                                        ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 6,
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: screenWidth < 577
                                                      ? 8
                                                      : 0),
                                              child: Text(
                                                lang.S.of(context).totalAmount,
                                                style:
                                                    theme.textTheme.bodyLarge,
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
                                              decoration: const BoxDecoration(
                                                  color: Color(0xff00AE1C),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(8))),
                                              child: Center(
                                                child: Text(
                                                  '$globalCurrency ${myFormat.format(double.tryParse((double.parse(getTotalAmount()) + serviceCharge - discountAmount + vatGst).toStringAsFixed(2)) ?? 0)}',
                                                  style: kTextStyle.copyWith(
                                                      color: kWhite,
                                                      fontSize: 18.0,
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                              padding: EdgeInsets.only(
                                                  bottom: screenWidth < 577
                                                      ? 8
                                                      : 0),
                                              child: Text(
                                                lang.S
                                                    .of(context)
                                                    .shpingOrServices,
                                                style:
                                                    theme.textTheme.bodyLarge,
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
                                                initialValue:
                                                    serviceCharge.toString(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    serviceCharge =
                                                        double.parse(value);
                                                    updateDueAmount();
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                    border:
                                                        const OutlineInputBorder(),
                                                    hintText: lang.S
                                                        .of(context)
                                                        .enterAmount,
                                                    contentPadding:
                                                        EdgeInsets.zero),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 10.0),
                                        ListView.builder(
                                          itemCount: getAllTaxFromCartList(
                                                  cart: cartList)
                                              .length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child:
                                                  ResponsiveGridRow(children: [
                                                ResponsiveGridCol(
                                                  xs: 12,
                                                  lg: 6,
                                                  md: 6,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        bottom:
                                                            screenWidth < 577
                                                                ? 8
                                                                : 0),
                                                    child: Text(
                                                      getAllTaxFromCartList(
                                                                  cart:
                                                                      cartList)[
                                                              index]
                                                          .name,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: theme
                                                          .textTheme.bodyLarge,
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
                                                        initialValue:
                                                            getAllTaxFromCartList(
                                                                        cart:
                                                                            cartList)[
                                                                    index]
                                                                .taxRate
                                                                .toString(),
                                                        readOnly: true,
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 6.0),
                                                          hintText: '0',
                                                          border: const OutlineInputBorder(
                                                              gapPadding: 0.0,
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xFFff5f00))),
                                                          enabledBorder:
                                                              const OutlineInputBorder(
                                                                  gapPadding:
                                                                      0.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Color(0xFFff5f00))),
                                                          disabledBorder:
                                                              const OutlineInputBorder(
                                                                  gapPadding:
                                                                      0.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Color(0xFFff5f00))),
                                                          focusedBorder:
                                                              const OutlineInputBorder(
                                                                  gapPadding:
                                                                      0.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Color(0xFFff5f00))),
                                                          prefixIconConstraints:
                                                              const BoxConstraints(
                                                                  maxWidth:
                                                                      30.0,
                                                                  minWidth:
                                                                      30.0),
                                                          prefixIcon: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8.0,
                                                                    left: 8.0),
                                                            height: 40,
                                                            decoration: const BoxDecoration(
                                                                color: Color(
                                                                    0xFFff5f00),
                                                                borderRadius: BorderRadius.only(
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            4.0),
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            4.0))),
                                                            child: const Text(
                                                              '%',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      20.0,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
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
                                              padding: EdgeInsets.only(
                                                  bottom: screenWidth < 577
                                                      ? 8
                                                      : 0),
                                              child: Text(
                                                lang.S
                                                    .of(context)
                                                    .shpingOrServices,
                                                style:
                                                    theme.textTheme.bodyLarge,
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
                                                      controller:
                                                          discountPercentageEditingController,
                                                      onChanged: (value) {
                                                        if (value == '') {
                                                          setState(() {
                                                            discountAmountEditingController
                                                                    .text =
                                                                0.toString();
                                                          });
                                                        } else {
                                                          if (value.toInt() <=
                                                              100) {
                                                            setState(() {
                                                              discountAmount = double.parse(((value
                                                                              .toDouble() /
                                                                          100) *
                                                                      getTotalAmount()
                                                                          .toDouble())
                                                                  .toStringAsFixed(
                                                                      1));
                                                              discountAmountEditingController
                                                                      .text =
                                                                  discountAmount
                                                                      .toString();
                                                            });
                                                          } else {
                                                            setState(() {
                                                              discountAmount =
                                                                  0;
                                                              discountAmountEditingController
                                                                  .clear();
                                                              discountPercentageEditingController
                                                                  .clear();
                                                            });
                                                            EasyLoading
                                                                .showError(lang
                                                                    .S
                                                                    .of(context)
                                                                    .enterAValidDiscount);
                                                          }
                                                        }
                                                        updateDueAmount();
                                                      },
                                                      textAlign:
                                                          TextAlign.right,
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 6.0),
                                                        hintText: '0',
                                                        border: const OutlineInputBorder(
                                                            gapPadding: 0.0,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xffFF8C00))),
                                                        enabledBorder:
                                                            const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xffFF8C00))),
                                                        disabledBorder:
                                                            const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xffFF8C00))),
                                                        focusedBorder:
                                                            const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xffFF8C00))),
                                                        prefixIconConstraints:
                                                            const BoxConstraints(
                                                                maxWidth: 30.0,
                                                                minWidth: 30.0),
                                                        prefixIcon: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 8.0,
                                                                  left: 8.0),
                                                          height: 40,
                                                          decoration: const BoxDecoration(
                                                              color: Color(
                                                                  0xffFF8C00),
                                                              borderRadius: BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          4.0),
                                                                  bottomLeft: Radius
                                                                      .circular(
                                                                          4.0))),
                                                          child: const Text(
                                                            '%',
                                                            style: TextStyle(
                                                                fontSize: 18.0,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                      keyboardType:
                                                          TextInputType.name,
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
                                                        controller:
                                                            discountAmountEditingController,
                                                        onChanged: (value) {
                                                          if (value == '') {
                                                            setState(() {
                                                              discountAmount =
                                                                  0;
                                                              discountPercentageEditingController
                                                                      .text =
                                                                  0.toString();
                                                            });
                                                          } else {
                                                            if (value.toInt() <=
                                                                getTotalAmount()
                                                                    .toDouble()) {
                                                              setState(() {
                                                                discountAmount =
                                                                    double.parse(
                                                                        value);
                                                                discountPercentageEditingController
                                                                    .text = ((discountAmount *
                                                                            100) /
                                                                        getTotalAmount()
                                                                            .toDouble())
                                                                    .toStringAsFixed(
                                                                        1);
                                                              });
                                                            } else {
                                                              setState(() {
                                                                discountAmount =
                                                                    0;
                                                                discountPercentageEditingController
                                                                    .clear();
                                                                discountAmountEditingController
                                                                    .clear();
                                                              });
                                                              EasyLoading
                                                                  .showError(lang
                                                                      .S
                                                                      .of(context)
                                                                      .enterAValidDiscount);
                                                            }
                                                          }
                                                          updateDueAmount();
                                                        },
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 6.0),
                                                          hintText: '0',
                                                          border: const OutlineInputBorder(
                                                              gapPadding: 0.0,
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xff00AE1C))),
                                                          enabledBorder:
                                                              const OutlineInputBorder(
                                                                  gapPadding:
                                                                      0.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Color(0xff00AE1C))),
                                                          disabledBorder:
                                                              const OutlineInputBorder(
                                                                  gapPadding:
                                                                      0.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Color(0xff00AE1C))),
                                                          focusedBorder:
                                                              const OutlineInputBorder(
                                                                  gapPadding:
                                                                      0.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Color(0xff00AE1C))),
                                                          prefixIconConstraints:
                                                              const BoxConstraints(
                                                                  maxWidth:
                                                                      40.0,
                                                                  minWidth:
                                                                      40.0),
                                                          prefixIcon: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8.0,
                                                                    left: 8.0),
                                                            height: 40,
                                                            decoration: const BoxDecoration(
                                                                color: Color(
                                                                    0xff00AE1C),
                                                                borderRadius: BorderRadius.only(
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            4.0),
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            4.0))),
                                                            child: Text(
                                                              currency,
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      18.0,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ),
                                                        textFieldType:
                                                            TextFieldType.PHONE,
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
                        ResponsiveGridRow(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (screenWidth > 1240)
                                ResponsiveGridCol(
                                    lg: 3,
                                    xs: 0,
                                    md: 0,
                                    child: const SizedBox.shrink()),
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
                                      if (await Subscription
                                          .subscriptionChecker(
                                              item: 'Ventas')) {
                                        if (cartList.isEmpty) {
                                          EasyLoading.showError(lang.S
                                              .of(context)
                                              .pleaseAddSomeProductFirst);
                                        } else {
                                          showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder:
                                                  (BuildContext dialogContext) {
                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Center(
                                                    child: Container(
                                                      width: 500,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(15),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              lang.S
                                                                  .of(context)
                                                                  .areYouWantToCreateThisQuation,
                                                              style: theme
                                                                  .textTheme
                                                                  .headlineSmall
                                                                  ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            const SizedBox(
                                                                height: 20),
                                                            ResponsiveGridRow(
                                                                children: [
                                                                  ResponsiveGridCol(
                                                                    lg: 6,
                                                                    md: 6,
                                                                    xs: 6,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                      child:
                                                                          ElevatedButton(
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              Colors.red,
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          lang.S
                                                                              .of(context)
                                                                              .cancel,
                                                                        ),
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.pop(
                                                                              dialogContext);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  ResponsiveGridCol(
                                                                    lg: 6,
                                                                    md: 6,
                                                                    xs: 6,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                      child:
                                                                          ElevatedButton(
                                                                        child:
                                                                            Text(
                                                                          lang.S
                                                                              .of(context)
                                                                              .create,
                                                                        ),
                                                                        onPressed:
                                                                            () async {
                                                                          var invoice_number_variable =
                                                                              await getLastInvoiceNumber();
                                                                          print("llego aqui: " +
                                                                              invoice_number_variable.toString());

                                                                          SaleTransactionModel
                                                                              transitionModel =
                                                                              SaleTransactionModel(
                                                                            customerName:
                                                                                selectedUserName?.customerName ?? '',
                                                                            customerType:
                                                                                selectedUserName?.type ?? '',
                                                                            customerImage:
                                                                                selectedUserName?.profilePicture ?? '',
                                                                            customerAddress:
                                                                                selectedUserName?.customerAddress ?? '',
                                                                            customerPhone:
                                                                                selectedUserName?.phoneNumber ?? '',
                                                                            customerGst:
                                                                                selectedUserName?.gst ?? '',

                                                                            invoiceNumber:
                                                                                invoice_number_variable.toString(),

                                                                            sendWhatsappMessage:
                                                                                selectedUserName?.receiveWhatsappUpdates ?? false,
                                                                            purchaseDate:
                                                                                DateTime.now().toString(),
                                                                            productList:
                                                                                cartList,
                                                                            totalAmount:
                                                                                double.parse((getTotalAmount().toDouble() + serviceCharge - discountAmount + vatGst).toStringAsFixed(1)),
                                                                            discountAmount:
                                                                                discountAmount,
                                                                            serviceCharge:
                                                                                serviceCharge,
                                                                            vat:
                                                                                vatGst,

                                                                            reservationIds: cartList
                                                                                .where((item) => item.reservationId != null) // Filtra items con reserva
                                                                                .map((item) => item.reservationId!) // Extrae IDs
                                                                                .toList(), // Convierte a lista
                                                                          );

                                                                          try {
                                                                            EasyLoading.show(
                                                                                status: '${lang.S.of(context).loading}...',
                                                                                dismissOnTap: false);
                                                                            DatabaseReference
                                                                                ref =
                                                                                FirebaseDatabase.instance.ref("${await getUserID()}/Sales Quotation");

                                                                            transitionModel.isPaid =
                                                                                false;
                                                                            transitionModel.dueAmount =
                                                                                0;
                                                                            transitionModel.lossProfit =
                                                                                0;
                                                                            transitionModel.returnAmount =
                                                                                0;
                                                                            transitionModel.paymentType =
                                                                                'Just Quotation';
                                                                            transitionModel.sellerName = isSubUser
                                                                                ? constSubUserTitle
                                                                                : 'Admin';

                                                                            await ref.push().set(transitionModel.toJson());
                                                                            updateInvoice(
                                                                                typeOfInvoice: 'saleInvoiceCounter',
                                                                                invoice: transitionModel.invoiceNumber.toInt());
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
                                                                                        onPressed: () {
                                                                                          Navigator.pop(printDialogContext);
                                                                                          GeneratePdfAndPrint().printQuotationInvoice(
                                                                                            personalInformationModel: data,
                                                                                            saleTransactionModel: transitionModel,
                                                                                            context: context,
                                                                                            isFromInventorySale: true,
                                                                                            printFormat: 'large', // Formato grande
                                                                                          );
                                                                                        },
                                                                                        child: Text("Largo"),
                                                                                      ),
                                                                                      const SizedBox(height: 10),
                                                                                      ElevatedButton(
                                                                                        onPressed: () {
                                                                                          Navigator.pop(printDialogContext);
                                                                                          GeneratePdfAndPrint().printQuotationInvoice(
                                                                                            personalInformationModel: data,
                                                                                            saleTransactionModel: transitionModel,
                                                                                            context: context,
                                                                                            isFromInventorySale: true,
                                                                                            printFormat: 'small', // Formato pequeño
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
                                        EasyLoading.showError(
                                            '${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
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
                                          if (checkUserRoleEditPermissionV2(
                                              type: 'sales')) {
                                            if (await Subscription
                                                .subscriptionChecker(
                                                    item: 'Sales')) {
                                              if (cartList.isEmpty) {
                                                EasyLoading.showError(lang.S
                                                    .of(context)
                                                    .pleaseAddSomeProductFirst);
                                              } else {
                                                // getLastInvoiceNumber().then((valor) {
                                                //   setState(() {
                                                //     invoiceNumberGenerated = valor.toString();
                                                //   });
                                                // });

                                                // debugger();
                                                // print("llego aqui1: " + invoiceNumberGenerated.toString());

                                                var invoice_number_variable =
                                                    await getLastInvoiceNumber();
                                                print("llego aqui: " +
                                                    invoice_number_variable
                                                        .toString());

                                                SaleTransactionModel
                                                    transitionModel =
                                                    SaleTransactionModel(
                                                  customerName: selectedUserName
                                                          ?.customerName ??
                                                      '',
                                                  customerType:
                                                      selectedUserName?.type ??
                                                          '',
                                                  customerImage: selectedUserName
                                                          ?.profilePicture ??
                                                      '',
                                                  customerAddress:
                                                      selectedUserName
                                                              ?.customerAddress ??
                                                          '',
                                                  customerPhone:
                                                      selectedUserName
                                                              ?.phoneNumber ??
                                                          '',
                                                  customerGst:
                                                      selectedUserName?.gst ??
                                                          '',
                                                  // Se agrega validador en el momento
                                                  invoiceNumber:
                                                      invoice_number_variable
                                                          .toString(),

                                                  // data
                                                  //     .saleInvoiceCounter
                                                  //     .toString(),
                                                  sendWhatsappMessage:
                                                      selectedUserName
                                                              ?.receiveWhatsappUpdates ??
                                                          false,
                                                  purchaseDate:
                                                      DateTime.now().toString(),
                                                  productList: cartList,
                                                  totalAmount: double.parse(
                                                      (getTotalAmount()
                                                                  .toDouble() +
                                                              serviceCharge -
                                                              discountAmount +
                                                              vatGst)
                                                          .toStringAsFixed(1)),
                                                  discountAmount:
                                                      discountAmount,
                                                  serviceCharge: serviceCharge,
                                                  vat: vatGst,
                                                  reservationIds: cartList
                                                      .where((item) =>
                                                          item.reservationId !=
                                                          null)
                                                      .map((item) =>
                                                          item.reservationId!)
                                                      .toList(),
                                                );

                                                if (transitionModel
                                                            .customerType ==
                                                        "Guest" &&
                                                    dueAmountController.text
                                                            .toDouble() >
                                                        0) {
                                                  EasyLoading.showError(lang.S
                                                      .of(context)
                                                      .dueIsNotAvailableForGuest);
                                                } else {
                                                  try {
                                                    setState(() {
                                                      saleButtonClicked = true;
                                                    });

                                                    final printType =
                                                        await showDialog<
                                                            String>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: Text(
                                                            'Seleccionar formato de impresión'),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            ListTile(
                                                              leading: Icon(
                                                                  Icons.receipt,
                                                                  color: Colors
                                                                      .blue),
                                                              title: Text(
                                                                  'Factura térmica'),
                                                              subtitle: Text(
                                                                  'Para impresora de 58-80mm'),
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      'thermal'),
                                                            ),
                                                            Divider(),
                                                            ListTile(
                                                              leading: Icon(
                                                                  Icons
                                                                      .description,
                                                                  color: Colors
                                                                      .green),
                                                              title: Text(
                                                                  'Factura normal'),
                                                              subtitle: Text(
                                                                  'Formato completo A4/Letter'),
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      'normal'),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            child: Text(
                                                                'Cancelar'),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (printType == null) {
                                                      EasyLoading.dismiss();
                                                      setState(() =>
                                                          saleButtonClicked =
                                                              false);
                                                      return;
                                                    }

                                                    print(
                                                        "TIPO DE DE IMPRESION $printType");
                                                    EasyLoading.show(
                                                        status:
                                                            '${lang.S.of(context).loading}...',
                                                        dismissOnTap: false);
                                                    DatabaseReference ref =
                                                        FirebaseDatabase
                                                            .instance
                                                            .ref(
                                                                "${await getUserID()}/Sales Transition");
                                                    (double.tryParse(dueAmountController
                                                                    .text) ??
                                                                0) <=
                                                            0
                                                        ? transitionModel
                                                            .isPaid = true
                                                        : transitionModel
                                                            .isPaid = false;
                                                    (double.tryParse(dueAmountController
                                                                    .text) ??
                                                                0) <=
                                                            0
                                                        ? transitionModel
                                                            .dueAmount = 0
                                                        : transitionModel
                                                                .dueAmount =
                                                            (double.tryParse(
                                                                    dueAmountController
                                                                        .text) ??
                                                                0);
                                                    (double.tryParse(changeAmountController
                                                                    .text) ??
                                                                0) >
                                                            0
                                                        ? transitionModel
                                                                .returnAmount =
                                                            (double.tryParse(
                                                                        changeAmountController
                                                                            .text) ??
                                                                    0)
                                                                .abs()
                                                        : transitionModel
                                                            .returnAmount = 0;
                                                    transitionModel
                                                            .paymentType =
                                                        selectedPaymentOption;
                                                    transitionModel.sellerName =
                                                        isSubUser
                                                            ? constSubUserTitle
                                                            : 'Admin';
                                                    SaleTransactionModel post =
                                                        checkLossProfit(
                                                            transitionModel:
                                                                transitionModel);
                                                    await ref
                                                        .push()
                                                        .set(post.toJson());

                                                    //imprimir factura

                                                    print("llego aqui: " +
                                                        post
                                                            .toJson()
                                                            .toString());
                                                    if (printType == 'normal' ||
                                                        printType == 'both') {
                                                      await GeneratePdfAndPrint()
                                                          .printSaleInvoice(
                                                              personalInformationModel:
                                                                  data,
                                                              saleTransactionModel:
                                                                  transitionModel,
                                                              context: context,
                                                              fromInventorySale:
                                                                  true,
                                                              setting: setting,
                                                              printType:
                                                                  'normal',
                                                              post: post);
                                                    }

                                                    if (printType ==
                                                            'thermal' ||
                                                        printType == 'both') {
                                                      await GeneratePdfAndPrint()
                                                          .printSaleInvoice(
                                                        personalInformationModel:
                                                            data,
                                                        saleTransactionModel:
                                                            transitionModel,
                                                        context: context,
                                                        fromInventorySale: true,
                                                        setting: setting,
                                                        printType: 'thermal',
                                                        post: post,
                                                      );

                                                      print("llego uoo ");
                                                    }

                                                    limpiarCarro();

                                                    final stockRef =
                                                        FirebaseDatabase
                                                            .instance
                                                            .ref(
                                                                '${await getUserID()}/Products');
                                                    for (var element
                                                        in transitionModel
                                                            .productList!) {
                                                      var data = await stockRef
                                                          .orderByChild(
                                                              'productCode')
                                                          .equalTo(
                                                              element.productId)
                                                          .once();
                                                      final data2 = jsonDecode(
                                                          jsonEncode(data
                                                              .snapshot.value));
                                                      String productPath = data
                                                          .snapshot.value
                                                          .toString()
                                                          .substring(1, 21);

                                                      var data1 = await stockRef
                                                          .child(
                                                              '$productPath/productStock')
                                                          .get();
                                                      num stock = num.parse(
                                                          data1.value
                                                              .toString());
                                                      num remainStock = stock -
                                                          element.quantity;

                                                      stockRef
                                                          .child(productPath)
                                                          .update({
                                                        'productStock':
                                                            '$remainStock'
                                                      });

                                                      if (element.serialNumber
                                                              ?.isNotEmpty ??
                                                          false) {
                                                        var productOldSerialList =
                                                            data2[productPath][
                                                                'serialNumber'];

                                                        List<dynamic> result =
                                                            productOldSerialList
                                                                .where((item) =>
                                                                    !element
                                                                        .serialNumber!
                                                                        .contains(
                                                                            item))
                                                                .toList();
                                                        stockRef
                                                            .child(productPath)
                                                            .update({
                                                          'serialNumber': result
                                                              .map((e) => e)
                                                              .toList(),
                                                        });
                                                      }
                                                    }

                                                    updateInvoice(
                                                        typeOfInvoice:
                                                            'saleInvoiceCounter',
                                                        invoice: transitionModel
                                                            .invoiceNumber
                                                            .toInt());

                                                    Subscription
                                                        .decreaseSubscriptionLimits(
                                                            itemType:
                                                                'saleNumber',
                                                            context: context);

                                                    DailyTransactionModel
                                                        dailyTransaction =
                                                        DailyTransactionModel(
                                                      name: post.customerName,
                                                      date: post.purchaseDate,
                                                      type: 'Sale',
                                                      total: post.totalAmount!
                                                          .toDouble(),
                                                      paymentIn: post
                                                              .totalAmount!
                                                              .toDouble() -
                                                          post.dueAmount!
                                                              .toDouble(),
                                                      paymentOut: 0,
                                                      remainingBalance: post
                                                              .totalAmount!
                                                              .toDouble() -
                                                          post.dueAmount!
                                                              .toDouble(),
                                                      id: post.invoiceNumber,
                                                      saleTransactionModel:
                                                          post,
                                                    );
                                                    postDailyTransaction(
                                                        dailyTransactionModel:
                                                            dailyTransaction);

                                                    if (transitionModel
                                                            .customerName !=
                                                        'Guest') {
                                                      final dueUpdateRef =
                                                          FirebaseDatabase
                                                              .instance
                                                              .ref(
                                                                  '${await getUserID()}/Customers/');
                                                      String? key;

                                                      await FirebaseDatabase
                                                          .instance
                                                          .ref(
                                                              await getUserID())
                                                          .child('Customers')
                                                          .orderByKey()
                                                          .get()
                                                          .then((value) {
                                                        for (var element
                                                            in value.children) {
                                                          var data = jsonDecode(
                                                              jsonEncode(element
                                                                  .value));
                                                          if (data[
                                                                  'phoneNumber'] ==
                                                              transitionModel
                                                                  .customerPhone) {
                                                            key = element.key;
                                                          }
                                                        }
                                                      });
                                                      var data1 =
                                                          await dueUpdateRef
                                                              .child('$key/due')
                                                              .get();
                                                      int previousDue = data1
                                                          .value
                                                          .toString()
                                                          .toInt();

                                                      int totalDue =
                                                          previousDue +
                                                              transitionModel
                                                                  .dueAmount!
                                                                  .toInt();
                                                      dueUpdateRef
                                                          .child(key!)
                                                          .update({
                                                        'due': '$totalDue'
                                                      });
                                                    }

                                                    print(
                                                        "llegaaaaaaaaaaaaaa aqui ");
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        allCustomerProvider);
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        transitionProvider);
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        productProvider);
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        purchaseTransitionProvider);
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        dueTransactionProvider);
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        profileDetailsProvider);
                                                    // ignore: unused_result
                                                    consumerRef.refresh(
                                                        dailyTransactionProvider);

                                                    EasyLoading.showSuccess(lang
                                                        .S
                                                        .of(context)
                                                        .saleSuccessfullyDone);
                                                  } catch (e) {
                                                    setState(() {
                                                      saleButtonClicked = false;
                                                    });
                                                    EasyLoading.dismiss();
                                                  }
                                                }
                                              }
                                            } else {
                                              EasyLoading.showError(
                                                  '${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                            }
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
                              if (screenWidth > 1240)
                                ResponsiveGridCol(
                                    lg: 3,
                                    xs: 0,
                                    md: 0,
                                    child: const SizedBox.shrink()),
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
      print("limpiando carro");

      cartList.clear(); // Limpia la lista de productos
      productFocusNode.clear(); // Limpia los focus nodes
      payingAmountController.text = '0'; // Resetea el monto pagado
      changeAmountController.text = '0'; // Resetea el cambio
      dueAmountController.text = '0'; // Resetea el adeudo
      discountAmountEditingController.clear(); // Limpia el descuento en monto
      discountPercentageEditingController
          .clear(); // Limpia el descuento en porcentaje
      serviceCharge = 0; // Resetea el cargo por servicio
      discountAmount = 0; // Resetea el monto de descuento
      vatGst = 0; // Resetea los impuestos
    });
  }
}
