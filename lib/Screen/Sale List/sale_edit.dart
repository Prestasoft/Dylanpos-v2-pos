import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Sale%20List/show_edit_payment_popup.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/category_model.dart';
import '../../model/personal_information_model.dart';
import '../../model/product_model.dart';
import '../../model/sale_transaction_model.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Calculator/calculator.dart';
import '../currency/currency_provider.dart';

class SaleEdit extends StatefulWidget {
  const SaleEdit(
      {Key? key,
      required this.transitionModel,
      required this.personalInformationModel,
      required this.isPosScreen,
      required this.popUpContext})
      : super(key: key);

  final SaleTransactionModel transitionModel;
  final PersonalInformationModel personalInformationModel;
  final bool isPosScreen;
  final BuildContext popUpContext;

  // static const String route = '/sales-edit';

  @override
  State<SaleEdit> createState() => _SaleEditState();
}

class _SaleEditState extends State<SaleEdit> {
  List<AddToCartModel> cartList = [];
  List<AddToCartModel> pastProducts = [];
  List<AddToCartModel> decreaseStockList = [];
  String searchProductCode = '';
  String isSelected = 'Categories';
  String selectedCategory = 'Categories';
  FocusNode nameFocus = FocusNode();

  String getTotalAmount() {
    double total = 0.0;
    for (var item in cartList) {
      total = total + (double.parse(item.unitPrice) * item.quantity);
    }
    return total.toString();
  }

  bool uniqueCheck(String code) {
    bool isUnique = false;
    for (var item in cartList) {
      if (item.productId == code) {
        item.quantity += 1;
        isUnique = true;
        break;
      }
    }
    return isUnique;
  }

  DateTime selectedDueDate = DateTime.now();

  Future<void> _selectedDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDueDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  dynamic productPriceChecker(
      {required ProductModel product, required String customerType}) {
    if (customerType == "Regular") {
      return product.productSalePrice;
    } else if (customerType == "Frecuente") {
      return product.productWholeSalePrice == ''
          ? '0'
          : product.productWholeSalePrice;
    } else if (customerType == "Corporativo") {
      return product.productDealerPrice == ''
          ? '0'
          : product.productDealerPrice;
    } else if (customerType == "Guest") {
      return product.productSalePrice;
    }
  }

  bool uniqueCheckForSerial(
      {required String code, required List<dynamic> newSerialNumbers}) {
    for (var item in cartList) {
      if (item.productId == code) {
        item.serialNumber = item.serialNumber! + newSerialNumbers;
        // item.serialNumber?.add(newSerialNumbers);
        item.quantity += newSerialNumbers.length;
        return true;
      }
    }
    return false;
  }

  void showSerialNumberPopUp({required ProductModel productModel}) {
    List<String> list = productModel.serialNumber;
    TextEditingController editingController = TextEditingController();
    String searchWord = '';
    List<String> selectedSerialNumbers = [];
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
                      padding: const EdgeInsets.only(
                          top: 10.0, left: 10.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            lang.S.of(context).selectSerialNumber,
                            style: kTextStyle.copyWith(
                                color: kTitleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0),
                          ),
                          const Spacer(),
                          const Icon(FeatherIcons.x,
                                  color: kTitleColor, size: 25.0)
                              .onTap(() => {finish(context)})
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
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              labelText: lang.S.of(context).searchSerialNumber,
                              hintStyle:
                                  kTextStyle.copyWith(color: kGreyTextColor),
                              labelStyle:
                                  kTextStyle.copyWith(color: kTitleColor),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(lang.S.of(context).serialNumber),
                          const SizedBox(height: 10.0),
                          Container(
                            height: MediaQuery.of(context).size.height / 4,
                            width: 500,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(width: 1, color: Colors.grey),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10))),
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
                                          selectedSerialNumbers
                                              .add(list[index]);
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
                            decoration: BoxDecoration(
                                border:
                                    Border.all(width: 1, color: Colors.grey),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10))),
                            child: GridView.builder(
                                shrinkWrap: true,
                                itemCount: selectedSerialNumbers.length,
                                itemBuilder: (BuildContext context, int index) {
                                  if (selectedSerialNumbers.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                              onTap: () {
                                                setState1(() {
                                                  list.add(
                                                      selectedSerialNumbers[
                                                          index]);
                                                  selectedSerialNumbers
                                                      .removeAt(index);
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
                                    return Text(
                                        lang.S.of(context).noSerialNumberFound);
                                  }
                                },
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                              GestureDetector(
                                onTap: () => GoRouter.of(context).pop(),
                                child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 30.0,
                                        right: 30.0,
                                        top: 10.0,
                                        bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kRedTextColor,
                                    ),
                                    child: Text(
                                      lang.S.of(context).cancel,
                                      style: kTextStyle.copyWith(color: kWhite),
                                    )),
                              ),
                              const SizedBox(width: 10.0),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    AddToCartModel addToCartModel =
                                        AddToCartModel(
                                      productName: productModel.productName,
                                      warehouseName: productModel.warehouseName,
                                      warehouseId: productModel.warehouseId,
                                      productId: productModel.productCode,
                                      productImage: productModel.productPicture,
                                      productPurchasePrice:
                                          productModel.productPurchasePrice,
                                      subTotal: productPriceChecker(
                                          product: productModel,
                                          customerType: widget
                                              .transitionModel.customerType),
                                      unitPrice: '100',
                                      serialNumber: selectedSerialNumbers,
                                      subTaxes: productModel.subTaxes,
                                      excTax: productModel.excTax,
                                      groupTaxName: productModel.groupTaxName,
                                      groupTaxRate: productModel.groupTaxRate,
                                      incTax: productModel.incTax,
                                      margin: productModel.margin,
                                      taxType: productModel.taxType,
                                    );
                                    if (!uniqueCheckForSerial(
                                        code: productModel.productCode,
                                        newSerialNumbers:
                                            selectedSerialNumbers)) {
                                      if (productModel.productStock == '0') {
                                        EasyLoading.showError(lang.S
                                            .of(context)
                                            .productOutOfStock);
                                      } else {
                                        cartList.add(addToCartModel);
                                      }
                                    }
                                  });
                                  GoRouter.of(context).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 30.0,
                                      right: 30.0,
                                      top: 10.0,
                                      bottom: 10.0),
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

  // void showHoldPopUp() {
  //   showDialog(
  //     barrierDismissible: false,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return Dialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(5.0),
  //             ),
  //             child: SizedBox(
  //               width: 500,
  //               height: 200,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Padding(
  //                     padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           'Hold',
  //                           style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 20.0),
  //                         ),
  //                         const Spacer(),
  //                         const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {finish(context)})
  //                       ],
  //                     ),
  //                   ),
  //                   const Divider(thickness: 1.0, color: kLitGreyColor),
  //                   const SizedBox(height: 10.0),
  //                   Padding(
  //                     padding: const EdgeInsets.all(10.0),
  //                     child: Column(
  //                       children: [
  //                         AppTextField(
  //                           showCursor: true,
  //                           cursorColor: kTitleColor,
  //                           textFieldType: TextFieldType.NAME,
  //                           decoration: kInputDecoration.copyWith(
  //                             labelText: 'Hold Number',
  //                             hintText: '2090.00',
  //                             hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
  //                             labelStyle: kTextStyle.copyWith(color: kTitleColor),
  //                           ),
  //                         ),
  //                         const SizedBox(height: 20.0),
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.end,
  //                           children: [
  //                             Container(
  //                                 padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
  //                                 decoration: BoxDecoration(
  //                                   borderRadius: BorderRadius.circular(5.0),
  //                                   color: kRedTextColor,
  //                                 ),
  //                                 child: Text(
  //                                   'Cancel',
  //                                   style: kTextStyle.copyWith(color: kWhiteTextColor),
  //                                 )).onTap(() => {
  //                                   finish(context),
  //                                 }),
  //                             const SizedBox(width: 10.0),
  //                             Container(
  //                                 padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
  //                                 decoration: BoxDecoration(
  //                                   borderRadius: BorderRadius.circular(5.0),
  //                                   color: kBlueTextColor,
  //                                 ),
  //                                 child: Text(
  //                                   'Submit',
  //                                   style: kTextStyle.copyWith(color: kWhiteTextColor),
  //                                 )).onTap(() => {})
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void showCalcPopUp() {
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

  TextEditingController nameCodeCategoryController = TextEditingController();
  bool doNotCheckProducts = false;
  bool isGuestCustomer = false;

  double serviceCharge = 0;
  double discountAmount = 0;

  TextEditingController discountAmountEditingController =
      TextEditingController();

  // TextEditingController vatAmountEditingController = TextEditingController();
  TextEditingController discountPercentageEditingController =
      TextEditingController();

  // TextEditingController vatPercentageEditingController = TextEditingController();
  double vatGst = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    serviceCharge = widget.transitionModel.serviceCharge!;
    discountAmount = widget.transitionModel.discountAmount!.toDouble();

    pastProducts = widget.transitionModel.productList!;
    // vatGst = widget.transitionModel.vat!;
    discountPercentageEditingController.text = ((discountAmount * 100) /
            widget.transitionModel.totalAmount!.toDouble())
        .toStringAsFixed(1);
    discountAmountEditingController.text =
        widget.transitionModel.discountAmount.toString();
    // vatAmountEditingController.text = widget.transitionModel.vat.toString();
    // vatPercentageEditingController.text = vatPercentageEditingController.text = ((vatGst * 100) / widget.transitionModel.totalAmount!.toDouble()).toStringAsFixed(1);
  }

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
    return Consumer(
      builder: (context, consumerRef, __) {
        final wareHouseList = consumerRef.watch(warehouseProvider);
        final personalData = consumerRef.watch(profileDetailsProvider);
        final productLists = consumerRef.watch(productProvider);
        AsyncValue<List<ProductModel>> productList =
            consumerRef.watch(productProvider);
        if (!doNotCheckProducts) {
          List<AddToCartModel> list = [];
          productLists.value?.forEach((products) {
            String sentProductPrice = '';

            widget.transitionModel.productList?.forEach((element) {
              if (element.productId == products.productCode) {
                if (widget.transitionModel.customerType.contains('Regular')) {
                  sentProductPrice = products.productSalePrice;
                } else if (widget.transitionModel.customerType
                    .contains('Frecuente')) {
                  sentProductPrice = products.productDealerPrice;
                } else if (widget.transitionModel.customerType
                    .contains('Corporativo')) {
                  sentProductPrice = products.productWholeSalePrice;
                } else if (widget.transitionModel.customerType
                    .contains('Proveedor')) {
                  sentProductPrice = products.productPurchasePrice;
                } else if (widget.transitionModel.customerType
                    .contains('Guest')) {
                  sentProductPrice = products.productSalePrice;
                  isGuestCustomer = true;
                }
                AddToCartModel cartItem = AddToCartModel(
                  productName: products.productName,
                  warehouseName: products.warehouseName,
                  warehouseId: products.warehouseId,
                  productImage: products.productPicture,
                  subTotal: sentProductPrice,
                  quantity: element.quantity,
                  unitPrice: sentProductPrice,
                  productId: products.productCode,
                  productBrandName: products.brandName,
                  stock: int.parse(products.productStock),
                  serialNumber: products.serialNumber,
                  productPurchasePrice: products.productPurchasePrice,
                  subTaxes: products.subTaxes,
                  excTax: products.excTax,
                  groupTaxName: products.groupTaxName,
                  groupTaxRate: products.groupTaxRate,
                  incTax: products.incTax,
                  margin: products.margin,
                  taxType: products.taxType,
                );
                list.add(cartItem);
              }
            });

            if (widget.transitionModel.productList?.length == list.length) {
              cartList = list;
              // providerData.addToCartRiverPodForEdit(list);
              doNotCheckProducts = true;
            }
          });
        }
        return personalData.when(data: (data) {
          return Scaffold(
              backgroundColor: kDarkWhite,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: ResponsiveGridRow(rowSegments: 120, children: [
                        //-----------date-------------------
                        ResponsiveGridCol(
                          xs: screenWidth > 450 ? 60 : 120,
                          md: 40,
                          lg: 24,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              height: 40,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: kNeutral400),
                              ),
                              child: Center(
                                child: Text(
                                  widget.transitionModel.purchaseDate
                                      .substring(0, 10),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ).onTap(() => _selectedDueDate(context)),
                          ),
                        ),
                        //----------------previous due-----------------
                        ResponsiveGridCol(
                            xs: screenWidth > 450 ? 60 : 120,
                            md: 40,
                            lg: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).previousDue,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: kNeutral400),
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.transitionModel.dueAmount
                                              .toString(),
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        //--------------calculator section--------
                        ResponsiveGridCol(
                            xs: screenWidth > 450 ? 60 : 120,
                            md: 40,
                            lg: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).calculator,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 10),
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
                        //--------------dashboard section----------------
                        ResponsiveGridCol(
                          xs: screenWidth > 450 ? 60 : 120,
                          md: 40,
                          lg: 24,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
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
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ).onTap(() => context.go('/dashboard')),
                          ),
                        ),
                        //--------------warehouse section---------
                        ResponsiveGridCol(
                          xs: 60,
                          md: 40,
                          lg: 24,
                          child: wareHouseList.when(
                            data: (warehouse) {
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  height: 40,
                                  width: screenWidth,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: kNeutral400),
                                  ),
                                  child: Theme(
                                    data: ThemeData(
                                        highlightColor: dropdownItemColor,
                                        focusColor: Colors.transparent,
                                        hoverColor: dropdownItemColor),
                                    child: DropdownButtonHideUnderline(
                                      child: getWare(list: warehouse),
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
                        //----------------invoice----------------
                        ResponsiveGridCol(
                            xs: 60,
                            md: 40,
                            lg: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).invoiceCo,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: 10),
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
                                        "#${widget.transitionModel.invoiceNumber}",
                                        style: const TextStyle(
                                            color: kTitleColor,
                                            fontWeight: FontWeight.bold),
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        //-----------------select customer----------
                        ResponsiveGridCol(
                          xs: 120,
                          md: 40,
                          lg: 48,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: kNeutral400),
                              ),
                              child: Text(widget.transitionModel.customerName),
                            ),
                          ),
                        ),
                        //----------------search product-----------
                        ResponsiveGridCol(
                          xs: 120,
                          md: 40,
                          lg: 24,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: productList.when(data: (product) {
                              return SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: nameCodeCategoryController,
                                  showCursor: true,
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
                                        EasyLoading.showError(
                                            lang.S.of(context).noProductFound);
                                      }
                                      for (int i = 0; i < product.length; i++) {
                                        if (product[i].productCode == value) {
                                          AddToCartModel addToCartModel =
                                              AddToCartModel(
                                            productName: product[i].productName,
                                            warehouseName:
                                                product[i].warehouseName,
                                            warehouseId: product[i].warehouseId,
                                            productId: product[i].productCode,
                                            productImage:
                                                product[i].productPicture,
                                            quantity: 1,
                                            serialNumber: [],
                                            productPurchasePrice:
                                                product[i].productPurchasePrice,
                                            subTotal: productPriceChecker(
                                                product: product[i],
                                                customerType: widget
                                                    .transitionModel
                                                    .customerType),
                                            subTaxes: product[i].subTaxes,
                                            excTax: product[i].excTax,
                                            groupTaxName:
                                                product[i].groupTaxName,
                                            groupTaxRate:
                                                product[i].groupTaxRate,
                                            incTax: product[i].incTax,
                                            margin: product[i].margin,
                                            taxType: product[i].taxType,
                                          );

                                          setState(() {
                                            if (!uniqueCheck(
                                                product[i].productCode)) {
                                              cartList.add(addToCartModel);
                                              nameCodeCategoryController
                                                  .clear();
                                              nameFocus.requestFocus();
                                              searchProductCode = '';
                                            } else {
                                              nameCodeCategoryController
                                                  .clear();
                                              nameFocus.requestFocus();
                                              searchProductCode = '';
                                            }
                                          });
                                          break;
                                        }
                                        if (i + 1 == product.length) {
                                          nameCodeCategoryController.clear();
                                          nameFocus.requestFocus();
                                          EasyLoading.showError(
                                              lang.S.of(context).notFound);
                                          setState(() {
                                            searchProductCode = '';
                                          });
                                        }
                                      }
                                    }
                                  },
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(MdiIcons.barcode,
                                        color: kTitleColor, size: 18.0),
                                    hintText:
                                        lang.S.of(context).nameCodeOrCateogry,
                                    hintStyle: kTextStyle.copyWith(
                                        color: kGreyTextColor),
                                    border: InputBorder.none,
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
                            }),
                          ),
                        ),
                        //-------------customer type-------------
                        ResponsiveGridCol(
                          xs: 120,
                          md: 40,
                          lg: 24,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: kNeutral400),
                              ),
                              child: Center(
                                child: Text(
                                  widget.transitionModel.customerType
                                      .toString(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20.0),

                    ///__________sale_bord_____________________________________________
                    ResponsiveGridRow(rowSegments: 100, children: [
                      //------------------cart list--------------------------
                      ResponsiveGridCol(
                        lg: 47,
                        md: 100,
                        xs: 100,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Scrollbar(
                                child: Container(
                                  height: context.height() < 720
                                      ? 720 - 410
                                      : context.height() - 410,
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              width: 1, color: kNeutral300))),
                                  child: LayoutBuilder(
                                    builder: (BuildContext context,
                                        BoxConstraints constraints) {
                                      final kWidth = constraints.maxWidth;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        controller: _horizontalScroll,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: kWidth,
                                          ),
                                          child: Theme(
                                            data: theme.copyWith(
                                                dividerColor:
                                                    Colors.transparent,
                                                dividerTheme:
                                                    const DividerThemeData(
                                                        color: Colors
                                                            .transparent)),
                                            child: DataTable(
                                                border: const TableBorder(
                                                  horizontalInside: BorderSide(
                                                    width: 1,
                                                    color: kNeutral300,
                                                  ),
                                                ),
                                                dataRowColor:
                                                    const WidgetStatePropertyAll(
                                                        whiteColor),
                                                headingRowColor:
                                                    WidgetStateProperty.all(
                                                        const Color(
                                                            0xFFF8F3FF)),
                                                showBottomBorder: false,
                                                dividerThickness: 0.0,
                                                headingTextStyle:
                                                    theme.textTheme.titleMedium,
                                                dataTextStyle:
                                                    theme.textTheme.bodyLarge,
                                                columns: [
                                                  DataColumn(
                                                      label: Text(lang.S
                                                          .of(context)
                                                          .productName)),
                                                  DataColumn(
                                                      label: Text(lang.S
                                                          .of(context)
                                                          .quantity)),
                                                  DataColumn(
                                                      label: Text(lang.S
                                                          .of(context)
                                                          .price)),
                                                  DataColumn(
                                                      label: Text(lang.S
                                                          .of(context)
                                                          .subTotal)),
                                                  DataColumn(
                                                      label: Text(lang.S
                                                          .of(context)
                                                          .action)),
                                                ],
                                                rows: List.generate(
                                                    cartList.length, (index) {
                                                  int i = 0;
                                                  for (var element
                                                      in pastProducts) {
                                                    if (element.productId !=
                                                        cartList[index]
                                                            .productId) {
                                                      i++;
                                                    }
                                                    if (i ==
                                                        pastProducts.length) {
                                                      bool isInTheList = false;
                                                      for (var element
                                                          in decreaseStockList) {
                                                        if (element.productId ==
                                                            cartList[index]
                                                                .productId) {
                                                          element.quantity =
                                                              cartList[index]
                                                                  .quantity;
                                                          isInTheList = true;
                                                          break;
                                                        }
                                                      }

                                                      isInTheList
                                                          ? null
                                                          : decreaseStockList
                                                              .add(cartList[
                                                                  index]);
                                                    }
                                                  }
                                                  TextEditingController
                                                      quantityController =
                                                      TextEditingController(
                                                          text: cartList[index]
                                                              .quantity
                                                              .toString());
                                                  return DataRow(cells: [
                                                    ///______________name__________________________________________________
                                                    DataCell(
                                                      Text(
                                                        cartList[index]
                                                                .productName ??
                                                            '',
                                                      ),
                                                    ),

                                                    ///____________quantity_________________________________________________
                                                    DataCell(
                                                      Center(
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                                    FontAwesomeIcons
                                                                        .solidSquareMinus,
                                                                    color:
                                                                        kBlueTextColor)
                                                                .onTap(() {
                                                              setState(() {
                                                                cartList[index]
                                                                            .quantity >
                                                                        1
                                                                    ? cartList[
                                                                            index]
                                                                        .quantity--
                                                                    : cartList[
                                                                            index]
                                                                        .quantity = 1;
                                                              });
                                                            }),
                                                            const SizedBox(
                                                                width: 5),
                                                            SizedBox(
                                                              width: 60,
                                                              height: 35,
                                                              child:
                                                                  TextFormField(
                                                                controller:
                                                                    quantityController,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                onChanged:
                                                                    (value) {
                                                                  if (cartList[
                                                                              index]
                                                                          .stock!
                                                                          .toInt() <
                                                                      value
                                                                          .toInt()) {
                                                                    EasyLoading.showError(lang
                                                                        .S
                                                                        .of(context)
                                                                        .outOfStock);
                                                                    quantityController
                                                                        .clear();
                                                                  } else if (value ==
                                                                      '') {
                                                                    cartList[
                                                                            index]
                                                                        .quantity = 1;
                                                                  } else if (value ==
                                                                      '0') {
                                                                    cartList[
                                                                            index]
                                                                        .quantity = 1;
                                                                  } else {
                                                                    cartList[index]
                                                                            .quantity =
                                                                        value
                                                                            .toInt();
                                                                  }
                                                                },
                                                                onFieldSubmitted:
                                                                    (value) {
                                                                  if (value ==
                                                                      '') {
                                                                    setState(
                                                                        () {
                                                                      cartList[
                                                                              index]
                                                                          .quantity = 1;
                                                                    });
                                                                  } else {
                                                                    setState(
                                                                        () {
                                                                      cartList[index]
                                                                              .quantity =
                                                                          value
                                                                              .toInt();
                                                                    });
                                                                  }
                                                                },
                                                                decoration:
                                                                    const InputDecoration(
                                                                        border:
                                                                            InputBorder.none),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 5),
                                                            const Icon(
                                                                    FontAwesomeIcons
                                                                        .solidSquarePlus,
                                                                    color:
                                                                        kBlueTextColor)
                                                                .onTap(() {
                                                              if (cartList[
                                                                          index]
                                                                      .quantity <
                                                                  cartList[
                                                                          index]
                                                                      .stock!
                                                                      .toInt()) {
                                                                setState(() {
                                                                  cartList[
                                                                          index]
                                                                      .quantity += 1;
                                                                  toast(cartList[
                                                                          index]
                                                                      .quantity
                                                                      .toString());
                                                                });
                                                              } else {
                                                                EasyLoading.showError(lang
                                                                    .S
                                                                    .of(context)
                                                                    .outOfStock);
                                                              }
                                                            }),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    ///______price___________________________________________________________
                                                    DataCell(
                                                      SizedBox(
                                                        width: 70,
                                                        height: 35,
                                                        child: TextFormField(
                                                          initialValue:
                                                              cartList[index]
                                                                  .subTotal,
                                                          onChanged: (value) {
                                                            if (value == '') {
                                                              setState(() {
                                                                cartList[index]
                                                                        .subTotal =
                                                                    0.toString();
                                                              });
                                                            } else if (double
                                                                    .tryParse(
                                                                        value) ==
                                                                null) {
                                                              EasyLoading
                                                                  .showError(lang
                                                                      .S
                                                                      .of(context)
                                                                      .enterAValidPrice);
                                                            } else {
                                                              setState(() {
                                                                cartList[index]
                                                                        .subTotal =
                                                                    value;
                                                              });
                                                            }
                                                          },
                                                          onFieldSubmitted:
                                                              (value) {
                                                            if (value == '') {
                                                              setState(() {
                                                                cartList[index]
                                                                        .subTotal =
                                                                    0.toString();
                                                              });
                                                            } else if (double
                                                                    .tryParse(
                                                                        value) ==
                                                                null) {
                                                              EasyLoading
                                                                  .showError(lang
                                                                      .S
                                                                      .of(context)
                                                                      .enterAValidPrice);
                                                            } else {
                                                              setState(() {
                                                                cartList[index]
                                                                        .subTotal =
                                                                    value;
                                                              });
                                                            }
                                                          },
                                                          decoration:
                                                              const InputDecoration(),
                                                        ),
                                                      ),
                                                    ),

                                                    ///___________subtotal____________________________________________________
                                                    DataCell(
                                                      Text(
                                                        (double.parse(cartList[
                                                                        index]
                                                                    .subTotal) *
                                                                cartList[index]
                                                                    .quantity)
                                                            .toString(),
                                                        style:
                                                            kTextStyle.copyWith(
                                                                color:
                                                                    kTitleColor),
                                                      ),
                                                    ),

                                                    ///_______________actions_________________________________________________
                                                    DataCell(
                                                      const Icon(
                                                        Icons.close_sharp,
                                                        color: redColor,
                                                      ).onTap(() {
                                                        setState(() {
                                                          cartList
                                                              .removeAt(index);
                                                        });
                                                      }),
                                                    ),
                                                  ]);
                                                })),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ///__________total__________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Text(
                                            '${lang.S.of(context).totalItem}: ${cartList.length}',
                                            style: theme.textTheme.titleMedium,
                                          )),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Row(
                                            children: [
                                              Text(
                                                lang.S.of(context).subTotal,
                                                textAlign: TextAlign.end,
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                  child: Container(
                                                padding: const EdgeInsets.only(
                                                    left: 20.0,
                                                    right: 20.0,
                                                    top: 4.0,
                                                    bottom: 4.0),
                                                decoration: const BoxDecoration(
                                                    color: kGreenTextColor,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                8))),
                                                child: Center(
                                                  child: Text(
                                                    '$globalCurrency ${(getTotalAmount().toDouble() + serviceCharge - discountAmount + vatGst).toStringAsFixed(1)}',
                                                    style: kTextStyle.copyWith(
                                                        color: kWhite,
                                                        fontSize: 18.0,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              )),
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
                                        child: ListView.builder(
                                          itemCount: getAllTaxFromCartList(
                                                  cart: cartList)
                                              .length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                  top: 5, bottom: 5),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    getAllTaxFromCartList(
                                                            cart:
                                                                cartList)[index]
                                                        .name,
                                                    style: theme
                                                        .textTheme.titleMedium,
                                                  ),
                                                  Flexible(
                                                    child: AppTextField(
                                                      initialValue:
                                                          getAllTaxFromCartList(
                                                                      cart:
                                                                          cartList)[
                                                                  index]
                                                              .taxRate
                                                              .toString(),
                                                      readOnly: true,
                                                      textAlign:
                                                          TextAlign.right,
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 6.0),
                                                        hintText: '0',
                                                        border: const OutlineInputBorder(
                                                            gapPadding: 0.0,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xFFff5f00))),
                                                        enabledBorder:
                                                            const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xFFff5f00))),
                                                        disabledBorder:
                                                            const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xFFff5f00))),
                                                        focusedBorder:
                                                            const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xFFff5f00))),
                                                        prefixIconConstraints:
                                                            const BoxConstraints(
                                                                maxWidth: 30.0,
                                                                minWidth: 30.0),
                                                        prefixIcon: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 8.0,
                                                                  left: 8.0),
                                                          height: 40,
                                                          decoration: const BoxDecoration(
                                                              color: Color(
                                                                  0xFFff5f00),
                                                              borderRadius: BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          4.0),
                                                                  bottomLeft: Radius
                                                                      .circular(
                                                                          4.0))),
                                                          child: const Text(
                                                            '%',
                                                            style: TextStyle(
                                                                fontSize: 20.0,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                      textFieldType:
                                                          TextFieldType.NUMBER,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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
                                        child: Row(
                                          children: [
                                            Text(
                                              lang.S
                                                  .of(context)
                                                  .shpingOrServices,
                                              textAlign: TextAlign.end,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: SizedBox(
                                                height: 40,
                                                child: TextFormField(
                                                  initialValue:
                                                      serviceCharge.toString(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      serviceCharge =
                                                          value.toDouble();
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                      hintText: lang.S
                                                          .of(context)
                                                          .enterAmount),
                                                  textAlign: TextAlign.center,
                                                ),
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
                                    //                     vatGst = 0.0;
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
                                    //               textFieldType: TextFieldType.PHONE,
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
                                    //                     style: TextStyle(fontSize: 20.0, color: Colors.white),
                                    //                   ),
                                    //                 ),
                                    //               ),
                                    //               textFieldType: TextFieldType.PHONE,
                                    //             ),
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ],
                                    // ),
                                    // const SizedBox(height: 10.0),

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
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              lang.S.of(context).discount,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: SizedBox(
                                                      height: 40.0,
                                                      child: Center(
                                                        child: AppTextField(
                                                          controller:
                                                              discountPercentageEditingController,
                                                          onChanged: (value) {
                                                            if (value == '') {
                                                              setState(() {
                                                                discountAmountEditingController
                                                                        .text =
                                                                    0.toString();
                                                              });
                                                            } else {
                                                              if (value
                                                                      .toInt() <=
                                                                  100) {
                                                                setState(() {
                                                                  discountAmount = double.parse(((value.toDouble() /
                                                                              100) *
                                                                          getTotalAmount()
                                                                              .toDouble())
                                                                      .toStringAsFixed(
                                                                          1));
                                                                  discountAmountEditingController
                                                                          .text =
                                                                      discountAmount
                                                                          .toString();
                                                                });
                                                              } else {
                                                                setState(() {
                                                                  discountAmount =
                                                                      0;
                                                                  discountAmountEditingController
                                                                      .clear();
                                                                  discountPercentageEditingController
                                                                      .clear();
                                                                });
                                                                EasyLoading.showError(lang
                                                                    .S
                                                                    .of(context)
                                                                    .enterAValidDiscount);
                                                              }
                                                            }
                                                          },
                                                          textAlign:
                                                              TextAlign.right,
                                                          decoration:
                                                              InputDecoration(
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 6.0),
                                                            hintText: '0',
                                                            border: const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xFFff5f00))),
                                                            enabledBorder: const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xFFff5f00))),
                                                            disabledBorder:
                                                                const OutlineInputBorder(
                                                                    gapPadding:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                Color(0xFFff5f00))),
                                                            focusedBorder: const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide: BorderSide(
                                                                    color: Color(
                                                                        0xFFff5f00))),
                                                            prefixIconConstraints:
                                                                const BoxConstraints(
                                                                    maxWidth:
                                                                        30.0,
                                                                    minWidth:
                                                                        30.0),
                                                            prefixIcon:
                                                                Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 8.0,
                                                                      left:
                                                                          8.0),
                                                              height: 40,
                                                              decoration: const BoxDecoration(
                                                                  color: Color(
                                                                      0xFFff5f00),
                                                                  borderRadius: BorderRadius.only(
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              4.0),
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              4.0))),
                                                              child: const Text(
                                                                '%',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20.0,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                          ),
                                                          textFieldType:
                                                              TextFieldType
                                                                  .PHONE,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 4.0,
                                                  ),
                                                  Flexible(
                                                    child: SizedBox(
                                                      // width: 100,
                                                      height: 40.0,
                                                      child: Center(
                                                        child: AppTextField(
                                                          controller:
                                                              discountAmountEditingController,
                                                          onChanged: (value) {
                                                            if (value == '') {
                                                              setState(() {
                                                                discountAmount =
                                                                    0;
                                                                discountPercentageEditingController
                                                                        .text =
                                                                    0.toString();
                                                              });
                                                            } else {
                                                              if (value
                                                                      .toInt() <=
                                                                  getTotalAmount()
                                                                      .toDouble()) {
                                                                setState(
                                                                  () {
                                                                    discountAmount =
                                                                        double.parse(
                                                                            value);
                                                                    discountPercentageEditingController
                                                                        .text = ((discountAmount *
                                                                                100) /
                                                                            getTotalAmount()
                                                                                .toDouble())
                                                                        .toStringAsFixed(
                                                                            1);
                                                                  },
                                                                );
                                                              } else {
                                                                setState(
                                                                  () {
                                                                    discountAmount =
                                                                        0;
                                                                    discountPercentageEditingController
                                                                        .clear();
                                                                    discountAmountEditingController
                                                                        .clear();
                                                                  },
                                                                );
                                                                EasyLoading.showError(lang
                                                                    .S
                                                                    .of(context)
                                                                    .enterAValidDiscount);
                                                              }
                                                            }
                                                          },
                                                          textAlign:
                                                              TextAlign.right,
                                                          decoration:
                                                              InputDecoration(
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 6.0),
                                                            hintText: '0',
                                                            border: const OutlineInputBorder(
                                                                gapPadding: 0.0,
                                                                borderSide:
                                                                    BorderSide(
                                                                        color:
                                                                            kMainColor)),
                                                            enabledBorder:
                                                                const OutlineInputBorder(
                                                                    gapPadding:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                kMainColor)),
                                                            disabledBorder:
                                                                const OutlineInputBorder(
                                                                    gapPadding:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                kMainColor)),
                                                            focusedBorder:
                                                                const OutlineInputBorder(
                                                                    gapPadding:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                kMainColor)),
                                                            prefixIconConstraints:
                                                                const BoxConstraints(
                                                                    maxWidth:
                                                                        30.0,
                                                                    minWidth:
                                                                        30.0),
                                                            prefixIcon:
                                                                Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 8.0,
                                                                      left:
                                                                          8.0),
                                                              height: 40,
                                                              decoration: const BoxDecoration(
                                                                  color:
                                                                      kMainColor,
                                                                  borderRadius: BorderRadius.only(
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              4.0),
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              4.0))),
                                                              child: Text(
                                                                currency,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        20.0,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                          ),
                                                          textFieldType:
                                                              TextFieldType
                                                                  .PHONE,
                                                        ),
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

                                    ///__________buttons______________________________________
                                    const SizedBox(height: 20.0),
                                    ResponsiveGridRow(children: [
                                      //----------------cancel---------------------
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
                                              onPressed: () {
                                                GoRouter.of(context)
                                                    .pop(widget.popUpContext);
                                              },
                                              child: Text(
                                                lang.S.of(context).cancel,
                                              ),
                                            ),
                                          )),
                                      //----------------payment---------------------
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: kMainColor,
                                              ),
                                              onPressed: () {
                                                if (cartList.isEmpty) {
                                                  EasyLoading.showError(lang.S
                                                      .of(context)
                                                      .pleaseAddSomeProductFirst);
                                                } else {
                                                  SaleTransactionModel
                                                      transitionModel =
                                                      SaleTransactionModel(
                                                    dueAmount: widget
                                                        .transitionModel
                                                        .dueAmount,
                                                    customerAddress: widget
                                                        .transitionModel
                                                        .customerAddress,
                                                    customerImage: widget
                                                        .transitionModel
                                                        .customerImage,
                                                    customerGst: widget
                                                        .transitionModel
                                                        .customerGst,
                                                    customerName: widget
                                                        .transitionModel
                                                        .customerName,
                                                    customerType: widget
                                                        .transitionModel
                                                        .customerType,
                                                    customerPhone: widget
                                                        .transitionModel
                                                        .customerPhone,
                                                    invoiceNumber: widget
                                                        .transitionModel
                                                        .invoiceNumber,
                                                    purchaseDate: widget
                                                        .transitionModel
                                                        .purchaseDate,
                                                    productList: cartList,
                                                    discountAmount:
                                                        discountAmount,
                                                    serviceCharge:
                                                        serviceCharge,
                                                    vat: vatGst,
                                                    totalAmount:
                                                        getTotalAmount()
                                                                .toDouble() +
                                                            vatGst +
                                                            serviceCharge -
                                                            discountAmount,
                                                  );
                                                  ShowEditPaymentPopUp(
                                                    newTransitionModel:
                                                        transitionModel,
                                                    oldTransitionModel:
                                                        widget.transitionModel,
                                                    previousPaid: widget
                                                            .transitionModel
                                                            .totalAmount! -
                                                        widget.transitionModel
                                                            .dueAmount!
                                                            .toDouble(),
                                                    decreaseStockList:
                                                        decreaseStockList,
                                                    pastProducts: pastProducts,
                                                    saleListPopUpContext:
                                                        widget.popUpContext,
                                                  ).launch(context);
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
                      //----------------------selected Category-------------------
                      ResponsiveGridCol(
                        lg: 14,
                        md: 100,
                        xs: 100,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 1240 ? 0 : 16,
                              vertical: screenWidth > 1240 ? 0 : 12),
                          child: Consumer(
                            builder: (_, ref, watch) {
                              AsyncValue<List<CategoryModel>> categoryList =
                                  ref.watch(categoryProvider);
                              return categoryList.when(data: (category) {
                                return Container(
                                  // width: 150,
                                  height: screenWidth < 1240
                                      ? 110
                                      : context.height() < 720
                                          ? 720 - 142
                                          : context.height() - 160,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: const BoxDecoration(
                                      color: kWhite,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(15))),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: screenWidth < 1240
                                                  ? Colors.transparent
                                                  : isSelected == 'Categories'
                                                      ? kBlueTextColor
                                                      : kBlueTextColor
                                                          .withOpacity(0.1)),
                                          padding: EdgeInsets.only(
                                              left: screenWidth < 1240 ? 0 : 15,
                                              right: 8,
                                              top: screenWidth < 1240 ? 0 : 5,
                                              bottom:
                                                  screenWidth < 1240 ? 0 : 5),
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'Categories',
                                                  textAlign: TextAlign.start,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.titleSmall
                                                      ?.copyWith(
                                                          color: isSelected ==
                                                                  'Categories'
                                                              ? screenWidth <
                                                                      1240
                                                                  ? kTitleColor
                                                                  : Colors.white
                                                              : kDarkGreyColor,
                                                          fontSize:
                                                              screenWidth < 1240
                                                                  ? 20
                                                                  : 14),
                                                ),
                                              ),
                                              Icon(
                                                Icons.keyboard_arrow_right,
                                                color:
                                                    isSelected == 'Categories'
                                                        ? Colors.white
                                                        : kDarkGreyColor,
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
                                          scrollDirection: screenWidth < 1240
                                              ? Axis.horizontal
                                              : Axis.vertical,
                                          itemCount: category.length,
                                          shrinkWrap: true,
                                          itemBuilder: (_, i) {
                                            return GestureDetector(
                                              onTap: (() {
                                                setState(() {
                                                  isSelected =
                                                      category[i].categoryName;
                                                  selectedCategory =
                                                      category[i].categoryName;
                                                });
                                              }),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: 5,
                                                    bottom: 5,
                                                    right: screenWidth < 1240
                                                        ? 10
                                                        : 0),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 15.0,
                                                          right: 8.0,
                                                          top: 8.0,
                                                          bottom: 8.0),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5.0),
                                                      color: isSelected ==
                                                              category[i]
                                                                  .categoryName
                                                          ? kBlueTextColor
                                                          : kBlueTextColor
                                                              .withOpacity(
                                                                  0.1)),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      screenWidth < 1240
                                                          ? Text(
                                                              category[i]
                                                                  .categoryName,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: theme
                                                                  .textTheme
                                                                  .titleSmall
                                                                  ?.copyWith(
                                                                      color: isSelected ==
                                                                              category[i].categoryName
                                                                          ? Colors.white
                                                                          : kDarkGreyColor),
                                                            )
                                                          : Flexible(
                                                              child: Text(
                                                                category[i]
                                                                    .categoryName,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: kTextStyle.copyWith(
                                                                    color: isSelected ==
                                                                            category[i]
                                                                                .categoryName
                                                                        ? Colors
                                                                            .white
                                                                        : kDarkGreyColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ),
                                                      Icon(
                                                        Icons
                                                            .keyboard_arrow_right,
                                                        color: isSelected ==
                                                                category[i]
                                                                    .categoryName
                                                            ? Colors.white
                                                            : kDarkGreyColor,
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
                      //-----------------------product list---------------
                      ResponsiveGridCol(
                        lg: 39,
                        md: 100,
                        xs: 100,
                        child: productList.when(
                          data: (products) {
                            List<ProductModel> showProductVsCategory = [];
                            if (selectedCategory == 'Categories') {
                              for (var element in products) {
                                if (element.productCode
                                        .toLowerCase()
                                        .contains(searchProductCode) ||
                                    element.productCategory
                                        .toLowerCase()
                                        .contains(searchProductCode) ||
                                    element.productName
                                        .toLowerCase()
                                        .contains(searchProductCode)) {
                                  productPriceChecker(
                                                  product: element,
                                                  customerType: widget
                                                      .transitionModel
                                                      .customerType) !=
                                              '0' &&
                                          (selectedWareHouse?.id ==
                                              element.warehouseId)
                                      ? showProductVsCategory.add(element)
                                      : null;
                                }
                              }
                            } else {
                              for (var element in products) {
                                if (element.productCategory ==
                                    selectedCategory) {
                                  productPriceChecker(
                                                  product: element,
                                                  customerType: widget
                                                      .transitionModel
                                                      .customerType) !=
                                              '0' &&
                                          (selectedWareHouse?.id ==
                                              element.warehouseId)
                                      ? showProductVsCategory.add(element)
                                      : null;
                                }
                              }
                            }

                            return showProductVsCategory.isNotEmpty
                                ? Container(
                                    height: context.height() - 160,
                                    decoration: const BoxDecoration(
                                      color: kDarkWhite,
                                    ),
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
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
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            color: kWhite,
                                            border: Border.all(
                                              color: kLitGreyColor,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ///__________image________________________________________________
                                              Stack(
                                                alignment: Alignment.topLeft,
                                                children: [
                                                  Container(
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                              topLeft: Radius
                                                                  .circular(
                                                                      10.0),
                                                              topRight: Radius
                                                                  .circular(
                                                                      10.0)),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                              showProductVsCategory[
                                                                      i]
                                                                  .productPicture),
                                                          fit: BoxFit.cover),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 5,
                                                    top: 5,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 5.0,
                                                              right: 5.0),
                                                      decoration: BoxDecoration(
                                                          color: showProductVsCategory[
                                                                          i]
                                                                      .productStock ==
                                                                  '0'
                                                              ? kRedTextColor
                                                              : kGreenTextColor),
                                                      child: Text(
                                                        showProductVsCategory[i]
                                                                    .productStock !=
                                                                '0'
                                                            ? '${showProductVsCategory[i].productStock} pc'
                                                            : lang.S
                                                                .of(context)
                                                                .outOfStock,
                                                        style: theme.textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                                color: kWhite),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10.0,
                                                    left: 5,
                                                    right: 3),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ///______name_______________________________________________
                                                    Text(
                                                      showProductVsCategory[i]
                                                          .productName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme.bodyLarge,
                                                    ),
                                                    const SizedBox(height: 4.0),

                                                    ///________Purchase_price______________________________________________________
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 5.0,
                                                              right: 5.0),
                                                      decoration: BoxDecoration(
                                                        color: kGreenTextColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2.0),
                                                      ),
                                                      child: Text(
                                                        productPriceChecker(
                                                            product:
                                                                showProductVsCategory[
                                                                    i],
                                                            customerType: widget
                                                                .transitionModel
                                                                .customerType),
                                                        style: theme.textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                                color: kWhite),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).onTap(() {
                                          if (showProductVsCategory[i]
                                              .serialNumber
                                              .isNotEmpty) {
                                            showSerialNumberPopUp(
                                                productModel:
                                                    showProductVsCategory[i]);
                                          } else {
                                            setState(
                                              () {
                                                AddToCartModel addToCartModel =
                                                    AddToCartModel(
                                                  productName:
                                                      showProductVsCategory[i]
                                                          .productName,
                                                  warehouseName:
                                                      showProductVsCategory[i]
                                                          .warehouseName,
                                                  warehouseId:
                                                      showProductVsCategory[i]
                                                          .warehouseId,
                                                  productImage:
                                                      showProductVsCategory[i]
                                                          .productPicture,
                                                  productId:
                                                      showProductVsCategory[i]
                                                          .productCode,
                                                  productPurchasePrice:
                                                      showProductVsCategory[i]
                                                          .productPurchasePrice,
                                                  subTotal: productPriceChecker(
                                                      product:
                                                          showProductVsCategory[
                                                              i],
                                                      customerType: widget
                                                          .transitionModel
                                                          .customerType),
                                                  serialNumber: [],
                                                  unitPrice: productPriceChecker(
                                                      product:
                                                          showProductVsCategory[
                                                              i],
                                                      customerType: widget
                                                          .transitionModel
                                                          .customerType),
                                                  subTaxes:
                                                      showProductVsCategory[i]
                                                          .subTaxes,
                                                  excTax:
                                                      showProductVsCategory[i]
                                                          .excTax,
                                                  groupTaxName:
                                                      showProductVsCategory[i]
                                                          .groupTaxName,
                                                  groupTaxRate:
                                                      showProductVsCategory[i]
                                                          .groupTaxRate,
                                                  incTax:
                                                      showProductVsCategory[i]
                                                          .incTax,
                                                  margin:
                                                      showProductVsCategory[i]
                                                          .margin,
                                                  taxType:
                                                      showProductVsCategory[i]
                                                          .taxType,
                                                );

                                                if (!uniqueCheck(
                                                    showProductVsCategory[i]
                                                        .productCode)) {
                                                  if (showProductVsCategory[i]
                                                          .productStock ==
                                                      '0') {
                                                    EasyLoading.showError(lang.S
                                                        .of(context)
                                                        .productOutOfStock);
                                                  } else {
                                                    cartList
                                                        .add(addToCartModel);
                                                  }
                                                } else {}
                                              },
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  )
                                : Container(
                                    height: context.height() < 720
                                        ? 720 - 136
                                        : context.height() - 136,
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 80),
                                        const Image(
                                          image: AssetImage(
                                              'images/empty_screen.png'),
                                        ),
                                        const SizedBox(height: 20),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                color: kBlueTextColor,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(15))),
                                            width: 200,
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20.0),
                                                child: Text(
                                                  lang.S.of(context).addProduct,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.0),
                                                ),
                                              ),
                                            ),
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
                        ),
                      )
                    ]),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.start,
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     ///___________Cart_List_________________________________________
                    //     IntrinsicWidth(
                    //       child: Container(
                    //         decoration: BoxDecoration(
                    //           color: kWhite,
                    //           border: Border.all(width: 1, color: kGreyTextColor.withOpacity(0.3)),
                    //           borderRadius: const BorderRadius.all(
                    //             Radius.circular(15),
                    //           ),
                    //         ),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Container(
                    //               width: context.width() < 1260 ? 630 : context.width() * 0.5,
                    //               height: context.height() < 720 ? 720 - 410 : context.height() - 410,
                    //               decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: kGreyTextColor.withOpacity(0.3)))),
                    //               child: SingleChildScrollView(
                    //                 child: Column(
                    //                   children: [
                    //                     Container(
                    //                       padding: const EdgeInsets.all(15),
                    //                       decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: kGreyTextColor.withOpacity(0.3)))),
                    //                       child: Row(
                    //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                         children: [
                    //                           SizedBox(width: 250, child: Text(lang.S.of(context).productName)),
                    //                           SizedBox(width: 110, child: Text(lang.S.of(context).quantity)),
                    //                           SizedBox(width: 70, child: Text(lang.S.of(context).price)),
                    //                           SizedBox(width: 100, child: Text(lang.S.of(context).subTotal)),
                    //                           SizedBox(width: 50, child: Text(lang.S.of(context).action)),
                    //                         ],
                    //                       ),
                    //                     ),
                    //                     ListView.builder(
                    //                       shrinkWrap: true,
                    //                       physics: const NeverScrollableScrollPhysics(),
                    //                       itemCount: cartList.length,
                    //                       itemBuilder: (BuildContext context, int index) {
                    //                         int i = 0;
                    //                         for (var element in pastProducts) {
                    //                           if (element.productId != cartList[index].productId) {
                    //                             i++;
                    //                           }
                    //                           if (i == pastProducts.length) {
                    //                             bool isInTheList = false;
                    //                             for (var element in decreaseStockList) {
                    //                               if (element.productId == cartList[index].productId) {
                    //                                 element.quantity = cartList[index].quantity;
                    //                                 isInTheList = true;
                    //                                 break;
                    //                               }
                    //                             }
                    //
                    //                             isInTheList ? null : decreaseStockList.add(cartList[index]);
                    //                           }
                    //                         }
                    //                         TextEditingController quantityController = TextEditingController(text: cartList[index].quantity.toString());
                    //                         return Column(
                    //                           children: [
                    //                             Row(
                    //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                               children: [
                    //                                 ///______________name__________________________________________________
                    //                                 Container(
                    //                                   width: 250,
                    //                                   padding: const EdgeInsets.only(left: 15),
                    //                                   child: Column(
                    //                                     mainAxisSize: MainAxisSize.min,
                    //                                     crossAxisAlignment: CrossAxisAlignment.start,
                    //                                     mainAxisAlignment: MainAxisAlignment.center,
                    //                                     children: [
                    //                                       Flexible(
                    //                                         child: Text(
                    //                                           cartList[index].productName ?? '',
                    //                                           maxLines: 2,
                    //                                           overflow: TextOverflow.ellipsis,
                    //                                           style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                                         ),
                    //                                       ),
                    //                                     ],
                    //                                   ),
                    //                                 ),
                    //
                    //                                 ///____________quantity_________________________________________________
                    //                                 SizedBox(
                    //                                   width: 110,
                    //                                   child: Center(
                    //                                     child: Row(
                    //                                       children: [
                    //                                         const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor).onTap(() {
                    //                                           setState(() {
                    //                                             cartList[index].quantity > 1 ? cartList[index].quantity-- : cartList[index].quantity = 1;
                    //                                           });
                    //                                         }),
                    //                                         Container(
                    //                                           width: 60,
                    //                                           padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                    //                                           decoration: BoxDecoration(
                    //                                             borderRadius: BorderRadius.circular(2.0),
                    //                                             color: Colors.white,
                    //                                           ),
                    //                                           child: TextFormField(
                    //                                             controller: quantityController,
                    //                                             textAlign: TextAlign.center,
                    //                                             onChanged: (value) {
                    //                                               if (cartList[index].stock!.toInt() < value.toInt()) {
                    //                                                 EasyLoading.showError(lang.S.of(context).outOfStock);
                    //                                                 quantityController.clear();
                    //                                               } else if (value == '') {
                    //                                                 cartList[index].quantity = 1;
                    //                                               } else if (value == '0') {
                    //                                                 cartList[index].quantity = 1;
                    //                                               } else {
                    //                                                 cartList[index].quantity = value.toInt();
                    //                                               }
                    //                                             },
                    //                                             onFieldSubmitted: (value) {
                    //                                               if (value == '') {
                    //                                                 setState(() {
                    //                                                   cartList[index].quantity = 1;
                    //                                                 });
                    //                                               } else {
                    //                                                 setState(() {
                    //                                                   cartList[index].quantity = value.toInt();
                    //                                                 });
                    //                                               }
                    //                                             },
                    //                                             decoration: const InputDecoration(border: InputBorder.none),
                    //                                           ),
                    //                                         ),
                    //                                         const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor).onTap(() {
                    //                                           if (cartList[index].quantity < cartList[index].stock!.toInt()) {
                    //                                             setState(() {
                    //                                               cartList[index].quantity += 1;
                    //                                               toast(cartList[index].quantity.toString());
                    //                                             });
                    //                                           } else {
                    //                                             EasyLoading.showError(lang.S.of(context).outOfStock);
                    //                                           }
                    //                                         }),
                    //                                       ],
                    //                                     ),
                    //                                   ),
                    //                                 ),
                    //
                    //                                 ///______price___________________________________________________________
                    //                                 SizedBox(
                    //                                   width: 70,
                    //                                   child: TextFormField(
                    //                                     initialValue: cartList[index].subTotal,
                    //                                     onChanged: (value) {
                    //                                       if (value == '') {
                    //                                         setState(() {
                    //                                           cartList[index].subTotal = 0.toString();
                    //                                         });
                    //                                       } else if (double.tryParse(value) == null) {
                    //                                         EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                    //                                       } else {
                    //                                         setState(() {
                    //                                           cartList[index].subTotal = value;
                    //                                         });
                    //                                       }
                    //                                     },
                    //                                     onFieldSubmitted: (value) {
                    //                                       if (value == '') {
                    //                                         setState(() {
                    //                                           cartList[index].subTotal = 0.toString();
                    //                                         });
                    //                                       } else if (double.tryParse(value) == null) {
                    //                                         EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                    //                                       } else {
                    //                                         setState(() {
                    //                                           cartList[index].subTotal = value;
                    //                                         });
                    //                                       }
                    //                                     },
                    //                                     decoration: const InputDecoration(border: InputBorder.none),
                    //                                   ),
                    //                                 ),
                    //
                    //                                 ///___________subtotal____________________________________________________
                    //                                 SizedBox(
                    //                                   width: 100,
                    //                                   child: Text(
                    //                                     (double.parse(cartList[index].subTotal) * cartList[index].quantity).toString(),
                    //                                     style: kTextStyle.copyWith(color: kTitleColor),
                    //                                   ),
                    //                                 ),
                    //
                    //                                 ///_______________actions_________________________________________________
                    //                                 SizedBox(
                    //                                   width: 50,
                    //                                   child: const Icon(
                    //                                     Icons.close_sharp,
                    //                                     color: redColor,
                    //                                   ).onTap(() {
                    //                                     setState(() {
                    //                                       cartList.removeAt(index);
                    //                                     });
                    //                                   }),
                    //                                 ),
                    //                               ],
                    //                             ),
                    //                             Container(
                    //                               width: double.infinity,
                    //                               height: 1,
                    //                               color: kGreyTextColor.withOpacity(0.3),
                    //                             )
                    //                           ],
                    //                         );
                    //                       },
                    //                     )
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //             Padding(
                    //               padding: const EdgeInsets.all(10.0),
                    //               child: Column(
                    //                 crossAxisAlignment: CrossAxisAlignment.end,
                    //                 children: [
                    //                   ///__________total__________________________________________
                    //                   Row(
                    //                     mainAxisAlignment: MainAxisAlignment.start,
                    //                     children: [
                    //                       Text(
                    //                         '${lang.S.of(context).totalItem}: ${cartList.length}',
                    //                         style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                       ),
                    //                       const Spacer(),
                    //                       SizedBox(
                    //                         width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10,
                    //                         child: Padding(
                    //                           padding: const EdgeInsets.only(right: 20),
                    //                           child: Text(
                    //                             lang.S.of(context).subTotal,
                    //                             textAlign: TextAlign.end,
                    //                             style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                       SizedBox(
                    //                         width: 204,
                    //                         child: Container(
                    //                           padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 4.0, bottom: 4.0),
                    //                           decoration: const BoxDecoration(color: kGreenTextColor, borderRadius: BorderRadius.all(Radius.circular(8))),
                    //                           child: Center(
                    //                             child: Text(
                    //                               '$globalCurrency ${(getTotalAmount().toDouble() + serviceCharge - discountAmount + vatGst).toStringAsFixed(1)}',
                    //                               style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                    //                             ),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                   const SizedBox(height: 10.0),
                    //
                    //                   ///_________Taxes__________________________________________
                    //
                    //                   SizedBox(
                    //                     height: 50.00 * getAllTaxFromCartList(cart: cartList).length,
                    //                     width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10 + 204,
                    //                     child: ListView.builder(
                    //                       itemCount: getAllTaxFromCartList(cart: cartList).length,
                    //                       shrinkWrap: true,
                    //                       itemBuilder: (context, index) {
                    //                         return Container(
                    //                           height: 40,
                    //                           margin: const EdgeInsets.only(top: 5, bottom: 5),
                    //                           child: Row(
                    //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                             children: [
                    //                               SizedBox(
                    //                                 width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10,
                    //                                 child: Padding(
                    //                                   padding: const EdgeInsets.only(right: 20),
                    //                                   child: Text(
                    //                                     getAllTaxFromCartList(cart: cartList)[index].name,
                    //                                     textAlign: TextAlign.end,
                    //                                     style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                                   ),
                    //                                 ),
                    //                               ),
                    //                               SizedBox(
                    //                                 width: 204,
                    //                                 height: 40.0,
                    //                                 child: Center(
                    //                                   child: AppTextField(
                    //                                     initialValue: getAllTaxFromCartList(cart: cartList)[index].taxRate.toString(),
                    //                                     readOnly: true,
                    //                                     textAlign: TextAlign.right,
                    //                                     decoration: InputDecoration(
                    //                                       contentPadding: const EdgeInsets.only(right: 6.0),
                    //                                       hintText: '0',
                    //                                       border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                       enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                       disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                       focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                       prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                    //                                       prefixIcon: Container(
                    //                                         padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    //                                         height: 40,
                    //                                         decoration: const BoxDecoration(
                    //                                             color: Color(0xFFff5f00),
                    //                                             borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                    //                                         child: const Text(
                    //                                           '%',
                    //                                           style: TextStyle(fontSize: 20.0, color: Colors.white),
                    //                                         ),
                    //                                       ),
                    //                                     ),
                    //                                     textFieldType: TextFieldType.NUMBER,
                    //                                   ),
                    //                                 ),
                    //                               ),
                    //                             ],
                    //                           ),
                    //                         );
                    //                       },
                    //                     ),
                    //                   ),
                    //                   const SizedBox(height: 10.0),
                    //
                    //                   ///__________service/shipping_____________________________
                    //                   Row(
                    //                     mainAxisAlignment: MainAxisAlignment.end,
                    //                     children: [
                    //                       SizedBox(
                    //                         width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10,
                    //                         child: Padding(
                    //                           padding: const EdgeInsets.only(right: 20),
                    //                           child: Text(
                    //                             lang.S.of(context).shpingOrServices,
                    //                             textAlign: TextAlign.end,
                    //                             style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                       SizedBox(
                    //                         width: 204,
                    //                         height: 40,
                    //                         child: TextFormField(
                    //                           initialValue: serviceCharge.toString(),
                    //                           onChanged: (value) {
                    //                             setState(() {
                    //                               serviceCharge = value.toDouble();
                    //                             });
                    //                           },
                    //                           decoration: InputDecoration(border: OutlineInputBorder(), hintText: lang.S.of(context).enterAmount),
                    //                           textAlign: TextAlign.center,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                   const SizedBox(height: 10.0),
                    //
                    //                   ///___________vat____________________________________
                    //                   // Row(
                    //                   //   mainAxisAlignment: MainAxisAlignment.end,
                    //                   //   children: [
                    //                   //     SizedBox(
                    //                   //       width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10,
                    //                   //       child: Padding(
                    //                   //         padding: const EdgeInsets.only(right: 20),
                    //                   //         child: Text(
                    //                   //           lang.S.of(context).vatOrgst,
                    //                   //           textAlign: TextAlign.end,
                    //                   //           style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                   //         ),
                    //                   //       ),
                    //                   //     ),
                    //                   //     Row(
                    //                   //       children: [
                    //                   //         SizedBox(
                    //                   //           width: 100,
                    //                   //           height: 40.0,
                    //                   //           child: Center(
                    //                   //             child: AppTextField(
                    //                   //               controller: vatPercentageEditingController,
                    //                   //               onChanged: (value) {
                    //                   //                 if (value == '') {
                    //                   //                   setState(() {
                    //                   //                     vatGst = 0.0;
                    //                   //                     vatAmountEditingController.text = 0.toString();
                    //                   //                   });
                    //                   //                 } else {
                    //                   //                   setState(() {
                    //                   //                     vatGst = double.parse(((value.toDouble() / 100) * getTotalAmount().toDouble()).toStringAsFixed(1));
                    //                   //                     vatAmountEditingController.text = vatGst.toString();
                    //                   //                   });
                    //                   //                 }
                    //                   //               },
                    //                   //               textAlign: TextAlign.right,
                    //                   //               decoration: InputDecoration(
                    //                   //                 contentPadding: const EdgeInsets.only(right: 6.0),
                    //                   //                 hintText: '0',
                    //                   //                 border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                    //                   //                 enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                    //                   //                 disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                    //                   //                 focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kTitleColor)),
                    //                   //                 prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                    //                   //                 prefixIcon: Container(
                    //                   //                   padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    //                   //                   height: 40,
                    //                   //                   decoration: const BoxDecoration(
                    //                   //                       color: kTitleColor,
                    //                   //                       borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                    //                   //                   child: const Text(
                    //                   //                     '%',
                    //                   //                     style: TextStyle(fontSize: 20.0, color: Colors.white),
                    //                   //                   ),
                    //                   //                 ),
                    //                   //               ),
                    //                   //               textFieldType: TextFieldType.PHONE,
                    //                   //             ),
                    //                   //           ),
                    //                   //         ),
                    //                   //         const SizedBox(
                    //                   //           width: 4.0,
                    //                   //         ),
                    //                   //         SizedBox(
                    //                   //           width: 100,
                    //                   //           height: 40.0,
                    //                   //           child: Center(
                    //                   //             child: AppTextField(
                    //                   //               controller: vatAmountEditingController,
                    //                   //               onChanged: (value) {
                    //                   //                 if (value == '') {
                    //                   //                   setState(() {
                    //                   //                     vatGst = 0;
                    //                   //                     vatPercentageEditingController.text = 0.toString();
                    //                   //                   });
                    //                   //                 } else {
                    //                   //                   setState(() {
                    //                   //                     vatGst = double.parse(value);
                    //                   //                     vatPercentageEditingController.text = ((vatGst * 100) / getTotalAmount().toDouble()).toStringAsFixed(1);
                    //                   //                   });
                    //                   //                 }
                    //                   //               },
                    //                   //               textAlign: TextAlign.right,
                    //                   //               decoration: InputDecoration(
                    //                   //                 contentPadding: const EdgeInsets.only(right: 6.0),
                    //                   //                 hintText: '0',
                    //                   //                 border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                   //                 enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                   //                 disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                   //                 focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                   //                 prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                    //                   //                 prefixIcon: Container(
                    //                   //                   padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    //                   //                   height: 40,
                    //                   //                   decoration: const BoxDecoration(
                    //                   //                       color: kMainColor,
                    //                   //                       borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                    //                   //                   child: Text(
                    //                   //                     currency,
                    //                   //                     style: TextStyle(fontSize: 20.0, color: Colors.white),
                    //                   //                   ),
                    //                   //                 ),
                    //                   //               ),
                    //                   //               textFieldType: TextFieldType.PHONE,
                    //                   //             ),
                    //                   //           ),
                    //                   //         ),
                    //                   //       ],
                    //                   //     ),
                    //                   //   ],
                    //                   // ),
                    //                   // const SizedBox(height: 10.0),
                    //
                    //                   ///________discount_________________________________________________
                    //                   Row(
                    //                     mainAxisAlignment: MainAxisAlignment.end,
                    //                     children: [
                    //                       SizedBox(
                    //                         width: context.width() < 1080 ? 1080 * .10 : MediaQuery.of(context).size.width * .10,
                    //                         child: Padding(
                    //                           padding: const EdgeInsets.only(right: 20),
                    //                           child: Text(
                    //                             lang.S.of(context).discount,
                    //                             textAlign: TextAlign.end,
                    //                             style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                       Row(
                    //                         children: [
                    //                           SizedBox(
                    //                             width: 100,
                    //                             height: 40.0,
                    //                             child: Center(
                    //                               child: AppTextField(
                    //                                 controller: discountPercentageEditingController,
                    //                                 onChanged: (value) {
                    //                                   if (value == '') {
                    //                                     setState(() {
                    //                                       discountAmountEditingController.text = 0.toString();
                    //                                     });
                    //                                   } else {
                    //                                     if (value.toInt() <= 100) {
                    //                                       setState(() {
                    //                                         discountAmount = double.parse(((value.toDouble() / 100) * getTotalAmount().toDouble()).toStringAsFixed(1));
                    //                                         discountAmountEditingController.text = discountAmount.toString();
                    //                                       });
                    //                                     } else {
                    //                                       setState(() {
                    //                                         discountAmount = 0;
                    //                                         discountAmountEditingController.clear();
                    //                                         discountPercentageEditingController.clear();
                    //                                       });
                    //                                       EasyLoading.showError(lang.S.of(context).enterAValidDiscount);
                    //                                     }
                    //                                   }
                    //                                 },
                    //                                 textAlign: TextAlign.right,
                    //                                 decoration: InputDecoration(
                    //                                   contentPadding: const EdgeInsets.only(right: 6.0),
                    //                                   hintText: '0',
                    //                                   border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                   enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                   disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                   focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xFFff5f00))),
                    //                                   prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                    //                                   prefixIcon: Container(
                    //                                     padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    //                                     height: 40,
                    //                                     decoration: const BoxDecoration(
                    //                                         color: Color(0xFFff5f00),
                    //                                         borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                    //                                     child: const Text(
                    //                                       '%',
                    //                                       style: TextStyle(fontSize: 20.0, color: Colors.white),
                    //                                     ),
                    //                                   ),
                    //                                 ),
                    //                                 textFieldType: TextFieldType.PHONE,
                    //                               ),
                    //                             ),
                    //                           ),
                    //                           const SizedBox(
                    //                             width: 4.0,
                    //                           ),
                    //                           SizedBox(
                    //                             width: 100,
                    //                             height: 40.0,
                    //                             child: Center(
                    //                               child: AppTextField(
                    //                                 controller: discountAmountEditingController,
                    //                                 onChanged: (value) {
                    //                                   if (value == '') {
                    //                                     setState(() {
                    //                                       discountAmount = 0;
                    //                                       discountPercentageEditingController.text = 0.toString();
                    //                                     });
                    //                                   } else {
                    //                                     if (value.toInt() <= getTotalAmount().toDouble()) {
                    //                                       setState(
                    //                                         () {
                    //                                           discountAmount = double.parse(value);
                    //                                           discountPercentageEditingController.text = ((discountAmount * 100) / getTotalAmount().toDouble()).toStringAsFixed(1);
                    //                                         },
                    //                                       );
                    //                                     } else {
                    //                                       setState(
                    //                                         () {
                    //                                           discountAmount = 0;
                    //                                           discountPercentageEditingController.clear();
                    //                                           discountAmountEditingController.clear();
                    //                                         },
                    //                                       );
                    //                                       EasyLoading.showError(lang.S.of(context).enterAValidDiscount);
                    //                                     }
                    //                                   }
                    //                                 },
                    //                                 textAlign: TextAlign.right,
                    //                                 decoration: InputDecoration(
                    //                                   contentPadding: const EdgeInsets.only(right: 6.0),
                    //                                   hintText: '0',
                    //                                   border: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                                   enabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                                   disabledBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                                   focusedBorder: const OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: kMainColor)),
                    //                                   prefixIconConstraints: const BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                    //                                   prefixIcon: Container(
                    //                                     padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    //                                     height: 40,
                    //                                     decoration: const BoxDecoration(
                    //                                         color: kMainColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), bottomLeft: Radius.circular(4.0))),
                    //                                     child: Text(
                    //                                       currency,
                    //                                       style: const TextStyle(fontSize: 20.0, color: Colors.white),
                    //                                     ),
                    //                                   ),
                    //                                 ),
                    //                                 textFieldType: TextFieldType.PHONE,
                    //                               ),
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ],
                    //                   ),
                    //                   const SizedBox(height: 10.0),
                    //
                    //                   ///__________buttons______________________________________
                    //                   const SizedBox(height: 20.0),
                    //
                    //                   Row(
                    //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //                     children: [
                    //                       Expanded(
                    //                         flex: 1,
                    //                         child: Container(
                    //                           padding: const EdgeInsets.all(10.0),
                    //                           decoration: BoxDecoration(
                    //                             shape: BoxShape.rectangle,
                    //                             borderRadius: BorderRadius.circular(10.0),
                    //                             color: kRedTextColor,
                    //                           ),
                    //                           child: Text(
                    //                             lang.S.of(context).cancel,
                    //                             textAlign: TextAlign.center,
                    //                             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                    //                           ),
                    //                         ).onTap(() {
                    //                           GoRouter.of(context).pop(widget.popUpContext);
                    //                           // Navigator.pop(widget.popUpContext);
                    //                         }),
                    //                       ),
                    //                       const SizedBox(width: 20.0),
                    //                       Expanded(
                    //                         flex: 1,
                    //                         child: Container(
                    //                           padding: const EdgeInsets.all(10.0),
                    //                           decoration: BoxDecoration(
                    //                             shape: BoxShape.rectangle,
                    //                             borderRadius: BorderRadius.circular(10.0),
                    //                             color: kBlueTextColor,
                    //                           ),
                    //                           child: Text(
                    //                             lang.S.of(context).payment,
                    //                             textAlign: TextAlign.center,
                    //                             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                    //                           ),
                    //                         ).onTap(
                    //                           () {
                    //                             if (cartList.isEmpty) {
                    //                               EasyLoading.showError(lang.S.of(context).pleaseAddSomeProductFirst);
                    //                             } else {
                    //                               SaleTransactionModel transitionModel = SaleTransactionModel(
                    //                                 dueAmount: widget.transitionModel.dueAmount,
                    //                                 customerAddress: widget.transitionModel.customerAddress,
                    //                                 customerImage: widget.transitionModel.customerImage,
                    //                                 customerGst: widget.transitionModel.customerGst,
                    //                                 customerName: widget.transitionModel.customerName,
                    //                                 customerType: widget.transitionModel.customerType,
                    //                                 customerPhone: widget.transitionModel.customerPhone,
                    //                                 invoiceNumber: widget.transitionModel.invoiceNumber,
                    //                                 purchaseDate: widget.transitionModel.purchaseDate,
                    //                                 productList: cartList,
                    //                                 discountAmount: discountAmount,
                    //                                 serviceCharge: serviceCharge,
                    //                                 vat: vatGst,
                    //                                 totalAmount: getTotalAmount().toDouble() + vatGst + serviceCharge - discountAmount,
                    //                               );
                    //                               ShowEditPaymentPopUp(
                    //                                 newTransitionModel: transitionModel,
                    //                                 oldTransitionModel: widget.transitionModel,
                    //                                 previousPaid: widget.transitionModel.totalAmount! - widget.transitionModel.dueAmount!.toDouble(),
                    //                                 decreaseStockList: decreaseStockList,
                    //                                 pastProducts: pastProducts,
                    //                                 saleListPopUpContext: widget.popUpContext,
                    //                               ).launch(context);
                    //                             }
                    //                           },
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 10.0),
                    //
                    //     ///_________selected_category_____________________________________
                    //     Consumer(
                    //       builder: (_, ref, watch) {
                    //         AsyncValue<List<CategoryModel>> categoryList = ref.watch(categoryProvider);
                    //         return categoryList.when(data: (category) {
                    //           return Container(
                    //             width: 150,
                    //             height: context.height() < 720 ? 720 - 142 : context.height() - 142,
                    //             padding: const EdgeInsets.all(8.0),
                    //             decoration: BoxDecoration(
                    //                 color: kWhite, border: Border.all(width: 1, color: kGreyTextColor.withOpacity(0.3)), borderRadius: const BorderRadius.all(Radius.circular(15))),
                    //             child: SingleChildScrollView(
                    //               child: Column(
                    //                 children: [
                    //                   GestureDetector(
                    //                     child: Container(
                    //                       decoration: BoxDecoration(
                    //                           borderRadius: BorderRadius.circular(5.0), color: isSelected == 'Categories' ? kBlueTextColor : kBlueTextColor.withOpacity(0.1)),
                    //                       height: 35,
                    //                       width: 150,
                    //                       padding: const EdgeInsets.only(left: 15, right: 8),
                    //                       alignment: Alignment.centerLeft,
                    //                       child: Row(
                    //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                         children: [
                    //                           Text(
                    //                             lang.S.of(context).categories,
                    //                             textAlign: TextAlign.start,
                    //                             style: kTextStyle.copyWith(color: isSelected == 'Categories' ? Colors.white : kDarkGreyColor, fontWeight: FontWeight.bold),
                    //                           ),
                    //                           Icon(
                    //                             Icons.keyboard_arrow_right,
                    //                             color: isSelected == 'Categories' ? Colors.white : kDarkGreyColor,
                    //                             size: 16,
                    //                           )
                    //                         ],
                    //                       ),
                    //                     ),
                    //                     onTap: () {
                    //                       setState(() {
                    //                         selectedCategory = 'Categories';
                    //                         isSelected = "Categories";
                    //                       });
                    //                     },
                    //                   ),
                    //                   const SizedBox(height: 10.0),
                    //                   ListView.builder(
                    //                     itemCount: category.length,
                    //                     shrinkWrap: true,
                    //                     physics: const NeverScrollableScrollPhysics(),
                    //                     itemBuilder: (_, i) {
                    //                       return GestureDetector(
                    //                         onTap: (() {
                    //                           setState(() {
                    //                             isSelected = category[i].categoryName;
                    //                             selectedCategory = category[i].categoryName;
                    //                           });
                    //                         }),
                    //                         child: Padding(
                    //                           padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    //                           child: Container(
                    //                             padding: const EdgeInsets.only(left: 15.0, right: 8.0, top: 8.0, bottom: 8.0),
                    //                             decoration: BoxDecoration(
                    //                                 borderRadius: BorderRadius.circular(5.0),
                    //                                 color: isSelected == category[i].categoryName ? kBlueTextColor : kBlueTextColor.withOpacity(0.1)),
                    //                             child: Row(
                    //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                               children: [
                    //                                 Text(
                    //                                   category[i].categoryName,
                    //                                   style: kTextStyle.copyWith(
                    //                                       color: isSelected == category[i].categoryName ? Colors.white : kDarkGreyColor, fontWeight: FontWeight.bold),
                    //                                 ),
                    //                                 Icon(
                    //                                   Icons.keyboard_arrow_right,
                    //                                   color: isSelected == category[i].categoryName ? Colors.white : kDarkGreyColor,
                    //                                   size: 16,
                    //                                 )
                    //                               ],
                    //                             ),
                    //                           ),
                    //                         ),
                    //                       );
                    //                     },
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           );
                    //         }, error: (e, stack) {
                    //           return Center(
                    //             child: Text(e.toString()),
                    //           );
                    //         }, loading: () {
                    //           return const Center(
                    //             child: CircularProgressIndicator(),
                    //           );
                    //         });
                    //       },
                    //     ),
                    //     const SizedBox(width: 10.0),
                    //
                    //     ///________product_List___________________________________________
                    //     productList.when(
                    //       data: (products) {
                    //         List<ProductModel> showProductVsCategory = [];
                    //         if (selectedCategory == 'Categories') {
                    //           for (var element in products) {
                    //             if (element.productCode.toLowerCase().contains(searchProductCode) ||
                    //                 element.productCategory.toLowerCase().contains(searchProductCode) ||
                    //                 element.productName.toLowerCase().contains(searchProductCode)) {
                    //               productPriceChecker(product: element, customerType: widget.transitionModel.customerType) != '0' && (selectedWareHouse?.id == element.warehouseId)
                    //                   ? showProductVsCategory.add(element)
                    //                   : null;
                    //             }
                    //           }
                    //         } else {
                    //           for (var element in products) {
                    //             if (element.productCategory == selectedCategory) {
                    //               productPriceChecker(product: element, customerType: widget.transitionModel.customerType) != '0' && (selectedWareHouse?.id == element.warehouseId)
                    //                   ? showProductVsCategory.add(element)
                    //                   : null;
                    //             }
                    //           }
                    //         }
                    //
                    //         return showProductVsCategory.isNotEmpty
                    //             ? Expanded(
                    //                 flex: 4,
                    //                 child: SizedBox(
                    //                   height: context.height() < 720 ? 720 - 136 : context.height() - 136,
                    //                   child: Container(
                    //                     decoration: const BoxDecoration(
                    //                       color: kDarkWhite,
                    //                     ),
                    //                     child: GridView.builder(
                    //                       gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    //                         maxCrossAxisExtent: 180,
                    //                         mainAxisExtent: 200,
                    //                         mainAxisSpacing: 10,
                    //                         crossAxisSpacing: 10,
                    //                       ),
                    //                       itemCount: showProductVsCategory.length,
                    //                       itemBuilder: (_, i) {
                    //                         return Container(
                    //                           width: 130.0,
                    //                           height: 170.0,
                    //                           decoration: BoxDecoration(
                    //                             borderRadius: BorderRadius.circular(10.0),
                    //                             color: kWhite,
                    //                             border: Border.all(
                    //                               color: kLitGreyColor,
                    //                             ),
                    //                           ),
                    //                           child: Column(
                    //                             crossAxisAlignment: CrossAxisAlignment.start,
                    //                             children: [
                    //                               ///__________image________________________________________________
                    //                               Stack(
                    //                                 alignment: Alignment.topLeft,
                    //                                 children: [
                    //                                   Container(
                    //                                     height: 120,
                    //                                     decoration: BoxDecoration(
                    //                                       borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
                    //                                       image: DecorationImage(image: NetworkImage(showProductVsCategory[i].productPicture), fit: BoxFit.cover),
                    //                                     ),
                    //                                   ),
                    //                                   Positioned(
                    //                                     left: 5,
                    //                                     top: 5,
                    //                                     child: Container(
                    //                                       padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                    //                                       decoration: BoxDecoration(color: showProductVsCategory[i].productStock == '0' ? kRedTextColor : kGreenTextColor),
                    //                                       child: Text(
                    //                                         showProductVsCategory[i].productStock != '0'
                    //                                             ? '${showProductVsCategory[i].productStock} pc'
                    //                                             : lang.S.of(context).outOfStock,
                    //                                         style: kTextStyle.copyWith(color: kWhite),
                    //                                       ),
                    //                                     ),
                    //                                   ),
                    //                                 ],
                    //                               ),
                    //
                    //                               Padding(
                    //                                 padding: const EdgeInsets.only(top: 10.0, left: 5, right: 3),
                    //                                 child: Column(
                    //                                   crossAxisAlignment: CrossAxisAlignment.start,
                    //                                   children: [
                    //                                     ///______name_______________________________________________
                    //                                     Text(
                    //                                       showProductVsCategory[i].productName,
                    //                                       maxLines: 2,
                    //                                       overflow: TextOverflow.ellipsis,
                    //                                       style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                    //                                     ),
                    //                                     const SizedBox(height: 4.0),
                    //
                    //                                     ///________Purchase_price______________________________________________________
                    //                                     Container(
                    //                                       padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                    //                                       decoration: BoxDecoration(
                    //                                         color: kGreenTextColor,
                    //                                         borderRadius: BorderRadius.circular(2.0),
                    //                                       ),
                    //                                       child: Text(
                    //                                         productPriceChecker(product: showProductVsCategory[i], customerType: widget.transitionModel.customerType),
                    //                                         style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold, fontSize: 14.0),
                    //                                       ),
                    //                                     ),
                    //                                   ],
                    //                                 ),
                    //                               ),
                    //                             ],
                    //                           ),
                    //                         ).onTap(() {
                    //                           if (showProductVsCategory[i].serialNumber.isNotEmpty) {
                    //                             showSerialNumberPopUp(productModel: showProductVsCategory[i]);
                    //                           } else {
                    //                             setState(
                    //                               () {
                    //                                 AddToCartModel addToCartModel = AddToCartModel(
                    //                                   productName: showProductVsCategory[i].productName,
                    //                                   warehouseName: showProductVsCategory[i].warehouseName,
                    //                                   warehouseId: showProductVsCategory[i].warehouseId,
                    //                                   productImage: showProductVsCategory[i].productPicture,
                    //                                   productId: showProductVsCategory[i].productCode,
                    //                                   productPurchasePrice: showProductVsCategory[i].productPurchasePrice,
                    //                                   subTotal: productPriceChecker(product: showProductVsCategory[i], customerType: widget.transitionModel.customerType),
                    //                                   serialNumber: [],
                    //                                   unitPrice: productPriceChecker(product: showProductVsCategory[i], customerType: widget.transitionModel.customerType),
                    //                                   subTaxes: showProductVsCategory[i].subTaxes,
                    //                                   excTax: showProductVsCategory[i].excTax,
                    //                                   groupTaxName: showProductVsCategory[i].groupTaxName,
                    //                                   groupTaxRate: showProductVsCategory[i].groupTaxRate,
                    //                                   incTax: showProductVsCategory[i].incTax,
                    //                                   margin: showProductVsCategory[i].margin,
                    //                                   taxType: showProductVsCategory[i].taxType,
                    //                                 );
                    //
                    //                                 if (!uniqueCheck(showProductVsCategory[i].productCode)) {
                    //                                   if (showProductVsCategory[i].productStock == '0') {
                    //                                     EasyLoading.showError(lang.S.of(context).productOutOfStock);
                    //                                   } else {
                    //                                     cartList.add(addToCartModel);
                    //                                   }
                    //                                 } else {}
                    //                               },
                    //                             );
                    //                           }
                    //                         });
                    //                       },
                    //                     ),
                    //                   ),
                    //                 ),
                    //               )
                    //             : Expanded(
                    //                 flex: 4,
                    //                 child: Container(
                    //                   height: context.height() < 720 ? 720 - 136 : context.height() - 136,
                    //                   color: Colors.white,
                    //                   child: Column(
                    //                     mainAxisSize: MainAxisSize.min,
                    //                     children: [
                    //                       const SizedBox(height: 80),
                    //                       const Image(
                    //                         image: AssetImage('images/empty_screen.png'),
                    //                       ),
                    //                       const SizedBox(height: 20),
                    //                       GestureDetector(
                    //                         onTap: () {},
                    //                         child: Container(
                    //                           decoration: const BoxDecoration(color: kBlueTextColor, borderRadius: BorderRadius.all(Radius.circular(15))),
                    //                           width: 200,
                    //                           child: Center(
                    //                             child: Padding(
                    //                               padding: const EdgeInsets.all(20.0),
                    //                               child: Text(
                    //                                 lang.S.of(context).addProduct,
                    //                                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
                    //                               ),
                    //                             ),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //               );
                    //       },
                    //       error: (e, stack) {
                    //         return Center(
                    //           child: Text(e.toString()),
                    //         );
                    //       },
                    //       loading: () {
                    //         return const Center(
                    //           child: CircularProgressIndicator(),
                    //         );
                    //       },
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(
                    //   height: 10.0,
                    // ),
                  ],
                ),
              ));
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
}
