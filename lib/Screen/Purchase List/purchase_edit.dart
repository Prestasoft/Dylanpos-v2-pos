import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../model/category_model.dart';
import '../../model/customer_model.dart';
import '../../model/personal_information_model.dart';
import '../../model/product_model.dart';
import '../../model/purchase_transation_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Calculator/calculator.dart';
import '../Widgets/Pop UP/Pos Sale/due_sale_popup.dart';
import '../Widgets/Pop UP/Pos Sale/sale_list_popup.dart';
import 'show_payment_popup.dart';

class PurchaseEdit extends StatefulWidget {
  const PurchaseEdit({
    Key? key,
    required this.personalInformationModel,
    required this.isPosScreen,
    required this.purchaseTransitionModel,
    required this.popupContext,
  }) : super(key: key);

  final PurchaseTransactionModel purchaseTransitionModel;
  final PersonalInformationModel personalInformationModel;
  final bool isPosScreen;
  final BuildContext popupContext;

  static const String route = '/purchaseEdit';

  @override
  State<PurchaseEdit> createState() => _PurchaseEditState();
}

class _PurchaseEditState extends State<PurchaseEdit> {
  List<ProductModel> cartList = [];
  List<ProductModel> pastProducts = [];
  List<ProductModel> increaseStockList = [];

  bool isChecked = true;

  String isSelected = 'Categories';
  String? selectedUserId;
  String? invoiceNumber;
  String previousDue = "0";
  FocusNode nameFocus = FocusNode();

  List<SaleTransactionModel> filteredData = [];
  SaleTransactionModel? dueTransactionModel;
  List<CustomerModel> customerLists = [];

  String searchProductCode = '';
  String selectedCategory = 'Categories';

  String selectedUser = 'Name  Phone  Due';

  String getTotalAmount() {
    double total = 0.0;
    for (var item in cartList) {
      total = total + (double.parse(item.productPurchasePrice) * item.productStock.toInt());
    }
    return total.toString();
  }

  bool uniqueCheck(String code) {
    bool isUnique = false;
    for (var item in cartList) {
      if (item.productCode == code) {
        item.productStock = (int.parse(item.productStock) + 1).toString();
        isUnique = true;
        break;
      }
    }
    return isUnique;
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

  List<ProductModel> allProduct = [];

  TextEditingController nameCodeCategoryController = TextEditingController();
  bool doNotCheckProducts = false;
  bool isGuestCustomer = false;

  void productEditPopUp({required ProductModel product, required int index}) {
    FocusNode serialFocus = FocusNode();
    String editedPurchasePrice = '';
    String editedSalePrice = '';
    String editDealerPrice = '';
    String editWholesalerPrice = '';
    List<String> serialNumberList = [];
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

    bool isWantToAddSerial = false;
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
                                          //return 'Please enter Purchase Price';
                                          return lang.S.of(context).pleaseEnterPurchasePrice;
                                        } else if (double.tryParse(value!) == null && !value.isEmptyOrNull) {
                                          return '${lang.S.of(context).enterPriceInNumber}.';
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
                                          return lang.S.of(context).pleaseEnterSalePrice;
                                        } else if (double.tryParse(value!) == null && !value.isEmptyOrNull) {
                                          return '${lang.S.of(context).enterPriceInNumber}.';
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
                                        labelText: lang.S.of(context).salePrice,
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
                                        hintText: lang.S.of(context).enterWholeSalePrice,
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
                                    EasyLoading.showError(lang.S.of(context).alreadyAdded);
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
                                        return Text(lang.S.of(context).nosSerialNumberFound);
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
                              // context.pop();
                              GoRouter.of(context).pop();
                            }),
                            const SizedBox(width: 10.0),
                            GestureDetector(
                              onTap: () {
                                if (validateAndSave()) {
                                  cartList[index].serialNumber = serialNumberList;
                                  cartList[index].productPurchasePrice = editedPurchasePrice.toString();
                                  cartList[index].productSalePrice = editedSalePrice.toString();
                                  cartList[index].productDealerPrice = editDealerPrice.toString();
                                  cartList[index].productWholeSalePrice = editWholesalerPrice.toString();
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    pastProducts = widget.purchaseTransitionModel.productList!;
    discountAmountEditingController.text = widget.purchaseTransitionModel.discountAmount.toString();
    discountAmount = widget.purchaseTransitionModel.discountAmount!;
    discountPercentageEditingController.text = ((discountAmount * 100) / widget.purchaseTransitionModel.totalAmount!.toDouble()).toStringAsFixed(1);
  }

  final ScrollController mainSideScroller = ScrollController();
  final ScrollController sideScroller = ScrollController();

  TextEditingController qtyController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController discountPercentageEditingController = TextEditingController();
  TextEditingController discountAmountEditingController = TextEditingController();
  double discountAmount = 0;
  double percentage = 0;

  final _horizontalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, consumerRef, __) {
        final personalData = consumerRef.watch(profileDetailsProvider);
        final productLists = consumerRef.watch(productProvider);
        AsyncValue<List<ProductModel>> productList = consumerRef.watch(productProvider);
        if (!doNotCheckProducts) {
          List<ProductModel> list = [];
          productLists.value?.forEach((products) {
            widget.purchaseTransitionModel.productList?.forEach((element) {
              if (element.productCode == products.productCode) {
                list.add(element);
              }
            });

            if (widget.purchaseTransitionModel.productList?.length == list.length) {
              cartList = list;
              doNotCheckProducts = true;
            }
          });
        }

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
                        ///__________header_____________________________________________
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: ResponsiveGridRow(rowSegments: 120, children: [
                            //-------------------date--------------------------
                            ResponsiveGridCol(
                                xs: screenWidth > 450 ? 60 : 120,
                                md: 40,
                                lg: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: GestureDetector(
                                    onTap: () => _selectedDueDate(context),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 40,
                                      width: screenWidth,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: kNeutral400),
                                      ),
                                      padding: const EdgeInsets.all(10.0),
                                      child: Center(
                                        child: Text(
                                          widget.purchaseTransitionModel.purchaseDate.substring(0, 10),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: kNeutral700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                            //-------------------due amount---------------------
                            ResponsiveGridCol(
                                xs: screenWidth > 450 ? 60 : 120,
                                md: 40,
                                lg: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(children: [
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
                                            widget.purchaseTransitionModel.dueAmount.toString(),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: kNeutral700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                )),
                            //----------------calculator------------------------
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
                                        child: GestureDetector(
                                          onTap: () => showCalcPopUp(),
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
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            //----------------dashboard-----------------------
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
                            //-----------------company section------------
                            ResponsiveGridCol(
                              xs: 60,
                              md: 40,
                              lg: 30,
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FeatherIcons.user,
                                        color: kTitleColor,
                                        size: 18.0,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Flexible(
                                        child: Text(
                                          '${lang.S.of(context).welcome} ${data.companyName.toString()}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            //------------invoice number---------------
                            ResponsiveGridCol(
                                xs: 60,
                                md: 40,
                                lg: 20,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
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
                                            "#${widget.purchaseTransitionModel.invoiceNumber}",
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
                            //_____________Customer_name__________________________________
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 40,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  height: 40,
                                  width: screenWidth,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                                    border: Border.all(color: kNeutral400),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.purchaseTransitionModel.customerName,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            //___________product_search_________________________________
                            ResponsiveGridCol(
                              xs: 120,
                              md: 60,
                              lg: 30,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
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
                                            EasyLoading.showError(lang.S.of(context).noProductFound);
                                          }
                                          for (int i = 0; i < product.length; i++) {
                                            if (product[i].productCode == value) {
                                              ProductModel cartProduct = product[i];
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
                                              EasyLoading.showError(lang.S.of(context).notFound);
                                              setState(() {
                                                searchProductCode = '';
                                              });
                                            }
                                          }
                                        }
                                      },
                                      keyboardType: TextInputType.name,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(8),
                                        prefixIcon: Icon(MdiIcons.barcode, color: kTitleColor, size: 18.0),
                                        hintText: lang.S.of(context).nameCodeOrCateogry,
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
                          ]),
                        ),
                        const SizedBox(height: 20.0),

                        ///_________Purchase_bord_____________________________________
                        ResponsiveGridRow(rowSegments: 100, children: [
                          ///_____Cart_show_And_button_show____________________________
                          ResponsiveGridCol(
                            lg: 47,
                            md: 100,
                            xs: 100,
                            child: IntrinsicWidth(
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
                                    LayoutBuilder(
                                      builder: (BuildContext context, BoxConstraints constraints) {
                                        final kWidth = constraints.maxWidth;
                                        return Scrollbar(
                                          controller: _horizontalController,
                                          thumbVisibility: true,
                                          thickness: 6,
                                          child: SingleChildScrollView(
                                            controller: _horizontalController,
                                            scrollDirection: Axis.horizontal,
                                            child: Container(
                                              constraints: BoxConstraints(
                                                minWidth: kWidth,
                                              ),
                                              height: context.height() < 720 ? 720 - 350 : context.height() - 350,
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
                                                      DataColumn(label: Text(lang.S.of(context).quantity)),
                                                      DataColumn(label: Text(lang.S.of(context).unit)),
                                                      DataColumn(label: Text(lang.S.of(context).purchase)),
                                                      DataColumn(label: Text(lang.S.of(context).total)),
                                                      DataColumn(label: Text(lang.S.of(context).action)),
                                                    ],
                                                    rows: List.generate(cartList.length, (index) {
                                                      int i = 0;
                                                      for (var element in pastProducts) {
                                                        if (element.productCode != cartList[index].productCode) {
                                                          i++;
                                                        }
                                                        if (i == pastProducts.length) {
                                                          bool isInTheList = false;
                                                          for (var element in increaseStockList) {
                                                            if (element.productCode == cartList[index].productCode) {
                                                              element.productStock = cartList[index].productStock;
                                                              isInTheList = true;
                                                              break;
                                                            }
                                                          }

                                                          isInTheList ? null : increaseStockList.add(cartList[index]);
                                                        }
                                                      }
                                                      TextEditingController quantityController = TextEditingController(text: cartList[index].productStock.toString());
                                                      return DataRow(cells: [
                                                        ///______________name__________________________________________________
                                                        DataCell(
                                                          Text(
                                                            cartList[index].productName,
                                                          ),
                                                        ),

                                                        ///____________quantity_________________________________________________
                                                        DataCell(
                                                          SizedBox(
                                                            height: 35,
                                                            child: TextFormField(
                                                              textAlign: TextAlign.center,
                                                              maxLines: 1,
                                                              showCursor: true,
                                                              cursorColor: kTitleColor,
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
                                                              decoration: kInputDecoration.copyWith(),
                                                              inputFormatters: [
                                                                FilteringTextInputFormatter.digitsOnly,
                                                                LengthLimitingTextInputFormatter(6),
                                                              ],
                                                            ),
                                                          ),
                                                        ),

                                                        ///______Unit___________________________________________________________
                                                        DataCell(
                                                          Text(
                                                            cartList[index].productUnit,
                                                          ),
                                                        ),

                                                        ///___________Purchase____________________________________________________
                                                        DataCell(
                                                          Text(
                                                            cartList[index].productPurchasePrice,
                                                          ),
                                                        ),

                                                        ///___________Total____________________________________________________
                                                        DataCell(
                                                          Text(
                                                            (double.parse(cartList[index].productPurchasePrice) * cartList[index].productStock.toInt()).toString(),
                                                          ),
                                                        ),

                                                        ///_______________actions_________________________________________________
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
                                          ),
                                        );
                                      },
                                    ),

                                    ///__________price_section & buttons
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        children: [
                                          //---------------price section-----------------
                                          ResponsiveGridRow(children: [
                                            //----------total item-------------------
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: screenWidth < 1600 ? 4 : 6,
                                              child: Padding(
                                                padding: EdgeInsets.only(bottom: screenWidth < 577 ? 12 : 0),
                                                child: Text(
                                                  '${lang.S.of(context).totalItem}: ${cartList.length}',
                                                  style: theme.textTheme.titleMedium,
                                                ),
                                              ),
                                            ),
                                            //-------------------subtotal--------------------------
                                            ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: screenWidth < 1600 ? 8 : 6,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    lang.S.of(context).subTotal,
                                                    style: theme.textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: const BoxDecoration(color: kMainColor, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                      child: Center(
                                                        child: Text(
                                                          (getTotalAmount().toDouble() - discountAmount).toString(),
                                                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]),
                                          const SizedBox(height: 10),
                                          //-----------discount----------------------
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
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      lang.S.of(context).discount,
                                                      style: theme.textTheme.titleMedium,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Row(
                                                        children: [
                                                          Flexible(
                                                            child: SizedBox(
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
                                                                        EasyLoading.showError(lang.S.of(context).enterAValidDiscount);
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
                                                          const SizedBox(width: 4.0),
                                                          Flexible(
                                                            child: SizedBox(
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
                                                                        EasyLoading.showError(lang.S.of(context).enterAValidDiscount);
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
                                                ))
                                          ]),
                                          const SizedBox(height: 10),

                                          ///__________buttons_____________________________________________
                                          ResponsiveGridRow(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
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
                                                      if (cartList.isEmpty) {
                                                        EasyLoading.showError(lang.S.of(context).pleaseAddSomeProductFirst);
                                                      } else {
                                                        PurchaseTransactionModel purchaseTransitionModel = PurchaseTransactionModel(
                                                          customerName: widget.purchaseTransitionModel.customerName,
                                                          customerAddress: widget.purchaseTransitionModel.customerAddress,
                                                          customerType: widget.purchaseTransitionModel.customerType,
                                                          customerPhone: widget.purchaseTransitionModel.customerPhone,
                                                          invoiceNumber: widget.purchaseTransitionModel.invoiceNumber,
                                                          customerGst: widget.purchaseTransitionModel.customerGst,
                                                          discountAmount: discountAmount,
                                                          isPaid: true,
                                                          paymentType: 'cash',
                                                          returnAmount: 0,
                                                          dueAmount: widget.purchaseTransitionModel.dueAmount,
                                                          purchaseDate: widget.purchaseTransitionModel.purchaseDate,
                                                          totalAmount: getTotalAmount().toDouble() - discountAmount,
                                                          productList: cartList,
                                                        );
                                                        ShowEditPurchasePaymentPopUp(
                                                          purchaseTransitionModel: purchaseTransitionModel,
                                                          increaseStockList: increaseStockList,
                                                          saleListPopUpContext: widget.popupContext,
                                                          previousPaid: widget.purchaseTransitionModel.totalAmount! - widget.purchaseTransitionModel.dueAmount!.toDouble(),
                                                        ).launch(context);
                                                      }
                                                    },
                                                    child: Text(
                                                      lang.S.of(context).payment,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          ///_________selected_category_____________________________________
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
                                      decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.all(Radius.circular(15))),
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

                          ///_____________products_show____________________________
                          ResponsiveGridCol(
                              lg: 39,
                              md: 100,
                              xs: 100,
                              child: Consumer(
                                builder: (_, ref, watch) {
                                  AsyncValue<List<ProductModel>> productList = ref.watch(productProvider);
                                  return productList.when(data: (products) {
                                    List<ProductModel> showProductVsCategory = [];
                                    if (selectedCategory == 'Categories') {
                                      for (var element in products) {
                                        if (element.productCode.toLowerCase().contains(searchProductCode) || element.productCategory.toLowerCase().contains(searchProductCode) || element.productName.toLowerCase().contains(searchProductCode)) {
                                          showProductVsCategory.add(element);
                                        }
                                      }
                                    } else {
                                      for (var element in products) {
                                        if (element.productCategory == selectedCategory) {
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
                                                mainAxisExtent: 190,
                                                mainAxisSpacing: 10,
                                                crossAxisSpacing: 10,
                                              ),
                                              itemCount: showProductVsCategory.length,
                                              itemBuilder: (_, i) {
                                                return Container(
                                                  width: 130.0,
                                                  height: 165.0,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10.0),
                                                    color: kWhite,
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
                                                              image: DecorationImage(
                                                                image: NetworkImage(showProductVsCategory[i].productPicture),
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),

                                                          ///_______stock________________________________________________
                                                          Positioned(
                                                            left: 5,
                                                            top: 5,
                                                            child: Container(
                                                              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                                                              decoration: BoxDecoration(color: showProductVsCategory[i].productStock == '0' ? kRedTextColor : kGreenTextColor),
                                                              child: Text(
                                                                showProductVsCategory[i].productStock != '0' ? '${showProductVsCategory[i].productStock} pc' : lang.S.of(context).outOfStock,
                                                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(10.0),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              showProductVsCategory[i].productName,
                                                              style: theme.textTheme.titleMedium,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 4.0),
                                                            Container(
                                                              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                                                              decoration: BoxDecoration(color: kGreenTextColor, borderRadius: BorderRadius.circular(2.0)),
                                                              child: Text(
                                                                showProductVsCategory[i].productPurchasePrice,
                                                                style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
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
                                                      showProductVsCategory[i].serialNumber.isEmpty ? [] : showProductVsCategory[i].serialNumber,
                                                      manufacturingDate: showProductVsCategory[i].manufacturingDate,
                                                      lowerStockAlert: showProductVsCategory[i].lowerStockAlert,
                                                      expiringDate: showProductVsCategory[i].expiringDate,
                                                      taxType: '',
                                                      margin: 0,
                                                      excTax: 0,
                                                      incTax: 0,
                                                      groupTaxName: '',
                                                      groupTaxRate: 0,
                                                      subTaxes: [],
                                                      //  taxType: selectedTaxType,
                                                      //           margin: num.tryParse(marginController.text) ?? 0,
                                                      //           excTax: num.tryParse(excTaxAmount) ?? 0,
                                                      //           incTax: num.tryParse(incTaxAmount) ?? 0,
                                                      //           groupTaxName: selectedGroupTaxModel?.name ?? '',
                                                      //           groupTaxRate: selectedGroupTaxModel?.taxRate ?? 0,
                                                      //           subTaxes: selectedGroupTaxModel?.subTaxes ?? [],
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
                                            // height: context.height() < 720 ? 720 - 136 : context.height() - 136,
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
                                                  onTap: () {},
                                                  child: Container(
                                                    decoration: const BoxDecoration(color: kBlueTextColor, borderRadius: BorderRadius.all(Radius.circular(15))),
                                                    width: 200,
                                                    child: Center(
                                                      child: Padding(
                                                        padding: EdgeInsets.all(20.0),
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
                                  });
                                },
                              ))
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
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
