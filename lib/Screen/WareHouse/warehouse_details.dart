import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/product_model.dart';

import '../../Provider/product_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class WareHouseDetails extends StatefulWidget {
  const WareHouseDetails({super.key, required this.warehouseID, required this.warehouseName});

  final String warehouseID;
  final String warehouseName;

  static const String route = '/warehouse-details';

  @override
  State<WareHouseDetails> createState() => _WareHouseDetailsState();
}

class _WareHouseDetailsState extends State<WareHouseDetails> {
  int selectedItem = 10;
  int itemCount = 10;
  String searchItem = '';
  bool isRegularSelected = true;

  List<String> title = ['Product List', 'Expired List'];

  String isSelected = 'Product List';

  ScrollController mainScroll = ScrollController();
  int _productsPerPage = 10; // Default number of items to display
  int _currentPage = 1;
  final _horizontalScroll = ScrollController();

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
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          backgroundColor: kDarkWhite,
          body: Consumer(
            builder: (_, ref, watch) {
              final warehouse = ref.watch(warehouseProvider);
              AsyncValue<List<ProductModel>> productList = ref.watch(productProvider);
              return productList.when(
                data: (snapShot) {
                  List<ProductModel> showAbleProducts = [];
                  for (var element in snapShot) {
                    if (!isRegularSelected) {
                      if (((element.productName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.productName.contains(searchItem))) && element.expiringDate != null && ((DateTime.tryParse(element.expiringDate ?? '') ?? DateTime.now()).isBefore(DateTime.now().add(const Duration(days: 7))))) {
                        if (element.warehouseId == widget.warehouseID) {
                          showAbleProducts.add(element);
                        }
                      }
                    } else {
                      if (searchItem != '' && (element.productName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.productName.contains(searchItem))) {
                        if (element.warehouseId == widget.warehouseID) {
                          showAbleProducts.add(element);
                        }
                      } else if (searchItem == '') {
                        if (element.warehouseId == widget.warehouseID) {
                          showAbleProducts.add(element);
                        }
                      }
                    }
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ///________title and add product_______________________________________
                              Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                                child: Text(
                                  widget.warehouseName,
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Divider(
                                height: 1,
                                thickness: 1.0,
                                color: kDividerColor,
                              ),
                              const SizedBox(height: 10),

                              ///___________search________________________________________________
                              ResponsiveGridRow(children: [
                                ResponsiveGridCol(
                                  xs: 12,
                                  md: 6,
                                  lg: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                        hintText: (lang.S.of(context).searchWithProductName),
                                        suffixIcon: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(
                                            FeatherIcons.search,
                                            color: kTitleColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ]),
                              const SizedBox(height: 20),
                              showAbleProducts.isNotEmpty
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LayoutBuilder(
                                          builder: (BuildContext context, BoxConstraints constraints) {
                                            final kWidth = constraints.maxWidth;
                                            return LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Scrollbar(
                                                  thickness: 8,
                                                  thumbVisibility: true,
                                                  controller: _horizontalScroll,
                                                  radius: const Radius.circular(8),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    controller: _horizontalScroll,
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        minWidth: kWidth,
                                                      ),
                                                      child: Theme(
                                                        data: theme.copyWith(dividerTheme: const DividerThemeData(color: Colors.transparent)),
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
                                                              label: Text(lang.S.of(context).SL),
                                                            ),
                                                            DataColumn(label: Text(lang.S.of(context).image)),
                                                            DataColumn(
                                                              label: Flexible(
                                                                child: Text(
                                                                  lang.S.of(context).productName,
                                                                  //'Product Name',
                                                                  style: kTextStyle.copyWith(color: Colors.black, overflow: TextOverflow.ellipsis),
                                                                ),
                                                              ),
                                                            ),
                                                            DataColumn(label: Text(lang.S.of(context).category)),
                                                            DataColumn(label: Text(lang.S.of(context).retailer)),
                                                            DataColumn(label: Text(lang.S.of(context).dealer)),
                                                            DataColumn(label: Text(lang.S.of(context).wholesale)),
                                                            DataColumn(label: Text(lang.S.of(context).stock)),
                                                          ],
                                                          rows: List.generate(
                                                            _productsPerPage == -1
                                                                ? showAbleProducts.length
                                                                : (_currentPage - 1) * _productsPerPage + _productsPerPage <= showAbleProducts.length
                                                                    ? _productsPerPage
                                                                    : showAbleProducts.length - (_currentPage - 1) * _productsPerPage,
                                                            (index) {
                                                              final dataIndex = (_currentPage - 1) * _productsPerPage + index;
                                                              final product = showAbleProducts[dataIndex];
                                                              return DataRow(
                                                                cells: [
                                                                  DataCell(
                                                                    Text('${(_currentPage - 1) * _productsPerPage + index + 1}'),
                                                                  ),
                                                                  DataCell(
                                                                    Container(
                                                                      height: 40,
                                                                      width: 40,
                                                                      decoration: BoxDecoration(
                                                                        shape: BoxShape.circle,
                                                                        border: Border.all(color: kBorderColorTextField),
                                                                        image: DecorationImage(
                                                                            image: NetworkImage(
                                                                              product.productPicture,
                                                                            ),
                                                                            fit: BoxFit.cover),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      product.productName,
                                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      (!isRegularSelected && product.expiringDate != null) ? ((DateTime.tryParse(product.expiringDate ?? '') ?? DateTime.now()).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) ? lang.S.of(context).expired : "${lang.S.of(context).willExpireAt}\n${DateFormat.yMMMd().format(DateTime.tryParse(product.expiringDate ?? '') ?? DateTime.now())}") : product.productCategory,
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: kTextStyle.copyWith(color: (!isRegularSelected && product.expiringDate != null) ? Colors.red : kGreyTextColor),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      "$globalCurrency ${myFormat.format(double.tryParse(product.productSalePrice) ?? 0)}",
                                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      "$globalCurrency ${myFormat.format(double.tryParse(product.productDealerPrice) ?? 0)}",
                                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      "$globalCurrency ${myFormat.format(double.tryParse(product.productWholeSalePrice) ?? 0)}",
                                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      myFormat.format(double.tryParse(product.productStock) ?? 0),
                                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
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
                                                  '${lang.S.of(context).showing} ${((_currentPage - 1) * _productsPerPage + 1).toString()} ${lang.S.of(context).to} ${((_currentPage - 1) * _productsPerPage + _productsPerPage).clamp(0, showAbleProducts.length)} ${lang.S.of(context).OF} ${showAbleProducts.length} ${lang.S.of(context).entries}',
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
                                                      border: Border.all(color: kMainColor),
                                                      color: kMainColor,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '$_currentPage',
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    hoverColor: Colors.blue.withOpacity(0.1),
                                                    overlayColor: MaterialStateProperty.all<Color>(Colors.blue),
                                                    onTap: _currentPage * _productsPerPage < showAbleProducts.length ? () => setState(() => _currentPage++) : null,
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
                                                      child: Center(child: Text(lang.S.of(context).next)),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : EmptyWidget(title: lang.S.of(context).noProductFound),
                            ],
                          ),
                        ),
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
            },
          ),
        );
      },
    );
  }
}
