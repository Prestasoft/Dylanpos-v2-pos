import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/currency.dart';

import '../../../Provider/reservation_provider.dart';
import '../../../Provider/servicePackagesProvider.dart';
import '../../../Repository/task_repo.dart';
import '../../../model/reservation_model.dart';
import '../../../services/api_service.dart';
import '../Designation/model/designation_model.dart';
import '../Designation/repo/designation_repo.dart';
import '../employees/model/employee_model.dart';
import '../employees/repo/employee_repo.dart';

class TodayAssignmentsScreen extends ConsumerStatefulWidget {
  const TodayAssignmentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TodayAssignmentsScreen> createState() => _TodayAssignmentsScreenState();
}

class _TodayAssignmentsScreenState extends ConsumerState<TodayAssignmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  List<EmployeeModel> _employees = [];
  List<DesignationModel> _designations = [];
  bool _isLoadingEmployees = true;

  // Sistema de tareas: si el user tiene scoped_designation_id,
  // solo ve/asigna dentro de ese cargo.
  num? _scopedDesignationId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadEmployees(),
      _loadDesignations(),
      _loadUserScope(),
    ]);
  }

  Future<void> _loadEmployees() async {
    try {
      final repo = EmployeeRepository();
      final employees = await repo.getActiveEmployees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingEmployees = false);
      toast('Error cargando empleados: $e');
    }
  }

  Future<void> _loadDesignations() async {
    try {
      final list = await DesignationRepository().getAllDesignation();
      if (!mounted) return;
      setState(() => _designations = list);
    } catch (_) {
      // Silencioso: el screen sigue funcionando sin designaciones cargadas
    }
  }

  Future<void> _loadUserScope() async {
    try {
      final user = ApiService().currentUser;
      final scope = user != null ? user['scoped_designation_id'] : null;
      if (scope == null) return;
      num? parsed;
      if (scope is num) parsed = scope;
      if (scope is String) parsed = num.tryParse(scope);
      if (!mounted) return;
      setState(() => _scopedDesignationId = parsed);
    } catch (_) {}
  }

  /// Mapea keywords (fotograf, maquillaj, etc.) a designation_id basándose en
  /// el nombre de cada designación. Retorna null si no hay match.
  num? _designationIdForKeywords(String keywords) {
    final parts = keywords.toLowerCase().split(',').map((s) => s.trim()).toList();
    for (final d in _designations) {
      final name = d.designation.toLowerCase();
      if (parts.any((k) => k.isNotEmpty && name.contains(k))) {
        return d.id;
      }
    }
    return null;
  }

  Future<void> _updateAssignment(
      ReservationModel reservation, ReservationAssignments newAssignments) async {
    try {
      // 1) Persistir en reservations.nota (compatibilidad con flujo existente)
      final cleanNota = reservation.cleanNota;
      final jsonAssignment = jsonEncode(newAssignments.toJson());
      final newNota = '$cleanNota ||| $jsonAssignment'.trim();

      final api = ApiService();
      final response = await api.put('reservations/${reservation.id}', {'nota': newNota});
      if (!response.success) {
        toast('Error al guardar: ${response.message}');
        return;
      }

      // 2) Sincronizar con la tabla tasks (sistema nuevo de SLA)
      // Patrón: cada rol asignado crea/actualiza una task con el cargo correspondiente.
      await _syncTasksFromAssignments(reservation, newAssignments);

      toast('Asignación guardada');
    } catch (e) {
      toast('Error: $e');
    }
  }

  /// Sincroniza las 4 asignaciones posibles con la tabla tasks.
  /// - Si no existe task para (reservation, designation) y hay userId → POST (crea)
  /// - Si existe task y cambió el userId → PUT (reasigna, resetea SLA)
  /// - Si existe task pero el userId quedó null → no eliminamos (queda historial)
  Future<void> _syncTasksFromAssignments(
      ReservationModel reservation, ReservationAssignments a) async {
    final taskRepo = TaskRepository();

    // Cargar tasks existentes de esta reserva una sola vez
    List tasksForReservation;
    try {
      final allTasks = await taskRepo.getTasks();
      tasksForReservation =
          allTasks.where((t) => t.reservationId == reservation.id).toList();
    } catch (_) {
      tasksForReservation = [];
    }

    final pairs = <_AssignmentPair>[
      _AssignmentPair('fotograf,photo', a.fotografoId),
      _AssignmentPair('maquillaj,makeup,belleza', a.maquillistaId),
      _AssignmentPair('edici,editor', a.editorId),
      _AssignmentPair('ventas,recepcion,vendedor', a.bookedById),
    ];

    for (final p in pairs) {
      final designationId = _designationIdForKeywords(p.keywords);
      if (designationId == null) continue; // sin designación que coincida

      final existingList = tasksForReservation
          .where((t) => t.designationId == designationId)
          .toList();
      final existing = existingList.isNotEmpty ? existingList.first : null;

      final employeeId = p.employeeId;
      EmployeeModel? employee;
      if (employeeId != null && _employees.isNotEmpty) {
        employee = _employees
            .where((e) => e.id.toString() == employeeId)
            .firstOrNull;
      }
      final assignedToUserId = employee?.userId;

      try {
        if (existing == null) {
          if (employeeId == null) continue;
          await taskRepo.createTask(
            reservationId: reservation.id,
            designationId: designationId,
            assignedToUserId: assignedToUserId,
            assignedToEmployeeId: employeeId,
          );
        } else {
          // reasignación si cambió el empleado
          if (existing.assignedToEmployeeId != employeeId) {
            await taskRepo.updateTask(
              taskId: existing.id,
              assignedToUserId: assignedToUserId,
              assignedToEmployeeId: employeeId,
            );
          }
        }
      } catch (_) {
        // Silencioso: si el endpoint de tasks no está aún desplegado,
        // la asignación vía nota sigue funcionando.
      }
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  List<ReservationModel> _getReservationsForDay(List<ReservationModel> allReservations, DateTime targetDay, List<dynamic>? packages) {
    List<ReservationModel> result = [];
    final targetDateKey = DateTime(targetDay.year, targetDay.month, targetDay.day);
    
    String? packageRentaId;
    if (packages != null) {
      for (var pkg in packages) {
         if (pkg.name.toString().toLowerCase().contains('renta')) {
             packageRentaId = pkg.id;
             break;
         }
      }
    }

    Set<String> seenIds = {};
    void tryAdd(ReservationModel res, DateTime key) {
        if (key == targetDateKey && !seenIds.contains(res.id)) {
            result.add(res);
            seenIds.add(res.id);
        }
    }

    for (var reservation in allReservations) {
      if (reservation.estado == 'cancelado') continue;
      final date = _parseDate(reservation.reservationDate);
      final fiestaDate = _parseDate(reservation.fiestaDate ?? '');
      
      bool isRenta = false;
      if (packageRentaId != null && reservation.serviceId == packageRentaId) isRenta = true;
      if (reservation.serviceName != null && reservation.serviceName!.toLowerCase().contains('renta')) isRenta = true;

      if (date != null) {
        if (isRenta) {
          for (int i = -1; i <= 1; i++) {
            DateTime rentDate = date.add(Duration(days: i));
            tryAdd(reservation, DateTime(rentDate.year, rentDate.month, rentDate.day));
          }
        } else {
          tryAdd(reservation, DateTime(date.year, date.month, date.day));
        }
      }
      if (fiestaDate != null) {
        tryAdd(reservation, DateTime(fiestaDate.year, fiestaDate.month, fiestaDate.day));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationsProvider);
    final packagesAsync = ref.watch(servicePackagesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Asignación de Personal y Captación', style: TextStyle(color: Colors.black, fontSize: 16)),
            if (_scopedDesignationId != null)
              Builder(builder: (_) {
                final match = _designations.firstWhere(
                  (d) => d.id == _scopedDesignationId,
                  orElse: () => DesignationModel(id: 0, designation: '', designationDescription: ''),
                );
                if (match.designation.isEmpty) return const SizedBox.shrink();
                return Text(
                  'Vista del encargado · ${match.designation}',
                  style: const TextStyle(color: Colors.deepPurple, fontSize: 11, fontWeight: FontWeight.w500),
                );
              }),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.blue),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
        ],
        bottom: const TabBar(
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: [
            Tab(text: '⏳ Pendientes'),
            Tab(text: '✅ Asignados'),
          ],
        ),
      ),
      body: _isLoadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : reservationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (allReservations) {
                final packagesList = packagesAsync.asData?.value;
                final activeReservations = _getReservationsForDay(allReservations, _selectedDate, packagesList);

                if (activeReservations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No hay reservaciones para ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                bool isAssigned(ReservationModel r) {
                   final assign = r.assignments;
                   return assign.fotografoId != null || assign.maquillistaId != null || assign.editorId != null || assign.bookedById != null;
                }

                final pendingList = activeReservations.where((r) => !isAssigned(r)).toList();
                final assignedList = activeReservations.where((r) => isAssigned(r)).toList();

                return TabBarView(
                  children: [
                    _buildList(pendingList, 'No hay reservaciones pendientes'),
                    _buildList(assignedList, 'No hay reservaciones con personal asignado'),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildList(List<ReservationModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }
    // Si el user está scoped, filtra empleados al mismo cargo
    final visibleEmployees = _scopedDesignationId == null
        ? _employees
        : _employees.where((e) => e.designationId == _scopedDesignationId).toList();

    // Nombre del cargo scoped (para pasar al card)
    String? scopedDesignationName;
    if (_scopedDesignationId != null) {
      final match = _designations.firstWhere(
        (d) => d.id == _scopedDesignationId,
        orElse: () => DesignationModel(id: 0, designation: '', designationDescription: ''),
      );
      if (match.designation.isNotEmpty) scopedDesignationName = match.designation;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reservation = list[index];
        return _AssignmentCard(
          reservation: reservation,
          employees: visibleEmployees,
          scopedDesignationName: scopedDesignationName,
          onUpdate: (assignments) => _updateAssignment(reservation, assignments),
        );
      },
    );
  }
}

class _AssignmentCard extends StatefulWidget {
  final ReservationModel reservation;
  final List<EmployeeModel> employees;
  final String? scopedDesignationName;
  final Function(ReservationAssignments) onUpdate;

  const _AssignmentCard({
    required this.reservation,
    required this.employees,
    required this.onUpdate,
    this.scopedDesignationName,
    Key? key,
  }) : super(key: key);

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  late String? fotografoId;
  late String? maquillistaId;
  late String? editorId;
  late String? bookedById;
  late String? contactChannel;
  late String? socialNetwork;

  @override
  void initState() {
    super.initState();
    _loadFromReservation();
  }

  @override
  void didUpdateWidget(covariant _AssignmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservation.id != widget.reservation.id || oldWidget.reservation.nota != widget.reservation.nota) {
      _loadFromReservation();
    }
  }

  void _loadFromReservation() {
    final assign = widget.reservation.assignments;
    fotografoId = assign.fotografoId;
    maquillistaId = assign.maquillistaId;
    editorId = assign.editorId;
    bookedById = assign.bookedById;
    contactChannel = assign.contactChannel;
    socialNetwork = assign.socialNetwork;
  }

  void _triggerUpdate() {
    widget.onUpdate(
      ReservationAssignments(
        fotografoId: fotografoId,
        maquillistaId: maquillistaId,
        editorId: editorId,
        bookedById: bookedById,
        contactChannel: contactChannel,
        socialNetwork: socialNetwork,
      ),
    );
  }

  List<EmployeeModel> _getAvailableStaff(String depts) {
    if (depts == 'TODOS') return widget.employees;
    final keywords = depts.toLowerCase().split(',');
    return widget.employees.where((e) {
      final d = e.department.toLowerCase();
      return keywords.any((k) => d.contains(k.trim()));
    }).toList();
  }

  /// Si el user está scoped a un cargo, solo muestra el dropdown que matchea
  /// con las keywords del cargo (fotograf, maquillaj, edici, ventas, etc.).
  /// Sin scope: muestra todos los dropdowns.
  bool _shouldShowRole(String keywords) {
    final scopedName = widget.scopedDesignationName;
    if (scopedName == null) return true;
    final scoped = scopedName.toLowerCase();
    final parts = keywords.toLowerCase().split(',').map((s) => s.trim());
    return parts.any((k) => k.isNotEmpty && scoped.contains(k));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reservation.customerName ?? 'Cliente Desconocido',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        widget.reservation.serviceName ?? 'Servicio Estándar',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.reservation.reservationTime,
                    style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Selectores de Personal
            Text('STAFF OPERATIVO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
            const SizedBox(height: 8),
            if (_shouldShowRole('fotograf,photo'))
              _buildDropdown(
                label: 'Fotógrafo Asignado',
                icon: Icons.camera_alt,
                value: fotografoId,
                items: _getAvailableStaff('fotograf,photo'),
                onChanged: (val) {
                  setState(() => fotografoId = val);
                  _triggerUpdate();
                },
              ),
            if (_shouldShowRole('fotograf,photo')) const SizedBox(height: 12),
            if (_shouldShowRole('maquillaj,makeup,belleza'))
              _buildDropdown(
                label: 'Maquillista',
                icon: Icons.face_retouching_natural,
                value: maquillistaId,
                items: _getAvailableStaff('maquillaj,makeup,belleza'),
                onChanged: (val) {
                  setState(() => maquillistaId = val);
                  _triggerUpdate();
                },
              ),
            if (_shouldShowRole('maquillaj,makeup,belleza')) const SizedBox(height: 12),
            if (_shouldShowRole('edici,editor'))
              _buildDropdown(
                label: 'Editor',
                icon: Icons.edit,
                value: editorId,
                items: _getAvailableStaff('edici,editor'),
                onChanged: (val) {
                  setState(() => editorId = val);
                  _triggerUpdate();
                },
              ),

            if (_shouldShowRole('ventas,recepcion,vendedor')) ...[
              const SizedBox(height: 24),
              Text('ORIGEN Y CAPTACIÓN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Agendado Por (Ventas/Recepción)',
                icon: Icons.headset_mic,
                value: bookedById,
                items: widget.employees,
                onChanged: (val) {
                  setState(() => bookedById = val);
                  _triggerUpdate();
                },
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildSimpleDropdown(
                    label: 'Vía Contacto',
                    value: contactChannel,
                    options: ['Presencial', 'Redes', 'Llamada'],
                    onChanged: (val) {
                      setState(() {
                        contactChannel = val;
                        if (val != 'Redes') socialNetwork = null;
                      });
                      _triggerUpdate();
                    },
                  ),
                ),
                if (contactChannel == 'Redes') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildSimpleDropdown(
                      label: 'Red Social',
                      value: socialNetwork,
                      options: ['WhatsApp', 'Instagram', 'Facebook', 'TikTok'],
                      onChanged: (val) {
                        setState(() => socialNetwork = val);
                        _triggerUpdate();
                      },
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<EmployeeModel> items,
    required Function(String?) onChanged,
  }) {
    // Si el value no existe en la lista (ej: empleado borrado), agregamos un nulo temporal
    final bool validValue = value == null || items.any((e) => e.id.toString() == value);
    final finalValue = validValue ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: finalValue,
                hint: Text(label, style: const TextStyle(fontSize: 14)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Asignado', style: TextStyle(color: Colors.grey))),
                  ...items.map((e) => DropdownMenuItem(
                        value: e.id.toString(),
                        child: Text('${e.name} ${e.lastName}'),
                      )),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 13)),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('-', style: TextStyle(color: Colors.grey))),
            ...options.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Par (keywords de cargo, employeeId actualmente asignado en la reserva)
class _AssignmentPair {
  final String keywords;
  final String? employeeId;
  const _AssignmentPair(this.keywords, this.employeeId);
}
