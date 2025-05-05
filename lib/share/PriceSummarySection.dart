import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/Screen/tax%20rates/tax_model.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

class PriceSummarySection extends StatelessWidget {
  final int itemCount;
  final double totalAmount;
  final double serviceCharge;
  final double discountAmount;
  final List<TaxModel> taxes;
  final String currency;
  final Function(double) onServiceChargeChanged;
  final Function(double) onDiscountAmountChanged;
  final Function(double) onDiscountPercentageChanged;
  final VoidCallback onCancel;
  final VoidCallback onCreateQuotation;
  final VoidCallback onProceedToPayment;

  const PriceSummarySection({
    super.key,
    required this.itemCount,
    required this.totalAmount,
    required this.serviceCharge,
    required this.discountAmount,
    required this.taxes,
    required this.currency,
    required this.onServiceChargeChanged,
    required this.onDiscountAmountChanged,
    required this.onDiscountPercentageChanged,
    required this.onCancel,
    required this.onCreateQuotation,
    required this.onProceedToPayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ///__________total__________________________________________
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: Padding(
                padding: EdgeInsets.only(bottom: screenWidth < 577 ? 12 : 0),
                child: Text(
                  'Total Item: $itemCount',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            ResponsiveGridCol(
                xs: 12,
                md: 6,
                lg: 6,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        'Sub Total',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          fixedSize: Size(screenWidth, 40),
                        ),
                        onPressed: () {},
                        child: Text(
                          '$currency ${myFormat.format((totalAmount + serviceCharge - discountAmount))}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ))
          ]),
          const SizedBox(height: 10.0),

          ///_________Taxes__________________________________________
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: const SizedBox.shrink(),
            ),
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: SizedBox(
                child: ListView.builder(
                  itemCount: taxes.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Container(
                      height: 40,
                      margin: const EdgeInsets.only(top: 5, bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              taxes[index].name,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Flexible(
                            child: SizedBox(
                              height: 40.0,
                              child: Center(
                                child: AppTextField(
                                  initialValue: taxes[index].taxRate.toString(),
                                  readOnly: true,
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.only(right: 6.0),
                                    hintText: '0',
                                    border: const OutlineInputBorder(
                                        gapPadding: 0.0,
                                        borderSide: BorderSide(
                                            color: Color(0xFFff5f00))),
                                    enabledBorder: const OutlineInputBorder(
                                        gapPadding: 0.0,
                                        borderSide: BorderSide(
                                            color: Color(0xFFff5f00))),
                                    disabledBorder: const OutlineInputBorder(
                                        gapPadding: 0.0,
                                        borderSide: BorderSide(
                                            color: Color(0xFFff5f00))),
                                    focusedBorder: const OutlineInputBorder(
                                        gapPadding: 0.0,
                                        borderSide: BorderSide(
                                            color: Color(0xFFff5f00))),
                                    prefixIconConstraints: const BoxConstraints(
                                        maxWidth: 30.0, minWidth: 30.0),
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.only(
                                          top: 8.0, left: 8.0),
                                      height: 40,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFff5f00),
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(4.0),
                                              bottomLeft:
                                                  Radius.circular(4.0))),
                                      child: const Text(
                                        '%',
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  textFieldType: TextFieldType.NUMBER,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10.0),

          ///__________service/shipping_____________________________
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: const SizedBox.shrink(),
            ),
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        lang.S.of(context).shpingOrServices,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Flexible(
                      child: SizedBox(
                        width: screenWidth,
                        height: 40,
                        child: TextFormField(
                          initialValue: serviceCharge.toString(),
                          onChanged: (value) =>
                              onServiceChargeChanged(value.toDouble()),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter Amount',
                            contentPadding: EdgeInsets.all(7.0),
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10.0),

          ///________discount_________________________________________________
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: const SizedBox.shrink(),
            ),
            ResponsiveGridCol(
              xs: 12,
              md: 6,
              lg: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      lang.S.of(context).discount,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: 40.0,
                            child: AppTextField(
                              onChanged: (value) =>
                                  onDiscountPercentageChanged(value.toDouble()),
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.only(right: 6.0),
                                hintText: '0',
                                border: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide:
                                        BorderSide(color: Color(0xFFff5f00))),
                                enabledBorder: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide:
                                        BorderSide(color: Color(0xFFff5f00))),
                                disabledBorder: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide:
                                        BorderSide(color: Color(0xFFff5f00))),
                                focusedBorder: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide:
                                        BorderSide(color: Color(0xFFff5f00))),
                                prefixIconConstraints: const BoxConstraints(
                                    maxWidth: 30.0, minWidth: 30.0),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 8.0),
                                  height: 40,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFff5f00),
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4.0),
                                          bottomLeft: Radius.circular(4.0))),
                                  child: const Text(
                                    '%',
                                    style: TextStyle(
                                        fontSize: 20.0, color: Colors.white),
                                  ),
                                ),
                              ),
                              textFieldType: TextFieldType.NUMBER,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: SizedBox(
                            height: 40.0,
                            child: AppTextField(
                              initialValue: discountAmount.toString(),
                              onChanged: (value) =>
                                  onDiscountAmountChanged(value.toDouble()),
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.only(right: 6.0),
                                hintText: '0',
                                border: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide: BorderSide(color: kMainColor)),
                                enabledBorder: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide: BorderSide(color: kMainColor)),
                                disabledBorder: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide: BorderSide(color: kMainColor)),
                                focusedBorder: const OutlineInputBorder(
                                    gapPadding: 0.0,
                                    borderSide: BorderSide(color: kMainColor)),
                                prefixIconConstraints: const BoxConstraints(
                                    maxWidth: 30.0, minWidth: 30.0),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 8.0),
                                  height: 40,
                                  decoration: const BoxDecoration(
                                      color: kMainColor,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4.0),
                                          bottomLeft: Radius.circular(4.0))),
                                  child: Text(
                                    currency,
                                    style: const TextStyle(
                                        fontSize: 20.0, color: Colors.white),
                                  ),
                                ),
                              ),
                              textFieldType: TextFieldType.NUMBER,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20.0),

          ///____________buttons____________________________________________________
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
                xs: 6,
                md: 4,
                lg: 4,
                child: Padding(
                  padding: EdgeInsets.only(
                      right: 12, bottom: screenWidth < 577 ? 12 : 0),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: onCancel,
                    child: Text(lang.S.of(context).cancel),
                  ),
                )),
            ResponsiveGridCol(
                xs: 6,
                md: 4,
                lg: 4,
                child: Padding(
                  padding: EdgeInsets.only(
                      right: screenWidth < 577 ? 0 : 12,
                      bottom: screenWidth < 577 ? 12 : 0),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: onCreateQuotation,
                    child: Text(lang.S.of(context).quotation),
                  ),
                )),
            ResponsiveGridCol(
                xs: 12,
                md: 4,
                lg: 4,
                child: Padding(
                  padding: EdgeInsets.only(
                      right: screenWidth < 577 ? 0 : 12,
                      bottom: screenWidth < 577 ? 12 : 0),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: kMainColor),
                    onPressed: onProceedToPayment,
                    child: Text(lang.S.of(context).payment),
                  ),
                )),
          ]),
        ],
      ),
    );
  }
}
