import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../../Widgets/Constant Data/export_button.dart';
import '../widgets/deleteing_alart_dialog.dart';
import 'add_employee.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  // static const String route = '/HRM/employee_List';

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  String searchItem = '';

  ScrollController mainScroll = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _salaryPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final employee = ref.watch(employeeProvider);
          return Scaffold(
            backgroundColor: kDarkWhite,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_______________________________top_bar____________________________

                  employee.when(data: (designationList) {
                    List<EmployeeModel> reverseAllIncomeCategory = designationList.reversed.toList();
                    List<EmployeeModel> showIncomeCategory = [];
                    for (var element in reverseAllIncomeCategory) {
                      if (searchItem != '' && (element.name.toLowerCase().contains(searchItem.toLowerCase()) || element.designation.toLowerCase().contains(searchItem.toLowerCase()))) {
                        showIncomeCategory.add(element);
                      } else if (searchItem == '') {
                        showIncomeCategory.add(element);
                      }
                    }
                    final pages = (showIncomeCategory.length / _salaryPerPage).ceil();

                    final startIndex = (_currentPage - 1) * _salaryPerPage;
                    final endIndex = _salaryPerPage == -1 ? showIncomeCategory.length : startIndex + _salaryPerPage;
                    final paginatedList = showIncomeCategory.sublist(
                      startIndex,
                      endIndex > showIncomeCategory.length ? showIncomeCategory.length : endIndex,
                    );

                    return Container(
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
                                    'Empleado',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                ElevatedButton(
                                    onPressed: () async {
                                      if (finalUserRoleModel.hrmEdit == false) {
                                        EasyLoading.showError(userPermissionErrorText);
                                        return;
                                      }
                                      final data = await DesignationRepository().getAllDesignation();
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                            builder: (context, setStates) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                                child: AddEmployeeScreen(
                                                  listOfEmployees: designationList,
                                                  ref: ref,
                                                  designations: data,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('Agregar Empleado')),
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
                                        'Mostrar-',
                                        style: theme.textTheme.bodyLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DropdownButton<int>(
                                        isDense: true,
                                        padding: EdgeInsets.zero,
                                        underline: const SizedBox(),
                                        value: _salaryPerPage,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.black,
                                        ),
                                        items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text(
                                              value == -1 ? "Todos" : value.toString(),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (int? newValue) {
                                          setState(() {
                                            if (newValue == -1) {
                                              _salaryPerPage = -1; // Set to -1 for "All"
                                            } else {
                                              _salaryPerPage = newValue ?? 10;
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
                                                    const DataColumn(
                                                      label: Text(
                                                        'S.L',
                                                      ),
                                                    ),
                                                    const DataColumn(
                                                      label: Text(
                                                        'Nombre',
                                                      ),
                                                    ),
                                                    const DataColumn(
                                                      label: Text(
                                                        'Teléfono',
                                                      ),
                                                    ),
                                                    const DataColumn(
                                                      label: Text(
                                                        'Designación',
                                                      ),
                                                    ),
                                                    const DataColumn(
                                                      label: Text(
                                                        'Salario',
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        lang.S.of(context).action,
                                                      ),
                                                    ),
                                                  ],
                                                  rows: List.generate(
                                                    showIncomeCategory.length,
                                                    (index) => DataRow(cells: [
                                                      DataCell(
                                                        Text((index + 1).toString()),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          showIncomeCategory[index].name,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          showIncomeCategory[index].phoneNumber,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          showIncomeCategory[index].designation,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          showIncomeCategory[index].salary.toStringAsFixed(2),
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
                                                                child: GestureDetector(
                                                                  onTap: () async {
                                                                    if (finalUserRoleModel.hrmEdit == false) {
                                                                      EasyLoading.showError(userPermissionErrorText);
                                                                      return;
                                                                    }
                                                                    final data = await DesignationRepository().getAllDesignation();
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
                                                                              child: AddEmployeeScreen(
                                                                                listOfEmployees: designationList,
                                                                                employeeModel: showIncomeCategory[index],
                                                                                designations: data,
                                                                                ref: ref,
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
                                                              ),

                                                              ///____________Delete___________________________________________
                                                              PopupMenuItem(
                                                                child: GestureDetector(
                                                                  onTap: () async {
                                                                    if (finalUserRoleModel.hrmDelete == false) {
                                                                      EasyLoading.showError(userPermissionErrorText);
                                                                      return;
                                                                    }
                                                                    if (await showDeleteConfirmationDialog(context: context, itemName: 'employee')) {
                                                                      bool result = await EmployeeRepository().deleteEmployee(id: showIncomeCategory[index].id);
                                                                      if (result) {
                                                                        ref.refresh(employeeProvider);
                                                                      }
                                                                    }
                                                                    // Navigator.pop(bc);
                                                                    GoRouter.of(context).pop();
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 22.0, color: kErrorColor),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).delete,
                                                                        style: theme.textTheme.bodyLarge,
                                                                      ),
                                                                    ],
                                                                  ),
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
                                              '${lang.S.of(context).showing} ${((_currentPage - 1) * _salaryPerPage + 1).toString()} to ${((_currentPage - 1) * _salaryPerPage + _salaryPerPage).clamp(0, showIncomeCategory.length)} of ${showIncomeCategory.length} entries',
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
                                                onTap: _currentPage * _salaryPerPage < showIncomeCategory.length ? () => setState(() => _currentPage++) : null,
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
                                                  child: const Center(child: Text('Siguiente')),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const EmptyWidget(title: 'No se encontraron datos'),
                        ],
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
