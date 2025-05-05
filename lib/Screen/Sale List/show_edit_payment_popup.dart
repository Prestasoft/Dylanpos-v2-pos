import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/product_model.dart';

import '../../Provider/customer_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

// ignore: must_be_immutable
class ShowEditPaymentPopUp extends StatefulWidget {
  ShowEditPaymentPopUp(
      {super.key,
      required this.newTransitionModel,
      required this.previousPaid,
      required this.oldTransitionModel,
      required this.pastProducts,
      required this.decreaseStockList,
      required this.saleListPopUpContext});
  final SaleTransactionModel newTransitionModel;
  final SaleTransactionModel oldTransitionModel;
  final double previousPaid;
  List<AddToCartModel> pastProducts;
  List<AddToCartModel> decreaseStockList;
  BuildContext saleListPopUpContext;

  @override
  State<ShowEditPaymentPopUp> createState() => _ShowEditPaymentPopUpState();
}

class _ShowEditPaymentPopUpState extends State<ShowEditPaymentPopUp> {
  List<String> get paymentItem => [
        //'Cash',
        lang.S.current.cash,
        //'Bank',
        lang.S.current.bank,
        //'Mobile Pay'
        lang.S.current.mobilePay,
      ];
  late String selectedPaymentOption = paymentItem.first;

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

  String getTotalAmount() {
    double total = 0.0;
    for (var item in widget.newTransitionModel.productList!) {
      total = total + (double.parse(item.subTotal) * item.quantity);
    }
    return total.toString();
  }

  double dueAmount = 0.0;
  double returnAmount = 0.0;

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();

  bool isGuestCustomer = false;

  late SaleTransactionModel myTransitionModel;
  double pastDue = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    pastDue = widget.oldTransitionModel.dueAmount!.toDouble();

    payingAmountController.text = widget.previousPaid.toString();
    double paidAmount = widget.previousPaid;
    if (paidAmount > widget.newTransitionModel.totalAmount!.toDouble()) {
      changeAmountController.text =
          (paidAmount - widget.newTransitionModel.totalAmount!.toDouble())
              .toString();
      dueAmountController.text = '0';
      dueAmount = 0;
    } else {
      dueAmount =
          (widget.newTransitionModel.totalAmount!.toDouble() - paidAmount)
              .abs();
      dueAmountController.text = dueAmount.toString();

      changeAmountController.text = '0';
    }
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
        final personalData = consumerRef.watch(profileDetailsProvider);
        final settingProvider = consumerRef.watch(generalSettingProvider);
        return personalData.when(data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
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
                      const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0)
                          .onTap(() => {
                                finish(context),
                              })
                    ],
                  ),
                ),
                const Divider(thickness: 1.0, color: kLitGreyColor),
                const SizedBox(height: 10.0),
                ResponsiveGridRow(children: [
                  ResponsiveGridCol(
                      xs: 12,
                      md: screenWidth < 700 ? 12 : 6,
                      lg: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color: kWhite,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //--------------paying amount--------------------
                              ResponsiveGridRow(children: [
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
                                          double paidAmount =
                                              double.parse(value);
                                          if (paidAmount >
                                              widget.newTransitionModel
                                                  .totalAmount!
                                                  .toDouble()) {
                                            changeAmountController.text =
                                                (paidAmount -
                                                        widget
                                                            .newTransitionModel
                                                            .totalAmount!
                                                            .toDouble())
                                                    .toString();
                                            dueAmountController.text = '0';
                                            dueAmount = 0;
                                          } else {
                                            dueAmount = (widget
                                                        .newTransitionModel
                                                        .totalAmount!
                                                        .toDouble() -
                                                    paidAmount)
                                                .abs();
                                            dueAmountController.text = (widget
                                                        .newTransitionModel
                                                        .totalAmount!
                                                        .toDouble() -
                                                    paidAmount)
                                                .abs()
                                                .toString();
                                            changeAmountController.text = '0';
                                          }
                                        });
                                      },
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      decoration: kInputDecoration.copyWith(
                                        hintText:
                                            lang.S.of(context).enterPaidAmount,
                                        hintStyle: kTextStyle.copyWith(
                                            color: kGreyTextColor),
                                      ),
                                    )),
                              ]),
                              const SizedBox(height: 10.0),
                              //-------------------change amount----------------
                              ResponsiveGridRow(children: [
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
                                    child: AppTextField(
                                      readOnly: true,
                                      controller: changeAmountController,
                                      cursorColor: kTitleColor,
                                      textFieldType: TextFieldType.NAME,
                                      decoration: kInputDecoration.copyWith(
                                        hintText:
                                            lang.S.of(context).changeAmount,
                                        hintStyle: kTextStyle.copyWith(
                                            color: kGreyTextColor),
                                      ),
                                    )),
                              ]),
                              // Row(
                              //   children: [
                              //     SizedBox(
                              //       width: 200,
                              //       child: Text(
                              //         lang.S.of(context).changeAmount,
                              //         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                              //       ),
                              //     ),
                              //     const Spacer(),
                              //     SizedBox(
                              //       width: context.width() < 750 ? 170 : context.width() * 0.22,
                              //       child: AppTextField(
                              //         readOnly: true,
                              //         controller: changeAmountController,
                              //         cursorColor: kTitleColor,
                              //         textFieldType: TextFieldType.NAME,
                              //         decoration: kInputDecoration.copyWith(
                              //           hintText: lang.S.of(context).changeAmount,
                              //           hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              const SizedBox(height: 10.0),
                              //----------------due amount---------------------------
                              ResponsiveGridRow(children: [
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
                                    child: AppTextField(
                                      readOnly: true,
                                      controller: dueAmountController,
                                      cursorColor: kTitleColor,
                                      textFieldType: TextFieldType.NAME,
                                      decoration: kInputDecoration.copyWith(
                                        hintText: lang.S.of(context).dueAmount,
                                        hintStyle: kTextStyle.copyWith(
                                            color: kGreyTextColor),
                                      ),
                                    )),
                              ]),
                              // Row(
                              //   children: [
                              //     SizedBox(
                              //       width: 200,
                              //       child: Text(
                              //         lang.S.of(context).dueAmount,
                              //         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                              //       ),
                              //     ),
                              //     const Spacer(),
                              //     SizedBox(
                              //       width: context.width() < 750 ? 170 : context.width() * 0.22,
                              //       child: AppTextField(
                              //         readOnly: true,
                              //         controller: dueAmountController,
                              //         cursorColor: kTitleColor,
                              //         textFieldType: TextFieldType.NAME,
                              //         decoration: kInputDecoration.copyWith(
                              //           hintText: lang.S.of(context).dueAmount,
                              //           hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              const SizedBox(height: 10.0),
                              //------------payment type----------------------
                              ResponsiveGridRow(children: [
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
                                        builder:
                                            (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.only(
                                                  left: 12.0,
                                                  right: 10.0,
                                                  top: 7.0,
                                                  bottom: 7.0),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                                child: getOption()),
                                          );
                                        },
                                      ),
                                    )),
                              ]),
                              const SizedBox(height: 20.0),
                              ResponsiveGridRow(children: [
                                //-------------cancel button-----------------
                                ResponsiveGridCol(
                                    xs: 12,
                                    lg: 6,
                                    md: 6,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: screenWidth > 577 ? 20 : 0,
                                          bottom: screenWidth < 577 ? 10 : 0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          // context.pop();
                                          GoRouter.of(context).pop();
                                        },
                                        child: Text(
                                          lang.S.of(context).cancel,
                                        ),
                                      ),
                                    )),
                                // -------------submit button----------

                                ResponsiveGridCol(
                                  xs: 12,
                                  lg: 6,
                                  md: 6,
                                  child: settingProvider.when(data: (setting) {
                                    return ElevatedButton(
                                      onPressed: () async {
                                        if (widget.newTransitionModel
                                            .productList!.isNotEmpty) {
                                          if (isGuestCustomer &&
                                              dueAmount > 0) {
                                            EasyLoading.showError(lang.S
                                                .of(context)
                                                .dueIsNotForGuestCustomer);
                                          } else {
                                            try {
                                              EasyLoading.show(
                                                  status:
                                                      '${lang.S.of(context).loading}...',
                                                  dismissOnTap: false);
                                              myTransitionModel =
                                                  widget.newTransitionModel;
                                              final userId = await getUserID();

                                              dueAmountController.text
                                                          .toDouble() <=
                                                      0
                                                  ? myTransitionModel.isPaid =
                                                      true
                                                  : myTransitionModel.isPaid =
                                                      false;
                                              dueAmountController.text
                                                          .toDouble() <=
                                                      0
                                                  ? myTransitionModel
                                                      .dueAmount = 0
                                                  : myTransitionModel
                                                      .dueAmount = dueAmount;
                                              returnAmount < 0
                                                  ? myTransitionModel
                                                          .returnAmount =
                                                      returnAmount.abs()
                                                  : myTransitionModel
                                                      .returnAmount = 0;
                                              myTransitionModel.productList =
                                                  widget.newTransitionModel
                                                      .productList;

                                              myTransitionModel.totalAmount =
                                                  widget.newTransitionModel
                                                      .totalAmount!
                                                      .toDouble();
                                              myTransitionModel.paymentType =
                                                  selectedPaymentOption;
                                              myTransitionModel.productList =
                                                  widget.newTransitionModel
                                                      .productList;

                                              ///__________total LossProfit & quantity________________________________________________________________
                                              myTransitionModel =
                                                  checkLossProfit(
                                                      transitionModel: widget
                                                          .newTransitionModel);

                                              ///__________updateInvoice_______________________________________
                                              String? key;
                                              await FirebaseDatabase.instance
                                                  .ref(userId)
                                                  .child('Sales Transition')
                                                  .orderByKey()
                                                  .get()
                                                  .then((value) {
                                                for (var element
                                                    in value.children) {
                                                  final t = SaleTransactionModel
                                                      .fromJson(jsonDecode(
                                                          jsonEncode(
                                                              element.value)));
                                                  if (myTransitionModel
                                                          .invoiceNumber ==
                                                      t.invoiceNumber) {
                                                    key = element.key;
                                                  }
                                                }
                                              });
                                              await FirebaseDatabase.instance
                                                  .ref(userId)
                                                  .child('Sales Transition')
                                                  .child(key!)
                                                  .update(myTransitionModel
                                                      .toJson());

                                              ///__________StockMange________________________________________________
                                              List<AddToCartModel>
                                                  presentProducts = widget
                                                      .newTransitionModel
                                                      .productList!;

                                              List<AddToCartModel>
                                                  increaseStockList = [];
                                              for (var pastElement
                                                  in widget.pastProducts) {
                                                int i = 0;
                                                for (var futureElement
                                                    in presentProducts) {
                                                  if (pastElement.productId ==
                                                      futureElement.productId) {
                                                    if (pastElement.quantity <
                                                            futureElement
                                                                .quantity &&
                                                        pastElement.quantity !=
                                                            futureElement
                                                                .quantity) {
                                                      widget.decreaseStockList
                                                              .contains(
                                                                  pastElement
                                                                      .productId)
                                                          ? null
                                                          : widget
                                                              .decreaseStockList
                                                              .add(
                                                              AddToCartModel(
                                                                productName:
                                                                    pastElement
                                                                        .productName,
                                                                warehouseName:
                                                                    pastElement
                                                                        .warehouseName,
                                                                warehouseId:
                                                                    pastElement
                                                                        .warehouseId,
                                                                productId:
                                                                    pastElement
                                                                        .productId,
                                                                productImage:
                                                                    pastElement
                                                                        .productImage,
                                                                quantity: futureElement
                                                                        .quantity
                                                                        .toInt() -
                                                                    pastElement
                                                                        .quantity
                                                                        .toInt(),
                                                                serialNumber:
                                                                    pastElement
                                                                        .serialNumber,
                                                                productPurchasePrice:
                                                                    pastElement
                                                                        .productPurchasePrice,
                                                                subTaxes:
                                                                    pastElement
                                                                        .subTaxes,
                                                                excTax:
                                                                    pastElement
                                                                        .excTax,
                                                                groupTaxName:
                                                                    pastElement
                                                                        .groupTaxName,
                                                                groupTaxRate:
                                                                    pastElement
                                                                        .groupTaxRate,
                                                                incTax:
                                                                    pastElement
                                                                        .incTax,
                                                                margin:
                                                                    pastElement
                                                                        .margin,
                                                                taxType:
                                                                    pastElement
                                                                        .taxType,
                                                              ),
                                                            );
                                                    } else if (pastElement
                                                                .quantity >
                                                            futureElement
                                                                .quantity &&
                                                        pastElement.quantity !=
                                                            futureElement
                                                                .quantity) {
                                                      increaseStockList.contains(
                                                              pastElement
                                                                  .productId)
                                                          ? null
                                                          : increaseStockList
                                                              .add(
                                                              AddToCartModel(
                                                                productName:
                                                                    pastElement
                                                                        .productName,
                                                                warehouseName:
                                                                    pastElement
                                                                        .warehouseName,
                                                                warehouseId:
                                                                    pastElement
                                                                        .warehouseId,
                                                                productId:
                                                                    pastElement
                                                                        .productId,
                                                                productImage:
                                                                    pastElement
                                                                        .productImage,
                                                                quantity: pastElement
                                                                        .quantity -
                                                                    futureElement
                                                                        .quantity,
                                                                serialNumber: pastElement
                                                                            .serialNumber !=
                                                                        []
                                                                    ? futureElement.quantity <
                                                                            pastElement
                                                                                .serialNumber!.length
                                                                        ? pastElement.serialNumber!.sublist(
                                                                            0,
                                                                            futureElement.quantity.round() +
                                                                                1)
                                                                        : pastElement
                                                                            .serialNumber
                                                                    : [],
                                                                productPurchasePrice:
                                                                    pastElement
                                                                        .productPurchasePrice,
                                                                subTaxes:
                                                                    pastElement
                                                                        .subTaxes,
                                                                excTax:
                                                                    pastElement
                                                                        .excTax,
                                                                groupTaxName:
                                                                    pastElement
                                                                        .groupTaxName,
                                                                groupTaxRate:
                                                                    pastElement
                                                                        .groupTaxRate,
                                                                incTax:
                                                                    pastElement
                                                                        .incTax,
                                                                margin:
                                                                    pastElement
                                                                        .margin,
                                                                taxType:
                                                                    pastElement
                                                                        .taxType,
                                                              ),
                                                            );
                                                    }
                                                    break;
                                                  } else {
                                                    i++;
                                                    if (i ==
                                                        presentProducts
                                                            .length) {
                                                      increaseStockList.add(
                                                        AddToCartModel(
                                                          productName:
                                                              pastElement
                                                                  .productName,
                                                          warehouseName:
                                                              pastElement
                                                                  .warehouseName,
                                                          warehouseId:
                                                              pastElement
                                                                  .warehouseId,
                                                          productId: pastElement
                                                              .productId,
                                                          productImage:
                                                              pastElement
                                                                  .productImage,
                                                          quantity: pastElement
                                                              .quantity,
                                                          serialNumber:
                                                              pastElement
                                                                  .serialNumber,
                                                          productPurchasePrice:
                                                              pastElement
                                                                  .productPurchasePrice,
                                                          subTaxes: pastElement
                                                              .subTaxes,
                                                          excTax: pastElement
                                                              .excTax,
                                                          groupTaxName:
                                                              pastElement
                                                                  .groupTaxName,
                                                          groupTaxRate:
                                                              pastElement
                                                                  .groupTaxRate,
                                                          incTax: pastElement
                                                              .incTax,
                                                          margin: pastElement
                                                              .margin,
                                                          taxType: pastElement
                                                              .taxType,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }
                                              }
                                              for (var element
                                                  in widget.decreaseStockList) {
                                                final ref = FirebaseDatabase
                                                    .instance
                                                    .ref(
                                                        '${await getUserID()}/Products/');

                                                var data = await ref
                                                    .orderByChild('productCode')
                                                    .equalTo(element.productId)
                                                    .once();
                                                String productPath = data
                                                    .snapshot.value
                                                    .toString()
                                                    .substring(1, 21);

                                                var data1 = await ref
                                                    .child(
                                                        '$productPath/productStock')
                                                    .get();
                                                int stock = int.parse(
                                                    data1.value.toString());
                                                int remainStock = stock -
                                                    int.parse(element.quantity
                                                        .toString());

                                                ref.child(productPath).update({
                                                  'productStock': '$remainStock'
                                                });
                                              }

                                              ///____________deleted_products_______________________________________________

                                              for (var element
                                                  in increaseStockList) {
                                                final ref = FirebaseDatabase
                                                    .instance
                                                    .ref(
                                                        '${await getUserID()}/Products/');

                                                var data = await ref
                                                    .orderByChild('productCode')
                                                    .equalTo(element.productId)
                                                    .once();
                                                String productPath = data
                                                    .snapshot.value
                                                    .toString()
                                                    .substring(1, 21);

                                                var data1 = await ref
                                                    .child(
                                                        '$productPath/productStock')
                                                    .get();

                                                int stock = int.parse(
                                                    data1.value.toString());

                                                ///______update_stock____________________________________________________
                                                int remainStock = stock +
                                                    int.parse(element.quantity
                                                        .toString());

                                                ref.child(productPath).update({
                                                  'productStock': '$remainStock'
                                                });

                                                ///_____serial_add________________________________
                                                ProductModel? productData;

                                                final serialRef =
                                                    FirebaseDatabase.instance.ref(
                                                        '$userId/Products/$productPath');
                                                await serialRef
                                                    .orderByKey()
                                                    .get()
                                                    .then((value) {
                                                  productData =
                                                      ProductModel.fromJson(
                                                          jsonDecode(jsonEncode(
                                                              value.value)));
                                                });

                                                for (var element
                                                    in element.serialNumber!) {
                                                  productData!.serialNumber
                                                      .add(element);
                                                }
                                                serialRef
                                                    .child('serialNumber')
                                                    .set(productData!
                                                        .serialNumber
                                                        .map((e) => e)
                                                        .toList());
                                              }

                                              ///_________DueUpdate______________________________________________________OK
                                              if (pastDue <
                                                  widget.newTransitionModel
                                                      .dueAmount!) {
                                                double due = pastDue -
                                                    widget.newTransitionModel
                                                        .dueAmount!;
                                                // getSpecificCustomersDueUpdate(
                                                //     phoneNumber: widget.newTransitionModel.customerPhone, isDuePaid: false, due: due.toInt());

                                                final ref = FirebaseDatabase
                                                    .instance
                                                    .ref(
                                                        '${await getUserID()}/Customers/');
                                                String? key;

                                                await FirebaseDatabase.instance
                                                    .ref(await getUserID())
                                                    .child('Customers')
                                                    .orderByKey()
                                                    .get()
                                                    .then((value) {
                                                  for (var element
                                                      in value.children) {
                                                    var data = jsonDecode(
                                                        jsonEncode(
                                                            element.value));
                                                    if (data['phoneNumber'] ==
                                                        widget
                                                            .newTransitionModel
                                                            .customerPhone) {
                                                      key = element.key;
                                                    }
                                                  }
                                                });
                                                var data1 = await ref
                                                    .child('$key/due')
                                                    .get();
                                                int previousDue = data1.value
                                                    .toString()
                                                    .toInt();

                                                int totalDue;

                                                totalDue =
                                                    previousDue - due.toInt();
                                                ref.child(key!).update(
                                                    {'due': '$totalDue'});
                                              } else if (pastDue >
                                                  widget.newTransitionModel
                                                      .dueAmount!) {
                                                double due = widget
                                                        .newTransitionModel
                                                        .dueAmount! -
                                                    pastDue;
                                                final ref = FirebaseDatabase
                                                    .instance
                                                    .ref('$userId/Customers/');
                                                String? key;

                                                await FirebaseDatabase.instance
                                                    .ref(userId)
                                                    .child('Customers')
                                                    .orderByKey()
                                                    .get()
                                                    .then((value) {
                                                  for (var element
                                                      in value.children) {
                                                    var data = jsonDecode(
                                                        jsonEncode(
                                                            element.value));
                                                    if (data['phoneNumber'] ==
                                                        widget
                                                            .newTransitionModel
                                                            .customerPhone) {
                                                      key = element.key;
                                                    }
                                                  }
                                                });
                                                var data1 = await ref
                                                    .child('$key/due')
                                                    .get();
                                                int previousDue = data1.value
                                                    .toString()
                                                    .toInt();

                                                int totalDue;

                                                totalDue =
                                                    previousDue + due.toInt();
                                                ref.child(key!).update(
                                                    {'due': '$totalDue'});
                                              }

                                              print(
                                                  '---------First step -----------');

                                              await GeneratePdfAndPrint()
                                                  .uploadSaleInvoice(
                                                      personalInformationModel:
                                                          data,
                                                      saleTransactionModel:
                                                          myTransitionModel,
                                                      setting: setting);

                                              print(
                                                  '---------Second step -----------');

                                              // ignore: unused_result
                                              consumerRef
                                                  // ignore: unused_result
                                                  .refresh(allCustomerProvider);
                                              // ignore: unused_result
                                              consumerRef.refresh(
                                                  buyerCustomerProvider);
                                              // ignore: unused_result
                                              consumerRef
                                                  // ignore: unused_result
                                                  .refresh(transitionProvider);
                                              // ignore: unused_result
                                              consumerRef
                                                  // ignore: unused_result
                                                  .refresh(productProvider);
                                              // ignore: unused_result
                                              consumerRef.refresh(
                                                  purchaseTransitionProvider);
                                              // ignore: unused_result
                                              consumerRef.refresh(
                                                  dueTransactionProvider);
                                              // ignore: unused_result
                                              consumerRef.refresh(
                                                  profileDetailsProvider);

                                              EasyLoading.dismiss();

                                              // ignore: use_build_context_synchronously
                                              int count = 0;
                                              // ignore: use_build_context_synchronously
                                              while (count < 2 &&
                                                  GoRouter.of(context)
                                                      .canPop()) {
                                                GoRouter.of(context).pop();
                                                count++;
                                              }
                                              // ignore: use_build_context_synchronously
                                              if (GoRouter.of(context)
                                                  .canPop()) {
                                                GoRouter.of(context).pop(widget
                                                    .saleListPopUpContext);
                                              }
                                            } catch (e) {
                                              EasyLoading.dismiss();
                                              print(e.toString());
                                              //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                            }
                                          }
                                        } else {
                                          EasyLoading.showError(lang.S
                                              .of(context)
                                              .addProductFirst);
                                        }
                                      },
                                      child: Text(
                                        lang.S.of(context).payment,
                                      ),
                                    );
                                  }, error: (error, stack) {
                                    return Text(error.toString());
                                  }, loading: () {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      )),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: radiusCircular(5.0),
                                    topRight: radiusCircular(5.0)),
                                color: kWhite,
                                border:
                                    Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).totalProduct,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${widget.newTransitionModel.productList?.length}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///______________total_Amount_______________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                color: kWhite,
                                border:
                                    Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).totalAmount,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${getTotalAmount()}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///__________vat_gst__________________________________________________________
                            // Container(
                            //   padding: const EdgeInsets.all(10.0),
                            //   decoration: BoxDecoration(
                            //     color: kWhite,
                            //     border: Border.all(color: kLitGreyColor),
                            //   ),
                            //   child: Row(
                            //     children: [
                            //       Text(
                            //         lang.S.of(context).vatOrgst,
                            //         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                            //       ),
                            //       const Spacer(),
                            //       Text(
                            //         '$globalCurrency ${widget.newTransitionModel.vat}',
                            //         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            ///___________service_________________________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                color: kWhite,
                                border:
                                    Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).shpingOrServices,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${widget.newTransitionModel.serviceCharge}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///___________service_________________________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                color: kWhite,
                                border:
                                    Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).discount,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${widget.newTransitionModel.discountAmount}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),

                            ///______________grand_total___________________________________________________
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    bottomLeft: radiusCircular(5.0),
                                    bottomRight: radiusCircular(5.0)),
                                color: kbgColor,
                                border:
                                    Border.all(color: kNeutral300, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).grandTotal,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$globalCurrency ${widget.newTransitionModel.totalAmount}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20.0),
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
}
