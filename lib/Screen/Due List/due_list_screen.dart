import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/customer_model.dart';
import 'package:intl/intl.dart'; // Añadir para manejo de fechas

import '../../Provider/customer_provider.dart';
import '../../const.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';
import 'due_popUp.dart';

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
  
  // Nuevas variables para el filtro de fecha
  String dateFilter = 'Todos'; // 'Hoy' o 'Todos'
  DateTimeRange? dateRange; // Para el selector de rango de fechas

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
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
            AsyncValue<List<CustomerModel>> customers =
                ref.watch(allCustomerProvider);
            return customers.when(data: (allCustomerList) {
              List<CustomerModel> customerList = [];
              List<CustomerModel> supplierList = [];
              List<CustomerModel> showAbleCustomer = [];
              List<CustomerModel> showAbleSupplier = [];
              for (var value1 in allCustomerList) {
                if (value1.type != 'Proveedores' &&
                    value1.dueAmount.toDouble() > 0) {
                  customerList.add(value1);
                } else {
                  value1.dueAmount.toDouble() > 0
                      ? supplierList.add(value1)
                      : null;
                }
              }

              ///___________customer_filter______________________________________________________
              for (var element in customerList) {
                final name = element.customerName?.replaceAll(' ', '').toLowerCase() ?? '';
                final phone = element.phoneNumber ?? '';

                final search = searchItem.toLowerCase();

                if ((name.contains(search) || phone.contains(search))) {
                  if (_filterByDate(element)) {
                    showAbleCustomer.add(element);
                  }
                } else if (searchItem == '' && _filterByDate(element)) {
                  showAbleCustomer.add(element);
                }
              }

              ///___________Suppiler_filter______________________________________________________
              for (var element in supplierList) {
                if ((element.customerName
                        .removeAllWhiteSpace()
                        .toLowerCase()
                        .contains(searchItem.toLowerCase()) ||
                    element.phoneNumber.contains(searchItem))) {
                  if (_filterByDate(element)) {
                    showAbleSupplier.add(element);
                  }
                } else if (searchItem == '' && _filterByDate(element)) {
                  showAbleSupplier.add(element);
                }
              }

              // Pagination logic - Updated to handle "All" case
              final List<CustomerModel> paginatedCustomerList;
              final List<CustomerModel> paginatedSupplierList;

              if (_categoryPerPage == -1) {
                // Show all items
                paginatedCustomerList = showAbleCustomer;
                paginatedSupplierList = showAbleSupplier;
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
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        onChanged: (value) {
                                          setState(() {
                                            searchItem = value;
                                            _currentPage =
                                                1; // Reset to first page when searching
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
                                        '$globalCurrency ${myFormat.format(double.tryParse(totalCustomerDue(customers: selectedParties == 'Clientes' ? showAbleCustomer : showAbleSupplier, selectedCustomerType: selectedParties).toStringAsFixed(2)) ?? 0)}',
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
                                                                ? '$globalCurrency${myFormat.format(double.tryParse(paginatedSupplierList[index].dueAmount) ?? 0)}'
                                                                : '$globalCurrency${myFormat.format(double.tryParse(paginatedCustomerList[index].dueAmount))}',
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