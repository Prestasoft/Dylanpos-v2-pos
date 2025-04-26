import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/user_role_model.dart';

import '../../Provider/user_role_provider.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';
import 'add_user_role_screen.dart';

class UserRoleScreen extends StatefulWidget {
  const UserRoleScreen({super.key});

  static const String route = '/user_role';

  @override
  State<UserRoleScreen> createState() => _UserRoleScreenState();
}

class _UserRoleScreenState extends State<UserRoleScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    // voidLink(context: context);
  }

  int selectedItem = 10;
  int itemCount = 10;
  final _horizontalScroll = ScrollController();
  int _lossProfitPerPage = 10; // Default number of items to display
  int _currentPage = 1;
  String searchItem = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
          backgroundColor: kDarkWhite,
          body: Consumer(builder: (_, ref, watch) {
            final customers = ref.watch(userRoleProvider);
            return customers.when(data: (allCustomerList) {
              List<UserRoleModel> customerList = allCustomerList;
              final pages = (customerList.length / _lossProfitPerPage).ceil();

              // Filter the list based on searchItem
              if (searchItem.isNotEmpty) {
                customerList = customerList.where((user) {
                  return user.userTitle?.toLowerCase().contains(searchItem.toLowerCase()) == true || user.email?.toLowerCase().contains(searchItem.toLowerCase()) == true;
                }).toList();
              }

              final startIndex = (_currentPage - 1) * _lossProfitPerPage;
              final endIndex = _lossProfitPerPage == -1 ? customerList.length : startIndex + _lossProfitPerPage;
              final paginatedList = customerList.sublist(
                startIndex,
                endIndex > customerList.length ? customerList.length : endIndex,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //_______________________________top_bar____________________________
                    // const TopBar(),
                    Container(
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
                                    lang.S.of(context).userRole,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: (() {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return StatefulBuilder(builder: (context, setState1) {
                                          return Dialog(
                                              insetPadding: const EdgeInsets.all(8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.0),
                                              ),
                                              surfaceTintColor: kWhite,
                                              child: SizedBox(
                                                width: 700,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(15.0),
                                                  child: AddUserRole(),
                                                ),
                                              ));
                                        });
                                      },
                                    );
                                  }),
                                  child: Text(
                                    lang.S.of(context).addNewUser,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          const Divider(
                            thickness: 1.0,
                            color: kNeutral300,
                            height: 1,
                          ),
                          const SizedBox(height: 20.0),

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
                                        value: _lossProfitPerPage,
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
                                              _lossProfitPerPage = -1; // Set to -1 for "All"
                                            } else {
                                              _lossProfitPerPage = newValue ?? 10;
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
                                    border: InputBorder.none,
                                    suffixIcon: const Icon(
                                      FeatherIcons.search,
                                      color: kTitleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                          customerList.isNotEmpty
                              ? Column(
                                  children: [
                                    Column(
                                      children: [
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
                                                          DataColumn(label: Text(lang.S.of(context).SL)),
                                                          DataColumn(label: Text(lang.S.of(context).userName)),
                                                          DataColumn(label: Text(lang.S.of(context).userRole)),
                                                          DataColumn(label: Text(lang.S.of(context).email)),
                                                          DataColumn(label: Text(lang.S.of(context).action)),
                                                        ],
                                                        rows: List.generate(paginatedList.length, (index) {
                                                          return DataRow(cells: [
                                                            ///______________S.L__________________________________________________
                                                            DataCell(Text("${startIndex + index + 1}")),

                                                            ///______________Date__________________________________________________
                                                            DataCell(
                                                              Text(
                                                                paginatedList[index].userTitle ?? '',
                                                              ),
                                                            ),

                                                            DataCell(
                                                              Text(
                                                                paginatedList[index].userTitle ?? '',
                                                              ),
                                                            ),

                                                            ///____________Invoice_________________________________________________
                                                            DataCell(
                                                              Text(
                                                                paginatedList[index].email ?? '',
                                                              ),
                                                            ),

                                                            ///______Party Name___________________________________________________________
                                                            DataCell(
                                                              GestureDetector(
                                                                onTap: () {
                                                                  showDialog(
                                                                    barrierDismissible: false,
                                                                    context: context,
                                                                    builder: (BuildContext context) {
                                                                      return StatefulBuilder(builder: (context, setState1) {
                                                                        return Dialog(
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(10.0),
                                                                            ),
                                                                            child: SizedBox(
                                                                              width: 700,
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(10.0),
                                                                                child: AddUserRole(
                                                                                  userRoleModel: paginatedList[index],
                                                                                ),
                                                                              ),
                                                                            ));
                                                                      });
                                                                    },
                                                                  );
                                                                },
                                                                child: Text(
                                                                  '${lang.S.of(context).view} >',
                                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                                    color: kMainColor,
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${lang.S.of(context).showing} ${((_currentPage - 1) * _lossProfitPerPage + 1).toString()} to ${((_currentPage - 1) * _lossProfitPerPage + _lossProfitPerPage).clamp(0, customerList.length)} of ${customerList.length} entries',
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
                                                    onTap: _currentPage * _lossProfitPerPage < customerList.length ? () => setState(() => _currentPage++) : null,
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
                                        // Container(
                                        //   padding: const EdgeInsets.all(15),
                                        //   decoration: BoxDecoration(color: kbgColor),
                                        //   child: Row(
                                        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        //     children: [
                                        //       SizedBox(width: 50, child: Text(lang.S.of(context).SL)),
                                        //       SizedBox(width: 200, child: Text(lang.S.of(context).userName)),
                                        //       SizedBox(width: 200, child: Text(lang.S.of(context).userRole)),
                                        //       SizedBox(width: 200, child: Text(lang.S.of(context).email)),
                                        //       SizedBox(width: 50, child: Text(lang.S.of(context).action)),
                                        //     ],
                                        //   ),
                                        // ),
                                        // SizedBox(
                                        //   height: (MediaQuery.of(context).size.height - 240).isNegative ? 0 : MediaQuery.of(context).size.height - 240,
                                        //   child: ListView.builder(
                                        //     shrinkWrap: true,
                                        //     physics: const AlwaysScrollableScrollPhysics(),
                                        //     itemCount: customerList.length,
                                        //     itemBuilder: (BuildContext context, int index) {
                                        //       return Column(
                                        //         children: [
                                        //           Padding(
                                        //             padding: const EdgeInsets.all(15),
                                        //             child: Row(
                                        //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        //               children: [
                                        //                 ///______________S.L__________________________________________________
                                        //                 SizedBox(
                                        //                   width: 50,
                                        //                   child: Text((index + 1).toString(), style: kTextStyle.copyWith(color: kGreyTextColor)),
                                        //                 ),
                                        //
                                        //                 ///______________Date__________________________________________________
                                        //                 SizedBox(
                                        //                   width: 200,
                                        //                   child: Text(
                                        //                     customerList[index].userTitle ?? '',
                                        //                     maxLines: 2,
                                        //                     overflow: TextOverflow.ellipsis,
                                        //                     style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                        //                   ),
                                        //                 ),
                                        //
                                        //                 SizedBox(
                                        //                   width: 200,
                                        //                   child: Text(
                                        //                     customerList[index].userTitle ?? '',
                                        //                     maxLines: 2,
                                        //                     overflow: TextOverflow.ellipsis,
                                        //                     style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                        //                   ),
                                        //                 ),
                                        //
                                        //                 ///____________Invoice_________________________________________________
                                        //                 SizedBox(
                                        //                   width: 200,
                                        //                   child: Text(customerList[index].email ?? '',
                                        //                       maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kGreyTextColor)),
                                        //                 ),
                                        //
                                        //                 ///______Party Name___________________________________________________________
                                        //                 GestureDetector(
                                        //                   onTap: () {
                                        //                     showDialog(
                                        //                       barrierDismissible: false,
                                        //                       context: context,
                                        //                       builder: (BuildContext context) {
                                        //                         return StatefulBuilder(builder: (context, setState1) {
                                        //                           return Dialog(
                                        //                               shape: RoundedRectangleBorder(
                                        //                                 borderRadius: BorderRadius.circular(10.0),
                                        //                               ),
                                        //                               child: SizedBox(
                                        //                                 width: 700,
                                        //                                 child: AddUserRole(
                                        //                                   userRoleModel: customerList[index],
                                        //                                 ),
                                        //                               ));
                                        //                         });
                                        //                       },
                                        //                     );
                                        //                   },
                                        //                   child: SizedBox(
                                        //                     width: 50,
                                        //                     child: Text(
                                        //                       '${lang.S.of(context).view} >',
                                        //                       style: kTextStyle.copyWith(color: Colors.blue),
                                        //                       maxLines: 2,
                                        //                       overflow: TextOverflow.ellipsis,
                                        //                     ),
                                        //                   ),
                                        //                 ),
                                        //               ],
                                        //             ),
                                        //           ),
                                        //           Container(
                                        //             width: double.infinity,
                                        //             height: 1,
                                        //             color: kGreyTextColor.withOpacity(0.2),
                                        //           )
                                        //         ],
                                        //       );
                                        //     },
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ],
                                )
                              : noDataFoundImage(text: lang.S.of(context).noUserFound),
                        ],
                      ),
                    ),
                  ],
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
          })),
    );
  }
}
