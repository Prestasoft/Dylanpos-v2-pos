import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/sales_returns_provider.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class SalesReturnWidget extends StatefulWidget {
  const SalesReturnWidget({super.key});

  @override
  State<SalesReturnWidget> createState() => _SalesReturnWidgetState();
}

class _SalesReturnWidgetState extends State<SalesReturnWidget> {
  double getTotalReturnAmount(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      total += element.totalAmount! - element.dueAmount!;
    }
    return total;
  }

  double calculateTotalDue(List<dynamic> purchaseTransitionModel) {
    double total = 0.0;
    for (var element in purchaseTransitionModel) {
      total += element.dueAmount!;
    }
    return total;
  }

  ScrollController listScroll = ScrollController();
  String searchItem = '';

  final _horizontalScroll = ScrollController();
  int _saleReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (_, ref, watch) {
      final transactionReport = ref.watch(saleReturnProvider);
      final settingProvider = ref.watch(generalSettingProvider);
      return transactionReport.when(data: (transaction) {
        List<SaleTransactionModel> reTransaction = [];
        for (var element in transaction.reversed.toList()) {
          if ((element.invoiceNumber
                  .toLowerCase()
                  .contains(searchItem.toLowerCase()) ||
              element.customerName
                  .toLowerCase()
                  .contains(searchItem.toLowerCase()))) {
            reTransaction.add(element);
          }
        }
        final profile = ref.watch(profileDetailsProvider);
        // Calculate pagination
        final pages = _saleReportPerPage == -1
            ? 1
            : (reTransaction.length / _saleReportPerPage).ceil();
        final startIndex = _saleReportPerPage == -1
            ? 0
            : (_currentPage - 1) * _saleReportPerPage;
        final endIndex = _saleReportPerPage == -1
            ? reTransaction.length
            : (startIndex + _saleReportPerPage).clamp(0, reTransaction.length);
        final paginatedList = reTransaction.sublist(startIndex, endIndex);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: kWhite,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveGridRow(rowSegments: 100, children: [
                    ResponsiveGridCol(
                      xs: 100,
                      md: 35,
                      lg: screenWidth < 1500 ? 35 : 25,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFFCFF4E3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myFormat.format(double.tryParse(
                                        transaction.length.toString()) ??
                                    0),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                lang.S.of(context).totalReturns,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Container(
                    //   padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(10.0),
                    //     color: const Color(0xFFFEE7CB),
                    //   ),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         '\$${getTotalDue(transaction).toString()}',
                    //         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    //       ),
                    //       Text(
                    //         'Unpaid',
                    //         style: kTextStyle.copyWith(color: kTitleColor),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    ResponsiveGridCol(
                      xs: 100,
                      md: screenWidth < 880 ? 50 : 35,
                      lg: screenWidth < 1500 ? 35 : 25,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFFFED3D3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$globalCurrency${myFormat.format(double.tryParse(getTotalReturnAmount(transaction).toString()) ?? 0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                lang.S.of(context).totalReturnAmount,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: kWhite,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      lang.S.of(context).saleReturn,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),

                  ///___________search________________________________________________-
                  ResponsiveGridRow(rowSegments: 100, children: [
                    ResponsiveGridCol(
                      xs: screenWidth < 360
                          ? 50
                          : screenWidth > 430
                              ? 38
                              : 45,
                      md: screenWidth < 768
                          ? 29
                          : screenWidth < 950
                              ? 25
                              : 20,
                      lg: screenWidth < 1700 ? 20 : 17,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          alignment: Alignment.center,
                          height: 48,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: kThemeOutlineColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                  child: Text(
                                'Mostrar-',
                                style: theme.textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              DropdownButton<int>(
                                isDense: true,
                                padding: EdgeInsets.zero,
                                underline: const SizedBox(),
                                value: _saleReportPerPage,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black,
                                ),
                                items: [10, 20, 50, 100, -1]
                                    .map<DropdownMenuItem<int>>((int value) {
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
                                      _saleReportPerPage =
                                          -1; // Set to -1 for "All"
                                    } else {
                                      _saleReportPerPage = newValue ?? 10;
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
                      md: 60,
                      lg: 35,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextFormField(
                          showCursor: true,
                          cursorColor: kTitleColor,
                          onChanged: (value) {
                            setState(() {
                              searchItem = value;
                            });
                          },
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10.0),
                            hintText:
                                (lang.S.of(context).searchByInvoiceOrName),
                            border: InputBorder.none,
                            suffixIcon: const Icon(
                              FeatherIcons.search,
                              color: kTitleColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),

                  ///________sate_list_________________________________________________________
                  reTransaction.isNotEmpty
                      ? Column(
                          children: [
                            LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
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
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: Theme(
                                        data: theme.copyWith(
                                          dividerTheme: const DividerThemeData(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        child: DataTable(
                                            border: const TableBorder(
                                              horizontalInside: BorderSide(
                                                width: 1,
                                                color: kNeutral300,
                                              ),
                                            ),
                                            dataRowColor:
                                                const WidgetStatePropertyAll(
                                                    Colors.white),
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    const Color(0xFFF8F3FF)),
                                            showBottomBorder: false,
                                            dividerThickness: 0.0,
                                            headingTextStyle:
                                                theme.textTheme.titleMedium,
                                            columns: [
                                              DataColumn(
                                                  label: Text(
                                                      lang.S.of(context).SL)),
                                              DataColumn(
                                                  label: Text(
                                                      lang.S.of(context).date)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .invoice)),
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
                                                      .amount)),
                                              DataColumn(
                                                  label: Text(
                                                      lang.S.of(context).due)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .status)),
                                              const DataColumn(
                                                  label: SizedBox(
                                                      width: 30,
                                                      child: Icon(FeatherIcons
                                                          .settings))),
                                            ],
                                            rows: List.generate(
                                                paginatedList.length, (index) {
                                              return DataRow(cells: [
                                                ///______________S.L__________________________________________________
                                                DataCell(
                                                  Text(
                                                    "${startIndex + index + 1}",
                                                  ),
                                                ),

                                                ///______________Date__________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                        .purchaseDate
                                                        .substring(0, 10),
                                                  ),
                                                ),

                                                ///____________Invoice_________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                        .invoiceNumber,
                                                  ),
                                                ),

                                                ///______Party Name___________________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                        .customerName,
                                                  ),
                                                ),

                                                ///___________Party Type______________________________________________

                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                        .paymentType
                                                        .toString(),
                                                  ),
                                                ),

                                                ///___________Amount____________________________________________________
                                                DataCell(
                                                  Text(
                                                    '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].totalAmount.toString()) ?? 0)}',
                                                  ),
                                                ),

                                                ///___________Due____________________________________________________

                                                DataCell(
                                                  Text(
                                                    '$globalCurrency${paginatedList[index].dueAmount.toString()}',
                                                  ),
                                                ),

                                                ///___________Due____________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedList[index].isPaid!
                                                        ? lang.S
                                                            .of(context)
                                                            .paid
                                                        : lang.S
                                                            .of(context)
                                                            .due,
                                                  ),
                                                ),

                                                ///_______________actions_________________________________________________
                                                DataCell(
                                                  settingProvider.when(
                                                      data: (setting) {
                                                    return Theme(
                                                      data: ThemeData(
                                                          highlightColor:
                                                              dropdownItemColor,
                                                          focusColor:
                                                              dropdownItemColor,
                                                          hoverColor:
                                                              dropdownItemColor),
                                                      child: PopupMenuButton(
                                                        surfaceTintColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        itemBuilder:
                                                            (BuildContext bc) =>
                                                                [
                                                          PopupMenuItem(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () async {
                                                                await GeneratePdfAndPrint().printSaleReturnInvoice(
                                                                    personalInformationModel:
                                                                        profile
                                                                            .value!,
                                                                    saleTransactionModel:
                                                                        paginatedList[
                                                                            index],
                                                                    setting:
                                                                        setting);
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                      MdiIcons
                                                                          .printer,
                                                                      size:
                                                                          18.0,
                                                                      color:
                                                                          kTitleColor),
                                                                  const SizedBox(
                                                                      width:
                                                                          4.0),
                                                                  Text(
                                                                    lang.S
                                                                        .of(context)
                                                                        .print,
                                                                    style: kTextStyle
                                                                        .copyWith(
                                                                            color:
                                                                                kTitleColor),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        child: Center(
                                                          child: Container(
                                                              height: 18,
                                                              width: 18,
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: const Icon(
                                                                Icons
                                                                    .more_vert_sharp,
                                                                size: 18,
                                                              )),
                                                        ),
                                                      ),
                                                    );
                                                  }, error: (e, stack) {
                                                    return Text(e.toString());
                                                  }, loading: () {
                                                    return Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  }),
                                                ),
                                              ]);
                                            })),
                                      ),
                                    ),
                                  ),
                                );
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
                                      '${lang.S.of(context).showing} ${((_currentPage - 1) * _saleReportPerPage + 1).toString()} to ${((_currentPage - 1) * _saleReportPerPage + _saleReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        overlayColor:
                                            WidgetStateProperty.all<Color>(
                                                Colors.grey),
                                        hoverColor: Colors.grey,
                                        onTap: _currentPage > 1
                                            ? () =>
                                                setState(() => _currentPage--)
                                            : null,
                                        child: Container(
                                          height: 32,
                                          width: 90,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(4.0),
                                              topLeft: Radius.circular(4.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                                lang.S.of(context).previous),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: kBorderColorTextField),
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
                                              color: kBorderColorTextField),
                                          color: Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$pages',
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        hoverColor:
                                            Colors.blue.withValues(alpha: 0.1),
                                        overlayColor:
                                            WidgetStateProperty.all<Color>(
                                                Colors.blue),
                                        onTap: _currentPage *
                                                    _saleReportPerPage <
                                                reTransaction.length
                                            ? () =>
                                                setState(() => _currentPage++)
                                            : null,
                                        child: Container(
                                          height: 32,
                                          width: 90,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomRight: Radius.circular(4.0),
                                              topRight: Radius.circular(4.0),
                                            ),
                                          ),
                                          child:
                                              const Center(child: Text('Next')),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      : EmptyWidget(title: lang.S.of(context).noReportFound)
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
    });
  }
}
