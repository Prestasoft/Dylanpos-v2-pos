import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_info_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_work_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_salary_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_contact_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_history_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/add_employee.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/Widgets/Constant Data/constant.dart';

/// Pantalla de Perfil Completo del Empleado con Pestañas
class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final EmployeeModel employee;

  const EmployeeProfileScreen({
    super.key,
    required this.employee,
  });

  @override
  ConsumerState<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends ConsumerState<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1240;

    return Scaffold(
      backgroundColor: kAppSurfaceBg,
      appBar: AppBar(
        backgroundColor: kMainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil de Empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.employee.fullName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Botón de editar
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditDialog(context),
            tooltip: 'Editar empleado',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header Card con foto y datos básicos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: kMainColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Foto del empleado
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: widget.employee.photoUrl != null &&
                          widget.employee.photoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            widget.employee.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              size: 50,
                              color: kMainColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.person, size: 50, color: kMainColor),
                ),
                const SizedBox(width: 20),
                // Datos básicos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.employee.designation,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusBadge(widget.employee.status),
                          const SizedBox(width: 12),
                          Text(
                            'ID: ${widget.employee.cedula}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Estadísticas rápidas (solo en desktop)
                if (isDesktop) ...[
                  const SizedBox(width: 20),
                  _buildQuickStats(),
                ],
              ],
            ),
          ),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: !isDesktop,
              labelColor: kMainColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kMainColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'Info Personal',
                ),
                Tab(
                  icon: Icon(Icons.work_outline),
                  text: 'Laboral',
                ),
                Tab(
                  icon: Icon(Icons.attach_money),
                  text: 'Salario',
                ),
                Tab(
                  icon: Icon(Icons.contact_phone),
                  text: 'Contacto',
                ),
                Tab(
                  icon: Icon(Icons.timeline),
                  text: 'Historial',
                ),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                EmployeeInfoTab(employee: widget.employee),
                EmployeeWorkTab(employee: widget.employee),
                EmployeeSalaryTab(employee: widget.employee),
                EmployeeContactTab(employee: widget.employee),
                EmployeeHistoryTab(employee: widget.employee),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'activo':
        color = Colors.greenAccent;
        icon = Icons.check_circle;
        break;
      case 'inactivo':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case 'suspendido':
        color = Colors.orangeAccent;
        icon = Icons.pause_circle;
        break;
      case 'licencia':
        color = Colors.blueAccent;
        icon = Icons.beach_access;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
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

  Widget _buildQuickStats() {
    final years = widget.employee.yearsOfService;
    final vacationDays = widget.employee.vacationDaysAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(76)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.timeline,
            label: 'Antigüedad',
            value: '$years ${years == 1 ? 'año' : 'años'}',
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Icons.beach_access,
            label: 'Vacaciones',
            value: '$vacationDays días',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  void _openEditDialog(BuildContext context) async {
    final designations = await DesignationRepository().getAllDesignation();
    final employees = await EmployeeRepository().getAllEmployees();

    if (!mounted) return;

    // Guardar el contexto antes del async gap
    final dialogContext = context;

    showDialog(
      barrierDismissible: false,
      context: dialogContext,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: AddEmployeeScreen(
            listOfEmployees: employees,
            ref: ref,
            designations: designations,
            employeeModel: widget.employee,
          ),
        );
      },
    );
  }
}
