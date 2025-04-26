// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/responsive.dart' as res;

import '../../Provider/profile_provider.dart';
import '../../model/personal_information_model.dart';
import '../../model/purchase_transation_model.dart';
import '../currency/currency_provider.dart';

class PurchaseInvoice extends StatefulWidget {
  const PurchaseInvoice({Key? key, required this.transitionModel, required this.personalInformationModel, required this.isPurchase}) : super(key: key);
  final PurchaseTransactionModel transitionModel;
  final PersonalInformationModel personalInformationModel;
  final bool isPurchase;

  @override
  State<PurchaseInvoice> createState() => _PurchaseInvoiceState();
}

class _PurchaseInvoiceState extends State<PurchaseInvoice> {
  String getTotalAmount() {
    double total = 0.0;
    for (var item in widget.transitionModel.productList!) {
      total = total + (double.parse(item.productPurchasePrice) * item.productStock.toInt());
    }
    return total.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    return Scaffold(
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), color: kRedTextColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FeatherIcons.x,
                    color: kWhite,
                    size: 25,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    lang.S.of(context).cancel,
                    style: kTextStyle.copyWith(color: kWhite, fontSize: 20.0),
                  ),
                ],
              ),
            ).onTap(() => widget.isPurchase
                ? context.go('/purchase')
                // Navigator.pushAndRemoveUntil<dynamic>(
                //         context,
                //         MaterialPageRoute<dynamic>(
                //           builder: (BuildContext context) => const Purchase(),
                //         ),
                //         (route) => false, //if you want to disable back feature set to false
                //       )
                : GoRouter.of(context).pop()),
            const SizedBox(width: 20.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), color: kRedTextColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    MdiIcons.printer,
                    color: kWhite,
                    size: 25,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    lang.S.of(context).printInvoice,
                    style: kTextStyle.copyWith(color: kWhite, fontSize: 20.0),
                  ),
                ],
              ),
            ).onTap(() => window.print()),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        backgroundColor: kWhite,
        body: res.Responsive(
          mobile: Container(),
          tablet: Container(),
          // tablet:
          //     TabletPurchaseInvoice(personalInformationModel: widget.personalInformationModel, transitionModel: widget.transitionModel, isTabPurchase: true),
          desktop: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Consumer(
              builder: (_, ref, watch) {
                final personalInfo = ref.watch(profileDetailsProvider);
                return personalInfo.when(data: (personalInfo) {
                  return SizedBox(
                    width: 700,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.personalInformationModel.companyName.toString(),
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                  ),
                                  Text(
                                    widget.personalInformationModel.countryName.toString(),
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                  Text(
                                    widget.personalInformationModel.phoneNumber.toString(),
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                  Text(
                                    widget.personalInformationModel.countryName.toString(),
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  image: DecorationImage(image: NetworkImage(widget.personalInformationModel.pictureUrl.toString()), fit: BoxFit.fill),
                                ),
                              )
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            lang.S.of(context).INVOICE,
                            style: kTextStyle.copyWith(color: kRedTextColor, fontWeight: FontWeight.bold, fontSize: 30.0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.S.of(context).billTo,
                                style: kTextStyle.copyWith(color: kTitleColor),
                              ),
                              Row(
                                children: [
                                  Text(
                                    widget.transitionModel.customerName,
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${lang.S.of(context).invoice}# ${widget.transitionModel.invoiceNumber}',
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    widget.transitionModel.customerType.toString(),
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${lang.S.of(context).date}:${widget.transitionModel.purchaseDate.substring(0, 10)}',
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${lang.S.of(context).phone}:${widget.transitionModel.customerPhone}',
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${lang.S.of(context).dueDate}:${widget.transitionModel.purchaseDate.substring(0, 10)}',
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(kRedTextColor),
                            showBottomBorder: false,
                            headingTextStyle: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                            horizontalMargin: null,
                            dividerThickness: 0,
                            headingRowHeight: 30.0,
                            dataRowHeight: 25.0,
                            columns: [
                              DataColumn(
                                label: Text(
                                  lang.S.of(context).product,
                                ),
                              ),
                              DataColumn(
                                label: Text(lang.S.of(context).quantity),
                              ),
                              DataColumn(
                                label: Text(lang.S.of(context).unitPrice),
                              ),
                              DataColumn(
                                label: Text(lang.S.of(context).totalPrice),
                              ),
                            ],
                            rows: List.generate(
                                widget.transitionModel.productList?.length ?? 0,
                                (index) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(widget.transitionModel.productList?[index].productName ?? ''),
                                        ),
                                        DataCell(
                                          Text(widget.transitionModel.productList?[index].productStock.toString() ?? ''),
                                        ),
                                        DataCell(
                                          Text('$globalCurrency ${widget.transitionModel.productList?[index].productPurchasePrice ?? ''}'),
                                        ),
                                        DataCell(
                                          Text('$globalCurrency ${double.parse(widget.transitionModel.productList![index].productPurchasePrice) * widget.transitionModel.productList![index].productStock.toDouble()}'),
                                        ),
                                      ],
                                    )),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.S.of(context).subTotal,
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kGreyTextColor),
                                  ),
                                  const SizedBox(width: 20.0),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$globalCurrency ${getTotalAmount()}',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.S.of(context).totalVat,
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kGreyTextColor),
                                  ),
                                  const SizedBox(width: 20.0),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$globalCurrency 0.00',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.S.of(context).totalDiscount,
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kGreyTextColor),
                                  ),
                                  const SizedBox(width: 20.0),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$globalCurrency ${widget.transitionModel.discountAmount}',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.S.of(context).deliveryCharge,
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kGreyTextColor),
                                  ),
                                  const SizedBox(width: 20.0),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$globalCurrency 0.00',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 250,
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: const BoxDecoration(color: kRedTextColor),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            lang.S.of(context).totalPayable,
                                            maxLines: 1,
                                            style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 20.0),
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              '$globalCurrency ${widget.transitionModel.totalAmount}',
                                              maxLines: 2,
                                              style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.S.of(context).paid,
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kGreyTextColor),
                                  ),
                                  const SizedBox(width: 20.0),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$globalCurrency ${widget.transitionModel.totalAmount! - widget.transitionModel.dueAmount!.toDouble()}',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.S.of(context).due,
                                    maxLines: 1,
                                    style: kTextStyle.copyWith(color: kGreyTextColor),
                                  ),
                                  const SizedBox(width: 20.0),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$globalCurrency ${widget.transitionModel.dueAmount}',
                                      maxLines: 2,
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
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
            ),
          ),
        ));
  }
}
