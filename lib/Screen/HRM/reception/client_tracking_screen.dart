import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../services/api_service.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../employees/model/employee_model.dart';
import '../employees/repo/employee_repo.dart';
import 'client_tracking_model.dart';
import 'client_tracking_repo.dart';
import 'widgets/client_journey_card.dart';
import 'widgets/kanban_board.dart';

/// Pantalla de Seguimiento de Clientes para el departamento de Recepción.
///
/// Adapta la vista según el rol del usuario logueado:
///   - Admin: ve todo, puede asignar recepcionistas
///   - department_head (encargada recepción): ve todo su departamento, puede asignar
///   - employee (recepcionista): ve solo SUS clientes asignados
class ClientTrackingScreen extends StatefulWidget {
  const ClientTrackingScreen({super.key});

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  final _repo = ClientTrackingRepository();
  final _api = ApiService();

  bool _loading = true;
  List<ClientTrackingModel> _clients = [];
  List<EmployeeModel> _receptionists = [];
  DateTime _dateFrom = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _dateTo = DateTime.now().add(const Duration(days: 60));

  // Rol del usuario actual
  String _userRole = 'admin'; // admin, department_head, employee
  String? _currentEmployeeId; // ID del empleado vinculado al user
  String? _currentUserName;

  // Filtro activo: null = Sin asignar, string = employeeId de recepcionista
  String? _activeFilter;
  String _stageFilter = 'todos';
  bool _showCompleted = false; // Tab Completado para recepcionistas
  Map<String, String> _kanbanColors = {}; // Colores personalizados del kanban

  @override
  void initState() {
    super.initState();
    _detectUserRole();
    _loadData();
  }

  void _detectUserRole() {
    final user = _api.currentUser;
    if (user == null) return;
    _userRole = user['role']?.toString() ?? 'admin';
    final linkedRaw = user['linked_employee_id']?.toString();
    _currentEmployeeId = (linkedRaw != null && linkedRaw.isNotEmpty && linkedRaw != 'null') ? linkedRaw : null;
    _currentUserName = user['name']?.toString();

    // Si tiene empleado vinculado y no es admin, ver solo sus clientes
    if (_currentEmployeeId != null && _userRole != 'admin') {
      _activeFilter = _currentEmployeeId;
    }
  }

  bool get _isAdmin => _userRole == 'admin';
  bool get _isDepartmentHead => _userRole == 'department_head';
  bool get _isLinkedUser => _currentEmployeeId != null && !_isAdmin;
  bool get _canAssign => _isAdmin || _isDepartmentHead;

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final dateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final clients = await _repo.getClients(dateFrom: dateFrom, dateTo: dateTo);

      // Cargar recepcionistas (empleados del departamento Recepción/Ventas)
      final allEmployees = await EmployeeRepository().getActiveEmployees();
      final receptionists = allEmployees.where((e) {
        final d = e.designation.toLowerCase();
        return d.contains('recepcion') || d.contains('tienda') || d.contains('vendedor');
      }).toList();

      // Cargar colores del kanban
      try {
        final colorsResp = await _api.get('hrm/kanban-colors');
        if (colorsResp.success && colorsResp.data != null) {
          final rawData = colorsResp.data is Map ? colorsResp.data as Map<String, dynamic> : <String, dynamic>{};
          final colorsList = rawData['data']?['colors'] ?? rawData['colors'] ?? [];
          if (colorsList is List) {
            for (final c in colorsList) {
              if (c is Map) _kanbanColors[c['stage_key']?.toString() ?? ''] = c['color_hex']?.toString() ?? '';
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _clients = clients;
        _receptionists = receptionists;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando tracking: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Clientes filtrados por la tab activa + etapa
  List<ClientTrackingModel> get _filteredClients {
    List<ClientTrackingModel> list;

    if (_activeFilter == null) {
      list = _clients.where((c) => c.isUnassigned).toList();
    } else {
      // Filtrar SOLO por bookedById (asignación formal desde el sistema)
      list = _clients.where((c) => c.bookedById == _activeFilter).toList();
    }

    if (_stageFilter != 'todos') {
      list = list.where((c) {
        if (_stageFilter == 'completado') return c.isFullyCompleted;
        if (_stageFilter == 'seguimiento') {
          // Clientes recién asignados sin tasks de otros departamentos
          return c.stages.isEmpty || c.departmentGroups.every((g) => g.isEmpty || g.key == 'seguimiento');
        }
        // Filtrar por departamento activo (tiene tasks pendientes/en proceso)
        final groups = c.departmentGroups;
        return groups.any((g) => g.key == _stageFilter && g.hasActive);
      }).toList();
    }

    return list;
  }

  String _getReceptionistName(String employeeId) {
    final match = _receptionists.where((e) => e.id.toString() == employeeId).firstOrNull;
    return match != null ? '${match.name} ${match.lastName}'.trim() : '';
  }

  List<_TabInfo> get _tabs {
    final tabs = <_TabInfo>[];

    // Solo admin y encargada ven "Sin asignar"
    if (_canAssign) {
      tabs.add(_TabInfo(
        id: null,
        label: 'Sin asignar',
        count: _clients.where((c) => c.isUnassigned).length,
        icon: Icons.person_add,
        color: Colors.orange,
      ));
    }

    if (_isLinkedUser && _currentEmployeeId != null) {
      // Empleado solo ve su tab
      final myCount = _clients.where((c) =>
          c.bookedById == _currentEmployeeId ||
          c.bookedByName == _currentUserName).length;
      tabs.add(_TabInfo(
        id: _currentEmployeeId,
        label: 'Mis Clientes',
        count: myCount,
        icon: Icons.person,
        color: const Color(0xFFD4A84B),
      ));
    } else {
      // Admin/encargada ve tabs de todas las recepcionistas
      // Usar la misma lógica de filtro que _filteredClients para contar
      final byReceptionist = <String, _TabInfo>{};
      for (final c in _clients.where((c) => !c.isUnassigned)) {
        final key = c.bookedById ?? '';
        if (key.isEmpty) continue;
        if (byReceptionist.containsKey(key)) {
          byReceptionist[key] = _TabInfo(
            id: key,
            label: byReceptionist[key]!.label,
            count: byReceptionist[key]!.count + 1,
            icon: Icons.person,
            color: const Color(0xFFD4A84B),
          );
        } else {
          final name = _getReceptionistName(key);
          final displayName = name.isNotEmpty ? name.split(' ').first : (c.bookedByName?.split(' ').first ?? 'Recep.');
          byReceptionist[key] = _TabInfo(
            id: key,
            label: displayName,
            count: 1,
            icon: Icons.person,
            color: const Color(0xFFD4A84B),
          );
        }
      }
      tabs.addAll(byReceptionist.values);
    }

    return tabs;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _loadData();
    }
  }

  /// Asigna recepcionista actualizando el campo nota de la reservación
  Future<void> _assignReceptionist(ClientTrackingModel client, EmployeeModel receptionist) async {
    try {
      EasyLoading.show(status: 'Asignando...');

      // Leer la reservación actual para obtener la nota
      final getResp = await _api.get('reservations/${client.reservationId}');
      if (!getResp.success) {
        EasyLoading.showError('Error al leer reservación');
        return;
      }

      final reservation = getResp.data['reservation'] ?? getResp.data;
      String currentNota = reservation['nota']?.toString() ?? '';

      // Parsear assignments existentes del nota
      Map<String, dynamic> assignments = {};
      if (currentNota.contains('|||')) {
        try {
          final jsonPart = currentNota.split('|||').last.trim();
          assignments = jsonDecode(jsonPart);
        } catch (_) {}
        // Limpiar la parte JSON del nota
        currentNota = currentNota.split('|||').first.trim();
      }

      // Actualizar bookedById
      assignments['b'] = receptionist.id.toString();
      assignments['bookedById'] = receptionist.id.toString();

      // Reconstruir nota
      final newNota = currentNota.isEmpty
          ? '||| ${jsonEncode(assignments)}'
          : '$currentNota ||| ${jsonEncode(assignments)}';

      // Guardar
      final putResp = await _api.put('reservations/${client.reservationId}', {'nota': newNota});

      if (putResp.success) {
        EasyLoading.showSuccess('Asignada a ${receptionist.name} ${receptionist.lastName}');
        _loadData();
      } else {
        EasyLoading.showError(putResp.message ?? 'Error al asignar');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: kWhite,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.track_changes, color: Color(0xFFD4A84B), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isLinkedUser && _currentUserName != null) ...[
                                    Text(
                                      _currentUserName!,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                                    ),
                                    Text(
                                      'Dpto. de Recepción',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    _isLinkedUser ? 'Mis Clientes' : 'Seguimiento de Clientes',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    _isLinkedUser
                                        ? '${_filteredClients.length} clientes asignados'
                                        : '${_clients.length} clientes en el período',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text(
                                isMobile
                                    ? '${DateFormat('dd/MM').format(_dateFrom)} - ${DateFormat('dd/MM').format(_dateTo)}'
                                    : '${DateFormat('dd MMM').format(_dateFrom)} - ${DateFormat('dd MMM yyyy').format(_dateTo)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _selectDateRange,
                            ),
                            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refrescar', onPressed: _loadData),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: kNeutral300),

                      // Tabs de recepcionistas
                      if (_tabs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ..._tabs.map((tab) {
                                  final isActive = _activeFilter == tab.id && !_showCompleted;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon(tab.icon, size: 16, color: isActive ? Colors.white : tab.color),
                                      label: Text(
                                        '${tab.label} (${tab.count})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                          color: isActive ? Colors.white : kTitleColor,
                                        ),
                                      ),
                                      selected: isActive,
                                      selectedColor: tab.color,
                                      backgroundColor: kNeutral100,
                                      side: BorderSide(color: isActive ? tab.color : kNeutral300),
                                      onSelected: (_) => setState(() {
                                        _activeFilter = tab.id;
                                        _stageFilter = 'todos';
                                        _showCompleted = false;
                                      }),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }),
                                // Tab Completado (solo para recepcionistas con clientes)
                                if (_isLinkedUser || _canAssign)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon(Icons.check_circle, size: 16, color: _showCompleted ? Colors.white : Colors.green),
                                      label: Text(
                                        'Completado (${_clients.where((c) => c.isFullyCompleted && !c.isUnassigned).length})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _showCompleted ? FontWeight.w600 : FontWeight.w400,
                                          color: _showCompleted ? Colors.white : kTitleColor,
                                        ),
                                      ),
                                      selected: _showCompleted,
                                      selectedColor: Colors.green,
                                      backgroundColor: kNeutral100,
                                      side: BorderSide(color: _showCompleted ? Colors.green : kNeutral300),
                                      onSelected: (_) => setState(() {
                                        _showCompleted = !_showCompleted;
                                        if (_showCompleted) _stageFilter = 'todos';
                                      }),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                // Botón configuración colores (solo admin)
                                if (_isAdmin)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: IconButton(
                                      icon: const Icon(Icons.palette, size: 20),
                                      color: const Color(0xFFD4A84B),
                                      tooltip: 'Configurar colores',
                                      onPressed: _showColorSettingsDialog,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      // Vista según el estado
                      if (_showCompleted)
                        // COMPLETADOS: lista simple de clientes terminados
                        _buildCompletedList()
                      else if (_isLinkedUser && _activeFilter != null)
                        // RECEPCIONISTA: Vista Kanban por columnas
                        KanbanBoard(
                          clients: _filteredClients.where((c) => !c.isFullyCompleted).toList(),
                          customColors: _kanbanColors,
                        )
                      else ...[
                        // ADMIN/ENCARGADA: Filtros de etapa + lista
                        if (_activeFilter != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildStageChip('todos', 'Todos', Icons.list),
                                  _buildStageChip('seguimiento', 'Seguimiento', Icons.visibility),
                                  _buildStageChip('maquillaje', 'Maquillaje', Icons.face_retouching_natural),
                                  _buildStageChip('sesion', 'Sesión', Icons.camera_alt),
                                  _buildStageChip('edicion', 'Edición', Icons.edit),
                                  _buildStageChip('impresion', 'Impresión', Icons.print),
                                  _buildStageChip('completado', 'Completado', Icons.check_circle),
                                ],
                              ),
                            ),
                          ),

                        // Lista de clientes
                        if (_filteredClients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  _activeFilter == null ? 'No hay clientes sin asignar' : 'No hay clientes en este filtro',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            itemCount: _filteredClients.length,
                            itemBuilder: (_, i) {
                              final client = _filteredClients[i];
                              return ClientJourneyCard(
                                client: client,
                                onAssign: (client.isUnassigned && _canAssign)
                                    ? () => _showAssignDialog(client)
                                    : null,
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStageChip(String value, String label, IconData icon) {
    final isActive = _stageFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey.shade600),
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : Colors.grey.shade700)),
        selected: isActive,
        selectedColor: Colors.deepPurple,
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => setState(() => _stageFilter = isActive ? 'todos' : value),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }

  Future<void> _showAssignDialog(ClientTrackingModel client) async {
    if (_receptionists.isEmpty) {
      toast('No hay recepcionistas disponibles');
      return;
    }

    final selected = await showDialog<EmployeeModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asignar Recepcionista', style: TextStyle(fontSize: 18)),
            Text(client.customerName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _receptionists.length,
            itemBuilder: (_, i) {
              final emp = _receptionists[i];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFD4A84B).withValues(alpha: 0.15),
                  child: Text(emp.name[0], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD4A84B))),
                ),
                title: Text('${emp.name} ${emp.lastName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(emp.designation, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                onTap: () => Navigator.pop(ctx, emp),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );

    if (selected != null) {
      await _assignReceptionist(client, selected);
    }
  }

  /// Lista de clientes completados
  Widget _buildCompletedList() {
    final completed = _clients.where((c) => c.isFullyCompleted && !c.isUnassigned).toList();
    if (completed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No hay clientes completados en este período', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: completed.length,
      itemBuilder: (_, i) => ClientJourneyCard(client: completed[i]),
    );
  }

  /// Modal de configuración de colores del Kanban (solo admin)
  Future<void> _showColorSettingsDialog() async {
    final stages = [
      {'key': 'seguimiento', 'label': 'Seguimiento'},
      {'key': 'maquillaje', 'label': 'Maquillaje'},
      {'key': 'sesion', 'label': 'Sesión'},
      {'key': 'edicion', 'label': 'Edición'},
      {'key': 'impresion', 'label': 'Impresión'},
    ];

    final presetColors = [
      '#6366F1', '#EC4899', '#F59E0B', '#3B82F6', '#10B981',
      '#EF4444', '#8B5CF6', '#14B8A6', '#F97316', '#06B6D4',
      '#D4A84B', '#84CC16', '#E11D48', '#7C3AED', '#0EA5E9',
    ];

    // Copia local de colores
    final localColors = Map<String, String>.from(_kanbanColors);
    // Defaults si no existen
    final defaults = {'seguimiento': '#6366F1', 'maquillaje': '#EC4899', 'sesion': '#F59E0B', 'edicion': '#3B82F6', 'impresion': '#10B981'};
    for (final s in stages) {
      localColors.putIfAbsent(s['key']!, () => defaults[s['key']!] ?? '#6366F1');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.palette, color: Color(0xFFD4A84B), size: 24),
                  SizedBox(width: 10),
                  Text('Colores del Pipeline', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: stages.map((s) {
                    final key = s['key']!;
                    final label = s['label']!;
                    final currentHex = localColors[key] ?? '#6366F1';
                    final currentColor = _hexToColor(currentHex);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: currentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: presetColors.map((hex) {
                                  final isSelected = currentHex == hex;
                                  return GestureDetector(
                                    onTap: () => setDialogState(() => localColors[key] = hex),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: _hexToColor(hex),
                                        borderRadius: BorderRadius.circular(6),
                                        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                                      ),
                                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A84B), foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // Guardar colores en el backend
      EasyLoading.show(status: 'Guardando...');
      final colors = localColors.entries.map((e) => {
        'stage_key': e.key,
        'color_hex': e.value,
        'label': stages.firstWhere((s) => s['key'] == e.key, orElse: () => {'label': e.key})['label'],
      }).toList();

      final resp = await _api.put('hrm/kanban-colors', {'colors': colors});
      EasyLoading.dismiss();

      if (resp.success) {
        EasyLoading.showSuccess('Colores guardados');
        setState(() => _kanbanColors = localColors);
      } else {
        EasyLoading.showError('Error al guardar');
      }
    }
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _TabInfo {
  final String? id;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const _TabInfo({required this.id, required this.label, required this.count, required this.icon, required this.color});
}
