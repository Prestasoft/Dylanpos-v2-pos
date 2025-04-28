import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/employees/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../Designation/model/designation_model.dart';
import 'model/employee_model.dart';

class AddEmployeeScreen extends StatefulWidget {
  AddEmployeeScreen({super.key, required this.listOfEmployees, this.employeeModel, required this.ref, required this.designations});

  final List<EmployeeModel> listOfEmployees;
  EmployeeModel? employeeModel;
  final List<DesignationModel> designations;
  final WidgetRef ref;

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final List<String> genderList = ['Male', 'Female', 'Other'];
  final List<String> typeList = ['Full time', 'Part time', 'Other'];
  String? selectedGender;
  String? selectedType;
  DesignationModel? selectedDesignation;

  DateTime birthDate = DateTime.now();
  DateTime joiningDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();

    if (widget.employeeModel != null) {
      nameController.text = widget.employeeModel?.name ?? '';
      phoneNumberController.text = widget.employeeModel?.phoneNumber ?? '';
      emailController.text = widget.employeeModel?.email ?? '';
      addressController.text = widget.employeeModel?.address ?? '';
      salaryController.text = widget.employeeModel?.salary.toString() ?? '';
      birthDate = widget.employeeModel?.birthDate ?? DateTime.now();
      joiningDate = widget.employeeModel?.joiningDate ?? DateTime.now();
      selectedGender = widget.employeeModel?.gender;
      selectedType = widget.employeeModel?.employmentType;

      for (var element in widget.designations) {
        if (element.id == widget.employeeModel?.designationId) {
          setState(() {
            selectedDesignation = element;
          });
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    addressController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                widget.employeeModel != null ? 'Editar Empleado' : 'Agregar Empleado',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(onPressed: () => GoRouter.of(context).pop(), icon: const Icon(FeatherIcons.x, color: kTitleColor, size: 22.0))
                          ],
                        ),
                      ),
                      const Divider(
                        thickness: 1,
                        color: kNeutral300,
                        height: 1,
                      ),
                      const SizedBox(height: 10),

                      ///________Name and phone_________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildTextField(
                              controller: nameController,
                              label: 'Nombre',
                              hint: 'Por favor ingrese el nombre del empleado',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el nombre del empleado';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildTextField(
                              controller: phoneNumberController,
                              label: 'Número de Teléfono',
                              hint: 'Por favor ingrese el número de teléfono',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el número de teléfono';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ]),
                      // Row(
                      //   children: [
                      //     _buildTextField(
                      //       controller: nameController,
                      //       label: 'Name',
                      //       width: 270,
                      //       hint: 'Please enter Employee Name',
                      //       validator: (value) {
                      //         if (value == null || value.trim().isEmpty) {
                      //           return 'Enter Employee Name';
                      //         }
                      //         return null;
                      //       },
                      //     ),
                      //     const SizedBox(width: 20.0),
                      //     _buildTextField(
                      //       controller: phoneNumberController,
                      //       label: 'Phone Number',
                      //       width: 270,
                      //       hint: 'Please enter Phone Number',
                      //       validator: (value) {
                      //         if (value == null || value.trim().isEmpty) {
                      //           return 'Enter Phone Number';
                      //         }
                      //         return null;
                      //       },
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 20.0),

                      ///________Email_and_address_________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildTextField(
                              controller: emailController,
                              label: 'Correo Electrónico',
                              hint: 'Por favor ingrese el correo electrónico',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el correo electrónico';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildTextField(
                              controller: addressController,
                              label: 'Dirección',
                              hint: 'Por favor ingrese la dirección',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese la dirección';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ]),

                      ///________gender_and_type____________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<String>(
                              validator: (value) {
                                if (value == null) {
                                  return 'Género requerido';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Género',
                              ),
                              value: selectedGender,
                              isExpanded: true,
                              hint: Text(
                                'Seleccione Género',
                                style: theme.textTheme.titleMedium,
                              ),
                              items: genderList
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(gender)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              validator: (value) {
                                if (value == null) {
                                  return 'Tipo de empleado requerido';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Empleado',
                              ),
                              value: selectedType,
                              hint: Text(
                                'Seleccione Tipo de Empleado',
                                style: theme.textTheme.titleMedium,
                              ),
                              items: typeList
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(gender)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                        )
                      ]),

                      ///____________Salary_and_designation________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          lg: 6,
                          md: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildTextField(
                              controller: salaryController,
                              label: 'Salario',
                              hint: 'Por favor ingrese el salario',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese el salario';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          lg: 6,
                          md: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropdownButtonFormField<DesignationModel>(
                              isExpanded: true,
                              validator: (value) {
                                if (value == null) {
                                  return 'Designaciones requeridas';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Designaciones',
                              ),
                              value: selectedDesignation,
                              hint: Text(
                                'Seleccione la designación del empleado',
                                style: theme.textTheme.titleMedium,
                              ),
                              items: widget.designations!
                                  .map(
                                    (items) => DropdownMenuItem(
                                      value: items,
                                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(items.designation)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDesignation = value;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              dropdownColor: Colors.white,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ]),

                      ///____________dates________________________
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildDatePickerField(
                              context: context,
                              label: 'Fecha de Nacimiento',
                              selectedDate: birthDate,
                              onChanged: (value) => setState(() => birthDate = value),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          md: 6,
                          lg: 6,
                          xs: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildDatePickerField(
                              context: context,
                              label: 'Fecha de Ingreso',
                              selectedDate: joiningDate,
                              onChanged: (value) => setState(() => joiningDate = value),
                            ),
                          ),
                        ),
                      ]),

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
                              label: widget.employeeModel != null ? lang.S.of(context).update : lang.S.of(context).saveAndPublish,
                              color: kGreenTextColor,
                              onTap: widget.employeeModel != null
                                  ? () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        EmployeeModel data = EmployeeModel(
                                          id: widget.employeeModel!.id,
                                          name: nameController.text,
                                          phoneNumber: phoneNumberController.text,
                                          email: emailController.text,
                                          address: addressController.text,
                                          gender: selectedGender ?? '',
                                          employmentType: selectedType ?? '',
                                          designationId: selectedDesignation!.id,
                                          designation: selectedDesignation!.designation,
                                          birthDate: birthDate,
                                          joiningDate: joiningDate,
                                          salary: double.parse(salaryController.text),
                                        );

                                        bool result = await EmployeeRepository().updateEmployee(employee: data);

                                        if (result) {
                                          ref.refresh(employeeProvider);
                                          GoRouter.of(context).pop();
                                        }
                                      }
                                    }
                                  : () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        num id = DateTime.now().millisecondsSinceEpoch;

                                        bool result = await EmployeeRepository().addEmployee(
                                          employee: EmployeeModel(
                                            id: id,
                                            name: nameController.text.trim(),
                                            phoneNumber: phoneNumberController.text.trim(),
                                            email: emailController.text.trim(),
                                            address: addressController.text.trim(),
                                            salary: double.parse(salaryController.text.trim()),
                                            birthDate: birthDate,
                                            joiningDate: joiningDate,
                                            gender: selectedGender!,
                                            employmentType: selectedType!,
                                            designation: selectedDesignation!.designation,
                                            designationId: selectedDesignation!.id,
                                          ),
                                        );

                                        if (result) {
                                          ref.refresh(employeeProvider);
                                          GoRouter.of(context).pop();
                                        }
                                      }
                                    },
                            ),
                          ),
                        )
                      ]),
                      const SizedBox(height: 10),
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
    return Wrap(
      spacing: 8, // Add spacing between elements
      runSpacing: 8, // Add spacing when elements wrap
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        GestureDetector(
          onTap: () async {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              const Icon(
                IconlyLight.calendar,
                color: kNeutral500,
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
