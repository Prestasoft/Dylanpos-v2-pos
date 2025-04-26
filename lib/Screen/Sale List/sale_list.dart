import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Provider/daily_transaction_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Screen/Sale%20List/sale_edit.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/delete_invoice_functions.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class SaleList extends StatefulWidget {
  const SaleList({super.key});

  // static const String route = '/saleList';

  @override
  State<SaleList> createState() => _SaleListState();
}

class _SaleListState extends State<SaleList> {
  int currentPage = 1;
  late int itemsPerPage = 10;
  String searchItem = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Consumer(builder: (_, consuearRef, watch) {
            AsyncValue<List<SaleTransactionModel>> transactionReport = consuearRef.watch(transitionProvider);
            final profile = consuearRef.watch(profileDetailsProvider);
            final settingProvider = consuearRef.watch(generalSettingProvider);
            return transactionReport.when(data: (mainTransaction) {
              // final reMainTransaction = mainTransaction.reversed.toList();
              // List<SaleTransactionModel> showAbleSaleTransactions = [];
              //
              // for (var element in reMainTransaction) {
              //   if (searchItem != '' &&
              //       (element.customerName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) ||
              //           element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()))) {
              //     showAbleSaleTransactions.add(element);
              //   } else if (searchItem == '') {
              //     showAbleSaleTransactions.add(element);
              //   }
              // }
              //
              // final totalPages = (showAbleSaleTransactions.length / itemsPerPage).ceil();
              // final startIndex = (currentPage - 1) * itemsPerPage;
              // final endIndex = itemsPerPage == -1 ? showAbleSaleTransactions.length : startIndex + itemsPerPage;
              // final paginatedTransactions = showAbleSaleTransactions.sublist(
              //   startIndex,
              //   endIndex > showAbleSaleTransactions.length ? showAbleSaleTransactions.length : endIndex,
              // );
              // Process transactions
              final reMainTransaction = mainTransaction.reversed.toList();
              List<SaleTransactionModel> showAbleSaleTransactions = [];

              // Filter transactions based on search
              for (var element in reMainTransaction) {
                if (searchItem != '' && (element.customerName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()))) {
                  showAbleSaleTransactions.add(element);
                } else if (searchItem == '') {
                  showAbleSaleTransactions.add(element);
                }
              }

              // Calculate pagination
              final totalPages = itemsPerPage == -1 ? 1 : (showAbleSaleTransactions.length / itemsPerPage).ceil();
              final startIndex = itemsPerPage == -1 ? 0 : (currentPage - 1) * itemsPerPage;
              final endIndex = itemsPerPage == -1 ? showAbleSaleTransactions.length : (startIndex + itemsPerPage).clamp(0, showAbleSaleTransactions.length);

              // Get paginated transactions
              final paginatedTransactions = showAbleSaleTransactions.sublist(startIndex, endIndex);
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: kWhite,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Text(
                        lang.S.of(context).salesList,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1.0,
                      color: kDividerColor,
                    ),

                    ///---------------------search---------------------------
                    const SizedBox(height: 16),
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: kNeutral300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(child: Text('Show-', style: theme.textTheme.bodyLarge)),
                                DropdownButton<int>(
                                  isDense: true,
                                  padding: EdgeInsets.zero,
                                  underline: const SizedBox(),
                                  value: itemsPerPage,
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
                                      itemsPerPage = newValue ?? 10;
                                      currentPage = 1; // Always reset to page 1 when changing items per page
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
                          padding: const EdgeInsets.all(10),
                          child: AppTextField(
                            showCursor: true,
                            cursorColor: kTitleColor,
                            onChanged: (value) {
                              setState(() {
                                searchItem = value;
                              });
                            },
                            textFieldType: TextFieldType.NAME,
                            decoration: InputDecoration(
                              hintText: lang.S.of(context).searchByInvoiceOrName,
                              suffixIcon: const Icon(
                                FeatherIcons.search,
                                color: kNeutral700,
                              ),
                            ),
                          ),
                        ),
                      )
                    ]),

                    ///_______sale_List_____________________________________________________
                    const SizedBox(height: 20.0),
                    paginatedTransactions.isNotEmpty
                        ? Column(
                            children: [
                              Scrollbar(
                                thickness: 8.0,
                                thumbVisibility: true,
                                controller: _horizontalScroll,
                                radius: const Radius.circular(5),
                                child: LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
                                    final kWidth = MediaQuery.of(context).size.width - 112.5;
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: _horizontalScroll,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: kWidth,
                                        ),
                                        child: Theme(
                                          data: theme.copyWith(dividerColor: Colors.transparent, dividerTheme: const DividerThemeData(color: Colors.transparent)),
                                          child: DataTable(
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  width: 1,
                                                  color: kNeutral300,
                                                ),
                                              ),
                                              dataRowColor: const WidgetStatePropertyAll(whiteColor),
                                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle: theme.textTheme.titleMedium,
                                              dataTextStyle: theme.textTheme.bodyLarge,
                                              columns: [
                                                DataColumn(label: Text(lang.S.of(context).SL, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).date, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).invoice, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).partyName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).paymentType, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).amount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).due, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).status, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).setting, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                              ],
                                              rows: List.generate(paginatedTransactions.length, (index) {
                                                return DataRow(cells: [
                                                  //--------------------------------sl number--------------------------
                                                  DataCell(
                                                    Text(
                                                      (index + 1 + (currentPage - 1) * itemsPerPage).toString(),
                                                    ),
                                                  ),
                                                  //-----------------------------date--------------------------------------
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].purchaseDate.substring(0, 10),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  //---------------------------invoice number----------------------
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].invoiceNumber,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  //______Party Name___________________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].customerName,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  //___________Party Type______________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].paymentType.toString(),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  //___________Amount____________________________________________________
                                                  DataCell(
                                                    Text(
                                                      '$currency${myFormat.format(double.tryParse(paginatedTransactions[index].totalAmount.toString()) ?? 0)}',
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  //-------------------------due------------------------
                                                  DataCell(
                                                    Text(
                                                      "$currency${myFormat.format(double.tryParse(paginatedTransactions[index].dueAmount.toString()) ?? 0)}",
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  //-----------------------------paid or unpaid----------------------
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  //_______________actions_________________________________________________
                                                  DataCell(
                                                    settingProvider.when(data: (setting) {
                                                      return SizedBox(
                                                        width: 30,
                                                        child: Theme(
                                                          data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                          child: PopupMenuButton(
                                                            surfaceTintColor: Colors.white,
                                                            padding: EdgeInsets.zero,
                                                            itemBuilder: (BuildContext bc) => [
                                                              PopupMenuItem(
                                                                onTap: () async {
                                                                  await GeneratePdfAndPrint().printSaleInvoice(
                                                                    setting: setting,
                                                                    personalInformationModel: profile.value!,
                                                                    saleTransactionModel: showAbleSaleTransactions[index],
                                                                    context: context,
                                                                    fromSaleReports: true,
                                                                  );
                                                                  GoRouter.of(bc).pop();
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(icon: HugeIcons.strokeRoundedPrinter, color: kGreyTextColor, size: 22.0),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).print,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  final arg = SaleEdit(
                                                                    transitionModel: paginatedTransactions[index],
                                                                    personalInformationModel: profile.value!,
                                                                    isPosScreen: false,
                                                                    popUpContext: context,
                                                                  );
                                                                  context.push('/sales/sales-edit', extra: arg); // Use the full nested path
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    Icon(IconlyLight.edit, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).edit,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              ///________Sale List Delete_______________________________
                                                              PopupMenuItem(
                                                                onTap: () => showDialog(
                                                                  context: context,
                                                                  builder: (context2) => AlertDialog(
                                                                    title: Text('${lang.S.of(context).areYouSureToDeleteThisSale}?'),
                                                                    content: Text(
                                                                      '${lang.S.of(context).theSaleWillBeDeletedAndAllTheDataWillBeDeletedAboutThisSaleAreYouSureToDeleteThis}?',
                                                                      maxLines: 5,
                                                                    ),
                                                                    actions: [
                                                                      Text(lang.S.of(context).cancel).onTap(() {
                                                                        // Use Navigator.of(context2) to pop the dialog
                                                                        Navigator.of(context2).pop();
                                                                      }),
                                                                      Padding(
                                                                        padding: const EdgeInsets.all(20.0),
                                                                        child: GestureDetector(
                                                                          onTap: () async {
                                                                            EasyLoading.show();

                                                                            DeleteInvoice delete = DeleteInvoice();
                                                                            await delete.editStockAndSerial(saleTransactionModel: showAbleSaleTransactions[index]);
                                                                            await delete.customerDueUpdate(
                                                                              due: showAbleSaleTransactions[index].dueAmount ?? 0,
                                                                              phone: showAbleSaleTransactions[index].customerPhone,
                                                                            );
                                                                            await delete.updateFromShopRemainBalance(
                                                                              paidAmount: (showAbleSaleTransactions[index].totalAmount ?? 0) - (showAbleSaleTransactions[index].dueAmount ?? 0),
                                                                              isFromPurchase: false,
                                                                            );
                                                                            await delete.deleteDailyTransaction(invoice: showAbleSaleTransactions[index].invoiceNumber, status: 'Sale', field: "saleTransactionModel");
                                                                            DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Transition/${showAbleSaleTransactions[index].key}");

                                                                            await ref.remove();
                                                                            consuearRef.refresh(transitionProvider);
                                                                            consuearRef.refresh(productProvider);
                                                                            consuearRef.refresh(allCustomerProvider);
                                                                            consuearRef.refresh(profileDetailsProvider);
                                                                            consuearRef.refresh(dailyTransactionProvider);
                                                                            EasyLoading.showSuccess(lang.S.of(context).done);
                                                                            // Use Navigator.of(context2).pop() instead of GoRouter.of(context2).pop()
                                                                            // Navigator.of(context2).pop();
                                                                            // Use Navigator.of(bc).pop() instead of GoRouter.of(bc).pop()
                                                                            // Navigator.of(bc).pop();
                                                                            GoRouter.of(bc).pop();
                                                                          },
                                                                          child: Text(lang.S.of(context).yesDeleteForever),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(
                                                                      icon: HugeIcons.strokeRoundedDelete02,
                                                                      color: kGreyTextColor,
                                                                      size: 22,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10.0,
                                                                    ),
                                                                    Text(
                                                                      lang.S.of(context).delete,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              ///____Sales_Return________________________________________
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  context.push(
                                                                    '/sales/sales-return',
                                                                    extra: {
                                                                      'personalInformationModel': profile.value!,
                                                                      'saleTransactionModel': showAbleSaleTransactions[index],
                                                                    },
                                                                  );
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(Icons.assignment_return, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).saleReturn,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                            child: Center(
                                                              child: Container(
                                                                  height: 18,
                                                                  width: 18,
                                                                  alignment: Alignment.centerRight,
                                                                  child: const Icon(
                                                                    Icons.more_vert_sharp,
                                                                    size: 18,
                                                                  )),
                                                            ),
                                                          ),
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
                                                ]);
                                              })),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       Flexible(
                              //         child: Text(
                              //           itemsPerPage == -1
                              //               ? 'Showing all ${showAbleSaleTransactions.length} entries'
                              //               : 'Showing ${startIndex + 1} to $endIndex of ${showAbleSaleTransactions.length} entries',
                              //           style: theme.textTheme.bodyLarge?.copyWith(
                              //             color: kNeutral700,
                              //           ),
                              //           maxLines: 2,
                              //           overflow: TextOverflow.ellipsis,
                              //         ),
                              //       ),
                              //       if (itemsPerPage != -1) // Only show pagination controls when not showing "All"
                              //         Container(
                              //           alignment: Alignment.center,
                              //           height: 32,
                              //           decoration: BoxDecoration(
                              //             borderRadius: BorderRadius.circular(4),
                              //             border: Border.all(color: kNeutral300),
                              //           ),
                              //           child: Row(
                              //             children: [
                              //               Padding(
                              //                 padding: const EdgeInsets.symmetric(horizontal: 10),
                              //                 child: GestureDetector(
                              //                   onTap: () {
                              //                     if (currentPage > 1) {
                              //                       setState(() {
                              //                         currentPage--;
                              //                       });
                              //                     }
                              //                   },
                              //                   child: Text(
                              //                     'Previous',
                              //                     style: theme.textTheme.bodyLarge?.copyWith(
                              //                       color: kNeutral700,
                              //                     ),
                              //                   ),
                              //                 ),
                              //               ),
                              //               Container(
                              //                 alignment: Alignment.center,
                              //                 decoration: const BoxDecoration(
                              //                   color: kMainColor,
                              //                   border: Border.symmetric(
                              //                     vertical: BorderSide(color: kNeutral300),
                              //                   ),
                              //                 ),
                              //                 child: Padding(
                              //                   padding: const EdgeInsets.symmetric(horizontal: 10),
                              //                   child: Text(
                              //                     '$currentPage',
                              //                     style: theme.textTheme.bodyLarge?.copyWith(
                              //                       color: Colors.white,
                              //                     ),
                              //                   ),
                              //                 ),
                              //               ),
                              //               Container(
                              //                 alignment: Alignment.center,
                              //                 decoration: const BoxDecoration(
                              //                   border: Border.symmetric(
                              //                     vertical: BorderSide(color: kNeutral300),
                              //                   ),
                              //                 ),
                              //                 child: Padding(
                              //                   padding: const EdgeInsets.symmetric(horizontal: 10),
                              //                   child: Text(
                              //                     '$totalPages',
                              //                     style: theme.textTheme.bodyLarge?.copyWith(
                              //                       color: kNeutral700,
                              //                     ),
                              //                   ),
                              //                 ),
                              //               ),
                              //               Padding(
                              //                 padding: const EdgeInsets.symmetric(horizontal: 10),
                              //                 child: GestureDetector(
                              //                   onTap: () {
                              //                     if (currentPage < totalPages) {
                              //                       setState(() {
                              //                         currentPage++;
                              //                       });
                              //                     }
                              //                   },
                              //                   child: Text(
                              //                     'Next',
                              //                     style: theme.textTheme.bodyLarge?.copyWith(
                              //                       color: kNeutral700,
                              //                     ),
                              //                   ),
                              //                 ),
                              //               ),
                              //             ],
                              //           ),
                              //         ),
                              //     ],
                              //   ),
                              // ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Showing ${startIndex + 1} to ${endIndex > showAbleSaleTransactions.length ? showAbleSaleTransactions.length : endIndex} of ${showAbleSaleTransactions.length} entries',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: kNeutral700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: kNeutral300),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (currentPage > 1) {
                                                  setState(() {
                                                    currentPage--;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                'Previous',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                                color: kMainColor,
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                                  color: kNeutral300,
                                                ))),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$currentPage',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                              color: kNeutral300,
                                            ))),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$totalPages',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (currentPage < totalPages) {
                                                  setState(() {
                                                    currentPage++;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                'Next',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        : EmptyWidget(title: lang.S.of(context).noSaleTransaactionFound)
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
          }),
        ),
      ),
    );
  }
}
