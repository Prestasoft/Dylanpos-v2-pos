import 'dart:convert';

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
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/customer_model.dart';

import '../../Provider/customer_provider.dart';
import '../../const.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';

class SupplierList extends StatefulWidget {
  const SupplierList({Key? key}) : super(key: key);

  static const String route = '/supplier';

  @override
  State<SupplierList> createState() => _SupplierListState();
}

class _SupplierListState extends State<SupplierList> {
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
        child: Text('${des.toString()} items'),
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

  void deleteCustomer(
      {required String phoneNumber,
      required WidgetRef updateRef,
      required BuildContext context}) async {
    EasyLoading.show(status: '${lang.S.of(context).deleting}..');
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
    final refreshedCustomers = updateRef.refresh(allCustomerProvider);
    print(refreshedCustomers);
    // ignore: use_build_context_synchronously
    // Navigator.pop(context);
    GoRouter.of(context).pop();

    EasyLoading.showSuccess(lang.S.of(context).done);
  }

  ScrollController mainScroll = ScrollController();
  String searchItem = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _categoryPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (_, ref, watch) {
          AsyncValue<List<CustomerModel>> allCustomers =
              ref.watch(allCustomerProvider);
          return allCustomers.when(data: (allList) {
            List<CustomerModel> allCustomers = allList.reversed.toList();
            List<String> listOfPhoneNumber = [];
            List<CustomerModel> showAbleSuppliers = [];
            List<CustomerModel> allSupplier = [];

            for (var value1 in allCustomers) {
              listOfPhoneNumber
                  .add(value1.phoneNumber.removeAllWhiteSpace().toLowerCase());
              if (value1.type == 'Supplier') {
                allSupplier.add(value1);
              }
            }

            for (var element in allSupplier) {
              if (element.customerName
                      .removeAllWhiteSpace()
                      .toLowerCase()
                      .contains(searchItem.toLowerCase()) ||
                  element.phoneNumber.contains(searchItem)) {
                showAbleSuppliers.add(element);
              } else if (searchItem == '') {
                showAbleSuppliers.add(element);
              }
            }
            final pages = (showAbleSuppliers.length / _categoryPerPage).ceil();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: kWhite),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              lang.S.of(context).supplierList,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (await Subscription.subscriptionChecker(
                                  item: 'Parties')) {
                                // Navigate to the GoRoute screen
                                context.push(
                                  '/add-customer',
                                  extra: {
                                    'typeOfCustomerAdd': 'Supplier',
                                    'listOfPhoneNumber': listOfPhoneNumber,
                                  },
                                );
                                // showDialog(
                                //     barrierDismissible: false,
                                //     context: context,
                                //     builder: (BuildContext context) {
                                //       return AddCustomer(
                                //         typeOfCustomerAdd: 'Supplier',
                                //         listOfPhoneNumber: listOfPhoneNumber,
                                //       );
                                //     });
                              } else {
                                EasyLoading.showError(
                                    '${lang.S.of(context).updateYourPlanFirstSaleLimitIsOver}.');
                              }
                            },
                            icon: const Icon(FeatherIcons.plus,
                                color: kWhite, size: 18.0),
                            label: Text(
                              lang.S.of(context).addSupplier,
                              style: kTextStyle.copyWith(color: kWhite),
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

                    ///___________search________________________________________________
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: kNeutral300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                    child: Text(
                                  'Show-',
                                  style: theme.textTheme.bodyLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                                DropdownButton<int>(
                                  isDense: true,
                                  padding: EdgeInsets.zero,
                                  underline: const SizedBox(),
                                  value: _categoryPerPage,
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
                                        _categoryPerPage =
                                            -1; // Set to -1 for "All"
                                      } else {
                                        _categoryPerPage = newValue ?? 10;
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
                              decoration: InputDecoration(
                                hintText:
                                    (lang.S.of(context).searchByNameOrPhone),
                                suffixIcon: const Icon(
                                  FeatherIcons.search,
                                  color: kTitleColor,
                                ),
                              ),
                            ),
                          )),
                    ]),
                    const SizedBox(height: 20.0),

                    ///__________list_______________________________________________________________________
                    showAbleSuppliers.isNotEmpty
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
                                      controller: _horizontalScroll,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(minWidth: kWidth),
                                        child: Theme(
                                          data: theme.copyWith(
                                            dividerColor: Colors.transparent,
                                            dividerTheme:
                                                const DividerThemeData(
                                                    color: Colors.transparent),
                                          ),
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
                                            columns: [
                                              DataColumn(
                                                label: Text(
                                                  lang.S.of(context).SL,
                                                  //'S.L',
                                                ),
                                              ),
                                              DataColumn(
                                                  label: Text(
                                                lang.S.of(context).image,
                                              )),
                                              DataColumn(
                                                  label: Flexible(
                                                      child: Text(
                                                lang.S.of(context).partyName,
                                              ))),
                                              DataColumn(
                                                  label: Flexible(
                                                      child: Text(
                                                lang.S.of(context).partyType,
                                              ))),
                                              DataColumn(
                                                  label: Text(
                                                lang.S.of(context).phone,
                                              )),
                                              DataColumn(
                                                  label: Text(
                                                lang.S.of(context).email,
                                              )),
                                              DataColumn(
                                                  label: Text(
                                                lang.S.of(context).due,
                                              )),
                                              const DataColumn(
                                                  label: Icon(
                                                      FeatherIcons.settings)),
                                            ],
                                            rows: List.generate(
                                              showAbleSuppliers.length,
                                              (index) {
                                                print(showAbleSuppliers[index]
                                                    .profilePicture);
                                                return DataRow(
                                                  cells: [
                                                    DataCell(Text(
                                                      (index + 1).toString(),
                                                      style: kTextStyle.copyWith(
                                                          color:
                                                              kGreyTextColor),
                                                      textAlign:
                                                          TextAlign.start,
                                                    )),
                                                    DataCell(Container(
                                                      height: 40,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color:
                                                                kBorderColorTextField),
                                                        image: DecorationImage(
                                                            image: NetworkImage(
                                                                showAbleSuppliers[
                                                                        index]
                                                                    .profilePicture),
                                                            fit: BoxFit.cover),
                                                      ),
                                                    )),
                                                    DataCell(
                                                      Text(
                                                        showAbleSuppliers[index]
                                                            .customerName,
                                                        style:
                                                            kTextStyle.copyWith(
                                                                color:
                                                                    kTitleColor),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(showAbleSuppliers[
                                                              index]
                                                          .type),
                                                    ),
                                                    DataCell(
                                                      Text(showAbleSuppliers[
                                                              index]
                                                          .phoneNumber),
                                                    ),
                                                    DataCell(
                                                      Text(showAbleSuppliers[
                                                              index]
                                                          .emailAddress),
                                                    ),
                                                    DataCell(
                                                      Text(myFormat.format(
                                                          double.tryParse(
                                                                  showAbleSuppliers[
                                                                          index]
                                                                      .dueAmount) ??
                                                              0)),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 20,
                                                        child: Theme(
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
                                                                Colors.white,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            itemBuilder:
                                                                (BuildContext
                                                                        bc) =>
                                                                    [
                                                              PopupMenuItem(
                                                                onTap: () {
                                                                  final customerModel =
                                                                      showAbleSuppliers[
                                                                          index];
                                                                  final allPreviousCustomer =
                                                                      allCustomers;
                                                                  const typeOfCustomerAdd =
                                                                      'Supplier';

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
                                                                              color: kNeutral500),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              PopupMenuItem(
                                                                value: 'delete',
                                                                onTap: () {
                                                                  if (!isDemo) {
                                                                    if (double.parse(showAbleSuppliers[index]
                                                                            .dueAmount
                                                                            .toString()) ==
                                                                        0) {
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
                                                                                  width: 500,
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
                                                                                        padding: const EdgeInsets.all(20.0),
                                                                                        child: Text(
                                                                                          lang.S.of(context).areYouWantToDeleteThisCustomer,
                                                                                          style: theme.textTheme.titleLarge?.copyWith(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontSize: 22,
                                                                                          ),
                                                                                          textAlign: TextAlign.center,
                                                                                        ),
                                                                                      ),
                                                                                      // const SizedBox(height: 20),
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
                                                                                              child: Text(
                                                                                                lang.S.of(context).cancel,
                                                                                              ),
                                                                                              onPressed: () {
                                                                                                GoRouter.of(context).pop();
                                                                                                // Navigator.pop(dialogContext);
                                                                                                // Navigator.pop(bc);
                                                                                              },
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
                                                                                                deleteCustomer(phoneNumber: showAbleSuppliers[index].phoneNumber, updateRef: ref, context: bc);
                                                                                                // Navigator.pop(dialogContext);
                                                                                                // GoRouter.of(context).pop();
                                                                                              },
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ]),
                                                                                      const SizedBox(height: 10),
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
                                                                          .thisCustomerHavePreviousDue);
                                                                      GoRouter.of(
                                                                              context)
                                                                          .pop();
                                                                    }
                                                                  } else {
                                                                    EasyLoading
                                                                        .showInfo(
                                                                            demoText);
                                                                  }
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    HugeIcon(
                                                                        icon: HugeIcons
                                                                            .strokeRoundedDelete02,
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
                                                                          .delete,
                                                                      style: theme
                                                                          .textTheme
                                                                          .bodyLarge
                                                                          ?.copyWith(
                                                                        color:
                                                                            kNeutral500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            ],
                                                            onSelected:
                                                                (value) {
                                                              context
                                                                  .go('$value');
                                                              // Navigator.pushNamed(context, '$value');
                                                            },
                                                            child: Center(
                                                              child: Container(
                                                                  height: 18,
                                                                  width: 18,
                                                                  alignment:
                                                                      Alignment
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
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
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
                                        '${lang.S.of(context).showing} ${((_currentPage - 1) * _categoryPerPage + 1).toString()} to ${((_currentPage - 1) * _categoryPerPage + _categoryPerPage).clamp(0, showAbleSuppliers.length)} of ${showAbleSuppliers.length} entries',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          overlayColor:
                                              WidgetStateProperty.all<Color>(
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
                                            child: Center(
                                              child: Text(
                                                  lang.S.of(context).previous),
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
                                              '$pages',
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
                                                      _categoryPerPage <
                                                  showAbleSuppliers.length
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
                            ],
                          )
                        : EmptyWidget(
                            title: lang.S.of(context).noSupplierFound),
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
