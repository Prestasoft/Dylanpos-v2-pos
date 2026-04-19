import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../assignments/widgets/date_filter_bar.dart';
import '../../assignments/widgets/task_theme.dart';
import '../../employees/model/employee_model.dart';
import '../../employees/repo/employee_repo.dart';
import '../client_tracking_model.dart';
import '../client_tracking_repo.dart';

/// Dashboard de Rendimiento para el departamento de Recepción.
/// Muestra ranking con score, gráfico de barras y alertas.
class ReceptionPerformanceView extends StatefulWidget {
  const ReceptionPerformanceView({super.key});

  @override
  State<ReceptionPerformanceView> createState() => _ReceptionPerformanceViewState();
}

class _ReceptionPerformanceViewState extends State<ReceptionPerformanceView> {
  bool _loading = true;
  List<_RecepScore> _scores = [];
  int _totalVendidos = 0;
  int _totalGestionados = 0;
  int _totalCompletados = 0;
  int _totalAtraso = 0;
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now().add(const Duration(days: 60));
  String _dateFilter = 'rango';
  String _chartMode = 'ventas'; // ventas, gestion, score

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final dateTo = DateFormat('yyyy-MM-dd').format(_dateTo);
      final clients = await ClientTrackingRepository().getClients(dateFrom: dateFrom, dateTo: dateTo);

      final allEmployees = await EmployeeRepository().getActiveEmployees();
      final team = allEmployees.where((e) {
        final d = e.designation.toLowerCase();
        return d.contains('recepcion') || d.contains('tienda') || d.contains('vendedor') || d.contains('redes') || d.contains('recursos humanos') || d.contains('administra');
      }).toList();

      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final scores = <_RecepScore>[];

      int maxVentas = 1;
      for (final emp in team) {
        final empId = emp.id.toString();
        final myClients = clients.where((c) => c.bookedById == empId).toList();
        if (myClients.length > maxVentas) maxVentas = myClients.length;
      }

      for (final emp in team) {
        final empId = emp.id.toString();
        final myClients = clients.where((c) => c.bookedById == empId).toList();

        int gestionados = 0, completados = 0, atraso = 0;
        for (final c in myClients) {
          final groups = c.departmentGroups;
          final hasTasks = groups.any((g) => g.tasks.isNotEmpty);
          final hasOverdue = groups.any((g) => g.hasOverdue);

          if (hasTasks || c.isFullyCompleted) gestionados++;
          if (c.isFullyCompleted) completados++;
          if (hasOverdue) atraso++;
        }

        // Score: Ventas 40% + Gestión 30% + Cumplimiento 20% + Actividad 10%
        final ventasScore = maxVentas > 0 ? (myClients.length / maxVentas) * 100 : 0.0;
        final gestionScore = myClients.isNotEmpty ? (gestionados / myClients.length) * 100 : 0.0;
        final cumplimientoScore = myClients.isNotEmpty ? ((1 - (atraso / myClients.length)).clamp(0, 1)) * 100 : 100.0;
        final actividadScore = myClients.isNotEmpty ? 100.0 : 0.0;

        final totalScore = (ventasScore * 0.40 + gestionScore * 0.30 + cumplimientoScore * 0.20 + actividadScore * 0.10).round();

        scores.add(_RecepScore(
          employee: emp,
          ventas: myClients.length,
          gestionados: gestionados,
          completados: completados,
          atraso: atraso,
          score: totalScore,
          cumplimiento: myClients.isNotEmpty ? ((1 - (atraso / myClients.length)) * 100).round() : 100,
        ));
      }

      scores.sort((a, b) => b.score.compareTo(a.score));

      if (!mounted) return;
      setState(() {
        _scores = scores;
        _totalVendidos = scores.fold(0, (s, r) => s + r.ventas);
        _totalGestionados = scores.fold(0, (s, r) => s + r.gestionados);
        _totalCompletados = scores.fold(0, (s, r) => s + r.completados);
        _totalAtraso = scores.fold(0, (s, r) => s + r.atraso);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando rendimiento recepción: $e');
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
        title: Text('Rendimiento', style: TextStyle(color: tc.appBarTitle, fontSize: 18)),
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
                  DateFilterBar(
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    activeFilter: _dateFilter,
                    onChanged: (result) {
                      setState(() { _dateFrom = result.from; _dateTo = result.to; _dateFilter = result.filter; });
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildKpis(tc),
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRanking(tc)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildChart(tc)),
                      ],
                    )
                  else ...[
                    _buildRanking(tc),
                    const SizedBox(height: 12),
                    _buildChart(tc),
                  ],
                  const SizedBox(height: 12),
                  _buildAlerts(tc),
                ],
              ),
            ),
    );
  }

  Widget _buildKpis(TaskColors tc) {
    return Row(
      children: [
        _kpi('Vendidos', _totalVendidos, const Color(0xFFD4A84B), Icons.shopping_bag, tc),
        const SizedBox(width: 6),
        _kpi('Gestionados', _totalGestionados, const Color(0xFF3B82F6), Icons.sync, tc),
        const SizedBox(width: 6),
        _kpi('Completados', _totalCompletados, const Color(0xFF10B981), Icons.check_circle, tc),
        const SizedBox(width: 6),
        _kpi('Atraso', _totalAtraso, const Color(0xFFEF4444), Icons.warning_amber, tc),
      ],
    );
  }

  Widget _kpi(String label, int value, Color color, IconData icon, TaskColors tc) {
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
            Icon(icon, size: 18, color: value > 0 ? Colors.white : tc.textHint),
            const SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: value > 0 ? Colors.white : tc.textPrimary)),
            Text(label, style: TextStyle(fontSize: 9, color: value > 0 ? Colors.white.withValues(alpha: 0.85) : tc.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildRanking(TaskColors tc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tc.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: tc.border.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('🏆', style: TextStyle(fontSize: 18)), SizedBox(width: 6), Text('Ranking del Equipo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))]),
          const SizedBox(height: 12),
          if (_scores.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: tc.textHint)))
          else
            ..._scores.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final medal = idx == 0 ? '🥇' : idx == 1 ? '🥈' : idx == 2 ? '🥉' : '${idx + 1}';
              final isTop = idx < 3 && s.score > 0;
              final scoreColor = s.score >= 80 ? Colors.green : s.score >= 50 ? Colors.orange : Colors.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isTop ? const Color(0xFFD4A84B).withValues(alpha: tc.isDark ? 0.1 : 0.04) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isTop ? Border.all(color: const Color(0xFFD4A84B).withValues(alpha: 0.3)) : null,
                ),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Text(medal, style: TextStyle(fontSize: idx < 3 ? 18 : 13), textAlign: TextAlign.center)),
                    const SizedBox(width: 8),
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: const Color(0xFFD4A84B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text(s.employee.name.isNotEmpty ? s.employee.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.employee.fullName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tc.textPrimary), overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Text('V:${s.ventas}', style: TextStyle(fontSize: 9, color: tc.textHint)),
                              const SizedBox(width: 6),
                              Text('G:${s.gestionados}', style: TextStyle(fontSize: 9, color: tc.textHint)),
                              const SizedBox(width: 6),
                              if (s.atraso > 0) Text('⚠${s.atraso}', style: const TextStyle(fontSize: 9, color: Colors.red)),
                              if (s.atraso == 0) Text('✅${s.cumplimiento}%', style: const TextStyle(fontSize: 9, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Score
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: scoreColor.withValues(alpha: 0.12), border: Border.all(color: scoreColor, width: 2)),
                      alignment: Alignment.center,
                      child: Text('${s.score}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: scoreColor)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildChart(TaskColors tc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tc.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: tc.border.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(child: Text('Comparativa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tc.textPrimary))),
            ],
          ),
          const SizedBox(height: 8),
          // Tabs
          Row(
            children: [
              _chartTab('Ventas', 'ventas', tc),
              const SizedBox(width: 4),
              _chartTab('Gestión', 'gestion', tc),
              const SizedBox(width: 4),
              _chartTab('Score', 'score', tc),
            ],
          ),
          const SizedBox(height: 14),
          // Barras
          ..._scores.take(7).map((s) {
            final value = _chartMode == 'ventas' ? s.ventas : _chartMode == 'gestion' ? s.gestionados : s.score;
            final maxVal = _scores.isEmpty ? 1 : _scores.map((x) => _chartMode == 'ventas' ? x.ventas : _chartMode == 'gestion' ? x.gestionados : x.score).reduce(max);
            final pct = maxVal > 0 ? value / maxVal : 0.0;
            final barColor = _chartMode == 'score'
                ? (value >= 80 ? Colors.green : value >= 50 ? Colors.orange : Colors.red)
                : const Color(0xFFD4A84B);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 70, child: Text(s.employee.name.split(' ').first, style: TextStyle(fontSize: 10, color: tc.textSecondary), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 20, decoration: BoxDecoration(color: tc.isDark ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.02, 1.0),
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 6),
                            child: Text('$value', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chartTab(String label, String key, TaskColors tc) {
    final isActive = _chartMode == key;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4A84B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? const Color(0xFFD4A84B) : tc.border.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? Colors.white : tc.textHint)),
      ),
    );
  }

  Widget _buildAlerts(TaskColors tc) {
    final alerts = <Widget>[];

    for (final s in _scores) {
      if (s.atraso > 0) {
        alerts.add(_alertRow('🔴', '${s.employee.name} tiene ${s.atraso} cliente${s.atraso > 1 ? 's' : ''} en atraso', Colors.red, tc));
      }
    }
    for (final s in _scores) {
      if (s.ventas == 0) {
        alerts.add(_alertRow('🟡', '${s.employee.name}: sin clientes asignados en el período', Colors.orange, tc));
      }
    }
    for (final s in _scores) {
      if (s.cumplimiento == 100 && s.ventas > 0) {
        alerts.add(_alertRow('🟢', '${s.employee.name}: 100% cumplimiento — excelente', Colors.green, tc));
      }
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tc.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: tc.border.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alertas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tc.textPrimary)),
          const SizedBox(height: 8),
          ...alerts,
        ],
      ),
    );
  }

  Widget _alertRow(String emoji, String text, Color color, TaskColors tc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: tc.textSecondary))),
        ],
      ),
    );
  }
}

class _RecepScore {
  final EmployeeModel employee;
  final int ventas;
  final int gestionados;
  final int completados;
  final int atraso;
  final int score;
  final int cumplimiento;

  const _RecepScore({
    required this.employee,
    required this.ventas,
    required this.gestionados,
    required this.completados,
    required this.atraso,
    required this.score,
    required this.cumplimiento,
  });
}
