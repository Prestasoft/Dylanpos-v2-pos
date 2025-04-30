//
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:nb_utils/nb_utils.dart';
// import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
// import 'package:salespro_admin/commas.dart';
// import 'package:salespro_admin/generated/l10n.dart' as lang;
// import 'package:salespro_admin/model/add_to_cart_model.dart';
//
// class CartItemsTable extends StatefulWidget {
//   final List<AddToCartModel> cartList;
//   final List<FocusNode> productFocusNodes;
//   final Function(int, int) onQuantityChanged;
//   final Function(int, String) onPriceChanged;
//   final Function(int) onItemRemoved;
//   final String currency;
//
//   const CartItemsTable({
//     super.key,
//     required this.cartList,
//     required this.productFocusNodes,
//     required this.onQuantityChanged,
//     required this.onPriceChanged,
//     required this.onItemRemoved,
//     required this.currency,
//   });
//
//   @override
//   State<CartItemsTable> createState() => _CartItemsTableState();
// }
//
// class _CartItemsTableState extends State<CartItemsTable> {
//   final _horizontalScroll = ScrollController();
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints constraints) {
//         final kWidth = constraints.maxWidth;
//         return RawScrollbar(
//           thumbVisibility: true,
//           controller: _horizontalScroll,
//           thickness: 8.0,
//           radius: const Radius.circular(5),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             controller: _horizontalScroll,
//             child: ConstrainedBox(
//               constraints: BoxConstraints(minWidth: kWidth),
//               child: Theme(
//                 data: theme.copyWith(
//                     dividerColor: Colors.transparent,
//                     dividerTheme: const DividerThemeData(color: Colors.transparent)),
//                 child: DataTable(
//                   border: const TableBorder(
//                     horizontalInside: BorderSide(width: 1, color: kNeutral300),
//                   ),
//                   dividerThickness: 0.0,
//                   dataRowColor: const WidgetStatePropertyAll(whiteColor),
//                   headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
//                   showBottomBorder: false,
//                   headingTextStyle: theme.textTheme.titleMedium,
//                   dataTextStyle: theme.textTheme.bodyLarge,
//                   columns: [
//                     DataColumn(label: Text(lang.S.of(context).productNam)),
//                     DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).quantity)),
//                     DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).price)),
//                     DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).subTotal)),
//                     DataColumn(
//                         headingRowAlignment: MainAxisAlignment.center,
//                         label: Text(
//                           lang.S.of(context).action,
//                           textAlign: TextAlign.end,
//                         )),
//                   ],
//                   rows: List.generate(widget.cartList.length, (index) {
//                     TextEditingController quantityController =
//                     TextEditingController(text: widget.cartList[index].quantity.toString());
//                     return DataRow(cells: [
//                       DataCell(
//                         Text(
//                           widget.cartList[index].productName ?? '',
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       DataCell(Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(FontAwesomeIcons.solidSquareMinus, color: kBlueTextColor)
//                                 .onTap(() => widget.onQuantityChanged(index, -1)),
//                             const SizedBox(width: 4),
//                             SizedBox(
//                               width: 60,
//                               height: 32,
//                               child: TextFormField(
//                                 controller: quantityController,
//                                 textAlign: TextAlign.center,
//                                 focusNode: widget.productFocusNodes[index],
//                                 onChanged: (value) {
//                                   if (widget.cartList[index].stock! < num.parse(value)) {
//                                     EasyLoading.showError('Out of Stock');
//                                     quantityController.clear();
//                                   } else if (value == '') {
//                                     widget.onQuantityChanged(index, 1);
//                                   } else if (value == '0') {
//                                     widget.onQuantityChanged(index, 1);
//                                   } else {
//                                     widget.onQuantityChanged(index, num.parse(value));
//                                   }
//                                 },
//                                 onFieldSubmitted: (value) {
//                                   if (value == '') {
//                                     widget.onQuantityChanged(index, 1);
//                                   } else {
//                                     widget.onQuantityChanged(index, num.parse(value));
//                                   }
//                                 },
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             const Icon(FontAwesomeIcons.solidSquarePlus, color: kBlueTextColor)
//                                 .onTap(() => widget.onQuantityChanged(index, 1)),
//                           ],
//                         ),
//                       )),
//                       DataCell(
//                         Align(
//                           alignment: Alignment.center,
//                           child: SizedBox(
//                             height: 32,
//                             width: 60,
//                             child: TextFormField(
//                               initialValue: myFormat.format(double.tryParse(widget.cartList[index].subTotal) ?? 0),
//                               onChanged: (value) => widget.onPriceChanged(index, value),
//                               onFieldSubmitted: (value) => widget.onPriceChanged(index, value),
//                               textAlign: TextAlign.center,
//                               decoration: const InputDecoration(contentPadding: EdgeInsets.all(6)),
//                             ),
//                           ),
//                         ),
//                       ),
//                       DataCell(
//                         Center(
//                           child: Text(
//                             '${widget.currency}${myFormat.format(double.tryParse((double.parse(widget.cartList[index].subTotal) * widget.cartList[index].quantity).toStringAsFixed(2)) ?? 0)}',
//                             style: kTextStyle.copyWith(color: kTitleColor),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                       DataCell(
//                         Align(
//                           alignment: Alignment.center,
//                           child: const Icon(Icons.close_sharp, color: redColor)
//                               .onTap(() => widget.onItemRemoved(index)),
//                         ),
//                       ),
//                     ]);
//                   }),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }