import 'package:flutter/material.dart';
import '../../assignments/widgets/date_filter_bar.dart';
import '../../assignments/widgets/task_theme.dart';
import '../client_tracking_model.dart';
import '../client_tracking_repo.dart';
import 'package:intl/intl.dart';

import '../../employees/model/employee_model.dart';
import '../../employees/repo/employee_repo.dart';

/// Vista "Mi Equipo" optimizada para encargadas de recepción.
/// Layout: Recepcionistas compactas (izq) + Ranking Top 5 (der)
class ReceptionTeamView extends StatefulWidget {
  const ReceptionTeamView({super.key});

  @override
  State<ReceptionTeamView> createState() => _ReceptionTeamViewState();
}

class _ReceptionTeamViewState extends State<ReceptionTeamView> {
  bool _loading = true;
  List<_ReceptionistStats> _receptionists = [];
  int _totalPendiente = 0;
  int _totalEnProceso = 0;
  int _totalHoy = 0;
  int _totalAtraso = 0;
  DateTime _dateFrom = DateTime.now();
  DateTime _dateTo = DateTime.now().add(const Duration(days: 60));
  String _dateFilter = 'rango';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final dateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final dateTo = DateFormat('yyyy-MM-dd').format(_dateTo);
      final clients = await ClientTrackingRepository().getClients(dateFrom: dateFrom, dateTo: dateTo);

      final allEmployees = await EmployeeRepository().getActiveEmployees();
      final receptionists = allEmployees.where((e) {
        final d = e.designation.toLowerCase();
        return d.contains('recepcion') || d.contains('tienda') || d.contains('vendedor');
      }).toList();

      final today = DateFormat('yyyy-MM-dd').format(now);
      final stats = <_ReceptionistStats>[];

      for (final emp in receptionists) {
        final empId = emp.id.toString();
        final myClients = clients.where((c) => c.bookedById == empId).toList();

        int pendiente = 0, enProceso = 0, hoy = 0, atraso = 0;
        for (final c in myClients) {
          final groups = c.departmentGroups;
          final resDate = c.reservationDate.split('T').first;
          final isToday = resDate == today;
          final hasTasks = groups.any((g) => g.tasks.isNotEmpty);
          final hasOverdue = groups.any((g) => g.hasOverdue);
          final hasActive = groups.any((g) => g.hasActive);

          if (isToday) hoy++;
          if (hasOverdue) {
            atraso++;
          } else if (hasActive || (hasTasks && !c.isFullyCompleted)) {
            enProceso++;
          } else if (!c.isFullyCompleted) {
            pendiente++;
          }
        }

        stats.add(_ReceptionistStats(
          employee: emp,
          totalClients: myClients.length,
          pendiente: pendiente,
          enProceso: enProceso,
          hoy: hoy,
          atraso: atraso,
        ));
      }

      // Ordenar: más clientes primero
      stats.sort((a, b) {
        if (a.atraso > 0 && b.atraso == 0) return -1;
        if (a.atraso == 0 && b.atraso > 0) return 1;
        return b.totalClients.compareTo(a.totalClients);
      });

      if (!mounted) return;
      setState(() {
        _receptionists = stats;
        _totalPendiente = stats.fold(0, (s, r) => s + r.pendiente);
        _totalEnProceso = stats.fold(0, (s, r) => s + r.enProceso);
        _totalHoy = stats.fold(0, (s, r) => s + r.hoy);
        _totalAtraso = stats.fold(0, (s, r) => s + r.atraso);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando equipo recepción: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        backgroundColor: tc.appBar,
        elevation: 0.5,
        iconTheme: tc.appBarIconTheme,
        title: Text('Mi Equipo', style: TextStyle(color: tc.appBarTitle, fontSize: 18)),
        actions: [
          const TaskThemeToggle(),
          IconButton(icon: Icon(Icons.refresh, color: tc.appBarIcon), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Filtro de fechas
                  DateFilterBar(
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    activeFilter: _dateFilter,
                    onChanged: (result) {
                      setState(() {
                        _dateFrom = result.from;
                        _dateTo = result.to;
                        _dateFilter = result.filter;
                      });
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 8),

                  // KPIs compactos
                  _buildKpiRow(tc),
                  const SizedBox(height: 12),

                  // Layout: Recepcionistas + Ranking
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildTeamList(tc)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildRanking(tc)),
                      ],
                    )
                  else ...[
                    _buildTeamList(tc),
                    const SizedBox(height: 12),
                    _buildRanking(tc),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow(TaskColors tc) {
    return Row(
      children: [
        _kpiChip('Pendiente', _totalPendiente, const Color(0xFFF59E0B), tc),
        const SizedBox(width: 6),
        _kpiChip('En Proceso', _totalEnProceso, const Color(0xFF3B82F6), tc),
        const SizedBox(width: 6),
        _kpiChip('Hoy', _totalHoy, const Color(0xFF8B5CF6), tc),
        const SizedBox(width: 6),
        _kpiChip('Atraso', _totalAtraso, const Color(0xFFEF4444), tc),
      ],
    );
  }

  Widget _kpiChip(String label, int value, Color color, TaskColors tc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: value > 0 ? color : tc.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value > 0 ? color : tc.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: value > 0 ? Colors.white : tc.textPrimary)),
            Text(label, style: TextStyle(fontSize: 9, color: value > 0 ? Colors.white.withValues(alpha: 0.85) : tc.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(TaskColors tc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recepcionistas (${_receptionists.length})', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tc.textPrimary)),
          const SizedBox(height: 10),
          ..._receptionists.map((r) => _buildCompactRow(r, tc)),
        ],
      ),
    );
  }

  Widget _buildCompactRow(_ReceptionistStats stats, TaskColors tc) {
    final hasAtraso = stats.atraso > 0;

    final row = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hasAtraso ? Colors.red.withValues(alpha: tc.isDark ? 0.1 : 0.04) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasAtraso ? Colors.red.withValues(alpha: 0.3) : tc.border.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (hasAtraso ? Colors.red : const Color(0xFFD4A84B)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              stats.employee.name.isNotEmpty ? stats.employee.name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hasAtraso ? Colors.red : const Color(0xFFD4A84B)),
            ),
          ),
          const SizedBox(width: 10),
          // Nombre
          Expanded(
            child: Text(
              stats.employee.fullName,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tc.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Stats compactos
          if (stats.totalClients > 0) ...[
            _miniStat(stats.pendiente, const Color(0xFFF59E0B), tc),
            const SizedBox(width: 3),
            _miniStat(stats.enProceso, const Color(0xFF3B82F6), tc),
            const SizedBox(width: 3),
            _miniStat(stats.hoy, const Color(0xFF8B5CF6), tc),
            const SizedBox(width: 3),
            _miniStat(stats.atraso, const Color(0xFFEF4444), tc),
          ] else
            Text('Sin clientes', style: TextStyle(fontSize: 10, color: tc.textHint)),
        ],
      ),
    );

    if (hasAtraso) return _BlinkingCard(child: row);
    return row;
  }

  Widget _miniStat(int value, Color color, TaskColors tc) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value > 0 ? color : color.withValues(alpha: tc.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: value > 0 ? Colors.white : tc.textHint),
      ),
    );
  }

  Widget _buildRanking(TaskColors tc) {
    // Top 5 por clientes gestionados
    final sorted = List<_ReceptionistStats>.from(_receptionists)
      ..sort((a, b) => b.totalClients.compareTo(a.totalClients));
    final top5 = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A84B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('Top 5 Vendedoras', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tc.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          if (top5.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: tc.textHint, fontSize: 12)))
          else
            ...top5.asMap().entries.map((entry) {
              final idx = entry.key;
              final stats = entry.value;
              final isFirst = idx == 0 && stats.totalClients > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xFFD4A84B).withValues(alpha: tc.isDark ? 0.15 : 0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isFirst ? Border.all(color: const Color(0xFFD4A84B).withValues(alpha: 0.3)) : null,
                ),
                child: Row(
                  children: [
                    // Posición
                    SizedBox(
                      width: 24,
                      child: isFirst
                          ? const Text('👑', style: TextStyle(fontSize: 16))
                          : Text('${idx + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tc.textHint), textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 8),
                    // Avatar
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (isFirst ? const Color(0xFFD4A84B) : Colors.grey).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        stats.employee.name.isNotEmpty ? stats.employee.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isFirst ? const Color(0xFFD4A84B) : tc.textHint),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nombre
                    Expanded(
                      child: Text(
                        stats.employee.fullName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                          color: tc.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Conteo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFirst ? const Color(0xFFD4A84B) : tc.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${stats.totalClients}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isFirst ? Colors.white : tc.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Text(
            'Clientes gestionados en el período',
            style: TextStyle(fontSize: 10, color: tc.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReceptionistStats {
  final EmployeeModel employee;
  final int totalClients;
  final int pendiente;
  final int enProceso;
  final int hoy;
  final int atraso;

  const _ReceptionistStats({
    required this.employee,
    required this.totalClients,
    required this.pendiente,
    required this.enProceso,
    required this.hoy,
    required this.atraso,
  });
}

class _BlinkingCard extends StatefulWidget {
  final Widget child;
  const _BlinkingCard({required this.child});

  @override
  State<_BlinkingCard> createState() => _BlinkingCardState();
}

class _BlinkingCardState extends State<_BlinkingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
