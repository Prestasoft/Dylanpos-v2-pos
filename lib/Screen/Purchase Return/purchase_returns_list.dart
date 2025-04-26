// ignore_for_file: unused_result

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/product_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/purchase_returns_provider.dart';
import '../../Provider/purchase_transaction_single.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/daily_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class PurchaseReturn extends StatefulWidget {
  const PurchaseReturn({super.key});

  // static const String route = '/purchase_Return';

  @override
  State<PurchaseReturn> createState() => _PurchaseReturnState();
}

class _PurchaseReturnState extends State<PurchaseReturn> {
  Future<void> saleReturn({required PurchaseTransactionModel purchase, required WidgetRef consumerRef, required BuildContext context}) async {
    try {
      EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);

      ///_________Push_on_Sale_return_dataBase____________________________________________________________________________
      DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Purchase Return");
      await ref.push().set(purchase.toJson());

      ///________________delete_From_Sale_transaction______________________________________________________________________
      String? key;
      await FirebaseDatabase.instance.ref(await getUserID()).child('Purchase Transition').orderByKey().get().then((value) {
        for (var element in value.children) {
          final t = PurchaseTransactionModel.fromJson(jsonDecode(jsonEncode(element.value)));
          if (purchase.invoiceNumber == t.invoiceNumber) {
            key = element.key;
          }
        }
      });
      await FirebaseDatabase.instance.ref(await getUserID()).child('Purchase Transition').child(key!).remove();

      ///__________StockMange_________________________________________________________________________________
      final stockRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');

      for (var element in purchase.productList!) {
        var data = await stockRef.orderByChild('productCode').equalTo(element.productCode).once();
        final data2 = jsonDecode(jsonEncode(data.snapshot.children.first.value));

        var data1 = await stockRef.child('${data.snapshot.children.first.key}/productStock').get();
        int stock = int.parse(data1.value.toString());
        int remainStock = stock - (int.tryParse(element.productStock) ?? 0);

        stockRef.child(data.snapshot.children.first.key!).update({'productStock': '$remainStock'});

        ///________Update_Serial_Number____________________________________________________

        if (element.serialNumber.isNotEmpty) {
          ProductModel p = ProductModel.fromJson(data2);
          final newList = p.serialNumber.where((item) => !element.serialNumber.contains(item)).toList();

          // List<dynamic> result = productOldSerialList.where((item) => !element.serialNumber!.contains(item)).toList();
          stockRef.child(data.snapshot.children.first.key!).update({
            'serialNumber': newList.map((e) => e).toList(),
            // 'serialNumber': p.serialNumber.where((item) => !element.serialNumber.contains(item)).toList(),
          });
        }
      }

      ///________daily_transactionModel_________________________________________________________________________

      DailyTransactionModel dailyTransaction = DailyTransactionModel(name: purchase.customerName, date: purchase.purchaseDate, type: 'Purchase Return', total: purchase.totalAmount!.toDouble(), paymentIn: purchase.totalAmount!.toDouble() - purchase.dueAmount!.toDouble(), paymentOut: 0, remainingBalance: purchase.totalAmount!.toDouble() - purchase.dueAmount!.toDouble(), id: purchase.invoiceNumber, purchaseTransactionModel: purchase);
      postDailyTransaction(dailyTransactionModel: dailyTransaction);

      ///_________DueUpdate___________________________________________________________________________________
      if (purchase.customerName != 'Guest') {
        final dueUpdateRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
        // String? key;
        final customerQuery = dueUpdateRef.orderByChild('phoneNumber').equalTo(purchase.customerPhone);
        final customerSnapshot = await customerQuery.once();

        var data1 = await dueUpdateRef.child('${customerSnapshot.snapshot.children.first.key}/due').get();
        int previousDue = data1.value.toString().toInt();

        int totalDue = previousDue - purchase.dueAmount!.toInt();
        dueUpdateRef.child(customerSnapshot.snapshot.children.first.key!).update({'due': '$totalDue'});
      }

      consumerRef.refresh(allCustomerProvider);
      consumerRef.refresh(buyerCustomerProvider);
      consumerRef.refresh(purchaseTransitionProvider);
      consumerRef.refresh(purchaseTransitionProviderSIngle);
      consumerRef.refresh(dueTransactionProvider);
      consumerRef.refresh(profileDetailsProvider);
      consumerRef.refresh(dailyTransactionProvider);
      consumerRef.refresh(productProvider);

      EasyLoading.showSuccess(lang.S.of(context).successfullyDone);

      // ignore: use_build_context_synchronously
      context.pop();
    } catch (e) {
      EasyLoading.dismiss();
      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  ScrollController mainScroll = ScrollController();
  String searchItem = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  int currentPage = 1;
  final int itemsPerPage = 20;
  final _horizontalController = ScrollController();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          final settingProvider = ref.watch(generalSettingProvider);
          AsyncValue<List<PurchaseTransactionModel>> transactionReport = ref.watch(purchaseReturnProvider);
          final profile = ref.watch(profileDetailsProvider);
          return transactionReport.when(data: (mainTransaction) {
            final reMainTransaction = mainTransaction.reversed.toList();
            List<dynamic> showAbleSaleTransactions = [];
            for (var element in reMainTransaction) {
              if (searchItem != '' && (element.customerName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()))) {
                showAbleSaleTransactions.add(element);
              } else if (searchItem == '') {
                showAbleSaleTransactions.add(element);
              }
            }
            final totalPages = (showAbleSaleTransactions.length / itemsPerPage).ceil();
            final startIndex = (currentPage - 1) * itemsPerPage;
            final endIndex = startIndex + itemsPerPage;
            final paginatedTransactions = showAbleSaleTransactions.sublist(startIndex, endIndex > showAbleSaleTransactions.length ? showAbleSaleTransactions.length : endIndex);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Text(
                        lang.S.of(context).saleReturn,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      height: 1,
                      color: kNeutral300,
                    ),
                    const SizedBox(height: 16),
                    ResponsiveGridRow(children: [
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              hintText: (lang.S.of(context).searchByInvoiceOrName),
                              suffixIcon: const Icon(
                                FeatherIcons.search,
                                color: kTitleColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),

                    ///_______sale_List_____________________________________________________
                    const SizedBox(height: 20.0),
                    showAbleSaleTransactions.isNotEmpty
                        ? Column(
                            children: [
                              LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints constraints) {
                                  final kWidth = constraints.maxWidth;
                                  return Scrollbar(
                                    thickness: 8.0,
                                    thumbVisibility: true,
                                    controller: _horizontalController,
                                    radius: const Radius.circular(5),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: _horizontalController,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: kWidth,
                                        ),
                                        child: Theme(
                                          data: theme.copyWith(
                                            dividerTheme: const DividerThemeData(color: Colors.transparent),
                                          ),
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
                                                DataColumn(label: Text(lang.S.of(context).SL)),
                                                DataColumn(label: Text(lang.S.of(context).date)),
                                                DataColumn(label: Text(lang.S.of(context).invoice)),
                                                DataColumn(label: Text(lang.S.of(context).partyName)),
                                                DataColumn(label: Text(lang.S.of(context).partyType)),
                                                DataColumn(label: Text(lang.S.of(context).amount)),
                                                DataColumn(label: Text(lang.S.of(context).due)),
                                                DataColumn(label: Text(lang.S.of(context).status)),
                                                DataColumn(label: Text(lang.S.of(context).setting)),
                                              ],
                                              rows: List.generate(paginatedTransactions.length, (index) {
                                                return DataRow(cells: [
                                                  ///______________S.L__________________________________________________
                                                  DataCell(
                                                    Text(
                                                      (index + 1).toString(),
                                                    ),
                                                  ),

                                                  ///______________Date__________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].purchaseDate.substring(0, 10),
                                                    ),
                                                  ),

                                                  ///____________Invoice_________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].invoiceNumber,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  ///______Party Name___________________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].customerName,
                                                    ),
                                                  ),

                                                  ///___________Party Type______________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].paymentType.toString(),
                                                    ),
                                                  ),

                                                  ///___________Amount____________________________________________________
                                                  DataCell(
                                                    Text(
                                                      myFormat.format(double.tryParse(paginatedTransactions[index].totalAmount.toString()) ?? 0),
                                                    ),
                                                  ),

                                                  ///___________Due____________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].dueAmount.toString(),
                                                    ),
                                                  ),

                                                  ///___________Due____________________________________________________

                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                                                    ),
                                                  ),

                                                  ///_______________actions_________________________________________________
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
                                                                  await GeneratePdfAndPrint().printPurchaseReturnInvoice(setting: setting, personalInformationModel: profile.value!, purchaseTransactionModel: paginatedTransactions[index]);
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(icon: HugeIcons.strokeRoundedPrinter, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).print,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(
                                                                        color: kGreyTextColor,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              // PopupMenuItem(
                                                              //   child: GestureDetector(
                                                              //     onTap: () {
                                                              //       showDialog(
                                                              //           barrierDismissible: false,
                                                              //           context: context,
                                                              //           builder: (BuildContext dialogContext) {
                                                              //             return Center(
                                                              //               child: Container(
                                                              //                 decoration: const BoxDecoration(
                                                              //                   color: Colors.white,
                                                              //                   borderRadius: BorderRadius.all(
                                                              //                     Radius.circular(15),
                                                              //                   ),
                                                              //                 ),
                                                              //                 child: Padding(
                                                              //                   padding: const EdgeInsets.all(20.0),
                                                              //                   child: Column(
                                                              //                     mainAxisSize: MainAxisSize.min,
                                                              //                     crossAxisAlignment: CrossAxisAlignment.center,
                                                              //                     mainAxisAlignment: MainAxisAlignment.center,
                                                              //                     children: [
                                                              //                       const Text(
                                                              //                         'Are you want to return this purchase?',
                                                              //                         style: TextStyle(fontSize: 22),
                                                              //                       ),
                                                              //                       const SizedBox(height: 30),
                                                              //                       Row(
                                                              //                         mainAxisAlignment: MainAxisAlignment.center,
                                                              //                         mainAxisSize: MainAxisSize.min,
                                                              //                         children: [
                                                              //                           GestureDetector(
                                                              //                             child: Container(
                                                              //                               width: 130,
                                                              //                               height: 50,
                                                              //                               decoration: const BoxDecoration(
                                                              //                                 color: Colors.red,
                                                              //                                 borderRadius: BorderRadius.all(
                                                              //                                   Radius.circular(15),
                                                              //                                 ),
                                                              //                               ),
                                                              //                               child: Center(
                                                              //                                 child: Text(
                                                              //                                   lang.S.of(context).no,
                                                              //                                   style: const TextStyle(color: Colors.white),
                                                              //                                 ),
                                                              //                               ),
                                                              //                             ),
                                                              //                             onTap: () {
                                                              //                               Navigator.pop(dialogContext);
                                                              //                               Navigator.pop(bc);
                                                              //                             },
                                                              //                           ),
                                                              //                           const SizedBox(width: 30),
                                                              //                           GestureDetector(
                                                              //                             child: Container(
                                                              //                               width: 130,
                                                              //                               height: 50,
                                                              //                               decoration: const BoxDecoration(
                                                              //                                 color: Colors.green,
                                                              //                                 borderRadius: BorderRadius.all(
                                                              //                                   Radius.circular(15),
                                                              //                                 ),
                                                              //                               ),
                                                              //                               child: Center(
                                                              //                                 child: Text(
                                                              //                                   lang.S.of(context).yesReturn,
                                                              //                                   style: const TextStyle(color: Colors.white),
                                                              //                                 ),
                                                              //                               ),
                                                              //                             ),
                                                              //                             onTap: () async {
                                                              //                               await saleReturn(
                                                              //                                 purchase: showAbleSaleTransactions[index],
                                                              //                                 consumerRef: ref,
                                                              //                                 context: dialogContext,
                                                              //                               );
                                                              //                               Navigator.pop(dialogContext);
                                                              //                             },
                                                              //                           ),
                                                              //                         ],
                                                              //                       )
                                                              //                     ],
                                                              //                   ),
                                                              //                 ),
                                                              //               ),
                                                              //             );
                                                              //           });
                                                              //     },
                                                              //     child: Row(
                                                              //       children: [
                                                              //         const Icon(Icons.assignment_return, size: 18.0, color: kTitleColor),
                                                              //         const SizedBox(width: 4.0),
                                                              //         Text(
                                                              //           'Purchase Return',
                                                              //           style: kTextStyle.copyWith(color: kTitleColor),
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //   ),
                                                              // ),
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
                                                      return Center(child: CircularProgressIndicator());
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
