import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/customer_model.dart';

import '../../Provider/customer_provider.dart';
import '../../const.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  static const String route = '/customerList';

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  void deleteCustomer(
      {required String phoneNumber,
      required WidgetRef updateRef,
      required BuildContext context}) async {
    EasyLoading.show(status: 'Deleting..');
    String customerKey = '';
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Customers')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['phoneNumber'].toString() == phoneNumber) {
          customerKey = element.key.toString();
        }
      }
    });
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("${await getUserID()}/Customers/$customerKey");
    await ref.remove();
    // ignore: unused_result
    updateRef.refresh(allCustomerProvider);
    // context.pop();
    EasyLoading.showSuccess('Done');
  }

  ScrollController mainScroll = ScrollController();
  String searchItem = '';

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _customerPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          AsyncValue<List<CustomerModel>> customers =
              ref.watch(allCustomerProvider);
          final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
          final globalCurrency = currencyProvider.currency ?? '\$';
          return customers.when(data: (list) {
            List<CustomerModel> allCustomerList = list.reversed.toList();
            List<String> listOfPhoneNumber = [];
            List<CustomerModel> customerLists = [];
            List<CustomerModel> showAbleCustomer = [];
            for (var value1 in allCustomerList) {
              listOfPhoneNumber.add(value1.phoneNumber
                  .replaceAll(RegExp(r'\s+'), '')
                  .toLowerCase());
              if (value1.type != 'Supplier') {
                customerLists.add(value1);
              }
            }
            for (var element in customerLists) {
              if (element.customerName
                      .replaceAll(RegExp(r'\s+'), '')
                      .toLowerCase()
                      .contains(searchItem.toLowerCase()) ||
                  element.phoneNumber.contains(searchItem)) {
                showAbleCustomer.add(element);
              } else if (searchItem == '') {
                showAbleCustomer.add(element);
              }
            }
            final totalPages =
                (showAbleCustomer.length / _customerPerPage).ceil();

            final startIndex = ((_currentPage - 1) * _customerPerPage);
            final endIndex = startIndex + _customerPerPage;
            final paginatedList = showAbleCustomer.sublist(
                startIndex,
                endIndex > showAbleCustomer.length
                    ? showAbleCustomer.length
                    : endIndex);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              lang.S.of(context).customerList,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(),
                            onPressed: () async {
                              if (finalUserRoleModel.partiesEdit == false) {
                                EasyLoading.showError(userPermissionErrorText);
                                return;
                              }
                              if (await Subscription.subscriptionChecker(
                                  item: "Parties")) {
                                // Use context.go or context.push to navigate to the AddCustomer screen
                                context.push(
                                  '/add-customer',
                                  extra: {
                                    'typeOfCustomerAdd': 'Buyer',
                                    'listOfPhoneNumber': listOfPhoneNumber,
                                  },
                                );
                              }
                              // else {
                              //   EasyLoading.showError('Update your plan first\nAdd Customer limit is over.');
                              // }
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                            label: Text(
                              lang.S.of(context).addCustomer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ElevatedButton.icon(
                          //     style: ElevatedButton.styleFrom(),
                          //     onPressed: () async {
                          //       if (finalUserRoleModel.partiesEdit == false) {
                          //         EasyLoading.showError(userPermissionErrorText);
                          //         return;
                          //       }
                          //       if (await Subscription.subscriptionChecker(item: "Parties")) {
                          //         // AddCustomer(typeOfCustomerAdd: 'Buyer', listOfPhoneNumber: listOfPhoneNumber, sideBarNumber: 1);
                          //         showDialog(
                          //             barrierDismissible: false,
                          //             context: context,
                          //             builder: (BuildContext context) {
                          //               return AddCustomer(
                          //                 typeOfCustomerAdd: 'Buyer',
                          //                 listOfPhoneNumber: listOfPhoneNumber,
                          //                 sideBarNumber: 6,
                          //               );
                          //             });
                          //       }
                          //       // else {
                          //       //   EasyLoading.showError('Update your plan first\nAdd Customer limit is over.');
                          //       // }
                          //     },
                          //     icon: const Icon(
                          //       Icons.add,
                          //       color: Colors.white,
                          //     ),
                          //     label: Text(
                          //       lang.S.of(context).addCustomer,
                          //       maxLines: 1,
                          //       overflow: TextOverflow.ellipsis,
                          //     )),
                          ///-------------------
                          // ResponsiveGridCol(
                          //     xs: 4,
                          //     md: 2,
                          //     lg: 2,
                          //     child: Padding(
                          //       padding: const EdgeInsets.symmetric(horizontal: 16),
                          //       child: ElevatedButton.icon(
                          //           style: ElevatedButton.styleFrom(
                          //             minimumSize: Size(
                          //               MediaQuery.of(context).size.width,
                          //               35,
                          //             ),
                          //           ),
                          //           onPressed: () async {
                          //             if (finalUserRoleModel.partiesEdit == false) {
                          //               EasyLoading.showError(userPermissionErrorText);
                          //               return;
                          //             }
                          //             if (await Subscription.subscriptionChecker(item: "Parties")) {
                          //               showDialog(
                          //                   barrierDismissible: false,
                          //                   context: context,
                          //                   builder: (BuildContext context) {
                          //                     return AddCustomer(
                          //                       typeOfCustomerAdd: 'Buyer',
                          //                       listOfPhoneNumber: listOfPhoneNumber,
                          //                       sideBarNumber: 6,
                          //                     );
                          //                   });
                          //             }
                          //             // else {
                          //             //   EasyLoading.showError('Update your plan first\nAdd Customer limit is over.');
                          //             // }
                          //           },
                          //           icon: const Icon(
                          //             Icons.add,
                          //             color: Colors.white,
                          //           ),
                          //           label: Text(
                          //             lang.S.of(context).addCustomer,
                          //             maxLines: 1,
                          //             overflow: TextOverflow.ellipsis,
                          //           )),
                          //     ))
                        ],
                      ),
                    ),
                    // Row(
                    //   children: [
                    //     Text(
                    //       lang.S.of(context).customerList,
                    //       style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    //     ),
                    //     const Spacer(),
                    //
                    //     ///___________search________________________________________________-
                    //     Container(
                    //       height: 40.0,
                    //       width: 300,
                    //       decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), border: Border.all(color: kGreyTextColor.withOpacity(0.1))),
                    //       child: AppTextField(
                    //         showCursor: true,
                    //         cursorColor: kTitleColor,
                    //         onChanged: (value) {
                    //           setState(() {
                    //             searchItem = value;
                    //           });
                    //         },
                    //         textFieldType: TextFieldType.NAME,
                    //         decoration: kInputDecoration.copyWith(
                    //           contentPadding: const EdgeInsets.all(10.0),
                    //           hintText: (lang.S.of(context).searchByNameOrPhone),
                    //           hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                    //           border: InputBorder.none,
                    //           enabledBorder: const OutlineInputBorder(
                    //             borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    //             borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                    //           ),
                    //           focusedBorder: const OutlineInputBorder(
                    //             borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    //             borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                    //           ),
                    //           suffixIcon: Padding(
                    //             padding: const EdgeInsets.all(4.0),
                    //             child: Container(
                    //                 padding: const EdgeInsets.all(2.0),
                    //                 decoration: BoxDecoration(
                    //                   borderRadius: BorderRadius.circular(30.0),
                    //                   color: kGreyTextColor.withOpacity(0.1),
                    //                 ),
                    //                 child: const Icon(
                    //                   FeatherIcons.search,
                    //                   color: kTitleColor,
                    //                 )),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 20),
                    //     Container(
                    //       padding: const EdgeInsets.all(10.0),
                    //       decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kBlueTextColor),
                    //       child: Row(
                    //         children: [
                    //           const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                    //           const SizedBox(width: 5.0),
                    //           Text(
                    //             lang.S.of(context).addCustomer,
                    //             style: kTextStyle.copyWith(color: kWhite),
                    //           ),
                    //         ],
                    //       ),
                    //     ).onTap(() async {
                    //       if (finalUserRoleModel.partiesEdit == false) {
                    //         EasyLoading.showError(userPermissionErrorText);
                    //         return;
                    //       }
                    //       if (await Subscription.subscriptionChecker(item: "Parties")) {
                    //         showDialog(
                    //             barrierDismissible: false,
                    //             context: context,
                    //             builder: (BuildContext context) {
                    //               return AddCustomer(
                    //                 typeOfCustomerAdd: 'Buyer',
                    //                 listOfPhoneNumber: listOfPhoneNumber,
                    //                 sideBarNumber: 6,
                    //               );
                    //             });
                    //       }
                    //       // else {
                    //       //   EasyLoading.showError('Update your plan first\nAdd Customer limit is over.');
                    //       // }
                    //     }
                    //     )
                    //   ],
                    // ),
                    const SizedBox(height: 10),
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
                                Flexible(
                                    child: Text('Show-',
                                        style: theme.textTheme.bodyLarge)),
                                DropdownButton<int>(
                                  isDense: true,
                                  padding: EdgeInsets.zero,
                                  underline: const SizedBox(),
                                  value: _customerPerPage,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.black,
                                  ),
                                  items: [10, 20, 50, 100, -1]
                                      .map<DropdownMenuItem<int>>((int value) {
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
                                        _customerPerPage =
                                            -1; // Set to -1 for "All"
                                      } else {
                                        _customerPerPage = newValue ?? 10;
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
                            child: TextFormField(
                              showCursor: true,
                              cursorColor: kTitleColor,
                              onChanged: (value) {
                                setState(() {
                                  searchItem = value;
                                });
                              },
                              keyboardType: TextInputType.name,
                              decoration: kInputDecoration.copyWith(
                                contentPadding: const EdgeInsets.all(10.0),
                                hintText:
                                    (lang.S.of(context).searchByNameOrPhone),
                                suffixIcon: const Icon(
                                  FeatherIcons.search,
                                  color: kNeutral400,
                                ),
                              ),
                            ),
                          )),
                    ]),

                    ///__________Customer_List________________________________________________
                    const SizedBox(height: 20.0),
                    showAbleCustomer.isNotEmpty
                        ? Column(
                            children: [
                              LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  final kWidth = constraints.maxWidth;
                                  return Scrollbar(
                                    controller: _horizontalScroll,
                                    thumbVisibility: true,
                                    radius: const Radius.circular(8),
                                    thickness: 8,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: _horizontalScroll,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: kWidth,
                                        ),
                                        child: Theme(
                                          data: theme.copyWith(
                                              dividerColor: Colors.transparent,
                                              dividerTheme:
                                                  const DividerThemeData(
                                                      color:
                                                          Colors.transparent)),
                                          child: DataTable(
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  width: 1,
                                                  color: kNeutral300,
                                                ),
                                              ),
                                              dataRowColor:
                                                  const WidgetStatePropertyAll(
                                                      Colors.white),
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                      const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle:
                                                  theme.textTheme.titleMedium,
                                              dataTextStyle:
                                                  theme.textTheme.bodyLarge,
                                              columns: [
                                                DataColumn(
                                                    label: Text(
                                                        lang.S.of(context).SL)),
                                                DataColumn(
                                                    label: Text(lang.S
                                                        .of(context)
                                                        .name)),
                                                DataColumn(
                                                    label: Text(lang.S
                                                        .of(context)
                                                        .paymentType)),
                                                DataColumn(
                                                    label: Text(lang.S
                                                        .of(context)
                                                        .phone)),
                                                DataColumn(
                                                    label: Text(lang.S
                                                        .of(context)
                                                        .email)),
                                                DataColumn(
                                                    label: Text(lang.S
                                                        .of(context)
                                                        .due)),
                                                DataColumn(
                                                    label: Text(lang.S
                                                        .of(context)
                                                        .setting)),
                                              ],
                                              rows: List.generate(
                                                  paginatedList.length,
                                                  (index) {
                                                final dataIndex =
                                                    (_currentPage - 1) *
                                                            _customerPerPage +
                                                        index;
                                                // ignore: unused_local_variable
                                                final customer =
                                                    showAbleCustomer[dataIndex];
                                                return DataRow(cells: [
                                                  ///______________S.L__________________________________________________
                                                  DataCell(
                                                    Text(
                                                        '${startIndex + index + 1}'),
                                                  ),

                                                  ///______________name__________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedList[index]
                                                          .customerName,
                                                    ),
                                                  ),

                                                  ///____________type_________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedList[index].type,
                                                    ),
                                                  ),

                                                  ///______Phone___________________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedList[index]
                                                          .phoneNumber,
                                                    ),
                                                  ),

                                                  ///___________Email____________________________________________________
                                                  DataCell(
                                                    Text(
                                                      paginatedList[index]
                                                          .emailAddress,
                                                    ),
                                                  ),

                                                  ///___________Due____________________________________________________

                                                  DataCell(
                                                    Text(
                                                      "$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].dueAmount) ?? 0)}",
                                                    ),
                                                  ),

                                                  ///_______________actions_________________________________________________
                                                  DataCell(
                                                    SizedBox(
                                                      width: 30,
                                                      child: Theme(
                                                        data: ThemeData(
                                                            highlightColor:
                                                                dropdownItemColor,
                                                            focusColor:
                                                                dropdownItemColor,
                                                            hoverColor:
                                                                dropdownItemColor),
                                                        child: PopupMenuButton(
                                                          surfaceTintColor:
                                                              Colors.white,
                                                          padding:
                                                              EdgeInsets.zero,
                                                          itemBuilder:
                                                              (BuildContext
                                                                      bc) =>
                                                                  [
                                                            ///____________Edit____________________________________________________
                                                            PopupMenuItem(
                                                                onTap: () {
                                                                  final customerModel =
                                                                      paginatedList[
                                                                          index];
                                                                  final allPreviousCustomer =
                                                                      allCustomerList;
                                                                  const typeOfCustomerAdd =
                                                                      'Buyer';

                                                                  // Use go_router to navigate to the EditCustomer screen
                                                                  context.push(
                                                                    '/edit-customer',
                                                                    extra: {
                                                                      'customerModel':
                                                                          customerModel,
                                                                      'allPreviousCustomer':
                                                                          allPreviousCustomer,
                                                                      'typeOfCustomerAdd':
                                                                          typeOfCustomerAdd,
                                                                    },
                                                                  );
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(
                                                                        IconlyLight
                                                                            .edit,
                                                                        size:
                                                                            20.0,
                                                                        color:
                                                                            kNeutral500),
                                                                    const SizedBox(
                                                                        width:
                                                                            4.0),
                                                                    Text(
                                                                      lang.S
                                                                          .of(context)
                                                                          .edit,
                                                                      style: theme
                                                                          .textTheme
                                                                          .bodyLarge
                                                                          ?.copyWith(
                                                                        color:
                                                                            kNeutral500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )),

                                                            ///____________delete___________________________________________________
                                                            PopupMenuItem(
                                                                onTap: () {
                                                                  if (double.parse(paginatedList[
                                                                              index]
                                                                          .dueAmount
                                                                          .toString()) ==
                                                                      0) {
                                                                    showDialog(
                                                                        barrierDismissible:
                                                                            false,
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (BuildContext
                                                                                dialogContext) {
                                                                          double
                                                                              dialogWidth =
                                                                              500;
                                                                          return Center(
                                                                            child:
                                                                                Container(
                                                                              width: dialogWidth,
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
                                                                                      lang.S.of(context).areYouWantToDeleteThisCustomer,
                                                                                      textAlign: TextAlign.center,
                                                                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    const SizedBox(height: 20),
                                                                                    ResponsiveGridRow(children: [
                                                                                      ResponsiveGridCol(
                                                                                        xs: 12,
                                                                                        md: 6,
                                                                                        lg: 6,
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.all(10.0),
                                                                                          child: OutlinedButton(
                                                                                            onPressed: () {
                                                                                              // Navigator.pop(dialogContext);
                                                                                              // Navigator.pop(bc);
                                                                                              context.pop();
                                                                                            },
                                                                                            child: Text(
                                                                                              lang.S.of(context).cancel,
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
                                                                                          child: ElevatedButton(
                                                                                            child: Text(
                                                                                              lang.S.of(context).delete,
                                                                                            ),
                                                                                            onPressed: () {
                                                                                              if (finalUserRoleModel.partiesDelete == false) {
                                                                                                EasyLoading.showError(userPermissionErrorText);
                                                                                                return;
                                                                                              }
                                                                                              if (!isDemo) {
                                                                                                deleteCustomer(phoneNumber: paginatedList[index].phoneNumber, updateRef: ref, context: bc);
                                                                                                // GoRouter.of(dialogContext).pop();
                                                                                                context.pop();
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
                                                                          );
                                                                        });
                                                                  } else {
                                                                    EasyLoading.showError(lang
                                                                        .S
                                                                        .of(context)
                                                                        .thisCustomerHavepreviousDue);
                                                                    // Navigator.pop(bc);
                                                                    context
                                                                        .pop();
                                                                  }
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(
                                                                      icon: HugeIcons
                                                                          .strokeRoundedDelete02,
                                                                      color:
                                                                          kNeutral500,
                                                                      size:
                                                                          20.0,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4.0),
                                                                    Text(
                                                                      lang.S
                                                                          .of(context)
                                                                          .delete,
                                                                      style: theme
                                                                          .textTheme
                                                                          .bodyLarge
                                                                          ?.copyWith(
                                                                              color: kNeutral500),
                                                                    ),
                                                                  ],
                                                                )),
                                                          ],
                                                          onSelected: (value) {
                                                            context
                                                                .go('$value');
                                                            // Navigator.pushNamed(context, '$value');
                                                          },
                                                          child: Center(
                                                            child: Container(
                                                                height: 18,
                                                                width: 18,
                                                                alignment: Alignment
                                                                    .centerRight,
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .more_vert_sharp,
                                                                  size: 18,
                                                                )),
                                                          ),
                                                        ),
                                                      ),
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
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'showing ${((_currentPage - 1) * _customerPerPage + 1).toString()} to ${((_currentPage - 1) * _customerPerPage + _customerPerPage).clamp(0, showAbleCustomer.length)} of ${showAbleCustomer.length} entries',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          overlayColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.grey),
                                          hoverColor: Colors.grey,
                                          onTap: _currentPage > 1
                                              ? () =>
                                                  setState(() => _currentPage--)
                                              : null,
                                          child: Container(
                                            height: 32,
                                            width: 90,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBorderColorTextField),
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
                                            border: Border.all(
                                                color: kBorderColorTextField),
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
                                        Container(
                                          height: 32,
                                          width: 32,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kBorderColorTextField),
                                            color: Colors.transparent,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$totalPages',
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          hoverColor:
                                              Colors.blue.withOpacity(0.1),
                                          overlayColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.blue),
                                          onTap: _currentPage *
                                                      _customerPerPage <
                                                  showAbleCustomer.length
                                              ? () =>
                                                  setState(() => _currentPage++)
                                              : null,
                                          child: Container(
                                            height: 32,
                                            width: 90,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBorderColorTextField),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomRight:
                                                    Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
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
                              // Container(
                              //   padding: const EdgeInsets.all(15),
                              //   decoration: const BoxDecoration(color: kbgColor),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       const SizedBox(width: 50, child: Text('S.L')),
                              //       SizedBox(width: 230, child: Text(lang.S.of(context).partyName)),
                              //       SizedBox(width: 75, child: Text(lang.S.of(context).partyType)),
                              //       SizedBox(width: 100, child: Text(lang.S.of(context).phone)),
                              //       SizedBox(width: 150, child: Text(lang.S.of(context).email)),
                              //       SizedBox(width: 70, child: Text(lang.S.of(context).due)),
                              //       const SizedBox(width: 30, child: Icon(FeatherIcons.settings)),
                              //     ],
                              //   ),
                              // ),
                              // SizedBox(
                              //   height: (MediaQuery.of(context).size.height - 315).isNegative ? 0 : MediaQuery.of(context).size.height - 315,
                              //   child: ListView.builder(
                              //     shrinkWrap: true,
                              //     physics: const AlwaysScrollableScrollPhysics(),
                              //     itemCount: showAbleCustomer.length,
                              //     itemBuilder: (BuildContext context, int index) {
                              //       return Padding(
                              //         padding: const EdgeInsets.only(bottom: 5),
                              //         child: Column(
                              //           children: [
                              //             Padding(
                              //               padding: const EdgeInsets.all(15.0),
                              //               child: Row(
                              //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //                 children: [
                              //                   ///______________S.L__________________________________________________
                              //                   SizedBox(
                              //                     width: 50,
                              //                     child: Text((index + 1).toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                              //                   ),
                              //
                              //                   ///______________name__________________________________________________
                              //                   SizedBox(
                              //                     width: 230,
                              //                     child: Text(
                              //                       showAbleCustomer[index].customerName,
                              //                       maxLines: 2,
                              //                       overflow: TextOverflow.ellipsis,
                              //                       style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                              //                     ),
                              //                   ),
                              //
                              //                   ///____________type_________________________________________________
                              //                   SizedBox(
                              //                     width: 75,
                              //                     child: Text(
                              //                       showAbleCustomer[index].type,
                              //                       maxLines: 2,
                              //                       overflow: TextOverflow.ellipsis,
                              //                       style: kTextStyle.copyWith(color: kGreyTextColor),
                              //                     ),
                              //                   ),
                              //
                              //                   ///______Phone___________________________________________________________
                              //                   SizedBox(
                              //                     width: 100,
                              //                     child: Text(
                              //                       showAbleCustomer[index].phoneNumber,
                              //                       style: kTextStyle.copyWith(color: kGreyTextColor),
                              //                       maxLines: 2,
                              //                       overflow: TextOverflow.ellipsis,
                              //                     ),
                              //                   ),
                              //
                              //                   ///___________Email____________________________________________________
                              //                   SizedBox(
                              //                     width: 150,
                              //                     child: Text(
                              //                       showAbleCustomer[index].emailAddress,
                              //                       style: kTextStyle.copyWith(color: kGreyTextColor),
                              //                       maxLines: 2,
                              //                       overflow: TextOverflow.ellipsis,
                              //                     ),
                              //                   ),
                              //
                              //                   ///___________Due____________________________________________________
                              //
                              //                   SizedBox(
                              //                     width: 70,
                              //                     child: Text(
                              //                       myFormat.format(double.tryParse(showAbleCustomer[index].dueAmount) ?? 0),
                              //                       style: kTextStyle.copyWith(color: kGreyTextColor),
                              //                       maxLines: 2,
                              //                       overflow: TextOverflow.ellipsis,
                              //                     ),
                              //                   ),
                              //
                              //                   ///_______________actions_________________________________________________
                              //                   SizedBox(
                              //                     width: 30,
                              //                     child: Theme(
                              //                       data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                              //                       child: PopupMenuButton(
                              //                         surfaceTintColor: Colors.white,
                              //                         padding: EdgeInsets.zero,
                              //                         itemBuilder: (BuildContext bc) => [
                              //                           ///____________Edit____________________________________________________
                              //                           PopupMenuItem(
                              //                             child: Row(
                              //                               children: [
                              //                                 const Icon(FeatherIcons.edit3, size: 18.0, color: kTitleColor),
                              //                                 const SizedBox(width: 4.0),
                              //                                 Text(
                              //                                   lang.S.of(context).edit,
                              //                                   style: kTextStyle.copyWith(color: kGreyTextColor),
                              //                                 ),
                              //                               ],
                              //                             ).onTap(() {
                              //                               showDialog(
                              //                                   barrierDismissible: false,
                              //                                   context: context,
                              //                                   builder: (BuildContext context) {
                              //                                     return EditCustomer(
                              //                                       allPreviousCustomer: allCustomerList,
                              //                                       customerModel: showAbleCustomer[index],
                              //                                       typeOfCustomerAdd: 'Buyer',
                              //                                       popupContext: bc,
                              //                                     );
                              //                                   });
                              //                             }),
                              //                           ),
                              //
                              //                           ///____________delete___________________________________________________
                              //                           PopupMenuItem(
                              //                             child: Row(
                              //                               children: [
                              //                                 const Icon(Icons.delete_outline, size: 18.0, color: kTitleColor),
                              //                                 const SizedBox(width: 4.0),
                              //                                 Text(
                              //                                   lang.S.of(context).delete,
                              //                                   style: kTextStyle.copyWith(color: kGreyTextColor),
                              //                                 ),
                              //                               ],
                              //                             ).onTap(() {
                              //                               if (double.parse(showAbleCustomer[index].dueAmount.toString()) == 0) {
                              //                                 showDialog(
                              //                                     barrierDismissible: false,
                              //                                     context: context,
                              //                                     builder: (BuildContext dialogContext) {
                              //                                       return Center(
                              //                                         child: Container(
                              //                                           decoration: const BoxDecoration(
                              //                                             color: Colors.white,
                              //                                             borderRadius: BorderRadius.all(
                              //                                               Radius.circular(15),
                              //                                             ),
                              //                                           ),
                              //                                           child: Padding(
                              //                                             padding: const EdgeInsets.all(20.0),
                              //                                             child: Column(
                              //                                               mainAxisSize: MainAxisSize.min,
                              //                                               crossAxisAlignment: CrossAxisAlignment.center,
                              //                                               mainAxisAlignment: MainAxisAlignment.center,
                              //                                               children: [
                              //                                                 Text(
                              //                                                   lang.S.of(context).areYouWantToDeleteThisCustomer,
                              //                                                   style: const TextStyle(fontSize: 22),
                              //                                                 ),
                              //                                                 const SizedBox(height: 30),
                              //                                                 Row(
                              //                                                   mainAxisAlignment: MainAxisAlignment.center,
                              //                                                   mainAxisSize: MainAxisSize.min,
                              //                                                   children: [
                              //                                                     GestureDetector(
                              //                                                       child: Container(
                              //                                                         width: 130,
                              //                                                         height: 50,
                              //                                                         decoration: const BoxDecoration(
                              //                                                           color: Colors.green,
                              //                                                           borderRadius: BorderRadius.all(
                              //                                                             Radius.circular(15),
                              //                                                           ),
                              //                                                         ),
                              //                                                         child: Center(
                              //                                                           child: Text(
                              //                                                             lang.S.of(context).cancel,
                              //                                                             style: const TextStyle(color: Colors.white),
                              //                                                           ),
                              //                                                         ),
                              //                                                       ),
                              //                                                       onTap: () {
                              //                                                         Navigator.pop(dialogContext);
                              //                                                         Navigator.pop(bc);
                              //                                                       },
                              //                                                     ),
                              //                                                     const SizedBox(width: 30),
                              //                                                     GestureDetector(
                              //                                                       child: Container(
                              //                                                         width: 130,
                              //                                                         height: 50,
                              //                                                         decoration: const BoxDecoration(
                              //                                                           color: Colors.red,
                              //                                                           borderRadius: BorderRadius.all(
                              //                                                             Radius.circular(15),
                              //                                                           ),
                              //                                                         ),
                              //                                                         child: Center(
                              //                                                           child: Text(
                              //                                                             lang.S.of(context).delete,
                              //                                                             style: const TextStyle(color: Colors.white),
                              //                                                           ),
                              //                                                         ),
                              //                                                       ),
                              //                                                       onTap: () {
                              //                                                         if (finalUserRoleModel.partiesDelete == false) {
                              //                                                           EasyLoading.showError(userPermissionErrorText);
                              //                                                           return;
                              //                                                         }
                              //                                                         if (!isDemo) {
                              //                                                           deleteCustomer(
                              //                                                               phoneNumber: showAbleCustomer[index].phoneNumber, updateRef: ref, context: bc);
                              //                                                           Navigator.pop(dialogContext);
                              //                                                         } else {
                              //                                                           EasyLoading.showInfo(demoText);
                              //                                                         }
                              //                                                       },
                              //                                                     ),
                              //                                                   ],
                              //                                                 )
                              //                                               ],
                              //                                             ),
                              //                                           ),
                              //                                         ),
                              //                                       );
                              //                                     });
                              //                               } else {
                              //                                 EasyLoading.showError(lang.S.of(context).thisCustomerHavepreviousDue);
                              //                                 Navigator.pop(bc);
                              //                               }
                              //                             }),
                              //                           ),
                              //                         ],
                              //                         onSelected: (value) {
                              //                           Navigator.pushNamed(context, '$value');
                              //                         },
                              //                         child: Center(
                              //                           child: Container(
                              //                               height: 18,
                              //                               width: 18,
                              //                               alignment: Alignment.centerRight,
                              //                               child: const Icon(
                              //                                 Icons.more_vert_sharp,
                              //                                 size: 18,
                              //                               )),
                              //                         ),
                              //                       ),
                              //                     ),
                              //                   ),
                              //                 ],
                              //               ),
                              //             ),
                              //             Container(
                              //               width: double.infinity,
                              //               height: 1,
                              //               color: kGreyTextColor.withOpacity(0.2),
                              //             )
                              //           ],
                              //         ),
                              //       );
                              //     },
                              //   ),
                              // )
                            ],
                          )
                        : EmptyWidget(title: lang.S.of(context).noCustomerFound)
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
        }));
  }
}
