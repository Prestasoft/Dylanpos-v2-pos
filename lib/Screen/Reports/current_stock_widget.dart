import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/product_provider.dart';
import '../../model/product_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class CurrentStockWidget extends StatefulWidget {
  const CurrentStockWidget({super.key});

  @override
  State<CurrentStockWidget> createState() => _CurrentStockWidgetState();
}

class _CurrentStockWidgetState extends State<CurrentStockWidget> {
  String searchItem = '';
  final _horizontalScroll = ScrollController();
  int _stockReportPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, ref, __) {
        AsyncValue<List<ProductModel>> stockData = ref.watch(productProvider);
        return stockData.when(data: (report) {
          List<ProductModel> reTransaction = [];
          for (var element in report) {
            if (element.productName.removeAllWhiteSpace().toLowerCase().contains(searchItem.removeAllWhiteSpace().toLowerCase())) {
              reTransaction.add(element);
            }
          }
          final pages = (reTransaction.length / _stockReportPerPage).ceil();

          final startIndex = (_currentPage - 1) * _stockReportPerPage;
          // final endIndex = startIndex + _saleReportPerPage;
          final endIndex = _stockReportPerPage == -1 ? reTransaction.length : startIndex + _stockReportPerPage;
          final paginatedList = reTransaction.sublist(
            startIndex,
            endIndex > reTransaction.length ? reTransaction.length : endIndex,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        child: Text(
                          lang.S.of(context).stockReport,
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
                                    'Show-',
                                    style: theme.textTheme.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  DropdownButton<int>(
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    underline: const SizedBox(),
                                    value: _stockReportPerPage,
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
                                          _stockReportPerPage = -1; // Set to -1 for "All"
                                        } else {
                                          _stockReportPerPage = newValue ?? 10;
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
                                hintText: (lang.S.of(context).searchByName),
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
                                        scrollDirection: Axis.horizontal,
                                        controller: _horizontalScroll,
                                        child: Theme(
                                          data: theme.copyWith(
                                            dividerTheme: const DividerThemeData(color: Colors.transparent),
                                          ),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth,
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
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).SL,
                                                    //'S.L',
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).PRODUCTNAME,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).CATEGORY,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).PRICE,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).QTY,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).warehouse,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).STATUS,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).TOTALVALUE,
                                                  ),
                                                ),
                                                // const DataColumn(
                                                //   label: Icon(FeatherIcons.settings, color: kGreyTextColor),
                                                // ),
                                              ],
                                              rows: List.generate(
                                                paginatedList.length,
                                                (index) => DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text("${startIndex + index + 1}"),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].productName,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].productCategory,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        myFormat.format(double.tryParse(paginatedList[index].productSalePrice) ?? 0),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].productStock,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].warehouseName,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        paginatedList[index].productStock.toString().toInt() < 50 ? lang.S.of(context).low : lang.S.of(context).high,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        myFormat.format(double.tryParse((paginatedList[index].productSalePrice.toInt() * paginatedList[index].productStock.toInt()).toString()) ?? 0),
                                                      ),
                                                    ),
                                                    // DataCell(
                                                    //   PopupMenuButton(
                                                    //     icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                                    //     padding: EdgeInsets.zero,
                                                    //     itemBuilder: (BuildContext bc) => [
                                                    //       PopupMenuItem(
                                                    //         child: GestureDetector(
                                                    //           onTap: () {},
                                                    //           child: Row(
                                                    //             children: [
                                                    //               const Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                    //               const SizedBox(width: 4.0),
                                                    //               Text(
                                                    //                 'Print',
                                                    //                 style: kTextStyle.copyWith(color: kTitleColor),
                                                    //               ),
                                                    //             ],
                                                    //           ),
                                                    //         ),
                                                    //       ),
                                                    //     ],
                                                    //     onSelected: (value) {
                                                    //       Navigator.pushNamed(context, '$value');
                                                    //     },
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
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
                                          '${lang.S.of(context).showing} ${((_currentPage - 1) * _stockReportPerPage + 1).toString()} to ${((_currentPage - 1) * _stockReportPerPage + _stockReportPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
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
                                            onTap: _currentPage * _stockReportPerPage < reTransaction.length ? () => setState(() => _currentPage++) : null,
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
                          : EmptyWidget(title: lang.S.of(context).noReportFound)
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
    );
  }
}
