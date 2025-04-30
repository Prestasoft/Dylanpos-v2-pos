import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/category_model.dart';
import '../../model/customer_model.dart';
import '../../model/product_model.dart';
import '../../model/sale_transaction_model.dart';
import '../../subscription.dart';
import '../Product/WarebasedProduct.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Calculator/calculator.dart';
import '../Widgets/Pop UP/Pos Sale/add_item_popup.dart';
import '../Widgets/Pop UP/Pos Sale/due_sale_popup.dart';
import '../Widgets/Pop UP/Pos Sale/sale_list_popup.dart';
import '../currency/currency_provider.dart';

class PosSale extends StatefulWidget {
  const PosSale({super.key, this.quotation});

  // static const String route = '/pos-sales';

  final SaleTransactionModel? quotation;

  @override
  State<PosSale> createState() => _PosSaleState();
}

class _PosSaleState extends State<PosSale> {
  List<AddToCartModel> cartList = [];
  addFocus() {
    FocusNode f = FocusNode();
    f.addListener(
      () {
        if (!f.hasFocus) {
          setState(() {});
        }
      },
    );
    productFocusNode.add(f);
  }

  List<FocusNode> productFocusNode = [];

  String searchProductCode = '';

  String isSelected = 'Categories';
  String selectedCategory = 'Categories';
  String? selectedUserId = 'Guest';
  CustomerModel selectedUserName = CustomerModel(customerName: "Guest", phoneNumber: "00", type: "Guest", customerAddress: '', emailAddress: '', profilePicture: '', openingBalance: '0', remainedBalance: '0', dueAmount: '0', gst: '', receiveWhatsappUpdates: false);

  String? invoiceNumber;
  String previousDue = "0";
  FocusNode nameFocus = FocusNode();

  DropdownButton<String> getResult(List<CustomerModel> model) {
    List<DropdownMenuItem<String>> dropDownItems = [const DropdownMenuItem(value: 'Guest', child: Text('Guest'))];
    for (var des in model) {
      var item = DropdownMenuItem(
        value: des.phoneNumber,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text('${des.customerName} ${des.phoneNumber}')),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      isExpanded: true,
      value: selectedUserId,
      onChanged: (value) {
        setState(() {
          selectedUserId = value!;
          for (var element in model) {
            if (element.phoneNumber == selectedUserId) {
              selectedUserName = element;
              previousDue = element.dueAmount;
              selectedCustomerType == element.type ? null : {selectedCustomerType = element.type, cartList.clear(), productFocusNode.clear()};
            } else if (selectedUserId == 'Guest') {
              previousDue = '0';
              selectedCustomerType = 'Retailer';
            }
          }
          invoiceNumber = '';
        });
      },
    );
  }

  dynamic productPriceChecker({required ProductModel product, required String customerType}) {
    if (customerType == "Retailer") {
      return product.productSalePrice;
    } else if (customerType == "Wholesaler") {
      return product.productWholeSalePrice == '' ? '0' : product.productWholeSalePrice;
    } else if (customerType == "Dealer") {
      return product.productDealerPrice == '' ? '0' : product.productDealerPrice;
    } else if (customerType == "Guest") {
      return product.productSalePrice;
    }
  }

  String getTotalAmount() {
    double total = 0.0;
    for (var item in cartList) {
      total = total + (double.parse(item.subTotal) * item.quantity);
    }
    return total.toStringAsFixed(2);
  }

  bool uniqueCheck(String code) {
    bool isUnique = false;
    for (var item in cartList) {
      if (item.productId == code) {
        if (item.quantity < item.stock!) {
          item.quantity += 1;
        } else {
          EasyLoading.showError('Out of Stock');
        }

        isUnique = true;
        break;
      }
    }
    return isUnique;
  }

  bool uniqueCheckForSerial({required String code, required List<dynamic> newSerialNumbers}) {
    bool isUnique = false;
    for (var item in cartList) {
      if (item.productId == code) {
        item.serialNumber = newSerialNumbers;
        item.quantity = newSerialNumbers.isEmpty ? 1 : newSerialNumbers.length;
        // item.serialNumber?.add(newSerialNumbers);

        isUnique = true;
        break;
      }
    }
    return isUnique;
  }

  List<String> customerType = [
    'Retailer',
    'Wholesaler',
    'Dealer',
  ];

  String selectedCustomerType = 'Retailer';

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in customerType) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(overflow: TextOverflow.ellipsis, color: kTitleColor),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedCustomerType,
      onChanged: (value) {
        setState(() {
          cartList.clear();
          selectedCustomerType = value!;
        });
      },
    );
  }

  DateTime selectedDueDate = DateTime.now();

  Future<void> _selectedDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDueDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  void showDueListPopUp() {
    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: const DueSalePopUp(),
          );
        },
      );
    }
  }

  void showSaleListPopUp() {
    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const SaleListPopUP());
            },
          );
        },
      );
    }
  }

  void showAddItemPopUp() {
    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const AddItemPopUP(),
              );
            },
          );
        },
      );
    }
  }

  void showHoldPopUp() {
    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: SizedBox(
                  width: 500,
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              lang.S.of(context).hold,
                              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 20.0),
                            ),
                            const Spacer(),
                            const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {finish(context)})
                          ],
                        ),
                      ),
                      const Divider(thickness: 1.0, color: kLitGreyColor),
                      const SizedBox(height: 10.0),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            AppTextField(
                              showCursor: true,
                              cursorColor: kTitleColor,
                              textFieldType: TextFieldType.NAME,
                              decoration: kInputDecoration.copyWith(
                                labelText: lang.S.of(context).holdNumber,
                                hintText: '2090.00',
                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kRedTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).cancel,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    )).onTap(() => {finish(context)}),
                                const SizedBox(width: 10.0),
                                Container(
                                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kBlueTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).submit,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    )).onTap(() => {finish(context)})
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  double serviceCharge = 0;
  double discountAmount = 0;

  TextEditingController discountAmountEditingController = TextEditingController();
  // TextEditingController vatAmountEditingController = TextEditingController();
  TextEditingController discountPercentageEditingController = TextEditingController();
  TextEditingController vatPercentageEditingController = TextEditingController();
  // double vatGst = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    // getConnectivity();
    checkInternet();
    if (widget.quotation != null) {
      for (var element in widget.quotation!.productList!) {
        cartList.add(element);
        addFocus();
      }
      discountAmountEditingController.text = widget.quotation!.discountAmount!.toStringAsFixed(2);
      discountAmount = widget.quotation!.discountAmount!;
      // vatAmountEditingController.text = widget.quotation!.vat!.toStringAsFixed(2);
      // vatGst = widget.quotation!.vat!;
      serviceCharge = widget.quotation!.discountAmount!;

      selectedUserName.customerName = widget.quotation!.customerName;
      selectedUserName.phoneNumber = widget.quotation!.customerPhone;
      selectedUserName.type = widget.quotation!.customerType;
    }
  }

  @override
  void dispose() {
    nameCodeCategoryController.dispose();
    discountAmountEditingController.dispose();
    discountPercentageEditingController.dispose();
    vatPercentageEditingController.dispose();
    nameFocus.dispose();

    // Dispose all focus nodes in the list
    for (var focusNode in productFocusNode) {
      focusNode.dispose();
    }

    super.dispose();
  }

  late StreamSubscription subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;

  // getConnectivity() => subscription = Connectivity().onConnectivityChanged.listen(
  //       (ConnectivityResult result) async {
  //         isDeviceConnected = await InternetConnectionChecker().hasConnection;
  //         if (!isDeviceConnected && isAlertSet == false) {
  //           showDialogBox();
  //           setState(() => isAlertSet = true);
  //         }
  //       },
  //     );

  checkInternet() async {
    isDeviceConnected = await InternetConnection().hasInternetAccess;
    if (!isDeviceConnected) {
      showDialogBox();
      setState(() => isAlertSet = true);
    }
  }

  void showSerialNumberPopUp({required ProductModel productModel}) {
    AddToCartModel productInCart = AddToCartModel(productPurchasePrice: 0, serialNumber: [], productImage: '', warehouseName: '', warehouseId: '', subTaxes: [], excTax: 0, groupTaxName: '', groupTaxRate: 0, incTax: 0, margin: 0, taxType: '');
    List<dynamic> selectedSerialNumbers = [];
    List<String> list = [];
    for (var element in cartList) {
      if (element.productId == productModel.productCode) {
        productInCart = element;
        break;
      }
    }
    selectedSerialNumbers = productInCart.serialNumber ?? [];

    for (var element in productModel.serialNumber) {
      if (!selectedSerialNumbers.contains(element)) {
        list.add(element);
      }
    }
    TextEditingController editingController = TextEditingController();
    String searchWord = '';

    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState1) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              lang.S.of(context).selectSerialNumber,
                              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 20.0),
                            ),
                            const Spacer(),
                            const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {finish(context)})
                          ],
                        ),
                      ),
                      const Divider(thickness: 1.0, color: kLitGreyColor),
                      const SizedBox(height: 10.0),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: editingController,
                              showCursor: true,
                              cursorColor: kTitleColor,
                              onChanged: (value) {
                                setState1(() {
                                  searchWord = value;
                                });
                              },
                              onFieldSubmitted: (value) {
                                for (var element in list) {
                                  if (value == element) {
                                    setState1(() {
                                      selectedSerialNumbers.add(element);
                                      editingController.clear();
                                      searchWord = '';
                                      list.removeWhere((element1) {
                                        return element1 == element;
                                      });
                                    });
                                    break;
                                  }
                                }
                              },
                              textFieldType: TextFieldType.NAME,
                              suffix: const Icon(Icons.search),
                              decoration: kInputDecoration.copyWith(
                                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                                labelText: lang.S.of(context).searchSerialNumber,
                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(lang.S.of(context).serialNumber),
                            const SizedBox(height: 10.0),
                            Container(
                              height: MediaQuery.of(context).size.height / 4,
                              width: 500,
                              decoration: BoxDecoration(border: Border.all(width: 1, color: Colors.grey), borderRadius: const BorderRadius.all(Radius.circular(10))),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: list.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState1(() {
                                            selectedSerialNumbers.add(list[index]);
                                            list.removeAt(index);
                                          });
                                        },
                                        child: Text(list[index]),
                                      ),
                                    ).visible(list[index].contains(searchWord));
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Text(lang.S.of(context).selectSerialNumber),
                            const SizedBox(height: 10.0),
                            Container(
                              width: 500,
                              height: 100,
                              decoration: BoxDecoration(border: Border.all(width: 1, color: Colors.grey), borderRadius: const BorderRadius.all(Radius.circular(10))),
                              child: GridView.builder(
                                  shrinkWrap: true,
                                  itemCount: selectedSerialNumbers.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    if (selectedSerialNumbers.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                                onTap: () {
                                                  setState1(() {
                                                    list.add(selectedSerialNumbers[index]);
                                                    selectedSerialNumbers.removeAt(index);
                                                  });
                                                },
                                                child: const Icon(
                                                  Icons.cancel_outlined,
                                                  size: 15,
                                                )),
                                            Text(
                                              '${selectedSerialNumbers[index]},',
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Text(lang.S.of(context).noSerialNumberFound);
                                    }
                                  },
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 4,
                                    crossAxisSpacing: 1,
                                    mainAxisSpacing: 1,
                                    // mainAxisExtent: 1,
                                  )),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kRedTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).cancel,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    )).onTap(() {
                                  GoRouter.of(context).pop();
                                }),
                                const SizedBox(width: 10.0),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      AddToCartModel addToCartModel = AddToCartModel(
                                        productName: productModel.productName,
                                        warehouseName: productModel.warehouseName,
                                        warehouseId: productModel.warehouseId,
                                        productId: productModel.productCode,
                                        productImage: productModel.productPicture,
                                        productPurchasePrice: productModel.productPurchasePrice.toDouble(),
                                        subTotal: productPriceChecker(product: productModel, customerType: selectedCustomerType),
                                        serialNumber: selectedSerialNumbers,
                                        quantity: selectedSerialNumbers.isEmpty ? 1 : selectedSerialNumbers.length,
                                        stock: num.parse(productModel.productStock),
                                        productWarranty: productModel.warranty,
                                        subTaxes: productModel.subTaxes,
                                        excTax: productModel.excTax,
                                        groupTaxName: productModel.groupTaxName,
                                        groupTaxRate: productModel.groupTaxRate,
                                        incTax: productModel.incTax,
                                        margin: productModel.margin,
                                        taxType: productModel.taxType,
                                      );
                                      if (!uniqueCheckForSerial(code: productModel.productCode, newSerialNumbers: selectedSerialNumbers)) {
                                        if (productModel.productStock == '0') {
                                          EasyLoading.showError('Product Out Of Stock');
                                        } else {
                                          cartList.add(addToCartModel);
                                          addFocus();
                                        }
                                      }
                                    });
                                    GoRouter.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kBlueTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).submit,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  void showCalcPopUp() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: SizedBox(
                  width: 300,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [CalcButton()],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  void showSaleListInvoicePopUp() {
    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const SaleListPopUP());
            },
          );
        },
      );
    }
  }

  TextEditingController nameCodeCategoryController = TextEditingController();

  final ScrollController mainSideScroller = ScrollController();

  //____________________________WareHouseModel_________________

  WareHouseModel? selectedWareHouse;

  int i = 0;

  DropdownButton<WareHouseModel> getWare({required List<WareHouseModel> list}) {
    // Set initial value to the first item in the list, if available
    // selectedWareHouse = list.isNotEmpty ? list.first : null;
    List<DropdownMenuItem<WareHouseModel>> dropDownItems = [];
    for (var element in list) {
      dropDownItems.add(DropdownMenuItem(
        value: element,
        child: Text(
          element.warehouseName,
          style: kTextStyle.copyWith(color: kGreyTextColor),
          overflow: TextOverflow.ellipsis,
        ),
      ));
      if (i == 0) {
        selectedWareHouse = element;
      }
      i++;
    }

    return DropdownButton(
      items: dropDownItems,
      isExpanded: true,
      value: selectedWareHouse,
      onChanged: (WareHouseModel? value) {
        setState(() {
          selectedWareHouse = value;
        });
      },
    );
  }

  final _horizontalScroll = ScrollController();
  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    List<String> allProductsNameList = [];
    List<String> allProductsCodeList = [];
    List<String> warehouseIdList = [];
    List<WarehouseBasedProductModel> warehouseBasedProductModel = [];
    return Consumer(
      builder: (context, consumerRef, __) {
        final wareHouseList = consumerRef.watch(warehouseProvider);
        final customerList = consumerRef.watch(allCustomerProvider);
        final personalData = consumerRef.watch(profileDetailsProvider);
        AsyncValue<List<ProductModel>> productList = consumerRef.watch(productProvider);

        return personalData.when(data: (data) {
          return Scaffold(
            backgroundColor: kDarkWhite,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///__________Header_______________________________________
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: ResponsiveGridRow(
                            rowSegments: 120,
                            children: [
                              //---------date----------------------------
                              ResponsiveGridCol(
                                xs: screenWidth > 450 ? 60 : 120,
                                md: 40,
                                lg: 24,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 40,
                                    width: screenWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: kNeutral400),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: kNeutral700,
                                        ),
                                      ),
                                    ),
                                  ).onTap(() => _selectedDueDate(context)),
                                ),
                              ),
                              //--------previous due---------------------
                              ResponsiveGridCol(
                                  xs: screenWidth > 450 ? 60 : 120,
                                  md: 40,
                                  lg: 24,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${lang.S.of(context).previousDue}:',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: kNeutral400),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$globalCurrency${myFormat.format(double.tryParse(previousDue) ?? 0)}',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              //--------------calculator-----------------
                              ResponsiveGridCol(
                                  xs: screenWidth > 450 ? 60 : 120,
                                  md: 40,
                                  lg: 24,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          lang.S.of(context).calculator,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Container(
                                            width: screenWidth,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: kNeutral400),
                                            ),
                                            child: Icon(
                                              MdiIcons.calculator,
                                              color: kTitleColor,
                                              size: 18.0,
                                            ),
                                          ).onTap(() => showCalcPopUp()),
                                        ),
                                      ],
                                    ),
                                  )),
                              //----------------dashboard-----------------------
                              ResponsiveGridCol(
                                xs: screenWidth > 450 ? 60 : 120,
                                md: 40,
                                lg: 24,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 40,
                                    width: screenWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: kNeutral400),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.speed,
                                          color: kTitleColor,
                                          size: 18.0,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Flexible(
                                          child: Text(
                                            lang.S.of(context).dashBoard,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: kNeutral700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).onTap(
                                    () => context.go('/dashboard'),
                                  ),
                                ),
                              ),
                              //----------------warehouse section-------------------------
                              ResponsiveGridCol(
                                xs: 60,
                                md: 40,
                                lg: 24,
                                child: wareHouseList.when(
                                  data: (warehouse) {
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Container(
                                        height: 40,
                                        width: screenWidth,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: kNeutral400),
                                        ),
                                        child: Theme(
                                          data: ThemeData(highlightColor: dropdownItemColor, focusColor: Colors.transparent, hoverColor: dropdownItemColor),
                                          child: DropdownButtonHideUnderline(
                                            child: getWare(list: warehouse ?? []),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  error: (e, stack) {
                                    return Center(
                                      child: Text(
                                        e.toString(),
                                      ),
                                    );
                                  },
                                  loading: () {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                ),
                              ),
                              //---------------invoice------------------------
                              ResponsiveGridCol(
                                  xs: 60,
                                  md: 40,
                                  lg: 24,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${lang.S.of(context).invoice}:',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(
                                          width: 12,
                                        ),
                                        Flexible(
                                          child: Container(
                                            height: 40,
                                            width: screenWidth,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: kNeutral400),
                                            ),
                                            child: Center(
                                                child: Text(
                                              "#${widget.quotation == null ? data.saleInvoiceCounter.toString() : widget.quotation!.invoiceNumber}",
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: kNeutral700,
                                              ),
                                            )),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              // -------------select customer-------------------------
                              ResponsiveGridCol(
                                xs: 120,
                                md: 40,
                                lg: 48,
                                child: customerList.when(data: (allCustomers) {
                                  List<String> listOfPhoneNumber = [];
                                  List<CustomerModel> customersList = [];
                                  for (var value1 in allCustomers) {
                                    listOfPhoneNumber.add(value1.phoneNumber.removeAllWhiteSpace().toLowerCase());
                                    if (value1.type != 'Supplier') {
                                      customersList.add(value1);
                                    }
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: Container(
                                              height: 40,
                                              width: screenWidth,
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                                                border: Border.all(color: kNeutral400),
                                              ),
                                              // width: context.width() < 1080 ? (1080 * .33) - 50 : (MediaQuery.of(context).size.width * .33) - 50,
                                              child: widget.quotation != null
                                                  ? FittedBox(
                                                      child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: Text(widget.quotation!.customerName),
                                                    ))
                                                  : DropdownButtonHideUnderline(child: getResult(customersList))),
                                        ),
                                        // const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            context.push(
                                              '/add-customer',
                                              extra: {
                                                'typeOfCustomerAdd': 'Buyer',
                                                'listOfPhoneNumber': listOfPhoneNumber,
                                              },
                                            );
                                          },
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                              color: kBlueTextColor,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                FeatherIcons.userPlus,
                                                size: 18.0,
                                                color: Colors.white,
                                              ),
                                            ),
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
                                }),
                              ),
                              // ---------------search product-----------------
                              ResponsiveGridCol(
                                  xs: 120,
                                  md: 40,
                                  lg: 24,
                                  child: productList.when(data: (product) {
                                    for (var element in product) {
                                      allProductsNameList.add(element.productName.removeAllWhiteSpace().toLowerCase());
                                      allProductsCodeList.add(element.productCode.removeAllWhiteSpace().toLowerCase());
                                      warehouseIdList.add(element.warehouseId.removeAllWhiteSpace().toLowerCase());
                                      warehouseBasedProductModel.add(WarehouseBasedProductModel(element.productName, element.warehouseId));
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        height: 40,
                                        child: AppTextField(
                                          controller: nameCodeCategoryController,
                                          showCursor: true,
                                          focus: nameFocus,
                                          autoFocus: true,
                                          cursorColor: kTitleColor,
                                          onChanged: (value) {
                                            setState(() {
                                              searchProductCode = value.toLowerCase();
                                              selectedCategory = 'Categories';
                                              isSelected = "Categories";
                                            });
                                          },
                                          onFieldSubmitted: (value) {
                                            if (value != '') {
                                              if (product.isEmpty) {
                                                EasyLoading.showError('No Product Found');
                                              }
                                              for (int i = 0; i < product.length; i++) {
                                                if (product[i].productCode == value) {
                                                  AddToCartModel addToCartModel = AddToCartModel(
                                                    productName: product[i].productName,
                                                    warehouseName: product[i].warehouseName,
                                                    warehouseId: product[i].warehouseId,
                                                    productId: product[i].productCode,
                                                    productImage: product[i].productPicture,
                                                    productPurchasePrice: product[i].productPurchasePrice.toDouble(),
                                                    subTotal: productPriceChecker(product: product[i], customerType: selectedCustomerType),
                                                    stock: num.parse(product[i].productStock),
                                                    productWarranty: product[i].warranty,
                                                    serialNumber: [],
                                                    subTaxes: product[i].subTaxes,
                                                    excTax: product[i].excTax,
                                                    groupTaxName: product[i].groupTaxName,
                                                    groupTaxRate: product[i].groupTaxRate,
                                                    incTax: product[i].incTax,
                                                    margin: product[i].margin,
                                                    taxType: product[i].taxType,
                                                    // productName: product[i].productName,
                                                    // warehouseName: product[i].warehouseName,
                                                    // warehouseId: product[i].warehouseId,
                                                    // productId: product[i].productCode,
                                                    // quantity: 1,
                                                    // productImage: product[i].productPicture,
                                                    // stock: product[i].productStock.toInt(),
                                                    // productPurchasePrice: product[i].productPurchasePrice.toDouble(),
                                                    // subTotal: productPriceChecker(product: product[i], customerType: selectedCustomerType)
                                                  );
                                                  setState(() {
                                                    if (!uniqueCheck(product[i].productCode)) {
                                                      cartList.add(addToCartModel);
                                                      addFocus();
                                                      nameCodeCategoryController.clear();
                                                      nameFocus.requestFocus();
                                                      searchProductCode = '';
                                                    } else {
                                                      nameCodeCategoryController.clear();
                                                      nameFocus.requestFocus();
                                                      searchProductCode = '';
                                                    }
                                                  });
                                                  break;
                                                }
                                                if (i + 1 == product.length) {
                                                  nameCodeCategoryController.clear();
                                                  nameFocus.requestFocus();
                                                  EasyLoading.showError('Not found');
                                                  setState(() {
                                                    searchProductCode = '';
                                                  });
                                                }
                                              }
                                            }
                                          },
                                          textFieldType: TextFieldType.NAME,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(MdiIcons.barcode, color: kTitleColor, size: 18.0),
                                            suffixIcon: Container(
                                              height: 10,
                                              width: 10,
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                                color: kBlueTextColor,
                                              ),
                                              child: const Center(
                                                child: Icon(FeatherIcons.plusSquare, color: Colors.white, size: 18.0),
                                              ),
                                            ).onTap(() => context.push(
                                                  '/product/add-product',
                                                  extra: {
                                                    'allProductsCodeList': allProductsCodeList,
                                                    'warehouseBasedProductModel': [],
                                                  },
                                                )),
                                            hintText: 'Search product name or code',
                                            border: InputBorder.none,
                                          ),
                                        ),
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
                                  })),
                              // ---------------customer type---------------
                              ResponsiveGridCol(
                                  xs: 120,
                                  md: 40,
                                  lg: 24,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      height: 40,
                                      width: screenWidth,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: kNeutral400),
                                      ),
                                      child: DropdownButtonHideUnderline(child: getCategories()),
                                    ),
                                  ))
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        ///_______Sale_Bord__________________________________________
                        ResponsiveGridRow(rowSegments: 100, children: [
                          //----------------product add section---------------------
                          ResponsiveGridCol(
                            lg: 47,
                            md: 100,
                            xs: 100,
                            child: IntrinsicWidth(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  border: Border.all(width: 1, color: kGreyTextColor.withOpacity(0.3)),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: context.height() < 720 ? 720 - 410 : context.height() - 410,
                                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: kNeutral300))),
                                      child: LayoutBuilder(
                                        builder: (BuildContext context, BoxConstraints constraints) {
                                          final kWidth = constraints.maxWidth;
                                          return RawScrollbar(
                                            thumbVisibility: true,
                                            controller: _horizontalScroll,
                                            thickness: 8.0,
                                            radius: const Radius.circular(5),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              controller: _horizontalScroll,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth: kWidth,
                                                ),
                                                child: Theme(
                                                  data: theme.copyWith(dividerColor: Colors.transparent, dividerTheme: const DividerThemeData(color: Colors.transparent)),
                                                  child: DataTable(
                                                      border: const TableBorder(
                                                        horizontalInside: BorderSide(
                                                          width: 1,
                                                          color: kNeutral300,
                                                        ),
                                                      ),
                                                      dividerThickness: 0.0,
                                                      dataRowColor: const WidgetStatePropertyAll(whiteColor),
                                                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                                      showBottomBorder: false,
                                                      headingTextStyle: theme.textTheme.titleMedium,
                                                      dataTextStyle: theme.textTheme.bodyLarge,
                                                      columns: [
                                                        DataColumn(label: Text(lang.S.of(context).productNam)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).quantity)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).price)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).subTotal)),
                                                        DataColumn(
                                                            headingRowAlignment: MainAxisAlignment.center,
                                                            label: Text(
                                                              lang.S.of(context).action,
                                                              textAlign: TextAlign.end,
                                                            )),
                                                      ],
                                                      rows: List.generate(cartList.length, (index) {
                                                        TextEditingController quantityController = TextEditingController(text: cartList[index].quantity.toString());
                                                        return DataRow(cells: [
                                                          //------------product name-----------------
                                                          DataCell(
                                                            Text(
                                                              cartList[index].productName ?? '',
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                          //---------------product quantity---------------------------------
                                                          DataCell(Center(
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor).onTap(() {
                                                                  setState(() {
                                                                    cartList[index].quantity > 1 ? cartList[index].quantity-- : cartList[index].quantity = 1;
                                                                  });
                                                                }),
                                                                const SizedBox(width: 4),
                                                                SizedBox(
                                                                  width: 60,
                                                                  height: 32,
                                                                  child: TextFormField(
                                                                    controller: quantityController,
                                                                    textAlign: TextAlign.center,
                                                                    focusNode: productFocusNode[index],
                                                                    onChanged: (value) {
                                                                      if (cartList[index].stock! < num.parse(value)) {
                                                                        EasyLoading.showError('Out of Stock');
                                                                        quantityController.clear();
                                                                      } else if (value == '') {
                                                                        cartList[index].quantity = 1;
                                                                      } else if (value == '0') {
                                                                        cartList[index].quantity = 1;
                                                                      } else {
                                                                        cartList[index].quantity = num.parse(value);
                                                                      }
                                                                    },
                                                                    onFieldSubmitted: (value) {
                                                                      if (value == '') {
                                                                        setState(() {
                                                                          cartList[index].quantity = 1;
                                                                        });
                                                                      } else {
                                                                        setState(() {
                                                                          cartList[index].quantity = num.parse(value);
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 4),
                                                                const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor).onTap(() {
                                                                  if (cartList[index].quantity < cartList[index].stock!) {
                                                                    setState(() {
                                                                      cartList[index].quantity += 1;
                                                                      toast(cartList[index].quantity.toString());
                                                                    });
                                                                  } else {
                                                                    EasyLoading.showError('Out of Stock');
                                                                  }
                                                                }),
                                                              ],
                                                            ),
                                                          )),
                                                          //-------------------product price---------------------------------
                                                          DataCell(
                                                            Align(
                                                              alignment: Alignment.center,
                                                              child: SizedBox(
                                                                height: 32,
                                                                width: 60,
                                                                child: TextFormField(
                                                                  initialValue: myFormat.format(double.tryParse(cartList[index].subTotal) ?? 0),
                                                                  onChanged: (value) {
                                                                    if (value == '') {
                                                                      setState(() {
                                                                        cartList[index].subTotal = 0.toString();
                                                                      });
                                                                    } else if (double.tryParse(value) == null) {
                                                                      EasyLoading.showError('Enter a valid Price');
                                                                    } else {
                                                                      setState(() {
                                                                        cartList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                                                      });
                                                                    }
                                                                  },
                                                                  onFieldSubmitted: (value) {
                                                                    if (value == '') {
                                                                      setState(() {
                                                                        cartList[index].subTotal = 0.toString();
                                                                      });
                                                                    } else if (double.tryParse(value) == null) {
                                                                      EasyLoading.showError('Enter a valid Price');
                                                                    } else {
                                                                      setState(() {
                                                                        cartList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                                                      });
                                                                    }
                                                                  },
                                                                  textAlign: TextAlign.center,
                                                                  decoration: const InputDecoration(contentPadding: EdgeInsets.all(6)),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          //-------------------sub total-----------------------------------
                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                '$globalCurrency${myFormat.format(double.tryParse((double.parse(cartList[index].subTotal) * cartList[index].quantity).toStringAsFixed(2)) ?? 0)}',
                                                                style: kTextStyle.copyWith(color: kTitleColor),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ),
                                                          ),
                                                          //-------------------------action----------------------------------
                                                          DataCell(
                                                            Align(
                                                              alignment: Alignment.center,
                                                              child: const Icon(
                                                                Icons.close_sharp,
                                                                color: redColor,
                                                              ).onTap(() {
                                                                setState(() {
                                                                  cartList.removeAt(index);
                                                                  productFocusNode.removeAt(index);
                                                                });
                                                              }),
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
                                    ),

                                    ///_______price_section_____________________________________________
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          ///__________total__________________________________________
                                          ResponsiveGridRow(children: [
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: Padding(
                                                padding: EdgeInsets.only(bottom: screenWidth < 577 ? 12 : 0),
                                                child: Text(
                                                  'Total Item: ${cartList.length}',
                                                  style: theme.textTheme.titleMedium,
                                                ),
                                              ),
                                            ),
                                            ResponsiveGridCol(
                                                xs: 12,
                                                md: 6,
                                                lg: 6,
                                                child: Row(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 12),
                                                      child: Text(
                                                        'Sub Total',
                                                        textAlign: TextAlign.end,
                                                        style: theme.textTheme.titleMedium,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          padding: EdgeInsets.zero,
                                                          fixedSize: Size(screenWidth, 40),
                                                        ),
                                                        onPressed: () {},
                                                        child: Text(
                                                          '$globalCurrency ${myFormat.format(double.tryParse((getTotalAmount().toDouble() + serviceCharge - discountAmount).toStringAsFixed(2)) ?? 0)}',
                                                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ))
                                          ]),
                                          const SizedBox(height: 10.0),

                                          ///_________Taxes__________________________________________
                                          ResponsiveGridRow(children: [
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: const SizedBox.shrink(),
                                            ),
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: SizedBox(
                                                // height: 50.00 * getAllTaxFromCartList(cart: cartList).length,
                                                // width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10 + 204,
                                                child: ListView.builder(
                                                  itemCount: getAllTaxFromCartList(cart: cartList).length,
                                                  shrinkWrap: true,
                                                  itemBuilder: (context, index) {
                                                    return Container(
                                                      height: 40,
                                                      margin: const EdgeInsets.only(top: 5, bottom: 5),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.only(right: 12),
                                                            child: Text(
                                                              getAllTaxFromCartList(cart: cartList)[index].name,
                                                              textAlign: TextAlign.end,
                                                              style: theme.textTheme.titleMedium,
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child: SizedBox(
                                                              height: 40.0,
                                                              child: Center(
                                                                child: AppTextField(
                                                                  initialValue: getAllTaxFromCartList(cart: cartList)[index].taxRate.toString(),
                                                                  readOnly: true,
                                                                  textAlign: TextAlign.right,
                                                                  decoration: InputDecoration(
                                                                    contentPadding: const EdgeInsets.only(right: 6.0),
                                                                    hintText: '0',
                                                                    border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                    enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                    disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                    focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                    prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                                                    prefixIcon: Container(
                                                                      padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                                                      height: 40,
                                                                      decoration: const BoxDecoration(color: Color(0xFFff5f00), borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                                                      child: const Text(
                                                                        '%',
                                                                        style: TextStyle(fontSize: 20.0, color: Colors.white),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  textFieldType: TextFieldType.NUMBER,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ]),
                                          const SizedBox(height: 10.0),

                                          ///__________service/shipping_____________________________
                                          ResponsiveGridRow(children: [
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: const SizedBox.shrink(),
                                            ),
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: SizedBox(
                                                // width: screenWidth,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 12),
                                                      child: Text(
                                                        lang.S.of(context).shpingOrServices,
                                                        textAlign: TextAlign.end,
                                                        style: theme.textTheme.titleMedium,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: SizedBox(
                                                        width: screenWidth,
                                                        height: 40,
                                                        child: TextFormField(
                                                          initialValue: serviceCharge.toString(),
                                                          onChanged: (value) {
                                                            setState(() {
                                                              serviceCharge = value.toDouble();
                                                            });
                                                          },
                                                          decoration: const InputDecoration(
                                                            border: OutlineInputBorder(),
                                                            hintText: 'Enter Amount',
                                                            contentPadding: EdgeInsets.all(7.0),
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          keyboardType: TextInputType.number,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ]),
                                          const SizedBox(height: 10.0),

                                          ///________discount_________________________________________________
                                          ResponsiveGridRow(children: [
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: const SizedBox.shrink(),
                                            ),
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 6,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 12),
                                                    child: Text(
                                                      lang.S.of(context).discount,
                                                      textAlign: TextAlign.end,
                                                      style: theme.textTheme.titleMedium,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          child: SizedBox(
                                                            height: 40.0,
                                                            child: AppTextField(
                                                              controller: discountPercentageEditingController,
                                                              onChanged: (value) {
                                                                if (value == '') {
                                                                  setState(() {
                                                                    discountAmountEditingController.text = 0.toString();
                                                                  });
                                                                } else {
                                                                  if (value.toInt() <= 100) {
                                                                    setState(() {
                                                                      discountAmount = double.parse(((value.toDouble() / 100) * getTotalAmount().toDouble()).toStringAsFixed(1));
                                                                      discountAmountEditingController.text = discountAmount.toString();
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      discountAmount = 0;
                                                                      discountAmountEditingController.clear();
                                                                      discountPercentageEditingController.clear();
                                                                    });
                                                                    EasyLoading.showError('Enter a valid Discount');
                                                                  }
                                                                }
                                                              },
                                                              textAlign: TextAlign.right,
                                                              decoration: InputDecoration(
                                                                contentPadding: const EdgeInsets.only(right: 6.0),
                                                                hintText: '0',
                                                                border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                                                                prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                                                prefixIcon: Container(
                                                                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                                                  height: 40,
                                                                  decoration: const BoxDecoration(color: Color(0xFFff5f00), borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                                                  child: const Text(
                                                                    '%',
                                                                    style: TextStyle(fontSize: 20.0, color: Colors.white),
                                                                  ),
                                                                ),
                                                              ),
                                                              textFieldType: TextFieldType.NUMBER,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4.0,
                                                        ),
                                                        Flexible(
                                                          child: SizedBox(
                                                            height: 40.0,
                                                            child: AppTextField(
                                                              controller: discountAmountEditingController,
                                                              onChanged: (value) {
                                                                if (value == '') {
                                                                  setState(() {
                                                                    discountAmount = 0;
                                                                    discountPercentageEditingController.text = 0.toString();
                                                                  });
                                                                } else {
                                                                  if (value.toInt() <= getTotalAmount().toDouble()) {
                                                                    setState(() {
                                                                      discountAmount = double.parse(value);
                                                                      discountPercentageEditingController.text = ((discountAmount * 100) / getTotalAmount().toDouble()).toStringAsFixed(1);
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      discountAmount = 0;
                                                                      discountPercentageEditingController.clear();
                                                                      discountAmountEditingController.clear();
                                                                    });
                                                                    EasyLoading.showError('Enter a valid Discount');
                                                                  }
                                                                }
                                                              },
                                                              textAlign: TextAlign.right,
                                                              decoration: InputDecoration(
                                                                contentPadding: const EdgeInsets.only(right: 6.0),
                                                                hintText: '0',
                                                                border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                                                enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                                                disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                                                focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                                                prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                                                prefixIcon: Container(
                                                                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                                                  height: 40,
                                                                  decoration: const BoxDecoration(color: kMainColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                                                  child: Text(
                                                                    currency,
                                                                    style: const TextStyle(fontSize: 20.0, color: Colors.white),
                                                                  ),
                                                                ),
                                                              ),
                                                              textFieldType: TextFieldType.NUMBER,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]),
                                          const SizedBox(height: 10.0),

                                          ///___________vat____________________________________
                                          // Row(
                                          //   mainAxisAlignment: MainAxisAlignment.end,
                                          //   children: [
                                          //     SizedBox(
                                          //       width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10,
                                          //       child: Padding(
                                          //         padding: const EdgeInsets.only(right: 20),
                                          //         child: Text(
                                          //           lang.S.of(context).vatOrgst,
                                          //           textAlign: TextAlign.end,
                                          //           style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          //         ),
                                          //       ),
                                          //     ),
                                          //     Row(
                                          //       children: [
                                          //         SizedBox(
                                          //           width: 100,
                                          //           height: 40.0,
                                          //           child: Center(
                                          //             child: AppTextField(
                                          //               controller: vatPercentageEditingController,
                                          //               onChanged: (value) {
                                          //                 if (value == '') {
                                          //                   setState(() {
                                          //                     // vatGst = 0.0;
                                          //                     vatAmountEditingController.text = 0.toString();
                                          //                   });
                                          //                 } else {
                                          //                   setState(() {
                                          //                     vatGst = double.parse(((value.toDouble() / 100) * getTotalAmount().toDouble()).toStringAsFixed(1));
                                          //                     vatAmountEditingController.text = vatGst.toString();
                                          //                   });
                                          //                 }
                                          //               },
                                          //               textAlign: TextAlign.right,
                                          //               decoration: InputDecoration(
                                          //                 contentPadding: const EdgeInsets.only(right: 6.0),
                                          //                 hintText: '0',
                                          //                 border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                                          //                 enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                                          //                 disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                                          //                 focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                                          //                 prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                          //                 prefixIcon: Container(
                                          //                   padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                          //                   height: 40,
                                          //                   decoration: const BoxDecoration(
                                          //                       color: kTitleColor,
                                          //                       borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                          //                   child: const Text(
                                          //                     '%',
                                          //                     style: TextStyle(fontSize: 20.0, color: Colors.white),
                                          //                   ),
                                          //                 ),
                                          //               ),
                                          //               textFieldType: TextFieldType.NUMBER,
                                          //             ),
                                          //           ),
                                          //         ),
                                          //         const SizedBox(
                                          //           width: 4.0,
                                          //         ),
                                          //         SizedBox(
                                          //           width: 100,
                                          //           height: 40.0,
                                          //           child: Center(
                                          //             child: AppTextField(
                                          //               controller: vatAmountEditingController,
                                          //               onChanged: (value) {
                                          //                 if (value == '') {
                                          //                   setState(() {
                                          //                     vatGst = 0;
                                          //                     vatPercentageEditingController.text = 0.toString();
                                          //                   });
                                          //                 } else {
                                          //                   setState(() {
                                          //                     vatGst = double.parse(value);
                                          //                     vatPercentageEditingController.text = ((vatGst * 100) / getTotalAmount().toDouble()).toStringAsFixed(1);
                                          //                   });
                                          //                 }
                                          //               },
                                          //               textAlign: TextAlign.right,
                                          //               decoration: InputDecoration(
                                          //                 contentPadding: const EdgeInsets.only(right: 6.0),
                                          //                 hintText: '0',
                                          //                 border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                          //                 enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                          //                 disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                          //                 focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                                          //                 prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                                          //                 prefixIcon: Container(
                                          //                   padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                                          //                   height: 40,
                                          //                   decoration: const BoxDecoration(
                                          //                       color: kMainColor,
                                          //                       borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                                          //                   child: Text(
                                          //                     currency,
                                          //                     style: const TextStyle(fontSize: 20.0, color: Colors.white),
                                          //                   ),
                                          //                 ),
                                          //               ),
                                          //               textFieldType: TextFieldType.NUMBER,
                                          //             ),
                                          //           ),
                                          //         ),
                                          //       ],
                                          //     ),
                                          //   ],
                                          // ),

                                          const SizedBox(height: 20.0),

                                          ///____________buttons____________________________________________________
                                          ResponsiveGridRow(children: [
                                            ResponsiveGridCol(
                                                xs: 6,
                                                md: 4,
                                                lg: 4,
                                                child: Padding(
                                                  padding: EdgeInsets.only(right: 12, bottom: screenWidth < 577 ? 12 : 0),
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      GoRouter.of(context).pop();
                                                    },
                                                    child: Text(
                                                      lang.S.of(context).cancel,
                                                    ),
                                                  ),
                                                )),
                                            ResponsiveGridCol(
                                                xs: 6,
                                                md: 4,
                                                lg: 4,
                                                child: Padding(
                                                  padding: EdgeInsets.only(right: screenWidth < 577 ? 0 : 12, bottom: screenWidth < 577 ? 12 : 0),
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.black,
                                                    ),
                                                    onPressed: () async {
                                                      if (await Subscription.subscriptionChecker(item: 'Sales')) {
                                                        if (cartList.isEmpty) {
                                                          EasyLoading.showError('Please Add Some Product first');
                                                        } else {
                                                          showDialog(
                                                              barrierDismissible: false,
                                                              context: context,
                                                              builder: (BuildContext dialogContext) {
                                                                return Padding(
                                                                  padding: const EdgeInsets.all(10.0),
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
                                                                              lang.S.of(context).areYouWantToCreateThisQuation,
                                                                              style: theme.textTheme.headlineSmall?.copyWith(
                                                                                fontWeight: FontWeight.w600,
                                                                              ),
                                                                              textAlign: TextAlign.center,
                                                                            ),
                                                                            const SizedBox(height: 20),
                                                                            ResponsiveGridRow(children: [
                                                                              ResponsiveGridCol(
                                                                                lg: 6,
                                                                                md: 6,
                                                                                xs: 6,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                  child: ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      backgroundColor: Colors.red,
                                                                                    ),
                                                                                    child: Text(
                                                                                      lang.S.of(context).cancel,
                                                                                      style: const TextStyle(color: Colors.white),
                                                                                    ),
                                                                                    onPressed: () {
                                                                                      // Navigator.pop(dialogContext);
                                                                                      GoRouter.of(dialogContext).pop();
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              ResponsiveGridCol(
                                                                                md: 6,
                                                                                xs: 6,
                                                                                lg: 6,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                  child: ElevatedButton(
                                                                                    child: Text(
                                                                                      lang.S.of(context).create,
                                                                                    ),
                                                                                    onPressed: () async {
                                                                                      // SaleTransactionModel transitionModel = SaleTransactionModel(
                                                                                      //   customerName: selectedUserName.customerName,
                                                                                      //   customerGst: selectedUserName.gst,
                                                                                      //   customerType: selectedUserName.type,
                                                                                      //   customerImage: selectedUserName.profilePicture,
                                                                                      //   customerAddress: selectedUserName.customerAddress,
                                                                                      //   customerPhone: selectedUserName.phoneNumber,
                                                                                      //   invoiceNumber: data.saleInvoiceCounter.toString(),
                                                                                      //   purchaseDate: DateTime.now().toString(),
                                                                                      //   productList: cartList,
                                                                                      //   totalAmount: double.parse(
                                                                                      //       (getTotalAmount().toDouble() + serviceCharge - discountAmount).toStringAsFixed(1)),
                                                                                      //   discountAmount: discountAmount,
                                                                                      //   serviceCharge: serviceCharge,
                                                                                      //   vat: 0,
                                                                                      // );
                                                                                      SaleTransactionModel transitionModel = SaleTransactionModel(
                                                                                        customerName: selectedUserName.customerName,
                                                                                        customerGst: selectedUserName.gst,
                                                                                        customerType: selectedUserName.type,
                                                                                        customerImage: selectedUserName.profilePicture,
                                                                                        customerAddress: selectedUserName.customerAddress,
                                                                                        customerPhone: selectedUserName.phoneNumber,
                                                                                        sendWhatsappMessage: selectedUserName.receiveWhatsappUpdates ?? false,
                                                                                        invoiceNumber: data.saleInvoiceCounter.toString(),
                                                                                        purchaseDate: DateTime.now().toString(),
                                                                                        productList: cartList,
                                                                                        totalAmount: double.parse((getTotalAmount().toDouble() + serviceCharge - discountAmount).toStringAsFixed(1)),
                                                                                        discountAmount: discountAmount,
                                                                                        serviceCharge: serviceCharge,
                                                                                        vat: 0,
                                                                                      );

                                                                                      try {
                                                                                        EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                                                                                        DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Quotation");

                                                                                        transitionModel.isPaid = false;
                                                                                        transitionModel.dueAmount = 0;
                                                                                        transitionModel.lossProfit = 0;
                                                                                        transitionModel.returnAmount = 0;
                                                                                        transitionModel.paymentType = 'Just Quotation';
                                                                                        transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';

                                                                                        ///_________Push_on_dataBase____________________________________________________________________________
                                                                                        await ref.push().set(transitionModel.toJson());

                                                                                        ///_________Invoice Increase____________________________________________________________________________
                                                                                        updateInvoice(typeOfInvoice: 'saleInvoiceCounter', invoice: transitionModel.invoiceNumber.toInt());

                                                                                        consumerRef.refresh(profileDetailsProvider);

                                                                                        EasyLoading.showSuccess('Added Successfully');
                                                                                        await GeneratePdfAndPrint().printQuotationInvoice(personalInformationModel: data, saleTransactionModel: transitionModel, context: context);
                                                                                        GoRouter.of(dialogContext).pop();
                                                                                      } catch (e) {
                                                                                        EasyLoading.dismiss();
                                                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              )
                                                                            ]),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              });
                                                        }
                                                      } else {
                                                        EasyLoading.showError('Update your plan first\nSale Limit is over.');
                                                      }
                                                    },
                                                    child: Text(
                                                      lang.S.of(context).quotation,
                                                    ),
                                                  ),
                                                )),
                                            ResponsiveGridCol(
                                                xs: 12,
                                                md: 4,
                                                lg: 4,
                                                child: Padding(
                                                  padding: EdgeInsets.only(right: screenWidth < 577 ? 0 : 12, bottom: screenWidth < 577 ? 12 : 0),
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: kMainColor,
                                                    ),
                                                    onPressed: () async {
                                                      if (await checkUserRolePermission(type: 'sale')) {
                                                        if (await Subscription.subscriptionChecker(item: 'Sales')) {
                                                          if (cartList.isEmpty) {
                                                            EasyLoading.showError('Please Add Some Product first');
                                                          } else {
                                                            SaleTransactionModel transitionModel = SaleTransactionModel(
                                                              customerName: selectedUserName.customerName,
                                                              customerType: selectedUserName.type,
                                                              customerGst: selectedUserName.gst,
                                                              customerImage: selectedUserName.profilePicture,
                                                              customerAddress: selectedUserName.customerAddress,
                                                              customerPhone: selectedUserName.phoneNumber,
                                                              invoiceNumber: widget.quotation == null ? data.saleInvoiceCounter.toString() : widget.quotation!.invoiceNumber,
                                                              purchaseDate: DateTime.now().toString(),
                                                              productList: cartList,
                                                              totalAmount: double.parse((getTotalAmount().toDouble() + serviceCharge - discountAmount).toStringAsFixed(1)),
                                                              discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
                                                              serviceCharge: double.parse(serviceCharge.toStringAsFixed(2)),
                                                              // vat: double.parse(vatGst.toStringAsFixed(2)),
                                                              vat: 0,
                                                            );
                                                            print(transitionModel);
                                                            // ShowPaymentPopUp(
                                                            //   transitionModel: transitionModel,
                                                            //   isFromQuotation: widget.quotation == null ? false : true,
                                                            // ).launch(context);
                                                            context.push(
                                                              '/sales/show-payment-popup',
                                                              extra: {
                                                                'transitionModel': transitionModel,
                                                                'isFromQuotation': widget.quotation != null,
                                                              },
                                                            );
                                                          }
                                                        } else {
                                                          EasyLoading.showError('Update your plan first\nSale Limit is over.');
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      lang.S.of(context).payment,
                                                    ),
                                                  ),
                                                )),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          //---------------product category section-----------------
                          ResponsiveGridCol(
                            lg: 14,
                            md: 100,
                            xs: 100,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth < 1240 ? 0 : 16, vertical: screenWidth > 1240 ? 0 : 12),
                              child: Consumer(
                                builder: (_, ref, watch) {
                                  AsyncValue<List<CategoryModel>> categoryList = ref.watch(categoryProvider);
                                  return categoryList.when(data: (category) {
                                    return Container(
                                      // width: 150,
                                      height: screenWidth < 1240
                                          ? 110
                                          : context.height() < 720
                                              ? 720 - 142
                                              : context.height() - 160,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(color: kWhite, border: Border.all(width: 1, color: kGreyTextColor.withOpacity(0.3)), borderRadius: const BorderRadius.all(Radius.circular(15))),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.0),
                                                    color: screenWidth < 1240
                                                        ? Colors.transparent
                                                        : isSelected == 'Categories'
                                                            ? kBlueTextColor
                                                            : kBlueTextColor.withOpacity(0.1)),
                                                padding: EdgeInsets.only(left: screenWidth < 1240 ? 0 : 15, right: 8, top: screenWidth < 1240 ? 0 : 5, bottom: screenWidth < 1240 ? 0 : 5),
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        lang.S.of(context).categories,
                                                        textAlign: TextAlign.start,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: theme.textTheme.titleSmall?.copyWith(
                                                            color: isSelected == 'Categories'
                                                                ? screenWidth < 1240
                                                                    ? kTitleColor
                                                                    : Colors.white
                                                                : kDarkGreyColor,
                                                            fontSize: screenWidth < 1240 ? 20 : 14),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.keyboard_arrow_right,
                                                      color: isSelected == 'Categories' ? Colors.white : kDarkGreyColor,
                                                      size: 16,
                                                    )
                                                  ],
                                                ),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  selectedCategory = 'Categories';
                                                  isSelected = "Categories";
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 5.0),
                                            SizedBox(
                                              height: screenWidth < 1240 ? 50 : null,
                                              child: ListView.builder(
                                                scrollDirection: screenWidth < 1240 ? Axis.horizontal : Axis.vertical,
                                                itemCount: category.length,
                                                shrinkWrap: true,
                                                itemBuilder: (_, i) {
                                                  return GestureDetector(
                                                    onTap: (() {
                                                      setState(() {
                                                        isSelected = category[i].categoryName;
                                                        selectedCategory = category[i].categoryName;
                                                      });
                                                    }),
                                                    child: Padding(
                                                      padding: EdgeInsets.only(top: 5, bottom: 4, right: screenWidth < 1240 ? 10 : 0),
                                                      child: Container(
                                                        padding: const EdgeInsets.only(left: 15.0, right: 8.0, top: 8.0, bottom: 8.0),
                                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: isSelected == category[i].categoryName ? kBlueTextColor : kBlueTextColor.withOpacity(0.1)),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            screenWidth < 1240
                                                                ? Text(
                                                                    category[i].categoryName,
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: theme.textTheme.titleSmall?.copyWith(color: isSelected == category[i].categoryName ? Colors.white : kDarkGreyColor),
                                                                  )
                                                                : Flexible(
                                                                    child: Text(
                                                                      category[i].categoryName,
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: kTextStyle.copyWith(color: isSelected == category[i].categoryName ? Colors.white : kDarkGreyColor, fontWeight: FontWeight.bold),
                                                                    ),
                                                                  ),
                                                            Icon(
                                                              Icons.keyboard_arrow_right,
                                                              color: isSelected == category[i].categoryName ? Colors.white : kDarkGreyColor,
                                                              size: 16,
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
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
                              ),
                            ),
                          ),
                          //----------------product list----------------------------
                          ResponsiveGridCol(
                            lg: 39,
                            md: 100,
                            xs: 100,
                            child: productList.when(data: (products) {
                              if (widget.quotation != null) {
                                //Compare the products from cartlist with productlist to see if any product is out of stock
                                cartList.forEach((element) {
                                  ProductModel? stockCheck = products.where((element2) => element2.productCode == element.productId).singleOrNull;
                                  if (stockCheck != null && int.parse(stockCheck?.productStock ?? "0") < element.stock!.toInt()) {
                                    EasyLoading.showError('Product ${element.productName} is out of stock');
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      setState(() {
                                        cartList.remove(element);
                                      });
                                    });
                                  }
                                });
                              }

                              List<ProductModel> showProductVsCategory = [];
                              if (selectedCategory == 'Categories') {
                                for (var element in products) {
                                  if (element.productCode.toLowerCase().contains(searchProductCode) || element.productCategory.toLowerCase().contains(searchProductCode) || element.productName.toLowerCase().contains(searchProductCode)) {
                                    productPriceChecker(product: element, customerType: selectedCustomerType) != '0' && ((selectedWareHouse?.warehouseName == 'InHouse' && element.warehouseId == '') ? true : selectedWareHouse?.id == element.warehouseId) ? showProductVsCategory.add(element) : null;
                                  }
                                }
                              } else {
                                for (var element in products) {
                                  if (element.productCategory == selectedCategory) {
                                    productPriceChecker(product: element, customerType: selectedCustomerType) != '0' && ((selectedWareHouse?.warehouseName == 'InHouse' && element.warehouseId == '') ? true : selectedWareHouse?.id == element.warehouseId) ? showProductVsCategory.add(element) : null;
                                  }
                                }
                              }

                              return showProductVsCategory.isNotEmpty
                                  ? SizedBox(
                                      height: context.height() - 160,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: kDarkWhite,
                                        ),
                                        child: GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 180,
                                            mainAxisExtent: 204,
                                            mainAxisSpacing: 10,
                                            crossAxisSpacing: 10,
                                          ),
                                          itemCount: showProductVsCategory.length,
                                          itemBuilder: (_, i) {
                                            return Container(
                                              width: 130.0,
                                              height: 170.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.0),
                                                color: kWhite,
                                                border: Border.all(
                                                  color: kLitGreyColor,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ///_____image_and_stock_______________________________
                                                  Stack(
                                                    alignment: Alignment.topLeft,
                                                    children: [
                                                      ///_______image______________________________________
                                                      Container(
                                                        height: 120,
                                                        decoration: BoxDecoration(
                                                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
                                                          image: DecorationImage(image: NetworkImage(showProductVsCategory[i].productPicture), fit: BoxFit.cover),
                                                        ),
                                                      ),

                                                      ///_______stock_________________________
                                                      Positioned(
                                                        left: 5,
                                                        top: 5,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: showProductVsCategory[i].productStock == '0' ? kRedTextColor : kBlueTextColor.withValues(alpha: 0.8),
                                                            borderRadius: BorderRadius.circular(3),
                                                          ),
                                                          child: Text(
                                                            showProductVsCategory[i].productStock != '0' ? '${myFormat.format(double.tryParse(showProductVsCategory[i].productStock) ?? 0)} pc' : 'Out of stock',
                                                            style: theme.textTheme.titleSmall?.copyWith(color: kWhite),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 10.0, left: 5, right: 3),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        ///______name_______________________________________________
                                                        Text(
                                                          showProductVsCategory[i].productName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: theme.textTheme.bodyLarge,
                                                        ),
                                                        const SizedBox(height: 4.0),

                                                        ///________Purchase_price______________________________________________________
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                                          decoration: BoxDecoration(
                                                            color: kGreenTextColor,
                                                            borderRadius: BorderRadius.circular(3.0),
                                                          ),
                                                          child: Text(
                                                            // ignore: prefer_interpolation_to_compose_strings
                                                            'Price: $globalCurrency ' + myFormat.format(double.tryParse(productPriceChecker(product: showProductVsCategory[i], customerType: selectedCustomerType)) ?? 0),
                                                            style: theme.textTheme.titleSmall?.copyWith(color: kWhite),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ).onTap(() {
                                              if (showProductVsCategory[i].serialNumber.isNotEmpty) {
                                                showSerialNumberPopUp(productModel: showProductVsCategory[i]);
                                              } else {
                                                setState(() {
                                                  AddToCartModel addToCartModel = AddToCartModel(
                                                    productName: showProductVsCategory[i].productName,
                                                    warehouseName: showProductVsCategory[i].warehouseName,
                                                    warehouseId: showProductVsCategory[i].warehouseId,
                                                    productId: showProductVsCategory[i].productCode,
                                                    productImage: showProductVsCategory[i].productPicture,
                                                    productPurchasePrice: showProductVsCategory[i].productPurchasePrice,
                                                    subTotal: productPriceChecker(product: showProductVsCategory[i], customerType: selectedCustomerType),
                                                    stock: num.parse(showProductVsCategory[i].productStock),
                                                    productWarranty: showProductVsCategory[i].warranty,
                                                    serialNumber: [],
                                                    subTaxes: showProductVsCategory[i].subTaxes,
                                                    excTax: showProductVsCategory[i].excTax,
                                                    groupTaxName: showProductVsCategory[i].groupTaxName,
                                                    groupTaxRate: showProductVsCategory[i].groupTaxRate,
                                                    incTax: showProductVsCategory[i].incTax,
                                                    margin: showProductVsCategory[i].margin,
                                                    taxType: showProductVsCategory[i].taxType,
                                                  );
                                                  if (!uniqueCheck(showProductVsCategory[i].productCode)) {
                                                    if (showProductVsCategory[i].productStock == '0') {
                                                      EasyLoading.showError('Product Out Of Stock');
                                                    } else {
                                                      cartList.add(addToCartModel);
                                                      addFocus();
                                                    }
                                                  } else {}
                                                });
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: context.height() < 720 ? 720 - 136 : context.height() - 136,
                                      color: Colors.white,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 80),
                                          const Image(
                                            image: AssetImage('images/empty_screen.png'),
                                          ),
                                          const SizedBox(height: 20),
                                          GestureDetector(
                                            onTap: () {
                                              context.push(
                                                '/product/add-product',
                                                extra: {
                                                  'allProductsCodeList': allProductsCodeList,
                                                  'warehouseBasedProductModel': [],
                                                },
                                              );
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(color: kBlueTextColor, borderRadius: BorderRadius.all(Radius.circular(15))),
                                              width: 200,
                                              child: Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Text(
                                                    lang.S.of(context).addProduct,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
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
                            }),
                          )
                        ])
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          );
        }, error: (e, stack) {
          return Center(
            child: Text(e.toString()),
          );
        }, loading: () {
          return const Center(child: CircularProgressIndicator());
        });
      },
    );
  }

  showDialogBox() => showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(lang.S.of(context).noConnection),
          content: Text(lang.S.of(context).pleaseCheckYourInternetConnectivity),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Navigator.pop(context, 'Cancel');
                GoRouter.of(context).pop();
                setState(() => isAlertSet = false);
                isDeviceConnected = await InternetConnection().hasInternetAccess;
                if (!isDeviceConnected && isAlertSet == false) {
                  showDialogBox();
                  setState(() => isAlertSet = true);
                }
              },
              child: Text(lang.S.of(context).tryAgain),
            ),
          ],
        ),
      );
}
