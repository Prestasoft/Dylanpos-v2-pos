import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class LossProfitScreen extends StatefulWidget {
  const LossProfitScreen({
    super.key,
  });

  static const String route = '/Loss_Profit';

  @override
  State<LossProfitScreen> createState() => _LossProfitScreenState();
}

class _LossProfitScreenState extends State<LossProfitScreen> {
  void showLossProfitDetails({required SaleTransactionModel transitionModel}) {
    double parseDouble(String value) {
      return double.tryParse(value) ?? 0.0;
    }

    String formatDouble(double value) {
      return myFormat.format(value);
    }

    double profit({required AddToCartModel productModel}) {
      if (productModel.taxType == 'Exclusive') {
        return (parseDouble(productModel.subTotal.toString()) -
                (parseDouble(productModel.productPurchasePrice.toString()) +
                    calculateAmountFromPercentage(
                        parseDouble(productModel.groupTaxRate.toString()),
                        parseDouble(
                            productModel.productPurchasePrice.toString())))) *
            productModel.quantity.toDouble();
      } else {
        return (parseDouble(productModel.subTotal.toString()) -
                parseDouble(productModel.productPurchasePrice.toString())) *
            productModel.quantity.toDouble();
      }
    }

    double allProductTotalProfit(
        {required SaleTransactionModel transitionModel}) {
      double profit = 0;
      for (var element in transitionModel.productList!) {
        if (element.taxType == 'Exclusive') {
          ((parseDouble(element.subTotal.toString()) -
                          (parseDouble(
                                  element.productPurchasePrice.toString()) +
                              calculateAmountFromPercentage(
                                  parseDouble(element.groupTaxRate.toString()),
                                  parseDouble(element.productPurchasePrice
                                      .toString())))) *
                      element.quantity.toDouble())
                  .isNegative
              ? null
              : profit += (parseDouble(element.subTotal.toString()) -
                      (parseDouble(element.productPurchasePrice.toString()) +
                          calculateAmountFromPercentage(
                              parseDouble(element.groupTaxRate.toString()),
                              parseDouble(
                                  element.productPurchasePrice.toString())))) *
                  element.quantity.toDouble();
        } else {
          ((parseDouble(element.subTotal.toString()) -
                          parseDouble(
                              element.productPurchasePrice.toString())) *
                      element.quantity.toDouble())
                  .isNegative
              ? null
              : profit += (parseDouble(element.subTotal.toString()) -
                      parseDouble(element.productPurchasePrice.toString())) *
                  element.quantity.toDouble();
        }
      }
      return profit;
    }

    double allProductTotalLoss(
        {required SaleTransactionModel transitionModel}) {
      double loss = 0;

      for (var element in transitionModel.productList!) {
        if (element.taxType == 'Exclusive') {
          ((parseDouble(element.subTotal.toString()) -
                          parseDouble(element.productPurchasePrice.toString()) +
                          calculateAmountFromPercentage(
                              parseDouble(element.groupTaxRate.toString()),
                              parseDouble(
                                  element.productPurchasePrice.toString()))) *
                      element.quantity.toDouble())
                  .isNegative
              ? loss += ((parseDouble(element.subTotal.toString()) -
                          (parseDouble(
                                  element.productPurchasePrice.toString()) +
                              calculateAmountFromPercentage(
                                  parseDouble(element.groupTaxRate.toString()),
                                  parseDouble(element.productPurchasePrice
                                      .toString())))) *
                      element.quantity.toDouble())
                  .abs()
              : null;
        } else {
          ((parseDouble(element.subTotal.toString()) -
                          parseDouble(
                              element.productPurchasePrice.toString())) *
                      element.quantity.toDouble())
                  .isNegative
              ? loss += ((parseDouble(element.subTotal.toString()) -
                          parseDouble(
                              element.productPurchasePrice.toString())) *
                      element.quantity.toDouble())
                  .abs()
              : null;
        }
      }
      return loss;
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
        final globalCurrency = currencyProvider.currency ?? '\$';
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              surfaceTintColor: kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: SizedBox(
                width: 820,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${lang.S.of(context).invoice}: ${transitionModel.invoiceNumber} - ${transitionModel.customerName}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          IconButton(
                              onPressed: () {
                                GoRouter.of(context).pop();
                              },
                              icon: const Icon(FeatherIcons.x, size: 20.0))
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      color: kNeutral300,
                      height: 1,
                    ),
                    const SizedBox(height: 10.0),
                    LayoutBuilder(
                      builder: (context, constrains) {
                        return Scrollbar(
                          controller: _horizontalScroll,
                          thumbVisibility: true,
                          radius: const Radius.circular(8),
                          thickness: 8,
                          child: SingleChildScrollView(
                            controller: _horizontalScroll,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constrains.maxWidth,
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                  dividerTheme: const DividerThemeData(
                                      color: Colors.transparent),
                                ),
                                child: DataTable(
                                  border: const TableBorder(
                                    horizontalInside: BorderSide(
                                      width: 1,
                                      color: kNeutral300,
                                    ),
                                  ),
                                  dataRowColor: const WidgetStatePropertyAll(
                                      Colors.white),
                                  headingRowColor: WidgetStateProperty.all(
                                      const Color(0xFFF8F3FF)),
                                  showBottomBorder: false,
                                  dividerThickness: 0.0,
                                  headingTextStyle:
                                      Theme.of(context).textTheme.titleMedium,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        lang.S.of(context).itemName,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(lang.S.of(context).quantity),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        lang.S.of(context).purchase,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        lang.S.of(context).salePrice,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        lang.S.of(context).profit,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(lang.S.of(context).loss),
                                    ),
                                  ],
                                  rows: List.generate(
                                    transitionModel.productList!.length + 1,
                                    (index) => DataRow(cells: [
                                      DataCell(
                                        index ==
                                                transitionModel
                                                    .productList!.length
                                            ? Text(
                                                lang.S.of(context).total,
                                              )
                                            : Text(
                                                transitionModel
                                                    .productList![index]
                                                    .productName
                                                    .toString(),
                                              ),
                                      ),
                                      DataCell(
                                        index ==
                                                transitionModel
                                                    .productList!.length
                                            ? Text(transitionModel.totalQuantity
                                                .toString())
                                            : Text(
                                                transitionModel
                                                    .productList![index]
                                                    .quantity
                                                    .toString(),
                                              ),
                                      ),
                                      DataCell(
                                        index ==
                                                transitionModel
                                                    .productList!.length
                                            ? const Text('')
                                            : Text(
                                                "$globalCurrency${formatDouble(parseDouble(transitionModel.productList![index].productPurchasePrice.toString()))}",
                                              ),
                                      ),
                                      DataCell(
                                        index ==
                                                transitionModel
                                                    .productList!.length
                                            ? const Text('')
                                            : Text(
                                                "$globalCurrency${formatDouble(parseDouble(transitionModel.productList![index].subTotal.toString()))}",
                                              ),
                                      ),
                                      DataCell(
                                        index ==
                                                transitionModel
                                                    .productList!.length
                                            ? Text(
                                                "$globalCurrency${formatDouble(allProductTotalProfit(transitionModel: transitionModel))}",
                                              )
                                            : Text(
                                                profit(
                                                            productModel:
                                                                transitionModel
                                                                        .productList![
                                                                    index])
                                                        .isNegative
                                                    ? ''
                                                    : "$globalCurrency${formatDouble(profit(productModel: transitionModel.productList![index]))}",
                                              ),
                                      ),
                                      DataCell(
                                        index ==
                                                transitionModel
                                                    .productList!.length
                                            ? Text(
                                                "$globalCurrency${formatDouble(allProductTotalLoss(transitionModel: transitionModel))}",
                                              )
                                            : Text(
                                                profit(
                                                            productModel:
                                                                transitionModel
                                                                        .productList![
                                                                    index])
                                                        .isNegative
                                                    ? "$globalCurrency${formatDouble(profit(productModel: transitionModel.productList![index]).abs())}"
                                                    : '',
                                              ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).totalProfit,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                "$globalCurrency${formatDouble(allProductTotalProfit(transitionModel: transitionModel))}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).totalLoss,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                '$globalCurrency${formatDouble(allProductTotalLoss(transitionModel: transitionModel))}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).totalDiscount,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                '$globalCurrency${transitionModel.discountAmount}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // border: Border.all(width: 1, color: Colors.green),
                        color: transitionModel.lossProfit!.isNegative
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : kMainColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transitionModel.lossProfit!.isNegative
                                  ? lang.S.of(context).totalLoss
                                  : lang.S.of(context).totalProfit,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              "$globalCurrency${formatDouble(transitionModel.lossProfit!.abs())}",
                              style: Theme.of(context).textTheme.titleMedium,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double calculateTotalProfit(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      element.lossProfit!.isNegative ? null : total += element.lossProfit!;
    }
    return total;
  }

  double getTotalDue(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      total += element.dueAmount!;
    }
    return total;
  }

  double calculateTotalSale(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      total += element.totalAmount!;
    }
    return total;
  }

  double calculateTotalLoss(List<SaleTransactionModel> transitionModel) {
    double total = 0.0;
    for (var element in transitionModel) {
      element.lossProfit!.isNegative ? total += element.lossProfit! : null;
    }
    return total.abs();
  }

  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime selected2ndDate = DateTime.now();

  Future<void> _selectedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selected2ndDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selected2ndDate) {
      setState(() {
        selected2ndDate = picked;
      });
    }
  }

  ScrollController mainScroll = ScrollController();

  List<String> get month => [
        'This Month',
        // lang.S.current.thisMonth,
        'Last Month',
        // lang.S.current.lastMonth,
        'Last 6 Month',
        // lang.S.current.last6Month,
        'This Year',
        // lang.S.current.thisYear,
      ];

  late String selectedMonth = month.first;

  DropdownButton<String> getMonth() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in month) {
      var item = DropdownMenuItem(
        value: des,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            des,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      isExpanded: true,
      items: dropDownItems,
      value: selectedMonth,
      onChanged: (value) {
        setState(() {
          selectedMonth = value!;
          switch (selectedMonth) {
            case 'This Month':
              {
                var date =
                    DateTime(DateTime.now().year, DateTime.now().month, 1)
                        .toString();

                selectedDate = DateTime.parse(date);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Last Month':
              {
                selectedDate =
                    DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
                selected2ndDate =
                    DateTime(DateTime.now().year, DateTime.now().month, 0);
              }
              break;
            case 'Last 6 Month':
              {
                selectedDate =
                    DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'This Year':
              {
                selectedDate = DateTime(DateTime.now().year, 1, 1);
                selected2ndDate = DateTime.now();
              }
              break;
          }
        });
      },
    );
  }

  String searchItem = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  // Function to calculate the amount from a given percentage
  double calculateAmountFromPercentage(double percentage, double price) {
    return (percentage * price) / 100;
  }

  final _horizontalScroll = ScrollController();
  int _lossProfitPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          AsyncValue<List<SaleTransactionModel>> transactionReport =
              ref.watch(transitionProvider);
          return transactionReport.when(data: (transaction) {
            final reTransaction = transaction.reversed.toList();
            List<SaleTransactionModel> showAbleSaleTransactions = [];
            for (var element in reTransaction) {
              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(element.purchaseDate);
              } catch (e) {
                continue;
              }

              if ((element.invoiceNumber
                          .toLowerCase()
                          .contains(searchItem.toLowerCase()) ||
                      element.customerName
                          .toLowerCase()
                          .contains(searchItem.toLowerCase())) &&
                  (selectedDate.isBefore(parsedDate) ||
                      parsedDate.isAtSameMomentAs(selectedDate)) &&
                  (selected2ndDate.isAfter(parsedDate) ||
                      parsedDate.isAtSameMomentAs(selected2ndDate))) {
                showAbleSaleTransactions.add(element);
              }
            }

            final pages =
                (showAbleSaleTransactions.length / _lossProfitPerPage).ceil();

            final startIndex = (_currentPage - 1) * _lossProfitPerPage;
            final endIndex = startIndex + _lossProfitPerPage;
            final paginatedList = showAbleSaleTransactions.sublist(
                startIndex,
                endIndex > showAbleSaleTransactions.length
                    ? showAbleSaleTransactions.length
                    : endIndex);

            // for (var element in reTransaction) {
            //   if ((element.invoiceNumber
            //               .toLowerCase()
            //               .contains(searchItem.toLowerCase()) ||
            //           element.customerName
            //               .toLowerCase()
            //               .contains(searchItem.toLowerCase())) &&
            //       (selectedDate
            //               .isBefore(DateTime.parse(element.purchaseDate)) ||
            //           DateTime.parse(element.purchaseDate)
            //               .isAtSameMomentAs(selectedDate)) &&
            //       (selected2ndDate
            //               .isAfter(DateTime.parse(element.purchaseDate)) ||
            //           DateTime.parse(element.purchaseDate)
            //               .isAtSameMomentAs(selected2ndDate))) {
            //     showAbleSaleTransactions.add(element);
            //   }
            // }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //----------calculate data-----------------
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: kWhite,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///____________day_filter________________________________________________________________
                        ResponsiveGridRow(rowSegments: 100, children: [
                          ResponsiveGridCol(
                              xs: 100,
                              md: 30,
                              lg: 15,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: SizedBox(
                                  height: 48,
                                  child: FormField(
                                    builder: (FormFieldState<dynamic> field) {
                                      return InputDecorator(
                                        decoration: const InputDecoration(),
                                        child: Theme(
                                            data: ThemeData(
                                                highlightColor:
                                                    dropdownItemColor,
                                                focusColor: dropdownItemColor,
                                                hoverColor: dropdownItemColor),
                                            child: DropdownButtonHideUnderline(
                                                child: getMonth())),
                                      );
                                    },
                                  ),
                                ),
                              )),
                          ResponsiveGridCol(
                            xs: 100,
                            md: 45,
                            lg: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      border: Border.all(color: kNeutral400)),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            color: kGreyTextColor),
                                        child: Center(
                                          child: Text(
                                            lang.S.of(context).between,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                        style: theme.textTheme.titleSmall,
                                      ).onTap(() => _selectDate(context)),
                                      const SizedBox(width: 5.0),
                                      Text(
                                        lang.S.of(context).to,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(width: 5.0),
                                      Flexible(
                                        child: Text(
                                          '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                                          style: theme.textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ).onTap(() => _selectedDate(context)),
                                      ),
                                      const SizedBox(width: 10.0),
                                    ],
                                  )),
                            ),
                          ),
                        ]),
                        // Row(
                        //   children: [
                        //     SizedBox(
                        //       width: 155,
                        //       child: FormField(
                        //         builder: (FormFieldState<dynamic> field) {
                        //           return InputDecorator(
                        //             decoration: const InputDecoration(
                        //               border: InputBorder.none,
                        //             ),
                        //             child: Theme(
                        //                 data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                        //                 child: DropdownButtonHideUnderline(child: getMonth())),
                        //           );
                        //         },
                        //       ),
                        //     ),
                        //     const SizedBox(width: 10.0),
                        //     Container(
                        //         height: 30,
                        //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), border: Border.all(color: kGreyTextColor)),
                        //         child: Row(
                        //           children: [
                        //             Container(
                        //               width: 70,
                        //               height: 30,
                        //               decoration: const BoxDecoration(shape: BoxShape.rectangle, color: kGreyTextColor),
                        //               child: Center(
                        //                 child: Text(
                        //                   lang.S.of(context).between,
                        //                   style: kTextStyle.copyWith(color: kWhite),
                        //                 ),
                        //               ),
                        //             ),
                        //             const SizedBox(width: 10.0),
                        //             Text(
                        //               '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        //               style: kTextStyle.copyWith(color: kTitleColor),
                        //             ).onTap(() => _selectDate(context)),
                        //             const SizedBox(width: 10.0),
                        //             Text(
                        //               lang.S.of(context).to,
                        //               style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                        //             ),
                        //             const SizedBox(width: 10.0),
                        //             Text(
                        //               '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                        //               style: kTextStyle.copyWith(color: kTitleColor),
                        //             ).onTap(() => _selectedDate(context)),
                        //             const SizedBox(width: 10.0),
                        //           ],
                        //         )),
                        //   ],
                        // ),

                        ResponsiveGridRow(
                          rowSegments: 100,
                          children: [
                            ResponsiveGridCol(
                              xs: 100,
                              md: 50,
                              lg: screenWidth < 1450 ? 25 : 20,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 20.0,
                                      top: 10.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: const Color(0xFFCFF4E3),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(transaction.length.toString(),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          )),
                                      Text(
                                        lang.S.of(context).totalSale,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 100,
                              md: 50,
                              lg: screenWidth < 1450 ? 25 : 20,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 20.0,
                                      top: 10.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: const Color(0xFFFEE7CB),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$globalCurrency ${myFormat.format(double.tryParse(getTotalDue(transaction).toString()) ?? 0)}',
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0),
                                      ),
                                      Text(
                                        lang.S.of(context).unPaid,
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 100,
                              md: 50,
                              lg: screenWidth < 1450 ? 25 : 20,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 20.0,
                                      top: 10.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: const Color(0xFF2DB0F6)
                                        .withOpacity(0.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$globalCurrency ${myFormat.format(double.tryParse(calculateTotalSale(transaction).toStringAsFixed(2)) ?? 0)}',
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0),
                                      ),
                                      Text(
                                        lang.S.of(context).totalAmount,
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 100,
                              md: 50,
                              lg: screenWidth < 1450 ? 25 : 20,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 20.0,
                                      top: 10.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: const Color(0xFF15CD75)
                                        .withOpacity(0.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$globalCurrency ${myFormat.format(double.tryParse(calculateTotalProfit(transaction).toStringAsFixed(2)) ?? 0)}',
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0),
                                      ),
                                      Text(
                                        lang.S.of(context).totalProfit,
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 100,
                              md: 50,
                              lg: screenWidth < 1450 ? 25 : 20,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 20.0,
                                      top: 10.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color:
                                        const Color(0xFFFF2525).withOpacity(.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$globalCurrency ${myFormat.format(double.tryParse(calculateTotalLoss(transaction).toStringAsFixed(2)) ?? 0)}',
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0),
                                      ),
                                      Text(
                                        lang.S.of(context).totalLoss,
                                        style: kTextStyle.copyWith(
                                            color: kTitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: kWhite,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            lang.S.of(context).lossOrProfit,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Divider(
                          thickness: 1.0,
                          color: kNeutral300,
                          height: 1,
                        ),

                        ///___________search________________________________________________-
                        ResponsiveGridRow(rowSegments: 100, children: [
                          ResponsiveGridCol(
                            xs: screenWidth < 360
                                ? 50
                                : screenWidth > 430
                                    ? 33
                                    : 40,
                            md: screenWidth < 768
                                ? 24
                                : screenWidth < 950
                                    ? 20
                                    : 15,
                            lg: screenWidth < 1700 ? 15 : 10,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                alignment: Alignment.center,
                                height: 48,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: kNeutral300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                        child: Text(
                                      'Show-',
                                      style: theme.textTheme.bodyLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    DropdownButton<int>(
                                      isDense: true,
                                      padding: EdgeInsets.zero,
                                      underline: const SizedBox(),
                                      value: _lossProfitPerPage,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.black,
                                      ),
                                      items: [
                                        10,
                                        20,
                                        50,
                                        100,
                                        -1
                                      ].map<DropdownMenuItem<int>>((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(
                                            value == -1
                                                ? "All"
                                                : value.toString(),
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          if (newValue == -1) {
                                            _lossProfitPerPage =
                                                -1; // Set to -1 for "All"
                                          } else {
                                            _lossProfitPerPage = newValue ?? 10;
                                          }
                                          _currentPage = 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                            xs: 100,
                            md: 60,
                            lg: 35,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                showCursor: true,
                                cursorColor: kTitleColor,
                                onChanged: (value) {
                                  setState(() {
                                    searchItem = value;
                                  });
                                },
                                keyboardType: TextInputType.name,
                                decoration: kInputDecoration.copyWith(
                                  contentPadding: const EdgeInsets.all(10.0),
                                  hintText: (lang.S
                                      .of(context)
                                      .searchByInvoiceOrName),
                                  border: InputBorder.none,
                                  suffixIcon: const Icon(
                                    FeatherIcons.search,
                                    color: kTitleColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 5.0),
                        showAbleSaleTransactions.isNotEmpty
                            ? Column(
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constrains) {
                                      return Scrollbar(
                                        controller: _horizontalScroll,
                                        thumbVisibility: true,
                                        radius: const Radius.circular(8),
                                        thickness: 8,
                                        child: SingleChildScrollView(
                                          controller: _horizontalScroll,
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: constrains.maxWidth,
                                            ),
                                            child: Theme(
                                              data: theme.copyWith(
                                                dividerColor:
                                                    Colors.transparent,
                                                dividerTheme:
                                                    const DividerThemeData(
                                                        color:
                                                            Colors.transparent),
                                              ),
                                              child: DataTable(
                                                  border: const TableBorder(
                                                    horizontalInside:
                                                        BorderSide(
                                                      width: 1,
                                                      color: kNeutral300,
                                                    ),
                                                  ),
                                                  dataRowColor:
                                                      const WidgetStatePropertyAll(
                                                          Colors.white),
                                                  headingRowColor:
                                                      WidgetStateProperty.all(
                                                          const Color(
                                                              0xFFF8F3FF)),
                                                  showBottomBorder: false,
                                                  dividerThickness: 0.0,
                                                  headingTextStyle: theme
                                                      .textTheme.titleMedium,
                                                  columns: [
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .SL)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .date)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .invoice)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .partyName)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .saleAmount)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .payingAmount)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .dueAmount)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .profitPlus)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .lossminus)),
                                                    DataColumn(
                                                        label: Text(lang.S
                                                            .of(context)
                                                            .action)),
                                                  ],
                                                  rows: List.generate(
                                                      paginatedList.length,
                                                      (index) {
                                                    return DataRow(cells: [
                                                      ///______________S.L__________________________________________________
                                                      DataCell(
                                                        Text(
                                                            '${startIndex + index + 1}'),
                                                      ),

                                                      ///______________Date__________________________________________________
                                                      DataCell(
                                                        Text(
                                                          paginatedList[index]
                                                              .purchaseDate
                                                              .substring(0, 10),
                                                        ),
                                                      ),

                                                      ///____________Invoice_________________________________________________
                                                      DataCell(
                                                        Text(
                                                          paginatedList[index]
                                                              .invoiceNumber,
                                                        ),
                                                      ),

                                                      ///______Party Name___________________________________________________________
                                                      DataCell(
                                                        Text(
                                                          paginatedList[index]
                                                              .customerName,
                                                        ),
                                                      ),

                                                      ///___________Sale Amount____________________________________________________
                                                      DataCell(
                                                        Text(
                                                          '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].totalAmount.toString()) ?? 0)}',
                                                        ),
                                                      ),

                                                      ///___________PayAmount____________________________________________________

                                                      DataCell(
                                                        Text(
                                                          '$globalCurrency${myFormat.format(double.tryParse((paginatedList[index].totalAmount!.toDouble() - paginatedList[index].dueAmount!.toDouble()).toString()) ?? 0)}',
                                                        ),
                                                      ),

                                                      ///___________DueAmount____________________________________________________

                                                      DataCell(
                                                        Text(
                                                          '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].dueAmount.toString()) ?? 0)}',
                                                        ),
                                                      ),

                                                      ///___________Profit____________________________________________________

                                                      DataCell(
                                                        Text(
                                                          paginatedList[index]
                                                                  .lossProfit!
                                                                  .isNegative
                                                              ? ''
                                                              : '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].lossProfit!.toStringAsFixed(2)) ?? 0)}',
                                                        ),
                                                      ),

                                                      ///___________Loss____________________________________________________

                                                      DataCell(
                                                        Text(
                                                          paginatedList[index]
                                                                  .lossProfit!
                                                                  .isNegative
                                                              ? '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].lossProfit!.toStringAsFixed(2)) ?? 0)}'
                                                              : '',
                                                        ),
                                                      ),

                                                      ///_______________Action_________________________________________________
                                                      DataCell(
                                                        GestureDetector(
                                                          onTap: () {
                                                            showLossProfitDetails(
                                                                transitionModel:
                                                                    showAbleSaleTransactions[
                                                                        index]);
                                                          },
                                                          child: Text(
                                                            lang.S
                                                                .of(context)
                                                                .show,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .blue),
                                                          ),
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
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${lang.S.of(context).showing} ${((_currentPage - 1) * _lossProfitPerPage + 1).toString()} to ${((_currentPage - 1) * _lossProfitPerPage + _lossProfitPerPage).clamp(0, showAbleSaleTransactions.length)} of ${showAbleSaleTransactions.length} entries',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            InkWell(
                                              overlayColor: WidgetStateProperty
                                                  .all<Color>(Colors.grey),
                                              hoverColor: Colors.grey,
                                              onTap: _currentPage > 1
                                                  ? () => setState(
                                                      () => _currentPage--)
                                                  : null,
                                              child: Container(
                                                height: 32,
                                                width: 90,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          kBorderColorTextField),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(4.0),
                                                    topLeft:
                                                        Radius.circular(4.0),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(lang.S
                                                      .of(context)
                                                      .previous),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 32,
                                              width: 32,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                                color: kMainColor,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$_currentPage',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 32,
                                              width: 32,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                                color: Colors.transparent,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$pages',
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              hoverColor: Colors.blue
                                                  .withValues(alpha: 0.1),
                                              overlayColor: WidgetStateProperty
                                                  .all<Color>(Colors.blue),
                                              onTap: _currentPage *
                                                          _lossProfitPerPage <
                                                      showAbleSaleTransactions
                                                          .length
                                                  ? () => setState(
                                                      () => _currentPage++)
                                                  : null,
                                              child: Container(
                                                height: 32,
                                                width: 90,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          kBorderColorTextField),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    bottomRight:
                                                        Radius.circular(4.0),
                                                    topRight:
                                                        Radius.circular(4.0),
                                                  ),
                                                ),
                                                child: const Center(
                                                    child: Text('Next')),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : EmptyWidget(
                                title: lang.S.of(context).noTransactionFound),
                      ],
                    ),
                  ),
                  // Visibility(visible: MediaQuery.of(context).size.height != 0, child: const Footer()),
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
        }));
  }
}
