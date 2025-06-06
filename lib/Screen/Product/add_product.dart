// ignore_for_file: unused_result, use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Widgets/dotted_border/dotted_border.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/category_model.dart';
import 'package:salespro_admin/model/unit_model.dart';

import '../../Provider/product_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/brands_model.dart';
import '../../model/product_model.dart';
import '../../subscription.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../tax rates/tax_model.dart';
import 'WarebasedProduct.dart';

class AddProduct extends StatefulWidget {
  const AddProduct(
      {super.key,
      required this.allProductsCodeList,
      required this.warehouseBasedProductModel});

  final List<WarehouseBasedProductModel> warehouseBasedProductModel;
  final List<String> allProductsCodeList;

  // final bool inventorySales;

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  bool checkProductName({required String name, required String id}) {
    for (var element in widget.warehouseBasedProductModel) {
      print('name: ${element.productName}, id: ${element.productID}');
      if (element.productName.toLowerCase() == name.toLowerCase() &&
          element.productID == id) {
        return false;
      }
    }

    return true;
  }

  List<String> allNameInThisFile = [];
  List<String> allCodeInThisFile = [];
  List<String> allCategory = [];
  bool isSize = false;
  bool isColor = false;
  bool isWeight = false;
  bool isCapacity = false;
  bool isType = false;
  bool isWarranty = false;
  bool isSizedBoxShow = false;
  bool isColoredBoxShow = false;
  bool isWeightsBoxShow = false;
  bool isWarrantyBoxShow = false;
  bool isCapacityBoxShow = false;
  bool isTypeBoxShow = false;
  int brandTime = 0;
  int unitTime = 0;
  int categoryTime = 0;
  TextEditingController expireDateTextEditingController =
      TextEditingController();
  TextEditingController manufactureDateTextEditingController =
      TextEditingController();
  int lowerStockAlert = 5;
  String? expireDate;
  String? manufactureDate;
  String selectedType = 'product'; // <<<<<< NUEVO aquí

  List<String> productSerialNumberList = [];
  bool saleButtonClicked = false;

  Future<void> addCategoryShowPopUp(
      {required WidgetRef ref,
      required List<String> categoryNameList,
      required BuildContext addProductContext}) async {
    GlobalKey<FormState> categoryNameKey = GlobalKey<FormState>();
    bool categoryValidateAndSave() {
      final form = categoryNameKey.currentState;
      if (form!.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    showDialog(
        barrierDismissible: false,
        context: addProductContext,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState1) {
            return Dialog(
              surfaceTintColor: kWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              child: SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration:
                                const BoxDecoration(shape: BoxShape.rectangle),
                            child: const Icon(
                              FeatherIcons.plus,
                              color: kTitleColor,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            lang.S.of(context).addItemCategory,
                            style: kTextStyle.copyWith(
                                color: kTitleColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(
                            FeatherIcons.x,
                            color: kTitleColor,
                            size: 21.0,
                          ).onTap(() {
                            itemCategoryController.clear();
                            isSize = false;
                            isColor = false;
                            isWeight = false;
                            isCapacity = false;
                            isType = false;
                            isWarranty = false;
                            finish(context);
                          })
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Text(
                            lang.S.of(context).categoryName,
                            style: kTextStyle.copyWith(
                                color: kTitleColor, fontSize: 18.0),
                          ),
                          const SizedBox(width: 20),
                          Form(
                            key: categoryNameKey,
                            child: SizedBox(
                              width: 400,
                              child: TextFormField(
                                controller: itemCategoryController,
                                validator: (value) {
                                  if (value.isEmptyOrNull) {
                                    return 'Category name is required.';
                                  } else if (categoryNameList.contains(value
                                      .removeAllWhiteSpace()
                                      .toLowerCase())) {
                                    return 'Category name is already exist.';
                                  } else {
                                    return null;
                                  }
                                },
                                showCursor: true,
                                cursorColor: kTitleColor,
                                decoration: kInputDecoration.copyWith(
                                  errorBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.red)),
                                  labelText: lang.S.of(context).categoryName,
                                  hintText:
                                      lang.S.of(context).enterCategoryName,
                                  hintStyle: kTextStyle.copyWith(
                                      color: kGreyTextColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30.0),
                      Text(
                        lang.S.of(context).selectVariations,
                        style: kTextStyle.copyWith(
                            color: kTitleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                value: isSize,
                                onChanged: (val) {
                                  setState1(
                                    () {
                                      isSize = val!;
                                    },
                                  );
                                },
                              ),
                              title: Text(lang.S.of(context).size),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                value: isColor,
                                onChanged: (val) {
                                  setState1(() {
                                    isColor = val!;
                                  });
                                },
                              ),
                              title: Text(lang.S.of(context).color),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                value: isWeight,
                                onChanged: (val) {
                                  setState1(() {
                                    isWeight = val!;
                                  });
                                },
                              ),
                              title: Text(lang.S.of(context).wight),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                value: isCapacity,
                                onChanged: (val) {
                                  setState1(
                                    () {
                                      isCapacity = val!;
                                    },
                                  );
                                },
                              ),
                              title: Text(lang.S.of(context).capacity),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                value: isType,
                                onChanged: (val) {
                                  setState1(
                                    () {
                                      isType = val!;
                                    },
                                  );
                                },
                              ),
                              title: Text(lang.S.of(context).type),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                value: isWarranty,
                                onChanged: (val) {
                                  setState1(
                                    () {
                                      isWarranty = val!;
                                    },
                                  );
                                },
                              ),
                              title: Text(lang.S.of(context).warranty),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kRedTextColor),
                            child: Text(
                              lang.S.of(context).cancel,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() {
                            itemCategoryController.clear();
                            isSize = false;
                            isColor = false;
                            isWeight = false;
                            isCapacity = false;
                            isType = false;
                            isWarranty = false;

                            finish(context);
                          }),
                          const SizedBox(width: 5.0),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kGreenTextColor),
                            child: Text(
                              lang.S.of(context).submit,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() async {
                            if (categoryValidateAndSave()) {
                              EasyLoading.show(status: 'Adding Category');
                              try {
                                final DatabaseReference categoryInformationRef =
                                    FirebaseDatabase.instance
                                        .ref()
                                        .child(await getUserID())
                                        .child('Categories');
                                CategoryModel categoryModel = CategoryModel(
                                  categoryName: itemCategoryController.text,
                                  size: isSize,
                                  color: isColor,
                                  capacity: isCapacity,
                                  type: isType,
                                  weight: isWeight,
                                  warranty: isWarranty,
                                );

                                await categoryInformationRef
                                    .push()
                                    .set(categoryModel.toJson());
                                ref.refresh(categoryProvider);

                                setState1(() {
                                  // selectedCategories = categoryModel.categoryName;
                                  isSizedBoxShow = isSize;
                                  isColoredBoxShow = isColor;
                                  isWeightsBoxShow = isWeight;
                                  isCapacityBoxShow = isCapacity;
                                  isTypeBoxShow = isType;
                                  isWarrantyBoxShow = isWarranty;
                                });

                                itemCategoryController.clear();
                                isSize = false;
                                isColor = false;
                                isWeight = false;
                                isCapacity = false;
                                isType = false;
                                isWarranty = false;
                                EasyLoading.showSuccess("Successfully Added");

                                finish(context);
                              } catch (e) {
                                EasyLoading.showError('Error');
                              }
                            }
                          })
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  Future<void> showBrandPopUp(
      {required WidgetRef ref,
      required List<String> brandNameList,
      required BuildContext addProductsContext}) async {
    GlobalKey<FormState> brandNameKey = GlobalKey<FormState>();
    bool brandValidateAndSave() {
      final form = brandNameKey.currentState;
      if (form!.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    showDialog(
        barrierDismissible: false,
        context: addProductsContext,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              surfaceTintColor: kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration:
                                const BoxDecoration(shape: BoxShape.rectangle),
                            child: const Icon(
                              FeatherIcons.plus,
                              color: kTitleColor,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            lang.S.of(context).addBrand,
                            style: kTextStyle.copyWith(
                                color: kTitleColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(
                            FeatherIcons.x,
                            color: kTitleColor,
                            size: 21.0,
                          ).onTap(() {
                            brandNameController.clear();
                            finish(context);
                          })
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Text(
                            lang.S.of(context).brandName,
                            style: kTextStyle.copyWith(
                                color: kTitleColor, fontSize: 18.0),
                          ),
                          const SizedBox(width: 50),
                          Form(
                            key: brandNameKey,
                            child: SizedBox(
                              width: 400,
                              child: TextFormField(
                                validator: (value) {
                                  if (value.isEmptyOrNull) {
                                    return 'Brand name is required.';
                                  } else if (brandNameList.contains(value
                                      .removeAllWhiteSpace()
                                      .toLowerCase())) {
                                    return 'Brand name is already exist.';
                                  } else {
                                    return null;
                                  }
                                },
                                controller: brandNameController,
                                showCursor: true,
                                cursorColor: kTitleColor,
                                decoration: kInputDecoration.copyWith(
                                  errorBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.red)),
                                  labelText: lang.S.of(context).brandName,
                                  hintText: lang.S.of(context).enterBrandName,
                                  hintStyle: kTextStyle.copyWith(
                                      color: kGreyTextColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kRedTextColor),
                            child: Text(
                              lang.S.of(context).cancel,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() {
                            brandNameController.clear();
                            finish(context);
                          }),
                          const SizedBox(
                            width: 5.0,
                          ),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kGreenTextColor),
                            child: Text(
                              lang.S.of(context).submit,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() async {
                            if (brandValidateAndSave()) {
                              try {
                                EasyLoading.show(status: 'Adding Brand');
                                final DatabaseReference categoryInformationRef =
                                    FirebaseDatabase.instance
                                        .ref()
                                        .child(await getUserID())
                                        .child('Brands');
                                BrandsModel brandModel = BrandsModel(
                                    brandName: brandNameController.text);
                                await categoryInformationRef
                                    .push()
                                    .set(brandModel.toJson());
                                ref.refresh(brandProvider);
                                setState(() {
                                  // selectedBrand = brandModel.brandName;
                                  // brandName.clear();
                                });
                                brandNameController.clear();
                                EasyLoading.showSuccess("Successfully Added");
                                finish(context);
                              } catch (e) {
                                EasyLoading.showError('Error');
                              }
                            }
                          })
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  void showUnitPopUp(
      {required WidgetRef ref,
      required List<String> unitNameList,
      required BuildContext addProductsContext}) {
    GlobalKey<FormState> unitNameKey = GlobalKey<FormState>();
    bool unitValidateAndSave() {
      final form = unitNameKey.currentState;
      if (form!.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    showDialog(
        barrierDismissible: true,
        context: addProductsContext,
        builder: (BuildContext context) {
          return Dialog(
            surfaceTintColor: kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: SizedBox(
              width: 600,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration:
                              const BoxDecoration(shape: BoxShape.rectangle),
                          child: const Icon(
                            FeatherIcons.plus,
                            color: kTitleColor,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          lang.S.of(context).addUnit,
                          style: kTextStyle.copyWith(
                              color: kTitleColor,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        const Icon(
                          FeatherIcons.x,
                          color: kTitleColor,
                          size: 21.0,
                        ).onTap(() {
                          unitNameController.clear();
                          descriptionController.clear();
                          finish(context);
                        })
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Divider(
                      thickness: 1.0,
                      color: kGreyTextColor.withOpacity(0.2),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Text(
                          lang.S.of(context).unitName,
                          style: kTextStyle.copyWith(
                              color: kTitleColor, fontSize: 18.0),
                        ),
                        const SizedBox(width: 50),
                        Form(
                          key: unitNameKey,
                          child: SizedBox(
                            width: 400,
                            child: TextFormField(
                              validator: (value) {
                                if (value.isEmptyOrNull) {
                                  return 'Unit name is required.';
                                } else if (unitNameList.contains(value
                                    .removeAllWhiteSpace()
                                    .toLowerCase())) {
                                  return 'Unit name is already exist.';
                                } else {
                                  return null;
                                }
                              },
                              controller: unitNameController,
                              showCursor: true,
                              cursorColor: kTitleColor,
                              decoration: kInputDecoration.copyWith(
                                errorBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red)),
                                labelText: lang.S.of(context).unitName,
                                hintText: lang.S.of(context).enterUnitName,
                                hintStyle:
                                    kTextStyle.copyWith(color: kGreyTextColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Divider(
                      thickness: 1.0,
                      color: kGreyTextColor.withOpacity(0.2),
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              color: kRedTextColor),
                          child: Text(
                            lang.S.of(context).cancel,
                            style: kTextStyle.copyWith(color: kWhite),
                          ),
                        ).onTap(() {
                          unitNameController.clear();
                          finish(context);
                        }),
                        const SizedBox(width: 5.0),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              color: kGreenTextColor),
                          child: Text(
                            lang.S.of(context).submit,
                            style: kTextStyle.copyWith(color: kWhite),
                          ),
                        ).onTap(() async {
                          if (unitValidateAndSave()) {
                            try {
                              EasyLoading.show(status: 'Adding Units');
                              final DatabaseReference categoryInformationRef =
                                  FirebaseDatabase.instance
                                      .ref()
                                      .child(await getUserID())
                                      .child('Units');
                              UnitModel unitModel =
                                  UnitModel(unitNameController.text);
                              await categoryInformationRef
                                  .push()
                                  .set(unitModel.toJson());
                              ref.refresh(unitProvider);
                              setState(() {
                                unitTime = 0;
                                extraAddedUnits.clear();
                                selectedUnit = unitModel.unitName;
                              });
                              unitNameController.clear();
                              EasyLoading.showSuccess("Successfully Added");
                              finish(context);
                            } catch (e) {
                              EasyLoading.showError('Error');
                            }
                          }
                        })
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  String productPicture =
      'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672';

  Uint8List? image;

  Future<void> uploadFile() async {
    // File file = File(filePath);
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        // File? file = await ImagePickerWeb.getImageAsFile();
        if (bytesFromPicker!.isNotEmpty) {
          EasyLoading.show(
            status: 'Uploading... ',
            dismissOnTap: false,
          );
        }

        var snapshot = await FirebaseStorage.instance
            .ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}')
            .putData(bytesFromPicker);
        var url = await snapshot.ref.getDownloadURL();
        EasyLoading.showSuccess('Upload Successful!');
        setState(() {
          image = bytesFromPicker;
          productPicture = url.toString();
        });
      } on firebase_core.FirebaseException catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.code.toString())));
      }
    }
  }

  List<String> warrantyTime = ['Day', 'Month', 'Year'];

  // List<String> fixedUnitList = [
  //   "PIECES (Pcs)",
  //   "BAGS (Bag)",
  //   "BOX ( Box )",
  //   "PACKS (Pac)",
  //   "PAIRS (Prs)",
  //   "LITRE (Ltr)",
  //   "CANS (Can)",
  //   "ROLLS (Rol)",
  //   "QUINTAL (Qtl)",
  //   "CARTONS (Ctn)",
  //   "DOZENS (Dzn)",
  //   "MILILITRE (Mr)",
  //   "BOTTLES (Blt)",
  //   "BUNDLES (Bdl)",
  //   "GRAMMES (Gm)",
  //   "KILOGRAMS (Kg)",
  //   "NUMBERS (Nos)",
  //   "TABLETS (Tbs)",
  //   "SQUARE FEET (Sqf)",
  //   "SQUARE METERS (Sqm)"
  // ];
  List<String> extraAddedUnits = [];
  List<String> allUnitList = [
    "PIECES (Pcs)",
    "BAGS (Bag)",
    "BOX ( Box )",
    "PACKS (Pac)",
    "PAIRS (Prs)",
    "LITRE (Ltr)",
    "CANS (Can)",
    "ROLLS (Rol)",
    "QUINTAL (Qtl)",
    "CARTONS (Ctn)",
    "DOZENS (Dzn)",
    "MILILITRE (Mr)",
    "BOTTLES (Blt)",
    "BUNDLES (Bdl)",
    "GRAMMES (Gm)",
    "KILOGRAMS (Kg)",
    "NUMBERS (Nos)",
    "TABLETS (Tbs)",
    "SQUARE FEET (Sqf)",
    "SQUARE METERS (Sqm)"
  ];

  String? selectedBrand;
  String? selectedCategories;
  String selectedTime = 'Month';
  String? selectedUnit = 'PIECES (Pcs)';
  bool isSerialNumberTaken = false;

  String productSalePrice = '';
  String productPurchasePrice = '';
  String productDealerPrice = '';
  String productWholeSalePrice = '';
  String excTaxAmount = '';
  String incTaxAmount = '';

  TextEditingController productNameController = TextEditingController();
  TextEditingController productCodeController = TextEditingController();
  TextEditingController productQuantityController = TextEditingController();
  TextEditingController productSalePriceController = TextEditingController();
  TextEditingController productPurchasePriceController =
      TextEditingController();
  TextEditingController productDiscountPriceController =
      TextEditingController(text: '');
  TextEditingController productWholesalePriceController =
      TextEditingController(text: '');
  TextEditingController productDealerPriceController =
      TextEditingController(text: '');
  TextEditingController productManufacturerController =
      TextEditingController(text: '');
  TextEditingController productSerialNumberController =
      TextEditingController(text: '');

  TextEditingController itemCategoryController = TextEditingController();
  TextEditingController brandNameController = TextEditingController();
  TextEditingController unitNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  TextEditingController sizeController = TextEditingController(text: '');
  TextEditingController colorController = TextEditingController(text: '');
  TextEditingController weightController = TextEditingController(text: '');
  TextEditingController capacityController = TextEditingController(text: '');
  TextEditingController typeController = TextEditingController(text: '');
  TextEditingController warrantyController = TextEditingController(text: '');

  TextEditingController totalAmountController = TextEditingController();
  TextEditingController incTaxController = TextEditingController();
  TextEditingController excTaxController = TextEditingController();
  TextEditingController marginController = TextEditingController();

  GlobalKey<FormState> addProductFormKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = addProductFormKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  ScrollController mainScroll = ScrollController();

  WareHouseModel ar = WareHouseModel(
      warehouseName: 'Select warehouse', warehouseAddress: '', id: '');
  late WareHouseModel? selectedWareHouse;

  int i = 0;

  DropdownButton<WareHouseModel> getName({required List<WareHouseModel> list}) {
    List<DropdownMenuItem<WareHouseModel>> dropDownItems = [
      // DropdownMenuItem(
      //   enabled: false,
      //   value: ar,
      //   child: Text(ar.warehouseName),
      // )
    ];
    for (var element in list) {
      dropDownItems.add(DropdownMenuItem(
        value: element,
        child: SizedBox(
          width: 110,
          child: Text(
            element.warehouseName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ));
      if (i == 0) {
        selectedWareHouse = element;
      }
      i++;
    }
    return DropdownButton(
      items: dropDownItems,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: kGreyTextColor,
      ),
      value: selectedWareHouse,
      onChanged: (value) {
        setState(() {
          selectedWareHouse = value!;
        });
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    productPurchasePriceController.addListener(calculateTotal);
    marginController.addListener(() {
      setState(() {
        adjustSalesPrices();
      });
    });
  }

  @override
  void dispose() {
    productPurchasePriceController.removeListener(calculateTotal);
    productPurchasePriceController.dispose();
    totalAmountController.dispose();
    marginController.dispose();
    productSalePriceController.dispose();
    productDealerPriceController.dispose();
    super.dispose();
  }

  //___________________________________tax_dropdown________________________________
  DropdownButton<GroupTaxModel> getTax({required List<GroupTaxModel> list}) {
    return DropdownButton(
      hint: const Text('Select Tax'),
      items: list.map((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(e.name),
        );
      }).toList(),
      value: selectedGroupTaxModel,
      onChanged: (value) {
        setState(() {
          selectedGroupTaxModel = value!;
        });
      },
    );
  }

  GroupTaxModel? selectedGroupTaxModel;

  //___________________________________tax_type____________________________________
  List<String> status = [
    'Inclusive',
    'Exclusive',
  ];

  String selectedTaxType = 'Exclusive';

  DropdownButton<String> getTaxType() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in status) {
      var item = DropdownMenuItem(
        value: des,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(des)),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      isExpanded: true,
      hint: const Flexible(
          child: Text(
        'Select Tax type',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      )),
      items: dropDownItems,
      value: selectedTaxType,
      onChanged: (value) {
        setState(() {
          selectedTaxType = value!;
          adjustSalesPrices();
        });
      },
    );
  }

  //___________________________________calculate_total_with_tax____________________
  double totalAmount = 0.0;

  void calculateTotal() {
    String saleAmountText =
        productPurchasePriceController.text.replaceAll(',', '');
    double saleAmount = double.tryParse(saleAmountText) ?? 0.0;
    if (selectedGroupTaxModel != null) {
      double taxRate = double.parse(selectedGroupTaxModel!.taxRate.toString());
      double totalAmount = calculateTotalAmount(saleAmount, taxRate);
      setState(() {
        totalAmountController.text = totalAmount.toStringAsFixed(2);
        this.totalAmount = totalAmount;
      });
    }
  }

  double calculateTotalAmount(double saleAmount, double taxRate) {
    double taxDecimal = taxRate / 100;
    double totalAmount = saleAmount + (saleAmount * taxDecimal);
    return totalAmount;
  }

  void adjustSalesPrices() {
    double margin = double.tryParse(marginController.text) ?? 0;
    double purchasePrice = double.tryParse(productPurchasePrice) ?? 0;
    double salesPrice = 0;
    double excPrice = 0;
    double taxAmount = calculateAmountFromPercentage(
        (selectedGroupTaxModel?.taxRate.toString() ?? '').toDouble(),
        purchasePrice);

    if (selectedTaxType == 'Inclusive') {
      salesPrice =
          purchasePrice + calculateAmountFromPercentage(margin, purchasePrice);
      // salesPrice -= calculateAmountFromPercentage(double.parse(selectedGroupTaxModel!.taxRate.toString()), purchasePrice);
      productSalePrice = salesPrice.toString();
      productDealerPrice = salesPrice.toString();
      productWholeSalePrice = salesPrice.toString();
      incTaxAmount = purchasePrice.toString();
      excTaxAmount = salesPrice.toString();
    } else {
      salesPrice = purchasePrice +
          calculateAmountFromPercentage(margin, purchasePrice) +
          taxAmount;
      excPrice = purchasePrice + taxAmount;
      productSalePrice = salesPrice.toString();
      productDealerPrice = salesPrice.toString();
      productWholeSalePrice = salesPrice.toString();
      incTaxAmount = purchasePrice.toString();
      excTaxAmount = excPrice.toString();
    }

    // Add margin to prices if margin is provided

    // Update controllers with adjusted prices
    productSalePriceController.text = salesPrice.toStringAsFixed(2);
    productWholesalePriceController.text = salesPrice.toStringAsFixed(2);
    productDealerPriceController.text = salesPrice.toStringAsFixed(2);
    incTaxController.text = salesPrice.toStringAsFixed(2);
    excTaxController.text = excPrice.toStringAsFixed(2);
  }

  // Function to calculate the amount from a given percentage
  double calculateAmountFromPercentage(double percentage, double price) {
    return price * (percentage / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Consumer(
        builder: (context, ref, __) {
          final unitList = ref.watch(unitProvider);
          final brandList = ref.watch(brandProvider);
          final categoryList = ref.watch(categoryProvider);
          final wareHouseList = ref.watch(warehouseProvider);
          final groupTax = ref.watch(groupTaxProvider);
          return SingleChildScrollView(
            child: Form(
              key: addProductFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_______________________________top_bar____________________________
                  // const TopBar(),

                  const SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      lang.S.of(context).addProduct,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ResponsiveGridRow(children: [
                    ResponsiveGridCol(
                        xs: 12,
                        md: screenWidth < 778 ? 12 : 8,
                        lg: screenWidth < 778 ? 12 : 8,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
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
                                    const SizedBox(height: 10.0),

                                    ///________Name_And_Category_____________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value
                                                        ?.removeAllWhiteSpace()
                                                        .toLowerCase()
                                                        .isEmptyOrNull ??
                                                    true) {
                                                  return 'Product name is required.';
                                                } else if (!checkProductName(
                                                    name: value!,
                                                    id: selectedWareHouse!
                                                        .id)) {
                                                  return 'Product Name already exists in this warehouse.';
                                                } else {
                                                  return null; // Validation passes
                                                }
                                              },
                                              onSaved: (value) {
                                                productNameController.text =
                                                    value!;
                                              },
                                              showCursor: true,
                                              controller: productNameController,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .productNam,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterProductName,
                                              ),
                                            ),
                                          )),
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: categoryList.when(
                                          data: (category) {
                                            List<String> editNameList = [];
                                            List<String> categoryName = [];

                                            for (var element in category) {
                                              categoryName
                                                  .add(element.categoryName);
                                              editNameList.add(element
                                                  .categoryName
                                                  .toLowerCase()
                                                  .removeAllWhiteSpace());
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: SizedBox(
                                                height: 48,
                                                child: FormField(
                                                  builder:
                                                      (FormFieldState<dynamic>
                                                          field) {
                                                    return InputDecorator(
                                                      decoration: InputDecoration(
                                                          suffixIcon: GestureDetector(
                                                              onTap: () async {
                                                                await addCategoryShowPopUp(
                                                                    ref: ref,
                                                                    categoryNameList:
                                                                        editNameList,
                                                                    addProductContext:
                                                                        context);
                                                              },
                                                              child: Container(
                                                                  height: 48,
                                                                  width: 48,
                                                                  alignment: Alignment.center,
                                                                  decoration: const BoxDecoration(
                                                                      color: kMainColor100,
                                                                      borderRadius: BorderRadius.only(
                                                                        topRight:
                                                                            Radius.circular(8),
                                                                        bottomRight:
                                                                            Radius.circular(8),
                                                                      )),
                                                                  child: const Icon(FeatherIcons.plusSquare, color: kMainColor))),
                                                          contentPadding: const EdgeInsets.all(8.0),
                                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                                          labelText: lang.S.of(context).category),
                                                      child: Theme(
                                                        data: ThemeData(
                                                            highlightColor:
                                                                dropdownItemColor,
                                                            focusColor:
                                                                dropdownItemColor,
                                                            hoverColor:
                                                                dropdownItemColor),
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                                child:
                                                                    DropdownButton<
                                                                        String>(
                                                          icon: const Icon(
                                                            Icons
                                                                .keyboard_arrow_down,
                                                            color:
                                                                kGreyTextColor,
                                                          ),
                                                          hint: Text(
                                                            'Select Category',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          onChanged:
                                                              (String? value) {
                                                            setState(() {
                                                              selectedCategories =
                                                                  value!;
                                                              for (var element
                                                                  in category) {
                                                                if (element
                                                                        .categoryName ==
                                                                    selectedCategories) {
                                                                  isSizedBoxShow =
                                                                      element
                                                                          .size;
                                                                  isColoredBoxShow =
                                                                      element
                                                                          .color;
                                                                  isWeightsBoxShow =
                                                                      element
                                                                          .weight;
                                                                  isCapacityBoxShow =
                                                                      element
                                                                          .capacity;
                                                                  isTypeBoxShow =
                                                                      element
                                                                          .type;
                                                                  isWarrantyBoxShow =
                                                                      element
                                                                          .warranty;
                                                                }
                                                              }
                                                              toast(
                                                                  selectedCategories);
                                                            });
                                                          },
                                                          value:
                                                              selectedCategories,
                                                          items: categoryName
                                                              .map((String
                                                                  items) {
                                                            return DropdownMenuItem(
                                                              value: items,
                                                              child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child:
                                                                    Text(items),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        )),
                                                      ),
                                                    );
                                                  },
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
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                        ),
                                      )
                                    ]),

                                    ///________Size_&_Color____________________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: isColoredBoxShow ? 6 : 12,
                                        lg: isColoredBoxShow ? 6 : 12,
                                        child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              validator: (value) {
                                                return null;
                                              },
                                              onSaved: (value) {
                                                sizeController.text = value!;
                                              },
                                              showCursor: true,
                                              controller: sizeController,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .productSize,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterProductSize,
                                              ),
                                            )).visible(isSizedBoxShow),
                                      ),
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: isSizedBoxShow ? 6 : 12,
                                        lg: isSizedBoxShow ? 6 : 12,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: TextFormField(
                                            validator: (value) {
                                              return null;
                                            },
                                            onSaved: (value) {
                                              colorController.text = value!;
                                            },
                                            showCursor: true,
                                            controller: colorController,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .productColor,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterProductColor,
                                            ),
                                          ),
                                        ).visible(isColoredBoxShow),
                                      )
                                    ]),

                                    ///_____________Weight_&_Capacity___________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: isCapacityBoxShow ? 6 : 12,
                                          lg: isCapacityBoxShow ? 6 : 12,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: TextFormField(
                                              validator: (value) {
                                                return null;
                                              },
                                              onSaved: (value) {
                                                weightController.text = value!;
                                              },
                                              showCursor: true,
                                              controller: weightController,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .productWeight,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterProductWeight,
                                              ),
                                            ),
                                          ).visible(isWeightsBoxShow)),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: isWeightsBoxShow ? 6 : 12,
                                          lg: isWeightsBoxShow ? 6 : 12,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: TextFormField(
                                              validator: (value) {
                                                return null;
                                              },
                                              onSaved: (value) {
                                                capacityController.text =
                                                    value!;
                                              },
                                              showCursor: true,
                                              controller: capacityController,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .productcapacity,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterProductCapacity,
                                              ),
                                            ),
                                          ).visible(isCapacityBoxShow))
                                    ]),

                                    ///_____________Type_&_Warranty___________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: isWarrantyBoxShow ? 6 : 12,
                                        lg: isWarrantyBoxShow ? 6 : 12,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextFormField(
                                            validator: (value) {
                                              return null;
                                            },
                                            onSaved: (value) {
                                              typeController.text = value!;
                                            },
                                            showCursor: true,
                                            controller: typeController,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .productType,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterProductType,
                                            ),
                                          ),
                                        ).visible(isTypeBoxShow),
                                      ),
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: isTypeBoxShow ? 6 : 12,
                                        lg: isTypeBoxShow ? 6 : 12,
                                        child: ResponsiveGridRow(children: [
                                          ResponsiveGridCol(
                                            xs: 12,
                                            md: 6,
                                            lg: 8,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (double.tryParse(value!) ==
                                                          null &&
                                                      !value.isEmptyOrNull) {
                                                    return 'Enter Quantity in number.';
                                                  } else {
                                                    return null;
                                                  }
                                                },
                                                onSaved: (value) {
                                                  warrantyController.text =
                                                      value!;
                                                },
                                                showCursor: true,
                                                controller: warrantyController,
                                                cursorColor: kTitleColor,
                                                decoration: InputDecoration(
                                                  labelText: lang.S
                                                      .of(context)
                                                      .productWaranty,
                                                  hintText: lang.S
                                                      .of(context)
                                                      .enterWarranty,
                                                ),
                                              ),
                                            ).visible(isWarrantyBoxShow),
                                          ),
                                          ResponsiveGridCol(
                                              xs: 12,
                                              md: 6,
                                              lg: 4,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: FormField(
                                                  builder:
                                                      (FormFieldState<dynamic>
                                                          field) {
                                                    return InputDecorator(
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: lang.S
                                                            .of(context)
                                                            .warranty,
                                                      ),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                              child:
                                                                  DropdownButton<
                                                                      String>(
                                                        isExpanded: true,
                                                        icon: const Icon(
                                                          Icons
                                                              .keyboard_arrow_down,
                                                          color: kGreyTextColor,
                                                        ),
                                                        onChanged:
                                                            (String? value) {
                                                          setState(() {
                                                            selectedTime =
                                                                value!;
                                                          });
                                                        },
                                                        hint: Text(lang.S
                                                            .of(context)
                                                            .selectWarrantyTime),
                                                        value: selectedTime,
                                                        items: warrantyTime.map(
                                                            (String items) {
                                                          return DropdownMenuItem(
                                                            value: items,
                                                            child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: Text(
                                                                    items)),
                                                          );
                                                        }).toList(),
                                                      )),
                                                    );
                                                  },
                                                ),
                                              ).visible(isWarrantyBoxShow)),
                                        ]),
                                      )
                                    ]),

                                    // Row(
                                    //   children: [
                                    //     Expanded(
                                    //       child: Padding(
                                    //         padding: const EdgeInsets.only(top: 20.0, bottom: 20),
                                    //         child: TextFormField(
                                    //           validator: (value) {
                                    //             return null;
                                    //           },
                                    //           onSaved: (value) {
                                    //             typeController.text = value!;
                                    //           },
                                    //           showCursor: true,
                                    //           controller: typeController,
                                    //           cursorColor: kTitleColor,
                                    //           decoration: kInputDecoration.copyWith(
                                    //             labelText: lang.S.of(context).productType,
                                    //             labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                    //             hintText: lang.S.of(context).enterProductType,
                                    //             hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                    //           ),
                                    //         ),
                                    //       ),
                                    //     ).visible(isTypeBoxShow),
                                    //     const SizedBox(width: 20).visible(isTypeBoxShow && isWarrantyBoxShow),
                                    //     Expanded(
                                    //       child: Row(
                                    //         children: [
                                    //           Expanded(
                                    //             child: Padding(
                                    //               padding: const EdgeInsets.only(top: 20.0, bottom: 20),
                                    //               child: TextFormField(
                                    //                 validator: (value) {
                                    //                   if (double.tryParse(value!) == null && !value.isEmptyOrNull) {
                                    //                     return 'Enter Quantity in number.';
                                    //                   } else {
                                    //                     return null;
                                    //                   }
                                    //                 },
                                    //                 onSaved: (value) {
                                    //                   warrantyController.text = value!;
                                    //                 },
                                    //                 showCursor: true,
                                    //                 controller: warrantyController,
                                    //                 cursorColor: kTitleColor,
                                    //                 decoration: kInputDecoration.copyWith(
                                    //                   errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                    //                   labelText: lang.S.of(context).productWaranty,
                                    //                   labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                    //                   hintText: lang.S.of(context).enterWarranty,
                                    //                   hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ),
                                    //           const SizedBox(width: 4),
                                    //           SizedBox(
                                    //             width: 200,
                                    //             child: FormField(
                                    //               builder: (FormFieldState<dynamic> field) {
                                    //                 return InputDecorator(
                                    //                   decoration: InputDecoration(
                                    //                     enabledBorder: const OutlineInputBorder(
                                    //                       borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                    //                       borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                                    //                     ),
                                    //                     contentPadding: const EdgeInsets.all(8.0),
                                    //                     floatingLabelBehavior: FloatingLabelBehavior.always,
                                    //                     labelText: lang.S.of(context).warranty,
                                    //                   ),
                                    //                   child: DropdownButtonHideUnderline(
                                    //                       child: DropdownButton<String>(
                                    //                     onChanged: (String? value) {
                                    //                       setState(() {
                                    //                         selectedTime = value!;
                                    //                       });
                                    //                     },
                                    //                     hint: Text(lang.S.of(context).selectWarrantyTime),
                                    //                     value: selectedTime,
                                    //                     items: warrantyTime.map((String items) {
                                    //                       return DropdownMenuItem(
                                    //                         value: items,
                                    //                         child: Text(items),
                                    //                       );
                                    //                     }).toList(),
                                    //                   )),
                                    //                 );
                                    //               },
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       ),
                                    //     ).visible(isWarrantyBoxShow),
                                    //   ],
                                    // ),
                                    ///_______brand_&_ProductCode________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: brandList.when(data: (brand) {
                                            List<String> editBrandList = [];
                                            List<String> brandName = [];
                                            // brandTime == 0
                                            //     // ignore: avoid_function_literals_in_foreach_calls
                                            //     ? brand.forEach((element) {
                                            //         brandName.add(element.brandName);
                                            //         // editBrandList.add(element.brandName.removeAllWhiteSpace().toLowerCase());
                                            //         brandTime++;
                                            //       })
                                            //     : null;
                                            for (var element in brand) {
                                              brandName
                                                  .add(element.brandName ?? '');
                                              editBrandList.add(element
                                                      .brandName
                                                      ?.toLowerCase()
                                                      .removeAllWhiteSpace() ??
                                                  '');
                                            }

                                            return SizedBox(
                                              height: 48,
                                              child: FormField(
                                                builder:
                                                    (FormFieldState<dynamic>
                                                        field) {
                                                  return InputDecorator(
                                                    decoration: InputDecoration(
                                                        suffixIcon: Container(
                                                          height: 48,
                                                          width: 48,
                                                          decoration:
                                                              const BoxDecoration(
                                                                  color:
                                                                      kMainColor100,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .only(
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            8),
                                                                    topRight: Radius
                                                                        .circular(
                                                                            8),
                                                                  )),
                                                          child: const Icon(
                                                                  FeatherIcons
                                                                      .plusSquare,
                                                                  color:
                                                                      kMainColor)
                                                              .onTap(() => showBrandPopUp(
                                                                  ref: ref,
                                                                  brandNameList:
                                                                      editBrandList,
                                                                  addProductsContext:
                                                                      context)),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        labelText: lang.S
                                                            .of(context)
                                                            .brand),
                                                    child: Theme(
                                                      data: ThemeData(
                                                          highlightColor:
                                                              dropdownItemColor,
                                                          focusColor:
                                                              dropdownItemColor,
                                                          hoverColor:
                                                              dropdownItemColor),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                              child:
                                                                  DropdownButton<
                                                                      String>(
                                                        isExpanded: true,
                                                        onChanged:
                                                            (String? value) {
                                                          setState(() {
                                                            selectedBrand =
                                                                value!;
                                                            toast(
                                                                selectedBrand);
                                                          });
                                                        },
                                                        hint: Text(
                                                          lang.S
                                                              .of(context)
                                                              .selectProductBrand,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        value: selectedBrand,
                                                        items: brandName.map(
                                                            (String items) {
                                                          return DropdownMenuItem(
                                                            value: items,
                                                            child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: Text(
                                                                    items)),
                                                          );
                                                        }).toList(),
                                                      )),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          }, error: (e, stack) {
                                            return Center(
                                              child: Text(e.toString()),
                                            );
                                          }, loading: () {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }),
                                        ),
                                      ),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              validator: (value) {
                                                // if (value.removeAllWhiteSpace().isEmptyOrNull) {
                                                //   return 'Product Code is required.';
                                                // } else
                                                if (widget.allProductsCodeList
                                                    .contains(value
                                                        .removeAllWhiteSpace()
                                                        .toLowerCase())) {
                                                  return 'Product Code already exist.';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              onSaved: (value) {
                                                if (value
                                                    .removeAllWhiteSpace()
                                                    .isEmptyOrNull) {
                                                  productCodeController.text =
                                                      DateTime.now().toString();
                                                } else {
                                                  productCodeController.text =
                                                      value!;
                                                }
                                              },
                                              controller: productCodeController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .productCod,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterProductCode,
                                                suffixIcon: Container(
                                                  height: 48,
                                                  width: 48,
                                                  decoration: const BoxDecoration(
                                                      color: kMainColor100,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          8),
                                                              topRight: Radius
                                                                  .circular(
                                                                      8))),
                                                  child: const Icon(
                                                    Icons.scanner,
                                                    color: kMainColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )),
                                    ]),

                                    ///______quantity_&_Unit______________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value
                                                    .removeAllWhiteSpace()
                                                    .isEmptyOrNull) {
                                                  return 'Product Quantity is required.';
                                                } else if (double.tryParse(
                                                        value!) ==
                                                    null) {
                                                  return 'Enter Quantity in number.';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              onSaved: (value) {
                                                productQuantityController.text =
                                                    value!;
                                              },
                                              controller:
                                                  productQuantityController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText:
                                                    lang.S.of(context).Quantity,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterProductQuantity,
                                              ),
                                            ),
                                          )),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: unitList.when(data: (unit) {
                                            List<String> editUnitNameList = [];
                                            unitTime == 0
                                                // ignore: avoid_function_literals_in_foreach_calls
                                                ? unit.forEach((element) {
                                                    extraAddedUnits
                                                        .add(element.unitName);

                                                    // editUnitNameList.add(element.unitName.removeAllWhiteSpace().removeAllWhiteSpace());
                                                    unitTime++;
                                                    if (element.unitName ==
                                                        unit.last.unitName) {
                                                      allUnitList =
                                                          allUnitList +
                                                              extraAddedUnits;
                                                    }
                                                  })
                                                : null;

                                            for (var element in allUnitList) {
                                              editUnitNameList.add(element
                                                  .removeAllWhiteSpace()
                                                  .removeAllWhiteSpace());
                                            }

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: SizedBox(
                                                height: 48,
                                                child: FormField(
                                                  builder:
                                                      (FormFieldState<dynamic>
                                                          field) {
                                                    return InputDecorator(
                                                      decoration:
                                                          InputDecoration(
                                                        suffixIcon: Container(
                                                          height: 48,
                                                          width: 48,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color:
                                                                kMainColor100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          8),
                                                              topRight: Radius
                                                                  .circular(8),
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                                  FeatherIcons
                                                                      .plusSquare,
                                                                  color:
                                                                      kMainColor)
                                                              .onTap(() => showUnitPopUp(
                                                                  ref: ref,
                                                                  unitNameList:
                                                                      editUnitNameList,
                                                                  addProductsContext:
                                                                      context)),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 8.0,
                                                                top: 8,
                                                                bottom: 8),
                                                        floatingLabelBehavior:
                                                            FloatingLabelBehavior
                                                                .always,
                                                        labelText: lang.S
                                                            .of(context)
                                                            .productUnit,
                                                      ),
                                                      child: Theme(
                                                        data: ThemeData(
                                                            highlightColor:
                                                                dropdownItemColor,
                                                            focusColor:
                                                                dropdownItemColor,
                                                            hoverColor:
                                                                dropdownItemColor),
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                                child:
                                                                    DropdownButton<
                                                                        String>(
                                                          isExpanded: true,
                                                          icon: const Icon(
                                                            Icons
                                                                .keyboard_arrow_down,
                                                            color:
                                                                kGreyTextColor,
                                                          ),
                                                          onChanged:
                                                              (String? value) {
                                                            setState(() {
                                                              selectedUnit =
                                                                  value!;
                                                              toast(
                                                                  selectedUnit);
                                                            });
                                                          },
                                                          value: selectedUnit,
                                                          items: allUnitList
                                                              .map((String
                                                                  items) {
                                                            return DropdownMenuItem(
                                                              value: items,
                                                              child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: Text(
                                                                  items,
                                                                  style: kTextStyle.copyWith(
                                                                      color:
                                                                          kTitleColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        )),
                                                      ),
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
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          })),
                                    ]),

                                    ///________Manufacturer && warehouse_____________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: TextFormField(
                                            validator: (value) {
                                              return null;
                                            },
                                            onSaved: (value) {
                                              productManufacturerController
                                                  .text = value!;
                                            },
                                            controller:
                                                productManufacturerController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .manufacturer,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterManufacturerName,
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
                                          child: wareHouseList.when(
                                            data: (warehouse) {
                                              return SizedBox(
                                                height: 48,
                                                child: FormField(
                                                  builder:
                                                      (FormFieldState<dynamic>
                                                          field) {
                                                    return InputDecorator(
                                                      decoration: const InputDecoration(
                                                          contentPadding:
                                                              EdgeInsets.all(
                                                                  8.0),
                                                          floatingLabelBehavior:
                                                              FloatingLabelBehavior
                                                                  .always,
                                                          labelText:
                                                              'Warehouse'),
                                                      child: Theme(
                                                        data: ThemeData(
                                                            highlightColor:
                                                                dropdownItemColor,
                                                            focusColor:
                                                                dropdownItemColor,
                                                            hoverColor:
                                                                dropdownItemColor),
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                          child: getName(
                                                              list: warehouse),
                                                        ),
                                                      ),
                                                    );
                                                  },
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
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    ]),

                                    ///______________ExpireDate______________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              keyboardType: TextInputType.name,
                                              readOnly: true,
                                              validator: (value) {
                                                return null;
                                              },
                                              controller:
                                                  manufactureDateTextEditingController,
                                              decoration: InputDecoration(
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior
                                                        .always,
                                                labelText: "Manufacture Date",
                                                hintText: 'Enter Date',
                                                suffixIcon: IconButton(
                                                  onPressed: () async {
                                                    final DateTime? picked =
                                                        await showDatePicker(
                                                      // initialDate: DateTime.now(),
                                                      firstDate:
                                                          DateTime(2015, 8),
                                                      lastDate: DateTime(2101),
                                                      context: context,
                                                    );
                                                    setState(() {
                                                      picked != null
                                                          ? manufactureDateTextEditingController
                                                                  .text =
                                                              DateFormat.yMMMd()
                                                                  .format(
                                                                      picked)
                                                          : null;
                                                      picked != null
                                                          ? manufactureDate =
                                                              picked.toString()
                                                          : null;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      FeatherIcons.calendar),
                                                ),
                                              ),
                                            ),
                                          )),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              keyboardType: TextInputType.name,
                                              readOnly: true,
                                              validator: (value) {
                                                return null;
                                              },
                                              controller:
                                                  expireDateTextEditingController,
                                              decoration: InputDecoration(
                                                labelText: 'Expire Date',
                                                hintText: 'Enter Date',
                                                suffixIcon: IconButton(
                                                  onPressed: () async {
                                                    final DateTime? picked =
                                                        await showDatePicker(
                                                      // initialDate: DateTime.now(),
                                                      firstDate:
                                                          DateTime(2015, 8),
                                                      lastDate: DateTime(2101),
                                                      context: context,
                                                    );
                                                    setState(() {
                                                      picked != null
                                                          ? expireDateTextEditingController
                                                                  .text =
                                                              DateFormat.yMMMd()
                                                                  .format(
                                                                      picked)
                                                          : null;
                                                      picked != null
                                                          ? expireDate =
                                                              picked.toString()
                                                          : null;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      FeatherIcons.calendar),
                                                ),
                                              ),
                                            ),
                                          ))
                                    ]),

                                    ///_______Lower_stock___________________________
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: TextFormField(
                                        initialValue:
                                            lowerStockAlert.toString(),
                                        onSaved: (value) {
                                          lowerStockAlert =
                                              int.tryParse(value ?? '') ?? 5;
                                        },
                                        decoration: const InputDecoration(
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.always,
                                          labelText: 'Low Stock Alert',
                                          hintText:
                                              'Enter Low Stock Alert Quantity',
                                          border: OutlineInputBorder(),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              //---------------serial number--------------------
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: kWhite,
                                ),
                                child: Column(
                                  children: [
                                    ///_________product_serial____________________________________________
                                    Row(
                                      children: [
                                        Theme(
                                          data: ThemeData(
                                              checkboxTheme:
                                                  const CheckboxThemeData(
                                                      side: BorderSide(
                                            color: kNeutral500,
                                          ))),
                                          child: Checkbox(
                                              value: isSerialNumberTaken,
                                              onChanged: (value) {
                                                setState(() {
                                                  isSerialNumberTaken = value!;
                                                });
                                              }),
                                        ),
                                        Flexible(
                                          child: Text.rich(TextSpan(
                                              text: 'Do you want to add a ',
                                              style: theme.textTheme.bodyLarge,
                                              children: [
                                                TextSpan(
                                                    text: 'serial number?',
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      color: kMainColor,
                                                    ))
                                              ])),
                                        ),
                                      ],
                                    ),

                                    ///____________serial_add_system_____________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 9,
                                          lg: 9,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              validator: (value) {
                                                return null;
                                              },
                                              controller:
                                                  productSerialNumberController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              onFieldSubmitted: (value) {
                                                if (isSerialNumberUnique(
                                                    allList:
                                                        productSerialNumberList,
                                                    newSerial: value)) {
                                                  setState(() {
                                                    productSerialNumberList
                                                        .add(value);
                                                  });
                                                  productSerialNumberController
                                                      .clear();
                                                } else {
                                                  EasyLoading.showError(
                                                      'Serial number already added!');
                                                }
                                              },
                                              keyboardType: TextInputType.name,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .serialNumber,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterSerialNumber,
                                              ),
                                            ),
                                          ).visible(isSerialNumberTaken)),
                                      ResponsiveGridCol(
                                        xs: 4,
                                        md: 3,
                                        lg: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (isSerialNumberUnique(
                                                  allList:
                                                      productSerialNumberList,
                                                  newSerial:
                                                      productSerialNumberController
                                                          .text)) {
                                                setState(() {
                                                  productSerialNumberList.add(
                                                      productSerialNumberController
                                                          .text);
                                                });
                                                productSerialNumberController
                                                    .clear();
                                              } else {
                                                EasyLoading.showError(
                                                    'Serial number already added!');
                                              }
                                            },
                                            child: Text(
                                              lang.S.of(context).add,
                                            ),
                                          ),
                                        ).visible(isSerialNumberTaken),
                                      ),
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: 12,
                                        lg: 12,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Container(
                                            // width: context.width() < 1280 ? 200 : 400,
                                            // width: 400,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1, color: kNeutral400),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(8)),
                                            ),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: productSerialNumberList
                                                  .length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                if (productSerialNumberList
                                                    .isNotEmpty) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      color: kNeutral100,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          SizedBox(
                                                            width: 170,
                                                            height: 40,
                                                            child: Text(
                                                              productSerialNumberList[
                                                                  index],
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                productSerialNumberList
                                                                    .removeAt(
                                                                        index);
                                                              });
                                                            },
                                                            child: const Icon(
                                                              Icons.cancel,
                                                              color: Colors.red,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return const Text(
                                                      'No Serial Number Found');
                                                }
                                              },
                                            ),
                                          ),
                                        ).visible(isSerialNumberTaken),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              //----------pricing section--------------
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: kWhite,
                                ),
                                child: Column(
                                  children: [
                                    ///________Tax && Type____________________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                        lg: 6,
                                        md: 6,
                                        xs: 12,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: groupTax.when(
                                            data: (groupTax) {
                                              // List<WareHouseModel> wareHouseList = [];
                                              return SizedBox(
                                                height: 48,
                                                child: FormField(
                                                  builder:
                                                      (FormFieldState<dynamic>
                                                          field) {
                                                    return InputDecorator(
                                                      decoration:
                                                          const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              labelText:
                                                                  'Applicable Tax'),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                            GroupTaxModel>(
                                                          isExpanded: true,
                                                          hint: Text(
                                                            'Select Tax',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          items:
                                                              groupTax.map((e) {
                                                            return DropdownMenuItem<
                                                                GroupTaxModel>(
                                                              value: e,
                                                              child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: Text(
                                                                    e.name),
                                                              ),
                                                            );
                                                          }).toList(),
                                                          value:
                                                              selectedGroupTaxModel,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              selectedGroupTaxModel =
                                                                  value;
                                                              calculateTotal();
                                                              adjustSalesPrices(); // Update total amount when tax changes
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
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
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      ResponsiveGridCol(
                                          lg: 6,
                                          md: 6,
                                          xs: 12,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              height: 48,
                                              child: FormField(
                                                builder:
                                                    (FormFieldState<dynamic>
                                                        field) {
                                                  return InputDecorator(
                                                    decoration:
                                                        const InputDecoration(
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    8.0),
                                                            labelText:
                                                                'Tax Type'),
                                                    child:
                                                        DropdownButtonHideUnderline(
                                                      child: getTaxType(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ))
                                    ]),

                                    ///________Margin____________________________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              keyboardType:
                                                  TextInputType.number,
                                              controller: marginController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: const InputDecoration(
                                                labelText: 'Margin %',
                                                hintText: '0',
                                              ),
                                            ),
                                          )),
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: selectedTaxType == 'Inclusive'
                                            ? 6
                                            : 0,
                                        lg: selectedTaxType == 'Inclusive'
                                            ? 6
                                            : 0,
                                        child: Visibility(
                                          visible:
                                              selectedTaxType == 'Inclusive',
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              controller: incTaxController,
                                              keyboardType:
                                                  TextInputType.number,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: const InputDecoration(
                                                labelText: 'Inc. tax:',
                                                hintText: '0',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      ResponsiveGridCol(
                                        xs: 12,
                                        md: selectedTaxType == 'Exclusive'
                                            ? 6
                                            : 0,
                                        lg: selectedTaxType == 'Exclusive'
                                            ? 6
                                            : 0,
                                        child: Visibility(
                                          visible:
                                              selectedTaxType == 'Exclusive',
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              controller: excTaxController,
                                              keyboardType:
                                                  TextInputType.number,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: const InputDecoration(
                                                labelText: 'Exc. tax:',
                                                hintText: '0',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),

                                    ///__________Sale_Price_&_Purchase_Price_______________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              onChanged: (value) {
                                                productPurchasePrice =
                                                    value.replaceAll(',', '');
                                                adjustSalesPrices();
                                                var formattedText = myFormat
                                                    .format(double.tryParse(
                                                            productPurchasePrice) ??
                                                        0);
                                                productPurchasePriceController
                                                        .value =
                                                    productPurchasePriceController
                                                        .value
                                                        .copyWith(
                                                  text: formattedText,
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset: formattedText
                                                              .length),
                                                );
                                              },
                                              validator: (value) {
                                                if (productPurchasePrice
                                                    .isEmptyOrNull) {
                                                  //return 'Product Purchase Price is required.';
                                                  return '${lang.S.of(context).productPurchasePriceIsRequired}.';
                                                } else if (double.tryParse(
                                                        productPurchasePrice) ==
                                                    null) {
                                                  //return 'Enter price in number.';
                                                  return '${lang.S.of(context).enterPriceInNumber}.';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              onSaved: (value) {
                                                productPurchasePriceController
                                                    .text = value!;
                                              },
                                              controller:
                                                  productPurchasePriceController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .purchasePrice,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterPurchasePrice,
                                              ),
                                            ),
                                          )),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              onChanged: (value) {
                                                productSalePrice =
                                                    value.replaceAll(',', '');
                                                var formattedText =
                                                    myFormat.format(int.parse(
                                                        productSalePrice));
                                                productSalePriceController
                                                        .value =
                                                    productSalePriceController
                                                        .value
                                                        .copyWith(
                                                  text: formattedText,
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset: formattedText
                                                              .length),
                                                );
                                              },
                                              validator: (value) {
                                                if (productSalePrice
                                                    .isEmptyOrNull) {
                                                  //return 'Product Sale Price is required.';
                                                  return '${lang.S.of(context).productSalePriceIsRequired}.';
                                                } else if (double.tryParse(
                                                        productSalePrice) ==
                                                    null) {
                                                  // return 'Enter price in number.';
                                                  return '${lang.S.of(context).enterPriceInNumber}.';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              onSaved: (value) {
                                                productSalePriceController
                                                    .text = value!;
                                              },
                                              controller:
                                                  productSalePriceController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .salePrices,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterSalePrice,
                                              ),
                                            ),
                                          )),
                                    ]),

                                    ///__________Dealer &_Wholesale_Price______________________________________
                                    ResponsiveGridRow(children: [
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              validator: (value) {
                                                if (productDealerPrice
                                                    .isEmptyOrNull) {
                                                  //return 'Product Sale Price is required.';
                                                  return '${lang.S.of(context).productSalePriceIsRequired}.';
                                                } else if (double.tryParse(
                                                        productDealerPrice) ==
                                                    null) {
                                                  // return 'Enter price in number.';
                                                  return '${lang.S.of(context).enterPriceInNumber}.';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              onSaved: (value) {
                                                productDealerPriceController
                                                    .text = value!;
                                              },
                                              onChanged: (value) {
                                                productDealerPrice =
                                                    value.replaceAll(',', '');
                                                var formattedText =
                                                    myFormat.format(int.parse(
                                                        productDealerPrice));
                                                productDealerPriceController
                                                        .value =
                                                    productDealerPriceController
                                                        .value
                                                        .copyWith(
                                                  text: formattedText,
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset: formattedText
                                                              .length),
                                                );
                                              },
                                              controller:
                                                  productDealerPriceController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .dealerPrice,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterDealePrice,
                                              ),
                                            ),
                                          )),
                                      ResponsiveGridCol(
                                          xs: 12,
                                          md: 6,
                                          lg: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              // validator: (value) {
                                              //   if (double.tryParse(value!) == null && !value.isEmptyOrNull) {
                                              //     return 'Enter price in number.';
                                              //   } else {
                                              //     return null;
                                              //   }
                                              // },
                                              onSaved: (value) {
                                                productWholesalePriceController
                                                    .text = value!;
                                              },
                                              onChanged: (value) {
                                                productWholeSalePrice =
                                                    value.replaceAll(',', '');
                                                var formattedText =
                                                    myFormat.format(int.parse(
                                                        productWholeSalePrice));
                                                productWholesalePriceController
                                                        .value =
                                                    productWholesalePriceController
                                                        .value
                                                        .copyWith(
                                                  text: formattedText,
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset: formattedText
                                                              .length),
                                                );
                                              },
                                              controller:
                                                  productWholesalePriceController,
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              decoration: InputDecoration(
                                                labelText: lang.S
                                                    .of(context)
                                                    .wholeSaleprice,
                                                hintText: lang.S
                                                    .of(context)
                                                    .enterPrice,
                                              ),
                                            ),
                                          )),
                                    ]),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )),
                    ResponsiveGridCol(
                        xs: 12,
                        md: screenWidth < 778 ? 12 : 4,
                        lg: screenWidth < 778 ? 12 : 4,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    'Published product',
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Divider(
                                  thickness: 1.0,
                                  color: kNeutral300,
                                ),
                                ResponsiveGridRow(children: [
                                  ResponsiveGridCol(
                                    xs: 12,
                                    md: 6,
                                    lg: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          context.pop();
                                        },
                                        child: Text(lang.S.of(context).cancel),
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
                                          onPressed: saleButtonClicked
                                              ? () {}
                                              : () async {
                                                  if (!isDemo) {
                                                    if (checkUserRoleEditPermissionV2(
                                                        type: 'products')) {
                                                      if (validateAndSave() &&
                                                          selectedCategories !=
                                                              null &&
                                                          selectedCategories!
                                                              .isNotEmpty) {
                                                        try {
                                                          setState(() {
                                                            saleButtonClicked =
                                                                true;
                                                          });
                                                          EasyLoading.show(
                                                              status:
                                                                  'Loading...',
                                                              dismissOnTap:
                                                                  false);
                                                          final DatabaseReference
                                                              productInformationRef =
                                                              FirebaseDatabase
                                                                  .instance
                                                                  .ref()
                                                                  .child(
                                                                      await getUserID())
                                                                  .child(
                                                                      'Products');
                                                          ProductModel
                                                              productModel =
                                                              ProductModel(
                                                            productNameController
                                                                .text,
                                                            selectedCategories ??
                                                                '',
                                                            sizeController.text,
                                                            colorController
                                                                .text,
                                                            weightController
                                                                .text,
                                                            capacityController
                                                                .text,
                                                            typeController.text,
                                                            warrantyController
                                                                        .text ==
                                                                    ''
                                                                ? ''
                                                                : '${warrantyController.text} $selectedTime',
                                                            selectedBrand ?? '',
                                                            productCodeController
                                                                .text,
                                                            productQuantityController
                                                                .text,
                                                            selectedUnit ?? '',
                                                            productSalePrice,
                                                            productPurchasePrice,
                                                            productDiscountPriceController
                                                                .text,
                                                            productWholeSalePrice,
                                                            productDealerPrice,
                                                            productManufacturerController
                                                                .text,
                                                            selectedWareHouse!
                                                                .warehouseName,
                                                            selectedWareHouse!
                                                                .id,
                                                            productPicture,
                                                            productSerialNumberList,
                                                            expiringDate:
                                                                expireDate,
                                                            lowerStockAlert:
                                                                lowerStockAlert,
                                                            manufacturingDate:
                                                                manufactureDate,
                                                            taxType:
                                                                selectedTaxType,
                                                            margin: num.tryParse(
                                                                    marginController
                                                                        .text) ??
                                                                0,
                                                            excTax: num.tryParse(
                                                                    excTaxAmount) ??
                                                                0,
                                                            incTax: num.tryParse(
                                                                    incTaxAmount) ??
                                                                0,
                                                            groupTaxName:
                                                                selectedGroupTaxModel
                                                                        ?.name ??
                                                                    '',
                                                            groupTaxRate:
                                                                selectedGroupTaxModel
                                                                        ?.taxRate ??
                                                                    0,
                                                            subTaxes:
                                                                selectedGroupTaxModel
                                                                        ?.subTaxes ??
                                                                    [],
                                                          );
                                                          await productInformationRef
                                                              .push()
                                                              .set(productModel
                                                                  .toJson());

                                                          Subscription
                                                              .decreaseSubscriptionLimits(
                                                                  itemType:
                                                                      'products',
                                                                  context:
                                                                      context);

                                                          EasyLoading.showSuccess(
                                                              'Added Successfully',
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500));
                                                          ref.refresh(
                                                              productProvider);
                                                          Future.delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      100), () {
                                                            context.pop();
                                                          });
                                                        } catch (e) {
                                                          setState(() {
                                                            saleButtonClicked =
                                                                false;
                                                          });
                                                          EasyLoading.dismiss();
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      e.toString())));
                                                        }
                                                      } else {
                                                        EasyLoading.showInfo(
                                                            'Fill all required field');
                                                      }
                                                    }
                                                  } else {
                                                    EasyLoading.showInfo(
                                                        demoText);
                                                  }
                                                },
                                          child: Text(lang.S.of(context).save),
                                        ),
                                      ))
                                ]),

                                ///____Image__________________
                                Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: kWhite),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomDottedBorder(
                                        // padding: const EdgeInsets.all(6),
                                        color: kLitGreyColor,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          child: image != null
                                              ? Image.memory(
                                                  fit: BoxFit.cover,
                                                  image!,
                                                  // width: 150,
                                                  height: 150,
                                                )
                                              : Container(
                                                  height: 150,
                                                  alignment: Alignment.center,
                                                  width: context.width(),
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          SvgPicture.asset(
                                                                  'images/blank_image.svg')
                                                              .onTap(
                                                            () => uploadFile(),
                                                          ),
                                                          // Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: 5.0),
                                                      RichText(
                                                          textAlign:
                                                              TextAlign.center,
                                                          text: TextSpan(
                                                              text: lang.S
                                                                  .of(context)
                                                                  .uploadAImage,
                                                              style: theme
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                color:
                                                                    kGreenTextColor,
                                                              ),
                                                              children: [
                                                                TextSpan(
                                                                    text: lang.S
                                                                        .of(
                                                                            context)
                                                                        .orDragAndDropPng,
                                                                    style: theme
                                                                        .textTheme
                                                                        .titleMedium
                                                                        ?.copyWith(
                                                                            color:
                                                                                kGreyTextColor))
                                                              ]))
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ]),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool isSerialNumberUnique(
      {required List<String> allList, required String newSerial}) {
    for (var element in allList) {
      if (element.toLowerCase().removeAllWhiteSpace() ==
          newSerial.toLowerCase().removeAllWhiteSpace()) {
        return false;
      }
    }
    return true;
  }
}
