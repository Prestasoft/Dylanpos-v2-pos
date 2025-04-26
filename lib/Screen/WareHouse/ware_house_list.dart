import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
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
import '../currency/currency_provider.dart';
import 'edit_warehouse.dart';

class WareHouseList extends StatefulWidget {
  const WareHouseList({super.key});

  static const String route = '/warehouse_list';

  @override
  State<WareHouseList> createState() => _WareHouseListState();
}

class _WareHouseListState extends State<WareHouseList> {
  int selectedItem = 10;
  int itemCount = 10;
  String searchItem = '';
  bool isRegularSelected = true;

  List<String> title = ['Product List', 'Expired List'];

  String isSelected = 'Product List';

  ScrollController mainScroll = ScrollController();

  String warehouseName = '';
  String address = '';
  DateTime id = DateTime.now();

  bool checkWarehouse({required List<WareHouseModel> allList, required String category}) {
    for (var element in allList) {
      if (element.id == id.toString()) {
        return false;
      }
    }
    return true;
  }

  int selectedIndex = -1;

  void deleteExpenseCategory({required String incomeCategoryName, required WidgetRef updateRef, required BuildContext context}) async {
    EasyLoading.show(status: '${lang.S.of(context).deleting}..');
    String expenseKey = '';
    final userId = await getUserID();
    await FirebaseDatabase.instance.ref(userId).child('Warehouse List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['warehouseName'].toString() == incomeCategoryName) {
          expenseKey = element.key.toString();
        }
      }
    });
    DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Warehouse List/$expenseKey");
    await ref.remove();
    updateRef.refresh(warehouseProvider);
    EasyLoading.showSuccess(lang.S.of(context).done).then(
      (value) => GoRouter.of(context).pop(),
    );
  }

  void _onRowSelected(int index, bool selected) {
    setState(() {
      selectedIndex = selected ? index : -1;
    });
  }

  num grandTotalStockValue = 0;

  // double grandTotal = calculateGrandTotal(showAbleProducts, productSnap);

  double calculateGrandTotal(List<WareHouseModel> showAbleProducts, List<ProductModel> productSnap) {
    double grandTotal = 0;
    // grandTotal = 0;
    for (var index = 0; index < showAbleProducts.length; index++) {
      for (var element in productSnap) {
        if (showAbleProducts[index].id == element.warehouseId) {
          double stockValue = (double.tryParse(element.productStock) ?? 0) * (double.tryParse(element.productSalePrice) ?? 0);
          grandTotal += stockValue;
        }
      }
    }

    return grandTotal;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _productPerPage = 10; // Default number of items to display
  int _currentPage = 1;

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
              return warehouse.when(
                data: (snapShot) {
                  List<String> names = [];
                  for (var element in snapShot) {
                    names.add(element.warehouseName.removeAllWhiteSpace().toLowerCase());
                  }
                  return productList.when(
                    data: (productSnap) {
                      List<WareHouseModel> showAbleProducts = [];
                      for (var element in snapShot) {
                        if (element.warehouseName.removeAllWhiteSpace().toLowerCase().contains(searchItem.toLowerCase()) || element.warehouseName.contains(searchItem)) {
                          showAbleProducts.add(element);
                        }
                      }
                      final pages = (showAbleProducts.length / _productPerPage).ceil();
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ///________title and add product_______________________________________
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            lang.S.of(context).warehouseList,
                                            //'Warehouse List',
                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Flexible(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                                            label: Text(
                                              lang.S.of(context).addWareHouse,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return StatefulBuilder(
                                                    builder: (context, setStates) {
                                                      return Dialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(20.0),
                                                        ),
                                                        child: Container(
                                                          decoration: const BoxDecoration(
                                                            borderRadius: BorderRadius.all(Radius.circular(20)),
                                                            color: kWhite,
                                                          ),
                                                          width: 600,
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.all(12.0),
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        Flexible(
                                                                          child: Text(
                                                                            lang.S.of(context).addNewWareHouse,
                                                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                                                            maxLines: 2,
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        Flexible(
                                                                          child: IconButton(
                                                                              onPressed: () {
                                                                                GoRouter.of(context).pop();
                                                                              },
                                                                              icon: const Icon(
                                                                                FeatherIcons.x,
                                                                                size: 20,
                                                                              )),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const Divider(
                                                                    thickness: 1.0,
                                                                    color: kNeutral300,
                                                                    height: 1,
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets.all(12.0),
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          lang.S.of(context).pleaseEnterValidData,
                                                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                                                        ),
                                                                        const SizedBox(height: 20.0),
                                                                        TextFormField(
                                                                          onChanged: (value) {
                                                                            warehouseName = value;
                                                                          },
                                                                          showCursor: true,
                                                                          cursorColor: kTitleColor,
                                                                          keyboardType: TextInputType.name,
                                                                          decoration: InputDecoration(
                                                                            //labelText: 'Warehouse Name',
                                                                            labelText: lang.S.of(context).warehouseName,
                                                                            //hintText: 'Enter name',
                                                                            hintText: lang.S.of(context).enterName,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 20.0),
                                                                        TextFormField(
                                                                          onChanged: (value) {
                                                                            address = value;
                                                                          },
                                                                          showCursor: true,
                                                                          cursorColor: kTitleColor,
                                                                          keyboardType: TextInputType.name,
                                                                          decoration: InputDecoration(
                                                                            //labelText: 'Address',
                                                                            labelText: lang.S.of(context).address,
                                                                            // hintText: 'Enter address',
                                                                            hintText: lang.S.of(context).enterAddress,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  ResponsiveGridRow(children: [
                                                                    ResponsiveGridCol(
                                                                      xs: 12,
                                                                      md: 6,
                                                                      lg: 6,
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.all(10),
                                                                        child: ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: Colors.red,
                                                                          ),
                                                                          onPressed: () => GoRouter.of(context).pop(),
                                                                          child: Column(
                                                                            children: [
                                                                              Text(
                                                                                lang.S.of(context).cancel,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    ResponsiveGridCol(
                                                                      xs: 12,
                                                                      md: 6,
                                                                      lg: 6,
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.all(10.0),
                                                                        child: ElevatedButton(
                                                                          onPressed: () async {
                                                                            if (warehouseName != '' && !names.contains(warehouseName.toLowerCase().removeAllWhiteSpace())) {
                                                                              WareHouseModel warehouse = WareHouseModel(warehouseName: warehouseName, warehouseAddress: address, id: id.toString());
                                                                              try {
                                                                                EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                                                                final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Warehouse List');
                                                                                await productInformationRef.push().set(warehouse.toJson());
                                                                                EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));

                                                                                ///____provider_refresh____________________________________________
                                                                                ref.refresh(warehouseProvider);

                                                                                Future.delayed(const Duration(milliseconds: 100), () {
                                                                                  GoRouter.of(context).pop();
                                                                                });
                                                                              } catch (e) {
                                                                                EasyLoading.dismiss();
                                                                                //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                                              }
                                                                            } else if (names.contains(warehouseName.toLowerCase().removeAllWhiteSpace())) {
                                                                              //EasyLoading.showError('Category Name Already Exists');
                                                                              EasyLoading.showError(lang.S.of(context).categoryNameAlreadyExists);
                                                                            } else {
                                                                              // EasyLoading.showError('Enter Warehouse Name');
                                                                              EasyLoading.showError(lang.S.of(context).enterWarehouseName);
                                                                            }
                                                                          },
                                                                          child: Text(
                                                                            lang.S.of(context).saveAndPublish,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ]),
                                                                  const SizedBox(height: 10),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(
                                    height: 1,
                                    thickness: 1.0,
                                    color: kDividerColor,
                                  ),
                                  const SizedBox(height: 10),

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
                                                value: _productPerPage,
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
                                                      _productPerPage = -1; // Set to -1 for "All"
                                                    } else {
                                                      _productPerPage = newValue ?? 10;
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
                                          padding: const EdgeInsets.all(10),
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
                                              hintText: (lang.S.of(context).searchWithName),
                                              suffixIcon: const Icon(
                                                FeatherIcons.search,
                                                color: kNeutral400,
                                              ),
                                            ),
                                          ),
                                        )),
                                  ]),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      height: 80,
                                      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 100.0, 10.0),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: const Color(0xFFD6FFDF)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            // '$globalCurrency${grandTotal.toStringAsFixed(2)}',
                                            '$globalCurrency${myFormat.format(double.tryParse(calculateGrandTotal(showAbleProducts, productSnap).toString()) ?? 0)}',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            lang.S.of(context).totalValue,
                                            //'Total value',
                                            style: kTextStyle.copyWith(color: kGreyTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  LayoutBuilder(
                                    builder: (BuildContext context, BoxConstraints constraints) {
                                      final kWidth = constraints.maxWidth;
                                      return Scrollbar(
                                        thickness: 8,
                                        thumbVisibility: true,
                                        controller: _horizontalScroll,
                                        radius: const Radius.circular(8),
                                        child: SingleChildScrollView(
                                          controller: _horizontalScroll,
                                          scrollDirection: Axis.horizontal,
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
                                                  DataColumn(label: Text(lang.S.of(context).warehouseName)),
                                                  DataColumn(label: Text(lang.S.of(context).address)),
                                                  DataColumn(label: Center(child: Text(lang.S.of(context).stockQuantity))),
                                                  DataColumn(label: Center(child: Text(lang.S.of(context).stockValue))),
                                                  DataColumn(
                                                      label: Text(
                                                    lang.S.of(context).action,
                                                    //'Action',
                                                    style: kTextStyle.copyWith(color: Colors.black, overflow: TextOverflow.ellipsis),
                                                  )),
                                                ],
                                                rows: List.generate(
                                                  _productPerPage == -1
                                                      ? showAbleProducts.length
                                                      : (_currentPage - 1) * _productPerPage + _productPerPage <= showAbleProducts.length
                                                          ? _productPerPage
                                                          : showAbleProducts.length - (_currentPage - 1) * _productPerPage,
                                                  (index) {
                                                    num stockValue = 0;
                                                    num totalStock = 0;
                                                    for (var element in productSnap) {
                                                      if (showAbleProducts[index].id == element.warehouseId) {
                                                        stockValue += (num.tryParse(element.productStock) ?? 0) * (num.tryParse(element.productSalePrice) ?? 0);
                                                        totalStock += (num.tryParse(element.productStock) ?? 0);
                                                      }
                                                    }
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Text('${(_currentPage - 1) * _productPerPage + index + 1}'),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            showAbleProducts[index].warehouseName,
                                                            style: kTextStyle.copyWith(color: kGreyTextColor),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            showAbleProducts[index].warehouseAddress,
                                                            style: kTextStyle.copyWith(color: kGreyTextColor),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Padding(
                                                            padding: EdgeInsets.only(left: kWidth * 0.05),
                                                            child: Text(
                                                              totalStock.toString(),
                                                              style: kTextStyle.copyWith(color: kGreyTextColor),
                                                              maxLines: 2,
                                                              textAlign: TextAlign.center,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Padding(
                                                            padding: EdgeInsets.only(left: kWidth * 0.01),
                                                            child: Text(
                                                              '$globalCurrency${stockValue.toString()}',
                                                              style: kTextStyle.copyWith(color: kGreyTextColor),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          StatefulBuilder(
                                                            builder: (BuildContext context, void Function(void Function()) setState) {
                                                              return Theme(
                                                                data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                                child: PopupMenuButton(
                                                                  surfaceTintColor: Colors.white,
                                                                  padding: EdgeInsets.zero,
                                                                  itemBuilder: (BuildContext bc) => [
                                                                    PopupMenuItem(
                                                                      onTap: () => context.go(
                                                                        '/warehouse-details/${showAbleProducts[index].id}',
                                                                        extra: showAbleProducts[index].warehouseName,
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          const Icon(Icons.remove_red_eye, size: 18.0, color: kNeutral500),
                                                                          const SizedBox(width: 4.0),
                                                                          Text(
                                                                            lang.S.of(context).view,
                                                                            // 'View',
                                                                            style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    if (showAbleProducts[index].warehouseName != 'InHouse')
                                                                      PopupMenuItem(
                                                                        onTap: () {
                                                                          snapShot[index].warehouseName == 'InHouse'
                                                                              ? EasyLoading.showInfo(lang.S.of(context).inHouseCantBeEdit)
                                                                              : showDialog(
                                                                                  barrierDismissible: false,
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(
                                                                                      builder: (context, setStates) {
                                                                                        return Dialog(
                                                                                          shape: RoundedRectangleBorder(
                                                                                            borderRadius: BorderRadius.circular(20.0),
                                                                                          ),
                                                                                          child: EditWarehouse(
                                                                                            listOfWarehouse: showAbleProducts,
                                                                                            warehouseModel: showAbleProducts[index],
                                                                                            menuContext: bc,
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                  },
                                                                                );
                                                                        },
                                                                        child: Row(
                                                                          children: [
                                                                            const Icon(IconlyLight.edit, size: 20.0, color: kNeutral500),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).edit,
                                                                              style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),

                                                                    ///____________Delete___________________________________________
                                                                    if (showAbleProducts[index].warehouseName != 'InHouse')
                                                                      PopupMenuItem(
                                                                        onTap: () {
                                                                          if (checkWarehouse(allList: warehouse.value!, category: showAbleProducts[index].warehouseName)) {
                                                                            showAbleProducts[index].warehouseName == 'InHouse'
                                                                                ? EasyLoading.showInfo(lang.S.of(context).inHouseCantBeDelete)
                                                                                : showDialog(
                                                                                    barrierDismissible: false,
                                                                                    context: context,
                                                                                    builder: (BuildContext dialogContext) {
                                                                                      return Padding(
                                                                                        padding: const EdgeInsets.all(8.0),
                                                                                        child: Center(
                                                                                          child: Container(
                                                                                            width: 500,
                                                                                            decoration: const BoxDecoration(
                                                                                              color: Colors.white,
                                                                                              borderRadius: BorderRadius.all(
                                                                                                Radius.circular(15),
                                                                                              ),
                                                                                            ),
                                                                                            child: Padding(
                                                                                              padding: const EdgeInsets.all(20.0),
                                                                                              child: Column(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    lang.S.of(context).areYouWantToDeleteThisCustomer,
                                                                                                    textAlign: TextAlign.center,
                                                                                                    style: theme.textTheme.titleLarge?.copyWith(
                                                                                                      fontWeight: FontWeight.w600,
                                                                                                    ),
                                                                                                  ),
                                                                                                  const SizedBox(height: 30),
                                                                                                  Row(
                                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                                    children: [
                                                                                                      ElevatedButton(
                                                                                                        style: ElevatedButton.styleFrom(
                                                                                                          backgroundColor: Colors.red,
                                                                                                        ),
                                                                                                        child: Text(
                                                                                                          lang.S.of(context).cancel,
                                                                                                        ),
                                                                                                        onPressed: () {
                                                                                                          // Navigator.pop(dialogContext);
                                                                                                          // Navigator.pop(bc);
                                                                                                          GoRouter.of(context).pop();
                                                                                                        },
                                                                                                      ),
                                                                                                      const SizedBox(width: 30),
                                                                                                      ElevatedButton(
                                                                                                        child: Text(
                                                                                                          lang.S.of(context).delete,
                                                                                                        ),
                                                                                                        onPressed: () {
                                                                                                          deleteExpenseCategory(
                                                                                                            incomeCategoryName: showAbleProducts[index].warehouseName,
                                                                                                            updateRef: ref,
                                                                                                            context: dialogContext,
                                                                                                          );
                                                                                                          // Navigator.pop(dialogContext);
                                                                                                        },
                                                                                                      ),
                                                                                                    ],
                                                                                                  )
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    });
                                                                          } else {
                                                                            EasyLoading.showError(lang.S.of(context).thisCategoryCannotBeDeleted);
                                                                          }
                                                                        },
                                                                        child: Row(
                                                                          children: [
                                                                            const HugeIcon(
                                                                              icon: HugeIcons.strokeRoundedDelete02,
                                                                              color: kNeutral500,
                                                                              size: 20.0,
                                                                            ),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).delete,
                                                                              style: theme.textTheme.bodyLarge?.copyWith(color: kNeutral500),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                  ],
                                                                  onSelected: (value) {
                                                                    Navigator.pushNamed(context, '$value');
                                                                  },
                                                                  child: const Icon(
                                                                    Icons.more_vert_sharp,
                                                                    size: 18,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                      // selected: selectedIndex == 0,
                                                      // mouseCursor: WidgetStateMouseCursor.clickable,
                                                      // color: _onRowSelected == selectedIndex ? WidgetStateProperty.all<Color>(Colors.green) : null,
                                                      // onSelectChanged: (selected) {
                                                      //   _onRowSelected(0, selected!);
                                                      //   Navigator.push(
                                                      //     context,
                                                      //     MaterialPageRoute(
                                                      //       builder: (context) => WareHouseDetails(warehouseID: snapShot[index].id, warehouseName: snapShot[index].warehouseName),
                                                      //     ),
                                                      //   );
                                                      // },
                                                    );
                                                  },
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
                                            '${lang.S.of(context).showing} ${((_currentPage - 1) * _productPerPage + 1).toString()} to ${((_currentPage - 1) * _productPerPage + _productPerPage).clamp(0, showAbleProducts.length)} of ${showAbleProducts.length} entries',
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
                                              hoverColor: Colors.blue.withOpacity(0.1),
                                              overlayColor: MaterialStateProperty.all<Color>(Colors.blue),
                                              onTap: _currentPage * _productPerPage < showAbleProducts.length ? () => setState(() => _currentPage++) : null,
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
