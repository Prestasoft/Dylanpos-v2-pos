import 'dart:html' as html;

import 'package:excel/excel.dart' as e;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/product_provider.dart';
import '../../const.dart';
import '../../model/category_model.dart';
import '../../model/product_model.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';

class BulkProductUploadPopup extends StatefulWidget {
  const BulkProductUploadPopup({super.key, required this.allProductsNameList, required this.allProductsCodeList});

  final List<String> allProductsNameList;
  final List<String> allProductsCodeList;

  @override
  State<BulkProductUploadPopup> createState() => _BulkProductUploadPopupState();
}

class _BulkProductUploadPopupState extends State<BulkProductUploadPopup> {
  FilePickerResult? pickedFile;
  List<String> allNameInThisFile = [];
  List<String> allCodeInThisFile = [];
  List<String> allCategory = [];

  Future<ProductModel?> createProductModelFromExcelData({required List<e.Data?> row, required WidgetRef ref}) async {
    List<String> getSerialNumbers(String? serialNumberString) {
      List<String> data = serialNumberString?.split(",") ?? [];
      List<String> data2 = [];
      for (var element in data) {
        data2.add(element.removeAllWhiteSpace().trim());
      }
      return data2;
    }

    bool isProductNameUnique({required String? productName}) {
      for (var name in widget.allProductsNameList) {
        if (name.toLowerCase().trim() == productName?.trim().toLowerCase()) {
          return false;
        }
      }
      for (var element in allNameInThisFile) {
        if (element.toLowerCase().trim() == productName?.trim().toLowerCase()) {
          return false;
        }
      }

      productName != null ? allNameInThisFile.add(productName) : null;

      return true;
    }

    bool isProductCodeUnique({required String? productCode}) {
      for (var name in widget.allProductsCodeList) {
        if (name.toLowerCase().trim() == productCode?.trim().toLowerCase()) {
          return false;
        }
      }
      for (var element in allCodeInThisFile) {
        if (element.toLowerCase().trim() == productCode?.trim().toLowerCase()) {
          return false;
        }
      }

      productCode != null ? allCodeInThisFile.add(productCode) : null;

      return true;
    }

    String productPicture = 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672';

    ProductModel productModel = ProductModel(
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      productPicture,
      [],
      lowerStockAlert: 0,
      taxType: '',
      margin: 0,
      excTax: 0,
      incTax: 0,
      groupTaxName: '',
      groupTaxRate: 0,
      subTaxes: [],
    );
    for (var element in row) {
      if (element?.rowIndex == 0) {
        return null;
      }
      switch (element?.columnIndex) {
        case 1:
          if (element?.value == null || !isProductNameUnique(productName: element?.value.toString())) return null;
          productModel.productName = element?.value.toString() ?? '';
          break;
        case 2:
          if (element?.value == null || !isProductCodeUnique(productCode: element?.value.toString())) return null;
          productModel.productCode = element?.value.toString() ?? '';
          break;
        case 3:
          if (element?.value == null && num.tryParse(element?.value.toString() ?? '') != null) return null;
          productModel.productStock = element?.value.toString() ?? '';
          break;
        case 5:
          if (element?.value == null && num.tryParse(element?.value.toString() ?? '') != null) return null;
          productModel.productSalePrice = element?.value.toString() ?? '';
          break;
        case 4:
          if (element?.value == null && num.tryParse(element?.value.toString() ?? '') != null) return null;
          productModel.productPurchasePrice = element?.value.toString() ?? '';
          break;
        case 6:
          element?.value != null ? productModel.productWholeSalePrice = element!.value.toString() : null;
          break;
        case 7:
          element?.value != null ? productModel.productDealerPrice = element!.value.toString() : null;
          break;
        case 8:
          if (element?.value == null) return null;
          productModel.productCategory = await getCategoryFromDatabase(ref: ref, givenCategoryName: element!.value.toString());
          break;
        case 9:
          // productModel.brandName = getBrandsFromDatabase(ref: ref, givenBrandName: element?.value.toString()) ?? '';
          element?.value != null ? productModel.brandName = element!.value.toString() : null;
          break;
        case 10:
          // productModel.productUnit = getUnitFromDatabase(ref: ref, givenUnitName: element?.value.toString()) ?? '';
          element?.value != null ? productModel.productUnit = element!.value.toString() : null;
          break;
        case 11:
          element?.value != null ? productModel.productManufacturer = element!.value.toString() : null;
          break;
        case 12:
          element?.value != null ? productModel.manufacturingDate = element?.value.toString() : null;
          break;
        case 13:
          element?.value != null ? productModel.expiringDate = element?.value.toString() : null;
          break;
        case 14:
          productModel.lowerStockAlert = int.tryParse(element?.value.toString() ?? '') ?? 0;
          break;
        case 15:
          element?.value != null ? productModel.serialNumber = getSerialNumbers(element?.value.toString()) : null;
          break;
      }
    }
    return productModel;
  }

  Future<String> getCategoryFromDatabase({required WidgetRef ref, required String givenCategoryName}) async {
    final categoryData = ref.watch(categoryProvider);
    categoryData.when(
      data: (categories) async {
        bool pos = true;
        for (var element in categories) {
          if (element.categoryName.toLowerCase().trim() == givenCategoryName.toLowerCase().trim()) {
            pos = false;
            break;
          }
        }
        for (var element in allCategory) {
          if (element.toLowerCase().trim() == givenCategoryName.toLowerCase().trim()) {
            pos = false;
            break;
          }
        }
        pos ? await addCategory(categoryName: givenCategoryName) : null;
        allCategory.add(givenCategoryName.trim().toLowerCase());

        return givenCategoryName;
      },
      error: (error, stackTrace) {},
      loading: () {},
    );
    return givenCategoryName;
  }

  Future<void> addCategory({required String categoryName}) async {
    final DatabaseReference categoryInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories');

    CategoryModel categoryModel = CategoryModel(
      categoryName: categoryName,
      size: false,
      color: false,
      capacity: false,
      type: false,
      weight: false,
      warranty: false,
    );
    await categoryInformationRef.push().set(categoryModel.toJson());
  }

  String printSerialNumber(List<String> numberList) {
    String finalString = '';
    for (var element in numberList) {
      finalString + element;
    }

    return finalString;
  }

  Future<void> uploadProducts({
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    var bytes = pickedFile!.files.single.bytes;
    var excel = e.Excel.decodeBytes(bytes as List<int>);

    var sheet = excel.sheets.keys.first;
    var table = excel.tables[sheet]!;

    for (var row in table.rows) {
      ProductModel? data = await createProductModelFromExcelData(row: row, ref: ref);
      if (data != null) {
        final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Products');
        await productInformationRef.push().set(data.toJson());
        Subscription.decreaseSubscriptionLimits(itemType: 'products', context: context);
      }
    }
    ref.refresh(productProvider);
    ref.refresh(categoryProvider);

    Future.delayed(const Duration(seconds: 1), () {
      EasyLoading.showSuccess(lang.S.of(context).uploadDone);

      context.pop();
    });
  }

  pickExcelFile() async {
    pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    setState(() {});
  }

  Future<void> downloadFile() async {
    final storage = FirebaseStorage.instance;
    // final ref = storage.ref('gs://pos-saas-a7b6c.appspot.com/POS_Bharat_bulk_product_upload.xlsx');
    final ref = storage.ref('gs://pos-saas-a7b6c.appspot.com/POS_SAAS_bulk_product_upload.xlsx');
    try {
      final url = await ref.getDownloadURL();
      final anchor = html.AnchorElement(href: url);
      anchor.download = 'excel_file.xlsx';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } catch (error) {
      print(error); // Handle any errors
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child:

          ///_________Upload Excel_________________________
          Consumer(builder: (__, ref, _) {
        return Container(
          width: 500,
          padding: const EdgeInsets.only(bottom: 20, right: 20, left: 20, top: 0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhite),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: const Icon(Icons.close)),
              ResponsiveGridRow(children: [
                ResponsiveGridCol(
                  xs: screenWidth < 510 ? 12 : 6,
                  md: 6,
                  lg: 6,
                  child: Text(
                    lang.S.of(context).bulkProductUpload,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                ResponsiveGridCol(
                  xs: screenWidth < 510 ? 12 : 6,
                  md: 6,
                  lg: 6,
                  child: InkWell(
                      splashColor: kMainColor100,
                      onTap: () => downloadFile(),
                      child: Text(
                        lang.S.of(context).downloadExcelFormat,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: kMainColor,
                        ),
                        textAlign: TextAlign.start,
                      )),
                ),
              ]),
              const SizedBox(height: 10.0),
              DottedBorderWidget(
                padding: const EdgeInsets.all(6),
                color: kLitGreyColor,
                child:
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: Container(
                    width: context.width(),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      children: [
                        pickedFile == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(MdiIcons.microsoftExcel, size: 50.0, color: kLitGreyColor).onTap(() => pickExcelFile()),
                                  const SizedBox(height: 5.0),
                                  RichText(textAlign: TextAlign.center, text: TextSpan(text: lang.S.of(context).uploadAnExcel, style: kTextStyle.copyWith(color: kGreenTextColor, fontWeight: FontWeight.bold), children: [TextSpan(text: lang.S.of(context).orDragdropXlsx, style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold))])),
                                  const SizedBox(height: 5.0),
                                ],
                              )
                            : ListTile(
                                leading: Icon(MdiIcons.microsoftExcel, size: 50.0, color: CupertinoColors.activeGreen),
                                title: Text(lang.S.of(context).AnExcelFilePicked),
                                trailing: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        pickedFile = null;
                                      });
                                    },
                                    child: Text(lang.S.of(context).remove)),
                              ),
                        Visibility(
                          visible: pickedFile != null,
                          child: ElevatedButton(
                              style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(kMainColor)),
                              onPressed: () async {
                                EasyLoading.show(status: '${lang.S.of(context).uploading}...');
                                await uploadProducts(context: context, ref: ref);
                              },
                              child: Text(
                                lang.S.of(context).upload,
                                style: const TextStyle(color: Colors.white),
                              )),
                        )
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
        );
      }),
    );
  }
}
