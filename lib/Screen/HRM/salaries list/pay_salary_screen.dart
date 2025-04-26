import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/provider/salary_provider.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/repo/salary_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../employees/model/employee_model.dart';
import 'model/pay_salary_model.dart';

class PaySalaryScreen extends StatefulWidget {
  PaySalaryScreen({
    super.key,
    required this.listOfEmployees,
    this.payedSalary,
    required this.ref,
  });

  final List<EmployeeModel> listOfEmployees;
  PaySalaryModel? payedSalary;
  final WidgetRef ref;

  @override
  State<PaySalaryScreen> createState() => _PaySalaryScreenState();
}

class _PaySalaryScreenState extends State<PaySalaryScreen> {
  List<String> yearList = List.generate(111, (index) => (1990 + index).toString());
  List<String> paymentItem = ['Cash', 'Bank', 'Mobile Pay'];
  String? selectedPaymentOption = 'Cash';

  List<String> monthList = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  final TextEditingController paySalaryController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? selectedYear = DateTime.now().year.toString();
  String? selectedMonth;
  EmployeeModel? selectedEmployee;

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();

    if (widget.payedSalary != null) {
      paySalaryController.text = widget.payedSalary?.paySalary.toString() ?? '';
      notesController.text = widget.payedSalary?.note ?? '';
      selectedMonth = widget.payedSalary?.month;
      selectedYear = widget.payedSalary?.year;
      selectedPaymentOption = widget.payedSalary?.paymentType;
      for (var element in widget.listOfEmployees) {
        if (element.id == widget.payedSalary?.employmentId) {
          setState(() {
            selectedEmployee = element;
          });
          return;
        }
      }
    } else {
      setState(() {
        selectedMonth = monthList[DateTime.now().month - 1];
      });
    }
  }

  @override
  void dispose() {
    paySalaryController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: kWhite,
            ),
            width: 600,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Pay Salary',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(onPressed: () => GoRouter.of(context).pop(), icon: const Icon(FeatherIcons.x, color: kTitleColor, size: 22.0))
                          ],
                        ),
                      ),
                      const Divider(
                        thickness: 1.0,
                        height: 1,
                        color: kNeutral300,
                      ),

                      ///________Employee_and_Salary_______________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          lg: 6,
                          md: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<EmployeeModel>(
                              isExpanded: true,
                              validator: (value) {
                                if (value == null) {
                                  return 'Employee required';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Select Employee',
                              ),
                              value: selectedEmployee,
                              hint: Text(
                                'Select Employee Employee',
                                style: theme.textTheme.bodyLarge,
                              ),
                              items: widget.listOfEmployees
                                  .map(
                                    (items) => DropdownMenuItem(
                                      value: items,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          items.name,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedEmployee = value;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          lg: 6,
                          md: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildTextField(
                              controller: paySalaryController,
                              label: 'Pay Salary Amount',
                              hint: 'Please enter salary amount',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter Pay Salary Amount';
                                }
                                return null;
                              },
                            ),
                          ),
                        )
                      ]),
                      // Row(
                      //   children: [
                      //     DropdownButtonFormField<EmployeeModel>(
                      //       validator: (value) {
                      //         if (value == null) {
                      //           return 'Employee required';
                      //         }
                      //         return null;
                      //       },
                      //       decoration: kInputDecoration.copyWith(
                      //         labelText: 'Select Employee',
                      //         labelStyle: kTextStyle.copyWith(color: kTitleColor),
                      //         hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                      //       ),
                      //       value: selectedEmployee,
                      //       hint: const Text(
                      //         'Select Employee Employee',
                      //         style: TextStyle(color: Colors.black54, fontSize: 16),
                      //       ),
                      //       items: widget.listOfEmployees
                      //           .map(
                      //             (items) => DropdownMenuItem(
                      //               value: items,
                      //               child: Text(items.name),
                      //             ),
                      //           )
                      //           .toList(),
                      //       onChanged: (value) {
                      //         setState(() {
                      //           selectedEmployee = value;
                      //         });
                      //       },
                      //       icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      //       dropdownColor: Colors.white,
                      //       style: const TextStyle(color: Colors.black, fontSize: 16),
                      //     ),
                      //     const SizedBox(width: 20.0),
                      //     _buildTextField(
                      //       controller: paySalaryController,
                      //       label: 'Pay Salary Amount',
                      //       width: 270,
                      //       hint: 'Please enter salary amount',
                      //       validator: (value) {
                      //         if (value == null || value.trim().isEmpty) {
                      //           return 'Enter Pay Salary Amount';
                      //         }
                      //         return null;
                      //       },
                      //     ),
                      //   ],
                      // ),
                      ///________Year_and_Months_________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<String>(
                              // isExpanded: true,
                              validator: (value) {
                                if (value == null) {
                                  return 'Year required';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Select Year',
                              ),
                              value: selectedYear,
                              hint: Text(
                                'Select Year',
                                style: theme.textTheme.bodyLarge,
                              ),
                              items: yearList
                                  .map(
                                    (year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedYear = value!;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: DropdownButtonFormField<String>(
                              // isExpanded: true,
                              validator: (value) {
                                if (value == null) {
                                  return 'Month required';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Select Month',
                              ),
                              value: selectedMonth,
                              hint: Text(
                                'Select Month',
                                style: theme.textTheme.bodyLarge,
                              ),
                              items: monthList
                                  .map(
                                    (month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(
                                        month,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedMonth = value!;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        )
                      ]),

                      ///____________Payment Type_and_designation________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<String>(
                              // isExpanded: true,
                              validator: (value) {
                                if (value == null) {
                                  return 'Month required';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Select Month',
                              ),
                              value: selectedPaymentOption,
                              hint: Text(
                                'Select Month',
                                style: theme.textTheme.bodyLarge,
                              ),
                              items: paymentItem
                                  .map(
                                    (month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(
                                        month,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentOption = value!;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _buildTextField(
                              controller: notesController,
                              label: 'Note',
                              hint: 'Please enter notes',
                              validator: (value) {
                                return null;
                              },
                            ),
                          ),
                        )
                      ]),
                      // Row(
                      //   children: [
                      //     SizedBox(
                      //       width: 270,
                      //       child: DropdownButtonFormField<String>(
                      //         validator: (value) {
                      //           if (value == null) {
                      //             return 'Month required';
                      //           }
                      //           return null;
                      //         },
                      //         decoration: kInputDecoration.copyWith(
                      //           labelText: 'Select Month',
                      //           labelStyle: kTextStyle.copyWith(color: kTitleColor),
                      //           hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                      //         ),
                      //         value: selectedPaymentOption,
                      //         hint: const Text(
                      //           'Select Month',
                      //           style: TextStyle(color: Colors.black54, fontSize: 16),
                      //         ),
                      //         items: paymentItem
                      //             .map(
                      //               (month) => DropdownMenuItem(
                      //                 value: month,
                      //                 child: Text(month),
                      //               ),
                      //             )
                      //             .toList(),
                      //         onChanged: (value) {
                      //           setState(() {
                      //             selectedPaymentOption = value!;
                      //           });
                      //         },
                      //         icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      //         dropdownColor: Colors.white,
                      //         style: const TextStyle(color: Colors.black, fontSize: 16),
                      //       ),
                      //     ),
                      //     const SizedBox(width: 20),
                      //     _buildTextField(
                      //       controller: notesController,
                      //       label: 'Note',
                      //       hint: 'Please enter notes',
                      //       validator: (value) {
                      //         return null;
                      //       },
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 20.0),

                      ///___________Buttons___________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildButton(
                              label: lang.S.of(context).cancel,
                              color: Colors.red,
                              onTap: () => GoRouter.of(context).pop(),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildButton(
                              label: lang.S.of(context).saveAndPublish,
                              color: kGreenTextColor,
                              onTap: widget.payedSalary != null
                                  ? () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        final data = PaySalaryModel(
                                          id: widget.payedSalary!.id,
                                          designation: selectedEmployee?.designation ?? '',
                                          designationId: selectedEmployee?.designationId ?? 0,
                                          employeeName: selectedEmployee?.name ?? '',
                                          employmentId: selectedEmployee?.id ?? 0,
                                          month: selectedMonth ?? '',
                                          year: selectedYear ?? '',
                                          netSalary: selectedEmployee?.salary ?? 0,
                                          paySalary: num.tryParse(paySalaryController.text) ?? 0,
                                          payingDate: DateTime.now(),
                                          paymentType: selectedPaymentOption ?? '',
                                          note: notesController.text,
                                        );

                                        bool result = await SalaryRepository().updateSalary(salary: data);

                                        if (result) {
                                          ref.refresh(salaryProvider);
                                          // context.pop();
                                          GoRouter.of(context).pop();
                                        }
                                      }
                                    }
                                  : () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        num id = DateTime.now().millisecondsSinceEpoch;

                                        bool result = await SalaryRepository().paySalary(
                                          salary: PaySalaryModel(
                                            id: id,
                                            designation: selectedEmployee?.designation ?? '',
                                            designationId: selectedEmployee?.designationId ?? 0,
                                            employeeName: selectedEmployee?.name ?? '',
                                            employmentId: selectedEmployee?.id ?? 0,
                                            month: selectedMonth ?? '',
                                            year: selectedYear ?? '',
                                            netSalary: selectedEmployee?.salary ?? 0,
                                            paySalary: num.tryParse(paySalaryController.text ?? '0') ?? 0,
                                            payingDate: DateTime.now(),
                                            paymentType: selectedPaymentOption ?? '',
                                            note: notesController.text,
                                          ),
                                        );

                                        if (result) {
                                          ref.refresh(salaryProvider);
                                          GoRouter.of(context).pop();
                                          // context.pop();
                                        }
                                      }
                                    },
                            ),
                          ),
                        )
                      ]),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     _buildButton(
                      //       label: lang.S.of(context).cancel,
                      //       color: Colors.red,
                      //       onTap: () => Navigator.pop(context),
                      //     ),
                      //     const SizedBox(width: 20),
                      //     _buildButton(
                      //       label: lang.S.of(context).saveAndPublish,
                      //       color: kGreenTextColor,
                      //       onTap: widget.payedSalary != null
                      //           ? () async {
                      //               if (formKey.currentState?.validate() ?? false) {
                      //                 final data = PaySalaryModel(
                      //                   id: widget.payedSalary!.id,
                      //                   designation: selectedEmployee?.designation ?? '',
                      //                   designationId: selectedEmployee?.designationId ?? 0,
                      //                   employeeName: selectedEmployee?.name ?? '',
                      //                   employmentId: selectedEmployee?.id ?? 0,
                      //                   month: selectedMonth ?? '',
                      //                   year: selectedYear ?? '',
                      //                   netSalary: selectedEmployee?.salary ?? 0,
                      //                   paySalary: num.tryParse(paySalaryController.text) ?? 0,
                      //                   payingDate: DateTime.now(),
                      //                   paymentType: selectedPaymentOption ?? '',
                      //                   note: notesController.text,
                      //                 );
                      //
                      //                 bool result = await SalaryRepository().updateSalary(salary: data);
                      //
                      //                 if (result) {
                      //                   ref.refresh(salaryProvider);
                      //                   // context.pop();
                      //                   GoRouter.of(context).pop();
                      //                 }
                      //               }
                      //             }
                      //           : () async {
                      //               if (formKey.currentState?.validate() ?? false) {
                      //                 num id = DateTime.now().millisecondsSinceEpoch;
                      //
                      //                 bool result = await SalaryRepository().paySalary(
                      //                   salary: PaySalaryModel(
                      //                     id: id,
                      //                     designation: selectedEmployee?.designation ?? '',
                      //                     designationId: selectedEmployee?.designationId ?? 0,
                      //                     employeeName: selectedEmployee?.name ?? '',
                      //                     employmentId: selectedEmployee?.id ?? 0,
                      //                     month: selectedMonth ?? '',
                      //                     year: selectedYear ?? '',
                      //                     netSalary: selectedEmployee?.salary ?? 0,
                      //                     paySalary: num.tryParse(paySalaryController.text ?? '0') ?? 0,
                      //                     payingDate: DateTime.now(),
                      //                     paymentType: selectedPaymentOption ?? '',
                      //                     note: notesController.text,
                      //                   ),
                      //                 );
                      //
                      //                 if (result) {
                      //                   ref.refresh(salaryProvider);
                      //                   GoRouter.of(context).pop();
                      //                   // context.pop();
                      //                 }
                      //               }
                      //             },
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      showCursor: true,
      cursorColor: kTitleColor,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Widget _buildButton({required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
      ),
      onPressed: onTap,
      child: Text(
        label,
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onChanged,
  }) {
    return SizedBox(
      width: 270,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              label,
              style: kTextStyle.copyWith(color: kTitleColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                onChanged(pickedDate);
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: kTextStyle.copyWith(color: kGreenTextColor),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
