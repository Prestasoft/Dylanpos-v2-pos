import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/currency.dart';

import '../../../model/reservation_model.dart';
import '../../../services/api_service.dart';
import '../employees/model/employee_model.dart';
import '../employees/repo/employee_repo.dart';
import 'widgets/task_theme.dart';

class EfficiencyReportsScreen extends StatefulWidget {
  const EfficiencyReportsScreen({Key? key}) : super(key: key);

  @override
  State<EfficiencyReportsScreen> createState() => _EfficiencyReportsScreenState();
}

class _EfficiencyReportsScreenState extends State<EfficiencyReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  List<ReservationModel> _reservations = [];
  Map<String, String> _employeeNames = {}; // mapa id -> nombre

  // Estadísticas calculadas
  Map<String, int> _fotografosStats = {};
  Map<String, int> _maquillistasStats = {};
  Map<String, int> _editoresStats = {};
  Map<String, int> _vendedoresStats = {};
  Map<String, int> _canalesStats = {};
  Map<String, int> _redesStats = {};

  // Scope: si es encargado, solo muestra su departamento
  bool _isScoped = false;
  String _scopedSlot = ''; // fotografo, maquillista, editor, vendedor
  Set<String> _scopedEmployeeIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Filtra stats dejando solo los empleados del departamento del encargado
  Map<String, int> _filterByEmployees(Map<String, int> stats) {
    if (_scopedEmployeeIds.isEmpty) return stats;
    return Map.fromEntries(
      stats.entries.where((e) => _scopedEmployeeIds.contains(e.key)),
    );
  }

  String _detectSlot(String designation) {
    final d = designation.toLowerCase();
    if (d.contains('foto') || d.contains('photo') || d.contains('camer')) return 'fotografo';
    if (d.contains('maquil') || d.contains('makeup') || d.contains('belleza')) return 'maquillista';
    if (d.contains('edic') || d.contains('editor') || d.contains('post')) return 'editor';
    return 'vendedor';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar Empleados
      final repo = EmployeeRepository();
      final employees = await repo.getActiveEmployees();
      Map<String, String> namesMap = {};
      for (var e in employees) {
        namesMap[e.id.toString()] = '${e.name} ${e.lastName}';
      }

      // Detectar scope del encargado
      final user = ApiService().currentUser;
      final role = user?['role']?.toString() ?? '';
      final scopedDesId = user?['scoped_designation_id'];
      if (role == 'department_head' && scopedDesId != null) {
        _isScoped = true;
        // Buscar nombre de la designación para detectar el slot
        final scopedDesNum = scopedDesId is num ? scopedDesId : num.tryParse(scopedDesId.toString());
        final matchingEmp = employees.where((e) => e.designationId == scopedDesNum).toList();
        _scopedEmployeeIds = matchingEmp.map((e) => e.id.toString()).toSet();
        if (matchingEmp.isNotEmpty) {
          _scopedSlot = _detectSlot(matchingEmp.first.designation);
        }
      }

      // 2. Cargar Reservaciones usando ApiService directamente para rango
      final api = ApiService();
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      
      final response = await api.get('reservations', queryParams: {
        'start_date': startStr,
        'end_date': endStr,
        'limit': '5000',
      });

      List<ReservationModel> loadedReservations = [];
      if (response.success && response.data != null) {
        final rawList = response.data['reservations'] as List<dynamic>? ?? [];
        loadedReservations = rawList.map((item) {
          final data = Map<String, dynamic>.from(item as Map);
          final id = data['id']?.toString() ?? data['reservation_id']?.toString() ?? '';
          return ReservationModel.fromMap(data, id);
        }).toList();
      }

      // 3. Procesar Estadísticas
      _processStats(loadedReservations);

      setState(() {
        _employeeNames = namesMap;
        _reservations = loadedReservations;
        _isLoading = false;
      });
    } catch (e) {
      toast('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _processStats(List<ReservationModel> list) {
    _fotografosStats.clear();
    _maquillistasStats.clear();
    _editoresStats.clear();
    _vendedoresStats.clear();
    _canalesStats.clear();
    _redesStats.clear();

    for (var r in list) {
      if (r.estado == 'cancelado') continue;
      
      final st = r.assignments;
      
      // Incrementar contadores si existe la asignación
      if (st.fotografoId != null) {
        _fotografosStats[st.fotografoId!] = (_fotografosStats[st.fotografoId!] ?? 0) + 1;
      }
      if (st.maquillistaId != null) {
        _maquillistasStats[st.maquillistaId!] = (_maquillistasStats[st.maquillistaId!] ?? 0) + 1;
      }
      if (st.editorId != null) {
        _editoresStats[st.editorId!] = (_editoresStats[st.editorId!] ?? 0) + 1;
      }
      if (st.bookedById != null) {
        _vendedoresStats[st.bookedById!] = (_vendedoresStats[st.bookedById!] ?? 0) + 1;
      }
      if (st.contactChannel != null) {
        _canalesStats[st.contactChannel!] = (_canalesStats[st.contactChannel!] ?? 0) + 1;
      }
      if (st.socialNetwork != null) {
        _redesStats[st.socialNetwork!] = (_redesStats[st.socialNetwork!] ?? 0) + 1;
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData(); // Recargar datos
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        title: Text('Performance KPIs', style: TextStyle(color: tc.appBarTitle)),
        backgroundColor: tc.appBar,
        iconTheme: tc.appBarIconTheme,
        elevation: 0.5,
        actions: [
          const TaskThemeToggle(),
          TextButton.icon(
            icon: const Icon(Icons.date_range, color: Colors.blue),
            label: Text(
              '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
              style: const TextStyle(color: Colors.blue),
            ),
            onPressed: _selectDateRange,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(),
                  const SizedBox(height: 24),
                  
                  // Si es encargado, solo muestra la sección de su departamento
                  if (!_isScoped || _scopedSlot == 'fotografo')
                    _buildRankCard('Fotógrafos (Sesiones)', _isScoped ? _filterByEmployees(_fotografosStats) : _fotografosStats, Icons.camera_alt, Colors.blue),
                  if (!_isScoped || _scopedSlot == 'fotografo') const SizedBox(height: 16),

                  if (!_isScoped || _scopedSlot == 'maquillista')
                    _buildRankCard('Maquillistas (Trabajos)', _isScoped ? _filterByEmployees(_maquillistasStats) : _maquillistasStats, Icons.face_retouching_natural, Colors.pink),
                  if (!_isScoped || _scopedSlot == 'maquillista') const SizedBox(height: 16),

                  if (!_isScoped || _scopedSlot == 'editor')
                    _buildRankCard('Editores (Procesado)', _isScoped ? _filterByEmployees(_editoresStats) : _editoresStats, Icons.edit, Colors.orange),
                  if (!_isScoped || _scopedSlot == 'editor') const SizedBox(height: 16),

                  if (!_isScoped || _scopedSlot == 'vendedor')
                    _buildRankCard('Sellers (Cierres)', _isScoped ? _filterByEmployees(_vendedoresStats) : _vendedoresStats, Icons.headset_mic, Colors.purple),
                  if (!_isScoped || _scopedSlot == 'vendedor') const SizedBox(height: 16),

                  if (!_isScoped) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRankCard('Canales de Contacto', _canalesStats, Icons.share, Colors.green, resolveNames: false)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRankCard('Distribución Redes', _redesStats, Icons.thumb_up, Colors.indigo, resolveNames: false)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    final tc = TaskColors.read(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: tc.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatIndicator('Total Reservas', _reservations.length.toString(), Icons.event),
          _buildStatIndicator('Con Asignación', _reservations.where((r) => r.assignments.fotografoId != null || r.assignments.bookedById != null).length.toString(), Icons.check_circle_outline),
          _buildStatIndicator('Cierres Redes', _redesStats.values.fold<int>(0, (a, b) => a + b).toString(), Icons.campaign),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(String label, String value, IconData icon) {
    final tc = TaskColors.read(context);
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue[700]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tc.textPrimary)),
        Text(label, style: TextStyle(color: tc.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildRankCard(String title, Map<String, int> statsMap, IconData icon, Color color, {bool resolveNames = true}) {
    // Sort logic
    var sortedKeys = statsMap.keys.toList(growable: false)
      ..sort((k1, k2) => statsMap[k2]!.compareTo(statsMap[k1]!));

    final tc = TaskColors.read(context);
    return Card(
      elevation: 0,
      color: tc.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tc.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: tc.textPrimary)),
              ],
            ),
            Divider(height: 24, color: tc.divider),
            if (sortedKeys.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Sin datos', style: TextStyle(color: tc.textHint))),
              )
            else
              ...sortedKeys.map((key) {
                final count = statsMap[key]!;
                final maxCount = statsMap[sortedKeys.first]!;
                final displayName = resolveNames ? (_employeeNames[key] ?? 'Inactivo ($key)') : key;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(displayName, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: tc.textPrimary))),
                          Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: tc.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
