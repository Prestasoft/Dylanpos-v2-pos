import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart' show EasyLoading;
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/Designation/model/designation_model.dart';
import 'package:salespro_admin/Screen/HRM/Designation/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../../Widgets/Constant Data/export_button.dart';
import '../widgets/deleteing_alart_dialog.dart';
import 'add_designation.dart';

class DesignationListScreen extends StatefulWidget {
  const DesignationListScreen({super.key});

  static const String route = '/HRM/designation_List';

  @override
  State<DesignationListScreen> createState() => _DesignationListScreenState();
}

class _DesignationListScreenState extends State<DesignationListScreen> {
  String searchItem = '';

  ScrollController mainScroll = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _designationPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final designations = ref.watch(designationProvider);
          return Scaffold(
            backgroundColor: kDarkWhite,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_______________________________top_bar____________________________
                  // const TopBar(),

                  designations.when(data: (designationList) {
                    List<DesignationModel> reverseAllIncomeCategory = designationList.reversed.toList();
                    List<DesignationModel> showIncomeCategory = [];
                    for (var element in reverseAllIncomeCategory) {
                      if (searchItem != '' && (element.designation.toLowerCase().contains(searchItem.toLowerCase()) || element.designation.toLowerCase().contains(searchItem.toLowerCase()))) {
                        showIncomeCategory.add(element);
                      } else if (searchItem == '') {
                        showIncomeCategory.add(element);
                      }
                    }

                    final pages = (showIncomeCategory.length / _designationPerPage).ceil();

                    final startIndex = (_currentPage - 1) * _designationPerPage;
                    final endIndex = _designationPerPage == -1 ? showIncomeCategory.length : startIndex + _designationPerPage;
                    final paginatedList = showIncomeCategory.sublist(
                      startIndex,
                      endIndex > showIncomeCategory.length ? showIncomeCategory.length : endIndex,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      lang.S.of(context).designationList,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 20.0),
                                  ElevatedButton(
                                      onPressed: () => finalUserRoleModel.hrmEdit == false
                                          ? EasyLoading.showError(userPermissionErrorText)
                                          : showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return StatefulBuilder(
                                                  builder: (context, setStates) {
                                                    return Dialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20.0),
                                                      ),
                                                      child: AddDesignationScreen(listOfIncomeCategory: designationList),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                      child: Text(lang.S.of(context).addDesignation)),
                                  // Container(
                                  //   padding: const EdgeInsets.all(5.0),
                                  //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kBlueTextColor),
                                  //   child: Container(
                                  //     padding: const EdgeInsets.all(5.0),
                                  //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kBlueTextColor),
                                  //     child: Row(
                                  //       children: [
                                  //         const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                                  //         const SizedBox(width: 5.0),
                                  //         Text(
                                  //           lang.S.of(context).addDesignation,
                                  //           //'Add Designation',
                                  //           style: kTextStyle.copyWith(color: kWhite),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ).onTap(
                                  //   () => finalUserRoleModel.hrmEdit == false
                                  //       ? EasyLoading.showError(userPermissionErrorText)
                                  //       : showDialog(
                                  //           barrierDismissible: false,
                                  //           context: context,
                                  //           builder: (BuildContext context) {
                                  //             return StatefulBuilder(
                                  //               builder: (context, setStates) {
                                  //                 return Dialog(
                                  //                   shape: RoundedRectangleBorder(
                                  //                     borderRadius: BorderRadius.circular(20.0),
                                  //                   ),
                                  //                   child: AddDesignationScreen(listOfIncomeCategory: designationList),
                                  //                 );
                                  //               },
                                  //             );
                                  //           },
                                  //         ),
                                  // ),
                                ],
                              ),
                            ),
                            const Divider(
                              thickness: 1.0,
                              color: kNeutral300,
                              height: 1,
                            ),

                            ///___________search________________________________________________-
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
                                          value: _designationPerPage,
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
                                                _designationPerPage = -1; // Set to -1 for "All"
                                              } else {
                                                _designationPerPage = newValue ?? 10;
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
                                  padding: const EdgeInsets.all(10.0),
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
                                      contentPadding: const EdgeInsets.all(10.0),
                                      hintText: (lang.S.of(context).searchByName),
                                      suffixIcon: const Icon(
                                        FeatherIcons.search,
                                        color: kTitleColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),

                            ///__________expense_LIst____________________________________________________________________
                            showIncomeCategory.isNotEmpty
                                ? Column(
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constraints) {
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
                                                  data: theme.copyWith(
                                                    dividerColor: Colors.transparent,
                                                    dividerTheme: const DividerThemeData(color: Colors.transparent),
                                                  ),
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
                                                    columns: [
                                                      DataColumn(
                                                        label: Text(
                                                          lang.S.of(context).SL,
                                                          // 'S.L',
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          lang.S.of(context).categoryName,
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          lang.S.of(context).description,
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          lang.S.of(context).action,
                                                        ),
                                                      ),
                                                    ],
                                                    rows: List.generate(
                                                      paginatedList.length,
                                                      (index) => DataRow(cells: [
                                                        DataCell(
                                                          Text("${startIndex + index + 1}"),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            paginatedList[index].designation,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            paginatedList[index].designationDescription,
                                                          ),
                                                        ),

                                                        ///__________action_menu__________________________________________________________
                                                        DataCell(
                                                          Theme(
                                                            data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                            child: PopupMenuButton(
                                                              surfaceTintColor: Colors.white,
                                                              icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (BuildContext bc) => [
                                                                ///_________Edit___________________________________________
                                                                PopupMenuItem(
                                                                  onTap: () async {
                                                                    if (finalUserRoleModel.hrmEdit == false) {
                                                                      EasyLoading.showError(userPermissionErrorText);
                                                                      return;
                                                                    }
                                                                    await showDialog(
                                                                      barrierDismissible: false,
                                                                      context: context,
                                                                      builder: (BuildContext context) {
                                                                        return StatefulBuilder(
                                                                          builder: (context, setStates) {
                                                                            return Dialog(
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(20.0),
                                                                              ),
                                                                              child: AddDesignationScreen(
                                                                                listOfIncomeCategory: designationList,
                                                                                designationModel: paginatedList[index],
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    );
                                                                    GoRouter.of(context).pop();
                                                                    // Navigator.pop(bc);
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(IconlyLight.edit, size: 22.0, color: kSuccessColor),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).edit,
                                                                        style: theme.textTheme.bodyLarge,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),

                                                                ///____________Delete___________________________________________
                                                                PopupMenuItem(
                                                                  onTap: () async {
                                                                    if (finalUserRoleModel.hrmDelete == false) {
                                                                      EasyLoading.showError(userPermissionErrorText);
                                                                      return;
                                                                    }
                                                                    if (await showDeleteConfirmationDialog(context: context, itemName: 'designation')) {
                                                                      bool result = await DesignationRepository().deleteDesignation(id: paginatedList[index].id);
                                                                      if (result) {
                                                                        ref.refresh(designationProvider);
                                                                      }
                                                                    }
                                                                    // Navigator.pop(bc);
                                                                    GoRouter.of(context).pop();
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                       HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 22.0, color: kErrorColor),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).delete,
                                                                        style: theme.textTheme.bodyLarge,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ]),
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
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${lang.S.of(context).showing} ${((_currentPage - 1) * _designationPerPage + 1).toString()} to ${((_currentPage - 1) * _designationPerPage + _designationPerPage).clamp(0, showIncomeCategory.length)} of ${showIncomeCategory.length} entries',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                InkWell(
                                                  overlayColor: WidgetStateProperty.all<Color>(Colors.grey),
                                                  hoverColor: Colors.grey,
                                                  onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: kBorderColorTextField),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomLeft: Radius.circular(4.0),
                                                        topLeft: Radius.circular(4.0),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(lang.S.of(context).previous),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: kBorderColorTextField),
                                                    color: kMainColor,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$_currentPage',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: kBorderColorTextField),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$pages',
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  hoverColor: Colors.blue.withValues(alpha: 0.1),
                                                  overlayColor: WidgetStateProperty.all<Color>(Colors.blue),
                                                  onTap: _currentPage * _designationPerPage < showIncomeCategory.length ? () => setState(() => _currentPage++) : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: kBorderColorTextField),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomRight: Radius.circular(4.0),
                                                        topRight: Radius.circular(4.0),
                                                      ),
                                                    ),
                                                    child: const Center(child: Text('Next')),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                //: const EmptyWidget(title: 'No Data Found'),
                                : EmptyWidget(title: lang.S.of(context).noDataFound),
                          ],
                        ),
                      ),
                    );

                    // return ExpensesTableWidget(expenses: allExpenses);
                  }, error: (e, stack) {
                    return Center(
                      child: Text(e.toString()),
                    );
                  }, loading: () {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
                  // Visibility(visible: MediaQuery.of(context).size.height != 0, child: const Footer()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
