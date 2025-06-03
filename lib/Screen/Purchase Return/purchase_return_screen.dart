// ignore_for_file: unused_result
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/Provider/purchase_returns_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/product_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';

import '../../Provider/customer_provider.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/general_setting_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen(
      {super.key,
      required this.purchaseTransactionModel,
      required this.personalInformationModel});

  final PurchaseTransactionModel purchaseTransactionModel;
  final PersonalInformationModel personalInformationModel;

  static const String route = '/purchase_Return';

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  num getTotalReturnAmount() {
    num returnAmount = 0;
    for (var element in returnList) {
      if (element.lowerStockAlert > 0) {
        returnAmount += element.lowerStockAlert *
            (num.tryParse(element.productPurchasePrice.toString()) ?? 0);
      }
    }
    return returnAmount;
  }

  Future<void> purchaseReturn(
      {required PurchaseTransactionModel purchase,
      required PurchaseTransactionModel orginal,
      required WidgetRef consumerRef,
      required BuildContext context,
      required GeneralSettingModel setting}) async {
    try {
      EasyLoading.show(
          status: '${lang.S.of(context).loading}...', dismissOnTap: false);

      ///_________Push_on_Sale_return_dataBase____________________________________________________________________________
      DatabaseReference ref =
          FirebaseDatabase.instance.ref("${await getUserID()}/Purchase Return");
      await ref.push().set(purchase.toJson());

      await GeneratePdfAndPrint().printPurchaseReturnInvoice(
          personalInformationModel: widget.personalInformationModel,
          purchaseTransactionModel: purchase,
          setting: setting);

      ///__________StockMange_________________________________________________________________________________
      final stockRef =
          FirebaseDatabase.instance.ref('${await getUserID()}/Products/');

      for (var element in purchase.productList!) {
        var data = await stockRef
            .orderByChild('productCode')
            .equalTo(element.productCode)
            .once();
        String productPath = data.snapshot.value.toString().substring(1, 21);

        var data1 = await stockRef.child('$productPath/productStock').get();
        num stock = num.parse(data1.value.toString());
        num remainStock = stock - element.lowerStockAlert;

        stockRef.child(productPath).update({'productStock': '$remainStock'});

        //________Update_Serial_Number____________________________________________________

        // if (element.serialNumber.isNotEmpty) {
        //   var productOldSerialList = data2[productPath]['serialNumber'] + element.serialNumber;
        //
        //   // List<dynamic> result = productOldSerialList.where((item) => !element.serialNumber!.contains(item)).toList();
        //   stockRef.child(productPath).update({
        //     'serialNumber': productOldSerialList.map((e) => e).toList(),
        //   });
        // }
      }

      ///________daily_transactionModel_________________________________________________________________________

      DailyTransactionModel dailyTransaction = DailyTransactionModel(
        name: purchase.customerName,
        date: purchase.purchaseDate,
        type: 'Purchase Return',
        total: purchase.totalAmount!.toDouble(),
        paymentIn: ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)) >
                (purchase.totalAmount ?? 0)
            ? (purchase.totalAmount ?? 0)
            : ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)),
        remainingBalance:
            ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)) >
                    (purchase.totalAmount ?? 0)
                ? (purchase.totalAmount ?? 0)
                : ((orginal.totalAmount ?? 0) - (orginal.dueAmount ?? 0)),
        paymentOut: 0,
        id: purchase.invoiceNumber,
        purchaseTransactionModel: purchase,
      );

      postDailyTransaction(dailyTransactionModel: dailyTransaction);

      ///_________DueUpdate___________________________________________________________________________________
      if (purchase.customerName != 'Guest' && (orginal.dueAmount ?? 0) > 0) {
        final dueUpdateRef =
            FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
        String? key;

        await FirebaseDatabase.instance
            .ref(await getUserID())
            .child('Customers')
            .orderByKey()
            .get()
            .then((value) {
          for (var element in value.children) {
            var data = jsonDecode(jsonEncode(element.value));
            if (data['phoneNumber'] == purchase.customerPhone) {
              key = element.key;
            }
          }
        });
        var data1 = await dueUpdateRef.child('$key/due').get();
        int previousDue = data1.value.toString().toInt();

        num dueNow = (orginal.dueAmount ?? 0) - (purchase.totalAmount ?? 0);

        int totalDue =
            dueNow.isNegative ? 0 : previousDue - purchase.totalAmount!.toInt();
        dueUpdateRef.child(key!).update({'due': '$totalDue'});
      }

      consumerRef.refresh(allCustomerProvider);
      consumerRef.refresh(purchaseReturnProvider);
      consumerRef.refresh(buyerCustomerProvider);
      consumerRef.refresh(transitionProvider);
      consumerRef.refresh(productProvider);
      consumerRef.refresh(purchaseTransitionProvider);
      consumerRef.refresh(dueTransactionProvider);
      consumerRef.refresh(profileDetailsProvider);
      consumerRef.refresh(dailyTransactionProvider);

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

  DateTime selectedDueDate = DateTime.now();

  Future<void> _selectedDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDueDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  List<ProductModel> returnList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();

    for (var element in widget.purchaseTransactionModel.productList!) {
      element.lowerStockAlert = 0;
      returnList.add(element);
    }
  }

  final _horizontalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          final settingProvider = ref.watch(generalSettingProvider);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), color: kWhite),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          lang.S.of(context).purchaseReturn,
                          //'Purchase Return',
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
                      ResponsiveGridRow(children: [
                        //---------------customer-----------------------
                        ResponsiveGridCol(
                            lg: 4,
                            md: 4,
                            xs: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${lang.S.of(context).customerName}:',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: kNeutral400),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                          child: Text(
                                        widget.purchaseTransactionModel
                                            .customerName,
                                        style: theme.textTheme.titleMedium,
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        //---------------invoice-------------------------
                        ResponsiveGridCol(
                            lg: 4,
                            md: 4,
                            xs: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${lang.S.of(context).invoice}:',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: kNeutral400),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                          child: Text(
                                        "#${widget.purchaseTransactionModel.invoiceNumber}",
                                        style: theme.textTheme.titleMedium,
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        //-----------------date-----------------------
                        ResponsiveGridCol(
                            lg: 4,
                            md: 4,
                            xs: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${lang.S.of(context).date}:',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                      child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: kNeutral400),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ).onTap(() => _selectedDueDate(context)),
                                  )),
                                ],
                              ),
                            ))
                      ]),

                      const SizedBox(height: 20),

                      ///___________Cart_List_Show _and buttons__________________________________
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final kWidth = constraints.maxWidth;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horizontalController,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: kWidth,
                              ),
                              child: Theme(
                                data: theme.copyWith(
                                    dividerTheme: const DividerThemeData(
                                        color: Colors.transparent)),
                                child: DataTable(
                                    border: const TableBorder(
                                      horizontalInside: BorderSide(
                                        width: 1,
                                        color: kNeutral300,
                                      ),
                                    ),
                                    dataRowColor: const WidgetStatePropertyAll(
                                        whiteColor),
                                    headingRowColor: WidgetStateProperty.all(
                                        const Color(0xFFF8F3FF)),
                                    showBottomBorder: false,
                                    dividerThickness: 0.0,
                                    headingTextStyle:
                                        theme.textTheme.titleMedium,
                                    dataTextStyle: theme.textTheme.bodyLarge,
                                    columns: [
                                      DataColumn(
                                          label: Text(
                                              lang.S.of(context).productNam)),
                                      DataColumn(
                                          label: Text(
                                              lang.S.of(context).saleQuantity)),
                                      DataColumn(
                                          label: Text(lang.S
                                              .of(context)
                                              .returnQuantity)),
                                      DataColumn(
                                          label:
                                              Text(lang.S.of(context).price)),
                                      DataColumn(
                                          label: Text(
                                              lang.S.of(context).subTotal)),
                                    ],
                                    rows: List.generate(returnList.length,
                                        (index) {
                                      TextEditingController quantityController =
                                          TextEditingController(
                                              text: returnList[index]
                                                  .lowerStockAlert
                                                  .toString());
                                      return DataRow(cells: [
                                        ///______________name__________________________________________________
                                        DataCell(
                                          Text(
                                            returnList[index].productName,
                                          ),
                                        ),

                                        ///____________quantity_________________________________________________
                                        DataCell(
                                          Text(returnList[index]
                                              .productStock
                                              .toString()),
                                        ),

                                        ///____________return_quantity_________________________________________________
                                        DataCell(
                                          Row(
                                            children: [
                                              const Icon(
                                                      FontAwesomeIcons
                                                          .solidSquareMinus,
                                                      color: kBlueTextColor)
                                                  .onTap(() {
                                                setState(() {
                                                  returnList[index]
                                                              .lowerStockAlert >
                                                          0
                                                      ? returnList[index]
                                                          .lowerStockAlert--
                                                      : returnList[index]
                                                          .lowerStockAlert = 0;
                                                });
                                              }),
                                              const SizedBox(width: 5),
                                              SizedBox(
                                                height: 35,
                                                width: 60,
                                                child: TextFormField(
                                                  controller:
                                                      quantityController,
                                                  textAlign: TextAlign.center,
                                                  onChanged: (value) {
                                                    if ((num.tryParse(returnList[
                                                                    index]
                                                                .productStock) ??
                                                            0) <
                                                        (num.tryParse(value) ??
                                                            0)) {
                                                      EasyLoading.showError(lang
                                                          .S
                                                          .of(context)
                                                          .outOfStock);
                                                      quantityController
                                                          .clear();
                                                    } else if (value == '') {
                                                      returnList[index]
                                                          .lowerStockAlert = 1;
                                                    } else if (value == '0') {
                                                      returnList[index]
                                                          .lowerStockAlert = 1;
                                                    } else {
                                                      returnList[index]
                                                              .lowerStockAlert =
                                                          (num.tryParse(
                                                                  value) ??
                                                              0);
                                                    }
                                                  },
                                                  onFieldSubmitted: (value) {
                                                    if (value == '') {
                                                      setState(() {
                                                        returnList[index]
                                                            .lowerStockAlert = 1;
                                                      });
                                                    } else {
                                                      setState(() {
                                                        returnList[index]
                                                                .lowerStockAlert =
                                                            (num.tryParse(
                                                                    value) ??
                                                                0);
                                                      });
                                                    }
                                                  },
                                                  decoration:
                                                      const InputDecoration(),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                      FontAwesomeIcons
                                                          .solidSquarePlus,
                                                      color: kBlueTextColor)
                                                  .onTap(() {
                                                if (returnList[index]
                                                        .lowerStockAlert <
                                                    (num.tryParse(returnList[
                                                                index]
                                                            .productStock) ??
                                                        0)) {
                                                  setState(() {
                                                    returnList[index]
                                                        .lowerStockAlert += 1;
                                                    toast(returnList[index]
                                                        .lowerStockAlert
                                                        .toString());
                                                  });
                                                } else {
                                                  EasyLoading.showError(lang.S
                                                      .of(context)
                                                      .outOfStock);
                                                }
                                              }),
                                            ],
                                          ),
                                        ),

                                        ///______price___________________________________________________________
                                        DataCell(
                                          SizedBox(
                                            height: 35,
                                            width: 70,
                                            child: TextFormField(
                                              initialValue: myFormat.format(
                                                  double.tryParse(returnList[
                                                              index]
                                                          .productPurchasePrice) ??
                                                      0),
                                              onChanged: (value) {
                                                if (value == '') {
                                                  setState(() {
                                                    returnList[index]
                                                            .productPurchasePrice =
                                                        0.toString();
                                                  });
                                                } else if (double.tryParse(
                                                        value) ==
                                                    null) {
                                                  EasyLoading.showError(lang.S
                                                      .of(context)
                                                      .enterAValidPrice);
                                                } else {
                                                  setState(() {
                                                    returnList[index]
                                                            .productPurchasePrice =
                                                        double.parse(value)
                                                            .toStringAsFixed(2);
                                                  });
                                                }
                                              },
                                              onFieldSubmitted: (value) {
                                                if (value == '') {
                                                  setState(() {
                                                    returnList[index]
                                                            .productPurchasePrice =
                                                        0.toString();
                                                  });
                                                } else if (double.tryParse(
                                                        value) ==
                                                    null) {
                                                  EasyLoading.showError(lang.S
                                                      .of(context)
                                                      .enterAValidPrice);
                                                } else {
                                                  setState(() {
                                                    returnList[index]
                                                            .productPurchasePrice =
                                                        double.parse(value)
                                                            .toStringAsFixed(2);
                                                  });
                                                }
                                              },
                                              decoration:
                                                  const InputDecoration(),
                                            ),
                                          ),
                                        ),

                                        ///___________subtotal____________________________________________________
                                        DataCell(
                                          Text(
                                            myFormat.format(double.tryParse((double
                                                            .parse(returnList[
                                                                    index]
                                                                .productPurchasePrice) *
                                                        ((num.tryParse(returnList[
                                                                        index]
                                                                    .productStock) ??
                                                                0) -
                                                            (returnList[index]
                                                                .lowerStockAlert)))
                                                    .toStringAsFixed(2)) ??
                                                0),
                                          ),
                                        ),
                                      ]);
                                    })),
                              ),
                            ),
                          );
                        },
                      ),

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
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 12,
                                md: 6,
                                lg: 6,
                                child: ResponsiveGridRow(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            '${lang.S.of(context).totalReturnAmount} :',
                                            //'Total Return Amount',
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
                                              alignment: Alignment.center,
                                              height: 48,
                                              decoration: const BoxDecoration(
                                                  color: kGreenTextColor,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(5))),
                                              child: Center(
                                                child: Text(
                                                  '$globalCurrency ${myFormat.format(getTotalReturnAmount())}',
                                                  style: kTextStyle.copyWith(
                                                      color: kWhite,
                                                      fontSize: 18.0,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ))
                                    ]),
                              )
                            ]),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.start,
                            //   children: [
                            //     Text(
                            //       '${lang.S.of(context).totalItem}: ${returnList.length}',
                            //       style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                            //     ),
                            //     const Spacer(),
                            //     SizedBox(
                            //       width: context.width() < 1080 ? 1080 * .12 : MediaQuery.of(context).size.width * .12,
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(right: 20),
                            //         child: Text(
                            //           lang.S.of(context).totalReturnAmount,
                            //           //'Total Return Amount',
                            //           textAlign: TextAlign.end,
                            //           style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                            //         ),
                            //       ),
                            //     ),
                            //     SizedBox(
                            //       width: 204,
                            //       child: Container(
                            //         padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 4.0, bottom: 4.0),
                            //         decoration: const BoxDecoration(color: kGreenTextColor, borderRadius: BorderRadius.all(Radius.circular(8))),
                            //         child: Center(
                            //           child: Text(
                            //             '$globalCurrency ${myFormat.format(getTotalReturnAmount())}',
                            //             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            const SizedBox(height: 10.0),

                            ///____________buttons____________________________________________________
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ///________________cancel_button_____________________________________
                                Flexible(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      context.pop();
                                    },
                                    child: Text(
                                      lang.S.of(context).cancel,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: Text(
                                      lang.S.of(context).hold,
                                      textAlign: TextAlign.center,
                                      style: kTextStyle.copyWith(
                                          color: kWhite,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ).visible(false),

                                ///________________payments_________________________________________
                                const SizedBox(width: 10.0),

                                settingProvider.when(data: (setting) {
                                  return Flexible(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (!returnList.any((element) =>
                                            element.lowerStockAlert > 0)) {
                                          EasyLoading.showError(lang.S
                                              .of(context)
                                              .selectAProductForReturn);
                                        } else {
                                          returnList.removeWhere((element) =>
                                              element.lowerStockAlert <= 0);

                                          ///____________Invoice_edit______________________________________
                                          PurchaseTransactionModel
                                              myTransitionModel =
                                              widget.purchaseTransactionModel;
                                          final userId = await getUserID();

                                          (num.tryParse(getTotalReturnAmount()
                                                          .toString()) ??
                                                      0) >
                                                  (widget.purchaseTransactionModel
                                                          .dueAmount ??
                                                      0)
                                              ? myTransitionModel.isPaid = true
                                              : myTransitionModel.isPaid =
                                                  false;
                                          if ((widget.purchaseTransactionModel
                                                      .dueAmount ??
                                                  0) >
                                              0) {
                                            (num.tryParse(getTotalReturnAmount()
                                                            .toString()) ??
                                                        0) >=
                                                    (widget.purchaseTransactionModel
                                                            .dueAmount ??
                                                        0)
                                                ? myTransitionModel.dueAmount =
                                                    0
                                                : myTransitionModel
                                                    .dueAmount = (widget
                                                            .purchaseTransactionModel
                                                            .dueAmount ??
                                                        0) -
                                                    (num.tryParse(
                                                            getTotalReturnAmount()
                                                                .toString()) ??
                                                        0);
                                          }
                                          List<ProductModel> newProductList =
                                              [];
                                          for (var p in widget
                                              .purchaseTransactionModel
                                              .productList!) {
                                            if (returnList.any((element) =>
                                                element.productCode ==
                                                p.productCode)) {
                                              int index = returnList.indexWhere(
                                                  (element) =>
                                                      element.productCode ==
                                                      p.productCode);
                                              p.productStock = ((double.tryParse(
                                                              p.productStock) ??
                                                          0) -
                                                      returnList[index]
                                                          .lowerStockAlert)
                                                  .toString();
                                            }

                                            if ((double.tryParse(
                                                        p.productStock) ??
                                                    0) >
                                                0) newProductList.add(p);
                                          }
                                          myTransitionModel.productList =
                                              newProductList;

                                          myTransitionModel.totalAmount =
                                              (myTransitionModel.totalAmount ??
                                                      0) -
                                                  (double.tryParse(
                                                          getTotalReturnAmount()
                                                              .toString()) ??
                                                      0);

                                          ///________________updateInvoice___________________________________________________________ok
                                          String? key;
                                          await FirebaseDatabase.instance
                                              .ref(userId)
                                              .child('Purchase Transition')
                                              .orderByKey()
                                              .get()
                                              .then((value) {
                                            for (var element
                                                in value.children) {
                                              final t = PurchaseTransactionModel
                                                  .fromJson(jsonDecode(
                                                      jsonEncode(
                                                          element.value)));
                                              if (widget
                                                      .purchaseTransactionModel
                                                      .invoiceNumber ==
                                                  t.invoiceNumber) {
                                                key = element.key;
                                              }
                                            }
                                          });
                                          if (newProductList.isEmpty) {
                                            await FirebaseDatabase.instance
                                                .ref(userId)
                                                .child('Purchase Transition')
                                                .child(key!)
                                                .remove();
                                          } else {
                                            ///__________total LossProfit & quantity________________________________________________________________
                                            await FirebaseDatabase.instance
                                                .ref(userId)
                                                .child('Purchase Transition')
                                                .child(key!)
                                                .update(
                                                    myTransitionModel.toJson());
                                          }
                                          for (var element in returnList) {
                                            element.productStock = element
                                                .lowerStockAlert
                                                .toString();
                                          }
                                          returnList.removeWhere((element) =>
                                              element.lowerStockAlert <= 0);
                                          PurchaseTransactionModel invoice =
                                              PurchaseTransactionModel(
                                            customerName: widget
                                                .purchaseTransactionModel
                                                .customerName,
                                            customerType: widget
                                                .purchaseTransactionModel
                                                .customerType,
                                            customerGst: widget
                                                .purchaseTransactionModel
                                                .customerGst,
                                            customerPhone: widget
                                                .purchaseTransactionModel
                                                .customerPhone,
                                            invoiceNumber: widget
                                                .purchaseTransactionModel
                                                .invoiceNumber,
                                            purchaseDate: widget
                                                .purchaseTransactionModel
                                                .purchaseDate,
                                            customerAddress: widget
                                                .purchaseTransactionModel
                                                .customerAddress,
                                            sendWhatsappMessage: widget
                                                    .purchaseTransactionModel
                                                    .sendWhatsappMessage ??
                                                false,
                                            productList: returnList,
                                            totalAmount: double.tryParse(
                                                getTotalReturnAmount()
                                                    .toString()),
                                            discountAmount: 0,
                                            sellerName: "Admin", // TODO: Reemplazar por el nombre real del usuario autenticado
                                            dueAmount: 0,
                                            isPaid: false,
                                            paymentType: 'Cash',
                                            returnAmount: 0,
                                          );

                                          await purchaseReturn(
                                              purchase: invoice,
                                              orginal: widget
                                                  .purchaseTransactionModel,
                                              consumerRef: ref,
                                              context: context,
                                              setting: setting);
                                        }
                                      },
                                      child: Text(
                                        lang.S.of(context).conformReturn,
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
