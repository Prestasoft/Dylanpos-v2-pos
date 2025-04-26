// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/product_model.dart';

import '../../Provider/customer_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../model/category_model.dart';
import '../../model/customer_model.dart';
import '../../model/purchase_transation_model.dart';
import '../../subscription.dart';
import '../Product/WarebasedProduct.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Calculator/calculator.dart';
import '../Widgets/Pop UP/Purchase/purchase_due_sale_popup.dart';
import '../Widgets/Pop UP/Purchase/purchase_sale_list_popup.dart';
import '../Widgets/Pop UP/Purchase/purchase_show_add_item_popup.dart';
import '../currency/currency_provider.dart';

class Purchase extends StatefulWidget {
  const Purchase({super.key});

  // static const String route = '/pos-purchase';

  @override
  State<Purchase> createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  bool uniqueCheck(String code) {
    bool isUnique = false;
    for (var item in cartList) {
      if (item.productCode == code) {
        item.productStock = (item.productStock.toInt() + 1).toString();
        isUnique = true;
        break;
      }
    }
    return isUnique;
  }

  String getTotalAmount() {
    double total = 0.0;
    for (var item in cartList) {
      total = total + (double.parse(item.productPurchasePrice) * item.productStock.toInt());
    }
    return total.toStringAsFixed(2);
  }

  List<ProductModel> cartList = [];

  bool isChecked = true;
  String isSelected = 'Categories';
  String selectedUser = 'Name  Phone  Due';
  String searchProductCode = '';
  String selectedCategory = 'Categories';

  List<String> categories = [
    'Purchase Price',
  ];

  String selectedCategories = 'Purchase Price';

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in categories) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedCategories,
      onChanged: (value) {
        setState(() {
          selectedCategories = value!;
        });
      },
    );
  }

//Create Customer
  List<CustomerModel> customerLists = [];
  String? selectedUserId = 'Guest';
  String? invoiceNumber;
  String previousDue = "0";
  CustomerModel selectedUserName = CustomerModel(
    customerName: "Guest",
    phoneNumber: "00",
    type: "Guest",
    customerAddress: '',
    emailAddress: '',
    profilePicture: '',
    openingBalance: '0',
    remainedBalance: '0',
    dueAmount: '0',
    gst: '',
  );

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
            if (selectedUserId == 'Guest') {
              previousDue = '0';
              selectedUserName = CustomerModel(
                customerName: "Guest",
                phoneNumber: "00",
                type: "Guest",
                customerAddress: '',
                emailAddress: '',
                profilePicture: '',
                openingBalance: '0',
                remainedBalance: '0',
                dueAmount: '0',
                gst: '',
              );
            } else if (element.phoneNumber == selectedUserId) {
              selectedUserName = element;
              previousDue = element.dueAmount;
            }
          }
          invoiceNumber = '';
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

  DateTime selectedSaleDate = DateTime.now();

  DateTime selectedBirthDate = DateTime.now();

  String selectedCategoryList = 'Accessories';

// Import Image
  File? image;

  Future pickImage(ImageSource gallery) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() {
        this.image = imageTemporary;
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Field to pick image: $e');
      }
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
          child: const PurchaseDueSalePopUp(),
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
                child: const PurchaseSaleListPopUp());
          },
        );
      },
    );
  }

  void productEditPopUp({required ProductModel product, required int index}) {
    FocusNode serialFocus = FocusNode();
    String editedPurchasePrice = '';
    String editedSalePrice = '';
    String editDealerPrice = '';
    String editWholesalerPrice = '';
    List<String> serialNumberList = product.serialNumber;
    TextEditingController serialController = TextEditingController();
    GlobalKey<FormState> priceKey = GlobalKey<FormState>();
    bool validateAndSave() {
      final form = priceKey.currentState;
      if (form!.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    bool isWantToAddSerial = serialNumberList.isNotEmpty ? true : false;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState1) {
            return Dialog(
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: SizedBox(
                width: 500,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SingleChildScrollView(
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
                                "${product.productName} (${product.productStock})",
                                style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 20.0),
                              ),
                              const Spacer(),
                              const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {finish(context)})
                            ],
                          ),
                        ),
                        const Divider(thickness: 1.0, color: kLitGreyColor),
                        const SizedBox(height: 10.0),
                        Form(
                          key: priceKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value.isEmptyOrNull) {
                                          return 'Please enter Purchase Price';
                                        } else if (double.tryParse(value!) == null && !value.isEmptyOrNull) {
                                          return 'Enter Price in number.';
                                        } else {
                                          return null;
                                        }
                                      },
                                      initialValue: product.productPurchasePrice,
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      onSaved: (value) {
                                        editedPurchasePrice = value!;
                                      },
                                      decoration: kInputDecoration.copyWith(
                                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                                        labelText: lang.S.of(context).purchasePrice,
                                        hintText: lang.S.of(context).enterPurchasePrice,
                                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value.isEmptyOrNull) {
                                          return 'Please enter Sale Price';
                                        } else if (double.tryParse(value!) == null && !value.isEmptyOrNull) {
                                          return 'Enter Price in number.';
                                        } else {
                                          return null;
                                        }
                                      },
                                      initialValue: product.productSalePrice,
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      onSaved: (value) {
                                        editedSalePrice = value!;
                                      },
                                      decoration: kInputDecoration.copyWith(
                                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                                        labelText: lang.S.of(context).salePrices,
                                        hintText: lang.S.of(context).enterSalePrice,
                                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      validator: (value) {
                                        return null;
                                      },
                                      initialValue: product.productDealerPrice,
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      onSaved: (value) {
                                        editDealerPrice = value!;
                                      },
                                      decoration: kInputDecoration.copyWith(
                                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                                        labelText: lang.S.of(context).dealerPrice,
                                        hintText: lang.S.of(context).enterDealePrice,
                                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      validator: (value) {
                                        return null;
                                      },
                                      initialValue: product.productWholeSalePrice,
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      onSaved: (value) {
                                        editWholesalerPrice = value!;
                                      },
                                      decoration: kInputDecoration.copyWith(
                                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                                        labelText: lang.S.of(context).wholeSaleprice,
                                        hintText: lang.S.of(context).enterPrice,
                                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              Text(lang.S.of(context).addingSerialNumber),
                              const SizedBox(width: 10),
                              CupertinoSwitch(
                                  value: isWantToAddSerial,
                                  onChanged: (value) {
                                    setState1(() {
                                      isWantToAddSerial = value;
                                    });
                                  })
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                controller: serialController,
                                focus: serialFocus,
                                autoFocus: true,
                                showCursor: true,
                                cursorColor: kTitleColor,
                                onFieldSubmitted: (value) {
                                  if (!serialNumberList.contains(value)) {
                                    setState1(() {
                                      serialNumberList.add(value);
                                      serialController.text = '';
                                      serialFocus.requestFocus();
                                    });
                                  } else {
                                    EasyLoading.showError('Already Added');
                                    serialFocus.requestFocus();
                                  }
                                },
                                textFieldType: TextFieldType.NAME,
                                decoration: kInputDecoration.copyWith(
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                                  labelText: lang.S.of(context).serialNumber,
                                  hintText: lang.S.of(context).enterSerialNumber,
                                  hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                  labelStyle: kTextStyle.copyWith(color: kTitleColor),
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
                                    itemCount: serialNumberList.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      if (serialNumberList.isNotEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${serialNumberList[index]},',
                                              ),
                                              const SizedBox(width: 3),
                                              GestureDetector(
                                                  onTap: () {
                                                    setState1(() {
                                                      serialNumberList.removeAt(index);
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.red,
                                                    size: 15,
                                                  )),
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
                            ],
                          ),
                        ).visible(isWantToAddSerial),
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
                                if (validateAndSave()) {
                                  cartList[index].serialNumber = serialNumberList;
                                  cartList[index].productPurchasePrice = double.parse(editedPurchasePrice).toStringAsFixed(2);
                                  cartList[index].productSalePrice = double.parse(editedSalePrice).toStringAsFixed(2);
                                  cartList[index].productDealerPrice = double.parse(editDealerPrice).toStringAsFixed(2);
                                  cartList[index].productWholeSalePrice = double.parse(editWholesalerPrice).toStringAsFixed(2);

                                  setState(() {});

                                  GoRouter.of(context).pop();
                                }
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
                ),
              ),
            );
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
                child: const PurchaseShowAddItemPopUp());
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [CalcButton()],
                ),
              ),
            );
          },
        );
      },
    );
  }

  TextEditingController qtyController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController nameCodeCategoryController = TextEditingController();
  TextEditingController discountPercentageEditingController = TextEditingController();
  TextEditingController discountAmountEditingController = TextEditingController();
  double discountAmount = 0;
  double percentage = 0;

  FocusNode nameFocus = FocusNode();

  final ScrollController mainSideScroller = ScrollController();
  final ScrollController sideScroller = ScrollController();

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

  final _horizontalController = ScrollController();

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
    List<String> allProductsNameList = [];
    List<String> allProductsCodeList = [];
    List<String> warehouseIdList = [];
    List<WarehouseBasedProductModel> warehouseBasedProductModel = [];

    return Consumer(
      builder: (context, consumerRef, __) {
        final wareHouseList = consumerRef.watch(warehouseProvider);
        AsyncValue<List<ProductModel>> productList = consumerRef.watch(productProvider);
        final customers = consumerRef.watch(allCustomerProvider);
        final personalData = consumerRef.watch(profileDetailsProvider);
        return personalData.when(data: (data) {
          return Scaffold(
            backgroundColor: kDarkWhite,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ///__________Header section_______________________________________
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ResponsiveGridRow(rowSegments: 120, children: [
                          ///_______Date_________________________________________________
                          ResponsiveGridCol(
                            xs: screenWidth > 450 ? 60 : 120,
                            md: 40,
                            lg: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                alignment: Alignment.center,
                                height: 40,
                                width: screenWidth,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: kNeutral400),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  '${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: kNeutral700,
                                  ),
                                ),
                              ).onTap(() => _selectedDueDate(context)),
                            ),
                          ),

                          ///_________Previous_Due__________________________________
                          ResponsiveGridCol(
                            xs: screenWidth > 450 ? 60 : 120,
                            md: 40,
                            lg: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    lang.S.of(context).previousDue,
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
                            ),
                          ),

                          ///_________Calculator_____________________________________
                          ResponsiveGridCol(
                            xs: screenWidth > 450 ? 60 : 120,
                            md: 40,
                            lg: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
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
                            ),
                          ),

                          ///__________dashboard___________________________________________________________________
                          ResponsiveGridCol(
                            xs: screenWidth > 450 ? 60 : 120,
                            md: 40,
                            lg: 30,
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
                                        style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ).onTap(
                                () => context.go('/dashboard'),
                              ),
                            ),
                          ),

                          ///___________warehouse_section_______________________________
                          ResponsiveGridCol(
                            xs: 60,
                            md: 40,
                            lg: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: wareHouseList.when(
                                data: (warehouse) {
                                  return Container(
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
                          ),

                          ///______________invoice_counter-___________________________
                          ResponsiveGridCol(
                            xs: 60,
                            md: 40,
                            lg: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Invoice:',
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
                                        "#${data.purchaseInvoiceCounter.toString()}",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: kNeutral700,
                                        ),
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          ///---------------select customer-------------
                          ResponsiveGridCol(
                            xs: 120,
                            md: 60,
                            lg: 40,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: customers.when(data: (allCustomers) {
                                List<String> listOfPhoneNumber = [];
                                List<CustomerModel> suppliersList = [];

                                for (var value1 in allCustomers) {
                                  listOfPhoneNumber.add(value1.phoneNumber.removeAllWhiteSpace().toLowerCase());
                                  if (value1.type == 'Supplier') {
                                    suppliersList.add(value1);
                                  }
                                }
                                return Row(
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
                                          child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: Colors.transparent, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getResult(suppliersList)))),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.push(
                                          '/add-customer',
                                          extra: {
                                            'typeOfCustomerAdd': 'Supplier',
                                            'listOfPhoneNumber': listOfPhoneNumber,
                                          },
                                        );
                                      },
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: kBlueTextColor,
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                        ),
                                        child: const Icon(
                                          FeatherIcons.userPlus,
                                          color: Colors.white,
                                          size: 18.0,
                                        ),
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
                              }),
                            ),
                          ),

                          ///___________product_search_________________________________
                          ResponsiveGridCol(
                            xs: 120,
                            md: 60,
                            lg: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: productList.when(data: (product) {
                                for (var element in product) {
                                  allProductsNameList.add(element.productName.removeAllWhiteSpace().toLowerCase());
                                  allProductsCodeList.add(element.productCode.removeAllWhiteSpace().toLowerCase());
                                  warehouseIdList.add(element.warehouseId.removeAllWhiteSpace().toLowerCase());
                                  warehouseBasedProductModel.add(WarehouseBasedProductModel(element.productName, element.warehouseId));
                                }
                                return SizedBox(
                                  height: 40.0,
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
                                            ProductModel cartProduct = product[i];
                                            cartProduct.serialNumber = [];
                                            cartProduct.productStock = '1';
                                            setState(() {
                                              if (!uniqueCheck(product[i].productCode)) {
                                                cartList.add(cartProduct);
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
                                        decoration: const BoxDecoration(borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)), color: kBlueTextColor),
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
                                      hintText: lang.S.of(context).nameCodeOrCateogry,
                                      hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
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

                          // ///--------------customer type------------------------------
                          // ResponsiveGridCol(
                          //   xs: 120,
                          //   md: 40,
                          //   lg: 24,
                          //   child: SizedBox(
                          //     width: context.width() < 1080 ? 120 : MediaQuery.of(context).size.width * .20,
                          //     child: Card(
                          //       color: Colors.white,
                          //       elevation: 0,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(5.0),
                          //         side: const BorderSide(color: kLitGreyColor),
                          //       ),
                          //       child: SizedBox(
                          //         height: 40.0,
                          //         child: Center(
                          //           child: Text(
                          //             lang.S.of(context).purchasePrice,
                          //             style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      ///_________Purchase_bord_____________________________________
                      ResponsiveGridRow(rowSegments: 100, children: [
                        //---------------product and calculation section--------------
                        ResponsiveGridCol(
                          lg: 47,
                          md: 100,
                          xs: 100,
                          child: IntrinsicWidth(
                            child: Container(
                              decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.all(Radius.circular(15))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Scrollbar(
                                    controller: _horizontalController,
                                    thumbVisibility: true,
                                    thickness: 6,
                                    child: LayoutBuilder(
                                      builder: (BuildContext context, BoxConstraints constraints) {
                                        final kWidth = constraints.maxWidth;
                                        return SingleChildScrollView(
                                          controller: _horizontalController,
                                          scrollDirection: Axis.horizontal,
                                          child: Container(
                                            height: context.height() < 720 ? 720 - 350 : context.height() - 350,
                                            constraints: BoxConstraints(
                                              minWidth: kWidth,
                                            ),
                                            decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: kGreyTextColor.withOpacity(0.3)))),
                                            child: Theme(
                                              data: theme.copyWith(
                                                dividerTheme: const DividerThemeData(color: Colors.transparent),
                                              ),
                                              child: DataTable(
                                                  border: const TableBorder(
                                                    horizontalInside: BorderSide(
                                                      width: 1,
                                                      color: kNeutral300,
                                                    ),
                                                  ),
                                                  dataRowColor: const WidgetStatePropertyAll(whiteColor),
                                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                                  showBottomBorder: false,
                                                  dividerThickness: 0.0,
                                                  headingTextStyle: theme.textTheme.titleMedium,
                                                  dataTextStyle: theme.textTheme.bodyLarge,
                                                  columns: [
                                                    DataColumn(label: Text(lang.S.of(context).productName)),
                                                    DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).quantity)),
                                                    DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).unit)),
                                                    DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).purchase)),
                                                    DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).total)),
                                                    DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).action)),
                                                  ],
                                                  rows: List.generate(cartList.length, (index) {
                                                    TextEditingController quantityController = TextEditingController(text: cartList[index].productStock.toString());
                                                    return DataRow(cells: [
                                                      //-------------name--------------------
                                                      DataCell(Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            cartList[index].productName,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(width: 5),

                                                          ///_________serial_edit_________________________________________________________
                                                          Row(
                                                            children: [
                                                              Text(
                                                                lang.S.of(context).editOrAddSerial,
                                                                maxLines: 1,
                                                                style: theme.textTheme.bodySmall,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(width: 5),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  productEditPopUp(product: cartList[index], index: index);
                                                                },
                                                                child: const Icon(
                                                                  Icons.edit_note,
                                                                  size: 18,
                                                                  color: kBlueTextColor,
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      )),
                                                      //-------------quantity------------------
                                                      DataCell(Center(
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  int stock = int.tryParse(cartList[index].productStock) ?? 1;
                                                                  if (stock > 1) {
                                                                    stock--;
                                                                  } else {
                                                                    stock = 1;
                                                                  }
                                                                  cartList[index].productStock = stock.toString();
                                                                  toast(cartList[index].productStock = stock.toString());
                                                                });
                                                              },
                                                              child: Icon(
                                                                FontAwesomeIcons.solidSquareMinus,
                                                                color: kBlueTextColor,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            SizedBox(
                                                              width: 70,
                                                              height: 32,
                                                              child: TextFormField(
                                                                textAlign: TextAlign.center,
                                                                controller: quantityController,
                                                                onChanged: (value) {
                                                                  if (value == '' || value == '0') {
                                                                    cartList[index].productStock = '1';
                                                                  } else {
                                                                    cartList[index].productStock = value;
                                                                  }
                                                                },
                                                                onFieldSubmitted: (value) {
                                                                  if (value == '' || value == '0') {
                                                                    setState(() {
                                                                      cartList[index].productStock = '1';
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      cartList[index].productStock = value;
                                                                    });
                                                                  }
                                                                },
                                                                decoration: kInputDecoration.copyWith(
                                                                  contentPadding: const EdgeInsets.all(4),
                                                                ),
                                                                inputFormatters: [
                                                                  FilteringTextInputFormatter.digitsOnly,
                                                                  LengthLimitingTextInputFormatter(6),
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 4,
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  int stock = int.tryParse(cartList[index].productStock) ?? 1;
                                                                  stock++;
                                                                  cartList[index].productStock = stock.toString();
                                                                  toast(cartList[index].productStock = stock.toString());
                                                                });
                                                              },
                                                              child: Icon(
                                                                FontAwesomeIcons.solidSquarePlus,
                                                                color: kBlueTextColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                      DataCell(
                                                        Center(
                                                          child: Text(
                                                            cartList[index].productUnit,
                                                          ),
                                                        ),
                                                      ),
                                                      //___________Purchase____________________________________________________
                                                      DataCell(
                                                        Center(
                                                          child: Text(
                                                            '$globalCurrency${myFormat.format(double.tryParse(double.parse(cartList[index].productPurchasePrice).toStringAsFixed(2)) ?? 0)}',
                                                          ),
                                                        ),
                                                      ),
                                                      //___________Total____________________________________________________
                                                      DataCell(
                                                        Center(
                                                          child: Text(
                                                            '$globalCurrency${myFormat.format(double.tryParse((double.parse(cartList[index].productPurchasePrice) * cartList[index].productStock.toInt()).toStringAsFixed(2)) ?? 0)}',
                                                          ),
                                                        ),
                                                      ),
                                                      //_______________actions_________________________________________________
                                                      DataCell(
                                                        Center(
                                                          child: const Icon(
                                                            Icons.close_sharp,
                                                            color: redColor,
                                                          ).onTap(() {
                                                            setState(() {
                                                              cartList.removeAt(index);
                                                            });
                                                          }),
                                                        ),
                                                      ),
                                                    ]);
                                                  })),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  //__________Subtotal_discount_buttons____________________________________________________
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: [
                                        ///__________subTotal_____________________________________________________
                                        ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: screenWidth < 1600 ? 4 : 6,
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
                                              lg: screenWidth < 1600 ? 8 : 6,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    lang.S.of(context).subTotal,
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: const BoxDecoration(color: kMainColor, borderRadius: BorderRadius.all(Radius.circular(8))),
                                                      child: Center(
                                                        child: Text(
                                                          "$globalCurrency ${myFormat.format(double.tryParse((getTotalAmount().toDouble() - discountAmount).toStringAsFixed(2)) ?? 0)}",
                                                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ]),
                                        const SizedBox(height: 10),

                                        ///________discount_________________________________________________
                                        ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: screenWidth < 1600 ? 4 : 6,
                                            child: const SizedBox.shrink(),
                                          ),
                                          ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: screenWidth < 1600 ? 8 : 6,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    lang.S.of(context).discount,
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          child: SizedBox(
                                                            // width: 100,
                                                            height: 40.0,
                                                            child: Center(
                                                              child: AppTextField(
                                                                controller: discountPercentageEditingController,
                                                                onChanged: (value) {
                                                                  if (value == '') {
                                                                    setState(() {
                                                                      percentage = 0.0;
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
                                                                textFieldType: TextFieldType.PHONE,
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
                                                                    child: const Text(
                                                                      '\$',
                                                                      style: TextStyle(fontSize: 20.0, color: Colors.white),
                                                                    ),
                                                                  ),
                                                                ),
                                                                textFieldType: TextFieldType.PHONE,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ]),

                                        ///______________buttons__________________________________________________________
                                        const SizedBox(height: 10),
                                        ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                          ResponsiveGridCol(
                                            lg: 6,
                                            md: 6,
                                            xs: 12,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
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
                                            ),
                                          ),
                                          ResponsiveGridCol(
                                              lg: 6,
                                              md: 6,
                                              xs: 12,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    if (await Subscription.subscriptionChecker(item: 'Purchase')) {
                                                      if (cartList.isEmpty) {
                                                        EasyLoading.showError('Please Add Some Product first');
                                                      } else {
                                                        PurchaseTransactionModel transitionModel = PurchaseTransactionModel(
                                                          customerAddress: selectedUserName.customerAddress,
                                                          customerName: selectedUserName.customerName,
                                                          customerGst: selectedUserName.gst,
                                                          customerType: selectedUserName.type,
                                                          customerPhone: selectedUserName.phoneNumber,
                                                          invoiceNumber: data.purchaseInvoiceCounter.toString(),
                                                          purchaseDate: DateTime.now().toString(),
                                                          productList: cartList,
                                                          discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
                                                          totalAmount: double.parse((getTotalAmount().toDouble() - discountAmount).toStringAsFixed(2)),
                                                        );
                                                        context.push(
                                                          '/purchase/purchase-payment-popup',
                                                          extra: {
                                                            'transitionModel': transitionModel,
                                                          },
                                                        );
                                                      }
                                                    } else {
                                                      EasyLoading.showError('Update your plan first\nPurchase Limit is over.');
                                                    }
                                                  },
                                                  child: Text(
                                                    lang.S.of(context).payment,
                                                  ),
                                                ),
                                              )),
                                        ]),
                                        // Row(
                                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        //   children: [
                                        //     ///_______cancel_button____________________________________________________
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
                                        //       child: Container(
                                        //         padding: const EdgeInsets.all(10.0),
                                        //         decoration: BoxDecoration(
                                        //           shape: BoxShape.rectangle,
                                        //           borderRadius: BorderRadius.circular(2.0),
                                        //           color: Colors.black,
                                        //         ),
                                        //         child: Text(
                                        //           lang.S.of(context).quotation,
                                        //           textAlign: TextAlign.center,
                                        //           style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                                        //         ),
                                        //       ),
                                        //     ).visible(false),
                                        //     const SizedBox(width: 10.0),
                                        //     Expanded(
                                        //         flex: 1,
                                        //         child: Container(
                                        //           padding: const EdgeInsets.all(10.0),
                                        //           decoration: BoxDecoration(
                                        //             shape: BoxShape.rectangle,
                                        //             borderRadius: BorderRadius.circular(2.0),
                                        //             color: Colors.yellow,
                                        //           ),
                                        //           child: Text(
                                        //             lang.S.of(context).hold,
                                        //             textAlign: TextAlign.center,
                                        //             style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                                        //           ),
                                        //         ).onTap(() => showHoldPopUp())).visible(false),
                                        //     const SizedBox(width: 10.0),
                                        //
                                        //     ///__________payment_button________________________________________________
                                        //     Expanded(
                                        //       flex: 1,
                                        //       child: Container(
                                        //         padding: const EdgeInsets.all(10.0),
                                        //         decoration: BoxDecoration(
                                        //           shape: BoxShape.rectangle,
                                        //           borderRadius: BorderRadius.circular(10.0),
                                        //           color: kBlueTextColor,
                                        //         ),
                                        //         child: Text(
                                        //           lang.S.of(context).payment,
                                        //           textAlign: TextAlign.center,
                                        //           style: kTextStyle.copyWith(color: kWhite, fontSize: 18.0, fontWeight: FontWeight.bold),
                                        //         ),
                                        //       ).onTap(
                                        //         () async {
                                        //           if (await Subscription.subscriptionChecker(item: 'Purchase')) {
                                        //             if (cartList.isEmpty) {
                                        //               EasyLoading.showError('Please Add Some Product first');
                                        //             } else {
                                        //               PurchaseTransactionModel transitionModel = PurchaseTransactionModel(
                                        //                 customerAddress: selectedUserName.customerAddress,
                                        //                 customerName: selectedUserName.customerName,
                                        //                 customerGst: selectedUserName.gst,
                                        //                 customerType: selectedUserName.type,
                                        //                 customerPhone: selectedUserName.phoneNumber,
                                        //                 invoiceNumber: data.purchaseInvoiceCounter.toString(),
                                        //                 purchaseDate: DateTime.now().toString(),
                                        //                 productList: cartList,
                                        //                 discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
                                        //                 totalAmount: double.parse((getTotalAmount().toDouble() - discountAmount).toStringAsFixed(2)),
                                        //               );
                                        //               PurchaseShowPaymentPopUp(
                                        //                 transitionModel: transitionModel,
                                        //               ).launch(context);
                                        //             }
                                        //           } else {
                                        //             EasyLoading.showError('Update your plan first\nPurchase Limit is over.');
                                        //           }
                                        //         },
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
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
                                                    'Categories',
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
                                                  padding: EdgeInsets.only(top: 5, bottom: 5, right: screenWidth < 1240 ? 10 : 0),
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
                        //------------product list-------------------------
                        ResponsiveGridCol(
                          lg: 39,
                          md: 100,
                          xs: 100,
                          child: productList.when(data: (products) {
                            List<ProductModel> showProductVsCategory = [];
                            if (selectedCategory == 'Categories') {
                              for (var element in products) {
                                if ((element.productCode.toLowerCase().contains(searchProductCode) || element.productCategory.toLowerCase().contains(searchProductCode) || element.productName.toLowerCase().contains(searchProductCode)) && (selectedWareHouse?.id == element.warehouseId)) {
                                  showProductVsCategory.add(element);
                                }
                              }
                            } else {
                              for (var element in products) {
                                if ((element.productCategory == selectedCategory) && (selectedWareHouse?.id == element.warehouseId)) {
                                  showProductVsCategory.add(element);
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
                                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 180,
                                        mainAxisExtent: 200,
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
                                              ///_______image_and_stock_____________________________________
                                              Stack(
                                                alignment: Alignment.topLeft,
                                                children: [
                                                  //________image___________________________________________
                                                  Container(
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
                                                      image: DecorationImage(image: NetworkImage(showProductVsCategory[i].productPicture), fit: BoxFit.cover),
                                                    ),
                                                  ),

                                                  ///_______stock________________________________________________
                                                  Positioned(
                                                    left: 5,
                                                    top: 5,
                                                    child: Container(
                                                      padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2, bottom: 2),
                                                      decoration: BoxDecoration(
                                                        color: showProductVsCategory[i].productStock == '0' ? kRedTextColor : kGreenTextColor,
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        showProductVsCategory[i].productStock != '0' ? '${showProductVsCategory[i].productStock} pcs' : 'Out of stock',
                                                        style: theme.textTheme.titleSmall?.copyWith(
                                                          color: Colors.white,
                                                        ),
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
                                                    ///_______________product_name______________________________________________
                                                    Text(
                                                      showProductVsCategory[i].productName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 4.0),

                                                    ///________Purchase_price_________________________________________________
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(color: kGreenTextColor, borderRadius: BorderRadius.circular(2.0)),
                                                      child: Text(
                                                        '$globalCurrency${myFormat.format(double.tryParse(showProductVsCategory[i].productPurchasePrice) ?? 0)}',
                                                        style: theme.textTheme.titleSmall?.copyWith(
                                                          color: kWhite,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).onTap(() {
                                          setState(() {
                                            ProductModel product = ProductModel(
                                              showProductVsCategory[i].productName,
                                              showProductVsCategory[i].productCategory,
                                              showProductVsCategory[i].size,
                                              showProductVsCategory[i].color,
                                              showProductVsCategory[i].weight,
                                              showProductVsCategory[i].capacity,
                                              showProductVsCategory[i].type,
                                              showProductVsCategory[i].warranty,
                                              showProductVsCategory[i].brandName,
                                              showProductVsCategory[i].productCode,
                                              '1',
                                              showProductVsCategory[i].productUnit,
                                              showProductVsCategory[i].productSalePrice,
                                              showProductVsCategory[i].productPurchasePrice,
                                              showProductVsCategory[i].productDiscount,
                                              showProductVsCategory[i].productWholeSalePrice,
                                              showProductVsCategory[i].productDealerPrice,
                                              showProductVsCategory[i].productManufacturer,
                                              showProductVsCategory[i].warehouseName,
                                              showProductVsCategory[i].warehouseId,
                                              showProductVsCategory[i].productPicture,
                                              [],
                                              manufacturingDate: showProductVsCategory[i].manufacturingDate,
                                              lowerStockAlert: showProductVsCategory[i].lowerStockAlert,
                                              expiringDate: showProductVsCategory[i].expiringDate,
                                              taxType: showProductVsCategory[i].taxType,
                                              margin: showProductVsCategory[i].margin,
                                              excTax: showProductVsCategory[i].excTax,
                                              incTax: showProductVsCategory[i].incTax,
                                              groupTaxName: showProductVsCategory[i].groupTaxName,
                                              groupTaxRate: showProductVsCategory[i].groupTaxRate,
                                              subTaxes: showProductVsCategory[i].subTaxes,
                                              // showProductVsCategory[i].serialNumber.isEmpty ? [] : showProductVsCategory[i].serialNumber,
                                            );

                                            if (!uniqueCheck(product.productCode)) {
                                              cartList.add(product);
                                            }
                                          });
                                        });
                                      },
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
                                        ElevatedButton(
                                          onPressed: () {
                                            context.push(
                                              '/product/add-product',
                                              extra: {
                                                'allProductsCodeList': allProductsCodeList,
                                                'warehouseBasedProductModel': [],
                                              },
                                            );
                                          },
                                          child: Text(
                                            lang.S.of(context).addProduct,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
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
                      ]),
                    ],
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
}
