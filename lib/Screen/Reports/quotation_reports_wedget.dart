import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';
import '../currency/currency_provider.dart';

class QuotationReportWidget extends StatefulWidget {
  const QuotationReportWidget({super.key});

  @override
  State<QuotationReportWidget> createState() => _QuotationReportWidgetState();
}

class _QuotationReportWidgetState extends State<QuotationReportWidget> {
  double getTotalDue(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      total += element.dueAmount!;
    }
    return total;
  }

  double calculateTotalSale(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      total += element.totalAmount!;
    }
    return total;
  }

  ScrollController listScroll = ScrollController();

  final _horizontalScroll = ScrollController();
  int _purchaseReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;
  String searchItem = '';

  List<SaleTransactionModel> filterTransactions(
      List<SaleTransactionModel> transactions, String searchTerm) {
    if (searchTerm.isEmpty) {
      return transactions;
    }
    return transactions.where((transaction) {
      return transaction.invoiceNumber
              .toLowerCase()
              .contains(searchTerm.toLowerCase()) ||
          transaction.customerName
              .toLowerCase()
              .contains(searchTerm.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (_, ref, watch) {
      AsyncValue<List<SaleTransactionModel>> transactionReport =
          ref.watch(quotationHistoryProvider);
      return transactionReport.when(data: (transaction) {
        final reTransaction = transaction.reversed.toList();
        final filteredTransactions =
            filterTransactions(reTransaction, searchItem);
        final settingProvder = ref.watch(generalSettingProvider);
        // Calculate pagination
        final pages = _purchaseReportPerPage == -1
            ? 1
            : (filteredTransactions.length / _purchaseReportPerPage).ceil();
        final startIndex = _purchaseReportPerPage == -1
            ? 0
            : (_currentPage - 1) * _purchaseReportPerPage;
        final endIndex = _purchaseReportPerPage == -1
            ? filteredTransactions.length
            : (startIndex + _purchaseReportPerPage)
                .clamp(0, filteredTransactions.length);

        final paginatedList =
            filteredTransactions.sublist(startIndex, endIndex);

        final profile = ref.watch(profileDetailsProvider);
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
                      md: screenWidth < 800 ? 50 : 30,
                      lg: screenWidth < 1500 ? 30 : 20,
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                transaction.length.toString(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                lang.S.of(context).totalSale,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 100,
                      md: screenWidth < 800 ? 50 : 30,
                      lg: screenWidth < 1500 ? 30 : 20,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFFFEE7CB),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$globalCurrency${getTotalDue(transaction).toString()}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                lang.S.of(context).unPaid,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 100,
                      md: screenWidth < 800 ? 50 : 30,
                      lg: screenWidth < 1500 ? 30 : 20,
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$globalCurrency${calculateTotalSale(transaction).toString()}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                lang.S.of(context).totalAmount,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      lang.S.of(context).saleTransactionQuatationHistory,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 20.0),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),
                  Row(
                    children: [
                      Container(
                        height: 40.0,
                        width: 300,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                                color: kGreyTextColor.withValues(alpha: 0.1))),
                        child: AppTextField(
                          showCursor: true,
                          cursorColor: kTitleColor,
                          textFieldType: TextFieldType.NAME,
                          decoration: kInputDecoration.copyWith(
                            contentPadding: const EdgeInsets.all(10.0),
                            hintText: (lang.S.of(context).search),
                            hintStyle:
                                kTextStyle.copyWith(color: kGreyTextColor),
                            border: InputBorder.none,
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0)),
                              borderSide: BorderSide(
                                  color: kBorderColorTextField, width: 1),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0)),
                              borderSide: BorderSide(
                                  color: kBorderColorTextField, width: 1),
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                  padding: const EdgeInsets.all(2.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color:
                                        kGreyTextColor.withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(
                                    FeatherIcons.search,
                                    color: kTitleColor,
                                  )),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        MdiIcons.contentCopy,
                        color: kTitleColor,
                      ),
                      const SizedBox(width: 5.0),
                      Icon(MdiIcons.microsoftExcel, color: kTitleColor),
                      const SizedBox(width: 5.0),
                      Icon(MdiIcons.fileDelimited, color: kTitleColor),
                      const SizedBox(width: 5.0),
                      Icon(MdiIcons.filePdfBox, color: kTitleColor),
                      const SizedBox(width: 5.0),
                      const Icon(FeatherIcons.printer, color: kTitleColor),
                    ],
                  ).visible(false),

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
                                value: _purchaseReportPerPage,
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
                                      _purchaseReportPerPage =
                                          -1; // Set to -1 for "All"
                                    } else {
                                      _purchaseReportPerPage = newValue ?? 10;
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
                                    controller: _horizontalScroll,
                                    scrollDirection: Axis.horizontal,
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
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .setting)),
                                            ],
                                            rows: List.generate(
                                                paginatedList.length, (index) {
                                              return DataRow(cells: [
                                                ///______________S.L__________________________________________________
                                                DataCell(
                                                  Text(
                                                      "${startIndex + index + 1}"),
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
                                                    '$globalCurrency${paginatedList[index].totalAmount.toString()}',
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
                                                  settingProvder.when(
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
                                                                await GeneratePdfAndPrint().printSaleInvoice(
                                                                    fromSaleReports:
                                                                        true,
                                                                    personalInformationModel:
                                                                        profile
                                                                            .value!,
                                                                    setting:
                                                                        setting,
                                                                    saleTransactionModel:
                                                                        paginatedList[
                                                                            index],
                                                                    context:
                                                                        context);
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
                                                          CircularProgressIndicator(),
                                                    );
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
                                      '${lang.S.of(context).showing} ${((_currentPage - 1) * _purchaseReportPerPage + 1).toString()} to ${((_currentPage - 1) * _purchaseReportPerPage + _purchaseReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
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
                                                    _purchaseReportPerPage <
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
                            // Container(
                            //   padding: const EdgeInsets.all(15),
                            //   decoration: const BoxDecoration(color: kbgColor),
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //     children: [
                            //       SizedBox(width: 35, child: Text(lang.S.of(context).SL)),
                            //       SizedBox(width: 78, child: Text(lang.S.of(context).date)),
                            //       SizedBox(width: 50, child: Text(lang.S.of(context).invoice)),
                            //       SizedBox(width: 100, child: Text(lang.S.of(context).partyName)),
                            //       SizedBox(width: 95, child: Text(lang.S.of(context).partyType)),
                            //       SizedBox(width: 70, child: Text(lang.S.of(context).amount)),
                            //       SizedBox(width: 60, child: Text(lang.S.of(context).due)),
                            //       SizedBox(width: 50, child: Text(lang.S.of(context).status)),
                            //       const SizedBox(width: 30, child: Icon(FeatherIcons.settings)),
                            //     ],
                            //   ),
                            // ),
                            // ListView.builder(
                            //   shrinkWrap: true,
                            //   physics: const NeverScrollableScrollPhysics(),
                            //   itemCount: reTransaction.length,
                            //   itemBuilder: (BuildContext context, int index) {
                            //     return Column(
                            //       children: [
                            //         Padding(
                            //           padding: const EdgeInsets.all(15),
                            //           child: Row(
                            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //             children: [
                            //               ///______________S.L__________________________________________________
                            //               SizedBox(
                            //                 width: 40,
                            //                 child: Text((index + 1).toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                            //               ),
                            //
                            //               ///______________Date__________________________________________________
                            //               SizedBox(
                            //                 width: 78,
                            //                 child: Text(
                            //                   reTransaction[index].purchaseDate.substring(0, 10),
                            //                   overflow: TextOverflow.ellipsis,
                            //                   maxLines: 2,
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor, overflow: TextOverflow.ellipsis),
                            //                 ),
                            //               ),
                            //
                            //               ///____________Invoice_________________________________________________
                            //               SizedBox(
                            //                 width: 50,
                            //                 child: Text(reTransaction[index].invoiceNumber,
                            //                     maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kGreyTextColor)),
                            //               ),
                            //
                            //               ///______Party Name___________________________________________________________
                            //               SizedBox(
                            //                 width: 100,
                            //                 child: Text(
                            //                   reTransaction[index].customerName,
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Party Type______________________________________________
                            //
                            //               SizedBox(
                            //                 width: 95,
                            //                 child: Text(
                            //                   reTransaction[index].paymentType.toString(),
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Amount____________________________________________________
                            //               SizedBox(
                            //                 width: 70,
                            //                 child: Text(
                            //                   reTransaction[index].totalAmount.toString(),
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Due____________________________________________________
                            //
                            //               SizedBox(
                            //                 width: 60,
                            //                 child: Text(
                            //                   reTransaction[index].dueAmount.toString(),
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Due____________________________________________________
                            //
                            //               SizedBox(
                            //                 width: 50,
                            //                 child: Text(
                            //                   reTransaction[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///_______________actions_________________________________________________
                            //               SizedBox(
                            //                 width: 30,
                            //                 child: Theme(
                            //                   data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                            //                   child: PopupMenuButton(
                            //                     surfaceTintColor: Colors.white,
                            //                     padding: EdgeInsets.zero,
                            //                     itemBuilder: (BuildContext bc) => [
                            //                       PopupMenuItem(
                            //                         child: GestureDetector(
                            //                           onTap: () async {
                            //                             await GeneratePdfAndPrint()
                            //                                 .printSaleInvoice(personalInformationModel: profile.value!, saleTransactionModel: reTransaction[index]);
                            //                           },
                            //                           child: Row(
                            //                             children: [
                            //                               Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                            //                               const SizedBox(width: 4.0),
                            //                               Text(
                            //                                 lang.S.of(context).print,
                            //                                 style: kTextStyle.copyWith(color: kTitleColor),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                         ),
                            //                       ),
                            //                     ],
                            //                     child: Center(
                            //                       child: Container(
                            //                           height: 18,
                            //                           width: 18,
                            //                           alignment: Alignment.centerRight,
                            //                           child: const Icon(
                            //                             Icons.more_vert_sharp,
                            //                             size: 18,
                            //                           )),
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //         Container(
                            //           width: double.infinity,
                            //           height: 1,
                            //           color: kGreyTextColor.withOpacity(0.2),
                            //         )
                            //       ],
                            //     );
                            //   },
                            // ),
                          ],
                        )
                      : noDataFoundImage(
                          text: lang.S.of(context).noReportFound),
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
