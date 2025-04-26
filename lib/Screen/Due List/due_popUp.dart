// ignore_for_file: use_build_context_synchronously, unused_result

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
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/customer_model.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/due_transaction_model.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class ShowDuePaymentPopUp extends StatefulWidget {
  const ShowDuePaymentPopUp({super.key, required this.customerModel});
  final CustomerModel customerModel;

  @override
  State<ShowDuePaymentPopUp> createState() => _ShowDuePaymentPopUpState();
}

class _ShowDuePaymentPopUpState extends State<ShowDuePaymentPopUp> {
  // List of items in our dropdown menu
  List<String> items = ['Select Invoice'];
  int count = 0;

  bool saleButtonClicked = false;

  late DueTransactionModel dueTransactionModel = DueTransactionModel(
    customerName: widget.customerModel.customerName,
    customerPhone: widget.customerModel.phoneNumber,
    customerAddress: widget.customerModel.customerAddress,
    customerType: widget.customerModel.type,
    invoiceNumber: invoice.toString(),
    purchaseDate: DateTime.now().toString(),
    customerGst: widget.customerModel.gst,
    sendWhatsappMessage: widget.customerModel.receiveWhatsappUpdates,
  );

  List<String> paymentItem = [
    'Cash',
    'Bank',
    'Due',
    'B-kash',
    'Nagad',
    'Rocket',
    'DBBL',
  ];
  String selectedPaymentOption = 'Cash';

  DropdownButton<String> getOption() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentItem) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.normal),
        ),
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
  String selectedInvoice = 'Select Invoice';
  String dropdownValue = 'Select Invoice';
  int invoice = 0;

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dueAmount = widget.customerModel.remainedBalance.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    count++;
    return Consumer(
      builder: (context, consumerRef, __) {
        final customerProviderRef = widget.customerModel.type == 'Supplier' ? consumerRef.watch(purchaseTransitionProvider) : consumerRef.watch(transitionProvider);
        final personalData = consumerRef.watch(profileDetailsProvider);
        final settingProvider = consumerRef.watch(generalSettingProvider);

        return personalData.when(data: (data) {
          invoice = data.dueInvoiceCounter;
          return SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///_________title_and_close_button__________________________________________________
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          lang.S.of(context).createPayment,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            GoRouter.of(context).pop();
                          },
                          icon: const Icon(FeatherIcons.x, color: kNeutral500, size: 20.0))
                    ],
                  ),
                ),
                const Divider(
                  thickness: 1.0,
                  height: 1,
                  color: kNeutral300,
                ),

                ///____________________________________________________________________________________
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: ResponsiveGridRow(children: [
                            ResponsiveGridCol(
                              xs: 12,
                              md: 9,
                              lg: 9,
                              child: customerProviderRef.when(data: (customer) {
                                for (var element in customer) {
                                  if (element.customerPhone == widget.customerModel.phoneNumber && element.dueAmount != 0 && count < 2) {
                                    items.add(element.invoiceNumber);
                                  }
                                  if (selectedInvoice == element.invoiceNumber) {
                                    dueAmount = element.dueAmount!.toDouble();
                                  } else if (selectedInvoice == 'Select Invoice') {
                                    dueAmount = widget.customerModel.remainedBalance.toDouble();
                                  }
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(05),
                                      ),
                                      border: Border.all(width: 1, color: kNeutral400),
                                    ),
                                    child: Center(
                                      child: Theme(
                                        data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton(
                                            value: dropdownValue,
                                            icon: const Icon(Icons.keyboard_arrow_down),
                                            items: items.map((String items) {
                                              return DropdownMenuItem(
                                                value: items,
                                                child: Text(items,
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: kNeutral500,
                                                    )),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                payingAmountController.text = '0';
                                                payingAmountController.clear();
                                                dropdownValue = newValue.toString();
                                                selectedInvoice = newValue.toString();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }, error: (e, stack) {
                                return Text(e.toString());
                              }, loading: () {
                                return const Center(child: CircularProgressIndicator());
                              }),
                            ),
                            ResponsiveGridCol(xs: 0, md: 3, lg: 3, child: const SizedBox.shrink())
                          ])),
                      // ResponsiveGridCol(
                      //   xs: 12,
                      //   md: 6,
                      //   lg: 6,
                      //   child: customerProviderRef.when(data: (customer) {
                      //     for (var element in customer) {
                      //       if (element.customerPhone == widget.customerModel.phoneNumber && element.dueAmount != 0 && count < 2) {
                      //         items.add(element.invoiceNumber);
                      //       }
                      //       if (selectedInvoice == element.invoiceNumber) {
                      //         dueAmount = element.dueAmount!.toDouble();
                      //       } else if (selectedInvoice == 'Select Invoice') {
                      //         dueAmount = widget.customerModel.remainedBalance.toDouble();
                      //       }
                      //     }
                      //     return Padding(
                      //       padding: const EdgeInsets.all(12.0),
                      //       child: Container(
                      //         height: 48,
                      //         decoration: BoxDecoration(
                      //           borderRadius: const BorderRadius.all(
                      //             Radius.circular(05),
                      //           ),
                      //           border: Border.all(width: 1, color: kNeutral400),
                      //         ),
                      //         child: Center(
                      //           child: Theme(
                      //             data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                      //             child: DropdownButtonHideUnderline(
                      //               child: DropdownButton(
                      //                 value: dropdownValue,
                      //                 icon: const Icon(Icons.keyboard_arrow_down),
                      //                 items: items.map((String items) {
                      //                   return DropdownMenuItem(
                      //                     value: items,
                      //                     child: Text(items,
                      //                         style: theme.textTheme.titleMedium?.copyWith(
                      //                           fontWeight: FontWeight.w600,
                      //                           color: kNeutral500,
                      //                         )),
                      //                   );
                      //                 }).toList(),
                      //                 onChanged: (newValue) {
                      //                   setState(() {
                      //                     payingAmountController.text = '0';
                      //                     payingAmountController.clear();
                      //                     dropdownValue = newValue.toString();
                      //                     selectedInvoice = newValue.toString();
                      //                   });
                      //                 },
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     );
                      //   }, error: (e, stack) {
                      //     return Text(e.toString());
                      //   }, loading: () {
                      //     return const Center(child: CircularProgressIndicator());
                      //   }),
                      // ),
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              color: kbgColor,
                              border: Border.all(color: kbgColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.S.of(context).grandTotal,
                                  style: theme.textTheme.titleMedium,
                                ),
                                // const Spacer(),
                                Text(
                                  '$globalCurrency ${myFormat.format(double.tryParse(dueAmount.toString()) ?? 0)}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              lang.S.of(context).payingAmount,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextFormField(
                              controller: payingAmountController,
                              onChanged: (value) {
                                setState(() {
                                  double paidAmount = double.parse(value);
                                  if (paidAmount > dueAmount) {
                                    changeAmountController.text = (paidAmount - dueAmount).toString();
                                    dueAmountController.text = '0';
                                  } else {
                                    dueAmountController.text = (dueAmount - paidAmount).abs().toString();
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
                            ),
                          )),
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              lang.S.of(context).changeAmount,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: changeAmountController,
                              cursorColor: kTitleColor,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: lang.S.of(context).changeAmount,
                              ),
                            ),
                          )),
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            lang.S.of(context).dueAmount,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: dueAmountController,
                              cursorColor: kTitleColor,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: lang.S.of(context).dueAmount,
                              ),
                            ),
                          ))
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              lang.S.of(context).paymentType,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 48,
                              child: FormField(
                                builder: (FormFieldState<dynamic> field) {
                                  return InputDecorator(
                                    decoration: const InputDecoration(),
                                    child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getOption())),
                                  );
                                },
                              ),
                            ),
                          ))
                    ]),
                    const SizedBox(height: 20.0),
                    ResponsiveGridRow(children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => GoRouter.of(context).pop(),
                                child: Text(
                                  lang.S.of(context).cancel,
                                )),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: settingProvider.when(data: (setting) {
                              return ElevatedButton(
                                onPressed: saleButtonClicked
                                    ? () {}
                                    : () async {
                                        if (dueAmount > 0 && !payingAmountController.text.isEmptyOrNull && payingAmountController.text.toInt() > 0) {
                                          try {
                                            setState(() {
                                              saleButtonClicked = true;
                                            });
                                            EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                            DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Due Transaction");

                                            dueTransactionModel.totalDue = dueAmount;
                                            dueTransactionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                                            dueAmountController.text.toDouble() <= 0 ? dueTransactionModel.isPaid = true : dueTransactionModel.isPaid = false;
                                            dueAmountController.text.toDouble() <= 0 ? {dueTransactionModel.dueAmountAfterPay = 0, dueTransactionModel.payDueAmount = dueAmount} : {dueTransactionModel.dueAmountAfterPay = dueAmountController.text.toDouble(), dueTransactionModel.payDueAmount = dueAmount - dueAmountController.text.toDouble()};

                                            dueTransactionModel.paymentType = selectedPaymentOption;
                                            dueTransactionModel.sendWhatsappMessage = widget.customerModel.receiveWhatsappUpdates;
                                            await ref.push().set(dueTransactionModel.toJson());

                                            await GeneratePdfAndPrint().printDueInvoice(personalInformationModel: data, dueTransactionModel: dueTransactionModel, setting: setting);

                                            ///_____UpdateInvoice__________________________________________________
                                            selectedInvoice != 'Select Invoice'
                                                ? updateDueInvoice(
                                                    type: widget.customerModel.type,
                                                    invoice: selectedInvoice.toString(),
                                                    remainDueAmount: dueAmountController.text.toInt(),
                                                  )
                                                : null;

                                            ///________daily_transactionModel_________________________________________________________________________

                                            if (dueTransactionModel.customerType == 'Supplier') {
                                              DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                                name: dueTransactionModel.customerName,
                                                date: dueTransactionModel.purchaseDate,
                                                type: 'Due Payment',
                                                total: dueTransactionModel.totalDue!.toDouble(),
                                                paymentIn: 0,
                                                paymentOut: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                id: dueTransactionModel.invoiceNumber,
                                                dueTransactionModel: dueTransactionModel,
                                              );
                                              postDailyTransaction(dailyTransactionModel: dailyTransaction);
                                            } else {
                                              DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                                name: dueTransactionModel.customerName,
                                                date: dueTransactionModel.purchaseDate,
                                                type: 'Due Collection',
                                                total: dueTransactionModel.totalDue!.toDouble(),
                                                paymentIn: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                paymentOut: 0,
                                                remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                id: dueTransactionModel.invoiceNumber,
                                                dueTransactionModel: dueTransactionModel,
                                              );
                                              postDailyTransaction(dailyTransactionModel: dailyTransaction);
                                            }

                                            ///_________DueUpdate______________________________________________________
                                            final cRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
                                            String? key;

                                            await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
                                              for (var element in value.children) {
                                                var data = jsonDecode(jsonEncode(element.value));
                                                if (data['phoneNumber'] == widget.customerModel.phoneNumber) {
                                                  key = element.key;
                                                }
                                              }
                                            });
                                            var data1 = await cRef.child('$key/due').get();
                                            var data2 = await cRef.child('$key/remainedBalance').get();
                                            int previousDue = data1.value.toString().toInt();
                                            int remainedBalance = data2.value.toString().toInt();

                                            int totalDue = previousDue - dueTransactionModel.payDueAmount!.toInt();
                                            int remainedDue = remainedBalance - dueTransactionModel.payDueAmount!.toInt();
                                            cRef.child(key!).update({'due': '$totalDue'});
                                            selectedInvoice == 'Select Invoice' ? cRef.child(key!).update({'remainedBalance': '$remainedDue'}) : null;

                                            ///_________Invoice Increase____________________________________________________________________________
                                            updateInvoice(
                                              typeOfInvoice: 'dueInvoiceCounter',
                                              invoice: data.dueInvoiceCounter.toInt(),
                                            );

                                            ///________Subscription_____________________________________________________
                                            Subscription.decreaseSubscriptionLimits(itemType: 'dueNumber', context: context);

                                            consumerRef.refresh(allCustomerProvider);
                                            consumerRef.refresh(transitionProvider);
                                            consumerRef.refresh(purchaseTransitionProvider);
                                            consumerRef.refresh(dueTransactionProvider);
                                            consumerRef.refresh(profileDetailsProvider);
                                            consumerRef.refresh(dailyTransactionProvider);

                                            finish(context);
                                            EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully);
                                          } catch (e) {
                                            setState(() {
                                              saleButtonClicked = false;
                                            });
                                            EasyLoading.dismiss();
                                            //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                          }
                                        } else if (dueAmount <= 0) {
                                          // EasyLoading.showError('Select a Invoice');
                                          EasyLoading.showError(lang.S.of(context).selectAInvoice);
                                        } else if (payingAmountController.text.isEmptyOrNull || payingAmountController.text.toInt() <= 0) {
                                          //EasyLoading.showError('Please Enter Amount');
                                          EasyLoading.showError(lang.S.of(context).pleaseEnterAmount);
                                        }
                                      },
                                child: Text(
                                  lang.S.of(context).submit,
                                  style: kTextStyle.copyWith(color: kWhite),
                                ),
                              );
                            }, error: (e, stack) {
                              return Text(e.toString());
                            }, loading: () {
                              return CircularProgressIndicator();
                            }),
                          ))
                    ]),
                    // Row(
                    //   mainAxisSize: MainAxisSize.max,
                    //   mainAxisAlignment: MainAxisAlignment.center,
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
                    //         )).onTap(() => {
                    //           finish(context),
                    //         }),
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
                    //               if (dueAmount > 0 && !payingAmountController.text.isEmptyOrNull && payingAmountController.text.toInt() > 0) {
                    //                 try {
                    //                   setState(() {
                    //                     saleButtonClicked = true;
                    //                   });
                    //                   EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                    //                   DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Due Transaction");
                    //
                    //                   dueTransactionModel.totalDue = dueAmount;
                    //                   dueTransactionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                    //                   dueAmountController.text.toDouble() <= 0 ? dueTransactionModel.isPaid = true : dueTransactionModel.isPaid = false;
                    //                   dueAmountController.text.toDouble() <= 0
                    //                       ? {dueTransactionModel.dueAmountAfterPay = 0, dueTransactionModel.payDueAmount = dueAmount}
                    //                       : {
                    //                           dueTransactionModel.dueAmountAfterPay = dueAmountController.text.toDouble(),
                    //                           dueTransactionModel.payDueAmount = dueAmount - dueAmountController.text.toDouble()
                    //                         };
                    //
                    //                   dueTransactionModel.paymentType = selectedPaymentOption;
                    //                   dueTransactionModel.sendWhatsappMessage = widget.customerModel.receiveWhatsappUpdates;
                    //                   await ref.push().set(dueTransactionModel.toJson());
                    //
                    //                   await GeneratePdfAndPrint().printDueInvoice(personalInformationModel: data, dueTransactionModel: dueTransactionModel);
                    //
                    //                   ///_____UpdateInvoice__________________________________________________
                    //                   selectedInvoice != 'Select Invoice'
                    //                       ? updateDueInvoice(
                    //                           type: widget.customerModel.type,
                    //                           invoice: selectedInvoice.toString(),
                    //                           remainDueAmount: dueAmountController.text.toInt(),
                    //                         )
                    //                       : null;
                    //
                    //                   ///________daily_transactionModel_________________________________________________________________________
                    //
                    //                   if (dueTransactionModel.customerType == 'Supplier') {
                    //                     DailyTransactionModel dailyTransaction = DailyTransactionModel(
                    //                       name: dueTransactionModel.customerName,
                    //                       date: dueTransactionModel.purchaseDate,
                    //                       type: 'Due Payment',
                    //                       total: dueTransactionModel.totalDue!.toDouble(),
                    //                       paymentIn: 0,
                    //                       paymentOut: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       id: dueTransactionModel.invoiceNumber,
                    //                       dueTransactionModel: dueTransactionModel,
                    //                     );
                    //                     postDailyTransaction(dailyTransactionModel: dailyTransaction);
                    //                   } else {
                    //                     DailyTransactionModel dailyTransaction = DailyTransactionModel(
                    //                       name: dueTransactionModel.customerName,
                    //                       date: dueTransactionModel.purchaseDate,
                    //                       type: 'Due Collection',
                    //                       total: dueTransactionModel.totalDue!.toDouble(),
                    //                       paymentIn: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       paymentOut: 0,
                    //                       remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       id: dueTransactionModel.invoiceNumber,
                    //                       dueTransactionModel: dueTransactionModel,
                    //                     );
                    //                     postDailyTransaction(dailyTransactionModel: dailyTransaction);
                    //                   }
                    //
                    //                   ///_________DueUpdate______________________________________________________
                    //                   final cRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
                    //                   String? key;
                    //
                    //                   await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
                    //                     for (var element in value.children) {
                    //                       var data = jsonDecode(jsonEncode(element.value));
                    //                       if (data['phoneNumber'] == widget.customerModel.phoneNumber) {
                    //                         key = element.key;
                    //                       }
                    //                     }
                    //                   });
                    //                   var data1 = await cRef.child('$key/due').get();
                    //                   var data2 = await cRef.child('$key/remainedBalance').get();
                    //                   int previousDue = data1.value.toString().toInt();
                    //                   int remainedBalance = data2.value.toString().toInt();
                    //
                    //                   int totalDue = previousDue - dueTransactionModel.payDueAmount!.toInt();
                    //                   int remainedDue = remainedBalance - dueTransactionModel.payDueAmount!.toInt();
                    //                   cRef.child(key!).update({'due': '$totalDue'});
                    //                   selectedInvoice == 'Select Invoice' ? cRef.child(key!).update({'remainedBalance': '$remainedDue'}) : null;
                    //
                    //                   ///_________Invoice Increase____________________________________________________________________________
                    //                   updateInvoice(
                    //                     typeOfInvoice: 'dueInvoiceCounter',
                    //                     invoice: data.dueInvoiceCounter.toInt(),
                    //                   );
                    //
                    //                   ///________Subscription_____________________________________________________
                    //                   Subscription.decreaseSubscriptionLimits(itemType: 'dueNumber', context: context);
                    //
                    //                   consumerRef.refresh(allCustomerProvider);
                    //                   consumerRef.refresh(transitionProvider);
                    //                   consumerRef.refresh(purchaseTransitionProvider);
                    //                   consumerRef.refresh(dueTransactionProvider);
                    //                   consumerRef.refresh(profileDetailsProvider);
                    //                   consumerRef.refresh(dailyTransactionProvider);
                    //
                    //                   finish(context);
                    //                   EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully);
                    //                 } catch (e) {
                    //                   setState(() {
                    //                     saleButtonClicked = false;
                    //                   });
                    //                   EasyLoading.dismiss();
                    //                   //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    //                 }
                    //               } else if (dueAmount <= 0) {
                    //                 // EasyLoading.showError('Select a Invoice');
                    //                 EasyLoading.showError(lang.S.of(context).selectAInvoice);
                    //               } else if (payingAmountController.text.isEmptyOrNull || payingAmountController.text.toInt() <= 0) {
                    //                 //EasyLoading.showError('Please Enter Amount');
                    //                 EasyLoading.showError(lang.S.of(context).pleaseEnterAmount);
                    //               }
                    //             },
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
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

  void updateDueInvoice({required String type, required String invoice, required int remainDueAmount}) async {
    final ref = type == 'Supplier' ? FirebaseDatabase.instance.ref('${await getUserID()}/Purchase Transition/') : FirebaseDatabase.instance.ref('${await getUserID()}/Sales Transition/');
    String? key;

    type == 'Supplier'
        ? await FirebaseDatabase.instance.ref(await getUserID()).child('Purchase Transition/').orderByKey().get().then((value) {
            for (var element in value.children) {
              var data = jsonDecode(jsonEncode(element.value));
              if (data['invoiceNumber'] == invoice) {
                key = element.key;
              }
            }
          })
        : await FirebaseDatabase.instance.ref(await getUserID()).child('Sales Transition').orderByKey().get().then((value) {
            for (var element in value.children) {
              var data = jsonDecode(jsonEncode(element.value));
              if (data['invoiceNumber'] == invoice) {
                key = element.key;
              }
            }
          });
    ref.child(key!).update({
      'dueAmount': '$remainDueAmount',
    });
  }
}
