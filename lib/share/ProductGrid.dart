// import 'package:flutter/cupertino.dart' show BuildContext;
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValueX, ConsumerWidget, WidgetRef;
// import 'package:go_router/go_router.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:salespro_admin/Provider/product_provider.dart';
// import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
// import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
// import 'package:salespro_admin/commas.dart';
// import 'package:salespro_admin/currency.dart';
// import 'package:salespro_admin/generated/l10n.dart' as lang;
// import 'package:salespro_admin/model/add_to_cart_model.dart';
// import 'package:salespro_admin/model/product_model.dart';
// import 'package:flutter/material.dart';
//
// class ProductGrid extends ConsumerWidget {
//   final String selectedCategory;
//   final String searchProductCode;
//   final String selectedCustomerType;
//   final WareHouseModel? selectedWareHouse;
//   final List<String> allProductsCodeList;
//   final List<AddToCartModel> cartList;
//   final Function(ProductModel) onProductSelected;
//   final Function(ProductModel) onProductWithSerialSelected;
//
//   const ProductGrid({
//     super.key,
//     required this.selectedCategory,
//     required this.searchProductCode,
//     required this.selectedCustomerType,
//     required this.selectedWareHouse,
//     required this.allProductsCodeList,
//     required this.cartList,
//     required this.onProductSelected,
//     required this.onProductWithSerialSelected,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final productList = ref.watch(productProvider);
//     final theme = Theme.of(context);
//
//     return productList.when(
//       data: (products) {
//         if (cartList.isNotEmpty) {
//           // Check stock for each product in cart
//           for (var element in cartList) {
//             ProductModel? stockCheck = products
//                 .where((element2) => element2.productCode == element.productId)
//                 .singleOrNull;
//             if (stockCheck != null &&
//                 int.parse(stockCheck.productStock) < element.stock!.toInt()) {
//               EasyLoading.showError(
//                   'Product ${element.productName} is out of stock');
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 ref.read(cartProvider.notifier).removeFromCart(element);
//               });
//             }
//           }
//         }
//
//         List<ProductModel> showProductVsCategory = [];
//         if (selectedCategory == 'Categories') {
//           for (var element in products) {
//             if (element.productCode.toLowerCase().contains(searchProductCode) ||
//                 element.productCategory.toLowerCase().contains(searchProductCode) ||
//                 element.productName.toLowerCase().contains(searchProductCode)) {
//               if (_isProductAvailable(element)) {
//                 showProductVsCategory.add(element);
//               }
//             }
//           }
//         } else {
//           for (var element in products) {
//             if (element.productCategory == selectedCategory &&
//                 _isProductAvailable(element)) {
//               showProductVsCategory.add(element);
//             }
//           }
//         }
//
//         return showProductVsCategory.isNotEmpty
//             ? SizedBox(
//           height: context.height() - 160,
//           child: Container(
//             decoration: const BoxDecoration(color: kDarkWhite),
//             child: GridView.builder(
//               gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                 maxCrossAxisExtent: 180,
//                 mainAxisExtent: 204,
//                 mainAxisSpacing: 10,
//                 crossAxisSpacing: 10,
//               ),
//               itemCount: showProductVsCategory.length,
//               itemBuilder: (_, i) {
//                 return _buildProductCard(showProductVsCategory[i], theme);
//               },
//             ),
//           ),
//         )
//             : _buildEmptyProductGrid(context);
//       },
//       error: (e, stack) => Center(child: Text(e.toString())),
//       loading: () => const Center(child: CircularProgressIndicator()),
//     );
//   }
//
//   bool _isProductAvailable(ProductModel product) {
//     final price = productPriceChecker(
//         product: product,
//         customerType: selectedCustomerType);
//     final warehouseMatch = (selectedWareHouse?.warehouseName == 'InHouse' &&
//         product.warehouseId == '') ||
//         selectedWareHouse?.id == product.warehouseId;
//     return price != '0' && warehouseMatch;
//   }
//
//   Widget _buildProductCard(ProductModel product, ThemeData theme) {
//     return Container(
//       width: 130.0,
//       height: 170.0,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10.0),
//         color: kWhite,
//         border: Border.all(color: kLitGreyColor),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ///_____image_and_stock_______________________________
//           Stack(
//             alignment: Alignment.topLeft,
//             children: [
//               ///_______image______________________________________
//               Container(
//                 height: 120,
//                 decoration: BoxDecoration(
//                   borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(10.0),
//                       topRight: Radius.circular(10.0)),
//                   image: DecorationImage(
//                       image: NetworkImage(product.productPicture),
//                       fit: BoxFit.cover),
//                 ),
//               ),
//
//               ///_______stock_________________________
//               Positioned(
//                 left: 5,
//                 top: 5,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: product.productStock == '0'
//                         ? kRedTextColor
//                         : kBlueTextColor.withValues(alpha: 0.8),
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                   child: Text(
//                     product.productStock != '0'
//                         ? '${myFormat.format(double.tryParse(product.productStock) ?? 0)} pc'
//                         : 'Out of stock',
//                     style: theme.textTheme.titleSmall?.copyWith(color: kWhite),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           Padding(
//             padding: const EdgeInsets.only(top: 10.0, left: 5, right: 3),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ///______name_______________________________________________
//                 Text(
//                   product.productName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: theme.textTheme.bodyLarge,
//                 ),
//                 const SizedBox(height: 4.0),
//
//                 ///________Purchase_price______________________________________________________
//                 Container(
//                   padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
//                   decoration: BoxDecoration(
//                     color: kGreenTextColor,
//                     borderRadius: BorderRadius.circular(3.0),
//                   ),
//                   child: Text(
//                     'Price: $currency ${myFormat.format(double.tryParse(
//                         productPriceChecker(
//                             product: product,
//                             customerType: selectedCustomerType)) ?? 0)}',
//                     style: theme.textTheme.titleSmall?.copyWith(color: kWhite),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ).onTap(() {
//       if (product.serialNumber.isNotEmpty) {
//         onProductWithSerialSelected(product);
//       } else {
//         onProductSelected(product);
//       }
//     });
//   }
//
//   Widget _buildEmptyProductGrid(BuildContext context) {
//     return Container(
//       height: context.height() < 720 ? 720 - 136 : context.height() - 136,
//       color: Colors.white,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 80),
//           const Image(image: AssetImage('images/empty_screen.png')),
//           const SizedBox(height: 20),
//           GestureDetector(
//             onTap: () => context.push(
//               '/product/add-product',
//               extra: {
//                 'allProductsCodeList': allProductsCodeList,
//                 'warehouseBasedProductModel': [],
//               },
//             ),
//             child: Container(
//               decoration: const BoxDecoration(
//                   color: kBlueTextColor,
//                   borderRadius: BorderRadius.all(Radius.circular(15))),
//               width: 200,
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Text(
//                     lang.S.of(context).addProduct,
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18.0),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String productPriceChecker(
//       {required ProductModel product, required String customerType}) {
//     if (customerType == "Retailer") {
//       return product.productSalePrice;
//     } else if (customerType == "Wholesaler") {
//       return product.productWholeSalePrice == '' ? '0' : product.productWholeSalePrice;
//     } else if (customerType == "Dealer") {
//       return product.productDealerPrice == '' ? '0' : product.productDealerPrice;
//     } else if (customerType == "Guest") {
//       return product.productSalePrice;
//     }
//     return '0';
//   }
// }