import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../model/purchase_transation_model.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({Key? key}) : super(key: key);
  static const String route = '/warranty';

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  bool searchReturn({required SaleTransactionModel list, required String searchItem}) {
    for (var element in list.productList!) {
      if (element.serialNumber!.contains(searchItem)) {
        return true;
      }
    }

    return false;
  }

  bool searchReturnPurchase({required PurchaseTransactionModel list, required String searchItem}) {
    for (var element in list.productList!) {
      if (element.serialNumber.contains(searchItem)) {
        return true;
      }
    }

    return false;
  }

  ScrollController mainScroll = ScrollController();
  String searchItem = '';
  RegExp regex = RegExp('[a-zA-Z]');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Scrollbar(
          controller: mainScroll,
          child: SingleChildScrollView(
            controller: mainScroll,
            scrollDirection: Axis.horizontal,
            child: Consumer(builder: (_, ref, watch) {
              final transactionReport = ref.watch(transitionProvider);
              final settingProvider = ref.watch(generalSettingProvider);
              final purchaseTransactionReport = ref.watch(purchaseTransitionProvider);
              final profile = ref.watch(profileDetailsProvider);
              return transactionReport.when(data: (mainTransaction) {
                return purchaseTransactionReport.when(data: (purchase) {
                  final reMainTransaction = mainTransaction.reversed.toList();
                  List<SaleTransactionModel> showAbleSaleTransactions = [];
                  List<PurchaseTransactionModel> showAblePurchaseTransactions = [];
                  for (var element in reMainTransaction) {
                    if (searchItem != '' && (searchReturn(list: element, searchItem: searchItem.toLowerCase()) || element.invoiceNumber.toLowerCase().contains(searchItem.toLowerCase()))) {
                      showAbleSaleTransactions.add(element);
                    }
                  }
                  for (var element in purchase) {
                    if (searchItem != '' && searchReturnPurchase(list: element, searchItem: searchItem.toLowerCase())) {
                      showAblePurchaseTransactions.add(element);
                    }
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(
                      //   width: 240,
                      //   child: SideBarWidget(
                      //     index: 13,
                      //     isTab: false,
                      //   ),
                      // ),
                      Container(
                        width: MediaQuery.of(context).size.width < 1275 ? 1275 - 240 : MediaQuery.of(context).size.width - 240,
                        // width: context.width() < 1080 ? 1080 - 240 : MediaQuery.of(context).size.width - 240,
                        decoration: const BoxDecoration(color: kDarkWhite),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //_______________________________top_bar____________________________
                              // const TopBar(),

                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Container(
                                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            lang.S.of(context).checkWarranty,
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                          ),
                                          const Spacer(),

                                          ///___________search________________________________________________-
                                          Container(
                                            height: 40.0,
                                            width: 300,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), border: Border.all(color: kGreyTextColor.withOpacity(0.1))),
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
                                                contentPadding: const EdgeInsets.all(10.0),
                                                hintText: (lang.S.of(context).searchByInvoiceOrName),
                                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                border: InputBorder.none,
                                                suffixIcon: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Container(
                                                      padding: const EdgeInsets.all(2.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(30.0),
                                                        color: kGreyTextColor.withOpacity(0.1),
                                                      ),
                                                      child: const Icon(
                                                        FeatherIcons.search,
                                                        color: kTitleColor,
                                                      )),
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

                                      ///_______sale_List_____________________________________________________

                                      const SizedBox(height: 20.0),
                                      showAbleSaleTransactions.isNotEmpty
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(
                                                  child: SizedBox(
                                                    child: Column(
                                                      children: [
                                                        Text(lang.S.of(context).customerInvoices, style: TextStyle(fontSize: 18)),
                                                        const SizedBox(height: 10),
                                                        Container(
                                                          padding: const EdgeInsets.all(15),
                                                          decoration: BoxDecoration(color: kGreyTextColor.withOpacity(0.3)),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              SizedBox(width: 180, child: Text(lang.S.of(context).customerName)),
                                                              SizedBox(width: 50, child: Text(lang.S.of(context).invoice)),
                                                              SizedBox(width: 80, child: Text(lang.S.of(context).date)),
                                                              const SizedBox(width: 30, child: Icon(FeatherIcons.settings)),
                                                            ],
                                                          ),
                                                        ),
                                                        ListView.builder(
                                                          shrinkWrap: true,
                                                          physics: const NeverScrollableScrollPhysics(),
                                                          itemCount: showAbleSaleTransactions.length,
                                                          itemBuilder: (BuildContext context, int index) {
                                                            return Column(
                                                              children: [
                                                                Padding(
                                                                  padding: const EdgeInsets.all(15),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      ///______Party Name___________________________________________________________
                                                                      SizedBox(
                                                                        width: 180,
                                                                        child: Text(
                                                                          showAbleSaleTransactions[index].customerName,
                                                                          style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),

                                                                      ///____________Invoice_________________________________________________
                                                                      SizedBox(
                                                                        width: 50,
                                                                        child: Text(showAbleSaleTransactions[index].invoiceNumber, maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                                      ),

                                                                      ///______________Date__________________________________________________
                                                                      SizedBox(
                                                                        width: 78,
                                                                        child: Text(
                                                                          showAbleSaleTransactions[index].purchaseDate.substring(0, 10),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),

                                                                      ///_______________actions_________________________________________________
                                                                      settingProvider.when(data: (setting) {
                                                                        return SizedBox(
                                                                          width: 30,
                                                                          child: PopupMenuButton(
                                                                            padding: EdgeInsets.zero,
                                                                            itemBuilder: (BuildContext bc) => [
                                                                              PopupMenuItem(
                                                                                child: GestureDetector(
                                                                                  onTap: () async {
                                                                                    await GeneratePdfAndPrint().printSaleInvoice(setting: setting, personalInformationModel: profile.value!, saleTransactionModel: showAbleSaleTransactions[index], context: context);
                                                                                    // SaleInvoice(
                                                                                    //   isPosScreen: false,
                                                                                    //   transitionModel: showAbleSaleTransactions[index],
                                                                                    //   personalInformationModel: profile.value!,
                                                                                    // ).launch(context);
                                                                                  },
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                                                      const SizedBox(width: 4.0),
                                                                                      Text(
                                                                                        lang.S.of(context).print,
                                                                                        style: kTextStyle.copyWith(color: kTitleColor),
                                                                                      ),
                                                                                    ],
                                                                                  ),
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
                                                                        );
                                                                      }, error: (e, stack) {
                                                                        return Text(e.toString());
                                                                      }, loading: () {
                                                                        return Center(
                                                                          child: CircularProgressIndicator(),
                                                                        );
                                                                      })
                                                                    ],
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: double.infinity,
                                                                  height: 1,
                                                                  color: kGreyTextColor.withOpacity(0.2),
                                                                )
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: SizedBox(
                                                    child: Column(
                                                      children: [
                                                        Text(lang.S.of(context).supplierInvoice, style: const TextStyle(fontSize: 18)),
                                                        const SizedBox(height: 10),
                                                        Container(
                                                          padding: const EdgeInsets.all(15),
                                                          decoration: BoxDecoration(color: kGreyTextColor.withOpacity(0.3)),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              SizedBox(width: 180, child: Text(lang.S.of(context).customerName)),
                                                              SizedBox(width: 50, child: Text(lang.S.of(context).invoice)),
                                                              SizedBox(width: 80, child: Text(lang.S.of(context).date)),
                                                              const SizedBox(width: 30, child: Icon(FeatherIcons.settings)),
                                                            ],
                                                          ),
                                                        ),
                                                        ListView.builder(
                                                          shrinkWrap: true,
                                                          physics: const NeverScrollableScrollPhysics(),
                                                          itemCount: showAblePurchaseTransactions.length,
                                                          itemBuilder: (BuildContext context, int index) {
                                                            return Column(
                                                              children: [
                                                                Padding(
                                                                  padding: const EdgeInsets.all(15),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      ///______Party Name___________________________________________________________
                                                                      SizedBox(
                                                                        width: 180,
                                                                        child: Text(
                                                                          showAblePurchaseTransactions[index].customerName,
                                                                          style: kTextStyle.copyWith(color: kGreyTextColor),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),

                                                                      ///____________Invoice_________________________________________________
                                                                      SizedBox(
                                                                        width: 50,
                                                                        child: Text(showAblePurchaseTransactions[index].invoiceNumber, maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                                                      ),

                                                                      ///______________Date__________________________________________________
                                                                      SizedBox(
                                                                        width: 80,
                                                                        child: Text(
                                                                          showAblePurchaseTransactions[index].purchaseDate.substring(0, 10),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),

                                                                      ///_______________actions_________________________________________________
                                                                      settingProvider.when(data: (setting) {
                                                                        return SizedBox(
                                                                          width: 30,
                                                                          child: PopupMenuButton(
                                                                            padding: EdgeInsets.zero,
                                                                            itemBuilder: (BuildContext bc) => [
                                                                              PopupMenuItem(
                                                                                child: GestureDetector(
                                                                                  onTap: () async {
                                                                                    await GeneratePdfAndPrint().printPurchaseInvoice(
                                                                                      setting: setting,
                                                                                      personalInformationModel: profile.value!,
                                                                                      purchaseTransactionModel: showAblePurchaseTransactions[index],
                                                                                    );
                                                                                  },
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Icon(MdiIcons.printer, size: 18.0, color: kTitleColor),
                                                                                      const SizedBox(width: 4.0),
                                                                                      Text(
                                                                                        lang.S.of(context).print,
                                                                                        style: kTextStyle.copyWith(color: kTitleColor),
                                                                                      ),
                                                                                    ],
                                                                                  ),
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
                                                                        );
                                                                      }, error: (e, stack) {
                                                                        return Text(e.toString());
                                                                      }, loading: () {
                                                                        return Center(child: CircularProgressIndicator());
                                                                      }),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: double.infinity,
                                                                  height: 1,
                                                                  color: kGreyTextColor.withOpacity(0.2),
                                                                )
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ).visible(regex.hasMatch(searchItem)),
                                              ],
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 20),
                                                  const Image(
                                                    image: AssetImage('images/empty_screen.png'),
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    lang.S.of(context).noInvoiceFound,
                                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.0),
                                                  ),
                                                  const SizedBox(height: 20),
                                                ],
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
            }),
          ),
        ),
      ),
    );
  }
}
