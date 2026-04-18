import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/currency.dart';

import '../../../Provider/reservation_provider.dart';
import '../../../Provider/servicePackagesProvider.dart';
import '../../../Repository/task_repo.dart';
import '../../../model/task_model.dart';
import '../../../model/reservation_model.dart';
import '../../../services/api_service.dart';
import '../Designation/model/designation_model.dart';
import '../Designation/repo/designation_repo.dart';
import '../employees/model/employee_model.dart';
import '../employees/repo/employee_repo.dart';
import 'widgets/makeup_dashboard_banner.dart';
import 'widgets/task_theme.dart';

class TodayAssignmentsScreen extends ConsumerStatefulWidget {
  const TodayAssignmentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TodayAssignmentsScreen> createState() => _TodayAssignmentsScreenState();
}

class _TodayAssignmentsScreenState extends ConsumerState<TodayAssignmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  List<EmployeeModel> _employees = [];
  List<DesignationModel> _designations = [];
  List<dynamic> _allTasks = []; // Tasks para métricas de maquillaje
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
      _loadTasks(),
    ]);
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskRepository().getTasks();
      if (!mounted) return;
      setState(() => _allTasks = tasks);
    } catch (_) {}
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
      try {
        await _syncTasksFromAssignments(reservation, newAssignments);
      } catch (e) {
        debugPrint('⚠️ Error sincronizando tasks: $e');
      }

      // 3) Refrescar el provider para que la UI se actualice
      // ignore: unused_result
      ref.refresh(reservationsProvider);

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
      _AssignmentPair('edici,editor', a.editorId),
      _AssignmentPair('ventas,recepcion,vendedor', a.bookedById),
    ];
    // Multi-maquillaje: crear task por cada maquillista asignado
    if (a.maquillistaIds.isNotEmpty) {
      for (final mId in a.maquillistaIds) {
        if (mId.isNotEmpty) pairs.add(_AssignmentPair('maquillaj,makeup,belleza', mId));
      }
    } else if (a.maquillistaId != null) {
      pairs.add(_AssignmentPair('maquillaj,makeup,belleza', a.maquillistaId));
    }

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

      // Excluir rentas de vestimentas — no necesitan asignación de personal
      if (isRenta) continue;

      if (date != null) {
        tryAdd(reservation, DateTime(date.year, date.month, date.day));
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

    final tc = TaskColors.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: tc.scaffold,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Asignación de Personal y Captación', style: TextStyle(color: tc.appBarTitle, fontSize: 16)),
            if (_scopedDesignationId != null)
              Builder(builder: (_) {
                final match = _designations.firstWhere(
                  (d) => d.id == _scopedDesignationId,
                  orElse: () => DesignationModel(id: 0, designation: '', designationDescription: ''),
                );
                if (match.designation.isEmpty) return const SizedBox.shrink();
                return Text(
                  'Vista del encargado · ${match.designation}',
                  style: TextStyle(color: tc.tabSelected, fontSize: 11, fontWeight: FontWeight.w500),
                );
              }),
          ],
        ),
        backgroundColor: tc.appBar,
        iconTheme: tc.appBarIconTheme,
        elevation: 0.5,
        actions: [
          const TaskThemeToggle(),
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
        bottom: TabBar(
          labelColor: tc.tabSelected,
          unselectedLabelColor: tc.tabUnselected,
          indicatorColor: tc.tabIndicator,
          tabs: const [
            Tab(text: '⏳ Pendientes'),
            Tab(text: '✅ Asignados'),
            Tab(text: '🚫 No aplica'),
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
                        Icon(Icons.event_busy, size: 64, color: tc.textHint),
                        const SizedBox(height: 16),
                        Text('No hay reservaciones para ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                            style: TextStyle(fontSize: 18, color: tc.textSecondary)),
                      ],
                    ),
                  );
                }

                // Detectar slot del encargado para filtrar declined
                String? scopedSlot;
                if (_scopedDesignationId != null) {
                  final scopedDesig = _designations.where((d) => d.id == _scopedDesignationId).firstOrNull;
                  if (scopedDesig != null) scopedSlot = _detectRoleSlotByName(scopedDesig.designation);
                }

                bool isDeclined(ReservationModel r) {
                  if (scopedSlot == null) return false;
                  return r.assignments.isDeclined(scopedSlot!);
                }

                bool isAssigned(ReservationModel r) {
                   final assign = r.assignments;
                   if (scopedSlot != null) {
                     if (scopedSlot == 'maquillista') return assign.maquillistaId != null;
                     return _getAssignmentBySlot(assign, scopedSlot!) != null;
                   }
                   return assign.fotografoId != null || assign.maquillistaId != null || assign.editorId != null || assign.bookedById != null;
                }

                int compareByTime(ReservationModel a, ReservationModel b) {
                  return a.reservationTime.compareTo(b.reservationTime);
                }

                final declinedList = activeReservations.where((r) => isDeclined(r)).toList()..sort(compareByTime);
                final notDeclined = activeReservations.where((r) => !isDeclined(r)).toList();
                final pendingList = notDeclined.where((r) => !isAssigned(r)).toList()..sort(compareByTime);
                final assignedList = notDeclined.where((r) => isAssigned(r)).toList()..sort(compareByTime);

                // Calcular métricas de maquillaje para el banner
                Widget? makeupBanner;
                if (scopedSlot == 'maquillista' || _scopedDesignationId == null) {
                  int totalMaq = 0, unassignedMaq = 0;
                  final todayResIds = <String>{};

                  for (final r in notDeclined) {
                    todayResIds.add(r.id);
                    try {
                      final desc = _getPackageDescription(r);
                      final count = desc.isNotEmpty ? _parseMakeupCount(desc) : 1;
                      int assigned = 0;
                      for (int i = 0; i < count; i++) {
                        if (r.assignments.getMaquillistaAt(i) != null) assigned++;
                      }
                      totalMaq += count;
                      unassignedMaq += (count - assigned);
                    } catch (_) {
                      totalMaq += 1;
                      if (r.assignments.maquillistaId == null) unassignedMaq += 1;
                    }
                  }

                  // Contar tasks reales de maquillaje del día
                  final maqDesigId = _designationIdForKeywords('maquillaj,makeup,belleza');
                  int completedMaq = 0, inProgressMaq = 0, notStartedMaq = 0;
                  for (final t in _allTasks) {
                    if (maqDesigId != null && t.designationId != maqDesigId) continue;
                    if (!todayResIds.contains(t.reservationId)) continue;
                    if (t.status == TaskStatus.completada) {
                      completedMaq++;
                    } else if (t.status == TaskStatus.enProgreso) {
                      inProgressMaq++;
                    } else if (t.status == TaskStatus.pendiente) {
                      notStartedMaq++;
                    }
                  }

                  // Ajustar: si no hay tasks creadas aún, los asignados son "sin iniciar"
                  final taskedMaq = completedMaq + inProgressMaq + notStartedMaq;
                  final assignedNoTask = (totalMaq - unassignedMaq) - taskedMaq;
                  if (assignedNoTask > 0) notStartedMaq += assignedNoTask;

                  if (totalMaq > 0) {
                    makeupBanner = MakeupDashboardBanner(
                      totalNeeded: totalMaq,
                      completed: completedMaq,
                      inProgress: inProgressMaq,
                      notStarted: notStartedMaq,
                      unassigned: unassignedMaq,
                    );
                  }
                }

                return Column(
                  children: [
                    if (makeupBanner != null) makeupBanner,
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildList(pendingList, 'No hay reservaciones pendientes'),
                          _buildList(assignedList, 'No hay reservaciones con personal asignado'),
                          _buildDeclinedList(declinedList),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildList(List<ReservationModel> list, String emptyMessage) {
    final tc = TaskColors.read(context);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: tc.textHint),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(fontSize: 16, color: tc.textSecondary)),
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

        // Vista ENCARGADO: card compacta + modal para asignar
        if (scopedDesignationName != null) {
          return _buildScopedCard(
            index: index,
            reservation: reservation,
            employees: visibleEmployees,
            designationName: scopedDesignationName,
          );
        }

        // Vista ADMIN: card con todos los dropdowns
        return _AssignmentCard(
          reservation: reservation,
          employees: visibleEmployees,
          scopedDesignationName: null,
          onUpdate: (assignments) => _updateAssignment(reservation, assignments),
        );
      },
    );
  }

  /// Lista de reservaciones rechazadas (no aplica)
  Widget _buildDeclinedList(List<ReservationModel> list) {
    final tc = TaskColors.read(context);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: tc.textHint),
            const SizedBox(height: 16),
            Text('No hay reservaciones marcadas como "No aplica"',
                style: TextStyle(fontSize: 16, color: tc.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reservation = list[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: tc.card,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tc.textHint)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reservation.customerName ?? 'Cliente',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tc.textSecondary,
                              decoration: TextDecoration.lineThrough)),
                      Text('Maquillaje externo',
                          style: TextStyle(fontSize: 11, color: tc.textHint)),
                    ],
                  ),
                ),
                Text(reservation.reservationTime, style: TextStyle(color: tc.textHint, fontSize: 12)),
                const SizedBox(width: 8),
                SizedBox(
                  height: 30,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore, size: 14),
                    label: const Text('Restaurar', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _toggleDecline(reservation, false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Marca o desmarca una reservación como "No aplica" para el cargo del encargado
  Future<void> _toggleDecline(ReservationModel reservation, bool decline) async {
    String? slot;
    if (_scopedDesignationId != null) {
      final scopedDesig = _designations.where((d) => d.id == _scopedDesignationId).firstOrNull;
      if (scopedDesig != null) slot = _detectRoleSlotByName(scopedDesig.designation);
    }
    if (slot == null) return;

    final assign = reservation.assignments;
    final newDeclined = Map<String, bool>.from(assign.declined);
    if (decline) {
      newDeclined[slot] = true;
    } else {
      newDeclined.remove(slot);
    }

    final newAssign = ReservationAssignments(
      fotografoId: assign.fotografoId,
      maquillistaId: assign.maquillistaId,
      maquillistaIds: assign.maquillistaIds,
      maquillistaIdsPre: assign.maquillistaIdsPre,
      maquillistaIdsFiesta: assign.maquillistaIdsFiesta,
      editorId: assign.editorId,
      bookedById: assign.bookedById,
      contactChannel: assign.contactChannel,
      socialNetwork: assign.socialNetwork,
      declined: newDeclined,
    );

    await _updateAssignment(reservation, newAssign);
  }

  /// Card compacta para encargados: numerada, nombre del cliente, botón "Asignar"
  /// Para maquillaje, muestra N slots según la descripción del paquete.
  Widget _buildScopedCard({
    required int index,
    required ReservationModel reservation,
    required List<EmployeeModel> employees,
    required String designationName,
  }) {
    final assign = reservation.assignments;
    final slot = _detectRoleSlotByName(designationName);
    final tc = TaskColors.read(context);

    // Para maquillaje: detectar cuántos slots necesita y sus nombres
    final isMakeup = slot == 'maquillista';
    List<String> makeupLabels = ['Maquillaje'];
    String? makeupEvent;
    String? eventBadge;
    if (isMakeup) {
      try {
        final desc = _getPackageDescription(reservation);
        if (desc.isNotEmpty) {
          final parsed = _parseMakeupByEvent(desc);

          if (parsed.hasSections && reservation.fiestaDate != null && reservation.fiestaDate!.isNotEmpty) {
            final fiestaDate = DateTime.tryParse(reservation.fiestaDate!);
            final resDate = DateTime.tryParse(reservation.reservationDate);
            final today = _selectedDate;

            if (fiestaDate != null && today.year == fiestaDate.year && today.month == fiestaDate.month && today.day == fiestaDate.day) {
              makeupLabels = parsed.labelsFiesta.isNotEmpty ? parsed.labelsFiesta : ['Maquillaje'];
              makeupEvent = 'fiesta';
              eventBadge = 'Fiesta';
            } else if (resDate != null && today.year == resDate.year && today.month == resDate.month && today.day == resDate.day) {
              makeupLabels = parsed.labelsPre.isNotEmpty ? parsed.labelsPre : ['Maquillaje'];
              makeupEvent = 'pre';
              eventBadge = 'Pre-Quince';
            } else {
              makeupLabels = parsed.labels.isNotEmpty ? parsed.labels : ['Maquillaje'];
            }
          } else {
            makeupLabels = parsed.labels.isNotEmpty ? parsed.labels : ['Maquillaje'];
          }
        }
      } catch (e) {
        debugPrint('Error parseando maquillajes: $e');
        makeupLabels = ['Maquillaje'];
      }
    }
    final makeupSlots = makeupLabels.length;

    // Para maquillaje multi: calcular progreso de asignación
    int assignedCount = 0;
    if (isMakeup && makeupSlots > 1) {
      for (int i = 0; i < makeupSlots; i++) {
        if (assign.getMaquillistaAt(i, makeupEvent) != null) assignedCount++;
      }
    } else {
      assignedCount = _getAssignmentBySlot(assign, slot) != null ? 1 : 0;
    }
    final totalSlots = isMakeup && makeupSlots > 1 ? makeupSlots : 1;
    final isComplete = assignedCount >= totalSlots;
    final borderColor = isComplete
        ? Colors.green
        : assignedCount > 0
            ? Colors.orange
            : (tc.isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: borderColor.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header: número + cliente + progreso + hora
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: tc.isDark ? 0.1 : 0.04),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.customerName ?? 'Cliente',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tc.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reservation.serviceName != null && reservation.serviceName!.isNotEmpty)
                        Text(
                          reservation.serviceName!,
                          style: TextStyle(fontSize: 11, color: tc.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Badge de evento (Pre-Quince / Fiesta)
                if (eventBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: makeupEvent == 'fiesta'
                          ? Colors.pink.withValues(alpha: 0.12)
                          : Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      eventBadge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: makeupEvent == 'fiesta' ? Colors.pink : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Badge de progreso (solo multi-maquillaje)
                if (isMakeup && makeupSlots > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isComplete ? Icons.check_circle : Icons.face_retouching_natural,
                          size: 14,
                          color: isComplete ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$assignedCount/$makeupSlots',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isComplete ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  reservation.reservationTime,
                  style: TextStyle(color: tc.textHint, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Slots de asignación
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                if (isMakeup && makeupSlots > 1)
                  ...List.generate(makeupSlots, (mIdx) {
                    final maqId = assign.getMaquillistaAt(mIdx, makeupEvent);
                    final isSupport = maqId != null && maqId.startsWith('support:');
                    final supportN = isSupport ? maqId.substring(8) : null;
                    final emp = (maqId == null || isSupport) ? null : employees.where((e) => e.id.toString() == maqId).firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildAssignmentSlotRow(
                        tc: tc,
                        label: makeupLabels[mIdx],
                        supportName: supportN,
                        employee: emp,
                        onAssign: () => _showAssignModalMulti(reservation, employees, designationName, mIdx, makeupLabels[mIdx], makeupEvent),
                      ),
                    );
                  })
                else
                  _buildAssignmentSlotRow(
                    tc: tc,
                    employee: _getEmployeeForSlot(assign, slot, employees),
                    onAssign: () => _showAssignModal(reservation, employees, designationName, slot),
                  ),
                // Botón "No aplica" — maquillaje externo
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('No aplica / Maquillaje externo', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade300,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _toggleDecline(reservation, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de asignación: indicador + label + empleado + botón
  Widget _buildAssignmentSlotRow({
    required dynamic tc,
    EmployeeModel? employee,
    String? supportName,
    String? label,
    required VoidCallback onAssign,
  }) {
    final isAssigned = employee != null || (supportName != null && supportName.isNotEmpty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isAssigned
            ? Colors.green.withValues(alpha: tc.isDark ? 0.1 : 0.04)
            : Colors.orange.withValues(alpha: tc.isDark ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAssigned
              ? Colors.green.withValues(alpha: 0.25)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Icon(
            isAssigned ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isAssigned ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          // Label del slot
          if (label != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tc.isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tc.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Empleado asignado o "Sin asignar"
          Expanded(
            child: isAssigned
                ? Row(
                    children: [
                      if (supportName != null && supportName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Soporte', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.purple)),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          employee != null ? '${employee.name} ${employee.lastName}' : (supportName ?? ''),
                          style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text('Sin asignar', style: TextStyle(color: tc.textHint, fontSize: 12)),
          ),
          const SizedBox(width: 6),
          // Botón compacto
          SizedBox(
            height: 30,
            child: ElevatedButton.icon(
              icon: Icon(isAssigned ? Icons.swap_horiz : Icons.person_add, size: 14),
              label: Text(isAssigned ? 'Cambiar' : 'Asignar', style: const TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAssigned ? Colors.orange : Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: onAssign,
            ),
          ),
        ],
      ),
    );
  }

  EmployeeModel? _getEmployeeForSlot(ReservationAssignments assign, String slot, List<EmployeeModel> employees) {
    final id = _getAssignmentBySlot(assign, slot);
    if (id == null) return null;
    return employees.where((e) => e.id.toString() == id).firstOrNull;
  }

  /// Modal para asignar maquillista en un slot específico (multi-maquillaje)
  Future<void> _showAssignModalMulti(
    ReservationModel reservation,
    List<EmployeeModel> employees,
    String designationName,
    int maqIndex, [
    String? slotLabel,
    String? event,
  ]) async {
    final tc = TaskColors.read(context);
    // Resultado puede ser EmployeeModel o Map con support_name
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tc.dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.face_retouching_natural, color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maq. ${slotLabel ?? 'Maquillaje ${maqIndex + 1}'}', style: TextStyle(fontSize: 16, color: tc.textPrimary)),
                    Text(reservation.customerName ?? 'Cliente', style: TextStyle(fontSize: 12, color: tc.textHint, fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: employees.length + 2, // empleados + divider + soporte
              itemBuilder: (_, i) {
                if (i < employees.length) {
                  final emp = employees[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: CircleAvatar(
                      backgroundColor: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                      child: Text(emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                          style: TextStyle(color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${emp.name} ${emp.lastName}', style: TextStyle(fontWeight: FontWeight.w500, color: tc.textPrimary)),
                    subtitle: Text(emp.designation, style: TextStyle(fontSize: 12, color: tc.textHint)),
                    onTap: () => Navigator.of(ctx).pop(emp),
                  );
                }
                if (i == employees.length) return const Divider();
                // Último item: soporte
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_add_alt, color: Colors.purple, size: 20),
                  ),
                  title: Text('Maquillista de Soporte', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.purple.shade300)),
                  subtitle: Text('Maquillista externa', style: TextStyle(fontSize: 11, color: tc.textHint)),
                  onTap: () {
                    Navigator.of(ctx).pop(null);
                    _showSupportNameDialog(reservation, maqIndex, event);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          ],
        );
      },
    );

    if (result == null) return;
    if (result is EmployeeModel) {
      final newAssign = reservation.assignments.withMaquillistaAt(maqIndex, result.id.toString(), event);
      await _updateAssignment(reservation, newAssign);
    }
  }

  /// Diálogo para ingresar nombre de maquillista de soporte
  Future<void> _showSupportNameDialog(ReservationModel reservation, int maqIndex, String? event) async {
    final controller = TextEditingController();
    final tc = TaskColors.read(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add_alt, color: Colors.purple.shade300),
            const SizedBox(width: 10),
            Text('Maquillista de Soporte', style: TextStyle(fontSize: 16, color: tc.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: tc.textPrimary),
          decoration: InputDecoration(
            labelText: 'Nombre de la maquillista',
            hintText: 'Ej: María Rodríguez',
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(color: tc.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) Navigator.of(ctx).pop(val);
            },
            child: const Text('Asignar Soporte'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;

    // Crear task de soporte: sin employee_id, con support_name, asignada al encargado
    final maqDesigId = _designationIdForKeywords('maquillaj,makeup,belleza');
    if (maqDesigId == null) return;

    final taskRepo = TaskRepository();
    final user = ApiService().currentUser;
    final encargadaUserId = user?['id']?.toString();

    await taskRepo.createTask(
      reservationId: reservation.id,
      designationId: maqDesigId,
      assignedToUserId: encargadaUserId,
      supportName: name,
    );

    // Marcar slot como asignado con ID especial "support:nombre"
    final newAssign = reservation.assignments.withMaquillistaAt(maqIndex, 'support:$name', event);
    await _updateAssignment(reservation, newAssign);
  }

  /// Modal para seleccionar empleado
  Future<void> _showAssignModal(
    ReservationModel reservation,
    List<EmployeeModel> employees,
    String designationName,
    String slot,
  ) async {
    final tc = TaskColors.read(context);
    final selected = await showDialog<EmployeeModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.assignment_ind, color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asignar $designationName', style: TextStyle(fontSize: 16, color: tc.textPrimary)),
                  Text(
                    reservation.customerName ?? 'Cliente',
                    style: TextStyle(fontSize: 12, color: tc.textHint, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: employees.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No hay empleados disponibles en este departamento', style: TextStyle(color: tc.textSecondary)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: employees.length,
                  itemBuilder: (_, i) {
                    final emp = employees[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: CircleAvatar(
                        backgroundColor: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                        child: Text(
                          emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                          style: TextStyle(color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text('${emp.name} ${emp.lastName}', style: TextStyle(fontWeight: FontWeight.w500, color: tc.textPrimary)),
                      subtitle: Text(emp.designation, style: TextStyle(fontSize: 12, color: tc.textHint)),
                      onTap: () => Navigator.of(ctx).pop(emp),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected == null) return;

    // Crear las assignments actualizadas
    final assign = reservation.assignments;
    final newAssign = ReservationAssignments(
      fotografoId: slot == 'fotografo' ? selected.id.toString() : assign.fotografoId,
      maquillistaId: slot == 'maquillista' ? selected.id.toString() : assign.maquillistaId,
      editorId: slot == 'editor' ? selected.id.toString() : assign.editorId,
      bookedById: slot == 'vendedor' ? selected.id.toString() : assign.bookedById,
      contactChannel: assign.contactChannel,
      socialNetwork: assign.socialNetwork,
    );

    await _updateAssignment(reservation, newAssign);
  }

  String _detectRoleSlotByName(String name) {
    final d = name.toLowerCase();
    if (d.contains('foto') || d.contains('photo') || d.contains('camer')) return 'fotografo';
    if (d.contains('maquil') || d.contains('makeup') || d.contains('belleza')) return 'maquillista';
    if (d.contains('edic') || d.contains('editor') || d.contains('post')) return 'editor';
    return 'vendedor';
  }

  /// Resultado del parser de maquillajes por evento
  int _parseMakeupCount(String description) {
    return _parseMakeupLabels(description).length;
  }

  /// Parsea maquillajes de la descripción, dividiendo por sección Pre-Quince/Fiesta si existe.
  /// Retorna un MakeupParseResult con labels por evento.
  _MakeupParseResult _parseMakeupByEvent(String description) {
    if (description.isEmpty) {
      return _MakeupParseResult(labels: ['Maquillaje'], labelsPre: [], labelsFiesta: [], hasSections: false);
    }
    final lower = description.toLowerCase();

    // Detectar si tiene secciones Pre-Quince y Fiesta
    final preIdx = RegExp(r'pre[- ]?quince|pre[- ]?boda', caseSensitive: false).firstMatch(lower)?.start ?? -1;
    final fiestaIdx = RegExp(r'\nfiesta\b|\n\s*fiesta\b', caseSensitive: false).firstMatch(lower)?.start ?? -1;

    if (preIdx != -1 && fiestaIdx != -1 && fiestaIdx > preIdx) {
      // Tiene secciones separadas
      final preSection = lower.substring(preIdx, fiestaIdx);
      final fiestaSection = lower.substring(fiestaIdx);
      final labelsPre = _extractMakeupFromSection(preSection);
      final labelsFiesta = _extractMakeupFromSection(fiestaSection);
      return _MakeupParseResult(
        labels: [...labelsPre, ...labelsFiesta],
        labelsPre: labelsPre,
        labelsFiesta: labelsFiesta,
        hasSections: true,
      );
    }

    // Sin secciones: parsear todo como un bloque
    final labels = _extractMakeupFromSection(description.toLowerCase());
    return _MakeupParseResult(
      labels: labels.isNotEmpty ? labels : ['Maquillaje'],
      labelsPre: [],
      labelsFiesta: [],
      hasSections: false,
    );
  }

  /// Extrae labels de maquillaje de una sección de texto
  List<String> _extractMakeupFromSection(String section) {
    final labels = <String>[];
    final lines = section.split('\n');
    for (final line in lines) {
      if (!line.contains('maquillaj') && !line.contains('makeup')) continue;

      // Patrón "para: X, Y y Z" o "para X, Y y Z"
      final paraMatch = RegExp(r'para:?\s*(.+)', caseSensitive: false).firstMatch(line);
      if (paraMatch != null) {
        final afterPara = paraMatch.group(1)!.replaceAll(RegExp(r'\(.*?\)'), '').trim();
        final parts = afterPara.split(RegExp(r',\s*|\s+y\s+')).where((p) => p.trim().isNotEmpty).toList();
        for (final p in parts) {
          final clean = p.trim();
          if (clean.isNotEmpty) labels.add(_capitalize(clean));
        }
      } else {
        // "Maquillaje profesional" sin detalles
        final aLaMatch = RegExp(r'a\s+la\s+(\w+)', caseSensitive: false).firstMatch(line);
        if (aLaMatch != null) {
          labels.add(_capitalize(aLaMatch.group(1)!));
        } else {
          labels.add('Maquillaje');
        }
      }
    }
    return labels;
  }

  /// Parsea maquillajes sin distinción de evento (compatibilidad)
  List<String> _parseMakeupLabels(String description) {
    final result = _parseMakeupByEvent(description);
    return result.labels.isEmpty ? ['Maquillaje'] : result.labels;
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Busca el paquete correspondiente a la reservación
  String _getPackageDescription(ReservationModel reservation) {
    final packagesAsync = ref.read(servicePackagesProvider);
    final packages = packagesAsync.asData?.value;
    if (packages == null) return '';
    for (final pkg in packages) {
      if (pkg.id == reservation.serviceId) return pkg.description;
    }
    return '';
  }

  String? _getAssignmentBySlot(ReservationAssignments a, String slot) {
    switch (slot) {
      case 'fotografo': return a.fotografoId;
      case 'maquillista': return a.maquillistaId;
      case 'editor': return a.editorId;
      case 'vendedor': return a.bookedById;
      default: return null;
    }
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

  List<EmployeeModel> _getAvailableStaff(String keywords) {
    if (keywords == 'TODOS') return widget.employees;
    final parts = keywords.toLowerCase().split(',');
    return widget.employees.where((e) {
      // Buscar por nombre del cargo (designation), no por departamento
      final cargo = e.designation.toLowerCase();
      return parts.any((k) => cargo.contains(k.trim()));
    }).toList();
  }

  /// Detecta a cuál de los 4 campos de ReservationAssignments corresponde
  /// el cargo del encargado, basándose en el nombre de la designación.
  /// Retorna 'fotografo', 'maquillista', 'editor' o 'vendedor'.
  String _detectRoleSlot() {
    final name = (widget.scopedDesignationName ?? '').toLowerCase();
    if (name.contains('foto') || name.contains('photo') || name.contains('camer')) return 'fotografo';
    if (name.contains('maquil') || name.contains('makeup') || name.contains('belleza')) return 'maquillista';
    if (name.contains('edic') || name.contains('editor') || name.contains('post')) return 'editor';
    return 'vendedor';
  }

  /// Lee el valor actual del slot que corresponde al cargo del encargado.
  String? _getScopedValue() {
    switch (_detectRoleSlot()) {
      case 'fotografo': return fotografoId;
      case 'maquillista': return maquillistaId;
      case 'editor': return editorId;
      case 'vendedor': return bookedById;
      default: return null;
    }
  }

  /// Setea el valor del slot que corresponde al cargo del encargado.
  void _setScopedValue(String? val) {
    setState(() {
      switch (_detectRoleSlot()) {
        case 'fotografo': fotografoId = val; break;
        case 'maquillista': maquillistaId = val; break;
        case 'editor': editorId = val; break;
        case 'vendedor': bookedById = val; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: tc.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tc.isDark ? Colors.blue.shade900 : Colors.blue.shade100,
                  foregroundColor: tc.isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reservation.customerName ?? 'Cliente Desconocido',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tc.textPrimary),
                      ),
                      Text(
                        widget.reservation.serviceName ?? 'Servicio Estándar',
                        style: TextStyle(color: tc.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tc.isDark ? Colors.deepPurple.shade900 : Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.reservation.reservationTime,
                    style: TextStyle(color: tc.isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Divider(height: 32, color: tc.divider),

            // Si el user es encargado de un cargo específico, solo muestra
            // UN dropdown con su cargo y sus empleados. Sin scope = vista admin completa.
            if (widget.scopedDesignationName != null) ...[
              Text(
                widget.scopedDesignationName!.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tc.textHint),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Asignar ${widget.scopedDesignationName}',
                icon: Icons.assignment_ind,
                value: _getScopedValue(),
                items: widget.employees,
                onChanged: (val) {
                  _setScopedValue(val);
                  _triggerUpdate();
                },
              ),
            ] else ...[
              // Vista admin: todos los dropdowns
              Text('STAFF OPERATIVO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tc.textHint)),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              Text('ORIGEN Y CAPTACIÓN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tc.textHint)),
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

    final tc = TaskColors.read(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tc.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tc.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: finalValue,
                hint: Text(label, style: TextStyle(fontSize: 14, color: tc.textHint)),
                isExpanded: true,
                dropdownColor: tc.card,
                items: [
                  DropdownMenuItem(value: null, child: Text('No Asignado', style: TextStyle(color: tc.textHint))),
                  ...items.map((e) => DropdownMenuItem(
                        value: e.id.toString(),
                        child: Text('${e.name} ${e.lastName}', style: TextStyle(color: tc.textPrimary)),
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
    final tc = TaskColors.read(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tc.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: TextStyle(fontSize: 13, color: tc.textHint)),
          isExpanded: true,
          dropdownColor: tc.card,
          items: [
            DropdownMenuItem(value: null, child: Text('-', style: TextStyle(color: tc.textHint))),
            ...options.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(fontSize: 13, color: tc.textPrimary)),
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

class _MakeupParseResult {
  final List<String> labels; // Todos los maquillajes (compatibilidad)
  final List<String> labelsPre; // Maquillajes de Pre-Quince
  final List<String> labelsFiesta; // Maquillajes de Fiesta
  final bool hasSections; // true si la descripción tiene secciones separadas

  const _MakeupParseResult({
    required this.labels,
    required this.labelsPre,
    required this.labelsFiesta,
    required this.hasSections,
  });
}
