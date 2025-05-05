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
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../model/due_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';
import '../currency/currency_provider.dart';

class DueReportWidget extends StatefulWidget {
  const DueReportWidget({super.key});

  @override
  State<DueReportWidget> createState() => _DueReportWidgetState();
}

class _DueReportWidgetState extends State<DueReportWidget> {
  String selectedMonth = 'Este mes';

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

  List<String> month = [
    'Este mes',
    'Ultimo mes',
    'Ultimos 6 meses',
    'Este año',
    'Ver todo'
  ];

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
            case 'Este mes':
              {
                var date =
                    DateTime(DateTime.now().year, DateTime.now().month, 1)
                        .toString();

                selectedDate = DateTime.parse(date);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Ultimo mes':
              {
                selectedDate =
                    DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
                selected2ndDate =
                    DateTime(DateTime.now().year, DateTime.now().month, 0);
              }
              break;
            case 'Ultimos 6 meses':
              {
                selectedDate =
                    DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Este año':
              {
                selectedDate = DateTime(DateTime.now().year, 1, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Ver todo':
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

  double calculatePayableAmount(List<DueTransactionModel> dueTransactionModel) {
    double total = 0.0;
    for (var element in dueTransactionModel) {
      total += element.totalDue!;
    }
    return total;
  }

  double calculateDueAmount(List<DueTransactionModel> dueTransactionModel) {
    double total = 0.0;
    for (var element in dueTransactionModel) {
      total += element.dueAmountAfterPay!;
    }
    return total;
  }

  final _horizontalScroll = ScrollController();
  int _dueReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (_, ref, watch) {
      final dueReport = ref.watch(dueTransactionProvider);
      final settingProvider = ref.watch(generalSettingProvider);
      return dueReport.when(data: (dueReport) {
        List<DueTransactionModel> reTransaction = [];
        for (var element in dueReport.reversed.toList()) {
          if ((element.invoiceNumber
                      .toLowerCase()
                      .contains(searchItem.toLowerCase()) ||
                  element.customerName
                      .toLowerCase()
                      .contains(searchItem.toLowerCase())) &&
              (selectedDate.isBefore(DateTime.parse(element.purchaseDate)) ||
                  DateTime.parse(element.purchaseDate)
                      .isAtSameMomentAs(selectedDate)) &&
              (selected2ndDate.isAfter(DateTime.parse(element.purchaseDate)) ||
                  DateTime.parse(element.purchaseDate)
                      .isAtSameMomentAs(selected2ndDate))) {
            reTransaction.add(element);
          }
        }

        // final pages = (reTransaction.length / _dueReportPerPage).ceil();
        //
        // final startIndex = (_currentPage - 1) * _dueReportPerPage;
        // // final endIndex = startIndex + _saleReportPerPage;
        // final endIndex = _dueReportPerPage == -1 ? reTransaction.length : startIndex + _dueReportPerPage;
        // final paginatedList = reTransaction.sublist(
        //   startIndex,
        //   endIndex > reTransaction.length ? reTransaction.length : endIndex,
        // );

        // Calculate pagination
        final pages = _dueReportPerPage == -1
            ? 1
            : (reTransaction.length / _dueReportPerPage).ceil();
        final startIndex = _dueReportPerPage == -1
            ? 0
            : (_currentPage - 1) * _dueReportPerPage;
        final endIndex = _dueReportPerPage == -1
            ? reTransaction.length
            : (startIndex + _dueReportPerPage).clamp(0, reTransaction.length);

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
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                child: DropdownButtonHideUnderline(
                                    child: getMonth()),
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
                                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
                                                '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
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
                                myFormat.format(double.tryParse(
                                        reTransaction.length.toString()) ??
                                    0),
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
                                '$globalCurrency ${myFormat.format(double.tryParse(calculateDueAmount(reTransaction).toString()) ?? 0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 18),
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
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFFFED3D3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$globalCurrency${myFormat.format(double.tryParse(calculatePayableAmount(reTransaction).toString()) ?? 0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 18),
                              ),
                              Text(
                                lang.S.of(context).totalPaid,
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
                      lang.S.of(context).dueTransaction,
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
                  // Container(
                  //   height: 40.0,
                  //   width: 300,
                  //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), border: Border.all(color: kGreyTextColor.withOpacity(0.1))),
                  //   child: AppTextField(
                  //     showCursor: true,
                  //     cursorColor: kTitleColor,
                  //     onChanged: (value) {
                  //       setState(() {
                  //         searchItem = value;
                  //       });
                  //     },
                  //     textFieldType: TextFieldType.NAME,
                  //     decoration: kInputDecoration.copyWith(
                  //       contentPadding: const EdgeInsets.all(10.0),
                  //       hintText: (lang.S.of(context).searchByInvoice),
                  //       hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                  //       border: InputBorder.none,
                  //       enabledBorder: const OutlineInputBorder(
                  //         borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  //         borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                  //       ),
                  //       focusedBorder: const OutlineInputBorder(
                  //         borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  //         borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                  //       ),
                  //       suffixIcon: Padding(
                  //         padding: const EdgeInsets.all(4.0),
                  //         child: Container(
                  //           padding: const EdgeInsets.all(2.0),
                  //           decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.circular(30.0),
                  //             color: kGreyTextColor.withOpacity(0.1),
                  //           ),
                  //           child: const Icon(
                  //             FeatherIcons.search,
                  //             color: kTitleColor,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                                value: _dueReportPerPage,
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
                                      _dueReportPerPage =
                                          -1; // Set to -1 for "All"
                                    } else {
                                      _dueReportPerPage = newValue ?? 10;
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
                                                      .partyType)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .amount)),
                                              DataColumn(
                                                  label: Text(
                                                      lang.S.of(context).due)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .status)),
                                              DataColumn(
                                                  label: Text(lang.S
                                                      .of(context)
                                                      .setting)),
                                            ],
                                            rows: List.generate(
                                                paginatedList.length, (index) {
                                              return DataRow(cells: [
                                                ///______________S.L__________________________________________________
                                                DataCell(
                                                  Text(
                                                    (index +
                                                            1 +
                                                            (_currentPage - 1) *
                                                                _dueReportPerPage)
                                                        .toString(),
                                                  ),
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
                                                DataCell(Text(
                                                  paginatedList[index]
                                                      .invoiceNumber,
                                                )),

                                                ///______Party Name___________________________________________________________
                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                        .customerName,
                                                  ),
                                                ),

                                                ///___________Party Type______________________________________________

                                                DataCell(
                                                  Text(
                                                    paginatedList[index]
                                                        .paymentType
                                                        .toString(),
                                                  ),
                                                ),

                                                ///___________Amount____________________________________________________
                                                DataCell(
                                                  Text(
                                                    '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].totalDue.toString()) ?? 0)}',
                                                  ),
                                                ),

                                                ///___________Due____________________________________________________

                                                DataCell(
                                                  Text(
                                                    '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].dueAmountAfterPay.toString()) ?? 0)}',
                                                  ),
                                                ),

                                                ///___________Due____________________________________________________

                                                DataCell(
                                                  Text(
                                                    paginatedList[index].isPaid!
                                                        ? lang.S
                                                            .of(context)
                                                            .paid
                                                        : lang.S
                                                            .of(context)
                                                            .due,
                                                  ),
                                                ),

                                                ///_______________actions_________________________________________________
                                                DataCell(
                                                  settingProvider.when(
                                                      data: (setting) {
                                                    final dynamicInvoice = setting
                                                                .companyName
                                                                .isNotEmpty ==
                                                            true
                                                        ? setting.companyName
                                                        : invoiceFileName;
                                                    return Theme(
                                                      data: ThemeData(
                                                          highlightColor:
                                                              dropdownItemColor,
                                                          focusColor:
                                                              dropdownItemColor,
                                                          hoverColor:
                                                              dropdownItemColor),
                                                      child: PopupMenuButton(
                                                        surfaceTintColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        itemBuilder:
                                                            (BuildContext bc) =>
                                                                [
                                                          PopupMenuItem(
                                                            onTap: () async {
                                                              await GeneratePdfAndPrint().printDueInvoice(
                                                                  personalInformationModel:
                                                                      profile
                                                                          .value!,
                                                                  dueTransactionModel:
                                                                      paginatedList[
                                                                          index],
                                                                  setting:
                                                                      setting);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                    MdiIcons
                                                                        .printer,
                                                                    size: 18.0,
                                                                    color:
                                                                        kTitleColor),
                                                                const SizedBox(
                                                                    width: 4.0),
                                                                Text(
                                                                  lang.S
                                                                      .of(context)
                                                                      .print,
                                                                  style: kTextStyle
                                                                      .copyWith(
                                                                          color:
                                                                              kTitleColor),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            onTap: () async {
                                                              AnchorElement(
                                                                  href:
                                                                      "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(await GeneratePdfAndPrint().generateDueDocument(personalInformation: profile.value!, transactions: reTransaction[index], setting: setting))}")
                                                                ..setAttribute(
                                                                    "download",
                                                                    "${dynamicInvoice}_D-${paginatedList[index].invoiceNumber}.pdf")
                                                                ..click();
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                    MdiIcons
                                                                        .filePdfBox,
                                                                    size: 18.0,
                                                                    color:
                                                                        kTitleColor),
                                                                const SizedBox(
                                                                    width: 4.0),
                                                                Text(
                                                                  lang.S
                                                                      .of(context)
                                                                      .downloadPDF,
                                                                  style: kTextStyle
                                                                      .copyWith(
                                                                          color:
                                                                              kTitleColor),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                        child: Center(
                                                          child: Container(
                                                              height: 18,
                                                              width: 18,
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: const Icon(
                                                                Icons
                                                                    .more_vert_sharp,
                                                                size: 18,
                                                              )),
                                                        ),
                                                      ),
                                                    );
                                                  }, error: (e, stack) {
                                                    return Text(e.toString());
                                                  }, loading: () {
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${lang.S.of(context).showing} ${((_currentPage - 1) * _dueReportPerPage + 1).toString()} to ${((_currentPage - 1) * _dueReportPerPage + _dueReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
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
                                                    _dueReportPerPage <
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
                      : noDataFoundImage(
                          text: lang.S.of(context).noReportFound),
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
