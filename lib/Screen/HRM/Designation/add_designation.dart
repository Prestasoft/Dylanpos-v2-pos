import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/user_role_provider.dart';
import 'package:salespro_admin/Screen/HRM/Designation/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/user_role_model.dart';

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import 'model/designation_model.dart';

class AddDesignationScreen extends StatefulWidget {
  AddDesignationScreen(
      {super.key, required this.listOfIncomeCategory, this.designationModel});

  final List<DesignationModel> listOfIncomeCategory;
  final DesignationModel? designationModel;

  @override
  State<AddDesignationScreen> createState() => _AddDesignationScreenState();
}

class _AddDesignationScreenState extends State<AddDesignationScreen> {
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _slaDaysController = TextEditingController(text: '1');
  final TextEditingController _slaHoursController = TextEditingController(text: '0');
  final TextEditingController _slaMinutesController = TextEditingController(text: '0');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedManagerUserId;
  String _selectedColor = '#EC4899';

  // Paleta predefinida de colores por departamento
  static const List<String> _colorPalette = [
    '#EC4899', // pink (default RRHH)
    '#C62828', // red
    '#F59E0B', // amber
    '#10B981', // emerald
    '#3B82F6', // blue
    '#8B5CF6', // violet
    '#14B8A6', // teal
    '#F97316', // orange
    '#6366F1', // indigo
    '#0EA5E9', // sky
  ];

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();

    if (widget.designationModel != null) {
      _designationController.text = widget.designationModel?.designation ?? '';
      _descriptionController.text =
          widget.designationModel?.designationDescription ?? '';
      _slaDaysController.text = widget.designationModel!.slaDays.toString();
      _slaHoursController.text = widget.designationModel!.slaHours.toString();
      _slaMinutesController.text = widget.designationModel!.slaMinutes.toString();
      _selectedManagerUserId = widget.designationModel!.managerUserId;
      _selectedColor = widget.designationModel!.colorHex;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _designationController.dispose();
    _descriptionController.dispose();
    _slaDaysController.dispose();
    _slaHoursController.dispose();
    _slaMinutesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    List<String> names = widget.listOfIncomeCategory
        .map((element) =>
            element.designation.removeAllWhiteSpace().toLowerCase())
        .toList();

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.designationModel != null
                                ? 'Edit Designation'
                                : lang.S.of(context).addDesignation,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                            onPressed: () => GoRouter.of(context).pop(),
                            icon: const Icon(FeatherIcons.x,
                                color: kTitleColor, size: 30.0))
                      ],
                    ),
                  ),
                  const Divider(thickness: 1, height: 1, color: kNeutral300),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _designationController,
                          label: lang.S.of(context).designation,
                          hint: lang.S.of(context).pleaseEnterDesignation,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return lang.S.of(context).enterDesignationName;
                            }
                            if (widget.designationModel != null
                                ? (names.contains(value
                                        .removeAllWhiteSpace()
                                        .toLowerCase()) &&
                                    value.removeAllWhiteSpace().toLowerCase() !=
                                        widget.designationModel!.designation)
                                : (names.contains(value
                                    .removeAllWhiteSpace()
                                    .toLowerCase()))) {
                              return lang.S
                                  .of(context)
                                  .designationNameAlreadyExists;
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
                              return lang.S.of(context).enterDescription;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),
                        _buildSectionHeader('Encargado del cargo', FeatherIcons.userCheck),
                        const SizedBox(height: 8.0),
                        _buildManagerDropdown(ref),
                        const SizedBox(height: 24.0),
                        _buildSectionHeader('Tiempo límite (SLA)', FeatherIcons.clock),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Tiempo que tiene el empleado desde que se le asigna la tarea.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8.0),
                        _buildSlaRow(),
                        const SizedBox(height: 24.0),
                        _buildSectionHeader('Color del departamento', FeatherIcons.droplet),
                        const SizedBox(height: 8.0),
                        _buildColorPicker(),
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
                          label: widget.designationModel != null
                              ? lang.S.of(context).update
                              : lang.S.of(context).saveAndPublish,
                          color: kGreenTextColor,
                          onTap: widget.designationModel != null
                              ? () => _onUpdate(ref)
                              : () => _onCreate(ref),
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
      },
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTitleColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: kTitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildManagerDropdown(WidgetRef ref) {
    final usersAsync = ref.watch(allUserRoleProvider);
    return usersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Error cargando usuarios: $err',
          style: const TextStyle(color: Colors.red)),
      data: (users) {
        final activeUsers = users
            .where((u) => (u.userKey ?? u.databaseId).toString().isNotEmpty)
            .toList();
        return DropdownButtonFormField<String?>(
          initialValue: _selectedManagerUserId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Encargado (opcional)',
            hintText: 'Seleccionar usuario encargado',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin encargado asignado'),
            ),
            ...activeUsers.map((UserRoleModel u) {
              final id = u.userKey ?? u.databaseId ?? '';
              return DropdownMenuItem<String?>(
                value: id,
                child: Text(
                  u.userTitle ?? u.email ?? id,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedManagerUserId = value),
        );
      },
    );
  }

  Widget _buildSlaRow() {
    return Row(
      children: [
        Expanded(child: _buildSlaField(_slaDaysController, 'Días', 0, 365)),
        const SizedBox(width: 8),
        Expanded(child: _buildSlaField(_slaHoursController, 'Horas', 0, 23)),
        const SizedBox(width: 8),
        Expanded(child: _buildSlaField(_slaMinutesController, 'Minutos', 0, 59)),
      ],
    );
  }

  Widget _buildSlaField(
      TextEditingController controller, String label, int min, int max) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final v = int.tryParse(value ?? '');
        if (v == null) return 'Número requerido';
        if (v < min || v > max) return 'Entre $min y $max';
        return null;
      },
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorPalette.map((hex) {
        final isSelected = hex == _selectedColor;
        final color = _hexToColor(hex);
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isSelected ? 44 : 36,
            height: isSelected ? 44 : 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _hexToColor(String hex) {
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }

  Future<void> _onCreate(WidgetRef ref) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final num id = DateTime.now().millisecondsSinceEpoch;

    final model = DesignationModel(
      id: id,
      designation: _designationController.text.trim(),
      designationDescription: _descriptionController.text.trim(),
      managerUserId: _selectedManagerUserId,
      slaDays: int.tryParse(_slaDaysController.text) ?? 1,
      slaHours: int.tryParse(_slaHoursController.text) ?? 0,
      slaMinutes: int.tryParse(_slaMinutesController.text) ?? 0,
      colorHex: _selectedColor,
    );

    final result = await DesignationRepository().addDesignation(designation: model);
    if (result && mounted) {
      // ignore: unused_result
      ref.refresh(designationProvider);
      GoRouter.of(context).pop();
    }
  }

  Future<void> _onUpdate(WidgetRef ref) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final m = widget.designationModel!;
    m.designation = _designationController.text;
    m.designationDescription = _descriptionController.text;
    m.managerUserId = _selectedManagerUserId;
    m.slaDays = int.tryParse(_slaDaysController.text) ?? 1;
    m.slaHours = int.tryParse(_slaHoursController.text) ?? 0;
    m.slaMinutes = int.tryParse(_slaMinutesController.text) ?? 0;
    m.colorHex = _selectedColor;

    final result = await DesignationRepository().updateDesignation(designation: m);
    if (result && mounted) {
      // ignore: unused_result
      ref.refresh(designationProvider);
      GoRouter.of(context).pop();
    }
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

  Widget _buildButton(
      {required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    ).onTap(onTap);
  }
}
