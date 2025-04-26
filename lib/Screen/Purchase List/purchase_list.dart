import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../delete_invoice_functions.dart';
import '../../model/purchase_transation_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class PurchaseList extends StatefulWidget {
  const PurchaseList({super.key});

  // static const String route = '/purchaseList';

  @override
  State<PurchaseList> createState() => _PurchaseListState();
}

class _PurchaseListState extends State<PurchaseList> {
  List<int> item = [
    10,
    20,
    30,
    50,
    80,
    100,
  ];
  int selectedItem = 10;
  int itemCount = 10;
  DropdownButton<int> selectItem() {
    List<DropdownMenuItem<int>> dropDownItems = [];
    for (int des in item) {
      var item = DropdownMenuItem(
        value: des,
        child: Text('${des.toString()} ${lang.S.of(context).items}'),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedItem,
      onChanged: (value) {
        setState(() {
          selectedItem = value!;
          itemCount = value;
        });
      },
    );
  }

  int currentPage = 1;
  late int itemsPerPage = 10;

  String searchItem = '';

  final _horizontalScroll = ScrollController();
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, consuearRef, watch) {
          final purchaseList = consuearRef.watch(purchaseTransitionProvider);
          final profile = consuearRef.watch(profileDetailsProvider);
          final settingProver = consuearRef.watch(generalSettingProvider);
          return purchaseList.when(data: (purchase) {
            final allTransaction = purchase.reversed.toList();

            List<PurchaseTransactionModel> showAblePurchaseTransactions = [];
            for (var element in allTransaction) {
              if (searchItem != '' && (element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()) || element.customerName.toLowerCase().contains(searchItem.toLowerCase()))) {
                showAblePurchaseTransactions.add(element);
              } else if (searchItem == '') {
                showAblePurchaseTransactions.add(element);
              }
            }
            final totalPages = (showAblePurchaseTransactions.length / itemsPerPage).ceil();
            final startIndex = (currentPage - 1) * itemsPerPage;
            final endIndex = itemsPerPage == -1 ? showAblePurchaseTransactions.length : startIndex + itemsPerPage;
            final paginatedTransactions = showAblePurchaseTransactions.sublist(
              startIndex,
              endIndex > showAblePurchaseTransactions.length ? showAblePurchaseTransactions.length : endIndex,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Text(
                        lang.S.of(context).purchaseList,
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
                                Flexible(child: Text('Show-', style: theme.textTheme.bodyLarge)),
                                DropdownButton<int>(
                                  isDense: true,
                                  padding: EdgeInsets.zero,
                                  underline: const SizedBox(),
                                  value: itemsPerPage,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.black,
                                  ),
                                  items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        value == -1 ? "All" : value.toString(),
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      if (newValue == -1) {
                                        itemsPerPage = -1; // Set to -1 for "All"
                                      } else {
                                        itemsPerPage = newValue ?? 10;
                                      }
                                      currentPage = 1;
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
                              hintText: lang.S.of(context).searchByInvoiceOrName,
                              suffixIcon: const Icon(
                                FeatherIcons.search,
                                color: kNeutral700,
                              ),
                            ),
                          ),
                        ),
                      )
                    ]),
                    //_______sale_List_____________________________________________________
                    const SizedBox(
                      height: 10,
                    ),
                    paginatedTransactions.isNotEmpty
                        ? Column(
                            children: [
                              Scrollbar(
                                thickness: 8.0,
                                thumbVisibility: true,
                                controller: _horizontalScroll,
                                radius: const Radius.circular(5),
                                child: LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
                                    final kWidth = constraints.maxWidth;
                                    return SingleChildScrollView(
                                      controller: _horizontalScroll,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: kWidth,
                                        ),
                                        child: Theme(
                                          data: theme.copyWith(dividerColor: Colors.transparent, dividerTheme: const DividerThemeData(color: Colors.transparent)),
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
                                                DataColumn(label: Text(lang.S.of(context).SL)),
                                                DataColumn(label: Text(lang.S.of(context).date)),
                                                DataColumn(label: Text(lang.S.of(context).invoice)),
                                                DataColumn(label: Text(lang.S.of(context).partyName)),
                                                DataColumn(label: Text(lang.S.of(context).partyType)),
                                                DataColumn(label: Text(lang.S.of(context).amount)),
                                                DataColumn(label: Text(lang.S.of(context).due)),
                                                DataColumn(label: Text(lang.S.of(context).status)),
                                                DataColumn(label: Text(lang.S.of(context).setting)),
                                              ],
                                              rows: List.generate(paginatedTransactions.length, (index) {
                                                return DataRow(cells: [
                                                  ///______________S.L__________________________________________________
                                                  DataCell(
                                                    Text(
                                                      (index + 1 + (currentPage - 1) * itemsPerPage).toString(),
                                                    ),
                                                  ),

                                                  ///______________Date__________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].purchaseDate.substring(0, 10),
                                                    ),
                                                  ),

                                                  ///____________Invoice_________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].invoiceNumber,
                                                    ),
                                                  ),

                                                  ///______Party Name___________________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].customerName,
                                                    ),
                                                  ),

                                                  ///___________Party Type______________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].paymentType.toString(),
                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  ///___________Amount____________________________________________________
                                                  DataCell(
                                                    Text(
                                                      myFormat.format(double.tryParse(paginatedTransactions[index].totalAmount.toString()) ?? 0),
                                                    ),
                                                  ),

                                                  ///___________Due____________________________________________________

                                                  DataCell(
                                                    Text(
                                                      myFormat.format(double.tryParse(paginatedTransactions[index].dueAmount.toString()) ?? 0),
                                                    ),
                                                  ),

                                                  ///___________Due____________________________________________________

                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                                                      style: kTextStyle.copyWith(color: kGreyTextColor),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  ///_______________actions_________________________________________________
                                                  DataCell(
                                                    settingProver.when(data: (setting) {
                                                      return SizedBox(
                                                        width: 30,
                                                        child: Theme(
                                                          data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                          child: PopupMenuButton(
                                                            surfaceTintColor: Colors.white,
                                                            color: Colors.white,
                                                            padding: EdgeInsets.zero,
                                                            offset: Offset(0, 40),
                                                            itemBuilder: (BuildContext bc) => [
                                                              PopupMenuItem(
                                                                onTap: () async {
                                                                  await GeneratePdfAndPrint().printPurchaseInvoice(setting: setting, personalInformationModel: profile.value!, purchaseTransactionModel: paginatedTransactions[index]);
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(
                                                                      icon: HugeIcons.strokeRoundedPrinter,
                                                                      color: kGreyTextColor,
                                                                      size: 22.0,
                                                                    ),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).print,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),

                                                              ///________Edit_Purchase_______________________________
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  context.push(
                                                                    '/purchase/purchase-edit',
                                                                    extra: {
                                                                      'personalInformationModel': profile.value,
                                                                      'isPosScreen': false,
                                                                      'purchaseTransitionModel': paginatedTransactions[index],
                                                                      'popupContext': bc,
                                                                    },
                                                                  );
                                                                  // PurchaseEdit(
                                                                  //   personalInformationModel: profile.value!,
                                                                  //   isPosScreen: false,
                                                                  //   purchaseTransitionModel: paginatedTransactions[index],
                                                                  //   popupContext: bc,
                                                                  // ).launch(context);
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    Icon(IconlyLight.edit, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).edit,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              ///________Purchase Delete_______________________________
                                                              PopupMenuItem(
                                                                onTap: () => showDialog(
                                                                    context: context,
                                                                    builder: (context2) => AlertDialog(
                                                                          title: Text('${lang.S.of(context).areYouSureToDeleteThisPurchase}?'),
                                                                          content: Text(
                                                                            lang.S.of(context).theSaleWillBeDeletedAndAllTheDataWillBeDeletedAboutThisPurchaseAreYouSureToDeleteThis,
                                                                            //'The sale will be deleted and all the data will be deleted about this Purchase .Are you sure to delete this?',
                                                                            maxLines: 5,
                                                                          ),
                                                                          actions: [
                                                                            Text(lang.S.of(context).cancel).onTap(() => Navigator.pop(context2)),
                                                                            Padding(
                                                                              padding: const EdgeInsets.all(20.0),
                                                                              child: Text(lang.S.of(context).yesDeleteForever).onTap(() async {
                                                                                EasyLoading.show();

                                                                                DeleteInvoice delete = DeleteInvoice();

                                                                                await delete.editStockAndSerialForPurchase(saleTransactionModel: paginatedTransactions[index]);

                                                                                await delete.customerDueUpdate(
                                                                                  due: paginatedTransactions[index].dueAmount ?? 0,
                                                                                  phone: paginatedTransactions[index].customerPhone,
                                                                                );
                                                                                await delete.updateFromShopRemainBalance(
                                                                                  paidAmount: (paginatedTransactions[index].totalAmount ?? 0) - (paginatedTransactions[index].dueAmount ?? 0),
                                                                                  isFromPurchase: true,
                                                                                );
                                                                                await delete.deleteDailyTransaction(invoice: paginatedTransactions[index].invoiceNumber, status: 'Purchase', field: 'purchaseTransactionModel');
                                                                                DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Purchase Transition/${paginatedTransactions[index].key}");

                                                                                await ref.remove();
                                                                                consuearRef.refresh(purchaseTransitionProvider);
                                                                                consuearRef.refresh(productProvider);
                                                                                consuearRef.refresh(supplierProvider);
                                                                                consuearRef.refresh(profileDetailsProvider);
                                                                                consuearRef.refresh(dailyTransactionProvider);
                                                                                EasyLoading.showSuccess(lang.S.of(context).done);
                                                                                // ignore: use_build_context_synchronously
                                                                                GoRouter.of(context2).pop();
                                                                                GoRouter.of(bc).pop();
                                                                              }),
                                                                            ),
                                                                          ],
                                                                        )),
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(
                                                                      icon: HugeIcons.strokeRoundedDelete02,
                                                                      color: kGreyTextColor,
                                                                      size: 22,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 4.0,
                                                                    ),
                                                                    Text(
                                                                      lang.S.of(context).delete,
                                                                      //'Delete',
                                                                      style: theme.textTheme.bodyLarge?.copyWith(
                                                                        color: kGreyTextColor,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              ///____Sales_Return________________________________________
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  context.push(
                                                                    '/purchase/purchase-returns',
                                                                    extra: {
                                                                      'purchaseTransactionModel': paginatedTransactions[index],
                                                                      'personalInformationModel': profile.value,
                                                                    },
                                                                  );
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(Icons.assignment_return, size: 22.0, color: kGreyTextColor),
                                                                    const SizedBox(width: 4.0),
                                                                    Text(
                                                                      lang.S.of(context).purchaseReturn,
                                                                      //'Purchase Return',
                                                                      style: theme.textTheme.bodyLarge?.copyWith(
                                                                        color: kGreyTextColor,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                            child: Center(
                                                              child: Container(
                                                                  height: 18,
                                                                  width: 18,
                                                                  alignment: Alignment.centerRight,
                                                                  child: const Icon(
                                                                    Icons.more_vert_sharp,
                                                                    size: 18,
                                                                  )),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }, error: (e, stack) {
                                                      return Text(e.toString());
                                                    }, loading: () {
                                                      return Center(child: CircularProgressIndicator());
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
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Showing ${startIndex + 1} to ${endIndex > paginatedTransactions.length ? paginatedTransactions.length : endIndex} of ${paginatedTransactions.length} entries',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: kNeutral700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: kNeutral300),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (currentPage > 1) {
                                                  setState(() {
                                                    currentPage--;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                'Previous',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                                color: kMainColor,
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                                  color: kNeutral300,
                                                ))),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$currentPage',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                              color: kNeutral300,
                                            ))),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$totalPages',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (currentPage < totalPages) {
                                                  setState(() {
                                                    currentPage++;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                'Next',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        : EmptyWidget(title: lang.S.of(context).noPurchaseTransactionFound)
                  ],
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
        }),
      ),
    );
  }
}
