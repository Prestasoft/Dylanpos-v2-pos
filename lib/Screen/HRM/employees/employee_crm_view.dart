import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/employee_profile_screen.dart';

import '../../Widgets/Constant Data/constant.dart';
import '../departments/department_provider.dart';
import '../Designation/repo/designation_repo.dart';
import 'add_employee.dart';
import 'employee_list_v2.dart';
import 'widgets/department_column.dart';

/// Colores por defecto para departamentos (se rotan)
const _defaultDeptColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber
  Color(0xFFEF4444), // Red
  Color(0xFF8B5CF6), // Violet
  Color(0xFF14B8A6), // Teal
  Color(0xFFEC4899), // Pink
  Color(0xFFF97316), // Orange
  Color(0xFF06B6D4), // Cyan
];

/// Vista CRM de empleados organizada por columnas de departamento.
/// Soporta drag-and-drop para mover empleados entre departamentos.
class EmployeeCrmView extends ConsumerStatefulWidget {
  const EmployeeCrmView({super.key});

  @override
  ConsumerState<EmployeeCrmView> createState() => _EmployeeCrmViewState();
}

class _EmployeeCrmViewState extends ConsumerState<EmployeeCrmView> {
  String _search = '';
  String _statusFilter = 'activo'; // activo, todos, inactivo
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeProviderV2);
    final deptAsync = ref.watch(departmentProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return employeeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allEmployees) {
        final departments = deptAsync.valueOrNull ?? [];

        // Filtrar por estado
        List<EmployeeModel> filtered;
        if (_statusFilter == 'todos') {
          filtered = allEmployees;
        } else {
          filtered = allEmployees.where((e) => e.status.toLowerCase() == _statusFilter).toList();
        }

        // Filtrar por búsqueda
        if (_search.isNotEmpty) {
          final s = _search.toLowerCase();
          filtered = filtered.where((e) =>
              e.fullName.toLowerCase().contains(s) ||
              e.designation.toLowerCase().contains(s) ||
              e.phoneNumber.contains(s)).toList();
        }

        // Agrupar por departamento
        final grouped = <String, List<EmployeeModel>>{};
        for (final e in filtered) {
          final dept = e.department.isNotEmpty ? e.department : 'Sin Departamento';
          grouped.putIfAbsent(dept, () => []);
          grouped[dept]!.add(e);
        }

        // Ordenar departamentos por display_order
        final deptOrder = <String, int>{};
        final deptIdMap = <String, int>{};
        for (final d in departments) {
          deptOrder[d.name] = d.displayOrder;
          deptIdMap[d.name] = d.id;
        }

        // Incluir departamentos vacíos (que existen en la BD pero no tienen empleados)
        for (final d in departments) {
          grouped.putIfAbsent(d.name, () => []);
        }

        final sortedDeptNames = grouped.keys.toList()
          ..sort((a, b) {
            final oa = deptOrder[a] ?? 999;
            final ob = deptOrder[b] ?? 999;
            if (oa != ob) return oa.compareTo(ob);
            return a.compareTo(b);
          });

        // Stats
        final totalActive = allEmployees.where((e) => e.status.toLowerCase() == 'activo').length;
        final totalInactive = allEmployees.length - totalActive;

        // Column width
        final columnWidth = screenWidth > 1400
            ? (screenWidth - 80) / 6
            : screenWidth > 1000
                ? (screenWidth - 60) / 4.5
                : 250.0;

        return Column(
          children: [
            // Toolbar
            _buildToolbar(totalActive, totalInactive, allEmployees.length),

            // Columns
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  _scrollController.jumpTo(
                    (_scrollController.offset - details.delta.dx).clamp(
                      0.0,
                      _scrollController.position.maxScrollExtent,
                    ),
                  );
                },
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedDeptNames.map((deptName) {
                        final deptIndex = sortedDeptNames.indexOf(deptName);
                        final color = _defaultDeptColors[deptIndex % _defaultDeptColors.length];
                        final deptId = deptIdMap[deptName] ?? 0;

                        return SizedBox(
                          height: MediaQuery.of(context).size.height - 180,
                          child: DepartmentColumn(
                            departmentName: deptName,
                            departmentId: deptId,
                            color: color,
                            employees: grouped[deptName] ?? [],
                            width: columnWidth.clamp(220, 320),
                            onView: (emp) => _viewEmployee(emp),
                            onEdit: (emp) => _editEmployee(emp),
                            onDrop: (emp, newDept, newDeptId) => _moveEmployee(emp, newDept, newDeptId),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(int totalActive, int totalInactive, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar empleado...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status filter chips
          _filterChip('Activos ($totalActive)', 'activo'),
          const SizedBox(width: 6),
          _filterChip('Todos ($total)', 'todos'),
          const SizedBox(width: 6),
          _filterChip('Inactivos ($totalInactive)', 'inactivo'),

          const SizedBox(width: 12),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: Colors.grey[600],
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(employeeProviderV2),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = _statusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? Colors.white : Colors.grey[700],
        ),
      ),
      selected: isActive,
      selectedColor: kMainColor,
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: isActive ? kMainColor : Colors.grey.withValues(alpha: 0.3)),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  void _viewEmployee(EmployeeModel emp) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeProfileScreen(employee: emp)),
    );
  }

  void _editEmployee(EmployeeModel emp) async {
    final designations = await DesignationRepository().getAllDesignation();
    final employees = await EmployeeRepository().getAllEmployees();
    if (!mounted) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: AddEmployeeScreen(
            listOfEmployees: employees,
            ref: ref,
            designations: designations,
            employeeModel: emp,
          ),
        );
      },
    );
  }

  Future<void> _moveEmployee(EmployeeModel emp, String newDept, int newDeptId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: kMainColor),
            const SizedBox(width: 8),
            const Text('Cambiar Departamento', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            children: [
              const TextSpan(text: 'Mover a '),
              TextSpan(
                text: emp.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' de '),
              TextSpan(
                text: emp.department,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red[400]),
              ),
              const TextSpan(text: ' a '),
              TextSpan(
                text: newDept,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[600]),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
            child: const Text('Mover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      EasyLoading.show(status: 'Moviendo...');
      final success = await EmployeeRepository().updateEmployeePartial(
        id: emp.id,
        data: {'department': newDept},
      );

      if (success) {
        EasyLoading.showSuccess('${emp.fullName} movido a $newDept');
        ref.invalidate(employeeProviderV2);
      } else {
        EasyLoading.showError('Error al mover empleado');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }
}
