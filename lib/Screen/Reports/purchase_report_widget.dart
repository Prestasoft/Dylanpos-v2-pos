import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../PDF/purchase_invoice_pdf.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/purchase_transation_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';
import '../currency/currency_provider.dart';

class PurchaseReportWidget extends StatefulWidget {
  const PurchaseReportWidget({Key? key}) : super(key: key);

  @override
  State<PurchaseReportWidget> createState() => _PurchaseReportWidgetState();
}

class _PurchaseReportWidgetState extends State<PurchaseReportWidget> {
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
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(des)),
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

  double calculateTotalPurchase(List<dynamic> purchaseTransitionModel) {
    double total = 0.0;
    for (var element in purchaseTransitionModel) {
      total += element.totalAmount!;
    }
    return total;
  }

  double calculateTotalDue(List<dynamic> purchaseTransitionModel) {
    double total = 0.0;
    for (var element in purchaseTransitionModel) {
      total += element.dueAmount!;
    }
    return total;
  }

  final _horizontalScroll = ScrollController();
  int _purchaseReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (_, ref, watch) {
      final settingProvider = ref.watch(generalSettingProvider);
      //AsyncValue<List<PurchaseTransitionModel>> purchaseReport = ref.watch(purchaseTransitionProvider);
      final purchaseReports = ref.watch(purchaseTransitionProvider);
      return purchaseReports.when(data: (purchaseReport) {
        List<PurchaseTransactionModel> reTransaction = [];
        for (var element in purchaseReport.reversed.toList()) {
          if ((element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()) || element.customerName.toLowerCase().contains(searchItem.toLowerCase())) && (selectedDate.isBefore(DateTime.parse(element.purchaseDate)) || DateTime.parse(element.purchaseDate).isAtSameMomentAs(selectedDate)) && (selected2ndDate.isAfter(DateTime.parse(element.purchaseDate)) || DateTime.parse(element.purchaseDate).isAtSameMomentAs(selected2ndDate))) {
            reTransaction.add(element);
          }
        }

        // final pages = (reTransaction.length / _purchaseReportPerPage).ceil();
        //
        // final startIndex = (_currentPage - 1) * _purchaseReportPerPage;
        // // final endIndex = startIndex + _saleReportPerPage;
        // final endIndex = _purchaseReportPerPage == -1 ? reTransaction.length : startIndex + _purchaseReportPerPage;
        // final paginatedList = reTransaction.sublist(
        //   startIndex,
        //   endIndex > reTransaction.length ? reTransaction.length : endIndex,
        // );

        // Calculate pagination
        final pages = _purchaseReportPerPage == -1 ? 1 : (reTransaction.length / _purchaseReportPerPage).ceil();
        final startIndex = _purchaseReportPerPage == -1 ? 0 : (_currentPage - 1) * _purchaseReportPerPage;
        final endIndex = _purchaseReportPerPage == -1 ? reTransaction.length : (startIndex + _purchaseReportPerPage).clamp(0, reTransaction.length);

        // Get paginated transactions
        final paginatedList = reTransaction.sublist(startIndex, endIndex);

        final profile = ref.watch(profileDetailsProvider);
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
                                child: DropdownButtonHideUnderline(child: getMonth()),
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
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), border: Border.all(color: kGreyTextColor)),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 48,
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
                                myFormat.format(double.tryParse(reTransaction.length.toString()) ?? 0),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
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
                                '$globalCurrency ${myFormat.format(double.tryParse(calculateTotalDue(reTransaction).toString()) ?? 0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
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
                                '$globalCurrency ${myFormat.format(double.tryParse(calculateTotalPurchase(reTransaction).toString()) ?? 0)}',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
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
              padding: const EdgeInsets.all(10.0),
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
                      lang.S.of(context).purchaseTransaction,
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
                                value: _purchaseReportPerPage,
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
                                      _purchaseReportPerPage = -1; // Set to -1 for "All"
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

                  ///________sate_list_________________________________________________________
                  const SizedBox(height: 10.0),
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
                                                    paginatedList[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                                                  ),
                                                ),

                                                ///_______________actions_________________________________________________
                                                DataCell(
                                                  settingProvider.when(data: (setting) {
                                                    final dynamicInvoice = setting.companyName.isNotEmpty == true ? setting.companyName : invoiceFileName;
                                                    return Theme(
                                                      data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                      child: PopupMenuButton(
                                                        surfaceTintColor: Colors.white,
                                                        padding: EdgeInsets.zero,
                                                        itemBuilder: (BuildContext bc) => [
                                                          PopupMenuItem(
                                                            child: GestureDetector(
                                                              onTap: () async {
                                                                await GeneratePdfAndPrint().printPurchaseInvoice(personalInformationModel: profile.value!, purchaseTransactionModel: paginatedList[index], setting: setting);
                                                                // await Printing.layoutPdf(
                                                                //   onLayout: (PdfPageFormat format) async =>
                                                                //       await GeneratePdfAndPrint().generatePurchaseDocument(personalInformation: profile.value!, transactions: reTransaction[index]),
                                                                // );
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                                  const SizedBox(width: 4.0),
                                                                  Text(
                                                                    lang.S.of(context).printPdf,
                                                                    style: kTextStyle.copyWith(color: kTitleColor),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            child: GestureDetector(
                                                              onTap: () async {
                                                                AnchorElement(href: "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(await generatePurchaseDocument(personalInformation: profile.value!, setting: setting, transactions: reTransaction[index]))}")
                                                                  ..setAttribute("download", "${dynamicInvoice}_P-${reTransaction[index].invoiceNumber}.pdf")
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
                                                            ),
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
                                                    return Center(child: CircularProgressIndicator());
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
                                      '${lang.S.of(context).showing} ${((_currentPage - 1) * _purchaseReportPerPage + 1).toString()} to ${((_currentPage - 1) * _purchaseReportPerPage + _purchaseReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
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
                                        onTap: _currentPage * _purchaseReportPerPage < reTransaction.length ? () => setState(() => _currentPage++) : null,
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
                            // Container(
                            //   padding: const EdgeInsets.all(15),
                            //   decoration: const BoxDecoration(color: kbgColor),
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //     children: [
                            //       SizedBox(width: 35, child: Text(lang.S.of(context).SL)),
                            //       SizedBox(width: 82, child: Text(lang.S.of(context).date)),
                            //       SizedBox(width: 50, child: Text(lang.S.of(context).invoice)),
                            //       SizedBox(width: 100, child: Text(lang.S.of(context).partyName)),
                            //       SizedBox(width: 95, child: Text(lang.S.of(context).partyType)),
                            //       SizedBox(width: 70, child: Text(lang.S.of(context).amount)),
                            //       SizedBox(width: 60, child: Text(lang.S.of(context).due)),
                            //       SizedBox(width: 50, child: Text(lang.S.of(context).status)),
                            //       const SizedBox(width: 30, child: Icon(FeatherIcons.settings)),
                            //     ],
                            //   ),
                            // ),
                            // ListView.builder(
                            //   shrinkWrap: true,
                            //   physics: const NeverScrollableScrollPhysics(),
                            //   itemCount: reTransaction.length,
                            //   itemBuilder: (BuildContext context, int index) {
                            //     return Column(
                            //       children: [
                            //         Padding(
                            //           padding: const EdgeInsets.all(15),
                            //           child: Row(
                            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //             children: [
                            //               ///______________S.L__________________________________________________
                            //               SizedBox(
                            //                 width: 40,
                            //                 child: Text((index + 1).toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                            //               ),
                            //
                            //               ///______________Date__________________________________________________
                            //               SizedBox(
                            //                 width: 82,
                            //                 child: Text(
                            //                   reTransaction[index].purchaseDate.substring(0, 10),
                            //                   overflow: TextOverflow.ellipsis,
                            //                   maxLines: 2,
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor, overflow: TextOverflow.ellipsis),
                            //                 ),
                            //               ),
                            //
                            //               ///____________Invoice_________________________________________________
                            //               SizedBox(
                            //                 width: 50,
                            //                 child: Text(reTransaction[index].invoiceNumber,
                            //                     maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kGreyTextColor)),
                            //               ),
                            //
                            //               ///______Party Name___________________________________________________________
                            //               SizedBox(
                            //                 width: 100,
                            //                 child: Text(
                            //                   reTransaction[index].customerName,
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Party Type______________________________________________
                            //
                            //               SizedBox(
                            //                 width: 95,
                            //                 child: Text(
                            //                   reTransaction[index].paymentType.toString(),
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Amount____________________________________________________
                            //               SizedBox(
                            //                 width: 70,
                            //                 child: Text(
                            //                   myFormat.format(double.tryParse(reTransaction[index].totalAmount.toString()) ?? 0),
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Due____________________________________________________
                            //
                            //               SizedBox(
                            //                 width: 60,
                            //                 child: Text(
                            //                   myFormat.format(double.tryParse(reTransaction[index].dueAmount.toString()) ?? 0),
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///___________Due____________________________________________________
                            //
                            //               SizedBox(
                            //                 width: 50,
                            //                 child: Text(
                            //                   reTransaction[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                            //                   style: kTextStyle.copyWith(color: kGreyTextColor),
                            //                   maxLines: 2,
                            //                   overflow: TextOverflow.ellipsis,
                            //                 ),
                            //               ),
                            //
                            //               ///_______________actions_________________________________________________
                            //               SizedBox(
                            //                 width: 30,
                            //                 child: Theme(
                            //                   data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                            //                   child: PopupMenuButton(
                            //                     surfaceTintColor: Colors.white,
                            //                     padding: EdgeInsets.zero,
                            //                     itemBuilder: (BuildContext bc) => [
                            //                       PopupMenuItem(
                            //                         child: GestureDetector(
                            //                           onTap: () async {
                            //                             await GeneratePdfAndPrint()
                            //                                 .printPurchaseInvoice(personalInformationModel: profile.value!, purchaseTransactionModel: reTransaction[index]);
                            //                             // await Printing.layoutPdf(
                            //                             //   onLayout: (PdfPageFormat format) async =>
                            //                             //       await GeneratePdfAndPrint().generatePurchaseDocument(personalInformation: profile.value!, transactions: reTransaction[index]),
                            //                             // );
                            //                           },
                            //                           child: Row(
                            //                             children: [
                            //                               Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                            //                               const SizedBox(width: 4.0),
                            //                               Text(
                            //                                 lang.S.of(context).printPdf,
                            //                                 style: kTextStyle.copyWith(color: kTitleColor),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                         ),
                            //                       ),
                            //                       PopupMenuItem(
                            //                         child: GestureDetector(
                            //                           onTap: () async {
                            //                             AnchorElement(
                            //                                 href:
                            //                                     "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(await generatePurchaseDocument(personalInformation: profile.value!, transactions: reTransaction[index]))}")
                            //                               ..setAttribute("download", "${invoiceFileName}_P-${reTransaction[index].invoiceNumber}.pdf")
                            //                               ..click();
                            //                           },
                            //                           child: Row(
                            //                             children: [
                            //                               Icon(MdiIcons.filePdfBox, size: 18.0, color: kTitleColor),
                            //                               const SizedBox(width: 4.0),
                            //                               Text(
                            //                                 lang.S.of(context).downloadPDF,
                            //                                 style: kTextStyle.copyWith(color: kTitleColor),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                         ),
                            //                       ),
                            //                     ],
                            //                     child: Center(
                            //                       child: Container(
                            //                           height: 18,
                            //                           width: 18,
                            //                           alignment: Alignment.centerRight,
                            //                           child: const Icon(
                            //                             Icons.more_vert_sharp,
                            //                             size: 18,
                            //                           )),
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //         Container(
                            //           width: double.infinity,
                            //           height: 1,
                            //           color: kGreyTextColor.withOpacity(0.2),
                            //         )
                            //       ],
                            //     );
                            //   },
                            // ),
                          ],
                        )
                      : noDataFoundImage(text: lang.S.of(context).noReportFound),
                ],
              ),
            )
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

// Future<void> _createPDF() async {
//   //Create a PDF document.
//   PdfDocument document = PdfDocument();
//   //Add a page and draw text
//   document.pages
//       .add()
//       .graphics
//       .drawString('Hello World!', PdfStandardFont(PdfFontFamily.helvetica, 20), brush: PdfSolidBrush(PdfColor(0, 0, 0)), bounds: Rect.fromLTWH(20, 60, 150, 30));
//   //Save the document
//   List<int> bytes = await document.save();
//   //Dispose the document
//   document.dispose();
// }
