import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Provider/due_transaction_provider.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/product_model.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/purchase_transation_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

// ignore: must_be_immutable
class ShowEditPurchasePaymentPopUp extends StatefulWidget {
  ShowEditPurchasePaymentPopUp({
    super.key,
    required this.purchaseTransitionModel,
    required this.previousPaid,
    required this.increaseStockList,
    required this.saleListPopUpContext,
  });
  final PurchaseTransactionModel purchaseTransitionModel;
  final double previousPaid;
  List<ProductModel> increaseStockList;
  final BuildContext saleListPopUpContext;

  @override
  State<ShowEditPurchasePaymentPopUp> createState() =>
      _ShowEditPurchasePaymentPopUpState();
}

class _ShowEditPurchasePaymentPopUpState
    extends State<ShowEditPurchasePaymentPopUp> {
  List<String> paymentItem = ['Cash', 'Bank', 'Mobile Pay'];
  String selectedPaymentOption = 'Cash';

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
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: kNeutral400,
      ),
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
    for (var item in widget.purchaseTransitionModel.productList!) {
      total = total +
          (double.parse(item.productPurchasePrice) * item.productStock.toInt());
    }
    return total.toString();
  }

  double discountAmount = 0;
  double returnAmount = 0;
  double subTotal = 0;
  String? dropdownValue = 'Cash';

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();

  bool isGuestCustomer = false;
  List<ProductModel> presentProducts = [];
  List<ProductModel> decreaseStockList2 = [];
  late PurchaseTransactionModel myTransitionModel;

  @override
  void initState() {
    super.initState();

    payingAmountController.text = widget.previousPaid.toString();
    double paidAmount = widget.previousPaid;
    if (paidAmount > widget.purchaseTransitionModel.totalAmount!.toDouble()) {
      changeAmountController.text =
          (paidAmount - widget.purchaseTransitionModel.totalAmount!.toDouble())
              .toString();
      dueAmountController.text = '0';
    } else {
      dueAmountController.text =
          (widget.purchaseTransitionModel.totalAmount!.toDouble() - paidAmount)
              .abs()
              .toString();

      changeAmountController.text = '0';
    }
    presentProducts = widget.purchaseTransitionModel.productList!;
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
        return personalData.when(
          data: (data) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 10.0, left: 10.0, right: 10.0),
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
                        const Icon(FeatherIcons.x,
                                color: kTitleColor, size: 25.0)
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
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //-------------------paying amount-------------------
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
                                              widget.purchaseTransitionModel
                                                  .totalAmount!
                                                  .toDouble()) {
                                            changeAmountController
                                                .text = (paidAmount -
                                                    widget
                                                        .purchaseTransitionModel
                                                        .totalAmount!
                                                        .toDouble())
                                                .toString();
                                            dueAmountController.text = '0';
                                          } else {
                                            dueAmountController.text = (widget
                                                        .purchaseTransitionModel
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
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        hintText:
                                            lang.S.of(context).enterPaidAmount,
                                      ),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 10.0),
                                //------------------------change amount----------------------
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
                                    child: TextFormField(
                                      controller: changeAmountController,
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        hintText:
                                            lang.S.of(context).changeAmount,
                                      ),
                                    ),
                                  )
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
                                //         controller: changeAmountController,
                                //         showCursor: true,
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
                                //-----------------------due amount--------------------------
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
                                    child: TextFormField(
                                      controller: dueAmountController,
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        hintText: lang.S.of(context).dueAmount,
                                      ),
                                    ),
                                  )
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
                                //         controller: dueAmountController,
                                //         showCursor: true,
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
                                //--------------------payment type----------------
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
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 12.0,
                                                          right: 10.0,
                                                          top: 7.0,
                                                          bottom: 7.0),
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .never),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: getOption()),
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
                                //             child: DropdownButtonHideUnderline(child: getOption()),
                                //           );
                                //         },
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                const SizedBox(height: 20.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              GoRouter.of(context).pop(),
                                          child: Text(
                                            lang.S.of(context).cancel,
                                          )),
                                    ),
                                    const SizedBox(width: 20),
                                    settingProvider.when(data: (setting) {
                                      return Flexible(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (widget.purchaseTransitionModel
                                                .productList!.isNotEmpty) {
                                              if (isGuestCustomer &&
                                                  dueAmountController.text
                                                          .toDouble() >
                                                      0) {
                                                EasyLoading.showError(lang.S
                                                    .of(context)
                                                    .dueIsNotForGuestCustomer);
                                              } else {
                                                try {
                                                  EasyLoading.show(
                                                      status:
                                                          '${lang.S.of(context).loading}...',
                                                      dismissOnTap: false);
                                                  List<ProductModel>
                                                      originalProducts = [];
                                                  int originalDue = 0;

                                                  myTransitionModel =
                                                      PurchaseTransactionModel(
                                                    customerName: widget
                                                        .purchaseTransitionModel
                                                        .customerName,
                                                    customerPhone: widget
                                                        .purchaseTransitionModel
                                                        .customerPhone,
                                                    customerGst: widget
                                                        .purchaseTransitionModel
                                                        .customerGst,
                                                    customerAddress: widget
                                                        .purchaseTransitionModel
                                                        .customerAddress,
                                                    customerType: widget
                                                        .purchaseTransitionModel
                                                        .customerType,
                                                    invoiceNumber: widget
                                                        .purchaseTransitionModel
                                                        .invoiceNumber,
                                                    purchaseDate: widget
                                                        .purchaseTransitionModel
                                                        .purchaseDate,
                                                    discountAmount: widget
                                                        .purchaseTransitionModel
                                                        .discountAmount,
                                                    sellerName: "Admin", // TODO: Reemplazar por el nombre real del usuario autenticado
                                                  );
                                                  final userId =
                                                      await getUserID();

                                                  dueAmountController.text
                                                              .toDouble() <=
                                                          0
                                                      ? myTransitionModel
                                                          .isPaid = true
                                                      : myTransitionModel
                                                          .isPaid = false;
                                                  dueAmountController.text
                                                              .toDouble() <=
                                                          0
                                                      ? myTransitionModel
                                                          .dueAmount = 0
                                                      : myTransitionModel
                                                              .dueAmount =
                                                          dueAmountController
                                                              .text
                                                              .toDouble();
                                                  returnAmount < 0
                                                      ? myTransitionModel
                                                              .returnAmount =
                                                          returnAmount.abs()
                                                      : myTransitionModel
                                                          .returnAmount = 0;
                                                  myTransitionModel
                                                          .productList =
                                                      widget
                                                          .purchaseTransitionModel
                                                          .productList;

                                                  myTransitionModel
                                                          .totalAmount =
                                                      widget
                                                          .purchaseTransitionModel
                                                          .totalAmount!
                                                          .toDouble();
                                                  myTransitionModel
                                                          .paymentType =
                                                      selectedPaymentOption;

                                                  ///________________updateInvoice___________________________________________________________ok
                                                  String? key;
                                                  await FirebaseDatabase
                                                      .instance
                                                      .ref(userId)
                                                      .child(
                                                          'Purchase Transition')
                                                      .orderByKey()
                                                      .get()
                                                      .then((value) {
                                                    for (var element
                                                        in value.children) {
                                                      final t = PurchaseTransactionModel
                                                          .fromJson(jsonDecode(
                                                              jsonEncode(element
                                                                  .value)));
                                                      if (widget
                                                              .purchaseTransitionModel
                                                              .invoiceNumber ==
                                                          t.invoiceNumber) {
                                                        key = element.key;
                                                        originalProducts =
                                                            t.productList ?? [];
                                                        originalDue = t
                                                            .dueAmount!
                                                            .toInt();
                                                      }
                                                    }
                                                  });
                                                  await FirebaseDatabase
                                                      .instance
                                                      .ref(userId)
                                                      .child(
                                                          'Purchase Transition')
                                                      .child(key!)
                                                      .update(myTransitionModel
                                                          .toJson());

                                                  ///__________StockMange_________________________________________________ok

                                                  for (var pastElement
                                                      in originalProducts) {
                                                    int i = 0;
                                                    for (var futureElement
                                                        in presentProducts) {
                                                      if (pastElement
                                                              .productCode ==
                                                          futureElement
                                                              .productCode) {
                                                        if (pastElement
                                                                    .productStock
                                                                    .toInt() <
                                                                futureElement
                                                                    .productStock
                                                                    .toInt() &&
                                                            pastElement
                                                                    .productStock !=
                                                                futureElement
                                                                    .productStock) {
                                                          ProductModel m =
                                                              pastElement;
                                                          m.productStock = (futureElement
                                                                      .productStock
                                                                      .toInt() -
                                                                  pastElement
                                                                      .productStock
                                                                      .toInt())
                                                              .toString();
                                                          // ignore: iterable_contains_unrelated_type
                                                          widget.increaseStockList
                                                                  .contains(
                                                                      pastElement
                                                                          .productCode)
                                                              ? null
                                                              : widget
                                                                  .increaseStockList
                                                                  .add(m);
                                                        } else if (pastElement
                                                                    .productStock
                                                                    .toInt() >
                                                                futureElement
                                                                    .productStock
                                                                    .toInt() &&
                                                            pastElement
                                                                    .productStock
                                                                    .toInt() !=
                                                                futureElement
                                                                    .productStock
                                                                    .toInt()) {
                                                          ProductModel n =
                                                              pastElement;
                                                          n.productStock = (pastElement
                                                                      .productStock
                                                                      .toInt() -
                                                                  futureElement
                                                                      .productStock
                                                                      .toInt())
                                                              .toString();
                                                          // ignore: iterable_contains_unrelated_type
                                                          decreaseStockList2
                                                                  .contains(
                                                                      pastElement
                                                                          .productCode)
                                                              ? null
                                                              : decreaseStockList2
                                                                  .add(n);
                                                        }
                                                        break;
                                                      } else {
                                                        i++;
                                                        if (i ==
                                                            presentProducts
                                                                .length) {
                                                          ProductModel n =
                                                              pastElement;
                                                          decreaseStockList2
                                                              .add(n);
                                                        }
                                                      }
                                                    }
                                                  }

                                                  ///_____________StockUpdate_______________________________________________________ok

                                                  for (var element
                                                      in decreaseStockList2) {
                                                    final ref = FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            '$userId/Products');

                                                    var data = await ref
                                                        .orderByChild(
                                                            'productCode')
                                                        .equalTo(
                                                            element.productCode)
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
                                                        element.productStock
                                                            .toInt();

                                                    ref
                                                        .child(productPath)
                                                        .update({
                                                      'productStock':
                                                          '$remainStock'
                                                    });
                                                  }

                                                  for (var element in widget
                                                      .increaseStockList) {
                                                    final ref = FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            '$userId/Products');

                                                    var data = await ref
                                                        .orderByChild(
                                                            'productCode')
                                                        .equalTo(
                                                            element.productCode)
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
                                                    int remainStock = stock +
                                                        element.productStock
                                                            .toInt();

                                                    ref
                                                        .child(productPath)
                                                        .update({
                                                      'productStock':
                                                          '$remainStock'
                                                    });
                                                  }

                                                  ///_________DueUpdate______________________________________________________OK
                                                  if (myTransitionModel
                                                          .dueAmount!
                                                          .toDouble() <
                                                      widget
                                                          .purchaseTransitionModel
                                                          .dueAmount!) {
                                                    double due = originalDue -
                                                        myTransitionModel
                                                            .dueAmount!;

                                                    final ref = FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            '$userId/Customers/');
                                                    String? key;

                                                    await FirebaseDatabase
                                                        .instance
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
                                                        if (data[
                                                                'phoneNumber'] ==
                                                            widget
                                                                .purchaseTransitionModel
                                                                .customerPhone) {
                                                          key = element.key;
                                                        }
                                                      }
                                                    });
                                                    var data1 = await ref
                                                        .child('$key/due')
                                                        .get();
                                                    int previousDue = data1
                                                        .value
                                                        .toString()
                                                        .toInt();

                                                    int totalDue;

                                                    totalDue = previousDue -
                                                        due.toInt();
                                                    ref.child(key!).update(
                                                        {'due': '$totalDue'});
                                                  } else if (myTransitionModel
                                                          .dueAmount!
                                                          .toDouble() >
                                                      widget
                                                          .purchaseTransitionModel
                                                          .dueAmount!) {
                                                    double due =
                                                        myTransitionModel
                                                                .dueAmount! -
                                                            originalDue;
                                                    final ref = FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                            '$userId/Customers/');
                                                    String? key;

                                                    await FirebaseDatabase
                                                        .instance
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
                                                        if (data[
                                                                'phoneNumber'] ==
                                                            widget
                                                                .purchaseTransitionModel
                                                                .customerPhone) {
                                                          key = element.key;
                                                        }
                                                      }
                                                    });
                                                    var data1 = await ref
                                                        .child('$key/due')
                                                        .get();
                                                    int previousDue = data1
                                                        .value
                                                        .toString()
                                                        .toInt();

                                                    int totalDue;

                                                    totalDue = previousDue +
                                                        due.toInt();
                                                    ref.child(key!).update(
                                                        {'due': '$totalDue'});
                                                  }
                                                  await GeneratePdfAndPrint()
                                                      .uploadPurchaseInvoice(
                                                          personalInformationModel:
                                                              data,
                                                          purchaseTransactionModel:
                                                              myTransitionModel,
                                                          setting: setting);

                                                  // ignore: unused_result
                                                  consumerRef.refresh(
                                                      allCustomerProvider);

                                                  // ignore: unused_result
                                                  consumerRef.refresh(
                                                      buyerCustomerProvider);
                                                  // ignore: unused_result
                                                  consumerRef.refresh(
                                                      transitionProvider);
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
                                            lang.S.of(context).submit,
                                          ),
                                        ),
                                      );
                                    }, error: (e, stack) {
                                      return Text(e.toString());
                                    }, loading: () {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }),
                                  ],
                                ),
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
                              ///____________total Products_____________________________________________________
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      topLeft: radiusCircular(5.0),
                                      topRight: radiusCircular(1.0)),
                                  color: kWhite,
                                  border: Border.all(
                                      color: kOutlineColor, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      lang.S.of(context).totalProduct,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${widget.purchaseTransitionModel.productList?.length}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),

                              ///_________total Price______________________________________________________________
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  border: Border.all(
                                      color: kOutlineColor, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      lang.S.of(context).totalPrice,
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

                              ///___________discount________________________________________________________________
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  border: Border.all(
                                      color: kOutlineColor, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      lang.S.of(context).discount,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$globalCurrency ${widget.purchaseTransitionModel.discountAmount}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),

                              ///___________________grand_total___________________________________________________
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: radiusCircular(5.0),
                                      bottomRight: radiusCircular(5.0)),
                                  color: kBackgroundColor,
                                  border: Border.all(color: kOutlineColor),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      lang.S.of(context).grandTotal,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$globalCurrency ${widget.purchaseTransitionModel.totalAmount}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20.0),
                            ],
                          ),
                        ))
                  ]),
                ],
              ),
            );
          },
          error: (e, stack) {
            return Center(
              child: Text(e.toString()),
            );
          },
          loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      },
    );
  }
}
