import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_info_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_work_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_salary_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_contact_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_history_tab.dart';
import 'package:salespro_admin/Screen/HRM/employees/widgets/employee_photo_widget.dart';
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
      backgroundColor: const Color(0xFFF5F5F5), // Fondo gris claro
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.grey.withValues(alpha: 0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Usar Navigator.pop si la navegación fue con Navigator.push (ej: desde popup cumpleaños)
            // Si no, usar GoRouter.pop
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil de Empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              widget.employee.fullName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey[600]),
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
          // Header Card con foto y datos básicos - Tema Blanco
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Foto del empleado
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kMainColor, width: 2),
                  ),
                  child: EmployeePhotoWidget(
                    photoUrl: widget.employee.photoUrl,
                    size: 96,
                    borderRadius: 10,
                    backgroundColor: Colors.grey[100],
                    fallbackIconSize: 50,
                    fallbackIconColor: kMainColor,
                  ),
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
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.employee.designation,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
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

          // TabBarView - Con fondo blanco para consistencia de tema claro
          Expanded(
            child: Container(
              color: Colors.white,
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
      case 'licencia':
        color = Colors.blue;
        icon = Icons.medical_services;
        break;
      case 'vacaciones':
        color = Colors.teal;
        icon = Icons.beach_access;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMainColor.withValues(alpha: 0.3)),
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
        Icon(icon, color: kMainColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
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
