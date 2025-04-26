// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/transactions_provider.dart';
import 'package:salespro_admin/Screen/Reports/daily_transaction.dart';
import 'package:salespro_admin/Screen/Reports/purchase_report_widget.dart';
import 'package:salespro_admin/Screen/Reports/purchase_return_widget.dart';
import 'package:salespro_admin/Screen/Reports/quotation_reports_wedget.dart';
import 'package:salespro_admin/Screen/Reports/seles_return_widget.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../PDF/sales_invoice_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';
import '../currency/currency_provider.dart';
import 'current_stock_widget.dart';
import 'due_reports_wedget.dart';
import 'loss_profit_report.dart';

class SaleReports extends StatefulWidget {
  const SaleReports({super.key});
  // static const String route = '/reports';

  @override
  State<SaleReports> createState() => _SaleReportsState();
}

class _SaleReportsState extends State<SaleReports> {
  List<String> categoryList = [
    'Sale',
    'Sales Return',
    'Purchase',
    'Purchase Return',
    'Due',
    'Current Stock',
    'Daily Transaction',
    'Quotation Sale History',
    'Loss/Profit report',
  ];

  String selected = 'Sale';

  String selectedMonth = 'This Month';

  DateTime selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

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

  List<String> month = ['This Month', 'Last Month', 'Last 6 Month', 'This Year', 'View All'];

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

  String searchItem = '';

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
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

  final _horizontalScroll = ScrollController();
  int _saleReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //_______________________________top_bar____________________________
            // const TopBar(),
            ResponsiveGridRow(children: [
              //--------------for selected option-----------------
              ResponsiveGridCol(
                xs: 12,
                md: 3,
                lg: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: screenWidth,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                          color: kGreyTextColor.withValues(alpha: 0.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.S.of(context).transactionReport,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10.0),
                              bottomRight: Radius.circular(10.0),
                            ),
                            color: kWhite),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                                itemCount: categoryList.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (_, i) {
                                  return Container(
                                    padding: const EdgeInsets.all(5.0),
                                    decoration: BoxDecoration(
                                      color: selected == categoryList[i] ? Colors.grey.shade100 : null,
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        categoryList[i],
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ).onTap(() async {
                                    if (categoryList[i] == 'Current Stock') {
                                      if (await checkUserRolePermission(type: '/stock-list')) {
                                        setState(() {
                                          selected = categoryList[i];
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        selected = categoryList[i];
                                      });
                                    }
                                  });
                                })
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //-----------------sale reports-----------------------
              ResponsiveGridCol(
                xs: selected == 'Sale' ? 12 : 0,
                md: selected == 'Sale' ? 9 : 0,
                lg: selected == 'Sale' ? 9 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Consumer(builder: (_, ref, watch) {
                    AsyncValue<List<SaleTransactionModel>> transactionReport = ref.watch(transitionProvider);
                    final settingProvider = ref.watch(generalSettingProvider);
                    return transactionReport.when(data: (transaction) {
                      List<SaleTransactionModel> reTransaction = [];
                      for (var element in transaction.reversed.toList()) {
                        if ((element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()) || element.customerName.toLowerCase().contains(searchItem.toLowerCase())) && (selectedDate.isBefore(DateTime.parse(element.purchaseDate)) || DateTime.parse(element.purchaseDate).isAtSameMomentAs(selectedDate)) && (selected2ndDate.isAfter(DateTime.parse(element.purchaseDate)) || DateTime.parse(element.purchaseDate).isAtSameMomentAs(selected2ndDate))) {
                          reTransaction.add(element);
                        }
                      }
                      // final pages = (reTransaction.length / _saleReportPerPage).ceil();
                      //
                      // final startIndex = (_currentPage - 1) * _saleReportPerPage;
                      // // final endIndex = startIndex + _saleReportPerPage;
                      // final endIndex = _saleReportPerPage == -1 ? reTransaction.length : startIndex + _saleReportPerPage;
                      // final paginatedList = reTransaction.sublist(
                      //   startIndex,
                      //   endIndex > reTransaction.length ? reTransaction.length : endIndex,
                      // );
                      // Calculate pagination
                      final pages = _saleReportPerPage == -1 ? 1 : (reTransaction.length / _saleReportPerPage).ceil();
                      final startIndex = _saleReportPerPage == -1 ? 0 : (_currentPage - 1) * _saleReportPerPage;
                      final endIndex = _saleReportPerPage == -1 ? reTransaction.length : (startIndex + _saleReportPerPage).clamp(0, reTransaction.length);
                      // Get paginated transactions
                      final paginatedList = reTransaction.sublist(startIndex, endIndex);
                      final profile = ref.watch(profileDetailsProvider);
                      final settingProvider = ref.watch(generalSettingProvider);
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
                                              child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getMonth())),
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
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), border: Border.all(color: kThemeOutlineColor)),
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
                                                  child: Text.rich(TextSpan(text: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: theme.textTheme.titleSmall, children: [
                                                    TextSpan(
                                                      text: lang.S.of(context).to,
                                                      style: theme.textTheme.titleSmall,
                                                    ),
                                                    TextSpan(
                                                      text: ' ${lang.S.of(context).to} ',
                                                      style: theme.textTheme.titleSmall,
                                                    ),
                                                    TextSpan(
                                                      text: '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                                                      style: theme.textTheme.titleSmall,
                                                    )
                                                  ])),
                                                ),
                                              ),
                                            ],
                                          )),
                                    ),
                                  ),
                                ]),
                                ResponsiveGridRow(rowSegments: 100, children: [
                                  ResponsiveGridCol(
                                    xs: 100,
                                    md: screenWidth < 800 ? 50 : 30,
                                    lg: screenWidth < 1500 ? 30 : 20,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          color: const Color(0xFFCFF4E3),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reTransaction.length.toString(),
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                            ),
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
                                    md: screenWidth < 800 ? 50 : 30,
                                    lg: screenWidth < 1500 ? 30 : 20,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          color: const Color(0xFFFEE7CB),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$globalCurrency${myFormat.format(double.tryParse(getTotalDue(reTransaction).toString()) ?? 0)}',
                                              style: theme.textTheme.titleMedium?.copyWith(color: kTitleColor, fontWeight: FontWeight.w600, fontSize: 18.0),
                                            ),
                                            Text(
                                              lang.S.of(context).unPaid,
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                    xs: 100,
                                    md: screenWidth < 800 ? 50 : 30,
                                    lg: screenWidth < 1500 ? 30 : 20,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10.0),
                                          color: const Color(0xFFFED3D3),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$globalCurrency${myFormat.format(double.tryParse(calculateTotalSale(reTransaction).toString()) ?? 0)}',
                                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18.0),
                                            ),
                                            Text(
                                              lang.S.of(context).totalAmount,
                                              style: theme.textTheme.bodyLarge,
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
                                    lang.S.of(context).saleTransaction,
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
                                              'Show-',
                                              style: theme.textTheme.bodyLarge,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                            DropdownButton<int>(
                                              isDense: true,
                                              padding: EdgeInsets.zero,
                                              underline: const SizedBox(),
                                              value: _saleReportPerPage,
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
                                                    _saleReportPerPage = -1; // Set to -1 for "All"
                                                  } else {
                                                    _saleReportPerPage = newValue ?? 10;
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
                                Row(
                                  children: [
                                    Container(
                                      height: 40.0,
                                      width: 300,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kGreyTextColor.withOpacity(0.1))),
                                      child: AppTextField(
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        textFieldType: TextFieldType.NAME,
                                        decoration: kInputDecoration.copyWith(
                                          contentPadding: const EdgeInsets.all(0.0),
                                          hintText: (lang.S.of(context).search),
                                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                          border: InputBorder.none,
                                          enabledBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(30.0)),
                                            borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(30.0)),
                                            borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                                          ),
                                          suffixIcon: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Container(
                                                padding: const EdgeInsets.all(2.0),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  color: kGreyTextColor.withOpacity(0.1),
                                                ),
                                                child: const Icon(
                                                  FeatherIcons.search,
                                                  color: kTitleColor,
                                                )),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      MdiIcons.contentCopy,
                                      color: kTitleColor,
                                    ),
                                    const SizedBox(width: 5.0),
                                    Icon(MdiIcons.microsoftExcel, color: kTitleColor),
                                    const SizedBox(width: 5.0),
                                    Icon(MdiIcons.fileDelimited, color: kTitleColor),
                                    const SizedBox(width: 5.0),
                                    Icon(MdiIcons.filePdfBox, color: kTitleColor),
                                    const SizedBox(width: 5.0),
                                    const Icon(FeatherIcons.printer, color: kTitleColor),
                                  ],
                                ).visible(false),

                                ///________sate_list_________________________________________________________
                                reTransaction.isNotEmpty
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
                                                  scrollDirection: Axis.horizontal,
                                                  controller: _horizontalScroll,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minWidth: constrains.maxWidth,
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
                                                          dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                                          showBottomBorder: false,
                                                          dividerThickness: 0.0,
                                                          headingTextStyle: theme.textTheme.titleMedium,
                                                          columns: [
                                                            DataColumn(label: Text(lang.S.of(context).SL)),
                                                            DataColumn(label: Text(lang.S.of(context).date)),
                                                            DataColumn(label: Text(lang.S.of(context).invoice)),
                                                            DataColumn(label: Text(lang.S.of(context).partyName)),
                                                            DataColumn(label: Text(lang.S.of(context).partyType)),
                                                            DataColumn(label: Text(lang.S.of(context).amount)),
                                                            DataColumn(label: Text(lang.S.of(context).due)),
                                                            DataColumn(label: Text(lang.S.of(context).status)),
                                                            DataColumn(label: Text(lang.S.of(context).setting)),
                                                          ],
                                                          rows: List.generate(paginatedList.length, (index) {
                                                            return DataRow(cells: [
                                                              ///______________S.L__________________________________________________
                                                              DataCell(
                                                                Text('${startIndex + index + 1}'),
                                                              ),

                                                              ///______________Date__________________________________________________
                                                              DataCell(
                                                                Text(
                                                                  paginatedList[index].purchaseDate.substring(0, 10),
                                                                ),
                                                              ),

                                                              ///____________Invoice_________________________________________________
                                                              DataCell(
                                                                Text(
                                                                  paginatedList[index].invoiceNumber,
                                                                ),
                                                              ),

                                                              ///______Party Name___________________________________________________________
                                                              DataCell(
                                                                Text(
                                                                  paginatedList[index].customerName,
                                                                ),
                                                              ),

                                                              ///___________Party Type______________________________________________

                                                              DataCell(
                                                                Text(
                                                                  paginatedList[index].paymentType.toString(),
                                                                ),
                                                              ),

                                                              ///___________Amount____________________________________________________
                                                              DataCell(
                                                                Text(
                                                                  '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].totalAmount.toString()) ?? 0)}',
                                                                ),
                                                              ),

                                                              ///___________Due____________________________________________________
                                                              DataCell(
                                                                Text(
                                                                  '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].dueAmount.toString()) ?? 0)}',
                                                                ),
                                                              ),

                                                              ///___________Due____________________________________________________

                                                              DataCell(
                                                                Text(
                                                                  paginatedList[index].isPaid! ? 'Paid' : "Due",
                                                                ),
                                                              ),

                                                              ///_______________actions_________________________________________________
                                                              DataCell(
                                                                settingProvider.when(data: (setting) {
                                                                  return Theme(
                                                                    data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                                    child: PopupMenuButton(
                                                                      surfaceTintColor: Colors.white,
                                                                      padding: EdgeInsets.zero,
                                                                      itemBuilder: (BuildContext bc) => [
                                                                        PopupMenuItem(
                                                                          child: GestureDetector(
                                                                            onTap: () async {
                                                                              await GeneratePdfAndPrint().printSaleInvoice(personalInformationModel: profile.value!, fromSaleReports: true, setting: setting, saleTransactionModel: paginatedList[index], context: context);
                                                                              // await Printing.layoutPdf(
                                                                              //   onLayout: (PdfPageFormat format) async =>
                                                                              //   await GeneratePdfAndPrint().generateSaleDocument(personalInformation: profile.value!, transactions: reTransaction[index]),
                                                                              // );
                                                                              // SaleInvoice(
                                                                              //   isPosScreen: false,
                                                                              //   transitionModel: reTransaction[index],
                                                                              //   personalInformationModel: profile.value!,
                                                                              // ).launch(context);
                                                                            },
                                                                            child: Row(
                                                                              children: [
                                                                                Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                                                const SizedBox(width: 4.0),
                                                                                Text(
                                                                                  lang.S.of(context).print,
                                                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        PopupMenuItem(
                                                                          child: settingProvider.when(data: (setting) {
                                                                            final dynamicInvoice = setting.companyName.isNotEmpty == true ? setting.companyName : invoiceFileName;
                                                                            // final pdfFotter = setting.companyName.isNotEmpty == true ? setting.companyName : appsName;
                                                                            return GestureDetector(
                                                                              onTap: () async {
                                                                                AnchorElement(href: "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(await generateSaleDocument(personalInformation: profile.value!, transactions: paginatedList[index], generalSetting: setting))}")
                                                                                  ..setAttribute("download", "${dynamicInvoice}_S-${reTransaction[index].invoiceNumber}.pdf")
                                                                                  ..click();
                                                                              },
                                                                              child: Row(
                                                                                children: [
                                                                                  Icon(MdiIcons.filePdfBox, size: 18.0, color: kTitleColor),
                                                                                  const SizedBox(width: 4.0),
                                                                                  Text(
                                                                                    lang.S.of(context).downloadPDF,
                                                                                    style: kTextStyle.copyWith(color: kTitleColor),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          }, error: (e, string) {
                                                                            return Text(e.toString());
                                                                          }, loading: () {
                                                                            return Center(child: CircularProgressIndicator());
                                                                          }),
                                                                        ),
                                                                      ],
                                                                      child: Center(
                                                                        child: Container(
                                                                            height: 18,
                                                                            width: 18,
                                                                            alignment: Alignment.centerRight,
                                                                            child: const Icon(
                                                                              Icons.more_vert_sharp,
                                                                              size: 18,
                                                                            )),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }, error: (e, stack) {
                                                                  return Text(e.toString());
                                                                }, loading: () {
                                                                  return Center(
                                                                    child: CircularProgressIndicator(),
                                                                  );
                                                                }),
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
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${lang.S.of(context).showing} ${((_currentPage - 1) * _saleReportPerPage + 1).toString()} to ${((_currentPage - 1) * _saleReportPerPage + _saleReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
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
                                                      onTap: _currentPage * _saleReportPerPage < reTransaction.length ? () => setState(() => _currentPage++) : null,
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
                                    : noDataFoundImage(text: lang.S.of(context).noReportFound),
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
                  }).visible(selected == 'Sale'),
                ),
              ),

              ///____________Sales_return_report_________________________________________________
              ResponsiveGridCol(
                  xs: selected == 'Sales Return' ? 12 : 0,
                  md: selected == 'Sales Return' ? 9 : 0,
                  lg: selected == 'Sales Return' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const SalesReturnWidget().visible(selected == 'Sales Return'),
                  )),

              ///____________Purchase_report_________________________________________________
              ResponsiveGridCol(
                  xs: selected == 'Purchase' ? 12 : 0,
                  md: selected == 'Purchase' ? 9 : 0,
                  lg: selected == 'Purchase' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const PurchaseReportWidget().visible(selected == 'Purchase'),
                  )),

              ///____________Purchase_Return_report_________________________________________________
              ResponsiveGridCol(
                  xs: selected == 'Purchase Return' ? 12 : 0,
                  md: selected == 'Purchase Return' ? 9 : 0,
                  lg: selected == 'Purchase Return' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: const PurchaseReturnWidget().visible(selected == 'Purchase Return'),
                  )),

              ///___________Due_report_______________________________________________________
              ResponsiveGridCol(
                  xs: selected == 'Due' ? 12 : 0,
                  md: selected == 'Due' ? 9 : 0,
                  lg: selected == 'Due' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const DueReportWidget().visible(selected == 'Due'),
                  )),

              ///__________Product_current_stocks_____________________________________________
              ResponsiveGridCol(xs: selected == 'Current Stock' ? 12 : 0, md: selected == 'Current Stock' ? 9 : 0, lg: selected == 'Current Stock' ? 9 : 0, child: const CurrentStockWidget().visible(selected == 'Current Stock')),

              ///___________Due_report_________________________________________________________
              ResponsiveGridCol(
                  xs: selected == 'Daily Transaction' ? 12 : 0,
                  md: selected == 'Daily Transaction' ? 9 : 0,
                  lg: selected == 'Daily Transaction' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const DailyTransaction().visible(selected == 'Daily Transaction'),
                  )),

              ///___________Quotation_report___________________________________________________
              ResponsiveGridCol(
                  xs: selected == 'Quotation Sale History' ? 12 : 0,
                  md: selected == 'Quotation Sale History' ? 9 : 0,
                  lg: selected == 'Quotation Sale History' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const QuotationReportWidget().visible(selected == 'Quotation Sale History'),
                  )),

              ResponsiveGridCol(
                  xs: selected == 'Loss/Profit report' ? 12 : 0,
                  md: selected == 'Loss/Profit report' ? 9 : 0,
                  lg: selected == 'Loss/Profit report' ? 9 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const LossProfitReport().visible(selected == 'Loss/Profit report'),
                  )),
            ]),
            // Visibility(visible: MediaQuery.of(context).size.height != 0, child: ),
          ],
        ),
      ),
    );
  }
}
