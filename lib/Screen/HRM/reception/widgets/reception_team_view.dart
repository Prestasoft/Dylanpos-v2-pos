import 'package:flutter/material.dart';
import '../../assignments/widgets/date_filter_bar.dart';
import '../../assignments/widgets/task_theme.dart';
import '../client_tracking_model.dart';
import '../client_tracking_repo.dart';
import 'package:intl/intl.dart';

import '../../employees/model/employee_model.dart';
import '../../employees/repo/employee_repo.dart';
import '../../../../services/api_service.dart';

/// Vista "Mi Equipo" personalizada para encargadas de recepción.
/// Muestra recepcionistas con sus clientes agrupados por estado.
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

      // Cargar recepcionistas
      final allEmployees = await EmployeeRepository().getActiveEmployees();
      final receptionists = allEmployees.where((e) {
        final d = e.designation.toLowerCase();
        return d.contains('recepcion') || d.contains('tienda') || d.contains('vendedor');
      }).toList();

      // Agrupar clientes por recepcionista
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

      // Ordenar: atraso primero, luego hoy, luego en proceso, luego pendiente
      stats.sort((a, b) {
        if (a.atraso > 0 && b.atraso == 0) return -1;
        if (a.atraso == 0 && b.atraso > 0) return 1;
        if (a.hoy > 0 && b.hoy == 0) return -1;
        if (a.hoy == 0 && b.hoy > 0) return 1;
        if (a.enProceso > 0 && b.enProceso == 0) return -1;
        if (a.enProceso == 0 && b.enProceso > 0) return 1;
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

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        backgroundColor: tc.appBar,
        elevation: 0.5,
        iconTheme: tc.appBarIconTheme,
        title: Text('Mi Equipo', style: TextStyle(color: tc.appBarTitle, fontSize: 18)),
        actions: [
          const TaskThemeToggle(),
          IconButton(
            icon: Icon(Icons.refresh, color: tc.appBarIcon),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DateFilterBar(
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
                  ),
                  SliverToBoxAdapter(child: _buildKpiRow(tc)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Recepcionistas (${_receptionists.length})',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tc.textPrimary),
                      ),
                    ),
                  ),
                  _receptionists.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 64, color: tc.textHint),
                                const SizedBox(height: 16),
                                Text('Sin recepcionistas', style: TextStyle(color: tc.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildReceptionistCard(_receptionists[i], tc),
                            childCount: _receptionists.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow(TaskColors tc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: tc.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _kpiItem('Pendiente', _totalPendiente, const Color(0xFFF59E0B), Icons.schedule, tc),
          _kpiDivider(tc),
          _kpiItem('En Proceso', _totalEnProceso, const Color(0xFF3B82F6), Icons.sync, tc),
          _kpiDivider(tc),
          _kpiItem('Hoy', _totalHoy, const Color(0xFF8B5CF6), Icons.today, tc),
          _kpiDivider(tc),
          _kpiItem('En Atraso', _totalAtraso, const Color(0xFFEF4444), Icons.warning_amber_rounded, tc),
        ],
      ),
    );
  }

  Widget _kpiItem(String label, int value, Color color, IconData icon, TaskColors tc) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: tc.textPrimary)),
          Text(label, style: TextStyle(fontSize: 10, color: tc.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _kpiDivider(TaskColors tc) {
    return Container(width: 1, height: 50, color: tc.divider);
  }

  Widget _buildReceptionistCard(_ReceptionistStats stats, TaskColors tc) {
    final hasAtraso = stats.atraso > 0;
    final hasLogin = stats.employee.canLogin;

    final cardWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAtraso ? Colors.red : tc.border.withValues(alpha: 0.5),
          width: hasAtraso ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasAtraso ? Colors.red.withValues(alpha: 0.15) : tc.shadow,
            blurRadius: hasAtraso ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Avatar + Nombre + Estado
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (hasAtraso ? Colors.red : const Color(0xFFD4A84B)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  stats.employee.name.isNotEmpty ? stats.employee.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasAtraso ? Colors.red : const Color(0xFFD4A84B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.employee.fullName,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tc.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!hasLogin)
                      Text('Sin acceso al sistema', style: TextStyle(fontSize: 11, color: tc.textHint)),
                  ],
                ),
              ),
              // Badge estado
              if (hasAtraso)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 14),
                      SizedBox(width: 4),
                      Text('En Atraso', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else if (stats.totalClients > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text('${stats.totalClients} clientes', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_circle_outline, color: Colors.grey, size: 14),
                      SizedBox(width: 4),
                      Text('Sin clientes', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          // Fila 2: Stats
          if (stats.totalClients > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _statChip(stats.pendiente, 'Pendiente', const Color(0xFFF59E0B), tc),
                  const SizedBox(width: 6),
                  _statChip(stats.enProceso, 'En Proceso', const Color(0xFF3B82F6), tc),
                  const SizedBox(width: 6),
                  _statChip(stats.hoy, 'Hoy', const Color(0xFF8B5CF6), tc),
                  const SizedBox(width: 6),
                  _statChip(stats.atraso, 'Atraso', const Color(0xFFEF4444), tc),
                ],
              ),
            ),
        ],
      ),
    );

    if (hasAtraso) {
      return _BlinkingCard(child: cardWidget);
    }
    return cardWidget;
  }

  Widget _statChip(int value, String label, Color color, TaskColors tc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: value > 0 ? color : color.withValues(alpha: tc.isDark ? 0.15 : 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: value > 0 ? Colors.white : tc.textHint,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: value > 0 ? Colors.white.withValues(alpha: 0.85) : tc.textHint,
              ),
            ),
          ],
        ),
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

/// Widget que hace parpadear su hijo
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
