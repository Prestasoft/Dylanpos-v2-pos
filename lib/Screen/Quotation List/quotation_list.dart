// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class QuotationList extends StatefulWidget {
  const QuotationList({super.key});

  // static const String route = '/quotationList';

  @override
  State<QuotationList> createState() => _QuotationListState();
}

class _QuotationListState extends State<QuotationList> {
  ScrollController mainScroll = ScrollController();
  void deleteQuotation(
      {required String date,
      required WidgetRef updateRef,
      required BuildContext context}) async {
    EasyLoading.show(status: '${lang.S.of(context).deleting}..');
    String key = '';
    try {
      // Fetch data from Firebase
      final snapshot = await FirebaseDatabase.instance
          .ref(await getUserID())
          .child('Sales Quotation')
          .orderByKey()
          .get();

      // Find the key for the given date
      for (var element in snapshot.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['purchaseDate'].toString() == date) {
          key = element.key.toString();
          break; // Exit loop once the key is found
        }
      }

      // Delete the record
      if (key.isNotEmpty) {
        DatabaseReference ref = FirebaseDatabase.instance
            .ref("${await getUserID()}/Sales Quotation/$key");
        await ref.remove();
        EasyLoading.showSuccess(lang.S.of(context).done);
      } else {
        EasyLoading.showError('Record not found');
      }
    } catch (e) {
      EasyLoading.showError('Failed to delete: $e');
    } finally {
      // Refresh the provider and navigate back
      final _ = updateRef.refresh(quotationProvider);
      GoRouter.of(context).pop();
    }
  }

  String searchItem = '';
  int currentPage = 1;
  late int itemsPerPage = 10;

  String quatationAmount = '0';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          final transactionReport = ref.watch(quotationProvider);
          final profile = ref.watch(profileDetailsProvider);
          return transactionReport.when(data: (transaction) {
            // final reTransaction = transaction.reversed.toList();
            List<SaleTransactionModel> reTransaction = [];

            for (var element in transaction.reversed.toList()) {
              if (searchItem != '' &&
                  (element.customerName
                          .removeAllWhiteSpace()
                          .toLowerCase()
                          .contains(searchItem.toLowerCase()) ||
                      element.invoiceNumber
                          .toLowerCase()
                          .contains(searchItem.toLowerCase()))) {
                reTransaction.add(element);
              } else if (searchItem == '') {
                reTransaction.add(element);
              }
            }
            final totalPages = (reTransaction.length / itemsPerPage).ceil();
            final startIndex = (currentPage - 1) * itemsPerPage;
            final endIndex = itemsPerPage == -1
                ? reTransaction.length
                : startIndex + itemsPerPage;
            final paginatedTransactions = reTransaction.sublist(
              startIndex,
              endIndex > reTransaction.length ? reTransaction.length : endIndex,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.S.of(context).quotationList,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ElevatedButton(
                              onPressed: () {
                                context.go(
                                    '/sales/quotation-list/quotation-screen');
                              },
                              child: Text('Add Quotation'))
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1.0,
                      color: kDividerColor,
                    ),
                    const SizedBox(height: 16),

                    ///___________search________________________________________________-
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
                                Flexible(
                                    child: Text('Show-',
                                        style: theme.textTheme.bodyLarge)),
                                DropdownButton<int>(
                                  isDense: true,
                                  padding: EdgeInsets.zero,
                                  underline: const SizedBox(),
                                  value: itemsPerPage,
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
                                        itemsPerPage =
                                            -1; // Set to -1 for "All"
                                      } else {
                                        itemsPerPage = newValue ?? 10;
                                      }
                                      currentPage = 1;
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
                              hintText:
                                  lang.S.of(context).searchByInvoiceOrName,
                              suffixIcon: const Icon(
                                FeatherIcons.search,
                                color: kNeutral700,
                              ),
                            ),
                          ),
                        ),
                      )
                    ]),
                    const SizedBox(height: 5.0),
                    Divider(
                      thickness: 1.0,
                      color: kGreyTextColor.withOpacity(0.2),
                    ),

                    ///_______sale_List_____________________________________________________

                    const SizedBox(height: 20.0),
                    reTransaction.isNotEmpty
                        ? Column(
                            children: [
                              //-------------------data table---------------
                              LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  final kWidth = constraints.maxWidth;
                                  return Scrollbar(
                                    thickness: 8.0,
                                    thumbVisibility: true,
                                    controller: mainScroll,
                                    radius: const Radius.circular(5),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: mainScroll,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: kWidth,
                                        ),
                                        child: Theme(
                                          data: theme.copyWith(
                                            dividerTheme:
                                                const DividerThemeData(
                                                    color: Colors.transparent),
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
                                                    whiteColor),
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    const Color(0xFFF8F3FF)),
                                            showBottomBorder: false,
                                            dividerThickness: 0.0,
                                            headingTextStyle:
                                                theme.textTheme.titleMedium,
                                            dataTextStyle:
                                                theme.textTheme.bodyLarge,
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
                                                  label: Text(
                                                      lang.S.of(context).type)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .amount)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .setting)),
                                            ],
                                            rows: List.generate(
                                                paginatedTransactions.length,
                                                (index) {
                                              return DataRow(cells: [
                                                //-------------serial number----------------------------
                                                DataCell(Text(
                                                  "${startIndex + index + 1}",
                                                )),
                                                //______________Date__________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedTransactions[index]
                                                        .purchaseDate
                                                        .substring(0, 10),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                //____________Invoice_________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedTransactions[index]
                                                        .invoiceNumber,
                                                  ),
                                                ),
                                                //______Party Name___________________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedTransactions[index]
                                                        .customerName,
                                                  ),
                                                ),
                                                //___________Type______________________________________________
                                                DataCell(
                                                  Text(
                                                    lang.S
                                                        .of(context)
                                                        .quotation,
                                                  ),
                                                ),
                                                //___________Amount____________________________________________________
                                                DataCell(
                                                  Text(
                                                    myFormat.format(int.tryParse(
                                                            paginatedTransactions[
                                                                    index]
                                                                .totalAmount
                                                                .toString()) ??
                                                        0),
                                                  ),
                                                ),
                                                //_______________actions_________________________________________________
                                                DataCell(
                                                  SizedBox(
                                                    width: 30,
                                                    child: Theme(
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
                                                            onTap: () async {
                                                              await GeneratePdfAndPrint().printQuotationInvoice(
                                                                  personalInformationModel:
                                                                      profile
                                                                          .value!,
                                                                  saleTransactionModel:
                                                                      paginatedTransactions[
                                                                          index]);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                HugeIcon(
                                                                    icon: HugeIcons
                                                                        .strokeRoundedPrinter,
                                                                    size: 22.0,
                                                                    color:
                                                                        kGreyTextColor),
                                                                const SizedBox(
                                                                    width: 4.0),
                                                                Text(
                                                                  lang.S
                                                                      .of(context)
                                                                      .print,
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.copyWith(
                                                                    color:
                                                                        kGreyTextColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            onTap: () {
                                                              showDialog(
                                                                  barrierDismissible:
                                                                      false,
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          dialogContext) {
                                                                    return Center(
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            500,
                                                                        decoration:
                                                                            const BoxDecoration(
                                                                          color:
                                                                              Colors.white,
                                                                          borderRadius:
                                                                              BorderRadius.all(
                                                                            Radius.circular(15),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              20.0),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                lang.S.of(context).areYouWantToDeleteThisQuotion,
                                                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                                                  fontWeight: FontWeight.w600,
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 20),
                                                                              ResponsiveGridRow(children: [
                                                                                ResponsiveGridCol(
                                                                                  md: 6,
                                                                                  xs: 6,
                                                                                  lg: 6,
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
                                                                                        // Navigator.pop(dialogContext);
                                                                                        // Navigator.pop(bc);
                                                                                        GoRouter.of(context).pop();
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                ResponsiveGridCol(
                                                                                  md: 6,
                                                                                  xs: 6,
                                                                                  lg: 6,
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.all(10.0),
                                                                                    child: ElevatedButton(
                                                                                      child: Text(
                                                                                        lang.S.of(context).delete,
                                                                                      ),
                                                                                      onPressed: () {
                                                                                        deleteQuotation(date: paginatedTransactions[index].purchaseDate, updateRef: ref, context: bc);
                                                                                        // Navigator.pop(dialogContext);
                                                                                        GoRouter.of(dialogContext).pop();
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              ]),
                                                                              // Row(
                                                                              //   mainAxisAlignment: MainAxisAlignment.center,
                                                                              //   mainAxisSize: MainAxisSize.min,
                                                                              //   children: [
                                                                              //     GestureDetector(
                                                                              //       child: Container(
                                                                              //         width: 130,
                                                                              //         height: 50,
                                                                              //         decoration: const BoxDecoration(
                                                                              //           color: Colors.green,
                                                                              //           borderRadius: BorderRadius.all(
                                                                              //             Radius.circular(15),
                                                                              //           ),
                                                                              //         ),
                                                                              //         child: Center(
                                                                              //           child: Text(
                                                                              //             lang.S.of(context).cancel,
                                                                              //             style: TextStyle(color: Colors.white),
                                                                              //           ),
                                                                              //         ),
                                                                              //       ),
                                                                              //       onTap: () {
                                                                              //         // Navigator.pop(dialogContext);
                                                                              //         // Navigator.pop(bc);
                                                                              //         GoRouter.of(context).pop();
                                                                              //       },
                                                                              //     ),
                                                                              //     const SizedBox(width: 30),
                                                                              //     GestureDetector(
                                                                              //       child: Container(
                                                                              //         width: 130,
                                                                              //         height: 50,
                                                                              //         decoration: const BoxDecoration(
                                                                              //           color: Colors.red,
                                                                              //           borderRadius: BorderRadius.all(
                                                                              //             Radius.circular(15),
                                                                              //           ),
                                                                              //         ),
                                                                              //         child: Center(
                                                                              //           child: Text(
                                                                              //             lang.S.of(context).delete,
                                                                              //             style: TextStyle(color: Colors.white),
                                                                              //           ),
                                                                              //         ),
                                                                              //       ),
                                                                              //       onTap: () {
                                                                              //         deleteQuotation(date: paginatedTransactions[index].purchaseDate, updateRef: ref, context: bc);
                                                                              //         // Navigator.pop(dialogContext);
                                                                              //         GoRouter.of(dialogContext).pop();
                                                                              //       },
                                                                              //     ),
                                                                              //   ],
                                                                              // )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  });
                                                            },
                                                            child: Row(
                                                              children: [
                                                                HugeIcon(
                                                                  icon: HugeIcons
                                                                      .strokeRoundedDelete02,
                                                                  color:
                                                                      kGreyTextColor,
                                                                  size: 22,
                                                                ),
                                                                const SizedBox(
                                                                  width: 10.0,
                                                                ),
                                                                Text(
                                                                  lang.S
                                                                      .of(context)
                                                                      .delete,
                                                                  // 'Delete',
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.copyWith(
                                                                          color:
                                                                              kGreyTextColor),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            onTap: () async {
                                                              if (await Subscription
                                                                  .subscriptionChecker(
                                                                      item:
                                                                          'Sales')) {
                                                                // Check if reTransaction[index] is not null and is of type SaleTransactionModel
                                                                context.go(
                                                                  '/sales/pos-sales',
                                                                  extra:
                                                                      reTransaction[
                                                                          index],
                                                                );
                                                              } else {
                                                                EasyLoading
                                                                    .showError(
                                                                        '${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                                              }
                                                            },
                                                            child: Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .point_of_sale_sharp,
                                                                    size: 22.0,
                                                                    color:
                                                                        kGreyTextColor),
                                                                const SizedBox(
                                                                    width: 4.0),
                                                                Text(
                                                                  lang.S
                                                                      .of(context)
                                                                      .convertToSale,
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.copyWith(
                                                                    color:
                                                                        kGreyTextColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          // PopupMenuItem(
                                                          //   onTap: () async {
                                                          //     if (await Subscription.subscriptionChecker(item: 'Sales')) {
                                                          //       context.go(
                                                          //         '/sales/pos-sales',
                                                          //         extra: reTransaction[index],
                                                          //       );
                                                          //     } else {
                                                          //       EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                                          //     }
                                                          //   },
                                                          //   child: Row(
                                                          //     children: [
                                                          //       const Icon(Icons.point_of_sale_sharp, size: 22.0, color: kGreyTextColor),
                                                          //       const SizedBox(width: 4.0),
                                                          //       Text(
                                                          //         lang.S.of(context).convertToSale,
                                                          //         style: theme.textTheme.bodyLarge?.copyWith(
                                                          //           color: kGreyTextColor,
                                                          //         ),
                                                          //       ),
                                                          //     ],
                                                          //   ),
                                                          // ),
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
                                                    ),
                                                  ),
                                                ),
                                              ]);
                                            }),

                                            // Container(
                                            //   padding: const EdgeInsets.all(15),
                                            //   decoration: const BoxDecoration(color: kbgColor),
                                            //   child: Row(
                                            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            //     children: [
                                            //       SizedBox(width: 50, child: Text(lang.S.of(context).SL)),
                                            //       SizedBox(width: 85, child: Text(lang.S.of(context).date)),
                                            //       SizedBox(width: 50, child: Text(lang.S.of(context).invoice)),
                                            //       SizedBox(width: 180, child: Text(lang.S.of(context).partyName)),
                                            //       SizedBox(width: 100, child: Text(lang.S.of(context).type)),
                                            //       SizedBox(width: 70, child: Text(lang.S.of(context).amount)),
                                            //       const SizedBox(width: 30, child: Icon(FeatherIcons.settings)),
                                            //     ],
                                            //   ),
                                            // ),
                                            // SizedBox(
                                            //   height: (MediaQuery.of(context).size.height - 315).isNegative ? 0 : MediaQuery.of(context).size.height - 315,
                                            //   child: ListView.builder(
                                            //     shrinkWrap: true,
                                            //     physics: const AlwaysScrollableScrollPhysics(),
                                            //     itemCount: reTransaction.length,
                                            //     itemBuilder: (BuildContext context, int index) {
                                            //       return Column(
                                            //         children: [
                                            //           Padding(
                                            //             padding: const EdgeInsets.all(15),
                                            //             child: Row(
                                            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            //               children: [
                                            //                 ///______________S.L__________________________________________________
                                            //                 SizedBox(
                                            //                   width: 50,
                                            //                   child: Text((index + 1).toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                            //                 ),
                                            //
                                            //                 ///______________Date__________________________________________________
                                            //                 SizedBox(
                                            //                   width: 85,
                                            //                   child: Text(
                                            //                     reTransaction[index].purchaseDate.substring(0, 10),
                                            //                     overflow: TextOverflow.ellipsis,
                                            //                     maxLines: 2,
                                            //                     style: kTextStyle.copyWith(color: kGreyTextColor, overflow: TextOverflow.ellipsis),
                                            //                   ),
                                            //                 ),
                                            //
                                            //                 ///____________Invoice_________________________________________________
                                            //                 SizedBox(
                                            //                   width: 50,
                                            //                   child: Text(reTransaction[index].invoiceNumber,
                                            //                       maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                            //                 ),
                                            //
                                            //                 ///______Party Name___________________________________________________________
                                            //                 SizedBox(
                                            //                   width: 180,
                                            //                   child: Text(
                                            //                     reTransaction[index].customerName,
                                            //                     style: kTextStyle.copyWith(color: kGreyTextColor),
                                            //                     maxLines: 2,
                                            //                     overflow: TextOverflow.ellipsis,
                                            //                   ),
                                            //                 ),
                                            //
                                            //                 ///___________Type______________________________________________
                                            //
                                            //                 SizedBox(
                                            //                   width: 100,
                                            //                   child: Text(
                                            //                     lang.S.of(context).quotation,
                                            //                     style: kTextStyle.copyWith(color: kGreyTextColor),
                                            //                     maxLines: 2,
                                            //                     overflow: TextOverflow.ellipsis,
                                            //                   ),
                                            //                 ),
                                            //
                                            //                 ///___________Amount____________________________________________________
                                            //                 SizedBox(
                                            //                   width: 70,
                                            //                   child: Text(
                                            //                     myFormat.format(int.tryParse(reTransaction[index].totalAmount.toString()) ?? 0),
                                            //                     style: kTextStyle.copyWith(color: kGreyTextColor),
                                            //                     maxLines: 2,
                                            //                     overflow: TextOverflow.ellipsis,
                                            //                   ),
                                            //                 ),
                                            //
                                            //                 ///_______________actions_________________________________________________
                                            //                 SizedBox(
                                            //                   width: 30,
                                            //                   child: Theme(
                                            //                     data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                            //                     child: PopupMenuButton(
                                            //                       surfaceTintColor: Colors.white,
                                            //                       padding: EdgeInsets.zero,
                                            //                       itemBuilder: (BuildContext bc) => [
                                            //                         PopupMenuItem(
                                            //                           child: GestureDetector(
                                            //                             onTap: () async {
                                            //                               await GeneratePdfAndPrint()
                                            //                                   .printQuotationInvoice(personalInformationModel: profile.value!, saleTransactionModel: reTransaction[index]);
                                            //                             },
                                            //                             child: Row(
                                            //                               children: [
                                            //                                 Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                            //                                 const SizedBox(width: 4.0),
                                            //                                 Text(
                                            //                                   lang.S.of(context).print,
                                            //                                   style: kTextStyle.copyWith(color: kTitleColor),
                                            //                                 ),
                                            //                               ],
                                            //                             ),
                                            //                           ),
                                            //                         ),
                                            //                         PopupMenuItem(
                                            //                           child: GestureDetector(
                                            //                             onTap: () {
                                            //                               showDialog(
                                            //                                   barrierDismissible: false,
                                            //                                   context: context,
                                            //                                   builder: (BuildContext dialogContext) {
                                            //                                     return Center(
                                            //                                       child: Container(
                                            //                                         decoration: const BoxDecoration(
                                            //                                           color: Colors.white,
                                            //                                           borderRadius: BorderRadius.all(
                                            //                                             Radius.circular(15),
                                            //                                           ),
                                            //                                         ),
                                            //                                         child: Padding(
                                            //                                           padding: const EdgeInsets.all(20.0),
                                            //                                           child: Column(
                                            //                                             mainAxisSize: MainAxisSize.min,
                                            //                                             crossAxisAlignment: CrossAxisAlignment.center,
                                            //                                             mainAxisAlignment: MainAxisAlignment.center,
                                            //                                             children: [
                                            //                                               Text(
                                            //                                                 lang.S.of(context).areYouWantToDeleteThisQuotion,
                                            //                                                 style: const TextStyle(fontSize: 22),
                                            //                                               ),
                                            //                                               const SizedBox(height: 30),
                                            //                                               Row(
                                            //                                                 mainAxisAlignment: MainAxisAlignment.center,
                                            //                                                 mainAxisSize: MainAxisSize.min,
                                            //                                                 children: [
                                            //                                                   GestureDetector(
                                            //                                                     child: Container(
                                            //                                                       width: 130,
                                            //                                                       height: 50,
                                            //                                                       decoration: const BoxDecoration(
                                            //                                                         color: Colors.green,
                                            //                                                         borderRadius: BorderRadius.all(
                                            //                                                           Radius.circular(15),
                                            //                                                         ),
                                            //                                                       ),
                                            //                                                       child: Center(
                                            //                                                         child: Text(
                                            //                                                           lang.S.of(context).cancel,
                                            //                                                           style: TextStyle(color: Colors.white),
                                            //                                                         ),
                                            //                                                       ),
                                            //                                                     ),
                                            //                                                     onTap: () {
                                            //                                                       Navigator.pop(dialogContext);
                                            //                                                       Navigator.pop(bc);
                                            //                                                     },
                                            //                                                   ),
                                            //                                                   const SizedBox(width: 30),
                                            //                                                   GestureDetector(
                                            //                                                     child: Container(
                                            //                                                       width: 130,
                                            //                                                       height: 50,
                                            //                                                       decoration: const BoxDecoration(
                                            //                                                         color: Colors.red,
                                            //                                                         borderRadius: BorderRadius.all(
                                            //                                                           Radius.circular(15),
                                            //                                                         ),
                                            //                                                       ),
                                            //                                                       child: Center(
                                            //                                                         child: Text(
                                            //                                                           lang.S.of(context).delete,
                                            //                                                           style: TextStyle(color: Colors.white),
                                            //                                                         ),
                                            //                                                       ),
                                            //                                                     ),
                                            //                                                     onTap: () {
                                            //                                                       deleteQuotation(date: reTransaction[index].purchaseDate, updateRef: ref, context: bc);
                                            //                                                       Navigator.pop(dialogContext);
                                            //                                                     },
                                            //                                                   ),
                                            //                                                 ],
                                            //                                               )
                                            //                                             ],
                                            //                                           ),
                                            //                                         ),
                                            //                                       ),
                                            //                                     );
                                            //                                   });
                                            //                             },
                                            //                             child: Row(
                                            //                               children: [
                                            //                                 const Icon(Icons.delete, size: 18.0, color: kTitleColor),
                                            //                                 const SizedBox(width: 4.0),
                                            //                                 Text(
                                            //                                   lang.S.of(context).delete,
                                            //                                   style: kTextStyle.copyWith(color: kTitleColor),
                                            //                                 ),
                                            //                               ],
                                            //                             ),
                                            //                           ),
                                            //                         ),
                                            //                         PopupMenuItem(
                                            //                           child: GestureDetector(
                                            //                             onTap: () async {
                                            //                               if (await Subscription.subscriptionChecker(item: 'Sales')) {
                                            //                                 Navigator.push(context, MaterialPageRoute(
                                            //                                   builder: (context) {
                                            //                                     return PosSale(
                                            //                                       quotation: reTransaction[index],
                                            //                                     );
                                            //                                   },
                                            //                                 ));
                                            //                                 // ShowPaymentPopUp(
                                            //                                 //   transitionModel: reTransaction[index],
                                            //                                 //   isFromQuotation: true,
                                            //                                 // ).launch(context);
                                            //                               } else {
                                            //                                 //EasyLoading.showError('Update your plan first\nSale Limit is over.');
                                            //                                 EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                            //                               }
                                            //                             },
                                            //                             child: Row(
                                            //                               children: [
                                            //                                 const Icon(Icons.point_of_sale_sharp, size: 18.0, color: kTitleColor),
                                            //                                 const SizedBox(width: 4.0),
                                            //                                 Text(
                                            //                                   lang.S.of(context).convertToSale,
                                            //                                   style: kTextStyle.copyWith(color: kTitleColor),
                                            //                                 ),
                                            //                               ],
                                            //                             ),
                                            //                           ),
                                            //                         ),
                                            //                       ],
                                            //                       child: Center(
                                            //                         child: Container(
                                            //                             height: 18,
                                            //                             width: 18,
                                            //                             alignment: Alignment.centerRight,
                                            //                             child: const Icon(
                                            //                               Icons.more_vert_sharp,
                                            //                               size: 18,
                                            //                             )),
                                            //                       ),
                                            //                     ),
                                            //                   ),
                                            //                 ),
                                            //               ],
                                            //             ),
                                            //           ),
                                            //           Container(
                                            //             width: double.infinity,
                                            //             height: 1,
                                            //             color: kGreyTextColor.withOpacity(0.2),
                                            //           )
                                            //         ],
                                            //       );
                                            //     },
                                            //   ),
                                            // ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 24),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Showing ${startIndex + 1} to ${endIndex > reTransaction.length ? reTransaction.length : endIndex} of ${reTransaction.length} entries',
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
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
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Text(
                                                '$currentPage',
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                              color: kNeutral300,
                                            ))),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Text(
                                                '$totalPages',
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
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
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
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
                        : EmptyWidget(
                            title: lang.S.of(context).noQuotionFound,
                          ),
                  ],
                ),
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
    );
  }
}
