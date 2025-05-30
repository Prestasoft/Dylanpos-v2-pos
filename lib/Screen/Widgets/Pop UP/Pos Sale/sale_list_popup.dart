import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../currency/currency_provider.dart';
import '../../Constant Data/constant.dart';

class SaleListPopUP extends StatefulWidget {
  const SaleListPopUP({Key? key}) : super(key: key);

  @override
  State<SaleListPopUP> createState() => _SaleListPopUPState();
}

class _SaleListPopUPState extends State<SaleListPopUP> {
  List<String> userId2 = [
    'Select Customer',
    'Shahidul\n017XXXXXXXX',
    'Prince\n017XXXXXXXX',
    'Alif\n017XXXXXXXX',
  ];
  String selectedUserId2 = 'Select Customer';

  DropdownButton<String> getResult2() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in userId2) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedUserId2,
      onChanged: (value) {
        setState(() {
          selectedUserId2 = value!;
        });
      },
    );
  }

  DateTime selectedSaleDate = DateTime.now();

  Future<void> _selectedSaleDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedSaleDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedSaleDate) {
      setState(() {
        selectedSaleDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    return SizedBox(
      width: 1000,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  lang.S.of(context).yourAllSales,
                  style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 20.0),
                ),
                const Spacer(),
                const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {finish(context)})
              ],
            ),
          ),
          const Divider(thickness: 1.0, color: kLitGreyColor),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FormField(
                    builder: (FormFieldState<dynamic> field) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                          suffixIcon: Icon(FeatherIcons.calendar, color: kTitleColor, size: 18.0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                          ),
                          contentPadding: EdgeInsets.all(8.0),
                        ),
                        child: Text(
                          selectedSaleDate.day.toString() + '/' + selectedSaleDate.month.toString() + '/' + selectedSaleDate.year.toString(),
                          style: kTextStyle.copyWith(color: kTitleColor),
                        ),
                      );
                    },
                  ).onTap(() => _selectedSaleDate(context)),
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  flex: 2,
                  child: FormField(
                    builder: (FormFieldState<dynamic> field) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                            ),
                            contentPadding: EdgeInsets.all(5.0)),
                        child: DropdownButtonHideUnderline(child: getResult2()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    showCursor: true,
                    cursorColor: kTitleColor,
                    textFieldType: TextFieldType.NAME,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(10.0),
                      suffixIcon: const Icon(
                        FeatherIcons.search,
                        color: kTitleColor,
                      ),
                      hintText: (lang.S.of(context).invoiceHint),
                      hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                      border: InputBorder.none,
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: const BoxDecoration(color: kDarkWhite, border: Border(bottom: BorderSide(width: 1.0, color: kTitleColor))),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 100,
                                    child: Text(
                                      lang.S.of(context).invoiceNo,
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                      maxLines: 2,
                                    )),
                                SizedBox(
                                    width: 180,
                                    child: Text(
                                      lang.S.of(context).customer,
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                      maxLines: 2,
                                    )),
                                SizedBox(
                                    width: 150,
                                    child: Text(
                                      lang.S.of(context).dateTime,
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                      maxLines: 2,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                          itemCount: 5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '000958',
                                      style: kTextStyle.copyWith(color: kTitleColor),
                                      maxLines: 2,
                                    ),
                                  ),
                                  SizedBox(
                                      width: 180,
                                      child: Text(
                                        lang.S.of(context).walkInCustomer,
                                        style: kTextStyle.copyWith(color: kTitleColor),
                                        maxLines: 2,
                                      )),
                                  SizedBox(
                                      width: 150,
                                      child: Text(
                                        '2022-06-27 22:41:13',
                                        style: kTextStyle.copyWith(color: kTitleColor),
                                        maxLines: 2,
                                      )),
                                ],
                              ),
                            );
                          })
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: kWhite,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Center(
                                child: Text(
                              lang.S.of(context).saleDetails,
                              textAlign: TextAlign.center,
                              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                            )),
                            Text(
                              lang.S.of(context).customerWalkIncostomer,
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              'Phone: 017XXXXXXXX',
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                            const SizedBox(height: 5.0),
                            Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: const BoxDecoration(color: kDarkWhite, border: Border(bottom: BorderSide(width: 1.0, color: kTitleColor))),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                          width: 120,
                                          child: Text(
                                            lang.S.of(context).item,
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                            maxLines: 2,
                                          )),
                                      SizedBox(
                                          width: 110,
                                          child: Text(
                                            lang.S.of(context).price,
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                            maxLines: 2,
                                          )),
                                      SizedBox(
                                          width: 80,
                                          child: Text(
                                            lang.S.of(context).QTY,
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                            maxLines: 2,
                                          )),
                                      SizedBox(
                                          width: 100,
                                          child: Text(
                                            lang.S.of(context).total,
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                            maxLines: 2,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                                itemCount: 5,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (_, i) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            lang.S.of(context).camera,
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                            maxLines: 2,
                                          ),
                                        ),
                                        SizedBox(
                                            width: 110,
                                            child: Text(
                                              '$globalCurrency 2800.00',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                              maxLines: 2,
                                            )),
                                        SizedBox(
                                            width: 80,
                                            child: Text(
                                              '1',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                              maxLines: 2,
                                            )),
                                        SizedBox(
                                            width: 100,
                                            child: Text(
                                              '2800.00 tk',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                              maxLines: 2,
                                            )),
                                      ],
                                    ),
                                  );
                                }),
                            const SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  lang.S.of(context).totalItem2,
                                  style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    lang.S.of(context).subTotal,
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    '2800.00 Tk',
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    lang.S.of(context).shipingOrOther,
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    '0.00 Tk',
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              thickness: 1.0,
                              color: kLitGreyColor,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    lang.S.of(context).totalPayable,
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    '2800.00 Tk',
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    lang.S.of(context).paidAmount,
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    '2800.00 Tk',
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    lang.S.of(context).dueAmount,
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    '$globalCurrency 0.00',
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kRedTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).cancel,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    )).onTap(() => {finish(context)}),
                                const SizedBox(width: 10.0),
                                Container(
                                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kBlueTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).print,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    )).onTap(() => {finish(context)})
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
