// ignore_for_file: unused_result

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/personal_information_model.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/sales_returns_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/general_setting_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key, required this.saleTransactionModel, required this.personalInformationModel});

  final SaleTransactionModel saleTransactionModel;
  final PersonalInformationModel personalInformationModel;

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> with WidgetsBindingObserver {
  double calculateAmountFromPercentage(double percentage, double price) {
    return (percentage * price) / 100;
  }

  num getTotalReturnAmount() {
    num returnAmount = 0;
    for (var element in returnList) {
      if (element.quantity > 0) {
        returnAmount += element.quantity * (num.tryParse(element.subTotal.toString()) ?? 0);
      }
    }
    return returnAmount;
  }

  Future<void> saleReturn({
    required SaleTransactionModel salesModel,
    required SaleTransactionModel original,
    required WidgetRef consumerRef,
    required BuildContext context,
    required GeneralSettingModel setting,
  }) async {
    try {
      if (!mounted) return; // Check if the widget is still mounted

      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      // Push sales return data to Firebase
      final DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Return");
      await ref.push().set(salesModel.toJson());

      // Print the invoice
      try {
        await GeneratePdfAndPrint().printSaleReturnInvoice(
          setting: setting,
          personalInformationModel: widget.personalInformationModel,
          saleTransactionModel: salesModel,
        );
      } catch (e) {
        if (!mounted) return;
        EasyLoading.dismiss();
      }

      // Update stock
      final stockRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');
      for (var element in salesModel.productList!) {
        var data = await stockRef.orderByChild('productCode').equalTo(element.productId).once();
        final data2 = jsonDecode(jsonEncode(data.snapshot.value));

        String productPath = data.snapshot.value.toString().substring(1, 21);

        var data1 = await stockRef.child('$productPath/productStock').get();
        num stock = num.parse(data1.value.toString());
        num remainStock = stock + element.quantity;

        stockRef.child(productPath).update({'productStock': '$remainStock'});

        if (element.serialNumber != null && element.serialNumber!.isNotEmpty) {
          var productOldSerialList = data2[productPath]['serialNumber'] + element.serialNumber;
          stockRef.child(productPath).update({
            'serialNumber': productOldSerialList.map((e) => e).toList(),
          });
        }
      }

      // Update daily transaction
      final dailyTransaction = DailyTransactionModel(
        name: salesModel.customerName,
        date: salesModel.purchaseDate,
        type: 'Sale Return',
        total: salesModel.totalAmount!.toDouble(),
        paymentIn: 0,
        paymentOut: ((original.totalAmount ?? 0) - (original.dueAmount ?? 0)) > (salesModel.totalAmount ?? 0) ? (salesModel.totalAmount ?? 0) : ((original.totalAmount ?? 0) - (original.dueAmount ?? 0)),
        remainingBalance: ((original.totalAmount ?? 0) - (original.dueAmount ?? 0)) > (salesModel.totalAmount ?? 0) ? (salesModel.totalAmount ?? 0) : ((original.totalAmount ?? 0) - (original.dueAmount ?? 0)),
        id: salesModel.invoiceNumber,
        saleTransactionModel: salesModel,
      );

      await postDailyTransaction(dailyTransactionModel: dailyTransaction);

      // Update due amount
      if (salesModel.customerName != 'Guest' && (original.dueAmount ?? 0) > 0) {
        final dueUpdateRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
        String? key;

        await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
          for (var element in value.children) {
            var data = jsonDecode(jsonEncode(element.value));
            if (data['phoneNumber'] == salesModel.customerPhone) {
              key = element.key;
            }
          }
        });

        var data1 = await dueUpdateRef.child('$key/due').get();
        int previousDue = data1.value.toString().toInt();

        num dueNow = (original.dueAmount ?? 0) - (salesModel.totalAmount ?? 0);
        int totalDue = dueNow.isNegative ? 0 : previousDue - salesModel.totalAmount!.toInt();
        dueUpdateRef.child(key!).update({'due': '$totalDue'});
      }

      // Refresh providers
      consumerRef.refresh(allCustomerProvider);
      consumerRef.refresh(saleReturnProvider);
      consumerRef.refresh(buyerCustomerProvider);
      consumerRef.refresh(transitionProvider);
      consumerRef.refresh(productProvider);
      consumerRef.refresh(purchaseTransitionProvider);
      consumerRef.refresh(dueTransactionProvider);
      consumerRef.refresh(profileDetailsProvider);
      consumerRef.refresh(dailyTransactionProvider);

      if (!mounted) return;
      EasyLoading.showSuccess('Successfully Done');
      // Navigator.of(context).pop();
      // context.push('sales/sales-return-list');
      GoRouter.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Future<void> saleReturn({required SaleTransactionModel salesModel, required SaleTransactionModel orginal, required WidgetRef consumerRef, required BuildContext context}) async {
  //   try {
  //     EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
  //
  //     ///_________Push_on_Sale_return_dataBase____________________________________________________________________________
  //     DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Return");
  //     await ref.push().set(salesModel.toJson());
  //     try {
  //       await GeneratePdfAndPrint().printSaleReturnInvoice(personalInformationModel: widget.personalInformationModel, saleTransactionModel: salesModel);
  //     } catch (e) {
  //       EasyLoading.dismiss();
  //     }
  //
  //     ///__________StockMange_________________________________________________________________________________
  //     final stockRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');
  //
  //     for (var element in salesModel.productList!) {
  //       var data = await stockRef.orderByChild('productCode').equalTo(element.productId).once();
  //       final data2 = jsonDecode(jsonEncode(data.snapshot.value));
  //
  //       String productPath = data.snapshot.value.toString().substring(1, 21);
  //
  //       var data1 = await stockRef.child('$productPath/productStock').get();
  //       num stock = num.parse(data1.value.toString());
  //       num remainStock = stock + element.quantity;
  //
  //       stockRef.child(productPath).update({'productStock': '$remainStock'});
  //
  //       //________Update_Serial_Number____________________________________________________
  //
  //       if (element.serialNumber != null && element.serialNumber!.isNotEmpty) {
  //         var productOldSerialList = data2[productPath]['serialNumber'] + element.serialNumber;
  //
  //         // List<dynamic> result = productOldSerialList.where((item) => !element.serialNumber!.contains(item)).toList();
  //         stockRef.child(productPath).update({
  //           'serialNumber': productOldSerialList.map((e) => e).toList(),
  //         });
  //       }
  //     }
  //
  //     ///________daily_transactionModel_________________________________________________________________________
  //
  //     DailyTransactionModel dailyTransaction = DailyTransactionModel(
  //       name: salesModel.customerName,
  //       date: salesModel.purchaseDate,
  //       type: 'Sale Return',
  //       total: salesModel.totalAmount!.toDouble(),
  //       paymentIn: 0,
  //       paymentOut: ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)) > (salesModel.totalAmount ?? 0)
  //           ? (salesModel.totalAmount ?? 0)
  //           : ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)),
  //       remainingBalance: ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)) > (salesModel.totalAmount ?? 0)
  //           ? (salesModel.totalAmount ?? 0)
  //           : ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)),
  //       id: salesModel.invoiceNumber,
  //       saleTransactionModel: salesModel,
  //     );
  //
  //     postDailyTransaction(dailyTransactionModel: dailyTransaction);
  //
  //     ///_________DueUpdate___________________________________________________________________________________
  //     if (salesModel.customerName != 'Guest' && (orginal.dueAmount ?? 0) > 0) {
  //       final dueUpdateRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
  //       String? key;
  //
  //       await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
  //         for (var element in value.children) {
  //           var data = jsonDecode(jsonEncode(element.value));
  //           if (data['phoneNumber'] == salesModel.customerPhone) {
  //             key = element.key;
  //           }
  //         }
  //       });
  //       var data1 = await dueUpdateRef.child('$key/due').get();
  //       int previousDue = data1.value.toString().toInt();
  //
  //       num dueNow = (orginal.dueAmount ?? 0) - (salesModel.totalAmount ?? 0);
  //
  //       int totalDue = dueNow.isNegative ? 0 : previousDue - salesModel.totalAmount!.toInt();
  //       dueUpdateRef.child(key!).update({'due': '$totalDue'});
  //     }
  //
  //     consumerRef.refresh(allCustomerProvider);
  //     consumerRef.refresh(saleReturnProvider);
  //     consumerRef.refresh(buyerCustomerProvider);
  //     consumerRef.refresh(transitionProvider);
  //     consumerRef.refresh(productProvider);
  //     consumerRef.refresh(purchaseTransitionProvider);
  //     consumerRef.refresh(dueTransactionProvider);
  //     consumerRef.refresh(profileDetailsProvider);
  //     consumerRef.refresh(dailyTransactionProvider);
  //
  //     EasyLoading.showSuccess(lang.S.of(context).successfullyDone);
  //
  //     // ignore: use_build_context_synchronously
  //     context.pop();
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  ScrollController mainScroll = ScrollController();
  String searchItem = '';

  DateTime selectedDueDate = DateTime.now();

  Future<void> _selectedDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDueDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  final _horizontalScroll = ScrollController();

  List<AddToCartModel> returnList = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();

    for (var element in widget.saleTransactionModel.productList!) {
      AddToCartModel p = AddToCartModel(
        warehouseName: element.warehouseName,
        warehouseId: element.warehouseId,
        productPurchasePrice: element.productPurchasePrice,
        productImage: element.productImage,
        itemCartIndex: element.itemCartIndex,
        productBrandName: element.productBrandName,
        productDetails: element.productDetails,
        productId: element.productId,
        productName: element.productName,
        productWarranty: element.productWarranty,
        quantity: 0,
        serialNumber: element.serialNumber,
        stock: element.quantity,
        subTotal: element.subTotal,
        uniqueCheck: element.uniqueCheck,
        unitPrice: element.unitPrice,
        uuid: element.uuid,
        subTaxes: element.subTaxes,
        excTax: element.excTax,
        groupTaxName: element.groupTaxName,
        groupTaxRate: element.groupTaxRate,
        incTax: element.incTax,
        margin: element.margin,
        taxType: element.taxType,
      );
      returnList.add(p);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    mainScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // You can access ancestors here if needed
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
          final settingProvider = ref.watch(generalSettingProvider);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      lang.S.of(context).saleReturn,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),
                  const SizedBox(
                    height: 16,
                  ),

                  ///--------------------------------header section----------------------
                  ResponsiveGridRow(children: [
                    //___________Customer Name_______________________________
                    ResponsiveGridCol(
                      lg: 4,
                      md: 4,
                      xs: 12,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                lang.S.of(context).customerName,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: kNeutral400),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                widget.saleTransactionModel.customerName,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //___________Invoice number_______________________________
                    ResponsiveGridCol(
                      lg: 4,
                      md: 4,
                      xs: 12,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                lang.S.of(context).invoice,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              height: 48.0,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: kNeutral400)),
                              child: Text(
                                "#${widget.saleTransactionModel.invoiceNumber}",
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //------------date--------------------------------------
                    ResponsiveGridCol(
                      lg: 4,
                      md: 4,
                      xs: 12,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                lang.S.of(context).date,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              height: 48.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: kNeutral400)),
                              child: Text(
                                '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                style: theme.textTheme.bodyLarge,
                              ).onTap(() => _selectedDueDate(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  ///___________Cart_List_Show _and buttons__________________________________
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final kWidth = constraints.maxWidth;
                      return Scrollbar(
                        thickness: 8.0,
                        thumbVisibility: true,
                        controller: _horizontalScroll,
                        radius: const Radius.circular(5),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScroll,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: kWidth,
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
                                  dataRowColor: const WidgetStatePropertyAll(whiteColor),
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                  showBottomBorder: false,
                                  dividerThickness: 0.0,
                                  headingTextStyle: theme.textTheme.titleMedium,
                                  dataTextStyle: theme.textTheme.bodyLarge,
                                  columns: [
                                    DataColumn(label: Text(lang.S.of(context).productNam)),
                                    DataColumn(label: Text(lang.S.of(context).saleQuantity)),
                                    DataColumn(label: Text(lang.S.of(context).returnQuantity)),
                                    DataColumn(label: Text(lang.S.of(context).price)),
                                    DataColumn(label: Text(lang.S.of(context).subTotal)),
                                  ],
                                  rows: List.generate(returnList.length, (index) {
                                    TextEditingController quantityController = TextEditingController(text: returnList[index].quantity.toString());
                                    return DataRow(cells: [
                                      ///______________name__________________________________________________
                                      DataCell(
                                        Text(
                                          returnList[index].productName ?? '',
                                        ),
                                      ),

                                      ///____________quantity_________________________________________________
                                      DataCell(
                                        Text(returnList[index].stock.toString()),
                                      ),

                                      ///____________return_quantity_________________________________________________
                                      DataCell(
                                        Row(
                                          children: [
                                            const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor).onTap(() {
                                              setState(() {
                                                returnList[index].quantity > 0 ? returnList[index].quantity-- : returnList[index].quantity = 0;
                                              });
                                            }),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              height: 35,
                                              width: 65,
                                              child: TextFormField(
                                                controller: quantityController,
                                                textAlign: TextAlign.center,
                                                onChanged: (value) {
                                                  if (returnList[index].stock!.toInt() < value.toInt()) {
                                                    EasyLoading.showError(lang.S.of(context).outOfStock);
                                                    quantityController.clear();
                                                  } else if (value == '') {
                                                    returnList[index].quantity = 1;
                                                  } else if (value == '0') {
                                                    returnList[index].quantity = 1;
                                                  } else {
                                                    returnList[index].quantity = value.toInt();
                                                  }
                                                },
                                                onFieldSubmitted: (value) {
                                                  if (value == '') {
                                                    setState(() {
                                                      returnList[index].quantity = 1;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      returnList[index].quantity = value.toInt();
                                                    });
                                                  }
                                                },
                                                decoration: const InputDecoration(border: InputBorder.none),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor).onTap(() {
                                              if (returnList[index].quantity < returnList[index].stock!.toInt()) {
                                                setState(() {
                                                  returnList[index].quantity += 1;
                                                  toast(returnList[index].quantity.toString());
                                                });
                                              } else {
                                                EasyLoading.showError(lang.S.of(context).outOfStock);
                                              }
                                            }),
                                          ],
                                        ),
                                      ),

                                      ///______price___________________________________________________________
                                      DataCell(
                                        SizedBox(
                                          height: 35,
                                          child: TextFormField(
                                            initialValue: myFormat.format(double.tryParse(returnList[index].subTotal) ?? 0),
                                            onChanged: (value) {
                                              if (value == '') {
                                                setState(() {
                                                  returnList[index].subTotal = 0.toString();
                                                });
                                              } else if (double.tryParse(value) == null) {
                                                EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                                              } else {
                                                setState(() {
                                                  returnList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                                });
                                              }
                                            },
                                            onFieldSubmitted: (value) {
                                              if (value == '') {
                                                setState(() {
                                                  returnList[index].subTotal = 0.toString();
                                                });
                                              } else if (double.tryParse(value) == null) {
                                                EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                                              } else {
                                                setState(() {
                                                  returnList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                                });
                                              }
                                            },
                                            decoration: const InputDecoration(border: InputBorder.none),
                                          ),
                                        ),
                                      ),

                                      ///___________subtotal____________________________________________________
                                      DataCell(
                                        Text(
                                          myFormat.format(double.tryParse((double.parse(returnList[index].subTotal) * ((returnList[index].stock ?? 0) - returnList[index].quantity)).toStringAsFixed(2)) ?? 0),
                                          style: kTextStyle.copyWith(color: kTitleColor),
                                        ),
                                      ),
                                    ]);
                                  })),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // IntrinsicWidth(
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       color: kWhite,
                  //       border: Border.all(width: 1, color: kGreyTextColor.withOpacity(0.3)),
                  //       borderRadius: const BorderRadius.all(
                  //         Radius.circular(15),
                  //       ),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Container(
                  //           width: context.width(),
                  //           height: 350,
                  //           // height: context.height() < 720 ? 720 - 410 : context.height(),
                  //           decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: kGreyTextColor.withOpacity(0.3)))),
                  //           child: SingleChildScrollView(
                  //             child: Column(
                  //               mainAxisSize: MainAxisSize.min,
                  //               children: [
                  //                 Container(
                  //                   padding: const EdgeInsets.all(15),
                  //                   decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: kGreyTextColor.withOpacity(0.3)))),
                  //                   child: Row(
                  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //                     children: [
                  //                       SizedBox(width: 250, child: Text(lang.S.of(context).productNam)),
                  //                       SizedBox(width: 110, child: Text(lang.S.of(context).saleQuantity)),
                  //                       SizedBox(width: 110, child: Text(lang.S.of(context).returnQuantity)),
                  //                       SizedBox(width: 70, child: Text(lang.S.of(context).price)),
                  //                       SizedBox(width: 100, child: Text(lang.S.of(context).subTotal)),
                  //                     ],
                  //                   ),
                  //                 ),
                  //                 ListView.builder(
                  //                   shrinkWrap: true,
                  //                   physics: const NeverScrollableScrollPhysics(),
                  //                   itemCount: returnList.length,
                  //                   itemBuilder: (BuildContext context, int index) {
                  //                     TextEditingController quantityController = TextEditingController(text: returnList[index].quantity.toString());
                  //                     return Column(
                  //                       mainAxisSize: MainAxisSize.min,
                  //                       children: [
                  //                         Row(
                  //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //                           children: [
                  //                             ///______________name__________________________________________________
                  //                             Container(
                  //                               width: 250,
                  //                               padding: const EdgeInsets.only(left: 15),
                  //                               child: Column(
                  //                                 mainAxisSize: MainAxisSize.min,
                  //                                 crossAxisAlignment: CrossAxisAlignment.start,
                  //                                 mainAxisAlignment: MainAxisAlignment.center,
                  //                                 children: [
                  //                                   Flexible(
                  //                                     child: Text(
                  //                                       returnList[index].productName ?? '',
                  //                                       maxLines: 2,
                  //                                       overflow: TextOverflow.ellipsis,
                  //                                       style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                  //                                     ),
                  //                                   ),
                  //                                   // Row(
                  //                                   //   children: [
                  //                                   //     Flexible(
                  //                                   //       child: Text(
                  //                                   //         cartList[index].serialNumber!.isEmpty ? '' : 'IMEI/Serial: ${cartList[index].serialNumber}',
                  //                                   //         maxLines: 1,
                  //                                   //         style: kTextStyle.copyWith(fontSize: 12, color: kTitleColor),
                  //                                   //       ),
                  //                                   //     ),
                  //                                   //   ],
                  //                                   // )
                  //                                 ],
                  //                               ),
                  //                             ),
                  //
                  //                             ///____________quantity_________________________________________________
                  //                             SizedBox(
                  //                               width: 110,
                  //                               child: Center(
                  //                                 child: Container(
                  //                                     width: 60,
                  //                                     padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                  //                                     decoration: BoxDecoration(
                  //                                       borderRadius: BorderRadius.circular(2.0),
                  //                                       color: Colors.white,
                  //                                     ),
                  //                                     child: Text(returnList[index].stock.toString())),
                  //                               ),
                  //                             ),
                  //
                  //                             ///____________return_quantity_________________________________________________
                  //                             SizedBox(
                  //                               width: 110,
                  //                               child: Center(
                  //                                 child: Row(
                  //                                   children: [
                  //                                     const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor).onTap(() {
                  //                                       setState(() {
                  //                                         returnList[index].quantity > 0 ? returnList[index].quantity-- : returnList[index].quantity = 0;
                  //                                       });
                  //                                     }),
                  //                                     Container(
                  //                                       width: 60,
                  //                                       padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                  //                                       decoration: BoxDecoration(
                  //                                         borderRadius: BorderRadius.circular(2.0),
                  //                                         color: Colors.white,
                  //                                       ),
                  //                                       child: TextFormField(
                  //                                         controller: quantityController,
                  //                                         textAlign: TextAlign.center,
                  //                                         onChanged: (value) {
                  //                                           if (returnList[index].stock!.toInt() < value.toInt()) {
                  //                                             EasyLoading.showError(lang.S.of(context).outOfStock);
                  //                                             quantityController.clear();
                  //                                           } else if (value == '') {
                  //                                             returnList[index].quantity = 1;
                  //                                           } else if (value == '0') {
                  //                                             returnList[index].quantity = 1;
                  //                                           } else {
                  //                                             returnList[index].quantity = value.toInt();
                  //                                           }
                  //                                         },
                  //                                         onFieldSubmitted: (value) {
                  //                                           if (value == '') {
                  //                                             setState(() {
                  //                                               returnList[index].quantity = 1;
                  //                                             });
                  //                                           } else {
                  //                                             setState(() {
                  //                                               returnList[index].quantity = value.toInt();
                  //                                             });
                  //                                           }
                  //                                         },
                  //                                         decoration: const InputDecoration(border: InputBorder.none),
                  //                                       ),
                  //                                     ),
                  //                                     const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor).onTap(() {
                  //                                       if (returnList[index].quantity < returnList[index].stock!.toInt()) {
                  //                                         setState(() {
                  //                                           returnList[index].quantity += 1;
                  //                                           toast(returnList[index].quantity.toString());
                  //                                         });
                  //                                       } else {
                  //                                         EasyLoading.showError(lang.S.of(context).outOfStock);
                  //                                       }
                  //                                     }),
                  //                                   ],
                  //                                 ),
                  //                               ),
                  //                             ),
                  //
                  //                             ///______price___________________________________________________________
                  //                             SizedBox(
                  //                               width: 70,
                  //                               child: TextFormField(
                  //                                 initialValue: myFormat.format(double.tryParse(returnList[index].subTotal) ?? 0),
                  //                                 onChanged: (value) {
                  //                                   if (value == '') {
                  //                                     setState(() {
                  //                                       returnList[index].subTotal = 0.toString();
                  //                                     });
                  //                                   } else if (double.tryParse(value) == null) {
                  //                                     EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                  //                                   } else {
                  //                                     setState(() {
                  //                                       returnList[index].subTotal = double.parse(value).toStringAsFixed(2);
                  //                                     });
                  //                                   }
                  //                                 },
                  //                                 onFieldSubmitted: (value) {
                  //                                   if (value == '') {
                  //                                     setState(() {
                  //                                       returnList[index].subTotal = 0.toString();
                  //                                     });
                  //                                   } else if (double.tryParse(value) == null) {
                  //                                     EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                  //                                   } else {
                  //                                     setState(() {
                  //                                       returnList[index].subTotal = double.parse(value).toStringAsFixed(2);
                  //                                     });
                  //                                   }
                  //                                 },
                  //                                 decoration: const InputDecoration(border: InputBorder.none),
                  //                               ),
                  //                             ),
                  //
                  //                             ///___________subtotal____________________________________________________
                  //                             SizedBox(
                  //                               width: 100,
                  //                               child: Text(
                  //                                 myFormat.format(double.tryParse(
                  //                                         (double.parse(returnList[index].subTotal) * ((returnList[index].stock ?? 0) - returnList[index].quantity))
                  //                                             .toStringAsFixed(2)) ??
                  //                                     0),
                  //                                 style: kTextStyle.copyWith(color: kTitleColor),
                  //                               ),
                  //                             ),
                  //                           ],
                  //                         ),
                  //                         Container(
                  //                           width: double.infinity,
                  //                           height: 1,
                  //                           color: kGreyTextColor.withOpacity(0.3),
                  //                         ),
                  //                       ],
                  //                     );
                  //                   },
                  //                 )
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  ///_______price_section_____________________________________________
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        ///__________total__________________________________________
                        ResponsiveGridRow(children: [
                          ResponsiveGridCol(
                              xs: 12,
                              md: 6,
                              lg: 6,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  '${lang.S.of(context).totalItem}: ${returnList.length}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              )),
                          ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                md: 6,
                                lg: 6,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    lang.S.of(context).totalReturnAmount,
                                    // 'Total Return Amount',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 12,
                                md: 6,
                                lg: 6,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 4.0, bottom: 4.0),
                                    decoration: const BoxDecoration(color: kGreenTextColor, borderRadius: BorderRadius.all(Radius.circular(8))),
                                    child: Text(
                                      '$globalCurrency ${myFormat.format(getTotalReturnAmount())}',
                                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          )
                        ]),
                        const SizedBox(height: 10.0),

                        ///____________buttons____________________________________________________
                        ResponsiveGridRow(children: [
                          //-----------------cancel button-----------------------
                          ResponsiveGridCol(xs: 12, md: 1, lg: 3, child: const SizedBox.shrink()),
                          ResponsiveGridCol(
                              xs: 12,
                              md: 5,
                              lg: 3,
                              child: Padding(
                                padding: screenWidth < 577 ? const EdgeInsets.only(bottom: 10) : const EdgeInsets.all(10.0),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => GoRouter.of(context).pop(),
                                    child: Text(lang.S.of(context).cancel)),
                              )),
                          //----------------------confirm return button------------------------------------
                          ResponsiveGridCol(
                              xs: 12,
                              md: 5,
                              lg: 3,
                              child: Padding(
                                padding: screenWidth < 577 ? const EdgeInsets.only(bottom: 10) : const EdgeInsets.all(10.0),
                                child: settingProvider.when(data: (setting) {
                                  return ElevatedButton(
                                      onPressed: () async {
                                        if (!returnList.any((element) => element.quantity > 0)) {
                                          EasyLoading.showError(lang.S.of(context).selectAProductForReturn);
                                        } else {
                                          returnList.removeWhere((element) => (element.quantity) <= 0);
                                          SaleTransactionModel editedTransitionModel = widget.saleTransactionModel;
                                          (num.tryParse(getTotalReturnAmount().toString()) ?? 0) > (widget.saleTransactionModel.dueAmount ?? 0) ? editedTransitionModel.isPaid = true : editedTransitionModel.isPaid = false;
                                          if ((widget.saleTransactionModel.dueAmount ?? 0) > 0) {
                                            (num.tryParse(getTotalReturnAmount().toString()) ?? 0) >= (widget.saleTransactionModel.dueAmount ?? 0) ? editedTransitionModel.dueAmount = 0 : editedTransitionModel.dueAmount = (widget.saleTransactionModel.dueAmount ?? 0) - (num.tryParse(getTotalReturnAmount().toString()) ?? 0);
                                          }
                                          List<AddToCartModel> newProductList = [];
                                          List<AddToCartModel> oldProduct = widget.saleTransactionModel.productList!;

                                          for (var p in widget.saleTransactionModel.productList!) {
                                            if (returnList.any((element) => element.productId == p.productId)) {
                                              int index = returnList.indexWhere((element) => element.productId == p.productId);
                                              p.quantity = p.quantity - returnList[index].quantity;
                                            }

                                            if (p.quantity > 0) newProductList.add(p);
                                          }

                                          editedTransitionModel.productList = newProductList;
                                          editedTransitionModel.totalAmount = (editedTransitionModel.totalAmount ?? 0) - (double.tryParse(getTotalReturnAmount().toString()) ?? 0);

                                          // myTransitionModel.totalAmount = widget.newTransitionModel.totalAmount!.toDouble();
                                          ///________________updateInvoice___________________________________________________________OK
                                          String? key;
                                          final userId = await getUserID();
                                          await FirebaseDatabase.instance.ref(userId).child('Sales Transition').orderByKey().get().then((value) {
                                            for (var element in value.children) {
                                              final t = SaleTransactionModel.fromJson(jsonDecode(jsonEncode(element.value)));
                                              if (editedTransitionModel.invoiceNumber == t.invoiceNumber) {
                                                key = element.key;
                                              }
                                            }
                                          });

                                          if (newProductList.isEmpty) {
                                            await FirebaseDatabase.instance.ref(userId).child('Sales Transition').child(key!).remove();
                                          } else {
                                            num totalQuantity = 0;
                                            double lossProfit = 0;
                                            double totalPurchasePrice = 0;
                                            double totalSalePrice = 0;
                                            for (var element in newProductList) {
                                              if (element.taxType == 'Exclusive') {
                                                double tax = calculateAmountFromPercentage(element.groupTaxRate.toDouble(), double.tryParse(element.productPurchasePrice.toString()) ?? 0);
                                                totalPurchasePrice = totalPurchasePrice + ((double.parse(element.productPurchasePrice.toString()) + tax) * element.quantity);
                                              } else {
                                                totalPurchasePrice = totalPurchasePrice + (double.parse(element.productPurchasePrice.toString()) * element.quantity);
                                              }

                                              totalSalePrice = totalSalePrice + (double.parse(element.subTotal.toString()) * element.quantity);

                                              totalQuantity = totalQuantity + element.quantity;
                                            }
                                            lossProfit = ((totalSalePrice - totalPurchasePrice.toDouble()) - double.parse(editedTransitionModel.discountAmount.toString()));
                                            editedTransitionModel.totalQuantity = totalQuantity;
                                            editedTransitionModel.lossProfit = lossProfit;

                                            ///__________total LossProfit & quantity________________________________________________________________
                                            // final postEditedTransitionModel = ShowEditPaymentPopUp.checkLossProfit(transitionModel: editedTransitionModel);
                                            await FirebaseDatabase.instance.ref(userId).child('Sales Transition').child(key!).update(editedTransitionModel.toJson());
                                          }
                                          SaleTransactionModel invoice = SaleTransactionModel(
                                            customerName: widget.saleTransactionModel.customerName,
                                            customerType: widget.saleTransactionModel.customerType,
                                            customerGst: widget.saleTransactionModel.customerGst,
                                            customerPhone: widget.saleTransactionModel.customerPhone,
                                            invoiceNumber: widget.saleTransactionModel.invoiceNumber,
                                            purchaseDate: widget.saleTransactionModel.purchaseDate,
                                            customerAddress: widget.saleTransactionModel.customerAddress,
                                            customerImage: widget.saleTransactionModel.customerImage,
                                            sendWhatsappMessage: widget.saleTransactionModel.sendWhatsappMessage ?? false,
                                            productList: returnList,
                                            totalAmount: double.tryParse(getTotalReturnAmount().toString()),
                                            discountAmount: 0,
                                            dueAmount: 0,
                                            isPaid: false,
                                            lossProfit: 0,
                                            paymentType: 'Cash',
                                            returnAmount: 0,
                                            serviceCharge: 0,
                                            vat: 0,
                                            totalQuantity: 0,
                                          );

                                          await saleReturn(
                                            salesModel: invoice,
                                            setting: setting,
                                            original: widget.saleTransactionModel,
                                            consumerRef: ref,
                                            context: context,
                                          );
                                        }
                                      },
                                      child: Text(lang.S.of(context).conformReturn));
                                }, error: (e, stack) {
                                  return Text(e.toString());
                                }, loading: () {
                                  return Center(child: CircularProgressIndicator());
                                }),
                              )),
                          ResponsiveGridCol(xs: 12, md: 1, lg: 3, child: const SizedBox.shrink()),
                        ]),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     ///________________cancel_button_____________________________________
                        //     Expanded(
                        //       flex: 1,
                        //       child: GestureDetector(
                        //         onTap: () {
                        //           context.pop();
                        //         },
                        //         child: Container(
                        //           padding: const EdgeInsets.all(10.0),
                        //           decoration: BoxDecoration(
                        //             shape: BoxShape.rectangle,
                        //             borderRadius: BorderRadius.circular(10.0),
                        //             color: kRedTextColor,
                        //           ),
                        //           child: Text(
                        //             lang.S.of(context).cancel,
                        //             textAlign: TextAlign.center,
                        //             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 10.0),
                        //     Expanded(
                        //       flex: 1,
                        //       child: Container(
                        //         padding: const EdgeInsets.all(10.0),
                        //         decoration: BoxDecoration(
                        //           shape: BoxShape.rectangle,
                        //           borderRadius: BorderRadius.circular(2.0),
                        //           color: Colors.yellow,
                        //         ),
                        //         child: Text(
                        //           lang.S.of(context).hold,
                        //           textAlign: TextAlign.center,
                        //           style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //         ),
                        //       ),
                        //     ).visible(false),
                        //
                        //     ///________________payments_________________________________________
                        //     const SizedBox(width: 10.0),
                        //     Expanded(
                        //       flex: 1,
                        //       child: GestureDetector(
                        //         onTap: () async {
                        //           if (!returnList.any((element) => element.quantity > 0)) {
                        //             EasyLoading.showError(lang.S.of(context).selectAProductForReturn);
                        //           } else {
                        //             returnList.removeWhere((element) => (element.quantity) <= 0);
                        //             SaleTransactionModel editedTransitionModel = widget.saleTransactionModel;
                        //             (num.tryParse(getTotalReturnAmount().toString()) ?? 0) > (widget.saleTransactionModel.dueAmount ?? 0)
                        //                 ? editedTransitionModel.isPaid = true
                        //                 : editedTransitionModel.isPaid = false;
                        //             if ((widget.saleTransactionModel.dueAmount ?? 0) > 0) {
                        //               (num.tryParse(getTotalReturnAmount().toString()) ?? 0) >= (widget.saleTransactionModel.dueAmount ?? 0)
                        //                   ? editedTransitionModel.dueAmount = 0
                        //                   : editedTransitionModel.dueAmount = (widget.saleTransactionModel.dueAmount ?? 0) - (num.tryParse(getTotalReturnAmount().toString()) ?? 0);
                        //             }
                        //             List<AddToCartModel> newProductList = [];
                        //             List<AddToCartModel> oldProduct = widget.saleTransactionModel.productList!;
                        //
                        //             for (var p in widget.saleTransactionModel.productList!) {
                        //               if (returnList.any((element) => element.productId == p.productId)) {
                        //                 int index = returnList.indexWhere((element) => element.productId == p.productId);
                        //                 p.quantity = p.quantity - returnList[index].quantity;
                        //               }
                        //
                        //               if (p.quantity > 0) newProductList.add(p);
                        //             }
                        //
                        //             editedTransitionModel.productList = newProductList;
                        //             editedTransitionModel.totalAmount = (editedTransitionModel.totalAmount ?? 0) - (double.tryParse(getTotalReturnAmount().toString()) ?? 0);
                        //
                        //             // myTransitionModel.totalAmount = widget.newTransitionModel.totalAmount!.toDouble();
                        //             ///________________updateInvoice___________________________________________________________OK
                        //             String? key;
                        //             final userId = await getUserID();
                        //             await FirebaseDatabase.instance.ref(userId).child('Sales Transition').orderByKey().get().then((value) {
                        //               for (var element in value.children) {
                        //                 final t = SaleTransactionModel.fromJson(jsonDecode(jsonEncode(element.value)));
                        //                 if (editedTransitionModel.invoiceNumber == t.invoiceNumber) {
                        //                   key = element.key;
                        //                 }
                        //               }
                        //             });
                        //
                        //             if (newProductList.isEmpty) {
                        //               await FirebaseDatabase.instance.ref(userId).child('Sales Transition').child(key!).remove();
                        //             } else {
                        //               num totalQuantity = 0;
                        //               double lossProfit = 0;
                        //               double totalPurchasePrice = 0;
                        //               double totalSalePrice = 0;
                        //               for (var element in newProductList) {
                        //                 if (element.taxType == 'Exclusive') {
                        //                   double tax =
                        //                       calculateAmountFromPercentage(element.groupTaxRate.toDouble(), double.tryParse(element.productPurchasePrice.toString()) ?? 0);
                        //                   totalPurchasePrice = totalPurchasePrice + ((double.parse(element.productPurchasePrice.toString()) + tax) * element.quantity);
                        //                 } else {
                        //                   totalPurchasePrice = totalPurchasePrice + (double.parse(element.productPurchasePrice.toString()) * element.quantity);
                        //                 }
                        //
                        //                 totalSalePrice = totalSalePrice + (double.parse(element.subTotal.toString()) * element.quantity);
                        //
                        //                 totalQuantity = totalQuantity + element.quantity;
                        //               }
                        //               lossProfit = ((totalSalePrice - totalPurchasePrice.toDouble()) - double.parse(editedTransitionModel.discountAmount.toString()));
                        //               editedTransitionModel.totalQuantity = totalQuantity;
                        //               editedTransitionModel.lossProfit = lossProfit;
                        //
                        //               ///__________total LossProfit & quantity________________________________________________________________
                        //               // final postEditedTransitionModel = ShowEditPaymentPopUp.checkLossProfit(transitionModel: editedTransitionModel);
                        //               await FirebaseDatabase.instance.ref(userId).child('Sales Transition').child(key!).update(editedTransitionModel.toJson());
                        //             }
                        //             SaleTransactionModel invoice = SaleTransactionModel(
                        //               customerName: widget.saleTransactionModel.customerName,
                        //               customerType: widget.saleTransactionModel.customerType,
                        //               customerGst: widget.saleTransactionModel.customerGst,
                        //               customerPhone: widget.saleTransactionModel.customerPhone,
                        //               invoiceNumber: widget.saleTransactionModel.invoiceNumber,
                        //               purchaseDate: widget.saleTransactionModel.purchaseDate,
                        //               customerAddress: widget.saleTransactionModel.customerAddress,
                        //               customerImage: widget.saleTransactionModel.customerImage,
                        //               sendWhatsappMessage: widget.saleTransactionModel.sendWhatsappMessage ?? false,
                        //               productList: returnList,
                        //               totalAmount: double.tryParse(getTotalReturnAmount().toString()),
                        //               discountAmount: 0,
                        //               dueAmount: 0,
                        //               isPaid: false,
                        //               lossProfit: 0,
                        //               paymentType: 'Cash',
                        //               returnAmount: 0,
                        //               serviceCharge: 0,
                        //               vat: 0,
                        //               totalQuantity: 0,
                        //             );
                        //
                        //             await saleReturn(salesModel: invoice, orginal: widget.saleTransactionModel, consumerRef: ref, context: context);
                        //           }
                        //         },
                        //         child: Container(
                        //           padding: const EdgeInsets.all(10.0),
                        //           decoration: BoxDecoration(
                        //             shape: BoxShape.rectangle,
                        //             borderRadius: BorderRadius.circular(10.0),
                        //             color: kBlueTextColor,
                        //           ),
                        //           child: Text(
                        //             lang.S.of(context).conformReturn,
                        //             //'Conform Return',
                        //             textAlign: TextAlign.center,
                        //             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
