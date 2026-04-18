import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/employee_profile_screen.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_quick_stats_popup.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_photo_widget.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/batch_photo_update_dialog.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/batch_birthdate_update_dialog.dart';
import 'package:salespro_admin/services/padron_electoral_service.dart';
import 'package:salespro_admin/commas.dart';

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../departments/department_provider.dart';
import '../widgets/deleteing_alart_dialog.dart';
import 'add_employee.dart';

/// Provider de empleados para la lista v2
final employeeProviderV2 = FutureProvider.autoDispose<List<EmployeeModel>>((ref) async {
  debugPrint('🔵 [employeeProviderV2] Iniciando carga de empleados...');
  try {
    final employees = await EmployeeRepository().getAllEmployees();
    debugPrint('🔵 [employeeProviderV2] Empleados cargados: ${employees.length}');
    return employees;
  } catch (e) {
    debugPrint('🔴 [employeeProviderV2] Error: $e');
    rethrow;
  }
});

class EmployeeListV2Screen extends StatefulWidget {
  const EmployeeListV2Screen({super.key});

  @override
  State<EmployeeListV2Screen> createState() => _EmployeeListV2ScreenState();
}

class _EmployeeListV2ScreenState extends State<EmployeeListV2Screen>
    with SingleTickerProviderStateMixin {
  String searchItem = '';
  String? _selectedDepartment; // null = Todos
  late TabController _tabController;
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final employeeAsync = ref.watch(employeeProviderV2);

          return Scaffold(
            backgroundColor: kAppSurfaceBg,
            body: employeeAsync.when(
              data: (allEmployees) {
                // Separar por estados
                final activeEmployees =
                    allEmployees.where((e) => e.status.toLowerCase() == 'activo').toList();
                final inactiveEmployees =
                    allEmployees.where((e) => e.status.toLowerCase() == 'inactivo').toList();
                final suspendedEmployees =
                    allEmployees.where((e) => e.status.toLowerCase() == 'suspendido').toList();
                final vacationEmployees =
                    allEmployees.where((e) => e.status.toLowerCase() == 'vacaciones').toList();
                final leaveEmployees =
                    allEmployees.where((e) => e.status.toLowerCase() == 'licencia').toList();

                // Aplicar búsqueda según tab actual
                List<EmployeeModel> currentList;
                switch (_tabController.index) {
                  case 0:
                    currentList = activeEmployees;
                    break;
                  case 1:
                    currentList = inactiveEmployees;
                    break;
                  case 2:
                    currentList = suspendedEmployees;
                    break;
                  case 3:
                    currentList = vacationEmployees;
                    break;
                  case 4:
                    currentList = leaveEmployees;
                    break;
                  default:
                    currentList = activeEmployees;
                }
                // Extraer departamentos únicos y ordenar por display_order de BD
                final allDepartments = <String>{};
                for (final e in allEmployees) {
                  if (e.department.isNotEmpty && e.department != 'General') {
                    allDepartments.add(e.department);
                  }
                }
                // Obtener orden de departamentos desde la BD
                final deptModels = ref.watch(departmentProvider).valueOrNull ?? [];
                final deptOrderMap = <String, int>{};
                for (final d in deptModels) {
                  deptOrderMap[d.name] = d.displayOrder;
                }
                final sortedDepartments = allDepartments.toList()
                  ..sort((a, b) {
                    final orderA = deptOrderMap[a] ?? 999;
                    final orderB = deptOrderMap[b] ?? 999;
                    if (orderA != orderB) return orderA.compareTo(orderB);
                    return a.compareTo(b); // fallback alfabético
                  });

                final filteredList = currentList.where((employee) {
                  // Filtro por departamento
                  if (_selectedDepartment != null && employee.department != _selectedDepartment) {
                    return false;
                  }
                  // Filtro por búsqueda de texto
                  if (searchItem.isEmpty) return true;
                  final search = searchItem.toLowerCase();
                  return employee.fullName.toLowerCase().contains(search) ||
                      employee.designation.toLowerCase().contains(search) ||
                      employee.phoneNumber.contains(search);
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: kWhite,
                    ),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Empleados',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total: ${allEmployees.length} | Activos: ${activeEmployees.length} | Inactivos: ${inactiveEmployees.length} | Suspendidos: ${suspendedEmployees.length} | Vacaciones: ${vacationEmployees.length} | Licencia: ${leaveEmployees.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20.0),
                              // Botón Actualizar Fotos
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.cloud_download, color: kMainColor),
                                tooltip: 'Actualizar fotos desde Padrón Electoral',
                                onSelected: (value) async {
                                  if (value == 'update_missing') {
                                    final result = await showBatchPhotoUpdateDialog(
                                      context,
                                      ref,
                                      forceUpdate: false,
                                    );
                                    if (result == true) {
                                      ref.invalidate(employeeProviderV2);
                                    }
                                  } else if (value == 'update_all') {
                                    // Confirmar antes de actualizar todas
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirmar actualización'),
                                        content: const Text(
                                          '¿Desea reemplazar TODAS las fotos de empleados?\n\n'
                                          'Esto sobrescribirá las fotos existentes con las del Padrón Electoral.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                            ),
                                            child: const Text('Sí, reemplazar todas'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      final result = await showBatchPhotoUpdateDialog(
                                        context,
                                        ref,
                                        forceUpdate: true,
                                      );
                                      if (result == true) {
                                        ref.invalidate(employeeProviderV2);
                                      }
                                    }
                                  } else if (value == 'update_birthdates') {
                                    // Actualizar fechas de nacimiento desde Padrón Electoral
                                    // forceUpdate: true para actualizar TODOS, incluso los que ya tienen fecha
                                    final result = await showBatchBirthDateUpdateDialog(
                                      context,
                                      ref,
                                      forceUpdate: true,
                                    );
                                    if (result == true) {
                                      ref.invalidate(employeeProviderV2);
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'update_missing',
                                    child: ListTile(
                                      leading: Icon(Icons.add_photo_alternate, color: Colors.green),
                                      title: Text('Agregar fotos faltantes'),
                                      subtitle: Text('Solo empleados sin foto'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'update_all',
                                    child: ListTile(
                                      leading: Icon(Icons.sync, color: Colors.orange),
                                      title: Text('Actualizar todas las fotos'),
                                      subtitle: Text('Reemplaza fotos existentes'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'update_birthdates',
                                    child: ListTile(
                                      leading: Icon(Icons.cake, color: Colors.purple),
                                      title: Text('Actualizar fechas nacimiento'),
                                      subtitle: Text('Desde Padrón Electoral'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // Botón Agregar
                              ElevatedButton.icon(
                                onPressed: () => _showAddEmployeeDialog(context, ref, allEmployees),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar Empleado'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMainColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1.0, color: kNeutral300, height: 1),

                        // TabBar
                        TabBar(
                          controller: _tabController,
                          labelColor: kMainColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: kMainColor,
                          onTap: (_) => setState(() {
                            _currentPage = 1; // Reset página al cambiar tab
                          }),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 18, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text('Activos (${activeEmployees.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cancel, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Inactivos (${inactiveEmployees.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pause_circle, size: 18, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text('Suspendidos (${suspendedEmployees.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.beach_access, size: 18, color: Colors.teal),
                                  const SizedBox(width: 6),
                                  Text('Vacaciones (${vacationEmployees.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.medical_services, size: 18, color: Colors.blue),
                                  const SizedBox(width: 6),
                                  Text('Licencia (${leaveEmployees.length})'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Barra de búsqueda y controles
                        ResponsiveGridRow(
                          rowSegments: 100,
                          children: [
                            ResponsiveGridCol(
                              xs: screenWidth < 360 ? 50 : screenWidth > 430 ? 33 : 40,
                              md: screenWidth < 768 ? 24 : screenWidth < 950 ? 20 : 15,
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
                                        ),
                                      ),
                                      DropdownButton<int>(
                                        isDense: true,
                                        padding: EdgeInsets.zero,
                                        underline: const SizedBox(),
                                        value: _itemsPerPage,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
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
                                            _itemsPerPage = newValue ?? 10;
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
                                    hintText: 'Buscar por nombre, cargo o teléfono',
                                    suffixIcon: const Icon(FeatherIcons.search, color: kTitleColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Chips de departamento
                        if (sortedDepartments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('Todos (${currentList.length})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: _selectedDepartment == null ? FontWeight.w600 : FontWeight.w400,
                                            color: _selectedDepartment == null ? Colors.white : kTitleColor,
                                          )),
                                      selected: _selectedDepartment == null,
                                      selectedColor: kMainColor,
                                      backgroundColor: kNeutral100,
                                      side: BorderSide(color: _selectedDepartment == null ? kMainColor : kNeutral300),
                                      onSelected: (_) => setState(() {
                                        _selectedDepartment = null;
                                        _currentPage = 1;
                                      }),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  ...sortedDepartments.map((dept) {
                                    final count = currentList.where((e) => e.department == dept).length;
                                    final isActive = _selectedDepartment == dept;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text('$dept ($count)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                              color: isActive ? Colors.white : kTitleColor,
                                            )),
                                        selected: isActive,
                                        selectedColor: kMainColor,
                                        backgroundColor: kNeutral100,
                                        side: BorderSide(color: isActive ? kMainColor : kNeutral300),
                                        onSelected: (_) => setState(() {
                                          _selectedDepartment = isActive ? null : dept;
                                          _currentPage = 1;
                                        }),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                        // Tabla de empleados
                        _buildEmployeeTable(theme, filteredList, ref),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card profesional del encargado de departamento
  Widget _buildHeadCard(EmployeeModel head, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFDF8EE), const Color(0xFFFFF9F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A84B).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A84B).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto
          Stack(
            children: [
              EmployeePhotoCircle(
                photoUrl: head.photoUrl,
                radius: 28,
                employeeName: head.fullName,
                showBadge: false,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A84B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A84B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ENCARGADO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB8860B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  head.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  head.designation,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Contacto
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (head.phoneNumber.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(head.phoneNumber, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: head.status == 'Activo' ? Colors.green : Colors.grey),
                  const SizedBox(width: 4),
                  Text(head.status, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Botón ver perfil
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            color: const Color(0xFFD4A84B),
            tooltip: 'Ver perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmployeeProfileScreen(employee: head),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable(ThemeData theme, List<EmployeeModel> employees, WidgetRef ref) {
    if (employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay empleados ${_getEmptyStateText()}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Separar encargado del equipo cuando hay departamento filtrado
    EmployeeModel? departmentHead;
    List<EmployeeModel> teamMembers = employees;

    if (_selectedDepartment != null) {
      final heads = employees.where((e) => e.isDepartmentHead).toList();
      if (heads.isNotEmpty) {
        departmentHead = heads.first;
        teamMembers = employees.where((e) => !e.isDepartmentHead).toList();
      }
    }

    // Paginación (solo para el equipo, el encargado siempre se muestra)
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = _itemsPerPage == -1
        ? teamMembers.length
        : (startIndex + _itemsPerPage).clamp(0, teamMembers.length);
    final paginatedEmployees = teamMembers.sublist(startIndex, endIndex);
    final totalPages = _itemsPerPage == -1 ? 1 : (teamMembers.length / _itemsPerPage).ceil();

    return Column(
      children: [
        // Card del encargado (si hay departamento filtrado y tiene encargado)
        if (departmentHead != null) ...[
          _buildHeadCard(departmentHead, ref),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Equipo (${teamMembers.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
          ),
        ],

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: const TableBorder(
              horizontalInside: BorderSide(width: 1, color: kNeutral300),
            ),
            dataRowColor: const WidgetStatePropertyAll(Colors.white),
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
            showBottomBorder: false,
            dividerThickness: 0.0,
            headingTextStyle: theme.textTheme.titleMedium,
            columns: const [
              DataColumn(label: Text('S.L')),
              DataColumn(label: Text('Foto')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Cargo')),
              DataColumn(label: Text('Departamento')),
              DataColumn(label: Text('Teléfono')),
              DataColumn(label: Text('Salario')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: List.generate(
              paginatedEmployees.length,
              (index) {
                final employee = paginatedEmployees[index];
                return DataRow(
                  cells: [
                    DataCell(Text((startIndex + index + 1).toString())),
                    DataCell(
                      EmployeePhotoCircle(
                        photoUrl: employee.photoUrl,
                        radius: 22,
                        employeeName: employee.fullName,
                        showBadge: true,
                      ),
                    ),
                    DataCell(Text(employee.fullName)),
                    DataCell(Text(employee.designation)),
                    DataCell(Text(employee.department)),
                    DataCell(Text(employee.phoneNumber)),
                    DataCell(Text(myFormat.format(employee.salary))),
                    DataCell(_buildStatusBadge(employee.status)),
                    DataCell(_buildActionButtons(context, employee, ref)),
                  ],
                );
              },
            ),
          ),
        ),

        // Paginación
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Página $_currentPage de $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getEmptyStateText() {
    switch (_tabController.index) {
      case 0:
        return 'activos';
      case 1:
        return 'inactivos';
      case 2:
        return 'suspendidos';
      case 3:
        return 'en vacaciones';
      case 4:
        return 'con licencia';
      default:
        return '';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inactivo':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case 'suspendido':
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      case 'vacaciones':
        color = Colors.teal;
        icon = Icons.beach_access;
        break;
      case 'licencia':
        color = Colors.blue;
        icon = Icons.medical_services;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EmployeeModel employee, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ver Perfil
        IconButton(
          icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
          onPressed: () => _openProfileScreen(context, employee),
          tooltip: 'Ver perfil',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        // Estadísticas
        IconButton(
          icon: const Icon(Icons.analytics, size: 20, color: Colors.purple),
          onPressed: () => EmployeeQuickStatsPopup.show(
            context,
            employee,
            onViewFullProfile: () => _openProfileScreen(context, employee),
          ),
          tooltip: 'Estadísticas',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        // Actualizar desde Padrón Electoral
        IconButton(
          icon: Icon(
            Icons.cloud_sync,
            size: 20,
            color: employee.cedula.isNotEmpty ? Colors.teal : Colors.grey,
          ),
          onPressed: employee.cedula.isNotEmpty
              ? () => _updateFromPadron(context, ref, employee)
              : null,
          tooltip: employee.cedula.isNotEmpty
              ? 'Actualizar desde Padrón Electoral'
              : 'Sin cédula registrada',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        // Editar
        IconButton(
          icon: const Icon(Icons.edit, size: 20, color: Colors.green),
          onPressed: () => _showEditEmployeeDialog(context, ref, employee),
          tooltip: 'Editar',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        // Eliminar
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: () => _deleteEmployee(context, ref, employee),
          tooltip: 'Eliminar',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _openProfileScreen(BuildContext context, EmployeeModel employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeProfileScreen(employee: employee),
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, WidgetRef ref, List<EmployeeModel> employees) async {
    if (!checkUserRoleEditPermissionV2(type: 'hrm')) {
      EasyLoading.showError(userPermissionErrorText);
      return;
    }

    final designations = await DesignationRepository().getAllDesignation();
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
          ),
        );
      },
    );
  }

  void _showEditEmployeeDialog(BuildContext context, WidgetRef ref, EmployeeModel employee) async {
    if (!checkUserRoleEditPermissionV2(type: 'hrm')) {
      EasyLoading.showError(userPermissionErrorText);
      return;
    }

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
            employeeModel: employee,
          ),
        );
      },
    );
  }

  void _deleteEmployee(BuildContext context, WidgetRef ref, EmployeeModel employee) async {
    if (!checkUserRoleDeletePermissionV2(type: 'hrm')) {
      EasyLoading.showError(userPermissionErrorText);
      return;
    }

    if (await showDeleteConfirmationDialog(context: context, itemName: 'employee')) {
      try {
        EasyLoading.show(status: 'Eliminando empleado...');
        await EmployeeRepository().deleteEmployee(id: employee.id.toString());
        EasyLoading.showSuccess('Empleado eliminado exitosamente');
        ref.invalidate(employeeProviderV2);
      } catch (e) {
        EasyLoading.showError('Error al eliminar: $e');
      }
    }
  }

  /// Actualiza los datos del empleado desde el Padrón Electoral
  Future<void> _updateFromPadron(BuildContext context, WidgetRef ref, EmployeeModel employee) async {
    if (!checkUserRoleEditPermissionV2(type: 'hrm')) {
      EasyLoading.showError(userPermissionErrorText);
      return;
    }

    // Mostrar diálogo de confirmación con opciones
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_sync, color: Colors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Actualizar desde Padrón',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empleado: ${employee.fullName}'),
            Text('Cédula: ${employee.cedula}'),
            const SizedBox(height: 16),
            const Text(
              '¿Qué datos desea actualizar desde el Padrón Electoral?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'photo_only'),
            icon: const Icon(Icons.photo_camera, size: 18),
            label: const Text('Solo Foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'all_data'),
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Todos los Datos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      EasyLoading.show(status: 'Consultando Padrón Electoral...');

      final padronService = PadronElectoralService();
      final response = await padronService.consultarCedula(employee.cedula);

      if (!response.success || response.data == null) {
        EasyLoading.showError(response.message ?? 'No se encontró la cédula');
        return;
      }

      final padronData = response.data!;
      Map<String, dynamic> updateData = {};

      if (result == 'all_data') {
        // Actualizar todos los datos
        updateData = {
          'first_name': padronData.nombres,
          'last_name': padronData.apellidosCompletos,
          'full_name': padronData.nombreCompleto,
          'gender': padronData.generoMapeado,
          'marital_status': padronData.estadoCivilMapeado,
          if (padronData.fechaNacimientoParsed != null)
            'birth_date': padronData.fechaNacimientoParsed!.toIso8601String().split('T')[0],
          if (padronData.provincia != null) 'province': padronData.provincia,
          if (padronData.municipio != null) 'city': padronData.municipio,
          if (padronData.direccion != null && padronData.direccion!.isNotEmpty)
            'address': 'Cerca de ${padronData.direccion}',
        };
      }

      // Agregar foto si está disponible
      if (padronData.tieneFoto) {
        updateData['image_url'] = padronData.fotoDataUrl;
        debugPrint('📷 [UpdateFromPadron] Foto disponible, longitud: ${padronData.fotoDataUrl?.length ?? 0}');
        debugPrint('📷 [UpdateFromPadron] Prefijo foto: ${padronData.fotoDataUrl?.substring(0, 30) ?? "null"}...');
      } else {
        debugPrint('📷 [UpdateFromPadron] No hay foto disponible');
      }

      if (updateData.isEmpty) {
        EasyLoading.showInfo('No hay datos nuevos para actualizar');
        return;
      }

      debugPrint('📷 [UpdateFromPadron] Datos a enviar: ${updateData.keys.toList()}');
      debugPrint('📷 [UpdateFromPadron] Tiene image_url: ${updateData.containsKey('image_url')}');

      EasyLoading.show(status: 'Actualizando empleado...');

      // Llamar al API para actualizar
      final updateResult = await EmployeeRepository().updateEmployeePartial(
        id: employee.id.toString(),
        data: updateData,
      );

      debugPrint('📷 [UpdateFromPadron] Resultado de actualización: $updateResult');

      if (updateResult) {
        EasyLoading.showSuccess('Empleado actualizado correctamente');
        ref.invalidate(employeeProviderV2);
      } else {
        EasyLoading.showError('Error al actualizar el empleado');
      }
    } catch (e) {
      debugPrint('Error actualizando desde Padrón: $e');
      EasyLoading.showError('Error: ${e.toString()}');
    }
  }
}
