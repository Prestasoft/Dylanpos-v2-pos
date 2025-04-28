// ignore_for_file: use_build_context_synchronously

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
  double totalCustomerDue({required List<CustomerModel> customers, required String selectedCustomerType}) {
    double totalDue = 0;
    for (var c in customers) {
      totalDue += double.parse(c.dueAmount);
    }
    return totalDue;
  }

  int selectedItem = 10;
  int itemCount = 10;
  String selectedParties = 'Customers';
  ScrollController mainScroll = ScrollController();
  String searchItem = '';

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _categoryPerPage = 10; // Default number of items to display
  int _currentPage = 1;

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
            AsyncValue<List<CustomerModel>> customers = ref.watch(allCustomerProvider);
            return customers.when(data: (allCustomerList) {
              List<CustomerModel> customerList = [];
              List<CustomerModel> supplierList = [];
              List<CustomerModel> showAbleCustomer = [];
              List<CustomerModel> showAbleSupplier = [];
              for (var value1 in allCustomerList) {
                if (value1.type != 'Supplier' && value1.dueAmount.toDouble() > 0) {
                  customerList.add(value1);
                } else {
                  value1.dueAmount.toDouble() > 0 ? supplierList.add(value1) : null;
                }
              }

              ///___________customer_filter______________________________________________________
              for (var element in customerList) {
                if (element.customerName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.phoneNumber.contains(searchItem)) {
                  showAbleCustomer.add(element);
                } else if (searchItem == '') {
                  showAbleCustomer.add(element);
                }
              }

              ///___________Suppiler_filter______________________________________________________
              for (var element in supplierList) {
                if (element.customerName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.phoneNumber.contains(searchItem)) {
                  showAbleSupplier.add(element);
                } else if (searchItem == '') {
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
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              selectedParties == 'Customers' ? 'Lista de pagos pendientes (cliente)' : 'Lista de pagos pendientes (Proveedores)',
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
                                          selectedParties = 'Customers';
                                          _currentPage = 1; // Reset to first page when switching tabs
                                        });
                                      }),
                                      child: Container(
                                        height: 40,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: selectedParties == 'Customers' ? kBlueTextColor : Colors.white,
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                          border: Border.all(width: 1, color: selectedParties == 'Customers' ? kBlueTextColor : Colors.grey),
                                        ),
                                        child: Center(
                                          child: Text(
                                            lang.S.of(context).customers,
                                            style: TextStyle(
                                              color: selectedParties == 'Customers' ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: (() {
                                        setState(() {
                                          selectedParties = 'Suppliers';
                                          _currentPage = 1; // Reset to first page when switching tabs
                                        });
                                      }),
                                      child: Container(
                                        height: 40,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: selectedParties == 'Suppliers' ? kBlueTextColor : Colors.white,
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                          border: Border.all(width: 1, color: selectedParties == 'Suppliers' ? kBlueTextColor : Colors.grey),
                                        ),
                                        child: Center(
                                          child: Text(
                                            lang.S.of(context).supplier,
                                            style: TextStyle(
                                              color: selectedParties == 'Suppliers' ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                ///___________search________________________________________________
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
                                          borderRadius: BorderRadius.circular(8.0),
                                          border: Border.all(color: kNeutral300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                                              items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                                return DropdownMenuItem<int>(
                                                  value: value,
                                                  child: Text(
                                                    value == -1 ? "Todos" : value.toString(),
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  _categoryPerPage = newValue ?? 10;
                                                  _currentPage = 1; // Reset to first page when changing items per page
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
                                            _currentPage = 1; // Reset to first page when searching
                                          });
                                        },
                                        keyboardType: TextInputType.name,
                                        decoration: kInputDecoration.copyWith(
                                          contentPadding: const EdgeInsets.all(10.0),
                                          hintText: (lang.S.of(context).searchByName),
                                          suffixIcon: const Icon(
                                            FeatherIcons.search,
                                            color: kNeutral400,
                                          ),
                                        ),
                                      )),
                                ]),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: const Color(0xFFFEE7CB),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$globalCurrency ${myFormat.format(double.tryParse(totalCustomerDue(customers: selectedParties == 'Clientes' ? showAbleCustomer : showAbleSupplier, selectedCustomerType: selectedParties).toStringAsFixed(2)) ?? 0)}',
                                        style: theme.textTheme.titleLarge?.copyWith(
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
                          selectedParties == 'Suppliers' && showAbleSupplier.isNotEmpty || selectedParties != 'Suppliers' && showAbleCustomer.isNotEmpty
                              ? Column(
                                  children: [
                                    LayoutBuilder(
                                      builder: (BuildContext context, BoxConstraints constraints) {
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
                                                    dividerColor: Colors.transparent,
                                                    dividerTheme: const DividerThemeData(color: Colors.transparent),
                                                  ),
                                                  child: DataTable(
                                                      border: const TableBorder(
                                                        horizontalInside: BorderSide(
                                                          width: 1,
                                                          color: kNeutral300,
                                                        ),
                                                      ),
                                                      dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                                      showBottomBorder: false,
                                                      dividerThickness: 0.0,
                                                      headingTextStyle: theme.textTheme.titleMedium,
                                                      columns: [
                                                        DataColumn(label: Text(lang.S.of(context).SL)),
                                                        DataColumn(label: Text(lang.S.of(context).partyName)),
                                                        DataColumn(label: Text(lang.S.of(context).partyType)),
                                                        DataColumn(label: Text(lang.S.of(context).phone)),
                                                        DataColumn(label: Text(lang.S.of(context).email)),
                                                        DataColumn(label: Text(lang.S.of(context).due)),
                                                        DataColumn(label: Text(lang.S.of(context).collectDue)),
                                                      ],
                                                      rows: List.generate(selectedParties == 'Suppliers' ? paginatedSupplierList.length : paginatedCustomerList.length, (index) {
                                                        return DataRow(cells: [
                                                          DataCell(Text((index + 1).toString())),
                                                          DataCell(Text(
                                                            selectedParties == 'Suppliers' ? paginatedSupplierList[index].customerName : paginatedCustomerList[index].customerName,
                                                          )),
                                                          DataCell(Text(
                                                            selectedParties == 'Suppliers' ? paginatedSupplierList[index].type : paginatedCustomerList[index].type,
                                                          )),
                                                          DataCell(Text(
                                                            selectedParties == 'Suppliers' ? paginatedSupplierList[index].phoneNumber : paginatedCustomerList[index].phoneNumber,
                                                            style: kTextStyle.copyWith(color: kGreyTextColor),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          )),
                                                          DataCell(Text(
                                                            selectedParties == 'Suppliers' ? paginatedSupplierList[index].emailAddress : paginatedCustomerList[index].emailAddress,
                                                            style: kTextStyle.copyWith(color: kGreyTextColor),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          )),
                                                          DataCell(Text(
                                                            selectedParties == 'Suppliers' ? '$globalCurrency${myFormat.format(double.tryParse(paginatedSupplierList[index].dueAmount) ?? 0)}' : '$globalCurrency${myFormat.format(double.tryParse(paginatedCustomerList[index].dueAmount))}',
                                                          )),
                                                          DataCell(
                                                            GestureDetector(
                                                              onTap: () async {
                                                                if (await Subscription.subscriptionChecker(item: 'Lista de pagos Pendientes')) {
                                                                  showDialog(
                                                                    barrierDismissible: false,
                                                                    context: context,
                                                                    builder: (BuildContext context) {
                                                                      return StatefulBuilder(
                                                                        builder: (context, setStates) {
                                                                          return Dialog(
                                                                            surfaceTintColor: Colors.white,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                            ),
                                                                            child: ShowDuePaymentPopUp(
                                                                              customerModel: selectedParties == 'Suppliers' ? paginatedSupplierList[index] : paginatedCustomerList[index],
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  );
                                                                } else {
                                                                  EasyLoading.showError('Update your plan first,\nDue Collection limit is over.');
                                                                }
                                                              },
                                                              child: const Text(
                                                                'Aplicar pago >',
                                                                style: TextStyle(color: Colors.blue),
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _categoryPerPage == -1 ? '${lang.S.of(context).showing} all ${selectedParties == 'Suppliers' ? showAbleSupplier.length : showAbleCustomer.length} entries' : '${lang.S.of(context).showing} ${((_currentPage - 1) * _categoryPerPage + 1).toString()} to ${((_currentPage - 1) * _categoryPerPage + _categoryPerPage).clamp(0, selectedParties == 'Suppliers' ? showAbleSupplier.length : showAbleCustomer.length)} of ${selectedParties == 'Suppliers' ? showAbleSupplier.length : showAbleCustomer.length} entries',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_categoryPerPage != -1) // Only show pagination controls when not in "All" mode
                                            Row(
                                              children: [
                                                InkWell(
                                                  overlayColor: WidgetStateProperty.all<Color>(Colors.grey),
                                                  hoverColor: Colors.grey,
                                                  onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: kBorderColorTextField),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomLeft: Radius.circular(4.0),
                                                        topLeft: Radius.circular(4.0),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(lang.S.of(context).previous),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: kBorderColorTextField),
                                                    color: kMainColor,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$_currentPage',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: kBorderColorTextField),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${(selectedParties == 'Suppliers' ? (showAbleSupplier.length / _categoryPerPage).ceil() : (showAbleCustomer.length / _categoryPerPage).ceil())}',
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  hoverColor: Colors.blue.withOpacity(0.1),
                                                  overlayColor: MaterialStateProperty.all<Color>(Colors.blue),
                                                  onTap: _currentPage * _categoryPerPage < (selectedParties == 'Suppliers' ? showAbleSupplier.length : showAbleCustomer.length) ? () => setState(() => _currentPage++) : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: kBorderColorTextField),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomRight: Radius.circular(4.0),
                                                        topRight: Radius.circular(4.0),
                                                      ),
                                                    ),
                                                    child: const Center(child: Text('Siguiente')),
                                                  ),
                                                ),
                                              ],
                                            )
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : EmptyWidget(title: lang.S.of(context).noDueTransantionFound)
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
