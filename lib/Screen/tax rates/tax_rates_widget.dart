import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/tax%20rates/tax_model.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';
import 'create_single_tax.dart';
import 'edit_group_tax_popUp.dart';
import 'new_tax_group_popup.dart';

class TaxRatesWidget extends StatefulWidget {
  const TaxRatesWidget({super.key});

  @override
  State<TaxRatesWidget> createState() => _TaxRatesWidgetState();
}

class _TaxRatesWidgetState extends State<TaxRatesWidget> {
  Future<void> deleteTax({required String name, required WidgetRef updateRef, required BuildContext context}) async {
    EasyLoading.show(status: '${lang.S.of(context).deleting}..');
    String expenseKey = '';
    final userId = await getUserID();
    await FirebaseDatabase.instance.ref(userId).child('Tax List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['name'].toString() == name) {
          expenseKey = element.key.toString();
        }
      }
    });
    DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Tax List/$expenseKey");
    if (expenseKey != '') {
      await ref.remove();
      updateRef.refresh(taxProvider);
      EasyLoading.showSuccess(lang.S.of(context).done);
      // Navigator.pop(context),
    }
  }

  Future<void> deleteTaxReport({required String name, required WidgetRef updateRef, required BuildContext context}) async {
    EasyLoading.show(status: '${lang.S.of(context).deleting}..');
    String expenseKey = '';
    final userId = await getUserID();
    await FirebaseDatabase.instance.ref(userId).child('Group Tax List').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['name'].toString() == name) {
          expenseKey = element.key.toString();
        }
      }
    });
    DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Group Tax List/$expenseKey");
    if (expenseKey != '') {
      await ref.remove();
      updateRef.refresh(groupTaxProvider);
      EasyLoading.showSuccess(lang.S.of(context).done);
    }
  }

  final _horizontalScroll = ScrollController();
  final _groupScrollData = ScrollController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Consumer(
      builder: (_, ref, watch) {
        final tax = ref.watch(taxProvider);
        final groupTax = ref.watch(groupTaxProvider);
        return tax.when(data: (taxData) {
          return groupTax.when(data: (groupTaxSnap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      //___________________________________Tax Rates______________________________
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                lang.S.of(context).taxRatesManageYourTaxRates,
                                //'Tax rates- Manage your Tax rates',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.all(20.0),
                                    child: Container(
                                      width: 450,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                      child: CreateSingleTaxPopUp(
                                        listOfTax: taxData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              child: Row(
                                spacing: 4,
                                children: [
                                  const Icon(
                                    FeatherIcons.plus,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    lang.S.of(context).add,
                                    // 'Add',
                                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Scrollbar(
                            controller: _horizontalScroll,
                            thumbVisibility: true,
                            radius: const Radius.circular(8),
                            thickness: 8,
                            child: SingleChildScrollView(
                              controller: _horizontalScroll,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: Theme(
                                  data: theme.copyWith(dividerTheme: const DividerThemeData(color: Colors.transparent)),
                                  child: DataTable(
                                    border: const TableBorder(
                                      horizontalInside: BorderSide(
                                        width: 1,
                                        color: kNeutral300,
                                      ),
                                    ),
                                    dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                    showBottomBorder: false,
                                    dividerThickness: 0.0,
                                    headingTextStyle: theme.textTheme.titleMedium,
                                    columns: <DataColumn>[
                                      DataColumn(
                                        label: Text(
                                          lang.S.of(context).name,
                                          // 'Name',
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          lang.S.of(context).taxRate,
                                          // 'Tax rate',
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          lang.S.of(context).action,

                                          ///'Acton',
                                        ),
                                      ),
                                    ],
                                    rows: List.generate(
                                      taxData.length,
                                      (index) => DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              taxData[index].name,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              taxData[index].taxRate.toString(),
                                            ),
                                          ),
                                          DataCell(PopupMenuButton(
                                              iconColor: kGreyTextColor,
                                              iconSize: 22,
                                              offset: const Offset(0, 40),
                                              itemBuilder: (bc) {
                                                return [
                                                  PopupMenuItem(
                                                      onTap: () => showDialog(
                                                          barrierDismissible: false,
                                                          context: context,
                                                          builder: (BuildContext dialogContext) {
                                                            return Dialog(
                                                              insetPadding: const EdgeInsets.all(20.0),
                                                              child: Container(
                                                                width: 450,
                                                                decoration: const BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.all(
                                                                    Radius.circular(15),
                                                                  ),
                                                                ),
                                                                child: EditSingleTaxPopUp(
                                                                  taxList: taxData,
                                                                  taxModel: taxData[index],
                                                                  groupTaxList: groupTaxSnap,
                                                                ),
                                                              ),
                                                            );
                                                          }),
                                                      child: Row(
                                                        spacing: 4,
                                                        children: [
                                                          const Icon(
                                                            IconlyBold.edit,
                                                            color: Colors.green,
                                                            size: 22,
                                                          ),
                                                          Text(
                                                            lang.S.of(context).edit,
                                                            style: theme.textTheme.bodyLarge?.copyWith(
                                                              color: kNeutral500,
                                                            ),
                                                          )
                                                        ],
                                                      )),
                                                  PopupMenuItem(
                                                      onTap: () {
                                                        showDialog(
                                                            barrierDismissible: false,
                                                            context: context,
                                                            builder: (BuildContext dialogContext) {
                                                              return Padding(
                                                                padding: const EdgeInsets.all(20.0),
                                                                child: Center(
                                                                  child: Container(
                                                                    width: 450,
                                                                    decoration: const BoxDecoration(
                                                                      color: Colors.white,
                                                                      borderRadius: BorderRadius.all(
                                                                        Radius.circular(15),
                                                                      ),
                                                                    ),
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        Padding(
                                                                          padding: const EdgeInsets.all(16.0),
                                                                          child: Text(
                                                                            '${lang.S.of(context).areYouSureWantToDeleteThisTax} ?',
                                                                            textAlign: TextAlign.center,
                                                                            style: theme.textTheme.titleLarge?.copyWith(
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        ResponsiveGridRow(children: [
                                                                          ResponsiveGridCol(
                                                                            lg: 6,
                                                                            md: 6,
                                                                            xs: 6,
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.all(12.0),
                                                                              child: OutlinedButton(
                                                                                style: OutlinedButton.styleFrom(
                                                                                  minimumSize: Size(screenWidth, 48),
                                                                                  side: const BorderSide(color: kMainColor),
                                                                                  foregroundColor: kMainColor,
                                                                                ),
                                                                                onPressed: () {
                                                                                  Navigator.pop(dialogContext);
                                                                                },
                                                                                child: Text(
                                                                                  lang.S.of(context).cancel,
                                                                                  //'Cancel',
                                                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                                                    color: kMainColor,
                                                                                    fontWeight: FontWeight.w600,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          ResponsiveGridCol(
                                                                            lg: 6,
                                                                            md: 6,
                                                                            xs: 6,
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.all(12.0),
                                                                              child: ElevatedButton(
                                                                                onPressed: () async {
                                                                                  await deleteTax(
                                                                                    name: taxData[index].name,
                                                                                    updateRef: ref,
                                                                                    context: dialogContext,
                                                                                  );
                                                                                  Navigator.pop(dialogContext);
                                                                                },
                                                                                child: Text(
                                                                                  lang.S.of(context).delete,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ]),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            });
                                                      },
                                                      child: Row(
                                                        spacing: 4,
                                                        children: [
                                                           HugeIcon(
                                                            icon: HugeIcons.strokeRoundedDelete02,
                                                            color: Colors.red,
                                                            size: 22,
                                                          ),
                                                          Text(
                                                            lang.S.of(context).delete,
                                                            style: theme.textTheme.bodyLarge?.copyWith(
                                                              color: kNeutral500,
                                                            ),
                                                          )
                                                        ],
                                                      )),
                                                ];
                                              })),
                                          // DataCell(
                                          //   Row(
                                          //     children: [
                                          //       SizedBox(
                                          //         height: 25.0,
                                          //         child: ElevatedButton(
                                          //           style: ElevatedButton.styleFrom(
                                          //             padding: const EdgeInsets.only(left: 2, right: 2),
                                          //             shape: RoundedRectangleBorder(
                                          //               borderRadius: BorderRadius.circular(4.0),
                                          //             ),
                                          //             backgroundColor: kMainColor,
                                          //             elevation: 1.0,
                                          //             foregroundColor: kGreyTextColor.withOpacity(0.1),
                                          //             shadowColor: kMainColor,
                                          //             animationDuration: const Duration(milliseconds: 300),
                                          //             textStyle: const TextStyle(color: Colors.white, fontFamily: 'Display', fontSize: 16, fontWeight: FontWeight.bold),
                                          //           ),
                                          //           onPressed: () => showDialog(
                                          //               barrierDismissible: false,
                                          //               context: context,
                                          //               builder: (BuildContext dialogContext) {
                                          //                 return Dialog(
                                          //                   insetPadding: EdgeInsets.all(20.0),
                                          //                   child: Container(
                                          //                     width: 400,
                                          //                     padding: const EdgeInsets.all(20.0),
                                          //                     decoration: const BoxDecoration(
                                          //                       color: Colors.white,
                                          //                       borderRadius: BorderRadius.all(
                                          //                         Radius.circular(15),
                                          //                       ),
                                          //                     ),
                                          //                     child: EditSingleTaxPopUp(
                                          //                       taxList: taxData,
                                          //                       taxModel: taxData[index],
                                          //                       groupTaxList: groupTaxSnap,
                                          //                     ),
                                          //                   ),
                                          //                 );
                                          //               }),
                                          //           child: Row(
                                          //             children: [
                                          //               const Icon(
                                          //                 FeatherIcons.edit,
                                          //                 size: 15,
                                          //                 color: kWhite,
                                          //               ),
                                          //               const SizedBox(width: 4),
                                          //               Text(
                                          //                 lang.S.of(context).edit,
                                          //                 //'Edit',
                                          //                 style: kTextStyle.copyWith(color: kWhite, fontSize: 12, fontWeight: FontWeight.bold),
                                          //               ),
                                          //             ],
                                          //           ),
                                          //         ),
                                          //       ),
                                          //       const SizedBox(width: 5.0),
                                          //       SizedBox(
                                          //         height: 25.0,
                                          //         child: ElevatedButton(
                                          //           style: ElevatedButton.styleFrom(
                                          //             padding: const EdgeInsets.only(left: 2, right: 2),
                                          //             shape: RoundedRectangleBorder(
                                          //               borderRadius: BorderRadius.circular(4.0),
                                          //             ),
                                          //             backgroundColor: Colors.red,
                                          //             elevation: 1.0,
                                          //             foregroundColor: Colors.white.withOpacity(0.1),
                                          //             shadowColor: Colors.red,
                                          //             animationDuration: const Duration(milliseconds: 300),
                                          //             textStyle: kTextStyle.copyWith(color: kWhite),
                                          //           ),
                                          //           onPressed: () {
                                          //             showDialog(
                                          //                 barrierDismissible: false,
                                          //                 context: context,
                                          //                 builder: (BuildContext dialogContext) {
                                          //                   return Padding(
                                          //                     padding: const EdgeInsets.all(20.0),
                                          //                     child: Center(
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
                                          //                                 '${lang.S.of(context).areYouSureWantToDeleteThisTax} ?',
                                          //                                 style: kTextStyle.copyWith(color: kTitleColor, fontSize: 18.0, fontWeight: FontWeight.bold),
                                          //                                 textAlign: TextAlign.center,
                                          //                               ),
                                          //                               const SizedBox(height: 30),
                                          //                               Row(
                                          //                                 mainAxisAlignment: MainAxisAlignment.center,
                                          //                                 mainAxisSize: MainAxisSize.min,
                                          //                                 children: [
                                          //                                   SizedBox(
                                          //                                     width: 130,
                                          //                                     child: ElevatedButton(
                                          //                                       onPressed: () {
                                          //                                         Navigator.pop(dialogContext);
                                          //                                       },
                                          //                                       style: ButtonStyle(
                                          //                                         shape: MaterialStateProperty.all(
                                          //                                           RoundedRectangleBorder(
                                          //                                               borderRadius: BorderRadius.circular(8.0), side: const BorderSide(color: kMainColor)),
                                          //                                         ),
                                          //                                         overlayColor: MaterialStateProperty.all<Color>(
                                          //                                           kMainColor.withOpacity(0.1),
                                          //                                         ),
                                          //                                         shadowColor: MaterialStateProperty.all<Color>(kMainColor.withOpacity(0.1)),
                                          //                                         minimumSize: MaterialStateProperty.all<Size>(
                                          //                                           const Size(150, 50),
                                          //                                         ),
                                          //                                         backgroundColor: MaterialStateProperty.all<Color>(kWhite),
                                          //
                                          //                                         // Change background color
                                          //                                         textStyle: MaterialStateProperty.all<TextStyle>(
                                          //                                             const TextStyle(color: Colors.white)), // Change text color
                                          //                                         // Add more properties as needed
                                          //                                       ),
                                          //                                       child: Text(
                                          //                                         lang.S.of(context).cancel,
                                          //                                         //'Cancel',
                                          //                                         style: kTextStyle.copyWith(color: kMainColor, fontWeight: FontWeight.bold, fontSize: 16),
                                          //                                       ),
                                          //                                     ),
                                          //                                   ),
                                          //                                   const SizedBox(width: 30),
                                          //                                   SizedBox(
                                          //                                     width: 130,
                                          //                                     child: ElevatedButton(
                                          //                                       onPressed: () {
                                          //                                         deleteTax(
                                          //                                           name: taxData[index].name,
                                          //                                           updateRef: ref,
                                          //                                           context: dialogContext,
                                          //                                         );
                                          //                                         Navigator.pop(dialogContext);
                                          //                                       },
                                          //                                       style: ButtonStyle(
                                          //                                         shape: MaterialStateProperty.all(
                                          //                                           RoundedRectangleBorder(
                                          //                                             borderRadius: BorderRadius.circular(8.0),
                                          //                                           ),
                                          //                                         ),
                                          //                                         overlayColor: MaterialStateProperty.all<Color>(
                                          //                                           kWhite.withOpacity(0.1),
                                          //                                         ),
                                          //                                         shadowColor: MaterialStateProperty.all<Color>(kMainColor.withOpacity(0.1)),
                                          //                                         minimumSize: MaterialStateProperty.all<Size>(Size(150, 50)),
                                          //                                         backgroundColor: MaterialStateProperty.all<Color>(kMainColor),
                                          //                                         // Change background color
                                          //                                         textStyle:
                                          //                                             MaterialStateProperty.all<TextStyle>(TextStyle(color: Colors.white)), // Change text color
                                          //                                         // Add more properties as needed
                                          //                                       ),
                                          //                                       child: Text(
                                          //                                         lang.S.of(context).delete,
                                          //                                         //'Delete',
                                          //                                         style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold, fontSize: 16),
                                          //                                       ),
                                          //                                     ),
                                          //                                   ),
                                          //                                 ],
                                          //                               )
                                          //                             ],
                                          //                           ),
                                          //                         ),
                                          //                       ),
                                          //                     ),
                                          //                   );
                                          //                 });
                                          //           },
                                          //           child: Row(
                                          //             children: [
                                          //               const Icon(
                                          //                 Icons.delete_outline,
                                          //                 size: 17,
                                          //                 color: kWhite,
                                          //               ),
                                          //               SizedBox(width: 4),
                                          //               Text(
                                          //                 lang.S.of(context).delete,
                                          //                 // 'Delete',
                                          //                 style: kTextStyle.copyWith(color: kWhite, fontSize: 12, fontWeight: FontWeight.bold),
                                          //               ),
                                          //             ],
                                          //           ),
                                          //         ),
                                          //       ),
                                          //     ],
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                //___________________________________Tax Group______________________________
                const SizedBox(height: 20.0),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.S.of(context).taxGroup,
                                    // 'Tax Group',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '(${lang.S.of(context).combinationOfMultipleTaxes})',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.all(20.0),
                                    child: Container(
                                      width: 600,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                      child: AddTaxGroupPopUP(
                                        listOfGroupTax: groupTaxSnap,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              child: Row(
                                spacing: 4,
                                children: [
                                  const Icon(
                                    FeatherIcons.plus,
                                    size: 22,
                                    color: kWhite,
                                  ),
                                  Text(lang.S.of(context).add,
                                      //'Add',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: Colors.white,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      groupTaxSnap.isNotEmpty
                          ? LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                return Scrollbar(
                                  controller: _groupScrollData,
                                  thumbVisibility: true,
                                  radius: const Radius.circular(8),
                                  thickness: 8,
                                  child: SingleChildScrollView(
                                    controller: _groupScrollData,
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: Theme(
                                        data: theme.copyWith(dividerTheme: const DividerThemeData(color: Colors.transparent)),
                                        child: DataTable(
                                          border: const TableBorder(
                                            horizontalInside: BorderSide(
                                              width: 1,
                                              color: kNeutral300,
                                            ),
                                          ),
                                          dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                          showBottomBorder: false,
                                          dividerThickness: 0.0,
                                          headingTextStyle: theme.textTheme.titleMedium,
                                          columns: <DataColumn>[
                                            DataColumn(
                                              label: Text(
                                                lang.S.of(context).name,
                                                //'Name',
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                '${lang.S.of(context).taxRate} %',
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                lang.S.of(context).subTaxes,
                                                //'Sub Taxes',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                lang.S.of(context).action,
                                                //'Acton',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                          rows: List.generate(
                                            groupTaxSnap.length,
                                            (index) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    groupTaxSnap[index].name,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    groupTaxSnap[index].taxRate.toString(),
                                                  ),
                                                ),
                                                DataCell(
                                                  Wrap(
                                                    children: List.generate(
                                                      groupTaxSnap[index].subTaxes?.length ?? 0,
                                                      (i) {
                                                        return Text(
                                                          (i > 0 ? ', ' : '') + (groupTaxSnap[index].subTaxes?[i].name.toString() ?? ''), // Join with comma if not the first item
                                                          maxLines: 1,
                                                          textAlign: TextAlign.start,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: kTextStyle.copyWith(color: kGreyTextColor),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                DataCell(PopupMenuButton(
                                                    iconColor: kGreyTextColor,
                                                    iconSize: 22,
                                                    itemBuilder: (bc) {
                                                      return [
                                                        PopupMenuItem(
                                                            onTap: () => showDialog(
                                                                  barrierDismissible: false,
                                                                  context: context,
                                                                  builder: (BuildContext dialogContext) {
                                                                    return Dialog(
                                                                      insetPadding: const EdgeInsets.all(20.0),
                                                                      child: Container(
                                                                        width: 600,
                                                                        decoration: const BoxDecoration(
                                                                          color: Colors.white,
                                                                          borderRadius: BorderRadius.all(
                                                                            Radius.circular(15),
                                                                          ),
                                                                        ),
                                                                        child: EditGroupTaxPopUP(
                                                                          listOfGroupTax: groupTaxSnap,
                                                                          groupTaxModel: groupTaxSnap[index],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                            child: Row(
                                                              spacing: 4,
                                                              children: [
                                                                const Icon(
                                                                  IconlyBold.edit,
                                                                  color: Colors.green,
                                                                  size: 22,
                                                                ),
                                                                Text(
                                                                  lang.S.of(context).edit,
                                                                  style: theme.textTheme.bodyLarge?.copyWith(
                                                                    color: kNeutral500,
                                                                  ),
                                                                )
                                                              ],
                                                            )),
                                                        PopupMenuItem(
                                                            onTap: () {
                                                              showDialog(
                                                                  barrierDismissible: false,
                                                                  context: context,
                                                                  builder: (BuildContext dialogContext) {
                                                                    return Padding(
                                                                      padding: const EdgeInsets.all(20.0),
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
                                                                                  // 'Are you sure want to delete this Tax Group?',
                                                                                  '${lang.S.of(context).areYouSureWantToDeleteThisTaxGroup}?',
                                                                                  style: theme.textTheme.titleLarge?.copyWith(
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
                                                                                        padding: const EdgeInsetsDirectional.only(end: 20),
                                                                                        child: OutlinedButton(
                                                                                          style: OutlinedButton.styleFrom(foregroundColor: kMainColor, side: const BorderSide(color: kMainColor), minimumSize: Size(screenWidth, 48)),
                                                                                          onPressed: () {
                                                                                            GoRouter.of(context).pop();
                                                                                          },
                                                                                          child: Text(
                                                                                            lang.S.of(context).cancel,
                                                                                            // 'Cancel',
                                                                                            style: theme.textTheme.titleMedium?.copyWith(
                                                                                              fontWeight: FontWeight.w600,
                                                                                              color: kMainColor,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      )),
                                                                                  ResponsiveGridCol(
                                                                                      md: 6,
                                                                                      lg: 6,
                                                                                      xs: 6,
                                                                                      child: ElevatedButton(
                                                                                        onPressed: () async {
                                                                                          await deleteTaxReport(
                                                                                            name: groupTaxSnap[index].name,
                                                                                            updateRef: ref,
                                                                                            context: dialogContext,
                                                                                          );
                                                                                          Navigator.pop(dialogContext);
                                                                                        },
                                                                                        child: Text(
                                                                                          lang.S.of(context).delete,
                                                                                          //'Delete',
                                                                                        ),
                                                                                      ))
                                                                                ]),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  });
                                                            },
                                                            child: Row(
                                                              spacing: 4,
                                                              children: [
                                                                 HugeIcon(
                                                                  icon: HugeIcons.strokeRoundedDelete02,
                                                                  color: Colors.red,
                                                                  size: 22,
                                                                ),
                                                                Text(
                                                                  lang.S.of(context).delete,
                                                                  style: theme.textTheme.bodyLarge?.copyWith(
                                                                    color: kNeutral500,
                                                                  ),
                                                                )
                                                              ],
                                                            )),
                                                      ];
                                                    })),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(lang.S.of(context).noGroupFound),
                            ),
                    ],
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
          });
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
    );
  }
}
