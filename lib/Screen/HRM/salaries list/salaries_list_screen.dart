import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:hugeicons/hugeicons.dart'; // Eliminado
import 'package:iconly/iconly.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/employees/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/nomina_completa_screen.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/provider/salary_provider.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/repo/salary_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../../Widgets/Constant Data/export_button.dart';
import '../widgets/deleteing_alart_dialog.dart';

class SalariesListScreen extends StatefulWidget {
  const SalariesListScreen({super.key});

  // static const String route = '/HRM/salaries_List';

  @override
  State<SalariesListScreen> createState() => _SalariesListScreenState();
}

class _SalariesListScreenState extends State<SalariesListScreen> {
  String searchItem = '';

  ScrollController mainScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  final _horizontalScroll = ScrollController();
  int _salaryPerPage = 10;
  int _currentPage = 1;

  Widget _buildQuickAccessButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final employee = ref.watch(employeeProvider);
          final salary = ref.watch(salaryProvider);
          return Scaffold(
            backgroundColor: kDarkWhite,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //_______________________________top_bar____________________________
                  // const TopBar(),

                  salary.when(data: (employeeList) {
                    List<PaySalaryModel> reverseAllIncomeCategory =
                        employeeList.reversed.toList();
                    List<PaySalaryModel> showIncomeCategory = [];
                    for (var element in reverseAllIncomeCategory) {
                      if (searchItem != '' &&
                          (element.employeeName
                                  .toLowerCase()
                                  .contains(searchItem.toLowerCase()) ||
                              element.designation
                                  .toLowerCase()
                                  .contains(searchItem.toLowerCase()))) {
                        showIncomeCategory.add(element);
                      } else if (searchItem == '') {
                        showIncomeCategory.add(element);
                      }
                    }
                    final pages =
                        (showIncomeCategory.length / _salaryPerPage).ceil();

                    final startIndex = (_currentPage - 1) * _salaryPerPage;
                    final endIndex = _salaryPerPage == -1
                        ? showIncomeCategory.length
                        : startIndex + _salaryPerPage;
                    final paginatedList = showIncomeCategory.sublist(
                      startIndex,
                      endIndex > showIncomeCategory.length
                          ? showIncomeCategory.length
                          : endIndex,
                    );
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            color: kWhite),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Gestión de Nómina',
                                          style:
                                              theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      employee.when(
                                        data: (employees) {
                                          return ElevatedButton.icon(
                                            onPressed: () {
                                              if (!checkUserRoleEditPermissionV2(type: 'hrm')) {
                                                EasyLoading.showError(
                                                    userPermissionErrorText);
                                                return;
                                              }
                                              showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return NominaCompletaScreen(
                                                    ref: ref,
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(FeatherIcons.plus,
                                                color: kWhite, size: 20.0),
                                            label: Text(
                                              'Pagar Nómina',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                        error: (error, stackTrace) {
                                          return const Center(
                                            child: Text('An Error accused'),
                                          );
                                        },
                                        loading: () {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Botones de acceso rápido
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildQuickAccessButton(
                                          context: context,
                                          icon: Icons.beach_access,
                                          label: 'Vacaciones y Licencias',
                                          color: Colors.blue,
                                          onTap: () => GoRouter.of(context).push('/hrm/vacations'),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildQuickAccessButton(
                                          context: context,
                                          icon: Icons.gavel,
                                          label: 'Calcular Prestaciones',
                                          color: Colors.orange,
                                          onTap: () => GoRouter.of(context).push('/hrm/prestaciones'),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildQuickAccessButton(
                                          context: context,
                                          icon: Icons.account_balance_wallet,
                                          label: 'Préstamos',
                                          color: Colors.purple,
                                          onTap: () => GoRouter.of(context).push('/hrm/loans'),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildQuickAccessButton(
                                          context: context,
                                          icon: Icons.fingerprint,
                                          label: 'Asistencia',
                                          color: Colors.teal,
                                          onTap: () => GoRouter.of(context).push('/hrm/attendance'),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildQuickAccessButton(
                                          context: context,
                                          icon: Icons.assessment,
                                          label: 'Reportes TSS',
                                          color: Colors.indigo,
                                          onTap: () => GoRouter.of(context).push('/hrm/tss-reports'),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          value: _salaryPerPage,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.black,
                                          ),
                                          items: [10, 20, 50, 100, -1]
                                              .map<DropdownMenuItem<int>>(
                                                  (int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(
                                                value == -1
                                                    ? "All"
                                                    : value.toString(),
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              if (newValue == -1) {
                                                _salaryPerPage =
                                                    -1; // Set to -1 for "All"
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
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      hintText:
                                          (lang.S.of(context).searchByName),
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
                                        builder: (BuildContext context,
                                            BoxConstraints constraints) {
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
                                                  minWidth:
                                                      constraints.maxWidth,
                                                ),
                                                child: Theme(
                                                  data: theme.copyWith(
                                                      dividerTheme:
                                                          const DividerThemeData(
                                                              color: Colors
                                                                  .transparent)),
                                                  child: DataTable(
                                                    border: const TableBorder(
                                                      horizontalInside:
                                                          BorderSide(
                                                        width: 1,
                                                        color: kNeutral300,
                                                      ),
                                                    ),
                                                    dataRowColor:
                                                        const WidgetStatePropertyAll(
                                                            Colors.white),
                                                    headingRowColor:
                                                        WidgetStateProperty.all(
                                                            const Color(
                                                                0xFFF8F3FF)),
                                                    showBottomBorder: false,
                                                    dividerThickness: 0.0,
                                                    headingTextStyle: theme
                                                        .textTheme.titleMedium,
                                                    columns: [
                                                      const DataColumn(
                                                        label: Text('#'),
                                                      ),
                                                      const DataColumn(
                                                        label: Text('Empleado'),
                                                      ),
                                                      const DataColumn(
                                                        label: Text('Período'),
                                                      ),
                                                      const DataColumn(
                                                        label: Text('Salario Bruto'),
                                                      ),
                                                      const DataColumn(
                                                        label: Text('Deducciones'),
                                                      ),
                                                      const DataColumn(
                                                        label: Text('Salario Neto'),
                                                      ),
                                                      const DataColumn(
                                                        label: Text('Estado'),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          lang.S.of(context).action,
                                                        ),
                                                      ),
                                                    ],
                                                    rows: List.generate(
                                                      paginatedList.length,
                                                      (index) {
                                                        final salary = paginatedList[index];
                                                        final monthNames = {
                                                          '01': 'Ene', '02': 'Feb', '03': 'Mar', '04': 'Abr',
                                                          '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Ago',
                                                          '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dic',
                                                          'Enero': 'Ene', 'Febrero': 'Feb', 'Marzo': 'Mar', 'Abril': 'Abr',
                                                          'Mayo': 'May', 'Junio': 'Jun', 'Julio': 'Jul', 'Agosto': 'Ago',
                                                          'Septiembre': 'Sep', 'Octubre': 'Oct', 'Noviembre': 'Nov', 'Diciembre': 'Dic',
                                                        };
                                                        final monthDisplay = monthNames[salary.month] ?? salary.month;
                                                        final fortnightText = salary.fortnight != null ? ' Q${salary.fortnight}' : '';
                                                        return DataRow(
                                                          cells: [
                                                            DataCell(
                                                              Text("${startIndex + index + 1}"),
                                                            ),
                                                            DataCell(
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Text(
                                                                    salary.employeeName,
                                                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                                                  ),
                                                                  Text(
                                                                    salary.designation,
                                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text('$monthDisplay ${salary.year}$fortnightText'),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                'RD\$ ${salary.grossSalary.toStringAsFixed(2)}',
                                                                style: const TextStyle(color: Colors.green),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                'RD\$ ${salary.totalDeductions.toStringAsFixed(2)}',
                                                                style: const TextStyle(color: Colors.red),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                'RD\$ ${salary.netSalary.toStringAsFixed(2)}',
                                                                style: const TextStyle(fontWeight: FontWeight.bold, color: kMainColor),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: salary.status == 'Pagado' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: Text(
                                                                  salary.status,
                                                                  style: TextStyle(
                                                                    color: salary.status == 'Pagado' ? Colors.green : Colors.orange,
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            ///__________action_menu__________________________________________________________
                                                            DataCell(
                                                              Theme(
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
                                                                      Colors
                                                                          .white,
                                                                  icon: const Icon(
                                                                      FeatherIcons
                                                                          .moreVertical,
                                                                      size:
                                                                          18.0),
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                              bc) =>
                                                                          [
                                                                    ///_________Edit___________________________________________
                                                                    PopupMenuItem(
                                                                      onTap:
                                                                          () async {
                                                                        if (!checkUserRoleEditPermissionV2(type: 'hrm')) {
                                                                          EasyLoading.showError(
                                                                              userPermissionErrorText);
                                                                          return;
                                                                        }
                                                                        await showDialog(
                                                                          barrierDismissible: false,
                                                                          context: context,
                                                                          builder: (BuildContext context) {
                                                                            return NominaCompletaScreen(
                                                                              payedSalary: salary,
                                                                              ref: ref,
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          const Icon(
                                                                              IconlyLight.edit,
                                                                              size: 22.0,
                                                                              color: kSuccessColor),
                                                                          const SizedBox(
                                                                              width: 4.0),
                                                                          Text(
                                                                            lang.S.of(context).edit,
                                                                            style:
                                                                                theme.textTheme.bodyLarge,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),

                                                                    ///____________Delete___________________________________________
                                                                    PopupMenuItem(
                                                                      onTap:
                                                                          () async {
                                                                        if (!checkUserRoleDeletePermissionV2(type: 'hrm')) {
                                                                          EasyLoading.showError(
                                                                              userPermissionErrorText);
                                                                          return;
                                                                        }
                                                                        if (await showDeleteConfirmationDialog(
                                                                            context:
                                                                                context,
                                                                            itemName:
                                                                                'salary')) {
                                                                          bool
                                                                              result =
                                                                              await SalaryRepository().deletePaidSalary(id: paginatedList[index].id);
                                                                          if (result) {
                                                                            // ignore: unused_result
                                                                            ref.refresh(salaryProvider);
                                                                          }
                                                                        }
                                                                        // Navigator.pop(bc);
                                                                        GoRouter.of(context)
                                                                            .pop();
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Icon(
                                                                              Icons.delete_outline,
                                                                              size: 22.0,
                                                                              color: kErrorColor),
                                                                          const SizedBox(
                                                                              width: 4.0),
                                                                          Text(
                                                                            lang.S.of(context).delete,
                                                                            style:
                                                                                theme.textTheme.bodyLarge,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
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
                                                '${lang.S.of(context).showing} ${((_currentPage - 1) * _salaryPerPage + 1).toString()} to ${((_currentPage - 1) * _salaryPerPage + _salaryPerPage).clamp(0, showIncomeCategory.length)} of ${showIncomeCategory.length} entries',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                InkWell(
                                                  overlayColor:
                                                      WidgetStateProperty.all<
                                                          Color>(Colors.grey),
                                                  hoverColor: Colors.grey,
                                                  onTap: _currentPage > 1
                                                      ? () => setState(
                                                          () => _currentPage--)
                                                      : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                4.0),
                                                        topLeft:
                                                            Radius.circular(
                                                                4.0),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(lang.S
                                                          .of(context)
                                                          .previous),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            kBorderColorTextField),
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
                                                        color:
                                                            kBorderColorTextField),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$pages',
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  hoverColor: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  overlayColor:
                                                      WidgetStateProperty.all<
                                                          Color>(Colors.blue),
                                                  onTap: _currentPage *
                                                              _salaryPerPage <
                                                          showIncomeCategory
                                                              .length
                                                      ? () => setState(
                                                          () => _currentPage++)
                                                      : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        bottomRight:
                                                            Radius.circular(
                                                                4.0),
                                                        topRight:
                                                            Radius.circular(
                                                                4.0),
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
                                : const EmptyWidget(title: 'No Data Found'),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
