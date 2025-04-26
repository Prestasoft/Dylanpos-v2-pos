import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/Designation/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import 'model/designation_model.dart';

class AddDesignationScreen extends StatefulWidget {
  AddDesignationScreen({super.key, required this.listOfIncomeCategory, this.designationModel});

  final List<DesignationModel> listOfIncomeCategory;
  DesignationModel? designationModel;

  @override
  State<AddDesignationScreen> createState() => _AddDesignationScreenState();
}

class _AddDesignationScreenState extends State<AddDesignationScreen> {
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();

    if (widget.designationModel != null) {
      _designationController.text = widget.designationModel?.designation ?? '';
      _descriptionController.text = widget.designationModel?.designationDescription ?? '';
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _designationController.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    List<String> names = widget.listOfIncomeCategory.map((element) => element.designation.removeAllWhiteSpace().toLowerCase()).toList();

    return Consumer(
      builder: (context, ref, child) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: kWhite,
          ),
          width: 600,
          child: Form(
            key: _formKey,
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
                              widget.designationModel != null ? 'Edit Designation' : lang.S.of(context).addDesignation,
                              // 'Add Designation',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(onPressed: () => GoRouter.of(context).pop(), icon: const Icon(FeatherIcons.x, color: kTitleColor, size: 30.0))
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      height: 1,
                      color: kNeutral300,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _designationController,
                            //label: 'Designation',
                            label: lang.S.of(context).designation,
                            //hint: 'Please enter Designation',
                            hint: lang.S.of(context).pleaseEnterDesignation,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                //return 'Enter Designation Name';
                                return lang.S.of(context).enterDesignationName;
                              }
                              if (widget.designationModel != null ? (names.contains(value.removeAllWhiteSpace().toLowerCase()) && value.removeAllWhiteSpace().toLowerCase() != widget.designationModel!.designation) : (names.contains(value.removeAllWhiteSpace().toLowerCase()))) {
                                //return 'Designation Name Already Exists';
                                return lang.S.of(context).designationNameAlreadyExists;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          _buildTextField(
                            controller: _descriptionController,
                            label: lang.S.of(context).description,
                            hint: lang.S.of(context).addDescription,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                //return 'Enter Description';
                                return lang.S.of(context).enterDescription;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    ResponsiveGridRow(children: [
                      ResponsiveGridCol(
                        xs: screenWidth < 450 ? 12 : 6,
                        md: 6,
                        lg: 6,
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
                        xs: screenWidth < 450 ? 12 : 6,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildButton(
                            label: widget.designationModel != null ? lang.S.of(context).update : lang.S.of(context).saveAndPublish,
                            color: kGreenTextColor,
                            onTap: widget.designationModel != null
                                ? () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      widget.designationModel!.designation = _designationController.text;
                                      widget.designationModel!.designationDescription = _descriptionController.text;

                                      bool result = await DesignationRepository().updateDesignation(designation: widget.designationModel!);

                                      if (result) {
                                        ref.refresh(designationProvider);
                                        GoRouter.of(context).pop();
                                      }
                                    }
                                  }
                                : () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      num id = DateTime.now().millisecondsSinceEpoch;

                                      bool result = await DesignationRepository().addDesignation(
                                        designation: DesignationModel(id: id, designation: _designationController.text.trim(), designationDescription: _descriptionController.text.trim()),
                                      );

                                      if (result) {
                                        ref.refresh(designationProvider);
                                        GoRouter.of(context).pop();
                                      }
                                    }
                                  },
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
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
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(
        label,
      ),
    ).onTap(onTap);
  }
}
