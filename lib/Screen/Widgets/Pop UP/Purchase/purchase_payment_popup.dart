// ignore_for_file: use_build_context_synchronously, unused_result

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../../PDF/print_pdf.dart';
import '../../../../Provider/customer_provider.dart';
import '../../../../Provider/daily_transaction_provider.dart';
import '../../../../Provider/due_transaction_provider.dart';
import '../../../../Provider/general_setting_provider.dart';
import '../../../../Provider/product_provider.dart';
import '../../../../Provider/profile_provider.dart';
import '../../../../Provider/transactions_provider.dart';
import '../../../../const.dart';
import '../../../../model/daily_transaction_model.dart';
import '../../../../model/purchase_transation_model.dart';
import '../../../../subscription.dart';
import '../../../currency/currency_provider.dart';
import '../../Constant Data/constant.dart';

class PurchaseShowPaymentPopUp extends StatefulWidget {
  const PurchaseShowPaymentPopUp({super.key, required this.transitionModel});
  final PurchaseTransactionModel transitionModel;

  @override
  State<PurchaseShowPaymentPopUp> createState() => _PurchaseShowPaymentPopUpState();
}

class _PurchaseShowPaymentPopUpState extends State<PurchaseShowPaymentPopUp> {
  List<String> paymentItem = ['Cash', 'Bank', 'Mobile Pay'];
  String selectedPaymentOption = 'Cash';

  bool saleButtonClicked = false;

  String getTotalAmount() {
    double total = 0.0;
    for (var item in widget.transitionModel.productList!) {
      total = total + (double.parse(item.productPurchasePrice) * item.productStock.toInt());
    }
    return total.toStringAsFixed(2);
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

  double dueAmount = 0.0;
  double returnAmount = 0.0;

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      payingAmountController.text = '0';
      double paidAmount = double.parse(payingAmountController.text);
      if (paidAmount > widget.transitionModel.totalAmount!.toDouble()) {
        changeAmountController.text = (paidAmount - widget.transitionModel.totalAmount!.toDouble()).toString();
        dueAmountController.text = '0';
      } else {
        dueAmountController.text = (widget.transitionModel.totalAmount!.toDouble() - paidAmount).abs().toString();
        changeAmountController.text = '0';
      }
    });
  }

  final ScrollController mainSideScroller = ScrollController();
  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, consumerRef, __) {
        final settingProvider = consumerRef.watch(generalSettingProvider);
        final personalData = consumerRef.watch(profileDetailsProvider);
        return personalData.when(data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        lang.S.of(context).createPayment,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: kTitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {
                            finish(context),
                          })
                    ],
                  ),
                ),
                const Divider(thickness: 1.0, color: kLitGreyColor),
                const SizedBox(height: 10.0),
                ResponsiveGridRow(children: [
                  //---------------calculation section------------------------
                  ResponsiveGridCol(
                    xs: 12,
                    md: screenWidth < 700 ? 12 : 6,
                    lg: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: kWhite,
                          border: Border.all(color: kNeutral300),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                lg: 6,
                                md: 6,
                                child: Text(
                                  lang.S.of(context).payingAmount,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              ResponsiveGridCol(
                                  xs: 12,
                                  lg: 6,
                                  md: 6,
                                  child: TextFormField(
                                    controller: payingAmountController,
                                    onChanged: (value) {
                                      setState(() {
                                        double paidAmount = double.parse(value);
                                        if (paidAmount > widget.transitionModel.totalAmount!.toDouble()) {
                                          changeAmountController.text = (paidAmount - widget.transitionModel.totalAmount!.toDouble()).toString();
                                          dueAmountController.text = '0';
                                        } else {
                                          dueAmountController.text = (widget.transitionModel.totalAmount!.toDouble() - paidAmount).abs().toString();
                                          changeAmountController.text = '0';
                                        }
                                      });
                                    },
                                    showCursor: true,
                                    cursorColor: kTitleColor,
                                    keyboardType: TextInputType.name,
                                    decoration: InputDecoration(
                                      hintText: lang.S.of(context).enterPaidAmount,
                                    ),
                                  ))
                            ]),
                            const SizedBox(height: 10.0),
                            ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                lg: 6,
                                md: 6,
                                child: Text(
                                  lang.S.of(context).changeAmount,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              ResponsiveGridCol(
                                  xs: 12,
                                  lg: 6,
                                  md: 6,
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: changeAmountController,
                                    cursorColor: kTitleColor,
                                    keyboardType: TextInputType.name,
                                    decoration: InputDecoration(
                                      hintText: lang.S.of(context).changeAmount,
                                    ),
                                  ))
                            ]),
                            const SizedBox(height: 10.0),
                            ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                lg: 6,
                                md: 6,
                                child: Text(
                                  lang.S.of(context).dueAmount,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              ResponsiveGridCol(
                                  xs: 12,
                                  lg: 6,
                                  md: 6,
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: dueAmountController,
                                    cursorColor: kTitleColor,
                                    keyboardType: TextInputType.name,
                                    decoration: InputDecoration(
                                      hintText: lang.S.of(context).dueAmount,
                                    ),
                                  ))
                            ]),
                            const SizedBox(height: 10.0),
                            ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                lg: 6,
                                md: 6,
                                child: Text(
                                  lang.S.of(context).paymentType,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              ResponsiveGridCol(
                                  xs: 12,
                                  lg: 6,
                                  md: 6,
                                  child: SizedBox(
                                    height: 48,
                                    child: FormField(
                                      builder: (FormFieldState<dynamic> field) {
                                        return InputDecorator(
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.only(left: 12.0, right: 10.0, top: 7.0, bottom: 7.0),
                                            floatingLabelBehavior: FloatingLabelBehavior.never,
                                          ),
                                          child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getOption())),
                                        );
                                      },
                                    ),
                                  ))
                            ]),
                            // Row(
                            //   children: [
                            //     SizedBox(
                            //       width: 200,
                            //       child: Text(
                            //         lang.S.of(context).paymentType,
                            //         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                            //       ),
                            //     ),
                            //     const Spacer(),
                            //     SizedBox(
                            //       width: context.width() < 750 ? 170 : context.width() * 0.22,
                            //       child: FormField(
                            //         builder: (FormFieldState<dynamic> field) {
                            //           return InputDecorator(
                            //             decoration: const InputDecoration(
                            //                 enabledBorder: OutlineInputBorder(
                            //                   borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            //                   borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                            //                 ),
                            //                 contentPadding: EdgeInsets.only(left: 12.0, right: 10.0, top: 7.0, bottom: 7.0),
                            //                 floatingLabelBehavior: FloatingLabelBehavior.never),
                            //             child: Theme(
                            //                 data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                            //                 child: DropdownButtonHideUnderline(child: getOption())),
                            //           );
                            //         },
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            const SizedBox(height: 20.0),
                            ResponsiveGridRow(children: [
                              ResponsiveGridCol(
                                xs: 6,
                                lg: 6,
                                md: 6,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () => {finish(context)},
                                      child: Text(
                                        lang.S.of(context).cancel,
                                      )).onTap(() => {finish(context)}),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 6,
                                lg: 6,
                                md: 6,
                                child: settingProvider.when(data: (setting) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: saleButtonClicked
                                          ? () {}
                                          : () async {
                                              if (widget.transitionModel.customerType == "Guest" && dueAmountController.text.toDouble() > 0) {
                                                EasyLoading.showError('Due is not available For Guest');
                                              } else {
                                                try {
                                                  setState(() {
                                                    saleButtonClicked = true;
                                                  });
                                                  EasyLoading.show(status: 'Loading...', dismissOnTap: false);

                                                  final userId = await getUserID();
                                                  DatabaseReference ref = FirebaseDatabase.instance.ref("$userId/Purchase Transition");

                                                  dueAmountController.text.toDouble() <= 0 ? widget.transitionModel.isPaid = true : widget.transitionModel.isPaid = false;
                                                  dueAmountController.text.toDouble() <= 0 ? widget.transitionModel.dueAmount = 0 : widget.transitionModel.dueAmount = dueAmountController.text.toDouble();
                                                  changeAmountController.text.toDouble() > 0 ? widget.transitionModel.returnAmount = changeAmountController.text.toDouble().abs() : widget.transitionModel.returnAmount = 0;
                                                  widget.transitionModel.totalAmount = widget.transitionModel.totalAmount!.toDouble();
                                                  widget.transitionModel.paymentType = selectedPaymentOption;

                                                  await ref.push().set(widget.transitionModel.toJson());

                                                  ///__________StockMange_________________________________________________
                                                  final stockRef = FirebaseDatabase.instance.ref('$userId/Products/');
                                                  for (var element in widget.transitionModel.productList!) {
                                                    var data = await stockRef.orderByChild('productCode').equalTo(element.productCode).once();
                                                    final data2 = jsonDecode(jsonEncode(data.snapshot.value));
                                                    String productPath = data.snapshot.value.toString().substring(1, 21);

                                                    var data1 = await stockRef.child('$productPath/productStock').get();
                                                    int stock = int.parse(data1.value.toString());
                                                    int remainStock = stock + element.productStock.toInt();

                                                    stockRef.child(productPath).update({
                                                      'productStock': '$remainStock',
                                                      'productSalePrice': element.productSalePrice,
                                                      'productPurchasePrice': element.productPurchasePrice,
                                                      'productDealerPrice': element.productDealerPrice,
                                                      'productWholeSalePrice': element.productWholeSalePrice,
                                                    });

                                                    ///________daily_transactionModel_________________________________________________________________________

                                                    DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                                      name: widget.transitionModel.customerName,
                                                      date: widget.transitionModel.purchaseDate,
                                                      type: 'Purchase',
                                                      total: widget.transitionModel.totalAmount!.toDouble(),
                                                      paymentIn: 0,
                                                      paymentOut: widget.transitionModel.totalAmount!.toDouble() - widget.transitionModel.dueAmount!.toDouble(),
                                                      remainingBalance: widget.transitionModel.totalAmount!.toDouble() - widget.transitionModel.dueAmount!.toDouble(),
                                                      id: widget.transitionModel.invoiceNumber,
                                                      purchaseTransactionModel: widget.transitionModel,
                                                    );
                                                    postDailyTransaction(dailyTransactionModel: dailyTransaction);

                                                    ///________Update_Serial_Number____________________________________________________

                                                    if (element.serialNumber.isNotEmpty) {
                                                      var productOldSerialList = data2[productPath]['serialNumber'] ?? [];

                                                      List<dynamic> result = productOldSerialList + element.serialNumber;
                                                      stockRef.child(productPath).update({
                                                        'serialNumber': result.map((e) => e).toList(),
                                                      });
                                                    }
                                                  }

                                                  ///_________Invoice Increase______________________________________________________
                                                  updateInvoice(typeOfInvoice: 'purchaseInvoiceCounter', invoice: widget.transitionModel.invoiceNumber.toInt());

                                                  ///________Subscription____________________________________________________________
                                                  Subscription.decreaseSubscriptionLimits(itemType: 'purchaseNumber', context: context);

                                                  ///_________DueUpdate___________________________________________________________________________________
                                                  if (widget.transitionModel.customerName != 'Guest') {
                                                    final dueUpdateRef = FirebaseDatabase.instance.ref('$userId/Customers/');
                                                    String? key;

                                                    await FirebaseDatabase.instance.ref(userId).child('Customers').orderByKey().get().then((value) {
                                                      for (var element in value.children) {
                                                        var data = jsonDecode(jsonEncode(element.value));
                                                        if (data['phoneNumber'] == widget.transitionModel.customerPhone) {
                                                          key = element.key;
                                                        }
                                                      }
                                                    });
                                                    var data1 = await dueUpdateRef.child('$key/due').get();
                                                    int previousDue = data1.value.toString().toInt();

                                                    int totalDue = previousDue + widget.transitionModel.dueAmount!.toInt();
                                                    dueUpdateRef.child(key!).update({'due': '$totalDue'});
                                                  }

                                                  ///________update_all_provider___________________________________________________
                                                  consumerRef.refresh(allCustomerProvider);
                                                  consumerRef.refresh(transitionProvider);
                                                  consumerRef.refresh(productProvider);
                                                  consumerRef.refresh(purchaseTransitionProvider);
                                                  consumerRef.refresh(dueTransactionProvider);
                                                  consumerRef.refresh(profileDetailsProvider);
                                                  consumerRef.refresh(dailyTransactionProvider);

                                                  EasyLoading.showSuccess('Purchase Successfully Done');

                                                  await GeneratePdfAndPrint().printPurchaseInvoice(setting: setting, personalInformationModel: data, purchaseTransactionModel: widget.transitionModel, context: context);
                                                  // context.pop();
                                                  // // ignore: use_build_context_synchronously
                                                  // PurchaseInvoice(
                                                  //   transitionModel: widget.transitionModel,
                                                  //   personalInformationModel: data,
                                                  //   isPurchase: true,
                                                  // ).launch(context);
                                                } catch (e) {
                                                  setState(() {
                                                    saleButtonClicked = false;
                                                  });
                                                  EasyLoading.dismiss();
                                                  //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                }
                                              }
                                            },
                                      child: Text(
                                        lang.S.of(context).submit,
                                        style: kTextStyle.copyWith(color: kWhite),
                                      ),
                                    ),
                                  );
                                }, error: (e, stack) {
                                  return Text(e.toString());
                                }, loading: () {
                                  return Center(child: CircularProgressIndicator());
                                }),
                              )
                            ]),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     Container(
                            //         padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                            //         decoration: BoxDecoration(
                            //           borderRadius: BorderRadius.circular(5.0),
                            //           color: kRedTextColor,
                            //         ),
                            //         child: Text(
                            //           lang.S.of(context).cancel,
                            //           style: kTextStyle.copyWith(color: kWhite),
                            //         )).onTap(() => {finish(context)}),
                            //     const SizedBox(width: 40.0),
                            //     Container(
                            //       padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                            //       decoration: BoxDecoration(
                            //         borderRadius: BorderRadius.circular(5.0),
                            //         color: kBlueTextColor,
                            //       ),
                            //       child: Text(
                            //         lang.S.of(context).submit,
                            //         style: kTextStyle.copyWith(color: kWhite),
                            //       ),
                            //     ).onTap(
                            //       saleButtonClicked
                            //           ? () {}
                            //           : () async {
                            //               if (widget.transitionModel.customerType == "Guest" && dueAmountController.text.toDouble() > 0) {
                            //                 EasyLoading.showError('Due is not available For Guest');
                            //               } else {
                            //                 try {
                            //                   setState(() {
                            //                     saleButtonClicked = true;
                            //                   });
                            //                   EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                            //
                            //                   final userId = await getUserID();
                            //                   DatabaseReference ref = FirebaseDatabase.instance.ref("$userId/Purchase Transition");
                            //
                            //                   dueAmountController.text.toDouble() <= 0 ? widget.transitionModel.isPaid = true : widget.transitionModel.isPaid = false;
                            //                   dueAmountController.text.toDouble() <= 0
                            //                       ? widget.transitionModel.dueAmount = 0
                            //                       : widget.transitionModel.dueAmount = dueAmountController.text.toDouble();
                            //                   changeAmountController.text.toDouble() > 0
                            //                       ? widget.transitionModel.returnAmount = changeAmountController.text.toDouble().abs()
                            //                       : widget.transitionModel.returnAmount = 0;
                            //                   widget.transitionModel.totalAmount = widget.transitionModel.totalAmount!.toDouble();
                            //                   widget.transitionModel.paymentType = selectedPaymentOption;
                            //
                            //                   await ref.push().set(widget.transitionModel.toJson());
                            //
                            //                   ///__________StockMange_________________________________________________
                            //                   final stockRef = FirebaseDatabase.instance.ref('$userId/Products/');
                            //                   for (var element in widget.transitionModel.productList!) {
                            //                     var data = await stockRef.orderByChild('productCode').equalTo(element.productCode).once();
                            //                     final data2 = jsonDecode(jsonEncode(data.snapshot.value));
                            //                     String productPath = data.snapshot.value.toString().substring(1, 21);
                            //
                            //                     var data1 = await stockRef.child('$productPath/productStock').get();
                            //                     int stock = int.parse(data1.value.toString());
                            //                     int remainStock = stock + element.productStock.toInt();
                            //
                            //                     stockRef.child(productPath).update({
                            //                       'productStock': '$remainStock',
                            //                       'productSalePrice': element.productSalePrice,
                            //                       'productPurchasePrice': element.productPurchasePrice,
                            //                       'productDealerPrice': element.productDealerPrice,
                            //                       'productWholeSalePrice': element.productWholeSalePrice,
                            //                     });
                            //
                            //                     ///________daily_transactionModel_________________________________________________________________________
                            //
                            //                     DailyTransactionModel dailyTransaction = DailyTransactionModel(
                            //                       name: widget.transitionModel.customerName,
                            //                       date: widget.transitionModel.purchaseDate,
                            //                       type: 'Purchase',
                            //                       total: widget.transitionModel.totalAmount!.toDouble(),
                            //                       paymentIn: 0,
                            //                       paymentOut: widget.transitionModel.totalAmount!.toDouble() - widget.transitionModel.dueAmount!.toDouble(),
                            //                       remainingBalance: widget.transitionModel.totalAmount!.toDouble() - widget.transitionModel.dueAmount!.toDouble(),
                            //                       id: widget.transitionModel.invoiceNumber,
                            //                       purchaseTransactionModel: widget.transitionModel,
                            //                     );
                            //                     postDailyTransaction(dailyTransactionModel: dailyTransaction);
                            //
                            //                     ///________Update_Serial_Number____________________________________________________
                            //
                            //                     if (element.serialNumber.isNotEmpty) {
                            //                       var productOldSerialList = data2[productPath]['serialNumber'] ?? [];
                            //
                            //                       List<dynamic> result = productOldSerialList + element.serialNumber;
                            //                       stockRef.child(productPath).update({
                            //                         'serialNumber': result.map((e) => e).toList(),
                            //                       });
                            //                     }
                            //                   }
                            //
                            //                   ///_________Invoice Increase______________________________________________________
                            //                   updateInvoice(typeOfInvoice: 'purchaseInvoiceCounter', invoice: widget.transitionModel.invoiceNumber.toInt());
                            //
                            //                   ///________Subscription____________________________________________________________
                            //                   Subscription.decreaseSubscriptionLimits(itemType: 'purchaseNumber', context: context);
                            //
                            //                   ///_________DueUpdate___________________________________________________________________________________
                            //                   if (widget.transitionModel.customerName != 'Guest') {
                            //                     final dueUpdateRef = FirebaseDatabase.instance.ref('$userId/Customers/');
                            //                     String? key;
                            //
                            //                     await FirebaseDatabase.instance.ref(userId).child('Customers').orderByKey().get().then((value) {
                            //                       for (var element in value.children) {
                            //                         var data = jsonDecode(jsonEncode(element.value));
                            //                         if (data['phoneNumber'] == widget.transitionModel.customerPhone) {
                            //                           key = element.key;
                            //                         }
                            //                       }
                            //                     });
                            //                     var data1 = await dueUpdateRef.child('$key/due').get();
                            //                     int previousDue = data1.value.toString().toInt();
                            //
                            //                     int totalDue = previousDue + widget.transitionModel.dueAmount!.toInt();
                            //                     dueUpdateRef.child(key!).update({'due': '$totalDue'});
                            //                   }
                            //
                            //                   ///________update_all_provider___________________________________________________
                            //                   consumerRef.refresh(allCustomerProvider);
                            //                   consumerRef.refresh(transitionProvider);
                            //                   consumerRef.refresh(productProvider);
                            //                   consumerRef.refresh(purchaseTransitionProvider);
                            //                   consumerRef.refresh(dueTransactionProvider);
                            //                   consumerRef.refresh(profileDetailsProvider);
                            //                   consumerRef.refresh(dailyTransactionProvider);
                            //
                            //                   EasyLoading.showSuccess('Purchase Successfully Done');
                            //
                            //                   await GeneratePdfAndPrint()
                            //                       .printPurchaseInvoice(personalInformationModel: data, purchaseTransactionModel: widget.transitionModel, context: context);
                            //                   // context.pop();
                            //                   // // ignore: use_build_context_synchronously
                            //                   // PurchaseInvoice(
                            //                   //   transitionModel: widget.transitionModel,
                            //                   //   personalInformationModel: data,
                            //                   //   isPurchase: true,
                            //                   // ).launch(context);
                            //                 } catch (e) {
                            //                   setState(() {
                            //                     saleButtonClicked = false;
                            //                   });
                            //                   EasyLoading.dismiss();
                            //                   //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            //                 }
                            //               }
                            //             },
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  //--------------price section----------------------
                  ResponsiveGridCol(
                      xs: 12,
                      md: screenWidth < 700 ? 12 : 6,
                      lg: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            ///______________total_product_______________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: kNeutral300),
                                borderRadius: BorderRadius.only(topLeft: radiusCircular(5.0), topRight: radiusCircular(5.0)),
                                color: kWhite,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).totalProduct,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${widget.transitionModel.productList?.length}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///______________total_Amount_______________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                color: kWhite,
                                border: Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).totalAmount,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${myFormat.format(double.tryParse(getTotalAmount()) ?? 0)}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///___________discount_______________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                color: kWhite,
                                border: Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).discount,
                                    // 'Discount',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${myFormat.format(double.tryParse(widget.transitionModel.discountAmount!.toStringAsFixed(2)) ?? 0)}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///______________grand_total___________________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(bottomLeft: radiusCircular(5.0), bottomRight: radiusCircular(5.0)),
                                color: kbgColor,
                                border: Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).grandTotal,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${myFormat.format(double.tryParse(widget.transitionModel.totalAmount!.toStringAsFixed(2)) ?? 0)}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(height: 20.0),
                          ],
                        ),
                      )),
                ]),
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
      },
    );
  }

  void getSpecificCustomers({required String phoneNumber, required int due}) async {
    final userId = await getUserID();
    final ref = FirebaseDatabase.instance.ref('$userId/Customers/');
    String? key;

    await FirebaseDatabase.instance.ref(userId).child('Customers').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['phoneNumber'] == phoneNumber) {
          key = element.key;
        }
      }
    });
    var data1 = await ref.child('$key/due').get();
    int previousDue = data1.value.toString().toInt();

    int totalDue = previousDue + due;
    ref.child(key!).update({'due': '$totalDue'});
  }

  void decreaseStock(String productCode, int quantity) async {
    final ref = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');

    var data = await ref.orderByChild('productCode').equalTo(productCode).once();
    String productPath = data.snapshot.value.toString().substring(1, 21);

    var data1 = await ref.child('$productPath/productStock').get();
    int stock = int.parse(data1.value.toString());
    int remainStock = stock - quantity;

    ref.child(productPath).update({'productStock': '$remainStock'});
  }
}
