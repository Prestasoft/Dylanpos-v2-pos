import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/Designation/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../employees/model/employee_model.dart';
import '../employees/repo/employee_repo.dart';

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
                                        widget.designationModel!.designation
                                            .removeAllWhiteSpace()
                                            .toLowerCase())
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
                          label: 'Departamento',
                          hint: 'Ej: Ventas, Producción, Limpieza',
                          validator: (_) => null,
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

  List<EmployeeModel>? _cachedEmployees;
  bool _loadingEmployees = false;

  Future<void> _loadEmployeesForDesignation() async {
    if (_loadingEmployees || _cachedEmployees != null) return;
    _loadingEmployees = true;
    try {
      final all = await EmployeeRepository().getActiveEmployees();
      final designationId = widget.designationModel?.id;
      if (mounted) {
        setState(() {
          _cachedEmployees = designationId != null
              ? all.where((e) => e.designationId == designationId).toList()
              : all;
          _loadingEmployees = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Widget _buildManagerDropdown(WidgetRef ref) {
    // Cargar empleados del cargo al primer build
    if (_cachedEmployees == null && !_loadingEmployees) {
      _loadEmployeesForDesignation();
    }

    if (_loadingEmployees) return const LinearProgressIndicator();

    final employees = _cachedEmployees ?? [];

    // Resolver nombre actual del encargado seleccionado
    String currentLabel = '';
    if (_selectedManagerUserId != null) {
      final match = employees.where((e) =>
        e.userId == _selectedManagerUserId ||
        e.id.toString() == _selectedManagerUserId).firstOrNull;
      if (match != null) currentLabel = '${match.name} ${match.lastName}'.trim();
    }

    return Autocomplete<EmployeeModel>(
      displayStringForOption: (e) => '${e.name} ${e.lastName}'.trim(),
      initialValue: TextEditingValue(text: currentLabel),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return employees;
        return employees.where((e) {
          final fullName = '${e.name} ${e.lastName}'.toLowerCase();
          return fullName.contains(query);
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Encargado (opcional)',
            hintText: employees.isEmpty
                ? 'No hay empleados en este cargo'
                : 'Buscar empleado del cargo...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      setState(() => _selectedManagerUserId = null);
                    },
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 500),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (ctx, i) {
                  final e = options.elementAt(i);
                  final fullName = '${e.name} ${e.lastName}'.trim();
                  final empId = e.userId ?? e.id.toString();
                  final isSelected = empId == _selectedManagerUserId;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: kMainColor.withValues(alpha: 0.08),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: kMainColor.withValues(alpha: 0.15),
                      child: Text(
                        e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMainColor),
                      ),
                    ),
                    title: Text(
                      fullName,
                      style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                    ),
                    subtitle: e.designation.isNotEmpty
                        ? Text(e.designation, style: TextStyle(fontSize: 11, color: Colors.grey[500]))
                        : null,
                    onTap: () => onSelected(e),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (e) {
        final id = e.userId ?? e.id.toString();
        setState(() => _selectedManagerUserId = id);
      },
    );
  }

  // Presets de SLA rápidos
  static const List<Map<String, dynamic>> _slaPresets = [
    {'label': '15 min', 'days': 0, 'hours': 0, 'minutes': 15},
    {'label': '30 min', 'days': 0, 'hours': 0, 'minutes': 30},
    {'label': '1 hora', 'days': 0, 'hours': 1, 'minutes': 0},
    {'label': '2 horas', 'days': 0, 'hours': 2, 'minutes': 0},
    {'label': '1 día', 'days': 1, 'hours': 0, 'minutes': 0},
    {'label': '3 días', 'days': 3, 'hours': 0, 'minutes': 0},
  ];

  void _applySlaPreset(Map<String, dynamic> preset) {
    setState(() {
      _slaDaysController.text = preset['days'].toString();
      _slaHoursController.text = preset['hours'].toString();
      _slaMinutesController.text = preset['minutes'].toString();
    });
  }

  String _getSlaPreview() {
    final d = int.tryParse(_slaDaysController.text) ?? 0;
    final h = int.tryParse(_slaHoursController.text) ?? 0;
    final m = int.tryParse(_slaMinutesController.text) ?? 0;
    if (d == 0 && h == 0 && m == 0) return 'Sin tiempo límite';
    final parts = <String>[];
    if (d > 0) parts.add('$d día${d > 1 ? 's' : ''}');
    if (h > 0) parts.add('$h hora${h > 1 ? 's' : ''}');
    if (m > 0) parts.add('$m minuto${m > 1 ? 's' : ''}');
    return parts.join(' y ');
  }

  bool _isPresetActive(Map<String, dynamic> preset) {
    return (int.tryParse(_slaDaysController.text) ?? 0) == preset['days'] &&
        (int.tryParse(_slaHoursController.text) ?? 0) == preset['hours'] &&
        (int.tryParse(_slaMinutesController.text) ?? 0) == preset['minutes'];
  }

  Widget _buildSlaRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets rápidos
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _slaPresets.map((preset) {
            final active = _isPresetActive(preset);
            return ChoiceChip(
              label: Text(
                preset['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : kTitleColor,
                ),
              ),
              selected: active,
              selectedColor: kMainColor,
              backgroundColor: kNeutral100,
              side: BorderSide(color: active ? kMainColor : kNeutral300),
              onSelected: (_) => _applySlaPreset(preset),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        // Steppers
        Row(
          children: [
            Expanded(child: _buildSlaStepper(_slaDaysController, 'Días', 0, 365, Icons.calendar_today)),
            const SizedBox(width: 10),
            Expanded(child: _buildSlaStepper(_slaHoursController, 'Horas', 0, 23, Icons.schedule)),
            const SizedBox(width: 10),
            Expanded(child: _buildSlaStepper(_slaMinutesController, 'Min', 0, 59, Icons.timer_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        // Preview total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: kMainColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kMainColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.timelapse, size: 16, color: kMainColor),
              const SizedBox(width: 8),
              Text(
                'Tiempo total: ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                _getSlaPreview(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTitleColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlaStepper(TextEditingController controller, String label, int min, int max, IconData icon) {
    final value = int.tryParse(controller.text) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: kNeutral100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kNeutral300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: kMainColor),
          const SizedBox(height: 4),
          // Botón +
          InkWell(
            onTap: value < max ? () => setState(() => controller.text = '${value + 1}') : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value < max ? kMainColor.withValues(alpha: 0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.add, size: 16, color: value < max ? kMainColor : Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 4),
          // Valor
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTitleColor),
          ),
          const SizedBox(height: 4),
          // Botón -
          InkWell(
            onTap: value > min ? () => setState(() => controller.text = '${value - 1}') : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value > min ? kMainColor.withValues(alpha: 0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.remove, size: 16, color: value > min ? kMainColor : Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
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
