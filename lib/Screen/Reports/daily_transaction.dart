import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/daily_transaction_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/daily_transaction_model.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../Expenses/expense_details.dart';
import '../Income/income_details.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class DailyTransaction extends StatefulWidget {
  const DailyTransaction({super.key});

  @override
  State<DailyTransaction> createState() => _DailyTransactionState();
}

class _DailyTransactionState extends State<DailyTransaction> {
  double calculateTotalPaymentIn(List<DailyTransactionModel> dailyTransaction) {
    double total = 0.0;
    for (var element in dailyTransaction) {
      total += element.paymentIn;
    }
    return total;
  }

  double calculateTotalPaymentOut(List<DailyTransactionModel> dailyTransaction) {
    double total = 0.0;
    for (var element in dailyTransaction) {
      total += element.paymentOut;
    }
    return total;
  }

  String searchItem = '';

  DateTime selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<String> month = ['This Month', 'Last Month', 'Last 6 Month', 'This Year', 'View All'];

  String selectedMonth = 'This Month';

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
            case 'This Month':
              {
                var date = DateTime(DateTime.now().year, DateTime.now().month, 1).toString();

                selectedDate = DateTime.parse(date);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Last Month':
              {
                selectedDate = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
                selected2ndDate = DateTime(DateTime.now().year, DateTime.now().month, 0);
              }
              break;
            case 'Last 6 Month':
              {
                selectedDate = DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'This Year':
              {
                selectedDate = DateTime(DateTime.now().year, 1, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'View All':
              {
                selectedDate = DateTime(1900, 01, 01);
                selected2ndDate = DateTime.now();
              }
              break;
          }
        });
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime selected2ndDate = DateTime.now();

  Future<void> _selectedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selected2ndDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selected2ndDate) {
      setState(() {
        selected2ndDate = picked;
      });
    }
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
    return Consumer(builder: (_, ref, watch) {
      final dailyTransactionReport = ref.watch(dailyTransactionProvider);
      final profile = ref.watch(profileDetailsProvider);
      final settingProvider = ref.watch(generalSettingProvider);
      return dailyTransactionReport.when(
        data: (dailyReport) {
          List<DailyTransactionModel> reTransaction = [];
          // for (var element in dailyReport.reversed.toList()) {
          //   if (element.date.isNotEmpty) {
          //     DateTime? parsedDate;
          //     try {
          //       parsedDate = DateTime.parse(element.date);
          //     } catch (e) {
          //       continue;
          //     }
          //
          //     if ((selectedDate.isBefore(parsedDate) || parsedDate.isAtSameMomentAs(selectedDate)) &&
          //         (selected2ndDate.isAfter(parsedDate) || parsedDate.isAtSameMomentAs(selected2ndDate))) {
          //       reTransaction.add(element);
          //     }
          //   }
          // }

          for (var element in dailyReport.reversed.toList()) {
            if (element.date.isNotEmpty) {
              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(element.date);
              } catch (e) {
                continue;
              }

              if ((selectedDate.isBefore(parsedDate) || parsedDate.isAtSameMomentAs(selectedDate)) && (selected2ndDate.isAfter(parsedDate) || parsedDate.isAtSameMomentAs(selected2ndDate))) {
                reTransaction.add(element);
              }
            }
          }

          // Apply search filter
          if (searchItem.isNotEmpty) {
            reTransaction = reTransaction.where((element) {
              return element.name.toLowerCase().contains(searchItem.toLowerCase()) || element.date.toLowerCase().contains(searchItem.toLowerCase()) || element.type.toLowerCase().contains(searchItem.toLowerCase()) || element.total.toString().contains(searchItem) || element.paymentIn.toString().contains(searchItem) || element.paymentOut.toString().contains(searchItem) || element.remainingBalance.toString().contains(searchItem);
            }).toList();
          }

          // final pages = (reTransaction.length / _lossProfitPerPage).ceil();
          //
          // final startIndex = (_currentPage - 1) * _lossProfitPerPage;
          // final endIndex = _lossProfitPerPage == -1 ? reTransaction.length : startIndex + _lossProfitPerPage;
          // final paginatedList = reTransaction.sublist(
          //   startIndex,
          //   endIndex > reTransaction.length ? reTransaction.length : endIndex,
          // );

          // Calculate pagination
          final pages = _lossProfitPerPage == -1 ? 1 : (reTransaction.length / _lossProfitPerPage).ceil();
          final startIndex = _lossProfitPerPage == -1 ? 0 : (_currentPage - 1) * _lossProfitPerPage;
          final endIndex = _lossProfitPerPage == -1 ? reTransaction.length : (startIndex + _lossProfitPerPage).clamp(0, reTransaction.length);

          // Get paginated transactions
          final paginatedList = reTransaction.sublist(startIndex, endIndex);
          // for (var element in dailyReport.reversed.toList()) {
          //   if ((selectedDate.isBefore(DateTime.parse(element.date)) || DateTime.parse(element.date).isAtSameMomentAs(selectedDate)) &&
          //       (selected2ndDate.isAfter(DateTime.parse(element.date)) || DateTime.parse(element.date).isAtSameMomentAs(selected2ndDate))) {
          //     reTransaction.add(element);
          //   }
          // }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                    decoration: const InputDecoration(
                                        // border: InputBorder.none,
                                        ),
                                    child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getMonth())),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: 45,
                          lg: 30,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                                height: 48,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), border: Border.all(color: kGreyTextColor)),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.all(4),
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(shape: BoxShape.rectangle, color: kGreyTextColor),
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
                                        onTap: () => _selectDate(context), // Handle date selection
                                        child: RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.titleSmall,
                                            children: [
                                              TextSpan(
                                                text: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ',
                                                style: theme.textTheme.titleSmall,
                                              ),
                                              TextSpan(text: lang.S.of(context).to),
                                              TextSpan(
                                                text: ' ${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                                                style: theme.textTheme.titleSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )),
                          ),
                        ),
                      ]),
                      ResponsiveGridRow(rowSegments: 100, children: [
                        ResponsiveGridCol(
                          xs: 100,
                          md: screenWidth < 950 ? 30 : 20,
                          lg: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color(0xFFCFF4E3),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    reTransaction.isNotEmpty ? '$globalCurrency${myFormat.format(double.tryParse(reTransaction.first.remainingBalance.toStringAsFixed(2))?.abs() ?? 0)}' : '0',
                                    style: theme.textTheme.titleLarge?.copyWith(color: kTitleColor, fontWeight: FontWeight.w600, fontSize: 18),
                                  ),
                                  Text(
                                    lang.S.of(context).remainingBalance,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: screenWidth < 950 ? 30 : 20,
                          lg: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color(0xFFFEE7CB),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$globalCurrency ${reTransaction.isNotEmpty ? myFormat.format(double.tryParse(calculateTotalPaymentOut(reTransaction).toStringAsFixed(2)) ?? 0) : 0}',
                                    style: theme.textTheme.titleLarge?.copyWith(color: kTitleColor, fontWeight: FontWeight.w600, fontSize: 18),
                                  ),
                                  Text(
                                    lang.S.of(context).totalpaymentIn,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: screenWidth < 950 ? 30 : 20,
                          lg: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color(0xFFFED3D3),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$globalCurrency ${reTransaction.isNotEmpty ? myFormat.format(double.tryParse(calculateTotalPaymentIn(reTransaction).toStringAsFixed(2)) ?? 0) : 0}',
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                                  ),
                                  Text(
                                    lang.S.of(context).totalPaymentOut,
                                    style: theme.textTheme.bodyMedium,
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
                          lang.S.of(context).dailyTransaction,
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
                      const ExportButton().visible(false),

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
                                    items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
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
                                          _lossProfitPerPage = -1; // Set to -1 for "All"
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
                                hintText: (lang.S.of(context).searchByInvoiceOrName),
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

                      reTransaction.isNotEmpty
                          ? Column(
                              children: [
                                LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
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
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: Theme(
                                            data: theme.copyWith(
                                              dividerColor: Colors.transparent,
                                              dividerTheme: const DividerThemeData(color: Colors.transparent),
                                            ),
                                            child: DataTable(
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  width: 1,
                                                  color: kNeutral300,
                                                ),
                                              ),
                                              dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle: theme.textTheme.titleMedium,
                                              columns: [
                                                DataColumn(label: Text(lang.S.of(context).SL)),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).name,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).date,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).type,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).total,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).paymentIn,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).paymentOut,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).balance,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).action,
                                                  ),
                                                ),
                                              ],
                                              rows: List.generate(
                                                paginatedList.length,
                                                (index) => paginatedList.last.date != paginatedList[index].date
                                                    ? DataRow(cells: [
                                                        DataCell(Text('${startIndex + index + 1}')),
                                                        DataCell(
                                                          Text(
                                                            paginatedList[index].name,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            paginatedList[index].date.substring(0, 10),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            paginatedList[index].type,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].total.toStringAsFixed(2)) ?? 0)}',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            myFormat.format(double.tryParse(paginatedList[index].paymentIn.toStringAsFixed(2)) ?? 0) == '0' ? '' : '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].paymentIn.toStringAsFixed(2)) ?? 0)}',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            myFormat.format(double.tryParse(paginatedList[index].paymentOut.toStringAsFixed(2)) ?? 0) == '0' ? '' : '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].paymentOut.toStringAsFixed(2)) ?? 0)}',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text('$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].remainingBalance.toStringAsFixed(2)) ?? 0)}'),
                                                        ),
                                                        DataCell(settingProvider.when(data: (setting) {
                                                          return Theme(
                                                            data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                            child: PopupMenuButton(
                                                              surfaceTintColor: Colors.white,
                                                              icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (BuildContext bc) => [
                                                                PopupMenuItem(
                                                                  onTap: () async {
                                                                    if (paginatedList[index].type == 'Sale') {
                                                                      await GeneratePdfAndPrint().printSaleInvoice(personalInformationModel: profile.value!, setting: setting, saleTransactionModel: paginatedList[index].saleTransactionModel!, context: context);
                                                                    } else if (paginatedList[index].type == 'Sale Return') {
                                                                      await GeneratePdfAndPrint().printSaleReturnInvoice(setting: setting, personalInformationModel: profile.value!, saleTransactionModel: paginatedList[index].saleTransactionModel!);
                                                                    } else if (paginatedList[index].type == 'Purchase') {
                                                                      await GeneratePdfAndPrint().printPurchaseInvoice(setting: setting, personalInformationModel: profile.value!, purchaseTransactionModel: paginatedList[index].purchaseTransactionModel!);
                                                                    } else if (paginatedList[index].type == 'Purchase Return') {
                                                                      await GeneratePdfAndPrint().printPurchaseReturnInvoice(setting: setting, personalInformationModel: profile.value!, purchaseTransactionModel: paginatedList[index].purchaseTransactionModel!);
                                                                    } else if (paginatedList[index].type == 'Due Collection' || paginatedList[index].type == 'Due Payment') {
                                                                      await GeneratePdfAndPrint().printDueInvoice(setting: setting, personalInformationModel: profile.value!, dueTransactionModel: paginatedList[index].dueTransactionModel!);
                                                                    } else if (paginatedList[index].type == 'Expense') {
                                                                      showDialog(
                                                                        barrierDismissible: false,
                                                                        context: context,
                                                                        builder: (BuildContext context) {
                                                                          return StatefulBuilder(
                                                                            builder: (context, setStates) {
                                                                              return Dialog(
                                                                                surfaceTintColor: Colors.white,
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(20.0),
                                                                                ),
                                                                                child: ExpenseDetails(expense: paginatedList[index].expenseModel!, manuContext: bc),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      );
                                                                    } else if (paginatedList[index].type == 'Income') {
                                                                      showDialog(
                                                                        barrierDismissible: false,
                                                                        context: context,
                                                                        builder: (BuildContext context) {
                                                                          return StatefulBuilder(
                                                                            builder: (context, setStates) {
                                                                              return Dialog(
                                                                                surfaceTintColor: Colors.white,
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(20.0),
                                                                                ),
                                                                                child: IncomeDetails(income: paginatedList[index].incomeModel!, manuContext: bc),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      );
                                                                    }
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      paginatedList[index].type == 'Income' || paginatedList[index].type == 'Expense' ? Icon(IconlyLight.show, size: 22.0, color: kGreyTextColor) : HugeIcon(icon: HugeIcons.strokeRoundedPrinter, size: 22.0, color: kGreyTextColor),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        // Show "View" for Income/Expense, "Print" for others
                                                                        paginatedList[index].type == 'Income' || paginatedList[index].type == 'Expense' ? lang.S.of(context).view : lang.S.of(context).print,
                                                                        style: theme.textTheme.bodyLarge?.copyWith(
                                                                          color: kGreyTextColor,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                              onSelected: (value) {
                                                                Navigator.pushNamed(context, '$value');
                                                              },
                                                            ),
                                                          );
                                                        }, error: (e, stack) {
                                                          return Text(e.toString());
                                                        }, loading: () {
                                                          return Center(
                                                            child: CircularProgressIndicator(),
                                                          );
                                                        })),
                                                      ])
                                                    : DataRow(cells: [
                                                        const DataCell(
                                                          Text(''),
                                                        ),
                                                        DataCell(
                                                          Text(lang.S.of(context).openingBalance),
                                                        ),
                                                        const DataCell(
                                                          Text(''),
                                                        ),
                                                        const DataCell(
                                                          Text(''),
                                                        ),
                                                        const DataCell(
                                                          Text(''),
                                                        ),
                                                        const DataCell(
                                                          Text(''),
                                                        ),
                                                        const DataCell(
                                                          Text(''),
                                                        ),
                                                        DataCell(
                                                          Text(myFormat.format(profile.value!.shopOpeningBalance)),
                                                        ),
                                                        const DataCell(
                                                          Text(''),
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
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${lang.S.of(context).showing} ${((_currentPage - 1) * _lossProfitPerPage + 1).toString()} to ${((_currentPage - 1) * _lossProfitPerPage + _lossProfitPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            overlayColor: WidgetStateProperty.all<Color>(Colors.grey),
                                            hoverColor: Colors.grey,
                                            onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                            child: Container(
                                              height: 32,
                                              width: 90,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: kBorderColorTextField),
                                                borderRadius: const BorderRadius.only(
                                                  bottomLeft: Radius.circular(4.0),
                                                  topLeft: Radius.circular(4.0),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(lang.S.of(context).previous),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 32,
                                            width: 32,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: kBorderColorTextField),
                                              color: kMainColor,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_currentPage',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 32,
                                            width: 32,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: kBorderColorTextField),
                                              color: Colors.transparent,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$pages',
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            hoverColor: Colors.blue.withValues(alpha: 0.1),
                                            overlayColor: WidgetStateProperty.all<Color>(Colors.blue),
                                            onTap: _currentPage * _lossProfitPerPage < reTransaction.length ? () => setState(() => _currentPage++) : null,
                                            child: Container(
                                              height: 32,
                                              width: 90,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: kBorderColorTextField),
                                                borderRadius: const BorderRadius.only(
                                                  bottomRight: Radius.circular(4.0),
                                                  topRight: Radius.circular(4.0),
                                                ),
                                              ),
                                              child: const Center(child: Text('Next')),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : EmptyWidget(title: lang.S.of(context).noTransactionFound),
                    ],
                  ),
                )
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
    });
  }
}
