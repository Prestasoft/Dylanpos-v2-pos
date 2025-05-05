import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/tax%20rates/tax_model.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/product_model.dart';

import '../../Provider/product_provider.dart';
import '../../const.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';
import 'WarebasedProduct.dart';
import 'bulk.dart';

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  // int selectedItem = 10;
  int itemsPerPage = 10;
  String searchItem = '';
  bool isRegularSelected = true;

  List<String> title = ['Product List', 'Expired List'];

  String isSelected = 'Product List';

  // void productStockEditPopUp({required ProductModel product, required BuildContext popUp, required WidgetRef pref}) {
  //   final ref = FirebaseDatabase.instance.ref(constUserId).child('Products');
  //   String productKey = '';
  //   ref.keepSynced(true);
  //
  //   ref.orderByKey().get().then((value) {
  //     for (var element in value.children) {
  //       var data = jsonDecode(jsonEncode(element.value));
  //       if (data['productCode'].toString() == product.productCode) {
  //         productKey = element.key.toString();
  //       }
  //     }
  //   });
  //
  //   TextEditingController stockController = TextEditingController(text: '0');
  //   TextEditingController saleController = TextEditingController(text: myFormat.format(double.tryParse(product.productSalePrice) ?? 0));
  //   TextEditingController purchaseController = TextEditingController(text: myFormat.format(double.tryParse(product.productPurchasePrice) ?? 0));
  //   TextEditingController wholeSeller = TextEditingController(text: myFormat.format(double.tryParse(product.productWholeSalePrice) ?? 0));
  //   TextEditingController dealer = TextEditingController(text: myFormat.format(double.tryParse(product.productDealerPrice) ?? 0));
  //
  //   String stock = '0';
  //   String productSalePrice = product.productSalePrice;
  //   String productPurchasePrice = product.productPurchasePrice;
  //   String productWholePrice = product.productWholeSalePrice;
  //   String productDealerPrice = product.productDealerPrice;
  //
  //   GlobalKey<FormState> priceKey = GlobalKey<FormState>();
  //   bool validateAndSave() {
  //     final form = priceKey.currentState;
  //     if (form!.validate()) {
  //       form.save();
  //       return true;
  //     }
  //     return false;
  //   }
  //
  //   showDialog(
  //     barrierDismissible: false,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context1, setState1) {
  //           return Dialog(
  //             surfaceTintColor: Colors.white,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(5.0),
  //             ),
  //             child: SizedBox(
  //               width: 500,
  //               child: Padding(
  //                 padding: const EdgeInsets.all(10.0),
  //                 child: SingleChildScrollView(
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             "${product.productName} (${product.productStock})",
  //                             style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 20.0),
  //                           ),
  //                           const Spacer(),
  //                           const Icon(FeatherIcons.x, color: kTitleColor, size: 25.0).onTap(() => {finish(context)})
  //                         ],
  //                       ),
  //                       const Divider(thickness: 1.0, color: kLitGreyColor),
  //                       const SizedBox(height: 10.0),
  //                       Form(
  //                         key: priceKey,
  //                         child: Column(
  //                           children: [
  //                             TextFormField(
  //                               controller: stockController,
  //                               onChanged: (value) {
  //                                 stock = value.replaceAll(',', '');
  //                                 var formattedText = myFormat.format(num.parse(stock));
  //                                 stockController.value = stockController.value.copyWith(
  //                                   text: formattedText,
  //                                   selection: TextSelection.collapsed(offset: formattedText.length),
  //                                 );
  //                               },
  //                               validator: (value) {
  //                                 if (stock.isEmptyOrNull) {
  //                                   return 'Please enter Stock';
  //                                 } else if (double.tryParse(stock) == null && stock.isEmptyOrNull) {
  //                                   return 'Enter Stock in number.';
  //                                 } else {
  //                                   return null;
  //                                 }
  //                               },
  //                               showCursor: true,
  //                               cursorColor: kTitleColor,
  //                               decoration: kInputDecoration.copyWith(
  //                                 border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
  //                                 labelText: lang.S.of(context).productStock,
  //                                 hintText: lang.S.of(context).pleaseEnterProductStock,
  //                                 hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
  //                                 labelStyle: kTextStyle.copyWith(color: kTitleColor),
  //                               ),
  //                             ),
  //                             const SizedBox(height: 20),
  //                             Row(
  //                               children: [
  //                                 Expanded(
  //                                   child: TextFormField(
  //                                     controller: purchaseController,
  //                                     onChanged: (value) {
  //                                       productPurchasePrice = value.replaceAll(',', '');
  //                                       var formattedText = myFormat.format(num.parse(productPurchasePrice));
  //                                       purchaseController.value = purchaseController.value.copyWith(
  //                                         text: formattedText,
  //                                         selection: TextSelection.collapsed(offset: formattedText.length),
  //                                       );
  //                                     },
  //                                     validator: (value) {
  //                                       if (productPurchasePrice.isEmptyOrNull) {
  //                                         return 'Please enter Purchase Price';
  //                                       } else if (double.tryParse(productPurchasePrice) == null && productPurchasePrice.isEmptyOrNull) {
  //                                         return 'Enter Price in number.';
  //                                       } else {
  //                                         return null;
  //                                       }
  //                                     },
  //                                     showCursor: true,
  //                                     cursorColor: kTitleColor,
  //                                     decoration: kInputDecoration.copyWith(
  //                                       border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
  //                                       labelText: lang.S.of(context).purchasePrice,
  //                                       hintText: lang.S.of(context).enterPurchasePrice,
  //                                       hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
  //                                       labelStyle: kTextStyle.copyWith(color: kTitleColor),
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 20),
  //                                 Expanded(
  //                                   child: TextFormField(
  //                                     controller: saleController,
  //                                     onChanged: (value) {
  //                                       productSalePrice = value.replaceAll(',', '');
  //                                       var formattedText = myFormat.format(num.parse(productSalePrice));
  //                                       saleController.value = saleController.value.copyWith(
  //                                         text: formattedText,
  //                                         selection: TextSelection.collapsed(offset: formattedText.length),
  //                                       );
  //                                     },
  //                                     validator: (value) {
  //                                       if (productSalePrice.isEmptyOrNull) {
  //                                         return 'Please enter Sale Price';
  //                                       } else if (double.tryParse(productSalePrice) == null && productSalePrice.isEmptyOrNull) {
  //                                         return 'Enter Price in number.';
  //                                       } else {
  //                                         return null;
  //                                       }
  //                                     },
  //                                     showCursor: true,
  //                                     cursorColor: kTitleColor,
  //                                     decoration: kInputDecoration.copyWith(
  //                                       border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
  //                                       labelText: lang.S.of(context).salePrices,
  //                                       hintText: lang.S.of(context).enterSalePrice,
  //                                       hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
  //                                       labelStyle: kTextStyle.copyWith(color: kTitleColor),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                             const SizedBox(height: 20),
  //                             Row(
  //                               children: [
  //                                 Expanded(
  //                                   child: TextFormField(
  //                                     controller: dealer,
  //                                     onChanged: (value) {
  //                                       productDealerPrice = value.replaceAll(',', '');
  //                                       var formattedText = myFormat.format(num.parse(productDealerPrice));
  //                                       dealer.value = dealer.value.copyWith(
  //                                         text: formattedText,
  //                                         selection: TextSelection.collapsed(offset: formattedText.length),
  //                                       );
  //                                     },
  //                                     validator: (value) {
  //                                       return null;
  //                                     },
  //                                     showCursor: true,
  //                                     cursorColor: kTitleColor,
  //                                     decoration: kInputDecoration.copyWith(
  //                                       border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
  //                                       labelText: lang.S.of(context).dealerPrice,
  //                                       hintText: lang.S.of(context).enterDealePrice,
  //                                       hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
  //                                       labelStyle: kTextStyle.copyWith(color: kTitleColor),
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 20),
  //                                 Expanded(
  //                                   child: TextFormField(
  //                                     controller: wholeSeller,
  //                                     onChanged: (value) {
  //                                       productWholePrice = value.replaceAll(',', '');
  //                                       var formattedText = myFormat.format(num.parse(productWholePrice));
  //                                       wholeSeller.value = wholeSeller.value.copyWith(
  //                                         text: formattedText,
  //                                         selection: TextSelection.collapsed(offset: formattedText.length),
  //                                       );
  //                                     },
  //                                     validator: (value) {
  //                                       return null;
  //                                     },
  //                                     showCursor: true,
  //                                     cursorColor: kTitleColor,
  //                                     decoration: kInputDecoration.copyWith(
  //                                       border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
  //                                       labelText: lang.S.of(context).wholeSaleprice,
  //                                       hintText: lang.S.of(context).enterPrice,
  //                                       hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
  //                                       labelStyle: kTextStyle.copyWith(color: kTitleColor),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                       const SizedBox(height: 20),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Container(
  //                               padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(5.0),
  //                                 color: kRedTextColor,
  //                               ),
  //                               child: Text(
  //                                 lang.S.of(context).cancel,
  //                                 style: kTextStyle.copyWith(color: kWhite),
  //                               )).onTap(() {
  //                             // context.pop();
  //                             GoRouter.of(context).pop();
  //                           }),
  //                           const SizedBox(width: 10.0),
  //                           GestureDetector(
  //                             onTap: () {
  //                               if (finalUserRoleModel.productEdit == false) {
  //                                 EasyLoading.showError(userPermissionErrorText);
  //                                 return;
  //                               }
  //                               if (validateAndSave()) {
  //                                 DatabaseReference ref = FirebaseDatabase.instance.ref("$constUserId/Products/$productKey");
  //                                 ref.keepSynced(true);
  //                                 ref.update({
  //                                   'productStock': ((num.tryParse(stock) ?? 0) + (num.tryParse(product.productStock) ?? 0)).toString(),
  //                                   // 'productStock': stockController.text,
  //                                   'productSalePrice': productSalePrice,
  //                                   'productPurchasePrice': productPurchasePrice,
  //                                   'productWholeSalePrice': productWholePrice,
  //                                   'productDealerPrice': productDealerPrice,
  //                                 });
  //                                 EasyLoading.showSuccess('Done');
  //                                 pref.refresh(productProvider);
  //                                 GoRouter.of(context).pop();
  //                               }
  //                             },
  //                             child: Container(
  //                               padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(5.0),
  //                                 color: kBlueTextColor,
  //                               ),
  //                               child: Text(
  //                                 lang.S.of(context).submit,
  //                                 style: kTextStyle.copyWith(color: kWhite),
  //                               ),
  //                             ),
  //                           )
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> productStockEditPopUp(
      {required ProductModel product,
      required BuildContext popUp,
      required WidgetRef pref}) async {
    TextEditingController stockController = TextEditingController(text: '0');
    TextEditingController saleController = TextEditingController(
        text: myFormat.format(double.tryParse(product.productSalePrice) ?? 0));
    TextEditingController purchaseController = TextEditingController(
        text: myFormat
            .format(double.tryParse(product.productPurchasePrice) ?? 0));
    TextEditingController wholeSeller = TextEditingController(
        text: myFormat
            .format(double.tryParse(product.productWholeSalePrice) ?? 0));
    TextEditingController dealer = TextEditingController(
        text:
            myFormat.format(double.tryParse(product.productDealerPrice) ?? 0));

    String stock = '0';
    String productSalePrice = product.productSalePrice;
    String productPurchasePrice = product.productPurchasePrice;
    String productWholePrice = product.productWholeSalePrice;
    String productDealerPrice = product.productDealerPrice;

    GlobalKey<FormState> priceKey = GlobalKey<FormState>();
    bool validateAndSave() {
      final form = priceKey.currentState;
      if (form!.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    await showDialog(
      barrierDismissible: false,
      context: popUp,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context1, setState1) {
            return Dialog(
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "${product.productName} (${product.productStock})",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              onPressed: () => GoRouter.of(context).pop(),
                              icon: Icon(
                                FeatherIcons.x,
                                color: kGreyTextColor,
                                size: 25.0,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(
                        thickness: 1.0,
                        color: kNeutral300,
                        height: 1,
                      ),
                      const SizedBox(height: 10.0),
                      Form(
                        key: priceKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                controller: stockController,
                                onChanged: (value) {
                                  stock = value.replaceAll(',', '');
                                  var formattedText =
                                      myFormat.format(num.parse(stock));
                                  stockController.value =
                                      stockController.value.copyWith(
                                    text: formattedText,
                                    selection: TextSelection.collapsed(
                                        offset: formattedText.length),
                                  );
                                },
                                validator: (value) {
                                  if (stock.isEmptyOrNull) {
                                    return 'Please enter Stock';
                                  } else if (double.tryParse(stock) == null &&
                                      stock.isEmptyOrNull) {
                                    return 'Enter Stock in number.';
                                  } else {
                                    return null;
                                  }
                                },
                                showCursor: true,
                                cursorColor: kTitleColor,
                                decoration: InputDecoration(
                                  labelText: lang.S.of(context).productStock,
                                  hintText: lang.S
                                      .of(context)
                                      .pleaseEnterProductStock,
                                ),
                              ),
                            ),
                            ResponsiveGridRow(children: [
                              ResponsiveGridCol(
                                  md: 6,
                                  lg: 6,
                                  xs: 12,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      controller: purchaseController,
                                      onChanged: (value) {
                                        productPurchasePrice =
                                            value.replaceAll(',', '');
                                        var formattedText = myFormat.format(
                                            num.parse(productPurchasePrice));
                                        purchaseController.value =
                                            purchaseController.value.copyWith(
                                          text: formattedText,
                                          selection: TextSelection.collapsed(
                                              offset: formattedText.length),
                                        );
                                      },
                                      validator: (value) {
                                        if (productPurchasePrice
                                            .isEmptyOrNull) {
                                          return 'Please enter Purchase Price';
                                        } else if (double.tryParse(
                                                    productPurchasePrice) ==
                                                null &&
                                            productPurchasePrice
                                                .isEmptyOrNull) {
                                          return 'Enter Price in number.';
                                        } else {
                                          return null;
                                        }
                                      },
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      decoration: InputDecoration(
                                        labelText:
                                            lang.S.of(context).purchasePrice,
                                        hintText: lang.S
                                            .of(context)
                                            .enterPurchasePrice,
                                      ),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                  md: 6,
                                  lg: 6,
                                  xs: 12,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      controller: saleController,
                                      onChanged: (value) {
                                        productSalePrice =
                                            value.replaceAll(',', '');
                                        var formattedText = myFormat.format(
                                            num.parse(productSalePrice));
                                        saleController.value =
                                            saleController.value.copyWith(
                                          text: formattedText,
                                          selection: TextSelection.collapsed(
                                              offset: formattedText.length),
                                        );
                                      },
                                      validator: (value) {
                                        if (productSalePrice.isEmptyOrNull) {
                                          return 'Please enter Sale Price';
                                        } else if (double.tryParse(
                                                    productSalePrice) ==
                                                null &&
                                            productSalePrice.isEmptyOrNull) {
                                          return 'Enter Price in number.';
                                        } else {
                                          return null;
                                        }
                                      },
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      decoration: InputDecoration(
                                        labelText:
                                            lang.S.of(context).salePrices,
                                        hintText:
                                            lang.S.of(context).enterSalePrice,
                                      ),
                                    ),
                                  ))
                            ]),
                            ResponsiveGridRow(children: [
                              ResponsiveGridCol(
                                  md: 6,
                                  lg: 6,
                                  xs: 123,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      controller: dealer,
                                      onChanged: (value) {
                                        productDealerPrice =
                                            value.replaceAll(',', '');
                                        var formattedText = myFormat.format(
                                            num.parse(productDealerPrice));
                                        dealer.value = dealer.value.copyWith(
                                          text: formattedText,
                                          selection: TextSelection.collapsed(
                                              offset: formattedText.length),
                                        );
                                      },
                                      validator: (value) {
                                        return null;
                                      },
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      decoration: InputDecoration(
                                        labelText:
                                            lang.S.of(context).dealerPrice,
                                        hintText:
                                            lang.S.of(context).enterDealePrice,
                                      ),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                  md: 6,
                                  lg: 6,
                                  xs: 12,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      controller: wholeSeller,
                                      onChanged: (value) {
                                        productWholePrice =
                                            value.replaceAll(',', '');
                                        var formattedText = myFormat.format(
                                            num.parse(productWholePrice));
                                        wholeSeller.value =
                                            wholeSeller.value.copyWith(
                                          text: formattedText,
                                          selection: TextSelection.collapsed(
                                              offset: formattedText.length),
                                        );
                                      },
                                      validator: (value) {
                                        return null;
                                      },
                                      showCursor: true,
                                      cursorColor: kTitleColor,
                                      decoration: InputDecoration(
                                        labelText:
                                            lang.S.of(context).wholeSaleprice,
                                        hintText: lang.S.of(context).enterPrice,
                                      ),
                                    ),
                                  ))
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                            md: 6,
                            lg: 6,
                            xs: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () => GoRouter.of(context).pop(),
                                  child: Text(
                                    lang.S.of(context).cancel,
                                  )),
                            )),
                        ResponsiveGridCol(
                            md: 6,
                            lg: 6,
                            xs: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (finalUserRoleModel.productEdit == false) {
                                    EasyLoading.showError(
                                        userPermissionErrorText);
                                    return;
                                  }
                                  if (validateAndSave()) {
                                    final userID = await getUserID();
                                    final ref = FirebaseDatabase.instance
                                        .ref(userID)
                                        .child('Products');
                                    String productKey = '';

                                    await ref.orderByKey().get().then((value) {
                                      for (var element in value.children) {
                                        var data = jsonDecode(
                                            jsonEncode(element.value));
                                        if (data['productCode'].toString() ==
                                            product.productCode) {
                                          productKey = element.key.toString();
                                        }
                                      }
                                    });

                                    await ref.child(productKey).update({
                                      'productStock': ((num.tryParse(stock) ??
                                                  0) +
                                              (num.tryParse(
                                                      product.productStock) ??
                                                  0))
                                          .toString(),
                                      // 'productStock': stockController.text,
                                      'productSalePrice': productSalePrice,
                                      'productPurchasePrice':
                                          productPurchasePrice,
                                      'productWholeSalePrice':
                                          productWholePrice,
                                      'productDealerPrice': productDealerPrice,
                                    });
                                    EasyLoading.showSuccess('Done');
                                    // ignore: unused_result
                                    pref.refresh(productProvider);
                                    GoRouter.of(context).pop();
                                    // Navigator.pop(popUp);
                                  }
                                },
                                child: Text(
                                  lang.S.of(context).submit,
                                ),
                              ),
                            )),
                      ]),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void deleteProduct({
    required String productCode,
    required WidgetRef updateProduct,
    required BuildContext context,
  }) async {
    EasyLoading.show(status: 'Deleting..');

    try {
      String userId = await getUserID(); // Get User ID first
      DatabaseReference productRef =
          FirebaseDatabase.instance.ref('$userId/Products');

      DataSnapshot snapshot = await productRef.orderByKey().get();

      String customerKey = '';

      for (var element in snapshot.children) {
        var data = jsonDecode(jsonEncode(element.value));

        if (data['productCode'].toString() == productCode) {
          customerKey = element.key.toString();
          break; // Exit loop as soon as the key is found
        }
      }

      if (customerKey.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref('$userId/Products/$customerKey')
            .remove();
        final _ = updateProduct.refresh(productProvider); // Refresh UI
        EasyLoading.showSuccess('Product Deleted');
      } else {
        EasyLoading.showError('Product Not Found');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  ScrollController mainScroll = ScrollController();

  final int _productsPerPage = 10; // Default number of items to display
  int _currentPage = 1;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    print('Build Called');
    List<String> allProductsNameList = [];
    List<String> allProductsCodeList = [];
    List<WarehouseBasedProductModel> warehouseBasedProductModel = [];
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Consumer(
        builder: (_, ref, watch) {
          AsyncValue<List<ProductModel>> productList =
              ref.watch(productProvider);
          final groupTax = ref.watch(groupTaxProvider);
          return productList.when(data: (allProducts) {
            List<ProductModel> showAbleProducts = [];
            for (var element in allProducts) {
              allProductsNameList
                  .add(element.productName.removeAllWhiteSpace().toLowerCase());
              allProductsCodeList
                  .add(element.productCode.removeAllWhiteSpace().toLowerCase());
              warehouseBasedProductModel.add(WarehouseBasedProductModel(
                  element.productName, element.warehouseId));
              if (!isRegularSelected) {
                if (((element.productName
                            .removeAllWhiteSpace()
                            .toLowerCase()
                            .contains(searchItem.toLowerCase()) ||
                        element.productName.contains(searchItem))) &&
                    element.expiringDate != null &&
                    ((DateTime.tryParse(element.expiringDate ?? '') ??
                            DateTime.now())
                        .isBefore(
                            DateTime.now().add(const Duration(days: 7))))) {
                  showAbleProducts.add(element);
                }
              } else {
                if (searchItem != '' &&
                    (element.productName
                            .removeAllWhiteSpace()
                            .toLowerCase()
                            .contains(searchItem.toLowerCase()) ||
                        element.productName.contains(searchItem))) {
                  showAbleProducts.add(element);
                } else if (searchItem == '') {
                  showAbleProducts.add(element);
                }
              }
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                // width: context.width() < 1080 ? 1080 - 240 : MediaQuery.of(context).size.width - 240,
                // width: MediaQuery.of(context).size.width < 1275 ? 1275 - 240 : MediaQuery.of(context).size.width - 240,
                decoration: const BoxDecoration(color: kDarkWhite),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), color: kWhite),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                        child: Text(
                          lang.S.of(context).productList,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1.0,
                        color: kDividerColor,
                      ),
                      //---------------------search---------------------------
                      const SizedBox(height: 16),

                      ///________title and add product_______________________________________
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: kNeutral300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: Text('Show-',
                                          style: theme.textTheme.bodyLarge)),
                                  DropdownButton<int>(
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    underline: const SizedBox(),
                                    value: itemsPerPage,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                    items: [
                                      10,
                                      20,
                                      50,
                                      100,
                                      -1
                                    ].map<DropdownMenuItem<int>>((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text(
                                          value == -1
                                              ? "All"
                                              : value.toString(),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        if (newValue == -1) {
                                          itemsPerPage =
                                              -1; // Set to -1 for "All"
                                        } else {
                                          itemsPerPage = newValue ?? 10;
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
                            child: AppTextField(
                              showCursor: true,
                              cursorColor: kTitleColor,
                              onChanged: (value) {
                                setState(() {
                                  searchItem = value;
                                });
                              },
                              textFieldType: TextFieldType.NAME,
                              decoration: InputDecoration(
                                hintText:
                                    lang.S.of(context).searchByInvoiceOrName,
                                suffixIcon: const Icon(
                                  FeatherIcons.search,
                                  color: kNeutral700,
                                ),
                              ),
                            ),
                          ),
                        )
                      ]),

                      ResponsiveGridRow(rowSegments: 120, children: [
                        //------------product list----------------
                        ResponsiveGridCol(
                          lg: screenWidth < 1700 ? 20 : 15,
                          md: screenWidth < 780 ? 35 : 24,
                          xs: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 42,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentPage = 1;
                                    isSelected = title[0];
                                    isRegularSelected = true;
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    color: isSelected == title[0]
                                        ? kBlueTextColor
                                        : white,
                                    border: Border.all(
                                      color: isSelected == title[0]
                                          ? kBlueTextColor
                                          : kBorderColorTextField,
                                    ),
                                  ),
                                  child: Text(
                                    title[0],
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: isSelected == title[0]
                                          ? kWhite
                                          : kTitleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          lg: screenWidth < 1700 ? 20 : 15,
                          md: screenWidth < 780 ? 35 : 24,
                          xs: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 42,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentPage = 2;
                                    isSelected = title[1];
                                    isRegularSelected = false;
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    color: isSelected == title[1]
                                        ? kBlueTextColor
                                        : white,
                                    border: Border.all(
                                      color: isSelected == title[1]
                                          ? kBlueTextColor
                                          : kBorderColorTextField,
                                    ),
                                  ),
                                  child: Text(
                                    title[1],
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: isSelected == title[1]
                                          ? kWhite
                                          : kTitleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        //---------------expire list----------------
                        // ResponsiveGridCol(
                        //   lg: 18,
                        //   md: 20,
                        //   xs: 40,
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(10.0),
                        //     child: SizedBox(
                        //       height: 42,
                        //       child: ListView.builder(
                        //           itemCount: 1,
                        //           shrinkWrap: true,
                        //           padding: EdgeInsets.zero,
                        //           scrollDirection: Axis.horizontal,
                        //           itemBuilder: (_, index) {
                        //             return InkWell(
                        //               onTap: () {
                        //                 setState(() {
                        //                   // isRegularSelected = index == 0;
                        //                   _currentPage = 1;
                        //                   isSelected = title[index];
                        //                   isRegularSelected = index == 0;
                        //                 });
                        //               },
                        //               child: Padding(
                        //                 padding: const EdgeInsets.only(right: 20.0),
                        //                 child: Container(
                        //                   alignment: Alignment.center,
                        //                   padding: const EdgeInsets.all(10.0),
                        //                   decoration: BoxDecoration(
                        //                       borderRadius: BorderRadius.circular(5.0),
                        //                       color: isSelected == title[index] ? kBlueTextColor : white,
                        //                       border: Border.all(
                        //                         color: isSelected == title[index] ? kBlueTextColor : kBorderColorTextField,
                        //                       )),
                        //                   child: Text(
                        //                     title[index],
                        //                     style: kTextStyle.copyWith(
                        //                       color: isSelected == title[index] ? kWhite : kTitleColor,
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //             );
                        //           }),
                        //     ),
                        //   ),
                        // ),
                        //-------------Balk upload-------------------
                        ResponsiveGridCol(
                          lg: screenWidth < 1700 ? 20 : 15,
                          md: screenWidth < 780 ? 35 : 24,
                          xs: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: kWhite,
                                  border:
                                      Border.all(color: kBorderColorTextField)),
                              child: Text(
                                "Bulk Upload",
                                style: theme.textTheme.titleSmall,
                              ),
                            ).onTap(() async {
                              await showDialog(
                                context: context,
                                builder: (context) => BulkProductUploadPopup(
                                    allProductsCodeList: allProductsCodeList,
                                    allProductsNameList: allProductsNameList),
                              );
                              setState(() {});
                            }),
                          ),
                        ),
                        //----------------------add product---------------
                        ResponsiveGridCol(
                          lg: screenWidth < 1700 ? 20 : 15,
                          md: screenWidth < 780 ? 30 : 24,
                          xs: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: kWhite,
                                  border:
                                      Border.all(color: kBorderColorTextField)),
                              child: Row(
                                children: [
                                  const Icon(FeatherIcons.plus,
                                      color: kTitleColor, size: 18.0),
                                  const SizedBox(width: 5.0),
                                  Flexible(
                                    child: Text(
                                      lang.S.of(context).addProduct,
                                      style: theme.textTheme.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ).onTap(() async {
                              if (await Subscription.subscriptionChecker(
                                  item: 'Products')) {
                                context.push(
                                  '/product/add-product',
                                  extra: {
                                    'allProductsCodeList': allProductsCodeList,
                                    'warehouseBasedProductModel': [],
                                  },
                                );
                              } else {
                                EasyLoading.showError(
                                    lang.S.of(context).updateYourPlanFirst);
                              }
                            }),
                          ),
                        ),
                        //-----------------------barcode generate------------------
                        ResponsiveGridCol(
                            lg: screenWidth < 1700 ? 20 : 15,
                            md: screenWidth < 780 ? 30 : 24,
                            xs: 60,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: InkWell(
                                onTap: () =>
                                    context.go('/product/barcode-generator'),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: kWhite,
                                      border: Border.all(
                                          color: kBorderColorTextField)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.qr_code,
                                          color: kTitleColor, size: 18.0),
                                      const SizedBox(width: 5.0),
                                      Flexible(
                                        child: Text(
                                          'Barcode Generate',
                                          style: theme.textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ]),

                      // ResponsiveGridRow(
                      //   children: [
                      //     ResponsiveGridCol(
                      //       xs: 12,
                      //       lg: 5,
                      //       md: 12,
                      //       child: ResponsiveGridRow(
                      //         children: [
                      //           //------------result-------------
                      //           // ResponsiveGridCol(
                      //           //   xs: 12,
                      //           //   md: 6,
                      //           //   lg: 4,
                      //           //   child: Padding(
                      //           //     padding: const EdgeInsets.all(10),
                      //           //     child: Container(
                      //           //       height: 48,
                      //           //       padding: const EdgeInsets.all(10),
                      //           //       decoration: BoxDecoration(
                      //           //         borderRadius: BorderRadius.circular(8.0),
                      //           //         border: Border.all(color: kNeutral300),
                      //           //       ),
                      //           //       child: Row(
                      //           //         mainAxisSize: MainAxisSize.min,
                      //           //         children: [
                      //           //           const Text('Result-'),
                      //           //           DropdownButton<int>(
                      //           //             isDense: true,
                      //           //             padding: EdgeInsets.zero,
                      //           //             underline: const SizedBox(),
                      //           //             value: _productsPerPage,
                      //           //             icon: const Icon(
                      //           //               Icons.keyboard_arrow_down,
                      //           //               color: Colors.black,
                      //           //             ),
                      //           //             items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                      //           //               return DropdownMenuItem<int>(
                      //           //                 value: value,
                      //           //                 child: Text(
                      //           //                   value == -1 ? "All" : value.toString(),
                      //           //                   style: const TextStyle(color: Colors.black),
                      //           //                 ),
                      //           //               );
                      //           //             }).toList(),
                      //           //             onChanged: (int? newValue) {
                      //           //               setState(() {
                      //           //                 if (newValue == -1) {
                      //           //                   _productsPerPage = -1; // Set to -1 for "All"
                      //           //                 } else {
                      //           //                   _productsPerPage = newValue ?? 10;
                      //           //                 }
                      //           //                 _currentPage = 1;
                      //           //               });
                      //           //             },
                      //           //           ),
                      //           //         ],
                      //           //       ),
                      //           //     ),
                      //           //   ),
                      //           // ),
                      //           //-----------search------------------
                      //           ResponsiveGridCol(
                      //             xs: 12,
                      //             md: 6,
                      //             lg: 8,
                      //             child: Padding(
                      //               padding: const EdgeInsets.all(10.0),
                      //               child: TextFormField(
                      //                 showCursor: true,
                      //                 cursorColor: kTitleColor,
                      //                 onChanged: (value) {
                      //                   setState(() {
                      //                     searchItem = value;
                      //                   });
                      //                 },
                      //                 keyboardType: TextInputType.name,
                      //                 decoration: InputDecoration(
                      //                   hintText: lang.S.of(context).searchByName,
                      //                   suffixIcon: const Padding(
                      //                     padding: EdgeInsets.all(4.0),
                      //                     child: Icon(
                      //                       FeatherIcons.search,
                      //                       color: kTitleColor,
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //     ResponsiveGridCol(xs: 0, lg: 1, md: 0, child: const SizedBox.shrink()),
                      //     ResponsiveGridCol(
                      //       xs: 12,
                      //       lg: 6,
                      //       md: 12,
                      //       child: ResponsiveGridRow(
                      //         rowSegments: 120,
                      //         children: [
                      //           //------------product list----------------
                      //           ResponsiveGridCol(
                      //             lg: 32,
                      //             md: 32,
                      //             xs: 40,
                      //             child: Padding(
                      //               padding: const EdgeInsets.all(10.0),
                      //               child: SizedBox(
                      //                 height: 42,
                      //                 child: ListView.builder(
                      //                   itemCount: 2,
                      //                   shrinkWrap: true,
                      //                   padding: EdgeInsets.zero,
                      //                   scrollDirection: Axis.horizontal,
                      //                   itemBuilder: (_, index) {
                      //                     return InkWell(
                      //                       onTap: () {
                      //                         setState(() {
                      //                           _currentPage = 1;
                      //                           isSelected = title[index];
                      //                           isRegularSelected = index == 0;
                      //                         });
                      //                       },
                      //                       child: Padding(
                      //                         padding: const EdgeInsets.only(right: 20.0),
                      //                         child: Container(
                      //                           alignment: Alignment.center,
                      //                           padding: const EdgeInsets.all(10.0),
                      //                           decoration: BoxDecoration(
                      //                             borderRadius: BorderRadius.circular(5.0),
                      //                             color: isSelected == title[index] ? kBlueTextColor : white,
                      //                             border: Border.all(
                      //                               color: isSelected == title[index] ? kBlueTextColor : kBorderColorTextField,
                      //                             ),
                      //                           ),
                      //                           child: Text(
                      //                             title[index],
                      //                             style: kTextStyle.copyWith(
                      //                               color: isSelected == title[index] ? kWhite : kTitleColor,
                      //                             ),
                      //                           ),
                      //                         ),
                      //                       ),
                      //                     );
                      //                   },
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //           //--------------Bulk upload--------------
                      //           ResponsiveGridCol(
                      //             lg: 26,
                      //             md: 26,
                      //             xs: 40,
                      //             child: Padding(
                      //               padding: const EdgeInsets.all(10.0),
                      //               child: Container(
                      //                 padding: const EdgeInsets.all(10.0),
                      //                 decoration: BoxDecoration(
                      //                   borderRadius: BorderRadius.circular(5.0),
                      //                   color: kWhite,
                      //                   border: Border.all(color: kBorderColorTextField),
                      //                 ),
                      //                 child: Text(
                      //                   "Bulk Upload",
                      //                   style: kTextStyle.copyWith(color: kTitleColor),
                      //                 ),
                      //               ).onTap(() async {
                      //                 await showDialog(
                      //                   context: context,
                      //                   builder: (context) => BulkProductUploadPopup(
                      //                     allProductsCodeList: allProductsCodeList,
                      //                     allProductsNameList: allProductsNameList,
                      //                   ),
                      //                 );
                      //                 setState(() {});
                      //               }),
                      //             ),
                      //           ),
                      //           //----------------------add product---------------
                      //           ResponsiveGridCol(
                      //             lg: 31,
                      //             md: 31,
                      //             xs: 40,
                      //             child: Padding(
                      //               padding: const EdgeInsets.all(10.0),
                      //               child: Container(
                      //                 padding: const EdgeInsets.all(10.0),
                      //                 decoration: BoxDecoration(
                      //                   borderRadius: BorderRadius.circular(5.0),
                      //                   color: kWhite,
                      //                   border: Border.all(color: kBorderColorTextField),
                      //                 ),
                      //                 child: Row(
                      //                   children: [
                      //                     const Icon(FeatherIcons.plus, color: kTitleColor, size: 18.0),
                      //                     const SizedBox(width: 5.0),
                      //                     Flexible(
                      //                       child: Text(
                      //                         lang.S.of(context).addProduct,
                      //                         style: kTextStyle.copyWith(color: kTitleColor),
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ).onTap(() async {
                      //                 if (await Subscription.subscriptionChecker(item: 'Products')) {
                      //                   AddProduct(
                      //                     allProductsCodeList: allProductsCodeList,
                      //                     warehouseBasedProductModel: [],
                      //                     sideBarNumber: 3,
                      //                   ).launch(context);
                      //                 } else {
                      //                   EasyLoading.showError(lang.S.of(context).updateYourPlanFirst);
                      //                 }
                      //               }),
                      //             ),
                      //           ),
                      //           //-----------------------barcode generate------------------
                      //           ResponsiveGridCol(
                      //             lg: 31,
                      //             md: 31,
                      //             xs: 40,
                      //             child: Padding(
                      //               padding: const EdgeInsets.all(10.0),
                      //               child: InkWell(
                      //                 onTap: () => Navigator.pushNamed(context, BarcodeGenerate.route),
                      //                 child: Container(
                      //                   padding: const EdgeInsets.all(10.0),
                      //                   decoration: BoxDecoration(
                      //                     borderRadius: BorderRadius.circular(5.0),
                      //                     color: kWhite,
                      //                     border: Border.all(color: kBorderColorTextField),
                      //                   ),
                      //                   child: Row(
                      //                     children: [
                      //                       const Icon(Icons.qr_code, color: kTitleColor, size: 18.0),
                      //                       const SizedBox(width: 5.0),
                      //                       Flexible(
                      //                         child: Text(
                      //                           'Barcode Generate',
                      //                           style: kTextStyle.copyWith(color: kTitleColor),
                      //                         ),
                      //                       ),
                      //                     ],
                      //                   ),
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      ///
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 10),
                      //   child: Row(
                      //     children: [
                      //       // Text(
                      //       //   lang.S.of(context).productList,
                      //       //   style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                      //       // ),
                      //       // const SizedBox(width: 10.0),
                      //       Container(
                      //         padding: const EdgeInsets.all(10),
                      //         decoration: BoxDecoration(
                      //           borderRadius: BorderRadius.circular(8.0),
                      //           border: Border.all(color: kNeutral300),
                      //         ),
                      //         child: Row(
                      //           mainAxisSize: MainAxisSize.min,
                      //           children: [
                      //             const Text('Result-'),
                      //             DropdownButton<int>(
                      //               isDense: true,
                      //               padding: EdgeInsets.zero,
                      //               underline: const SizedBox(),
                      //               value: _productsPerPage,
                      //               icon: const Icon(
                      //                 Icons.keyboard_arrow_down,
                      //                 color: Colors.black,
                      //               ),
                      //               items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                      //                 return DropdownMenuItem<int>(
                      //                   value: value,
                      //                   child: Text(
                      //                     value == -1 ? "All" : value.toString(),
                      //                     style: const TextStyle(color: Colors.black),
                      //                   ),
                      //                 );
                      //               }).toList(),
                      //               onChanged: (int? newValue) {
                      //                 setState(() {
                      //                   if (newValue == -1) {
                      //                     _productsPerPage = -1; // Set to -1 for "All"
                      //                   } else {
                      //                     _productsPerPage = newValue ?? 10;
                      //                   }
                      //                   _currentPage = 1;
                      //                 });
                      //               },
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //       const SizedBox(width: 20),
                      //
                      //       ///___________search________________________________________________-
                      //       TextFormField(
                      //         showCursor: true,
                      //         cursorColor: kTitleColor,
                      //         onChanged: (value) {
                      //           setState(() {
                      //             searchItem = value;
                      //           });
                      //         },
                      //         keyboardType: TextInputType.name,
                      //         decoration: const InputDecoration(
                      //           suffixIcon: Padding(
                      //             padding: EdgeInsets.all(4.0),
                      //             child: Icon(
                      //               FeatherIcons.search,
                      //               color: kTitleColor,
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //       const Spacer(),
                      //       SizedBox(
                      //         height: 42,
                      //         child: ListView.builder(
                      //             itemCount: 2,
                      //             shrinkWrap: true,
                      //             padding: EdgeInsets.zero,
                      //             scrollDirection: Axis.horizontal,
                      //             itemBuilder: (_, index) {
                      //               return InkWell(
                      //                 onTap: () {
                      //                   setState(() {
                      //                     // isRegularSelected = index == 0;
                      //                     _currentPage = 1;
                      //                     isSelected = title[index];
                      //                     isRegularSelected = index == 0;
                      //                   });
                      //                 },
                      //                 child: Padding(
                      //                   padding: const EdgeInsets.only(left: 10.0),
                      //                   child: Container(
                      //                     padding: const EdgeInsets.all(10.0),
                      //                     decoration: BoxDecoration(
                      //                         borderRadius: BorderRadius.circular(5.0),
                      //                         color: isSelected == title[index] ? kBlueTextColor : white,
                      //                         border: Border.all(
                      //                           color: isSelected == title[index] ? kBlueTextColor : kBorderColorTextField,
                      //                         )),
                      //                     child: Text(
                      //                       title[index],
                      //                       style: kTextStyle.copyWith(
                      //                         color: isSelected == title[index] ? kWhite : kTitleColor,
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 ),
                      //               );
                      //             }),
                      //       ),
                      //
                      //       // SizedBox(
                      //       //   height: 42,
                      //       //   child: ToggleButtons(
                      //       //     isSelected: [isRegularSelected, !isRegularSelected],
                      //       //     onPressed: (index) {
                      //       //       setState(() {
                      //       //         isRegularSelected = index == 0;
                      //       //       });
                      //       //     },
                      //       //     color: Colors.black,
                      //       //     selectedColor: Colors.white,
                      //       //     fillColor: kBlueTextColor,
                      //       //     borderRadius: BorderRadius.circular(5),
                      //       //     children: [
                      //       //       Container(
                      //       //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      //       //         child: Text(lang.S.of(context).productList),
                      //       //       ),
                      //       //
                      //       //       Container(
                      //       //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      //       //         child: const Text('Expired List'),
                      //       //       ),
                      //       //     ],
                      //       //   ),
                      //       // ),
                      //       const SizedBox(width: 10),
                      //
                      //       Container(
                      //         padding: const EdgeInsets.all(10.0),
                      //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kWhite, border: Border.all(color: kBorderColorTextField)),
                      //         child: Text(
                      //           "Bulk Upload",
                      //           style: kTextStyle.copyWith(color: kTitleColor),
                      //         ),
                      //       ).onTap(() async {
                      //         await showDialog(
                      //           context: context,
                      //           builder: (context) => BulkProductUploadPopup(allProductsCodeList: allProductsCodeList, allProductsNameList: allProductsNameList),
                      //         );
                      //         setState(() {});
                      //       }),
                      //       const SizedBox(width: 10),
                      //
                      //       ///________________add_productS________________________________________________
                      //       Container(
                      //         padding: const EdgeInsets.all(10.0),
                      //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kWhite, border: Border.all(color: kBorderColorTextField)),
                      //         child: Row(
                      //           children: [
                      //             const Icon(FeatherIcons.plus, color: kTitleColor, size: 18.0),
                      //             const SizedBox(width: 5.0),
                      //             Text(
                      //               lang.S.of(context).addProduct,
                      //               style: kTextStyle.copyWith(color: kTitleColor),
                      //             ),
                      //           ],
                      //         ),
                      //       ).onTap(() async {
                      //         if (await Subscription.subscriptionChecker(item: 'Products')) {
                      //           AddProduct(
                      //             allProductsCodeList: allProductsCodeList,
                      //             warehouseBasedProductModel: [],
                      //             sideBarNumber: 3,
                      //           ).launch(context);
                      //         } else {
                      //           EasyLoading.showError(lang.S.of(context).updateYourPlanFirst);
                      //         }
                      //       }),
                      //       const SizedBox(width: 10),
                      //
                      //       ///________________add_productS________________________________________________
                      //       InkWell(
                      //         onTap: () => Navigator.pushNamed(context, BarcodeGenerate.route),
                      //         child: Container(
                      //           padding: const EdgeInsets.all(10.0),
                      //           decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kWhite, border: Border.all(color: kBorderColorTextField)),
                      //           child: Row(
                      //             children: [
                      //               const Icon(Icons.qr_code, color: kTitleColor, size: 18.0),
                      //               const SizedBox(width: 5.0),
                      //               Text(
                      //                 'Barcode Generate',
                      //                 style: kTextStyle.copyWith(color: kTitleColor),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       )
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 5.0),
                      // Divider(
                      //   thickness: 1.0,
                      //   color: kGreyTextColor.withOpacity(0.2),
                      // ),

                      ///_______product_list______________________________________________________
                      const SizedBox(height: 20.0),

                      showAbleProducts.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Scrollbar(
                                  thickness: 8.0,
                                  thumbVisibility: true,
                                  controller: _horizontalController,
                                  radius: const Radius.circular(5),
                                  child: LayoutBuilder(
                                    builder: (BuildContext context,
                                        BoxConstraints constraints) {
                                      final kWidth = constraints.maxWidth;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        controller: _horizontalController,
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
                                                      const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle:
                                                  theme.textTheme.titleMedium,
                                              dataTextStyle:
                                                  theme.textTheme.bodyLarge,
                                              columns: const [
                                                DataColumn(label: Text('S.L')),
                                                DataColumn(
                                                    label: Text('Image')),
                                                DataColumn(
                                                    label:
                                                        Text('Product Name')),
                                                DataColumn(
                                                    label: Text('Category')),
                                                DataColumn(
                                                    label: Text('Retailer')),
                                                DataColumn(
                                                    label: Text('Dealer')),
                                                DataColumn(
                                                    label: Text('Wholesale')),
                                                DataColumn(
                                                    label: Text('Warehouse')),
                                                DataColumn(
                                                    label: Text('Stock')),
                                                DataColumn(
                                                    label:
                                                        Icon(Icons.settings)),
                                              ],
                                              rows: List.generate(
                                                _productsPerPage == -1
                                                    ? showAbleProducts.length
                                                    : (_currentPage - 1) *
                                                                    _productsPerPage +
                                                                _productsPerPage <=
                                                            showAbleProducts
                                                                .length
                                                        ? _productsPerPage
                                                        : showAbleProducts
                                                                .length -
                                                            (_currentPage - 1) *
                                                                _productsPerPage,
                                                (index) {
                                                  final dataIndex =
                                                      (_currentPage - 1) *
                                                              _productsPerPage +
                                                          index;
                                                  final product =
                                                      showAbleProducts[
                                                          dataIndex];
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(
                                                        Text(
                                                            '${(_currentPage - 1) * _productsPerPage + index + 1}'),
                                                      ),
                                                      DataCell(
                                                        Container(
                                                          height: 40,
                                                          width: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color:
                                                                    kBorderColorTextField),
                                                            image:
                                                                DecorationImage(
                                                                    image:
                                                                        NetworkImage(
                                                                      product
                                                                          .productPicture,
                                                                    ),
                                                                    fit: BoxFit
                                                                        .cover),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          product.productName,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          (!isRegularSelected &&
                                                                  product.expiringDate !=
                                                                      null)
                                                              ? ((DateTime.tryParse(product.expiringDate ?? '') ?? DateTime.now()).isBefore(DateTime(
                                                                      DateTime.now()
                                                                          .year,
                                                                      DateTime.now()
                                                                          .month,
                                                                      DateTime.now()
                                                                          .day))
                                                                  ? 'Expired'
                                                                  : "Will Expire at\n${DateFormat.yMMMd().format(DateTime.tryParse(product.expiringDate ?? '') ?? DateTime.now())}")
                                                              : product
                                                                  .productCategory,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          "$globalCurrency ${myFormat.format(double.tryParse(product.productSalePrice) ?? 0)}",
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          "$globalCurrency ${myFormat.format(double.tryParse(product.productDealerPrice) ?? 0)}",
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          "$globalCurrency ${myFormat.format(double.tryParse(product.productWholeSalePrice) ?? 0)}",
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          product.warehouseName,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          myFormat.format(double
                                                                  .tryParse(product
                                                                      .productStock) ??
                                                              0),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        SizedBox(
                                                          width: 30,
                                                          child:
                                                              StatefulBuilder(
                                                            builder: (BuildContext
                                                                    context,
                                                                void Function(
                                                                        void
                                                                            Function())
                                                                    setState) {
                                                              return Theme(
                                                                data: ThemeData(
                                                                    highlightColor:
                                                                        dropdownItemColor,
                                                                    focusColor:
                                                                        dropdownItemColor,
                                                                    hoverColor:
                                                                        dropdownItemColor),
                                                                child:
                                                                    PopupMenuButton(
                                                                  surfaceTintColor:
                                                                      Colors
                                                                          .white,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                              bc) =>
                                                                          [
                                                                    PopupMenuItem(
                                                                        onTap: () =>
                                                                            context
                                                                                .push(
                                                                              '/product/edit-product',
                                                                              extra: {
                                                                                'productModel': product,
                                                                                'allProductsNameList': allProductsNameList,
                                                                                'groupTaxModel': groupTax.value ?? [],
                                                                              },
                                                                            ),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(IconlyLight.edit,
                                                                                size: 22.0,
                                                                                color: kGreyTextColor),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).edit,
                                                                              style: theme.textTheme.bodyLarge,
                                                                            ),
                                                                          ],
                                                                        )),
                                                                    PopupMenuItem(
                                                                        onTap:
                                                                            () async {
                                                                          await productStockEditPopUp(
                                                                              product: product,
                                                                              popUp: context,
                                                                              pref: ref);
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            const Icon(Icons.add,
                                                                                size: 22.0,
                                                                                color: kTitleColor),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).increaseStock,
                                                                              style: theme.textTheme.bodyLarge,
                                                                            ),
                                                                          ],
                                                                        )),
                                                                    PopupMenuItem(
                                                                      onTap:
                                                                          () {
                                                                        showDialog(
                                                                            barrierDismissible:
                                                                                false,
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContext dialogContext) {
                                                                              return Padding(
                                                                                padding: const EdgeInsets.all(10.0),
                                                                                child: Center(
                                                                                  child: Container(
                                                                                    width: 450,
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
                                                                                            lang.S.of(context).areYouWantToDeleteThisProduct,
                                                                                            style: theme.textTheme.headlineSmall?.copyWith(
                                                                                              fontWeight: FontWeight.w600,
                                                                                            ),
                                                                                            textAlign: TextAlign.center,
                                                                                          ),
                                                                                          const SizedBox(height: 30),
                                                                                          ResponsiveGridRow(children: [
                                                                                            ResponsiveGridCol(
                                                                                              md: 6,
                                                                                              lg: 6,
                                                                                              xs: 6,
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
                                                                                              ),
                                                                                            ),
                                                                                            ResponsiveGridCol(
                                                                                              md: 6,
                                                                                              lg: 6,
                                                                                              xs: 6,
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.all(10.0),
                                                                                                child: ElevatedButton(
                                                                                                  child: Text(
                                                                                                    lang.S.of(context).delete,
                                                                                                  ),
                                                                                                  onPressed: () {
                                                                                                    if (!isDemo) {
                                                                                                      deleteProduct(
                                                                                                        productCode: product.productCode,
                                                                                                        updateProduct: ref,
                                                                                                        context: bc,
                                                                                                      );
                                                                                                      Navigator.pop(dialogContext);
                                                                                                    } else {
                                                                                                      EasyLoading.showInfo(demoText);
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
                                                                      },
                                                                      child:
                                                                          GestureDetector(
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            HugeIcon(
                                                                              icon: HugeIcons.strokeRoundedDelete02,
                                                                              color: kGreyTextColor,
                                                                              size: 22,
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 5,
                                                                            ),
                                                                            Text(
                                                                              lang.S.of(context).delete,
                                                                              style: theme.textTheme.bodyLarge,
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                  onSelected:
                                                                      (value) {
                                                                    Navigator.pushNamed(
                                                                        context,
                                                                        '$value');
                                                                  },
                                                                  child: Center(
                                                                    child: Container(
                                                                        height: 18,
                                                                        width: 18,
                                                                        alignment: Alignment.centerRight,
                                                                        child: const Icon(
                                                                          Icons
                                                                              .more_vert_sharp,
                                                                          size:
                                                                              18,
                                                                        )),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'showing ${((_currentPage - 1) * _productsPerPage + 1).toString()} to ${((_currentPage - 1) * _productsPerPage + _productsPerPage).clamp(0, showAbleProducts.length)} of ${showAbleProducts.length} entries',
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          InkWell(
                                            overlayColor: MaterialStateProperty
                                                .all<Color>(Colors.grey),
                                            hoverColor: Colors.grey,
                                            onTap: _currentPage > 1
                                                ? () => setState(
                                                    () => _currentPage--)
                                                : null,
                                            child: Container(
                                              height: 32,
                                              width: 90,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(4.0),
                                                  topLeft: Radius.circular(4.0),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Text('Previous'),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 32,
                                            width: 32,
                                            decoration: BoxDecoration(
                                              border:
                                                  Border.all(color: kMainColor),
                                              color: kMainColor,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_currentPage',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            hoverColor:
                                                Colors.blue.withOpacity(0.1),
                                            overlayColor: MaterialStateProperty
                                                .all<Color>(Colors.blue),
                                            onTap: _currentPage *
                                                        _productsPerPage <
                                                    showAbleProducts.length
                                                ? () => setState(
                                                    () => _currentPage++)
                                                : null,
                                            child: Container(
                                              height: 32,
                                              width: 90,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(4.0),
                                                  topRight:
                                                      Radius.circular(4.0),
                                                ),
                                              ),
                                              child: const Center(
                                                  child: Text('Next')),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : EmptyWidget(
                              title: lang.S.of(context).noProductFound),
                    ],
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
          });
        },
      ),
    );
  }
}
