import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../Repository/product_repo.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/customer_model.dart';
import '../../model/product_model.dart';
import '../../model/sale_transaction_model.dart';
import '../../subscription.dart';
import '../Product/WarebasedProduct.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Calculator/calculator.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Pop UP/Pos Sale/add_item_popup.dart';
import '../Widgets/Pop UP/Pos Sale/due_sale_popup.dart';
import '../Widgets/Pop UP/Pos Sale/sale_list_popup.dart';
import '../currency/currency_provider.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key, this.quotation});

  static const String route = '/quotation';
  final SaleTransactionModel? quotation;

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  String searchItem = '';
  ScrollController mainScroll = ScrollController();
  List<AddToCartModel> cartList = [];

  List<FocusNode> productFocusNode = [];

  updateDueAmount() {
    setState(() {
      double total = double.parse((getTotalAmount().toDouble() +
              serviceCharge -
              discountAmount +
              vatGst)
          .toStringAsFixed(1));
      double paidAmount = double.tryParse(payingAmountController.text) ?? 0;
      if (paidAmount > total) {
        changeAmountController.text = (paidAmount - total).toString();
        dueAmountController.text = '0';
      } else {
        dueAmountController.text = (total - paidAmount).abs().toString();
        changeAmountController.text = '0';
      }
    });
  }

  bool saleButtonClicked = false;

  Future<void> getPro() async {
    return;
  }

  List<String> get paymentItem => [
        //'Cash',
        lang.S.current.cash,
        //'Bank',
        lang.S.current.bank,
        //'Mobile Pay',
        lang.S.current.mobilePay
      ];
  late String selectedPaymentOption = paymentItem.first;

  late StreamSubscription subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;

  showDialogBox() => showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(lang.S.of(context).noConnection),
          content: Text(lang.S.of(context).pleaseCheckYourInternetConnectivity),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.pop(context, lang.S.of(context).cancel);
                setState(() => isAlertSet = false);
                isDeviceConnected =
                    await InternetConnection().hasInternetAccess;
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

  void deleteQuotation(
      {required String date, required WidgetRef updateRef}) async {
    String key = '';
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Sales Quotation')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['invoiceNumber'].toString() == date) {
          key = element.key.toString();
        }
      }
    });
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("${await getUserID()}/Sales Quotation/$key");
    await ref.remove();
    final _ = updateRef.refresh(quotationProvider);
  }

  DropdownButton<String> getOption() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentItem) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedPaymentOption,
      onChanged: (value) {
        setState(() {
          selectedPaymentOption = value!;
        });
      },
    );
  }

  double dueAmount = 0.0;

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();

  String searchProductCode = '';

  String isSelected = 'Categories';
  String selectedCategory = 'Categories';
  String? selectedUserId;
  CustomerModel? selectedUserName;
  String? invoiceNumber;
  String previousDue = "0";
  FocusNode nameFocus = FocusNode();

  DropdownButton<String> getResult(List<CustomerModel> model) {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (var des in model) {
      var item = DropdownMenuItem(
        alignment: Alignment.centerLeft,
        value: des.phoneNumber,
        child: Text(
          '${des.customerName} ${des.phoneNumber}',
          softWrap: true,
          style: kTextStyle.copyWith(
              color: kTitleColor, overflow: TextOverflow.ellipsis),
          textAlign: TextAlign.left,
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      padding: const EdgeInsets.only(left: 10.0),
      alignment: Alignment.centerLeft,
      items: dropDownItems,
      value: selectedUserId,
      onChanged: (value) {
        setState(() {
          selectedUserId = value!;
          for (var element in model) {
            if (element.phoneNumber == selectedUserId) {
              selectedUserName = element;
              previousDue = element.dueAmount;
              selectedCustomerType == element.type
                  ? null
                  : {
                      selectedCustomerType = element.type,
                      cartList.clear(),
                      productFocusNode.clear()
                    };
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

  dynamic productPriceChecker(
      {required ProductModel product, required String customerType}) {
    if (customerType == "Retailer") {
      return product.productSalePrice;
    } else if (customerType == "Wholesaler") {
      return product.productWholeSalePrice == ''
          ? '0'
          : product.productWholeSalePrice;
    } else if (customerType == "Dealer") {
      return product.productDealerPrice == ''
          ? '0'
          : product.productDealerPrice;
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
        if (item.quantity < item.stock!.toInt()) {
          item.quantity += 1;
        } else {
          EasyLoading.showError(lang.S.of(context).outOfStock);
        }

        isUnique = true;
        break;
      }
    }
    return isUnique;
  }

  bool uniqueCheckForSerial(
      {required String code, required List<dynamic> newSerialNumbers}) {
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

  List<String> get customerType => [
        lang.S.current.retailer,
        //'Retailer',
        lang.S.current.wholesaler,
        //'Wholesaler',
        lang.S.current.dealer,
        //'Dealer',
      ];

  late String selectedCustomerType = customerType.first;

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in customerType) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(
              color: kTitleColor, overflow: TextOverflow.ellipsis),
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

  void showDueListPopUp() {
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

  void showSaleListPopUp() {
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

  void showAddItemPopUp() {
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

  void showHoldPopUp() {
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
                      padding: const EdgeInsets.only(
                          top: 10.0, left: 10.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            lang.S.of(context).hold,
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
                        children: [
                          AppTextField(
                            showCursor: true,
                            cursorColor: kTitleColor,
                            textFieldType: TextFieldType.NAME,
                            decoration: kInputDecoration.copyWith(
                              labelText: lang.S.of(context).holdNumber,
                              hintText: '2090.00',
                              hintStyle:
                                  kTextStyle.copyWith(color: kGreyTextColor),
                              labelStyle:
                                  kTextStyle.copyWith(color: kTitleColor),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
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
                                  )).onTap(() => {finish(context)}),
                              const SizedBox(width: 10.0),
                              Container(
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

  double serviceCharge = 0;
  double discountAmount = 0;

  TextEditingController discountAmountEditingController =
      TextEditingController();

  // TextEditingController vatAmountEditingController = TextEditingController();
  TextEditingController discountPercentageEditingController =
      TextEditingController();

  // TextEditingController vatPercentageEditingController = TextEditingController();
  double vatGst = 0;

  addFocus() {
    FocusNode f = FocusNode();
    f.addListener(
      () {
        if (!f.hasFocus) {
          updateDueAmount();
        }
      },
    );
    productFocusNode.add(f);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    // getConnectivity();
    payingAmountController.text = '0';
    checkInternet();
    updateDueAmount();

    if (widget.quotation != null) {
      for (var element in widget.quotation!.productList!) {
        cartList.add(element);
        addFocus();
      }
      discountAmountEditingController.text =
          widget.quotation!.discountAmount!.toStringAsFixed(2);
      discountAmount = widget.quotation!.discountAmount!;
      serviceCharge = widget.quotation!.discountAmount!;
      selectedUserName?.customerName = widget.quotation!.customerName;
      selectedUserName?.phoneNumber = widget.quotation!.customerPhone;
      selectedUserName?.type = widget.quotation!.customerType;
    }
  }

  checkInternet() async {
    isDeviceConnected = await InternetConnection().hasInternetAccess;
    if (!isDeviceConnected) {
      showDialogBox();
      setState(() => isAlertSet = true);
    }
  }

  void showSerialNumberPopUp({required ProductModel productModel}) {
    AddToCartModel productInCart = AddToCartModel(
      productPurchasePrice: 0,
      serialNumber: [],
      productImage: '',
      warehouseName: '',
      warehouseId: '',
      taxType: '',
      margin: 0,
      incTax: 0,
      groupTaxRate: 0,
      groupTaxName: '',
      excTax: 0,
      subTaxes: [],
    );
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
                              Container(
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
                                  )).onTap(() {
                                Navigator.pop(context);
                              }),
                              const SizedBox(width: 10.0),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    AddToCartModel addToCartModel =
                                        AddToCartModel(
                                            productName:
                                                productModel.productName,
                                            warehouseName:
                                                productModel.warehouseName,
                                            warehouseId:
                                                productModel.warehouseId,
                                            productId: productModel.productCode,
                                            productImage:
                                                productModel.productPicture,
                                            productPurchasePrice: productModel
                                                .productPurchasePrice
                                                .toDouble(),
                                            subTotal: productPriceChecker(
                                                product: productModel,
                                                customerType:
                                                    selectedCustomerType),
                                            serialNumber: selectedSerialNumbers,
                                            quantity: selectedSerialNumbers
                                                    .isEmpty
                                                ? 1
                                                : selectedSerialNumbers.length,
                                            stock: productModel.productStock
                                                .toInt(),
                                            productWarranty:
                                                productModel.warranty,
                                            taxType: productModel.taxType,
                                            margin: productModel.margin,
                                            incTax: productModel.incTax,
                                            groupTaxRate:
                                                productModel.groupTaxRate,
                                            groupTaxName:
                                                productModel.groupTaxName,
                                            excTax: productModel.excTax,
                                            subTaxes: productModel.subTaxes);
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
                                        addFocus();
                                      }
                                    }
                                  });
                                  Navigator.pop(context);
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

  void showSaleListInvoicePopUp() {
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

  final horizontalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    List<String> allProductsNameList = [];
    List<String> allProductsCodeList = [];
    List<String> warehouseIdList = [];
    List<WarehouseBasedProductModel> warehouseBasedProductModel = [];
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (context, consumerRef, __) {
          final wareHouseList = consumerRef.watch(warehouseProvider);
          final customerList = consumerRef.watch(allCustomerProvider);
          final personalData = consumerRef.watch(profileDetailsProvider);
          AsyncValue<List<ProductModel>> productList =
              consumerRef.watch(productProvider);
          return personalData.when(data: (data) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_______________________________top_bar____________________________
                  Container(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: kWhite),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 12),
                          child: Text(
                            "Quotation",
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        const Divider(
                          thickness: 1.0,
                          color: kNeutral300,
                        ),
                        //----------header section---------------------------------
                        ResponsiveGridRow(rowSegments: 120, children: [
                          //--------------------------date------------------
                          ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 30,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextFormField(
                                  readOnly: true,
                                  onTap: () {
                                    _selectedDueDate(context);
                                  },
                                  decoration: bInputDecoration.copyWith(
                                      hintText:
                                          '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                      hintStyle: bTextStyle.copyWith(),
                                      contentPadding:
                                          const EdgeInsets.only(left: 8.0),
                                      suffixIcon: const Icon(
                                        Icons.calendar_month,
                                        color: kGreyTextColor,
                                      )),
                                ),
                              )),
                          //--------------------due fields-------------------
                          ResponsiveGridCol(
                            xs: 120,
                            md: 60,
                            lg: 30,
                            child: customerList.when(data: (allCustomers) {
                              List<String> listOfPhoneNumber = [];
                              List<CustomerModel> customersList = [];
                              for (var value1 in allCustomers) {
                                // listOfPhoneNumber.add(value1.phoneNumber.removeAllWhiteSpace().toLowerCase());
                                listOfPhoneNumber.add(value1.phoneNumber
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                if (value1.type != 'Supplier') {
                                  customersList.add(value1);
                                }
                              }
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: SizedBox(
                                  height: 48.0,
                                  child: FormField(
                                    builder: (FormFieldState<dynamic> field) {
                                      return InputDecorator(
                                        decoration: InputDecoration(
                                          label: RichText(
                                            text: TextSpan(
                                              text: lang.S.of(context).party,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(color: Colors.red),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        '(${lang.S.of(context).previousDue} '),
                                                TextSpan(
                                                    text:
                                                        '$globalCurrency${myFormat.format(double.tryParse(previousDue) ?? 0)} )')
                                              ],
                                            ),
                                          ),
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              context.push(
                                                '/add-customer',
                                                extra: {
                                                  'typeOfCustomerAdd': 'Buyer',
                                                  'listOfPhoneNumber':
                                                      listOfPhoneNumber,
                                                },
                                              );
                                            },
                                            child: Container(
                                              height: 48,
                                              width: 48,
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(5),
                                                    bottomRight:
                                                        Radius.circular(5)),
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
                                          ),
                                          enabledBorder:
                                              const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(8.0)),
                                            borderSide: BorderSide(
                                                color: kBorderColorTextField,
                                                width: 1),
                                          ),
                                          contentPadding: const EdgeInsets.only(
                                              left: 7.0, right: 7.0),
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.always,
                                        ),
                                        child: widget.quotation != null
                                            ? Text(
                                                widget.quotation!.customerName)
                                            : Theme(
                                                data: ThemeData(
                                                    highlightColor:
                                                        dropdownItemColor,
                                                    focusColor:
                                                        dropdownItemColor,
                                                    hoverColor:
                                                        dropdownItemColor),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                        child: getResult(
                                                            customersList))),
                                      );
                                    },
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
                          //----------------------invoice--------------------
                          ResponsiveGridCol(
                              xs: 40,
                              md: 40,
                              lg: 30,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                      labelText: lang.S.of(context).invoice,
                                      hintText: widget.quotation == null
                                          ? data.saleInvoiceCounter.toString()
                                          : widget.quotation!.invoiceNumber,
                                      contentPadding:
                                          const EdgeInsets.only(left: 10.0)),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                          //----------------warehouse--------------------
                          ResponsiveGridCol(
                              xs: 80,
                              md: 80,
                              lg: 30,
                              child: wareHouseList.when(
                                data: (warehouse) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 48.0,
                                      child: FormField(
                                        builder:
                                            (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText:
                                                  lang.S.of(context).warehouse,
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: getWare(
                                                list: warehouse,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                  // return Container(
                                  //   height: 48,
                                  //   padding: const EdgeInsets.all(10),
                                  //   decoration: BoxDecoration(
                                  //       border: Border.all(
                                  //         color: kOutlineColor,
                                  //       ),
                                  //       borderRadius: BorderRadius.circular(6.0)),
                                  //   child: Theme(
                                  //     data: ThemeData(highlightColor: dropdownItemColor, focusColor: Colors.transparent, hoverColor: dropdownItemColor),
                                  //     child: DropdownButtonHideUnderline(
                                  //       child: getWare(list: warehouse ?? []),
                                  //     ),
                                  //   ),
                                  // );
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
                              )),
                          //----------------product------------------------
                          ResponsiveGridCol(
                            xs: 120,
                            md: 120,
                            lg: 120,
                            child: productList.when(data: (product) {
                              for (var element in product) {
                                // allProductsNameList.add(element.productName.removeAllWhiteSpace().toLowerCase());
                                // allProductsCodeList.add(element.productCode.removeAllWhiteSpace().toLowerCase());
                                // warehouseIdList.add(element.warehouseId.removeAllWhiteSpace().toLowerCase());
                                allProductsNameList.add(element.productName
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                allProductsCodeList.add(element.productCode
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                warehouseIdList.add(element.warehouseId
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .toLowerCase());
                                warehouseBasedProductModel.add(
                                    WarehouseBasedProductModel(
                                        element.productName,
                                        element.warehouseId));
                              }
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TypeAheadField(
                                  suggestionsCallback: (pattern) {
                                    ProductRepo pr = ProductRepo();
                                    // return pr.getAllProductByJson(searchData: pattern);
                                    return pr.getAllProductByJsonWarehouse(
                                        searchData: pattern,
                                        warehouseId: selectedWareHouse!);
                                  },
                                  itemBuilder: (context, suggestion) {
                                    ProductModel product =
                                        ProductModel.fromJson(
                                      jsonDecode(
                                        jsonEncode(suggestion),
                                      ),
                                    );
                                    return ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          10.0, 5.0, 15.0, 5.0),
                                      // visualDensity: const VisualDensity(vertical: -2),
                                      horizontalTitleGap: 10.0,
                                      leading: Container(
                                        height: 45.0,
                                        width: 45.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: kBorderColorTextField),
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                  product.productPicture),
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      title: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: Text(
                                                '${lang.S.of(context).name}: ${product.productName}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(
                                                    color: kTitleColor,
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )),
                                          const Spacer(),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${lang.S.of(context).purchasePrice}: ${product.productPurchasePrice}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(
                                                    color: kGreyTextColor,
                                                    fontSize: 12.0),
                                              )),
                                          const Spacer(),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                  '${lang.S.of(context).salePrice}: ${product.productSalePrice}',
                                                  textAlign: TextAlign.start,
                                                  style: kTextStyle.copyWith(
                                                      color: kGreyTextColor,
                                                      fontSize: 12.0))),
                                          const Spacer(),
                                          Expanded(
                                            flex: 0,
                                            child: Text(
                                                '${lang.S.of(context).stock}: ${product.productStock}',
                                                textAlign: TextAlign.start,
                                                style: kTextStyle.copyWith(
                                                    color: kGreyTextColor,
                                                    fontSize: 12.0)),
                                          ),
                                        ],
                                      ),
                                      // subtitle: Row(
                                      //   crossAxisAlignment: CrossAxisAlignment.start,
                                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      //   children: [
                                      //     Text('Price : ${product.productSalePrice}'),
                                      //     Text('Purchase: ${product.productPurchasePrice}'),
                                      //     Text('Sale: ${product.productSalePrice}'),
                                      //   ],
                                      // ),
                                      // trailing: Text('Purchase: ${product.productStock}',textAlign: TextAlign.start,style: kTextStyle.copyWith(color: kTitleColor,fontSize: 14.0)),
                                    );
                                  },
                                  onSelected: (suggestion) {
                                    ProductModel product =
                                        ProductModel.fromJson(
                                            jsonDecode(jsonEncode(suggestion)));
                                    AddToCartModel addToCartModel =
                                        AddToCartModel(
                                            productName: product.productName,
                                            warehouseName:
                                                product.warehouseName,
                                            warehouseId: product.warehouseId,
                                            productId: product.productCode,
                                            quantity: 1,
                                            productImage:
                                                product.productPicture,
                                            // stock: product.productStock.toInt(),
                                            // productPurchasePrice: product.productPurchasePrice.toDouble(),
                                            stock: int.tryParse(
                                                    product.productStock) ??
                                                0,
                                            productPurchasePrice:
                                                double.tryParse(product
                                                        .productPurchasePrice) ??
                                                    0.0,
                                            subTotal: productPriceChecker(
                                              product: product,
                                              customerType:
                                                  selectedCustomerType,
                                            ),
                                            taxType: product.taxType,
                                            margin: product.margin,
                                            incTax: product.incTax,
                                            groupTaxRate: product.groupTaxRate,
                                            groupTaxName: product.groupTaxName,
                                            excTax: product.excTax,
                                            subTaxes: product.subTaxes);
                                    setState(() {
                                      if (!uniqueCheck(product.productCode)) {
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
                                      updateDueAmount();
                                    });
                                  },
                                  builder: (context, controller, focusNode) {
                                    return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          labelText:
                                              lang.S.of(context).selectProduct,
                                          hintText: lang.S
                                              .of(context)
                                              .searchWithProductName,
                                        ));
                                  },
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
                        ]),
                        const SizedBox(
                          height: 20,
                        ),
                        LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            final kWidth = constraints.maxWidth - 20;
                            return Scrollbar(
                              controller: horizontalScroll,
                              thickness: 8,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                scrollDirection: Axis.horizontal,
                                controller: horizontalScroll,
                                child: Container(
                                  // width: context.width() < 1260 ? 630 : context.width() * 1,
                                  height:
                                      MediaQuery.of(context).size.height < 720
                                          ? 720 - 410
                                          : MediaQuery.of(context).size.height -
                                              410,
                                  constraints: BoxConstraints(
                                    minWidth: kWidth,
                                  ),
                                  child: Theme(
                                    data: theme.copyWith(
                                        dividerColor: Colors.transparent,
                                        dividerTheme: const DividerThemeData(
                                            color: Colors.transparent)),
                                    child: DataTable(
                                        border: TableBorder.all(
                                          color: kNeutral300,
                                          width: 1.0,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        // border: const TableBorder(
                                        //   horizontalInside: BorderSide(
                                        //     width: 1,
                                        //     color: kNeutral300,
                                        //   ),
                                        // ),
                                        dividerThickness: 0.0,
                                        dataRowColor:
                                            const WidgetStatePropertyAll(
                                                Colors.white),
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                                const Color(0xFFF8F3FF)),
                                        showBottomBorder: false,
                                        headingTextStyle:
                                            theme.textTheme.titleMedium,
                                        dataTextStyle:
                                            theme.textTheme.bodyLarge,
                                        columns: [
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).productNam,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          )),
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).quantity,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          )),
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).price,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          )),
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).subTotal,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          )),
                                          DataColumn(
                                              label: Text(
                                            lang.S.of(context).action,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          )),
                                        ],
                                        rows: List.generate(cartList.length,
                                            (index) {
                                          TextEditingController
                                              quantityController =
                                              TextEditingController(
                                                  text: cartList[index]
                                                      .quantity
                                                      .toString());
                                          return DataRow(cells: [
                                            DataCell(
                                              Text(
                                                cartList[index].productName ??
                                                    '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                            DataCell(Row(
                                              children: [
                                                GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        cartList[index]
                                                                    .quantity >
                                                                1
                                                            ? cartList[index]
                                                                .quantity--
                                                            : cartList[index]
                                                                .quantity = 1;
                                                        updateDueAmount();
                                                      });
                                                    },
                                                    child: const Icon(
                                                        FontAwesomeIcons
                                                            .solidSquareMinus,
                                                        color: kBlueTextColor)),
                                                Container(
                                                  width: 60,
                                                  height: 35,
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10.0,
                                                          right: 10.0,
                                                          top: 2.0,
                                                          bottom: 2.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2.0),
                                                    color: Colors.white,
                                                  ),
                                                  child: TextFormField(
                                                    controller:
                                                        quantityController,
                                                    focusNode:
                                                        productFocusNode[index],
                                                    textAlign: TextAlign.center,
                                                    onChanged: (value) {
                                                      if ((cartList[index]
                                                                  .stock ??
                                                              0) <
                                                          (num.tryParse(
                                                                  value) ??
                                                              0)) {
                                                        EasyLoading.showError(
                                                            lang.S
                                                                .of(context)
                                                                .outOfStock);
                                                        quantityController
                                                            .clear();
                                                        // updateDueAmount();
                                                      } else if (value == '') {
                                                        cartList[index]
                                                            .quantity = 1;
                                                        // updateDueAmount();
                                                      } else if (value == '0') {
                                                        cartList[index]
                                                            .quantity = 1;
                                                        // updateDueAmount();
                                                      } else {
                                                        cartList[index]
                                                                .quantity =
                                                            (num.tryParse(
                                                                    value) ??
                                                                1);
                                                        // updateDueAmount();
                                                      }
                                                    },
                                                    onFieldSubmitted: (value) {
                                                      if (value == '') {
                                                        setState(() {
                                                          cartList[index]
                                                              .quantity = 1;
                                                          updateDueAmount();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          cartList[index]
                                                                  .quantity =
                                                              (num.tryParse(
                                                                      value) ??
                                                                  1);
                                                          updateDueAmount();
                                                        });
                                                      }
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                            border: InputBorder
                                                                .none),
                                                  ),
                                                ),
                                                GestureDetector(
                                                    onTap: () {
                                                      if (cartList[index]
                                                              .quantity <
                                                          cartList[index]
                                                              .stock!
                                                              .toInt()) {
                                                        setState(() {
                                                          cartList[index]
                                                              .quantity += 1;
                                                          updateDueAmount();
                                                          // toast(cartList[index].quantity.toString());
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                                content: Text(cartList[
                                                                        index]
                                                                    .quantity
                                                                    .toString())),
                                                          );
                                                        });
                                                      } else {
                                                        EasyLoading.showError(
                                                            lang.S
                                                                .of(context)
                                                                .outOfStock);
                                                      }
                                                    },
                                                    child: const Icon(
                                                        FontAwesomeIcons
                                                            .solidSquarePlus,
                                                        color: kBlueTextColor)),
                                              ],
                                            )),
                                            DataCell(
                                              SizedBox(
                                                width: 70,
                                                height: 35,
                                                child: TextFormField(
                                                  initialValue: myFormat.format(
                                                      double.tryParse(
                                                              cartList[index]
                                                                  .subTotal) ??
                                                          0),
                                                  onChanged: (value) {
                                                    if (value == '') {
                                                      setState(() {
                                                        cartList[index]
                                                                .subTotal =
                                                            0.toString();
                                                      });
                                                    } else if (double.tryParse(
                                                            value) ==
                                                        null) {
                                                      EasyLoading.showError(lang
                                                          .S
                                                          .of(context)
                                                          .enterAValidPrice);
                                                    } else {
                                                      setState(() {
                                                        cartList[index]
                                                            .subTotal = double
                                                                .parse(value)
                                                            .toStringAsFixed(2);
                                                      });
                                                    }
                                                    updateDueAmount();
                                                  },
                                                  onFieldSubmitted: (value) {
                                                    if (value == '') {
                                                      setState(() {
                                                        cartList[index]
                                                                .subTotal =
                                                            0.toString();
                                                        updateDueAmount();
                                                      });
                                                    } else if (double.tryParse(
                                                            value) ==
                                                        null) {
                                                      EasyLoading.showError(lang
                                                          .S
                                                          .of(context)
                                                          .enterAValidPrice);
                                                    } else {
                                                      setState(() {
                                                        cartList[index]
                                                            .subTotal = double
                                                                .parse(value)
                                                            .toStringAsFixed(2);
                                                        updateDueAmount();
                                                      });
                                                    }
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                          border:
                                                              InputBorder.none),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                myFormat.format(double.tryParse(
                                                        (double.parse(cartList[
                                                                        index]
                                                                    .subTotal) *
                                                                cartList[index]
                                                                    .quantity)
                                                            .toStringAsFixed(
                                                                2)) ??
                                                    0),
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                            DataCell(
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    cartList.removeAt(index);
                                                    productFocusNode
                                                        .removeAt(index);
                                                    updateDueAmount();
                                                  });
                                                },
                                                child: const SizedBox(
                                                  width: 50,
                                                  child: Icon(
                                                    Icons.close_sharp,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ]);
                                        })),
                                  ),
                                  // child: SingleChildScrollView(
                                  //   child: Column(
                                  //     children: [
                                  //       Container(
                                  //         padding: const EdgeInsets.all(15),
                                  //         decoration: const BoxDecoration(color: kbgColor),
                                  //         child: Row(
                                  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //           children: [
                                  //             SizedBox(width: 250, child: Text(lang.S.of(context).productNam)),
                                  //             SizedBox(width: 110, child: Text(lang.S.of(context).quantity)),
                                  //             SizedBox(width: 70, child: Text(lang.S.of(context).price)),
                                  //             SizedBox(width: 100, child: Text(lang.S.of(context).subTotal)),
                                  //             SizedBox(width: 50, child: Text(lang.S.of(context).action)),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //       ListView.builder(
                                  //         shrinkWrap: true,
                                  //         physics: const NeverScrollableScrollPhysics(),
                                  //         itemCount: cartList.length,
                                  //         itemBuilder: (BuildContext context, int index) {
                                  //           TextEditingController quantityController = TextEditingController(text: cartList[index].quantity.toString());
                                  //           return Column(
                                  //             children: [
                                  //               Row(
                                  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //                 children: [
                                  //                   ///______________name__________________________________________________
                                  //                   Container(
                                  //                     width: 250,
                                  //                     padding: const EdgeInsets.only(left: 15),
                                  //                     child: Column(
                                  //                       mainAxisSize: MainAxisSize.min,
                                  //                       crossAxisAlignment: CrossAxisAlignment.start,
                                  //                       mainAxisAlignment: MainAxisAlignment.center,
                                  //                       children: [
                                  //                         Flexible(
                                  //                           child: Text(
                                  //                             cartList[index].productName ?? '',
                                  //                             maxLines: 2,
                                  //                             overflow: TextOverflow.ellipsis,
                                  //                             style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                  //                           ),
                                  //                         ),
                                  //                         // Row(
                                  //                         //   children: [
                                  //                         //     Flexible(
                                  //                         //       child: Text(
                                  //                         //         cartList[index].serialNumber!.isEmpty ? '' : 'IMEI/Serial: ${cartList[index].serialNumber}',
                                  //                         //         maxLines: 1,
                                  //                         //         style: kTextStyle.copyWith(fontSize: 12, color: kTitleColor),
                                  //                         //       ),
                                  //                         //     ),
                                  //                         //   ],
                                  //                         // )
                                  //                       ],
                                  //                     ),
                                  //                   ),
                                  //
                                  //                   ///____________quantity_________________________________________________
                                  //                   SizedBox(
                                  //                     width: 110,
                                  //                     child: Center(
                                  //                       child: Row(
                                  //                         children: [
                                  //                           const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor).onTap(() {
                                  //                             setState(() {
                                  //                               cartList[index].quantity > 1 ? cartList[index].quantity-- : cartList[index].quantity = 1;
                                  //                               updateDueAmount();
                                  //                             });
                                  //                           }),
                                  //                           Container(
                                  //                             width: 60,
                                  //                             padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                                  //                             decoration: BoxDecoration(
                                  //                               borderRadius: BorderRadius.circular(2.0),
                                  //                               color: Colors.white,
                                  //                             ),
                                  //                             child: TextFormField(
                                  //                               controller: quantityController,
                                  //                               focusNode: productFocusNode[index],
                                  //                               textAlign: TextAlign.center,
                                  //                               onChanged: (value) {
                                  //                                 if ((cartList[index].stock ?? 0) < (num.tryParse(value) ?? 0)) {
                                  //                                   EasyLoading.showError(lang.S.of(context).outOfStock);
                                  //                                   quantityController.clear();
                                  //                                   // updateDueAmount();
                                  //                                 } else if (value == '') {
                                  //                                   cartList[index].quantity = 1;
                                  //                                   // updateDueAmount();
                                  //                                 } else if (value == '0') {
                                  //                                   cartList[index].quantity = 1;
                                  //                                   // updateDueAmount();
                                  //                                 } else {
                                  //                                   cartList[index].quantity = (num.tryParse(value) ?? 1);
                                  //                                   // updateDueAmount();
                                  //                                 }
                                  //                               },
                                  //                               onFieldSubmitted: (value) {
                                  //                                 if (value == '') {
                                  //                                   setState(() {
                                  //                                     cartList[index].quantity = 1;
                                  //                                     updateDueAmount();
                                  //                                   });
                                  //                                 } else {
                                  //                                   setState(() {
                                  //                                     cartList[index].quantity = (num.tryParse(value) ?? 1);
                                  //                                     updateDueAmount();
                                  //                                   });
                                  //                                 }
                                  //                               },
                                  //                               decoration: const InputDecoration(border: InputBorder.none),
                                  //                             ),
                                  //                           ),
                                  //                           const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor).onTap(() {
                                  //                             if (cartList[index].quantity < cartList[index].stock!.toInt()) {
                                  //                               setState(() {
                                  //                                 cartList[index].quantity += 1;
                                  //                                 updateDueAmount();
                                  //                                 toast(cartList[index].quantity.toString());
                                  //                               });
                                  //                             } else {
                                  //                               EasyLoading.showError(lang.S.of(context).outOfStock);
                                  //                             }
                                  //                           }),
                                  //                         ],
                                  //                       ),
                                  //                     ),
                                  //                   ),
                                  //
                                  //                   ///______price___________________________________________________________
                                  //                   SizedBox(
                                  //                     width: 70,
                                  //                     child: TextFormField(
                                  //                       initialValue: myFormat.format(double.tryParse(cartList[index].subTotal) ?? 0),
                                  //                       onChanged: (value) {
                                  //                         if (value == '') {
                                  //                           setState(() {
                                  //                             cartList[index].subTotal = 0.toString();
                                  //                           });
                                  //                         } else if (double.tryParse(value) == null) {
                                  //                           EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                                  //                         } else {
                                  //                           setState(() {
                                  //                             cartList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                  //                           });
                                  //                         }
                                  //                         updateDueAmount();
                                  //                       },
                                  //                       onFieldSubmitted: (value) {
                                  //                         if (value == '') {
                                  //                           setState(() {
                                  //                             cartList[index].subTotal = 0.toString();
                                  //                             updateDueAmount();
                                  //                           });
                                  //                         } else if (double.tryParse(value) == null) {
                                  //                           EasyLoading.showError(lang.S.of(context).enterAValidPrice);
                                  //                         } else {
                                  //                           setState(() {
                                  //                             cartList[index].subTotal = double.parse(value).toStringAsFixed(2);
                                  //                             updateDueAmount();
                                  //                           });
                                  //                         }
                                  //                       },
                                  //                       decoration: const InputDecoration(border: InputBorder.none),
                                  //                     ),
                                  //                   ),
                                  //
                                  //                   ///___________subtotal____________________________________________________
                                  //                   SizedBox(
                                  //                     width: 100,
                                  //                     child: Text(
                                  //                       myFormat.format(double.tryParse((double.parse(cartList[index].subTotal) * cartList[index].quantity).toStringAsFixed(2)) ?? 0),
                                  //                       style: kTextStyle.copyWith(color: kTitleColor),
                                  //                     ),
                                  //                   ),
                                  //
                                  //                   ///_______________actions_________________________________________________
                                  //                   SizedBox(
                                  //                     width: 50,
                                  //                     child: const Icon(
                                  //                       Icons.close_sharp,
                                  //                       color: redColor,
                                  //                     ).onTap(() {
                                  //                       setState(() {
                                  //                         cartList.removeAt(index);
                                  //                         productFocusNode.removeAt(index);
                                  //                         updateDueAmount();
                                  //                       });
                                  //                     }),
                                  //                   ),
                                  //                 ],
                                  //               ),
                                  //               Container(
                                  //                 width: double.infinity,
                                  //                 height: 1,
                                  //                 color: kGreyTextColor.withOpacity(0.3),
                                  //               )
                                  //             ],
                                  //           );
                                  //         },
                                  //       )
                                  //     ],
                                  //   ),
                                  // ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ResponsiveGridRow(children: [
                          ResponsiveGridCol(
                              md: 6,
                              lg: 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
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
                              md: 6,
                              lg: 6,
                              xs: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (await Subscription.subscriptionChecker(
                                        item: 'Sales')) {
                                      if (cartList.isEmpty) {
                                        EasyLoading.showError(lang.S
                                            .of(context)
                                            .pleaseAddSomeProductFirst);
                                      } else {
                                        if (selectedUserName == null) {
                                          EasyLoading.showError(
                                              "Please select a customer");
                                          return;
                                        }
                                        showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder:
                                                (BuildContext dialogContext) {
                                              return Center(
                                                child: Container(
                                                  width: 450,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(15),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          lang.S
                                                              .of(context)
                                                              .areYouWantToCreateThisQuation,
                                                          style: theme.textTheme
                                                              .headlineSmall
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                            height: 20),
                                                        ResponsiveGridRow(
                                                            children: [
                                                              ResponsiveGridCol(
                                                                lg: 6,
                                                                md: 6,
                                                                sm: 6,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                    child: Text(
                                                                      lang.S
                                                                          .of(context)
                                                                          .cancel,
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      GoRouter.of(
                                                                              dialogContext)
                                                                          .pop();
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                              ResponsiveGridCol(
                                                                lg: 6,
                                                                md: 6,
                                                                sm: 6,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      SaleTransactionModel
                                                                          transitionModel =
                                                                          SaleTransactionModel(
                                                                        customerName:
                                                                            selectedUserName?.customerName ??
                                                                                '',
                                                                        customerType:
                                                                            selectedUserName?.type ??
                                                                                '',
                                                                        customerImage:
                                                                            selectedUserName?.profilePicture ??
                                                                                '',
                                                                        customerAddress:
                                                                            selectedUserName?.customerAddress ??
                                                                                '',
                                                                        customerPhone:
                                                                            selectedUserName?.phoneNumber ??
                                                                                '',
                                                                        customerGst:
                                                                            selectedUserName?.gst ??
                                                                                '',
                                                                        invoiceNumber: data
                                                                            .saleInvoiceCounter
                                                                            .toString(),
                                                                        sendWhatsappMessage:
                                                                            selectedUserName?.receiveWhatsappUpdates ??
                                                                                false,
                                                                        purchaseDate:
                                                                            DateTime.now().toString(),
                                                                        productList:
                                                                            cartList,
                                                                        totalAmount: double.parse((getTotalAmount().toDouble() +
                                                                                serviceCharge -
                                                                                discountAmount +
                                                                                vatGst)
                                                                            .toStringAsFixed(1)),
                                                                        discountAmount:
                                                                            discountAmount,
                                                                        serviceCharge:
                                                                            serviceCharge,
                                                                        vat:
                                                                            vatGst,
                                                                      );

                                                                      try {
                                                                        EasyLoading.show(
                                                                            status:
                                                                                '${lang.S.of(context).loading}...',
                                                                            dismissOnTap:
                                                                                false);
                                                                        DatabaseReference
                                                                            ref =
                                                                            FirebaseDatabase.instance.ref("${await getUserID()}/Sales Quotation");

                                                                        transitionModel.isPaid =
                                                                            false;
                                                                        transitionModel
                                                                            .dueAmount = 0;
                                                                        transitionModel
                                                                            .lossProfit = 0;
                                                                        transitionModel
                                                                            .returnAmount = 0;
                                                                        transitionModel.paymentType =
                                                                            'Just Quotation';
                                                                        transitionModel.sellerName = isSubUser
                                                                            ? constSubUserTitle
                                                                            : 'Admin';

                                                                        ///_________Push_on_dataBase____________________________________________________________________________
                                                                        await ref
                                                                            .push()
                                                                            .set(transitionModel.toJson());
                                                                        //await GeneratePdfAndPrint().printQuotationInvoice(personalInformationModel: data, saleTransactionModel: transitionModel, context: context);

                                                                        ///_________Invoice Increase____________________________________________________________________________
                                                                        updateInvoice(
                                                                            typeOfInvoice:
                                                                                'saleInvoiceCounter',
                                                                            invoice:
                                                                                transitionModel.invoiceNumber.toInt());

                                                                        consumerRef
                                                                            // ignore: unused_result
                                                                            .refresh(profileDetailsProvider);
                                                                        consumerRef
                                                                            // ignore: unused_result
                                                                            .refresh(quotationProvider);

                                                                        EasyLoading.showSuccess(lang
                                                                            .S
                                                                            .of(context)
                                                                            .addedSuccessfully);
                                                                        GeneratePdfAndPrint().printQuotationInvoice(
                                                                            personalInformationModel:
                                                                                data,
                                                                            saleTransactionModel:
                                                                                transitionModel,
                                                                            context:
                                                                                context,
                                                                            isFromQuotation:
                                                                                true);
                                                                        GoRouter.of(context)
                                                                            .pop();
                                                                      } catch (e) {
                                                                        EasyLoading
                                                                            .dismiss();
                                                                        //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                      lang.S
                                                                          .of(context)
                                                                          .create,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            ]),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            });
                                      }
                                    } else {
                                      // EasyLoading.showError('Update your plan first\nSale Limit is over.');
                                      EasyLoading.showError(
                                          '${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                                    }
                                  },
                                  child: Text(
                                    lang.S.of(context).quotation,
                                  ),
                                ),
                              ).visible(widget.quotation == null)),
                        ]),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     ///________________cancel_button_____________________________________
                        //     Expanded(
                        //       flex: 1,
                        //       child: GestureDetector(
                        //         onTap: () {
                        //           GoRouter.of(context).pop();
                        //         },
                        //         child: Container(
                        //           padding: const EdgeInsets.all(10.0),
                        //           decoration: BoxDecoration(
                        //             shape: BoxShape.rectangle,
                        //             borderRadius: BorderRadius.circular(10.0),
                        //             color: kRedTextColor,
                        //           ),
                        //           child: Text(
                        //             lang.S.of(context).cancel,
                        //             textAlign: TextAlign.center,
                        //             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 10.0),
                        //     Expanded(
                        //       flex: 1,
                        //       child: GestureDetector(
                        //         onTap: () async {
                        //           if (await Subscription.subscriptionChecker(item: 'Sales')) {
                        //             if (cartList.isEmpty) {
                        //               EasyLoading.showError(lang.S.of(context).pleaseAddSomeProductFirst);
                        //             } else {
                        //               if (selectedUserName == null) {
                        //                 EasyLoading.showError("Please select a customer");
                        //                 return;
                        //               }
                        //               showDialog(
                        //                   barrierDismissible: false,
                        //                   context: context,
                        //                   builder: (BuildContext dialogContext) {
                        //                     return Center(
                        //                       child: Container(
                        //                         decoration: const BoxDecoration(
                        //                           color: Colors.white,
                        //                           borderRadius: BorderRadius.all(
                        //                             Radius.circular(15),
                        //                           ),
                        //                         ),
                        //                         child: Padding(
                        //                           padding: const EdgeInsets.all(20.0),
                        //                           child: Column(
                        //                             mainAxisSize: MainAxisSize.min,
                        //                             crossAxisAlignment: CrossAxisAlignment.center,
                        //                             mainAxisAlignment: MainAxisAlignment.center,
                        //                             children: [
                        //                               Text(
                        //                                 lang.S.of(context).areYouWantToCreateThisQuation,
                        //                                 style: const TextStyle(fontSize: 22),
                        //                               ),
                        //                               const SizedBox(height: 30),
                        //                               Row(
                        //                                 mainAxisAlignment: MainAxisAlignment.center,
                        //                                 mainAxisSize: MainAxisSize.min,
                        //                                 children: [
                        //                                   GestureDetector(
                        //                                     child: Container(
                        //                                       width: 130,
                        //                                       height: 50,
                        //                                       decoration: const BoxDecoration(
                        //                                         color: Colors.red,
                        //                                         borderRadius: BorderRadius.all(
                        //                                           Radius.circular(15),
                        //                                         ),
                        //                                       ),
                        //                                       child: Center(
                        //                                         child: Text(
                        //                                           lang.S.of(context).cancel,
                        //                                           style: const TextStyle(color: Colors.white),
                        //                                         ),
                        //                                       ),
                        //                                     ),
                        //                                     onTap: () {
                        //                                       Navigator.pop(dialogContext);
                        //                                     },
                        //                                   ),
                        //                                   const SizedBox(width: 30),
                        //                                   GestureDetector(
                        //                                     child: Container(
                        //                                       width: 130,
                        //                                       height: 50,
                        //                                       decoration: const BoxDecoration(
                        //                                         color: Colors.green,
                        //                                         borderRadius: BorderRadius.all(
                        //                                           Radius.circular(15),
                        //                                         ),
                        //                                       ),
                        //                                       child: Center(
                        //                                         child: Text(
                        //                                           lang.S.of(context).create,
                        //                                           style: const TextStyle(color: Colors.white),
                        //                                         ),
                        //                                       ),
                        //                                     ),
                        //                                     onTap: () async {
                        //                                       SaleTransactionModel transitionModel = SaleTransactionModel(
                        //                                         customerName: selectedUserName?.customerName ?? '',
                        //                                         customerType: selectedUserName?.type ?? '',
                        //                                         customerImage: selectedUserName?.profilePicture ?? '',
                        //                                         customerAddress: selectedUserName?.customerAddress ?? '',
                        //                                         customerPhone: selectedUserName?.phoneNumber ?? '',
                        //                                         customerGst: selectedUserName?.gst ?? '',
                        //                                         invoiceNumber: data.saleInvoiceCounter.toString(),
                        //                                         sendWhatsappMessage: selectedUserName?.receiveWhatsappUpdates ?? false,
                        //                                         purchaseDate: DateTime.now().toString(),
                        //                                         productList: cartList,
                        //                                         totalAmount:
                        //                                             double.parse((getTotalAmount().toDouble() + serviceCharge - discountAmount + vatGst).toStringAsFixed(1)),
                        //                                         discountAmount: discountAmount,
                        //                                         serviceCharge: serviceCharge,
                        //                                         vat: vatGst,
                        //                                       );
                        //
                        //                                       try {
                        //                                         EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                        //                                         DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Quotation");
                        //
                        //                                         transitionModel.isPaid = false;
                        //                                         transitionModel.dueAmount = 0;
                        //                                         transitionModel.lossProfit = 0;
                        //                                         transitionModel.returnAmount = 0;
                        //                                         transitionModel.paymentType = 'Just Quotation';
                        //                                         transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                        //
                        //                                         ///_________Push_on_dataBase____________________________________________________________________________
                        //                                         await ref.push().set(transitionModel.toJson());
                        //                                         //await GeneratePdfAndPrint().printQuotationInvoice(personalInformationModel: data, saleTransactionModel: transitionModel, context: context);
                        //
                        //                                         ///_________Invoice Increase____________________________________________________________________________
                        //                                         updateInvoice(typeOfInvoice: 'saleInvoiceCounter', invoice: transitionModel.invoiceNumber.toInt());
                        //
                        //                                         consumerRef.refresh(profileDetailsProvider);
                        //                                         consumerRef.refresh(quotationProvider);
                        //
                        //                                         EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully);
                        //                                         GeneratePdfAndPrint().printQuotationInvoice(
                        //                                             personalInformationModel: data, saleTransactionModel: transitionModel, context: context, isFromQuotation: true);
                        //                                         Navigator.pop(context);
                        //                                       } catch (e) {
                        //                                         EasyLoading.dismiss();
                        //                                         //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        //                                       }
                        //                                     },
                        //                                   ),
                        //                                 ],
                        //                               )
                        //                             ],
                        //                           ),
                        //                         ),
                        //                       ),
                        //                     );
                        //                   });
                        //             }
                        //           } else {
                        //             // EasyLoading.showError('Update your plan first\nSale Limit is over.');
                        //             EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                        //           }
                        //         },
                        //         child: Container(
                        //           padding: const EdgeInsets.all(10.0),
                        //           decoration: BoxDecoration(
                        //             shape: BoxShape.rectangle,
                        //             borderRadius: BorderRadius.circular(10.0),
                        //             color: Colors.black,
                        //           ),
                        //           child: Text(
                        //             lang.S.of(context).quotation,
                        //             textAlign: TextAlign.center,
                        //             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //           ),
                        //         ),
                        //       ),
                        //     ).visible(widget.quotation == null),
                        //     const SizedBox(width: 10.0),
                        //     Expanded(
                        //       flex: 1,
                        //       child: Container(
                        //         padding: const EdgeInsets.all(10.0),
                        //         decoration: BoxDecoration(
                        //           shape: BoxShape.rectangle,
                        //           borderRadius: BorderRadius.circular(2.0),
                        //           color: Colors.yellow,
                        //         ),
                        //         child: Text(
                        //           lang.S.of(context).hold,
                        //           textAlign: TextAlign.center,
                        //           style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //         ),
                        //       ).onTap(() => showHoldPopUp()),
                        //     ).visible(false),
                        //
                        //     // ///________________payments_________________________________________
                        //     // const SizedBox(width: 10.0),
                        //     // Expanded(
                        //     //   flex: 1,
                        //     //   child: Container(
                        //     //     padding: const EdgeInsets.all(10.0),
                        //     //     decoration: BoxDecoration(
                        //     //       shape: BoxShape.rectangle,
                        //     //       borderRadius: BorderRadius.circular(10.0),
                        //     //       color: kBlueTextColor,
                        //     //     ),
                        //     //     child: Text(
                        //     //       lang.S.of(context).payment,
                        //     //       textAlign: TextAlign.center,
                        //     //       style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                        //     //     ),
                        //     //   ).onTap(
                        //     //     () async {
                        //     //       if (await checkUserRolePermission(type: 'sale')) {
                        //     //         if (await Subscription.subscriptionChecker(item: 'Sales')) {
                        //     //           if (cartList.isEmpty) {
                        //     //             EasyLoading.showError(lang.S.of(context).pleaseAddSomeProductFirst);
                        //     //           } else {
                        //     //             if(selectedUserName == null){
                        //     //               EasyLoading.showError("Please select a customer");
                        //     //               return;
                        //     //             }
                        //     //             SaleTransactionModel transitionModel = SaleTransactionModel(
                        //     //               customerName: selectedUserName?.customerName ?? '',
                        //     //               customerType: selectedUserName?.type ?? '',
                        //     //               customerGst: selectedUserName?.gst ?? '',
                        //     //               customerAddress: selectedUserName?.customerAddress ?? '',
                        //     //               customerPhone: selectedUserName?.phoneNumber ?? '',
                        //     //               customerImage: selectedUserName?.profilePicture ?? '',
                        //     //               sendWhatsappMessage: selectedUserName?.receiveWhatsappUpdates ?? false,
                        //     //               invoiceNumber: widget.quotation == null ? data.saleInvoiceCounter.toString() : widget.quotation!.invoiceNumber,
                        //     //               purchaseDate: DateTime.now().toString(),
                        //     //               productList: cartList,
                        //     //               totalAmount: double.parse((getTotalAmount().toDouble() + serviceCharge - discountAmount + vatGst).toStringAsFixed(1)),
                        //     //               discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
                        //     //               serviceCharge: double.parse(serviceCharge.toStringAsFixed(2)),
                        //     //               vat: double.parse(vatGst.toStringAsFixed(2)),
                        //     //             );
                        //     //
                        //     //             if (transitionModel.customerType == "Guest" && dueAmountController.text.toDouble() > 0) {
                        //     //               EasyLoading.showError(lang.S.of(context).dueIsNotAvailableForGuest);
                        //     //             } else {
                        //     //               try {
                        //     //                 setState(() {
                        //     //                   saleButtonClicked = true;
                        //     //                 });
                        //     //                 EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                        //     //
                        //     //                 DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Transition");
                        //     //
                        //     //                 (double.tryParse(dueAmountController.text) ?? 0) <= 0 ? transitionModel.isPaid = true : transitionModel.isPaid = false;
                        //     //                 (double.tryParse(dueAmountController.text) ?? 0) <= 0 ? transitionModel.dueAmount = 0 : transitionModel.dueAmount = (double.tryParse(dueAmountController.text) ?? 0);
                        //     //                 (double.tryParse(changeAmountController.text) ?? 0) > 0 ? transitionModel.returnAmount = (double.tryParse(changeAmountController.text) ?? 0).abs() : transitionModel.returnAmount = 0;
                        //     //
                        //     //                 transitionModel.paymentType = selectedPaymentOption;
                        //     //                 transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                        //     //
                        //     //                 ///__________total LossProfit & quantity________________________________________________________________
                        //     //                 SaleTransactionModel post = checkLossProfit(transitionModel: transitionModel);
                        //     //
                        //     //                 ///_________Push_on_dataBase____________________________________________________________________________
                        //     //                 await ref.push().set(post.toJson());
                        //     //
                        //     //                 await GeneratePdfAndPrint().printSaleInvoice(personalInformationModel: data, saleTransactionModel: transitionModel, context: context);
                        //     //
                        //     //                 ///__________StockMange_________________________________________________________________________________
                        //     //                 final stockRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products');
                        //     //
                        //     //                 for (var element in transitionModel.productList!) {
                        //     //                   var data = await stockRef.orderByChild('productCode').equalTo(element.productId).once();
                        //     //                   final data2 = jsonDecode(jsonEncode(data.snapshot.value));
                        //     //                   String productPath = data.snapshot.value.toString().substring(1, 21);
                        //     //
                        //     //                   var data1 = await stockRef.child('$productPath/productStock').get();
                        //     //                   num stock = num.parse(data1.value.toString());
                        //     //                   num remainStock = stock - element.quantity;
                        //     //
                        //     //                   stockRef.child(productPath).update({'productStock': '$remainStock'});
                        //     //
                        //     //                   ///________Update_Serial_Number____________________________________________________
                        //     //
                        //     //                   if (element.serialNumber?.isNotEmpty ?? false) {
                        //     //                     var productOldSerialList = data2[productPath]['serialNumber'];
                        //     //
                        //     //                     List<dynamic> result = productOldSerialList.where((item) => !element.serialNumber!.contains(item)).toList();
                        //     //                     stockRef.child(productPath).update({
                        //     //                       'serialNumber': result.map((e) => e).toList(),
                        //     //                     });
                        //     //                   }
                        //     //                 }
                        //     //
                        //     //                 ///_________Invoice Increase____________________________________________________________________________
                        //     //                 updateInvoice(typeOfInvoice: 'saleInvoiceCounter', invoice: transitionModel.invoiceNumber.toInt());
                        //     //
                        //     //                 ///________Subscription_____________________________________________________
                        //     //
                        //     //                 Subscription.decreaseSubscriptionLimits(itemType: 'saleNumber', context: context);
                        //     //
                        //     //                 ///________daily_transactionModel_________________________________________________________________________
                        //     //
                        //     //                 DailyTransactionModel dailyTransaction = DailyTransactionModel(
                        //     //                   name: post.customerName,
                        //     //                   date: post.purchaseDate,
                        //     //                   type: 'Sale',
                        //     //                   total: post.totalAmount!.toDouble(),
                        //     //                   paymentIn: post.totalAmount!.toDouble() - post.dueAmount!.toDouble(),
                        //     //                   paymentOut: 0,
                        //     //                   remainingBalance: post.totalAmount!.toDouble() - post.dueAmount!.toDouble(),
                        //     //                   id: post.invoiceNumber,
                        //     //                   saleTransactionModel: post,
                        //     //                 );
                        //     //                 postDailyTransaction(dailyTransactionModel: dailyTransaction);
                        //     //
                        //     //                 ///_________DueUpdate___________________________________________________________________________________
                        //     //                 if (transitionModel.customerName != 'Guest') {
                        //     //                   final dueUpdateRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
                        //     //                   String? key;
                        //     //
                        //     //                   await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
                        //     //                     for (var element in value.children) {
                        //     //                       var data = jsonDecode(jsonEncode(element.value));
                        //     //                       if (data['phoneNumber'] == transitionModel.customerPhone) {
                        //     //                         key = element.key;
                        //     //                       }
                        //     //                     }
                        //     //                   });
                        //     //                   var data1 = await dueUpdateRef.child('$key/due').get();
                        //     //                   int previousDue = data1.value.toString().toInt();
                        //     //
                        //     //                   int totalDue = previousDue + transitionModel.dueAmount!.toInt();
                        //     //                   dueUpdateRef.child(key!).update({'due': '$totalDue'});
                        //     //                 }
                        //     //
                        //     //                 ///________update_all_provider___________________________________________________
                        //     //
                        //     //                 consumerRef.refresh(allCustomerProvider);
                        //     //                 consumerRef.refresh(transitionProvider);
                        //     //                 consumerRef.refresh(productProvider);
                        //     //                 consumerRef.refresh(purchaseTransitionProvider);
                        //     //                 consumerRef.refresh(dueTransactionProvider);
                        //     //                 consumerRef.refresh(profileDetailsProvider);
                        //     //                 consumerRef.refresh(dailyTransactionProvider);
                        //     //                 //
                        //     //                 //EasyLoading.showSuccess('Sale Successfully Done');
                        //     //                 EasyLoading.showSuccess(lang.S.of(context).saleSuccessfullyDone);
                        //     //               } catch (e) {
                        //     //                 setState(() {
                        //     //                   saleButtonClicked = false;
                        //     //                 });
                        //     //                 EasyLoading.dismiss();
                        //     //                 //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        //     //               }
                        //     //             }
                        //     //             // try {
                        //     //             //   final result = await InternetAddress.lookup('google.com');
                        //     //             //   if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        //     //             //     if (widget.transitionModel.customerType == "Guest" && dueAmountController.text.toDouble() > 0) {
                        //     //             //       EasyLoading.showError('Due is not available For Guest');
                        //     //             //     } else {
                        //     //             //       try {
                        //     //             //         EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                        //     //             //
                        //     //             //         DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Transition");
                        //     //             //         DatabaseReference ref1 = FirebaseDatabase.instance.ref("${await getUserID()}/Quotation Convert History");
                        //     //             //
                        //     //             //         dueAmountController.text.toDouble() <= 0 ? widget.transitionModel.isPaid = true : widget.transitionModel.isPaid = false;
                        //     //             //         dueAmountController.text.toDouble() <= 0
                        //     //             //             ? widget.transitionModel.dueAmount = 0
                        //     //             //             : widget.transitionModel.dueAmount = double.parse(dueAmountController.text);
                        //     //             //         changeAmountController.text.toDouble() > 0
                        //     //             //             ? widget.transitionModel.returnAmount = changeAmountController.text.toDouble().abs()
                        //     //             //             : widget.transitionModel.returnAmount = 0;
                        //     //             //         widget.transitionModel.totalAmount = widget.transitionModel.totalAmount!.toDouble().toDouble();
                        //     //             //         widget.transitionModel.paymentType = selectedPaymentOption;
                        //     //             //         widget.transitionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                        //     //             //
                        //     //             //         // ///_____sms_______________________________________________________
                        //     //             //         // SmsModel smsModel = SmsModel(
                        //     //             //         //   customerName: widget.transitionModel.customerName,
                        //     //             //         //   customerPhone: widget.transitionModel.customerPhone,
                        //     //             //         //   invoiceNumber: widget.transitionModel.invoiceNumber,
                        //     //             //         //   dueAmount: widget.transitionModel.dueAmount.toString(),
                        //     //             //         //   paidAmount:
                        //     //             //         //       (widget.transitionModel.totalAmount!.toDouble() - widget.transitionModel.dueAmount!.toDouble()).toString(),
                        //     //             //         //   sellerId: userId,
                        //     //             //         //   sellerMobile: data.phoneNumber,
                        //     //             //         //   sellerName: data.companyName,
                        //     //             //         //   totalAmount: widget.transitionModel.totalAmount.toString(),
                        //     //             //         //   status: false,
                        //     //             //         // );
                        //     //             //
                        //     //             //         ///__________total LossProfit & quantity________________________________________________________________
                        //     //             //         SaleTransactionModel post = checkLossProfit(transitionModel: widget.transitionModel);
                        //     //             //
                        //     //             //         ///_________Push_on_dataBase____________________________________________________________________________
                        //     //             //         await ref.push().set(post.toJson());
                        //     //             //
                        //     //             //         ///_________Push_on_Quotation to Sale history____________________________________________________________________________
                        //     //             //         widget.isFromQuotation ? await ref1.push().set(post.toJson()) : null;
                        //     //             //
                        //     //             //         ///________sms_post________________________________________________________________________
                        //     //             //         // FirebaseDatabase.instance.ref('Admin Panel').child('Sms List').push().set(smsModel.toJson());
                        //     //             //
                        //     //             //         ///__________StockMange_________________________________________________________________________________
                        //     //             //         final stockRef = FirebaseDatabase.instance.ref('${await getUserID()}/Products/');
                        //     //             //
                        //     //             //         for (var element in widget.transitionModel.productList!) {
                        //     //             //           var data = await stockRef.orderByChild('productCode').equalTo(element.productId).once();
                        //     //             //           final data2 = jsonDecode(jsonEncode(data.snapshot.value));
                        //     //             //           String productPath = data.snapshot.value.toString().substring(1, 21);
                        //     //             //
                        //     //             //           var data1 = await stockRef.child('$productPath/productStock').once();
                        //     //             //           int stock = int.parse(data1.snapshot.value.toString());
                        //     //             //           int remainStock = stock - element.quantity;
                        //     //             //
                        //     //             //           stockRef.child(productPath).update({'productStock': '$remainStock'});
                        //     //             //
                        //     //             //           ///________Update_Serial_Number____________________________________________________
                        //     //             //
                        //     //             //           if (element.serialNumber!.isNotEmpty) {
                        //     //             //             var productOldSerialList = data2[productPath]['serialNumber'];
                        //     //             //
                        //     //             //             List<dynamic> result = productOldSerialList.where((item) => !element.serialNumber!.contains(item)).toList();
                        //     //             //             stockRef.child(productPath).update({
                        //     //             //               'serialNumber': result.map((e) => e).toList(),
                        //     //             //             });
                        //     //             //           }
                        //     //             //         }
                        //     //             //
                        //     //             //         ///_________Invoice Increase____________________________________________________________________________
                        //     //             //         widget.isFromQuotation
                        //     //             //             ? null
                        //     //             //             : updateInvoice(typeOfInvoice: 'saleInvoiceCounter', invoice: widget.transitionModel.invoiceNumber.toInt());
                        //     //             //
                        //     //             //         ///_________delete_quotation___________________________________________________________________________________
                        //     //             //
                        //     //             //         widget.isFromQuotation ? deleteQuotation(date: widget.transitionModel.invoiceNumber, updateRef: consumerRef) : null;
                        //     //             //
                        //     //             //         ///________Subscription_____________________________________________________
                        //     //             //
                        //     //             //         Subscription.decreaseSubscriptionLimits(itemType: 'saleNumber', context: context);
                        //     //             //
                        //     //             //         ///________daily_transactionModel_________________________________________________________________________
                        //     //             //
                        //     //             //         DailyTransactionModel dailyTransaction = DailyTransactionModel(
                        //     //             //           name: post.customerName,
                        //     //             //           date: post.purchaseDate,
                        //     //             //           type: 'Sale',
                        //     //             //           total: post.totalAmount!.toDouble(),
                        //     //             //           paymentIn: post.totalAmount!.toDouble() - post.dueAmount!.toDouble(),
                        //     //             //           paymentOut: 0,
                        //     //             //           remainingBalance: post.totalAmount!.toDouble() - post.dueAmount!.toDouble(),
                        //     //             //           id: post.invoiceNumber,
                        //     //             //           saleTransactionModel: post,
                        //     //             //         );
                        //     //             //         postDailyTransaction(dailyTransactionModel: dailyTransaction);
                        //     //             //
                        //     //             //         ///_________DueUpdate___________________________________________________________________________________
                        //     //             //         if (widget.transitionModel.customerName != 'Guest') {
                        //     //             //           final dueUpdateRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
                        //     //             //           String? key;
                        //     //             //
                        //     //             //           await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
                        //     //             //             for (var element in value.children) {
                        //     //             //               var data = jsonDecode(jsonEncode(element.value));
                        //     //             //               if (data['phoneNumber'] == widget.transitionModel.customerPhone) {
                        //     //             //                 key = element.key;
                        //     //             //               }
                        //     //             //             }
                        //     //             //           });
                        //     //             //           var data1 = await dueUpdateRef.child('$key/due').once();
                        //     //             //           int previousDue = data1.snapshot.value.toString().toInt();
                        //     //             //
                        //     //             //           int totalDue = previousDue + widget.transitionModel.dueAmount!.toInt();
                        //     //             //           dueUpdateRef.child(key!).update({'due': '$totalDue'});
                        //     //             //         }
                        //     //             //
                        //     //             //         ///________update_all_provider___________________________________________________
                        //     //             //
                        //     //             //         consumerRef.refresh(allCustomerProvider);
                        //     //             //         consumerRef.refresh(transitionProvider);
                        //     //             //         consumerRef.refresh(productProvider);
                        //     //             //         consumerRef.refresh(purchaseTransitionProvider);
                        //     //             //         consumerRef.refresh(dueTransactionProvider);
                        //     //             //         consumerRef.refresh(profileDetailsProvider);
                        //     //             //         consumerRef.refresh(dailyTransactionProvider);
                        //     //             //
                        //     //             //         EasyLoading.showSuccess('Sale Successfully Done');
                        //     //             //
                        //     //             //         await GeneratePdfAndPrint()
                        //     //             //             .printSaleInvoice(personalInformationModel: data, saleTransactionModel: widget.transitionModel, context: context);
                        //     //             //       } catch (e) {
                        //     //             //         EasyLoading.dismiss();
                        //     //             //         //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        //     //             //       }
                        //     //             //     }
                        //     //             //     print('-----------------------connected-----------------');
                        //     //             //   }
                        //     //             // } on SocketException catch (_) {
                        //     //             //   setState(() {
                        //     //             //     showDialog(
                        //     //             //         context: context,
                        //     //             //         builder: (BuildContext context){
                        //     //             //           return AlertDialog(
                        //     //             //             shape: RoundedRectangleBorder(
                        //     //             //                 borderRadius: BorderRadius.circular(10)
                        //     //             //             ),
                        //     //             //             content: Column(
                        //     //             //               mainAxisSize: MainAxisSize.min,
                        //     //             //               children: [
                        //     //             //                 Text(lang.S.of(context).noConnection,style: kTextStyle.copyWith(fontWeight: FontWeight.bold),),
                        //     //             //                 Text(lang.S.of(context).pleaseCheckYourInternetConnectivity)
                        //     //             //               ],
                        //     //             //             ),
                        //     //             //           );
                        //     //             //         });
                        //     //             //   });
                        //     //             //   print('-----------------not connected---------------');
                        //     //             // }
                        //     //
                        //     //             // ShowPaymentPopUp(
                        //     //             //   transitionModel: transitionModel,
                        //     //             //   isFromQuotation: widget.quotation == null ? false : true,
                        //     //             // ).launch(context);
                        //     //           }
                        //     //         } else {
                        //     //           //EasyLoading.showError('Update your plan first\nSale Limit is over.');
                        //     //           EasyLoading.showError('${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                        //     //         }
                        //     //       }
                        //     //     },
                        //     //   ),
                        //     // ),
                        //   ],
                        // ),
                      ],
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
        }),
      ),
    );
  }
}
