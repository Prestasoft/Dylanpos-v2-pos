import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Screen/Reports/print%20loss%20profit%20report/print_loss_profit_report.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class LossProfitReport extends StatefulWidget {
  const LossProfitReport({
    super.key,
  });

  static const String route = '/Loss_Profit';

  @override
  State<LossProfitReport> createState() => _LossProfitReportState();
}

class _LossProfitReportState extends State<LossProfitReport> {
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

  DateTimeRange selectedDate = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
        23, 59, 59),
  );

  //DateTime selected2ndDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101),
        initialEntryMode: DatePickerEntryMode.calendar,
        builder: (context, child) {
          return Column(
            children: [
              Material(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.hardEdge,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400.0, maxHeight: 600),
                  child: child,
                ),
              )
            ],
          );
        });

    if (picked != null && picked != selectedDate) {
      final DateTime start =
          DateTime(picked.start.year, picked.start.month, picked.start.day);

      final DateTime end = DateTime(
          picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      setState(() {
        selectedDate = DateTimeRange(start: start, end: end);
      });
    }
  }

  // Future<void> _selectedDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(context: context, initialDate: selected2ndDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
  //   if (picked != null && picked != selected2ndDate) {
  //     setState(() {
  //       selected2ndDate = picked;
  //     });
  //   }
  // }

  ScrollController mainScroll = ScrollController();
  List<String> month = [
    'Este mes',
    'Ultimo mes',
    'Ultimos 6 meses',
    'Este año'
  ];

  String selectedMonth = 'Este mes';

  DropdownButton<String> getMonth() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in month) {
      var item = DropdownMenuItem(
        value: des,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(des),
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
            case 'Este mes':
              {
                selectedDate = DateTimeRange(
                    start:
                        DateTime(DateTime.now().year, DateTime.now().month, 1),
                    end: DateTime.now());
              }
              {
                selectedDate = DateTimeRange(
                    start:
                        DateTime(DateTime.now().year, DateTime.now().month, 1),
                    end: DateTime.now());
              }
              break;
            case 'Ultimo mes':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(
                        DateTime.now().year, DateTime.now().month - 1, 1),
                    end:
                        DateTime(DateTime.now().year, DateTime.now().month, 0));
              }
              break;
            case 'Ultimos 6 meses':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(
                        DateTime.now().year, DateTime.now().month - 6, 1),
                    end: DateTime.now());
              }
              break;
            case 'Este año':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(DateTime.now().year, 1, 1),
                    end: DateTime.now());
              }
              {
                selectedDate = DateTimeRange(
                    start: DateTime(DateTime.now().year, 1, 1),
                    end: DateTime.now());
              }
              break;
            case 'Ver todo':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(1900, 01, 01), end: DateTime.now());
              }
              {
                selectedDate = DateTimeRange(
                    start: DateTime(1900, 01, 01), end: DateTime.now());
              }
              break;
          }
        });
      },
    );
  }

  String searchItem = '';

  final _horizontalScroll = ScrollController();
  int _purchaseReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (_, ref, watch) {
      final personalData = ref.watch(profileDetailsProvider);
      final settingProvider = ref.watch(generalSettingProvider);
      AsyncValue<List<SaleTransactionModel>> transactionReport =
          ref.watch(transitionProvider);
      return transactionReport.when(data: (transaction) {
        final reTransaction = transaction.reversed.toList();
        List<SaleTransactionModel> showAbleSaleTransactions = [];
        for (var element in reTransaction) {
          if ((element.invoiceNumber
                      .toLowerCase()
                      .contains(searchItem.toLowerCase()) ||
                  element.customerName
                      .toLowerCase()
                      .contains(searchItem.toLowerCase())) &&
              (selectedDate.start
                      .isBefore(DateTime.parse(element.purchaseDate)) ||
                  DateTime.parse(element.purchaseDate)
                      .isAtSameMomentAs(selectedDate.start)) &&
              (selectedDate.end.isAfter(DateTime.parse(element.purchaseDate)) ||
                  DateTime.parse(element.purchaseDate)
                      .isAtSameMomentAs(selectedDate.end))) {
            showAbleSaleTransactions.add(element);
          }
        }

        // Calculate pagination
        final pages = _purchaseReportPerPage == -1
            ? 1
            : (showAbleSaleTransactions.length / _purchaseReportPerPage).ceil();
        final startIndex = _purchaseReportPerPage == -1
            ? 0
            : (_currentPage - 1) * _purchaseReportPerPage;
        final endIndex = _purchaseReportPerPage == -1
            ? showAbleSaleTransactions.length
            : (startIndex + _purchaseReportPerPage)
                .clamp(0, showAbleSaleTransactions.length);

        // Get paginated transactions
        final paginatedList =
            showAbleSaleTransactions.sublist(startIndex, endIndex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
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
                      lg: screenWidth < 1500 ? 20 : 15,
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
                                        highlightColor: dropdownItemColor,
                                        focusColor: dropdownItemColor,
                                        hoverColor: dropdownItemColor),
                                    child: DropdownButtonHideUnderline(
                                        child: getMonth())),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 100,
                      md: screenWidth < 800 ? 70 : 45,
                      lg: screenWidth < 1500 ? 40 : 30,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(color: kThemeOutlineColor)),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      color: kGreyTextColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        bottomLeft: Radius.circular(5),
                                      )),
                                  child: Center(
                                    child: Text(
                                      lang.S.of(context).between,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context),
                                    child: Text.rich(TextSpan(
                                        text:
                                            '${selectedDate.start.day}/${selectedDate.start.month}/${selectedDate.start.year}',
                                        style: theme.textTheme.titleSmall,
                                        children: [
                                          TextSpan(
                                            text: lang.S.of(context).to,
                                            style: theme.textTheme.titleSmall,
                                          ),
                                          TextSpan(
                                            text: ' ${lang.S.of(context).to} ',
                                            style: theme.textTheme.titleSmall,
                                          ),
                                          TextSpan(
                                            text:
                                                '${selectedDate.end.day}/${selectedDate.end.month}/${selectedDate.end.year}',
                                            style: theme.textTheme.titleSmall,
                                          )
                                        ])),
                                  ),
                                ),
                                // Text(
                                //   '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                //   style: kTextStyle.copyWith(color: kTitleColor),
                                // ).onTap(() => _selectDate(context)),
                                // const SizedBox(width: 10.0),
                                // Text(
                                //   lang.S.of(context).to,
                                //   style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                // ),
                                // const SizedBox(width: 10.0),
                                // Text(
                                //   '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                                //   style: kTextStyle.copyWith(color: kTitleColor),
                                // ).onTap(() => _selectedDate(context)),
                                // const SizedBox(width: 10.0),
                              ],
                            )),
                      ),
                    ),
                  ]),
                  ResponsiveGridRow(rowSegments: 120, children: [
                    ResponsiveGridCol(
                      xs: 120,
                      md: screenWidth < 800 ? 60 : 40,
                      lg: screenWidth < 1500 ? 40 : 30,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFFCFF4E3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.length.toString(),
                                style: kTextStyle.copyWith(
                                    color: kTitleColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0),
                              ),
                              Text(
                                lang.S.of(context).totalSale,
                                style: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 120,
                      md: screenWidth < 800 ? 60 : 40,
                      lg: screenWidth < 1500 ? 40 : 30,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFFFEE7CB),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 120,
                      md: screenWidth < 800 ? 60 : 40,
                      lg: screenWidth < 1500 ? 40 : 30,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color:
                                const Color(0xFF2DB0F6).withValues(alpha: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 120,
                      md: screenWidth < 800 ? 60 : 40,
                      lg: screenWidth < 1500 ? 40 : 30,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color:
                                const Color(0xFF15CD75).withValues(alpha: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      xs: 120,
                      md: screenWidth < 800 ? 60 : 40,
                      lg: screenWidth < 1500 ? 40 : 30,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color:
                                const Color(0xFFFF2525).withValues(alpha: .5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              // padding: const EdgeInsets.all(10.0),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            lang.S.of(context).lossOrProfit,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        personalData.when(data: (snapShot) {
                          return settingProvider.when(data: (setting) {
                            return Row(
                              children: [
                                Container(
                                  height: 35,
                                  width: 35,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.0),
                                      border: Border.all(color: kMainColor),
                                      color: kWhite),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: const VisualDensity(
                                        horizontal: -4, vertical: -4),
                                    onPressed: () async {
                                      await GenerateLossProfitReport()
                                          .printLossProfitReport(
                                        setting: setting,
                                        personalInformationModel: snapShot,
                                        saleTransactionModel:
                                            showAbleSaleTransactions,
                                        fromDate: selectedDate.start.toString(),
                                        toDate: selectedDate.end.toString(),
                                        saleAmount:
                                            calculateTotalSale(transaction)
                                                .toStringAsFixed(2),
                                        profit:
                                            calculateTotalProfit(transaction)
                                                .toStringAsFixed(2),
                                        loss: calculateTotalLoss(transaction)
                                            .toStringAsFixed(2),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      color: kMainColor,
                                    ),
                                    hoverColor:
                                        kMainColor.withValues(alpha: 0.1),
                                    style: ButtonStyle(
                                        shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.0),
                                      ),
                                    )),
                                    color: kMainColor,
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Container(
                                  height: 35,
                                  width: 35,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.0),
                                      border: Border.all(color: kMainColor),
                                      color: kWhite),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: const VisualDensity(
                                        horizontal: -4, vertical: -4),
                                    onPressed: () async {
                                      await DownloadLossProfitReport()
                                          .printLossProfitReport(
                                        setting: setting,
                                        personalInformationModel: snapShot,
                                        saleTransactionModel:
                                            showAbleSaleTransactions,
                                        fromDate: selectedDate.start.toString(),
                                        toDate: selectedDate.end.toString(),
                                        saleAmount:
                                            calculateTotalSale(transaction)
                                                .toStringAsFixed(2),
                                        profit:
                                            calculateTotalProfit(transaction)
                                                .toStringAsFixed(2),
                                        loss: calculateTotalLoss(transaction)
                                            .toStringAsFixed(2),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.download_outlined,
                                      color: kMainColor,
                                    ),
                                    hoverColor:
                                        kMainColor.withValues(alpha: 0.1),
                                    style: ButtonStyle(
                                        shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.0),
                                      ),
                                    )),
                                    color: kMainColor,
                                  ),
                                ),
                              ],
                            );
                          }, error: (e, stack) {
                            return Text(e.toString());
                          }, loading: () {
                            return Center(child: CircularProgressIndicator());
                          });
                        }, error: (e, stack) {
                          return Center(
                            child: Text(e.toString()),
                          );
                        }, loading: () {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        })
                      ],
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
                              ? 38
                              : 45,
                      md: screenWidth < 768
                          ? 29
                          : screenWidth < 950
                              ? 25
                              : 20,
                      lg: screenWidth < 1700 ? 20 : 17,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          alignment: Alignment.center,
                          height: 48,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: kThemeOutlineColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                  child: Text(
                                'Mostrar-',
                                style: theme.textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              DropdownButton<int>(
                                isDense: true,
                                padding: EdgeInsets.zero,
                                underline: const SizedBox(),
                                value: _purchaseReportPerPage,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black,
                                ),
                                items: [10, 20, 50, 100, -1]
                                    .map<DropdownMenuItem<int>>((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      value == -1 ? "All" : value.toString(),
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    if (newValue == -1) {
                                      _purchaseReportPerPage =
                                          -1; // Set to -1 for "All"
                                    } else {
                                      _purchaseReportPerPage = newValue ?? 10;
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
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10.0),
                            hintText:
                                (lang.S.of(context).searchByInvoiceOrName),
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
                  const SizedBox(height: 10.0),
                  showAbleSaleTransactions.isNotEmpty
                      ? Column(
                          children: [
                            LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                return Scrollbar(
                                  controller: _horizontalScroll,
                                  thumbVisibility: true,
                                  radius: const Radius.circular(8),
                                  thickness: 8,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    controller: _horizontalScroll,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: Theme(
                                        data: theme.copyWith(
                                          dividerTheme: const DividerThemeData(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        child: DataTable(
                                            border: const TableBorder(
                                              horizontalInside: BorderSide(
                                                width: 1,
                                                color: kNeutral300,
                                              ),
                                            ),
                                            dataRowColor:
                                                const WidgetStatePropertyAll(
                                                    Colors.white),
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                    const Color(0xFFF8F3FF)),
                                            showBottomBorder: false,
                                            dividerThickness: 0.0,
                                            headingTextStyle:
                                                theme.textTheme.titleMedium,
                                            columns: [
                                              DataColumn(
                                                  label: Text(
                                                      lang.S.of(context).SL)),
                                              DataColumn(
                                                  label: Text(
                                                      lang.S.of(context).date)),
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
                                                      .profitPlus)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .lossminus)),
                                            ],
                                            rows: List.generate(
                                                paginatedList.length, (index) {
                                              return DataRow(cells: [
                                                ///______________S.L__________________________________________________
                                                DataCell(
                                                  Text(
                                                      "${startIndex + index + 1}"),
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

                                                ///___________Profit____________________________________________________

                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                            .lossProfit!
                                                            .isNegative
                                                        ? '0'
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
                                                        : '0',
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
                                      '${lang.S.of(context).showing} ${((_currentPage - 1) * _purchaseReportPerPage + 1).toString()} to ${((_currentPage - 1) * _purchaseReportPerPage + _purchaseReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        overlayColor:
                                            WidgetStateProperty.all<Color>(
                                                Colors.grey),
                                        hoverColor: Colors.grey,
                                        onTap: _currentPage > 1
                                            ? () =>
                                                setState(() => _currentPage--)
                                            : null,
                                        child: Container(
                                          height: 32,
                                          width: 90,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(4.0),
                                              topLeft: Radius.circular(4.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                                lang.S.of(context).previous),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: kBorderColorTextField),
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
                                              color: kBorderColorTextField),
                                          color: Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$pages',
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        hoverColor:
                                            Colors.blue.withValues(alpha: 0.1),
                                        overlayColor:
                                            WidgetStateProperty.all<Color>(
                                                Colors.blue),
                                        onTap: _currentPage *
                                                    _purchaseReportPerPage <
                                                reTransaction.length
                                            ? () =>
                                                setState(() => _currentPage++)
                                            : null,
                                        child: Container(
                                          height: 32,
                                          width: 90,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomRight: Radius.circular(4.0),
                                              topRight: Radius.circular(4.0),
                                            ),
                                          ),
                                          child:
                                              const Center(child: Text('Next')),
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
          ],
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
    });
  }
}
