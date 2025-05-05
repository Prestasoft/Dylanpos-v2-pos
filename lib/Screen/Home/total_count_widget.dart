import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/product_provider.dart';
import '../../const.dart';
import '../../model/product_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';

class TotalCountWidget extends StatelessWidget {
  const TotalCountWidget(
      {super.key,
      required this.icon,
      required this.title,
      required this.count,
      required this.changes,
      required this.iconColor});

  final String title;
  final String count;
  final IconData icon;
  final int changes;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: kWhite,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: kTextStyle.copyWith(color: kGreyTextColor),
          ),
          subtitle: Row(
            children: [
              Text(
                '$globalCurrency ${myFormat.format(double.tryParse(count) ?? 0)}',
                maxLines: 2,
                style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontWeight: FontWeight.bold,
                    fontSize:
                        context.width() < 1000 ? 14 : context.width() * 0.018),
                overflow: TextOverflow.ellipsis,
              ),
              // const SizedBox(width: 10.0),
              // Container(
              //   padding: const EdgeInsets.only(left: 4.0, right: 4.0),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(30.0),
              //     color: changes <0 ? kRedTextColor.withOpacity(0.2) : kGreenTextColor.withOpacity(0.2) ,
              //   ),
              //   child: Text(
              //     '${changes.toString()}%',
              //     style: kTextStyle.copyWith(color: changes <0 ?kRedTextColor : kGreenTextColor, fontSize: 14.0),
              //   ),
              // ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class TotalSummary extends StatelessWidget {
  const TotalSummary({
    super.key,
    required this.title,
    required this.count,
    required this.withOutCurrency,
    required this.footerTitle,
    required this.backgroundColor,
    required this.icon,
    required this.predictIcon,
    required this.predictIconColor,
    required this.monthlyDifferent,
    required this.difWithoutCurrency,
  });

  final String title;
  final String footerTitle;
  final String count;
  final String monthlyDifferent;
  final bool withOutCurrency;
  final bool difWithoutCurrency;
  final Color backgroundColor;
  final String icon;
  final IconData predictIcon;
  final Color predictIconColor;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        // border: Border.all(color: kTitleColor),
        borderRadius: BorderRadius.circular(10.0),
        color: backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              withOutCurrency
                  ? myFormat.format(double.tryParse(count) ?? 0)
                  : '$globalCurrency ${myFormat.format(double.tryParse(count) ?? 0)}',
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: kGreyTextColor,
              ),
            ),
            // trailing: SvgPicture.asset(
            //   icon,
            //   height: 50.0,
            //   width: 42.0,
            //   allowDrawingOutsideViewBox: false,
            //   fit: BoxFit.cover,
            // ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white),
              color: Colors.white.withValues(alpha: 0.5),
            ),
            child: Text.rich(TextSpan(children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  predictIcon,
                  color: predictIconColor,
                  size: 12,
                ),
              ),
              TextSpan(
                text:
                    ' ${difWithoutCurrency ? monthlyDifferent : '$globalCurrency$monthlyDifferent'} ',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: predictIconColor),
              ),
              TextSpan(
                text: footerTitle,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: kGreyTextColor),
              )
            ])),
            // child: Row(
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   mainAxisAlignment: MainAxisAlignment.start,
            //   children: [
            //     Icon(
            //       predictIcon,
            //       color: predictIconColor,
            //       size: 12,
            //     ),
            //     const SizedBox(width: 4.0),
            //     Text(
            //       difWithoutCurrency ? monthlyDifferent : '$globalCurrency$monthlyDifferent',
            //       style: theme.textTheme.bodyMedium?.copyWith(color: predictIconColor),
            //     ),
            //     const SizedBox(width: 6.0),
            //     Text(
            //       footerTitle,
            //       maxLines: 1,
            //       style: theme.textTheme.bodyMedium?.copyWith(color: kGreyTextColor),
            //     )
            //   ],
            // ),
          )
        ],
      ),
    );
  }
}

///---------------------fl chart ------------------------------------------------------

class StatisticsData extends StatefulWidget {
  const StatisticsData(
      {super.key,
      required this.totalSaleCurrentYear,
      required this.totalSaleCurrentMonths,
      required this.totalSaleLastMonth,
      required this.monthlySale,
      required this.dailySale,
      required this.totalSaleCount,
      required this.freeUser,
      required this.totalExpenseCurrentYear,
      required this.totalExpenseCurrentMonths,
      required this.totalExpenseLastMonth,
      required this.monthlyExpense,
      required this.dailyExpense});
//_______________Sale_______________
  final double totalSaleCurrentYear;
  final double totalSaleCurrentMonths;
  final double totalSaleLastMonth;
  final List<double> monthlySale;
  final List<int> dailySale;
  final double totalSaleCount;
  final double freeUser;
  //_______________Expense_______________
  final double totalExpenseCurrentYear;
  final double totalExpenseCurrentMonths;
  final double totalExpenseLastMonth;
  final List<double> monthlyExpense;
  final List<int> dailyExpense;

  @override
  State<StatisticsData> createState() => _StatisticsDataState();
}

class _StatisticsDataState extends State<StatisticsData> {
  List<MonthlyIncomeData> data = [
    MonthlyIncomeData('Jan', 0, 0),
    MonthlyIncomeData('Feb', 0, 0),
    MonthlyIncomeData('Mar', 0, 0),
    MonthlyIncomeData('Apr', 0, 0),
    MonthlyIncomeData('May', 0, 0),
    MonthlyIncomeData('Jun', 0, 0),
    MonthlyIncomeData('July', 0, 0),
    MonthlyIncomeData('Aug', 0, 0),
    MonthlyIncomeData('Sep', 0, 0),
    MonthlyIncomeData('Oct', 0, 0),
    MonthlyIncomeData('Nov', 0, 0),
    MonthlyIncomeData('Dec', 0, 0),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    data = [
      MonthlyIncomeData('Jan', widget.monthlySale[0], widget.monthlyExpense[0]),
      MonthlyIncomeData('Feb', widget.monthlySale[1], widget.monthlyExpense[1]),
      MonthlyIncomeData('Mar', widget.monthlySale[2], widget.monthlyExpense[2]),
      MonthlyIncomeData('Apr', widget.monthlySale[3], widget.monthlyExpense[3]),
      MonthlyIncomeData('May', widget.monthlySale[4], widget.monthlyExpense[4]),
      MonthlyIncomeData('Jun', widget.monthlySale[5], widget.monthlyExpense[5]),
      MonthlyIncomeData('Jul', widget.monthlySale[6], widget.monthlyExpense[6]),
      MonthlyIncomeData('Aug', widget.monthlySale[7], widget.monthlyExpense[7]),
      MonthlyIncomeData('Sep', widget.monthlySale[8], widget.monthlyExpense[8]),
      MonthlyIncomeData('Oct', widget.monthlySale[9], widget.monthlyExpense[9]),
      MonthlyIncomeData(
          'Nov', widget.monthlySale[10], widget.monthlyExpense[10]),
      MonthlyIncomeData(
          'Dec', widget.monthlySale[11], widget.monthlyExpense[11]),
    ];
    dailyData = initializeSalesData();
    getAllTotal();
  }

  List<String> monthList = [
    'This Month',
    'Yearly',
  ];

  String selectedMonth = 'Yearly';

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in monthList) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: const TextStyle(
              color: kTitleColor, fontWeight: FontWeight.normal, fontSize: 14),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(Icons.keyboard_arrow_down),
      padding: EdgeInsets.zero,
      items: dropDownItems,
      value: selectedMonth,
      onChanged: (value) {
        setState(() {
          selectedMonth = value!;
        });
      },
    );
  }

  final ScrollController stockInventoryScrollController = ScrollController();

  late List<DailyIncomeData> dailyData;

  List<DailyIncomeData> initializeSalesData() {
    return List.generate(
      widget.dailySale.length,
      (index) => DailyIncomeData(
          (index + 1).toString(),
          widget.dailySale[index].toDouble(),
          widget.dailyExpense[index].toDouble()),
    );
  }

  int totalStock = 0;
  double totalSalePrice = 0;
  double totalParPrice = 0;

  // Calculate total income and expense amounts
  double get totalIncome {
    return data.fold(0.0, (sum, item) => sum + item.sales);
  }

  double get totalExpense {
    return data.fold(0.0, (sum, item) => sum + item.expense);
  }

  int getDaysInMonth(int year, int month) {
    final DateTime firstDayOfMonth = DateTime(year, month);
    final DateTime firstDayOfNextMonth = DateTime(year, month + 1);
    return firstDayOfNextMonth.difference(firstDayOfMonth).inDays;
  }

  @override
  Widget build(BuildContext context) {
    pro.Provider.of<CurrencyProvider>(context);
    final isYearly = selectedMonth == 'Yearly';
    TextTheme textTheme = Theme.of(context).textTheme;
    // Example usage:
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;
    final int daysInMonth = getDaysInMonth(currentYear, currentMonth);
    double freePercentage = ((widget.freeUser * 100) / widget.totalSaleCount);
    double paidPercentage = 100 - freePercentage;
    print(freePercentage);
    print(paidPercentage);
    final maxYValue = data
        .map((e) => e.sales)
        .followedBy(data.map((e) => e.expense))
        .reduce((a, b) => a > b ? a : b);
    return Consumer(
      builder: (_, ref, watch) {
        ref.watch(productProvider);
        return Container(
          height: 400,
          // width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                blurStyle: BlurStyle.inner,
                spreadRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up),
                    const SizedBox(width: 5.0),
                    Text(
                      lang.S.of(context).statistic,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      height: 35,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: kLitGreyColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: kLitGreyColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: kMainColor),
                          ),
                          // Optionally, you can add padding or other decorations here
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: ['This Month', 'Yearly']
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                        value: selectedMonth,
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = value!;
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
              const Divider(
                thickness: 1.0,
                height: 2,
                color: kBorderColorTextField,
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(TextSpan(children: [
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.circle,
                        color: kMainColor,
                        size: 14,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' ${lang.S.of(context).totalSales}: ${totalIncome.toStringAsFixed(2)}',
                      style: textTheme.titleMedium,
                    )
                  ])),
                  const SizedBox(width: 20),
                  Text.rich(TextSpan(children: [
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 14,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' ${lang.S.of(context).totalExpense}: ${totalExpense.toStringAsFixed(2)}',
                      style: textTheme.titleMedium,
                    )
                  ])),
                  // Display total expense
                  // Row(
                  //   children: [
                  //     const Icon(
                  //       Icons.circle,
                  //       color: Colors.red,
                  //       size: 14,
                  //     ),
                  //     const SizedBox(
                  //       width: 4,
                  //     ),
                  //     Text(
                  //       '${lang.S.of(context).totalExpense}: $globalCurrency${totalExpense.toStringAsFixed(2)}',
                  //       style: kTextStyle.copyWith(fontWeight: FontWeight.bold, color: kTitleColor),
                  //       maxLines: 2,
                  //       overflow: TextOverflow.ellipsis,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 15, top: 0),
                  child: isYearly
                      ? LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) {
                                return const FlLine(
                                  color: kLitGreyColor,
                                  strokeWidth: 1,
                                  dashArray: [3, 3],
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return const FlLine(
                                  color: kLitGreyColor,
                                  strokeWidth: 1,
                                  dashArray: [3, 3],
                                );
                              },
                            ),
                            minY: 0, // Set the minimum Y value
                            maxY: maxYValue + (maxYValue * 0.1),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval:
                                      1, // Ensures titles are shown at regular intervals
                                  getTitlesWidget: (value, meta) {
                                    // Validate that the value corresponds to a valid index in the data list
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < data.length) {
                                      final monthName =
                                          data[value.toInt()].month;

                                      // Ensure each month name is only displayed once
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          monthName,
                                          style: kTextStyle.copyWith(
                                              color: kTitleColor),
                                        ),
                                      );
                                    }
                                    // Return an empty widget if the value is invalid
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              // leftTitles: AxisTitles(
                              //   sideTitles: SideTitles(
                              //     showTitles: true,
                              //     reservedSize: 60,
                              //     getTitlesWidget: (value, meta) {
                              //       // Hide the maximum Y value
                              //       if (value == maxYValue) {
                              //         return const SizedBox.shrink();
                              //       }
                              //       return SideTitleWidget(
                              //         axisSide: meta.axisSide,
                              //         child: Text(
                              //           formatNumber(
                              //               value), // Format the number
                              //           style: kTextStyle.copyWith(
                              //               color: kGreyTextColor),
                              //         ),
                              //       );
                              //     },
                              //   ),
                              // ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    // Hide the highest data value
                                    if (value == meta.max) {
                                      return const SizedBox
                                          .shrink(); // Hide the title for the maximum value
                                    }
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        formatNumber(
                                            value), // Format the number
                                        style: kTextStyle.copyWith(
                                            color: kGreyTextColor),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            clipData: const FlClipData.all(),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                bottom:
                                    BorderSide(color: kLitGreyColor, width: 1),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: data
                                    .map((e) => FlSpot(
                                          data.indexOf(e).toDouble(),
                                          e.sales,
                                        ))
                                    .toList(),
                                isCurved: true,
                                color: kMainColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              ),
                              LineChartBarData(
                                spots: data
                                    .map((e) => FlSpot(
                                          data.indexOf(e).toDouble(),
                                          e.expense,
                                        ))
                                    .toList(),
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                        )

                      ///------------------total month---------------------------
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) {
                                return const FlLine(
                                  color: kLitGreyColor,
                                  strokeWidth: 1,
                                  dashArray: [
                                    3,
                                    3
                                  ], // Add dash array for dashed lines
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return const FlLine(
                                  color: kLitGreyColor,
                                  strokeWidth: 1,
                                  dashArray: [
                                    3,
                                    3
                                  ], // Add dash array for dashed lines
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    // Hide the highest data value
                                    if (value == meta.max) {
                                      return const SizedBox
                                          .shrink(); // Hide the title for the maximum value
                                    }
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        formatNumber(
                                            value), // Format the number
                                        style: kTextStyle.copyWith(
                                            color: kGreyTextColor),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                  bottom: BorderSide(color: kLitGreyColor)),
                            ),
                            clipData: const FlClipData.all(),
                            minY: 0, // Set the minimum Y value
                            maxY: maxYValue + (maxYValue * 0.1),
                            minX: 1, // Start from day 1
                            maxX: daysInMonth.toDouble(),
                            lineBarsData: [
                              LineChartBarData(
                                spots: dailyData
                                    .map((e) => FlSpot(
                                          // dailyData.indexOf(e).toDouble(),
                                          e.day.toDouble(),
                                          e.sales,
                                        ))
                                    .toList(),
                                isCurved: true,
                                color: kMainColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              ),
                              LineChartBarData(
                                spots: dailyData
                                    .map((e) => FlSpot(
                                          // dailyData.indexOf(e).toDouble(),
                                          e.day.toDouble(),
                                          e.expense,
                                        ))
                                    .toList(),
                                isCurved: true,
                                barWidth: 3,
                                color: Colors.red,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper function to format the number with K, M, B
  String formatNumber(double value) {
    if (value >= 1e9) {
      return (value / 1e9).toStringAsFixed(1) + 'B';
    } else if (value >= 1e6) {
      return (value / 1e6).toStringAsFixed(1) + 'M';
    } else if (value >= 1e3) {
      return (value / 1e3).toStringAsFixed(1) + 'K';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  void getAllTotal() async {
    // ignore: unused_local_variable
    List<ProductModel> productList = [];
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Products')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        totalStock = totalStock + int.parse(data['productStock']);
        totalSalePrice = totalSalePrice +
            (int.tryParse(data['productSalePrice']) ??
                0 * (int.tryParse(data['productStock']) ?? 0));
        totalParPrice = totalParPrice +
            (int.parse(data['productPurchasePrice']) *
                int.parse(data['productStock']));
        // productList.add(ProductModel.fromJson(jsonDecode(jsonEncode(element.value))));
      }
    });
    setState(() {});
  }
}

class MonthlyIncomeData {
  MonthlyIncomeData(this.month, this.sales, this.expense);

  final String month;
  final double sales;
  final double expense;
}

class DailyIncomeData {
  DailyIncomeData(this.day, this.sales, this.expense);

  final String day;
  final double sales;
  final double expense;
}

///---------------------Income expense chart----------------------
class IncomeExpenseLineChart extends StatefulWidget {
  const IncomeExpenseLineChart({
    super.key,
    required this.totalSaleCurrentMonths,
    required this.totalSaleLastMonth,
    required this.totalSaleCurrentYear,
    required this.monthlySale,
    required this.dailySale,
    required this.totalSaleCount,
    required this.freeUser,
    required this.totalExpenseCurrentYear,
    required this.totalExpenseCurrentMonths,
    required this.totalExpenseLastMonth,
    required this.monthlyExpense,
    required this.dailyExpense,
  });

  final double totalSaleCurrentMonths;
  final double totalSaleLastMonth;
  final double totalSaleCurrentYear;
  final List<double> monthlySale;
  final List<int> dailySale;
  final double totalSaleCount;
  final double freeUser;
  final double totalExpenseCurrentYear;
  final double totalExpenseCurrentMonths;
  final double totalExpenseLastMonth;
  final List<double> monthlyExpense;
  final List<int> dailyExpense;

  @override
  State<IncomeExpenseLineChart> createState() => _IncomeExpenseLineChartState();
}

class _IncomeExpenseLineChartState extends State<IncomeExpenseLineChart> {
  String selectedPeriod = 'Yearly'; // Default selection

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final _theme = Theme.of(context);
    final _isDark = _theme.brightness == Brightness.dark;
    final _lng = lang.S.of(context);

    final _mqSize = MediaQuery.sizeOf(context);

    const _incomeColor = Color(0xff7500FD);
    const _expenseColor = Color(0xffFF3030);

    // Determine which data to use based on the selected period
    final isYearly = selectedPeriod == 'Yearly';
    final chartData = isYearly
        ? widget.monthlySale
        : widget.dailySale.map((e) => e.toDouble()).toList();
    final chartExpenses = isYearly
        ? widget.monthlyExpense
        : widget.dailyExpense.map((e) => e.toDouble()).toList();

    // Calculate the maximum Y value for the chart
    final maxYValue =
        chartData.followedBy(chartExpenses).reduce((a, b) => a > b ? a : b);
    final interval = maxYValue / 4;

    // Ensure interval is not zero
    final safeInterval = interval > 0 ? interval : 1;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Dropdown to select period
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedActivity02,
                  color: Colors.black,
                  size: 24.0,
                ),
                const SizedBox(width: 5.0),
                Text(
                  lang.S.of(context).statistic,
                  style: _theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                SizedBox(
                  height: 32,
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: kMainColor),
                      ),
                    ),
                    items: ['Yearly', 'Monthly']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPeriod = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: kNeutral300,
            height: 1,
          ),
          const SizedBox(height: 16),
          Wrap(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '● ',
                      style: TextStyle(color: _incomeColor),
                    ),
                    TextSpan(
                      text: "${_lng.income}: ",
                      style: TextStyle(
                        color: _isDark
                            ? _theme.colorScheme.onPrimaryContainer
                            : const Color(0xff667085),
                      ),
                    ),
                    TextSpan(
                      text:
                          "$globalCurrency${isYearly ? widget.totalSaleCurrentYear.toStringAsFixed(2) : widget.totalSaleCurrentMonths.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: _isDark
                            ? _theme.colorScheme.onPrimaryContainer
                            : const Color(0xff344054),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '● ',
                      style: TextStyle(color: _expenseColor),
                    ),
                    TextSpan(
                      text: "${_lng.expense}: ",
                      style: TextStyle(
                        color: _isDark
                            ? _theme.colorScheme.onPrimaryContainer
                            : const Color(0xff667085),
                      ),
                    ),
                    TextSpan(
                      text:
                          "$globalCurrency${isYearly ? widget.totalExpenseCurrentYear.toStringAsFixed(2) : widget.totalExpenseCurrentMonths.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: _isDark
                            ? _theme.colorScheme.onPrimaryContainer
                            : const Color(0xff344054),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: _theme.textTheme.bodyMedium?.copyWith(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: isYearly ? 12 : widget.dailySale.length.toDouble(),
                  minY: 0,
                  maxY: maxYValue + (maxYValue * 0.1), // Add some padding
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: _theme.colorScheme.outline,
                      dashArray: [10, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes
                          .map(
                            (item) => TouchedSpotIndicatorData(
                              const FlLine(color: Colors.transparent),
                              FlDotData(
                                getDotPainter: (p0, p1, p2, p3) {
                                  return FlDotCirclePainter(
                                    color: p2.color ?? Colors.transparent,
                                    strokeWidth: 2.5,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                          )
                          .toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      maxContentWidth: 240,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((item) {
                          final _value = NumberFormat.compactCurrency(
                            decimalDigits: 4,
                            symbol: '',
                            locale: 'en',
                          ).format(item.bar.spots[item.spotIndex].y);

                          return LineTooltipItem(
                            "",
                            _theme.textTheme.bodySmall!,
                            textAlign: TextAlign.start,
                            children: [
                              TextSpan(
                                text: '● ',
                                style: TextStyle(color: item.bar.color),
                              ),
                              TextSpan(
                                text:
                                    "${item.barIndex == 0 ? _lng.income : _lng.expense}:",
                                style: TextStyle(
                                  color: _isDark
                                      ? _theme.colorScheme.onPrimaryContainer
                                      : const Color(0xff667085),
                                ),
                              ),
                              TextSpan(
                                text: " $_value",
                                style: TextStyle(
                                  color: _isDark
                                      ? _theme.colorScheme.onPrimaryContainer
                                      : const Color(0xff344054),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                      tooltipRoundedRadius: 4,
                      getTooltipColor: (touchedSpot) {
                        return _isDark
                            ? _theme.colorScheme.tertiaryContainer
                            : Colors.white;
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble() + 1, entry.value);
                      }).toList(),
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      color: _incomeColor,
                      belowBarData: BarAreaData(
                        show: true,
                        applyCutOffY: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [100, 80],
                          tileMode: TileMode.decal,
                          colors: [
                            _incomeColor.withOpacity(0.075),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: chartExpenses.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble() + 1, entry.value);
                      }).toList(),
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      color: _expenseColor,
                      belowBarData: BarAreaData(
                        show: true,
                        applyCutOffY: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [100, 80],
                          tileMode: TileMode.decal,
                          colors: [
                            _expenseColor.withOpacity(0.15),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: _getTitlesData(context, show: false),
                    rightTitles: _getTitlesData(context, show: false),
                    leftTitles: _getTitlesData(
                      context,
                      reservedSize: 42,
                      interval: safeInterval.toDouble(),
                      // getTitlesWidget: (value, titleMeta) {
                      //   return Text(
                      //     value.toStringAsFixed(0),
                      //     style: _theme.textTheme.bodyMedium?.copyWith(
                      //       color: _theme.colorScheme.onTertiary,
                      //     ),
                      //   );
                      // },
                    ),
                    bottomTitles: _getTitlesData(
                      context,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, titleMeta) {
                        if (isYearly) {
                          final _titles = {
                            1: 'Jan',
                            2: 'Feb',
                            3: 'Mar',
                            4: 'Apr',
                            5: 'May',
                            6: 'Jun',
                            7: 'Jul',
                            8: 'Aug',
                            9: 'Sep',
                            10: 'Oct',
                            11: 'Nov',
                            12: 'Dec',
                          };
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: 8,
                              end: 24,
                            ),
                            child: Transform.rotate(
                              angle: _mqSize.width < 480
                                  ? (-45 * (3.1416 / 180))
                                  : 0,
                              child: Text(
                                _titles[value.toInt()] ?? '',
                                style: _theme.textTheme.bodyMedium?.copyWith(
                                  color: _theme.colorScheme.onTertiary,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: 8,
                              end: 24,
                            ),
                            child: Text(
                              value.toInt().toString(),
                              style: _theme.textTheme.bodyMedium?.copyWith(
                                color: _theme.colorScheme.onTertiary,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AxisTitles _getTitlesData(
    BuildContext context, {
    bool show = true,
    Widget Function(double value, TitleMeta titleMeta)? getTitlesWidget,
    double reservedSize = 22,
    double? interval,
  }) {
    final safeInterval = interval ?? 1;
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: show,
        getTitlesWidget: getTitlesWidget ?? defaultGetTitle,
        reservedSize: reservedSize,
        interval: safeInterval,
      ),
    );
  }
}
