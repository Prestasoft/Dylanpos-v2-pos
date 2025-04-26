import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/personal_information_model.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/purchase_transaction_single.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/customer_model.dart';
import '../../model/purchase_transation_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({
    super.key,
  });

  static const String route = '/ledger';

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  double singleCustomersTotalSaleAmount({required List<SaleTransactionModel> allTransitions, required String customerPhoneNumber}) {
    double totalSale = 0;
    for (var transition in allTransitions) {
      if (transition.customerPhone == customerPhoneNumber) {
        totalSale += transition.totalAmount!.toDouble();
      }
    }
    return totalSale;
  }

  double singleSupplierTotalSaleAmount({required List<dynamic> allTransitions, required String customerPhoneNumber}) {
    double totalSale = 0;
    for (var transition in allTransitions) {
      if (transition.customerPhone == customerPhoneNumber) {
        totalSale += transition.totalAmount!.toDouble();
      }
    }
    return totalSale;
  }

  double totalSale({required List<SaleTransactionModel> allTransitions, required String selectedCustomerType}) {
    double totalSale = 0;

    if (selectedCustomerType != 'All') {
      for (var transition in allTransitions) {
        if (transition.customerType == selectedCustomerType) {
          totalSale += transition.totalAmount!.toDouble();
        }
      }
    } else {
      for (var transition in allTransitions) {
        totalSale += transition.totalAmount!.toDouble();
      }
    }

    return totalSale;
  }

  double totalPurchase({required List<dynamic> allTransitions}) {
    double totalPurchase = 0;

    for (var transition in allTransitions) {
      totalPurchase += transition.totalAmount!.toDouble();
    }
    return totalPurchase;
  }

  // double totalCustomerDue(
  //     {required List<CustomerModel> customers,
  //     required String selectedCustomerType}) {
  //   double totalDue = 0;
  //
  //   if (selectedCustomerType != 'All') {
  //     for (var c in customers) {
  //       if (c.type == selectedCustomerType) {
  //         totalDue += double.parse(c.dueAmount);
  //       }
  //     }
  //   } else {
  //     for (var c in customers) {
  //       if (c.type != 'Supplier') {
  //         totalDue += double.parse(c.dueAmount);
  //       }
  //     }
  //   }
  //   return totalDue;
  // }

  double totalCustomerDue({
    required List<CustomerModel> customers,
    required String selectedCustomerType,
  }) {
    double totalDue = 0;

    if (selectedCustomerType != 'All') {
      for (var c in customers) {
        if (c.type == selectedCustomerType) {
          totalDue += safeParseDouble(c.dueAmount);
        }
      }
    } else {
      for (var c in customers) {
        if (c.type != 'Supplier') {
          totalDue += safeParseDouble(c.dueAmount);
        }
      }
    }
    return totalDue;
  }

  double totalSupplierDue({required List<CustomerModel> customers}) {
    double totalDue = 0;

    for (var c in customers) {
      if (c.type == 'Supplier') {
        totalDue += double.parse(c.dueAmount);
      }
    }
    return totalDue;
  }

  double totalCustomerReceivedAmount({required List<SaleTransactionModel> allTransitions, required String selectedCustomerType}) {
    double totalReceived = 0;

    if (selectedCustomerType != 'All') {
      for (var transition in allTransitions) {
        if (transition.customerType == selectedCustomerType) {
          totalReceived += transition.totalAmount!.toDouble() - transition.dueAmount!.toDouble();
        }
      }
    } else {
      for (var transition in allTransitions) {
        totalReceived += transition.totalAmount!.toDouble() - transition.dueAmount!.toDouble();
      }
    }
    return totalReceived;
  }

  List<CustomerModel> listOfSelectedCustomers = [];

  late String selectedLedgerItems = allPartis.first;

  List<String> get allPartis => [
        'All',
        // lang.S.current.all,
        'Retailer',
        // lang.S.current.retailer,
        'Dealer',
        // lang.S.current.dealer,
        'Wholesaler',
        // lang.S.current.wholesaler,
        "Supplier",
        // lang.S.current.supplier,
      ];
  int counter = 0;
  ScrollController mainScroll = ScrollController();
  String searchItem = '';
  int _categoryPerPage = 10;
  int _currentPage = 1;

  List<CustomerModel> getPaginatedCustomers(List<CustomerModel> customers) {
    if (_categoryPerPage == -1) {
      return customers;
    } else {
      int startIndex = (_currentPage - 1) * _categoryPerPage;
      int endIndex = startIndex + _categoryPerPage;
      if (endIndex > customers.length) {
        endIndex = customers.length;
      }
      return customers.sublist(startIndex, endIndex);
    }
  }

  TextEditingController search = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();

  List<CustomerModel> getFilteredCustomers(List<CustomerModel> customers) {
    if (searchItem.isEmpty) {
      return customers;
    } else {
      return customers.where((customer) {
        return customer.customerName.toLowerCase().contains(searchItem.toLowerCase()) || customer.phoneNumber.toLowerCase().contains(searchItem.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer(builder: (_, ref, watch) {
          final saleTransactionReport = ref.watch(transitionProvider);
          final purchaseTransactionReport = ref.watch(purchaseTransitionProviderSIngle);
          final allCustomers = ref.watch(allCustomerProvider);
          final personalDetails = ref.watch(profileDetailsProvider);
          final settingProvider = ref.watch(generalSettingProvider);

          return allCustomers.when(data: (allCustomers) {
            counter == 0 ? listOfSelectedCustomers = List.from(allCustomers) : null;
            counter++;

            // Apply the filter to the list of selected customers
            final filteredCustomers = getFilteredCustomers(listOfSelectedCustomers);

            // Use the filtered list for pagination
            final paginatedCustomers = getPaginatedCustomers(filteredCustomers);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (rest of the code remains the same)
                ///_______All_totals__________________________________________________________
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: ResponsiveGridRow(
                    rowSegments: 100,
                    children: [
                      ///________Total Sale____________________________________________
                      ResponsiveGridCol(
                        xs: 100,
                        md: 50,
                        lg: screenWidth < 1400 ? 25 : 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: const Color(0xFFCFF4E3),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$globalCurrency ${myFormat.format(double.parse(totalSale(allTransitions: saleTransactionReport.value ?? [], selectedCustomerType: selectedLedgerItems).toStringAsFixed(2)) ?? '0') ?? 0}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                ),
                                Text(
                                  lang.S.of(context).totalSale,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ).visible(selectedLedgerItems != 'Supplier'),
                        ),
                      ),

                      ///________Total_purchase_________________________________________
                      ResponsiveGridCol(
                        xs: 100,
                        md: 50,
                        lg: screenWidth < 1400 ? 25 : 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: const Color(0xFF2DB0F6).withValues(alpha: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$globalCurrency ${myFormat.format(double.tryParse(totalPurchase(allTransitions: purchaseTransactionReport.value ?? []).toStringAsFixed(2) ?? '0') ?? 0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                ),
                                Text(
                                  lang.S.of(context).totalPurchase,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ).visible(selectedLedgerItems == 'Supplier' || selectedLedgerItems == 'All'),
                        ),
                      ),

                      ///____________Total received Amount_________________________________
                      ResponsiveGridCol(
                        xs: 100,
                        md: 50,
                        lg: screenWidth < 1400 ? 25 : 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: const Color(0xFF15CD75).withValues(alpha: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$globalCurrency ${myFormat.format(double.tryParse(totalCustomerReceivedAmount(allTransitions: saleTransactionReport.value ?? [], selectedCustomerType: selectedLedgerItems).toStringAsFixed(2) ?? '0') ?? 0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                ),
                                Text(
                                  lang.S.of(context).recivedAmount,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ).visible(selectedLedgerItems != "Supplier"),
                        ),
                      ),

                      ///________total_customer_due___________________________________________________________
                      ResponsiveGridCol(
                        xs: 100,
                        md: 50,
                        lg: screenWidth < 1400 ? 25 : 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: const Color(0xFFFEE7CB),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$globalCurrency ${myFormat.format(double.tryParse(totalCustomerDue(customers: allCustomers, selectedCustomerType: selectedLedgerItems).toStringAsFixed(2) ?? '0') ?? 0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                ),
                                Text(
                                  lang.S.of(context).customerDue,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ).visible(selectedLedgerItems != "Supplier"),
                        ),
                      ),

                      ///________total_Supplier_due___________________________________________________________
                      ResponsiveGridCol(
                        xs: 100,
                        md: 50,
                        lg: screenWidth < 1400 ? 25 : 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: const Color(0xFFFEE7CB),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$globalCurrency ${myFormat.format(double.tryParse(totalSupplierDue(customers: allCustomers).toStringAsFixed(2) ?? '0') ?? 0)}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                ),
                                Text(
                                  lang.S.of(context).supplierDue,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ).visible(selectedLedgerItems == "Supplier" || selectedLedgerItems == "All"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ///____________Customers_List_Bord____________________________________________
                Container(
                  // padding: const EdgeInsets.all(10.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
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
                            padding: const EdgeInsets.all(10.0),
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
                                    'Show-',
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
                                          value == -1 ? "All" : value.toString(),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        if (newValue == -1) {
                                          _categoryPerPage = -1; // Set to -1 for "All"
                                        } else {
                                          _categoryPerPage = newValue ?? 10;
                                        }
                                        _currentPage = 1;
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
                            md: 50,
                            lg: 25,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: FormField(
                                builder: (FormFieldState<dynamic> field) {
                                  return InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: lang.S.of(context).selectParties,
                                    ),
                                    child: Theme(
                                      data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          onChanged: (String? value) {
                                            listOfSelectedCustomers.clear();
                                            setState(() {
                                              selectedLedgerItems = value!;

                                              for (var element in allCustomers) {
                                                if (selectedLedgerItems == 'All') {
                                                  listOfSelectedCustomers.add(element);
                                                } else {
                                                  if (element.type == selectedLedgerItems) {
                                                    listOfSelectedCustomers.add(element);
                                                  }
                                                }
                                              }
                                              searchItem = '';
                                              search.clear();
                                              toast(selectedLedgerItems);
                                            });
                                          },
                                          value: selectedLedgerItems,
                                          items: allPartis.map((String items) {
                                            return DropdownMenuItem(
                                              value: items,
                                              child: Text(items),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )),
                      ]),

                      ///___________search________________________________________________
                      ResponsiveGridRow(rowSegments: 100, children: [
                        ResponsiveGridCol(
                          xs: 100,
                          md: 80,
                          lg: 60,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              controller: search,
                              showCursor: true,
                              cursorColor: kTitleColor,
                              onChanged: (value) {
                                setState(() {
                                  searchItem = value;
                                  _currentPage = 1; // Reset to the first page when searching
                                });
                              },
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: (lang.S.of(context).searchByNameOrPhone),
                                suffixIcon: const Icon(
                                  FeatherIcons.search,
                                  color: kTitleColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      ]),

                      ///___________selected_customer_list__________________________________________
                      const SizedBox(height: 15.0),
                      listOfSelectedCustomers.isNotEmpty
                          ? Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constrains) {
                                    final kWidth = constrains.maxWidth;
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
                                                  DataColumn(label: Text(lang.S.of(context).totalAmount)),
                                                  DataColumn(label: Text(lang.S.of(context).dueAmount)),
                                                  DataColumn(label: Text(lang.S.of(context).details)),
                                                ],
                                                rows: List.generate(paginatedCustomers.length, (index) {
                                                  return DataRow(cells: [
                                                    ///______________S.L__________________________________________________
                                                    DataCell(
                                                      Text('${(_currentPage - 1) * _categoryPerPage + index + 1}'),
                                                    ),

                                                    ///______________name__________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedCustomers[index].customerName,
                                                      ),
                                                    ),

                                                    ///____________type_________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedCustomers[index].type,
                                                      ),
                                                    ),

                                                    ///______Amount___________________________________________________________
                                                    DataCell(
                                                      Text(
                                                        paginatedCustomers[index].type == 'Supplier' ? (purchaseTransactionReport.value != null ? '$globalCurrency${singleSupplierTotalSaleAmount(allTransitions: purchaseTransactionReport.value!, customerPhoneNumber: paginatedCustomers[index].phoneNumber).toString()}' : 'N/A') : (saleTransactionReport.value != null ? '$globalCurrency${singleCustomersTotalSaleAmount(allTransitions: saleTransactionReport.value!, customerPhoneNumber: paginatedCustomers[index].phoneNumber!).toStringAsFixed(2)}' : 'N/A'),
                                                      ),
                                                    ),

                                                    ///___________Due____________________________________________________

                                                    DataCell(
                                                      Text(
                                                        '$globalCurrency${myFormat.format(double.tryParse(paginatedCustomers[index].dueAmount)!.abs())}',
                                                      ),
                                                    ),

                                                    ///_______________actions_________________________________________________
                                                    DataCell(
                                                      GestureDetector(
                                                        onTap: () {
                                                          ledgerDetails(
                                                            transitionModel: saleTransactionReport.value!,
                                                            customer: paginatedCustomers[index],
                                                            personalInformationModel: personalDetails.value!,
                                                            purchaseTransactionReport: purchaseTransactionReport.value ?? [],
                                                          );
                                                        },
                                                        child: Text(
                                                          lang.S.of(context).show,
                                                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blue),
                                                        ),
                                                      ),
                                                    ),
                                                  ]);
                                                }),
                                              ),
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
                                          '${lang.S.of(context).showing} ${((_currentPage - 1) * _categoryPerPage + 1).toString()} to ${((_currentPage - 1) * _categoryPerPage + _categoryPerPage).clamp(0, filteredCustomers.length)} of ${filteredCustomers.length} entries',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
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
                                                '${(filteredCustomers.length / _categoryPerPage).ceil()}',
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            hoverColor: Colors.blue.withValues(alpha: 0.1),
                                            overlayColor: WidgetStateProperty.all<Color>(Colors.blue),
                                            onTap: _currentPage * _categoryPerPage < filteredCustomers.length ? () => setState(() => _currentPage++) : null,
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
                                              child: const Center(child: Text('Next')),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : EmptyWidget(title: lang.S.of(context).noTransactionFound),
                    ],
                  ),
                )
              ],
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
        }),
      ),
    );
  }

  void ledgerDetails({
    required List<SaleTransactionModel> transitionModel,
    required CustomerModel customer,
    required PersonalInformationModel personalInformationModel,
    required List<PurchaseTransactionModel> purchaseTransactionReport,
  }) {
    double totalSale = 0;
    double totalPurchase = 0;
    double totalReceive = 0;
    double totalPaid = 0;
    List<SaleTransactionModel> transitions = [];
    List<PurchaseTransactionModel> purchaseTransitions = [];
    List<String> dayLimits = [
      'All',
      '7',
      '15',
      '30',
    ];
    String selectedDate = 'All';
    for (var element in transitionModel) {
      if (element.customerPhone == customer.phoneNumber) {
        transitions.add(element);
        totalSale += element.totalAmount!.toDouble();
        totalReceive += element.totalAmount!.toDouble() - element.dueAmount!.toDouble();
      }
    }
    for (var element in purchaseTransactionReport) {
      if (element.customerPhone == customer.phoneNumber) {
        purchaseTransitions.add(element);
        totalPurchase += element.totalAmount!.toDouble();
        totalPaid += element.totalAmount!.toDouble() - element.dueAmount!.toDouble();
      }
    }

    bool isInTime({required int day, required String date}) {
      if (DateTime.parse(date).isAfter(DateTime.now().subtract(Duration(days: day)))) {
        return true;
      } else if (date == 'All') {
        return true;
      } else {
        return false;
      }
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final kWidth = MediaQuery.of(context).size.width;
        return Consumer(
          builder: (_, ref, watch) {
            final settingProver = ref.watch(generalSettingProvider);
            return StatefulBuilder(
              builder: (context, setState) {
                final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
                final globalCurrency = currencyProvider.currency ?? '\$';
                return Dialog(
                  surfaceTintColor: kWhite,
                  backgroundColor: kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SizedBox(
                    // height: 500,
                    width: 1000,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  lang.S.of(context).ledgerDetails,
                                  // 'Ledger Details',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                  onPressed: () {
                                    GoRouter.of(context).pop();
                                  },
                                  icon: const Icon(FeatherIcons.x, color: kNeutral500, size: 20.0))
                            ],
                          ),
                        ),
                        const Divider(
                          thickness: 1.0,
                          color: kNeutral300,
                          height: 1,
                        ),
                        ResponsiveGridRow(rowSegments: 100, children: [
                          ///________Total Sale____________________________________________
                          ResponsiveGridCol(
                            xs: 100,
                            md: 50,
                            lg: 25,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFFCFF4E3),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$globalCurrency ${myFormat.format(double.tryParse(customer.type == 'Supplier' ? totalPurchase.toString() : totalSale.toString()) ?? 0)}',
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                    ),
                                    Text(
                                      customer.type == 'Supplier' ? lang.S.of(context).totalPurchase : lang.S.of(context).totalSale,
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          ///____________Total received Amount_________________________________
                          ResponsiveGridCol(
                            xs: 100,
                            md: 50,
                            lg: 25,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFF15CD75).withOpacity(0.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$globalCurrency ${myFormat.format(double.tryParse(customer.type == 'Supplier' ? totalPaid.toString() : totalReceive.toString()) ?? 0)}',
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                    ),
                                    Text(
                                      customer.type == 'Supplier' ? lang.S.of(context).paidAmount : lang.S.of(context).receivedAmount,
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          ///________total_customer_due___________________________________________________________
                          ResponsiveGridCol(
                            xs: 100,
                            md: 50,
                            lg: 25,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFFFEE7CB),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$globalCurrency ${myFormat.format(double.tryParse(customer.dueAmount) ?? 0)}',
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                    ),
                                    Text(
                                      lang.S.of(context).totalDue,
                                      //'Total Due',
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          ///________opening balance___________________________________________________________
                          ResponsiveGridCol(
                            xs: 100,
                            md: 50,
                            lg: 25,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFFFEE7CB),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$globalCurrency ${myFormat.format(double.tryParse(customer.remainedBalance) ?? 0)}',
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                    ),
                                    Text(
                                      lang.S.of(context).openingBalance,
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${lang.S.of(context).customerName}: ${customer.customerName}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${lang.S.of(context).customerPhone}: ${customer.phoneNumber}',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              settingProver.when(data: (setting) {
                                return ElevatedButton(
                                  onPressed: () async {
                                    if (customer.type != 'Supplier') {
                                      await GeneratePdfAndPrint().printSaleLedger(personalInformationModel: personalInformationModel, saleTransactionModel: transitions, customer: customer, setting: setting);
                                    } else {
                                      await GeneratePdfAndPrint().printPurchaseLedger(setting: setting, personalInformationModel: personalInformationModel, purchaseTransactionModel: purchaseTransitions, customer: customer);
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.print, color: Colors.white, size: 16),
                                      const SizedBox(width: 5.0),
                                      Text(
                                        lang.S.of(context).print,
                                        // 'Print',
                                        style: kTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }, error: (e, stack) {
                                return Text(e.toString());
                              }, loading: () {
                                return Center(child: CircularProgressIndicator());
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            return RawScrollbar(
                              thickness: 10,
                              thumbVisibility: true,
                              thumbColor: Colors.red,
                              controller: _horizontalScroll,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScroll,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Theme(
                                    data: theme.copyWith(dividerTheme: const DividerThemeData(color: Colors.transparent)),
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
                                        DataColumn(
                                          label: Text(
                                            lang.S.of(context).SL,
                                            //'S.L',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(lang.S.of(context).date,
                                              //'Date',
                                              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold)),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            lang.S.of(context).invoice,
                                            //'Invoice',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            lang.S.of(context).partyName,
                                            //'Party Name',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            lang.S.of(context).paymentType,
                                            //'Payment Type',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(lang.S.of(context).amount, style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold)),
                                        ),
                                        DataColumn(
                                          label: Text(lang.S.of(context).due, style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold)),
                                        ),
                                        DataColumn(
                                          label: Text(lang.S.of(context).status, style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold)),
                                        ),
                                        const DataColumn(
                                          label: Icon(FeatherIcons.settings, color: kGreyTextColor),
                                        ),
                                      ],
                                      rows: customer.type == 'Supplier'
                                          ? List.generate(
                                              purchaseTransitions.length,
                                              (index) {
                                                return DataRow(cells: [
                                                  DataCell(
                                                    Text((index + 1).toString()),
                                                  ),
                                                  DataCell(
                                                    Text(purchaseTransitions[index].purchaseDate.substring(0, 10), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(purchaseTransitions[index].invoiceNumber, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(purchaseTransitions[index].customerName, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(purchaseTransitions[index].paymentType.toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(myFormat.format(double.tryParse(purchaseTransitions[index].totalAmount.toString()) ?? 0), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(myFormat.format(double.tryParse(purchaseTransitions[index].dueAmount!.abs().toString()) ?? 0), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(purchaseTransitions[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    settingProver.when(data: (setting) {
                                                      return SizedBox(
                                                        width: 30,
                                                        child: PopupMenuButton(
                                                          icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                                          padding: EdgeInsets.zero,
                                                          itemBuilder: (BuildContext bc) => [
                                                            PopupMenuItem(
                                                              child: GestureDetector(
                                                                onTap: () async {
                                                                  await GeneratePdfAndPrint().printPurchaseInvoice(setting: setting, personalInformationModel: personalInformationModel, purchaseTransactionModel: purchaseTransitions[index]);
                                                                  // SaleInvoice(
                                                                  //   isPosScreen: false,
                                                                  //   transitionModel: transitions[index],
                                                                  //   personalInformationModel: personalInformationModel,
                                                                  // ).launch(context);
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).print,
                                                                      style: kTextStyle.copyWith(color: kTitleColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                          onSelected: (value) {
                                                            context.go('$value');
                                                            // Navigator.pushNamed(context, '$value');
                                                          },
                                                        ),
                                                      );
                                                    }, error: (e, stack) {
                                                      return Text(e.toString());
                                                    }, loading: () {
                                                      return Center(child: CircularProgressIndicator());
                                                    }),
                                                  ),
                                                ]);
                                              },
                                            )
                                          : List.generate(
                                              transitions.length,
                                              (index) {
                                                return DataRow(cells: [
                                                  DataCell(
                                                    Text((index + 1).toString()),
                                                  ),
                                                  DataCell(
                                                    Text(transitions[index].purchaseDate.substring(0, 10), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(transitions[index].invoiceNumber, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(transitions[index].customerName, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(transitions[index].paymentType.toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(myFormat.format(double.tryParse(transitions[index].totalAmount.toString()) ?? 0), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(myFormat.format(double.tryParse(transitions[index].dueAmount.toString()) ?? 0), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    Text(transitions[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                  ),
                                                  DataCell(
                                                    PopupMenuButton(
                                                      icon: Icon(FeatherIcons.moreVertical, size: 18.0),
                                                      padding: EdgeInsets.zero,
                                                      itemBuilder: (BuildContext bc) => [
                                                        PopupMenuItem(
                                                          child: settingProver.when(data: (setting) {
                                                            return GestureDetector(
                                                              onTap: () async {
                                                                await GeneratePdfAndPrint().printSaleInvoice(fromLedger: true, personalInformationModel: personalInformationModel, saleTransactionModel: transitions[index], setting: setting, context: context);
                                                                // SaleInvoice(
                                                                //   isPosScreen: false,
                                                                //   transitionModel: transitions[index],
                                                                //   personalInformationModel: personalInformationModel,
                                                                // ).launch(context);
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                                  const SizedBox(width: 4.0),
                                                                  Text(
                                                                    lang.S.of(context).print,
                                                                    style: kTextStyle.copyWith(color: kTitleColor),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }, error: (e, stack) {
                                                            return Text(e.toString());
                                                          }, loading: () {
                                                            return Center(
                                                              child: CircularProgressIndicator(),
                                                            );
                                                          }),
                                                        ),
                                                      ],
                                                      onSelected: (value) {
                                                        Navigator.pushNamed(context, '$value');
                                                      },
                                                    ),
                                                  ),
                                                ]);
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
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
}
