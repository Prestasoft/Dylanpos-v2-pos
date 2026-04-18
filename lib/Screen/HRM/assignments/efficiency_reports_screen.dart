import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Repository/task_repo.dart';
import '../../../services/api_service.dart';
import 'widgets/task_theme.dart';

class EfficiencyReportsScreen extends StatefulWidget {
  const EfficiencyReportsScreen({Key? key}) : super(key: key);

  @override
  State<EfficiencyReportsScreen> createState() => _EfficiencyReportsScreenState();
}

class _EfficiencyReportsScreenState extends State<EfficiencyReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _loading = true;
  Map<String, dynamic> _data = {};
  num? _scopedDesignationId;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadScope();
    _loadData();
  }

  void _loadScope() {
    final user = ApiService().currentUser;
    final scope = user?['scoped_designation_id'];
    if (scope is num) _scopedDesignationId = scope;
    if (scope is String) _scopedDesignationId = num.tryParse(scope);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await TaskRepository().getPerformance(
      dateFrom: DateFormat('yyyy-MM-dd').format(_startDate),
      dateTo: DateFormat('yyyy-MM-dd').format(_endDate),
      designationId: _scopedDesignationId,
    );
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    final employees = (_data['employees'] as List<dynamic>?) ?? [];
    final totals = (_data['totals'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        backgroundColor: tc.appBar,
        elevation: 0.5,
        iconTheme: tc.appBarIconTheme,
        title: Text('Rendimiento', style: TextStyle(color: tc.appBarTitle, fontSize: 18)),
        actions: [
          const TaskThemeToggle(),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
            onPressed: _pickDateRange,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Período
                  Text(
                    '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                    style: TextStyle(fontSize: 12, color: tc.textHint),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // KPIs Header
                  _buildKpiRow(totals, tc),
                  const SizedBox(height: 20),

                  // Ranking
                  if (employees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 64, color: tc.textHint),
                          const SizedBox(height: 12),
                          Text('Sin datos de rendimiento en este período',
                              style: TextStyle(color: tc.textSecondary, fontSize: 14)),
                        ],
                      ),
                    )
                  else ...[
                    Text('Ranking de Equipo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: tc.textPrimary)),
                    const SizedBox(height: 12),
                    ...List.generate(employees.length, (i) {
                      final emp = Map<String, dynamic>.from(employees[i]);
                      return _buildEmployeeCard(emp, i, tc);
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> totals, TaskColors tc) {
    final completed = totals['total_completed'] ?? 0;
    final complianceRate = ((totals['compliance_rate'] ?? 0) * 100).toInt();
    final avgMin = totals['avg_minutes'] ?? 0;
    final overdue = totals['total_overdue'] ?? 0;

    return Row(
      children: [
        _kpiCard('Realizados', '$completed', Icons.check_circle, const Color(0xFF10B981), tc),
        const SizedBox(width: 8),
        _kpiCard('Cumplimiento', '$complianceRate%', Icons.verified, const Color(0xFF3B82F6), tc),
        const SizedBox(width: 8),
        _kpiCard('Promedio', '${avgMin}min', Icons.speed, const Color(0xFFF59E0B), tc),
        const SizedBox(width: 8),
        _kpiCard('Vencidos', '$overdue', Icons.warning_amber, const Color(0xFFEF4444), tc),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, TaskColors tc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tc.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tc.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: tc.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp, int index, TaskColors tc) {
    final isFirst = index == 0 && (emp['tasks_completed'] ?? 0) > 0;
    final name = emp['employee_name'] ?? 'Desconocido';
    final photo = emp['employee_photo'];
    final completed = emp['tasks_completed'] ?? 0;
    final complianceRate = ((emp['compliance_rate'] ?? 0) * 100).toInt();
    final avgMin = emp['avg_completion_minutes'] ?? 0;
    final bestMin = emp['best_time_minutes'];
    final slaMin = emp['sla_minutes'] ?? 0;
    final overdue = emp['overdue_count'] ?? 0;
    final isExpanded = _expandedIndex == index;
    final isRecord = avgMin > 0 && slaMin > 0 && avgMin < slaMin;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst ? const Color(0xFFD4A84B).withValues(alpha: 0.5) : tc.border.withValues(alpha: 0.3),
          width: isFirst ? 2 : 1,
        ),
        boxShadow: [
          if (isFirst)
            BoxShadow(color: const Color(0xFFD4A84B).withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Card principal
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Posición
                  SizedBox(
                    width: 28,
                    child: isFirst
                        ? const Text('👑', style: TextStyle(fontSize: 20), textAlign: TextAlign.center)
                        : Text('${index + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc.textHint), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 10),
                  // Foto
                  _buildPhoto(photo, name, 42),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tc.textPrimary), overflow: TextOverflow.ellipsis),
                            ),
                            if (emp['designation'] != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tc.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(emp['designation'].toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: tc.textSecondary)),
                              ),
                            ],
                            if (isRecord) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A84B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('⚡ Rápida', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B))),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Métricas en fila
                        Row(
                          children: [
                            _metricChip('$completed', 'hechos', const Color(0xFF10B981), tc),
                            const SizedBox(width: 6),
                            _metricChip('$complianceRate%', 'SLA', complianceRate >= 80 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444), tc),
                            const SizedBox(width: 6),
                            _metricChip('${avgMin}m', 'prom.', const Color(0xFFF59E0B), tc),
                            if (bestMin != null) ...[
                              const SizedBox(width: 6),
                              _metricChip('${bestMin}m', 'mejor', const Color(0xFF8B5CF6), tc),
                            ],
                            if (overdue > 0) ...[
                              const SizedBox(width: 6),
                              _metricChip('$overdue', 'venc.', const Color(0xFFEF4444), tc),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Barra de cumplimiento circular
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (complianceRate / 100).clamp(0.0, 1.0),
                          strokeWidth: 4,
                          backgroundColor: tc.progressBg,
                          valueColor: AlwaysStoppedAnimation(complianceRate >= 80 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        ),
                        Text('$complianceRate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tc.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: tc.textHint, size: 20),
                ],
              ),
            ),
          ),

          // Detalle expandible: lista de clientes
          if (isExpanded) ...[
            Divider(height: 1, color: tc.border.withValues(alpha: 0.3)),
            _buildClientsList(emp, tc),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(String value, String label, Color color, TaskColors tc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tc.isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildClientsList(Map<String, dynamic> emp, TaskColors tc) {
    final clients = (emp['clients'] as List<dynamic>?) ?? [];
    if (clients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Sin clientes en el período', style: TextStyle(color: tc.textHint, fontSize: 12)),
      );
    }

    // Agrupar por cliente: si el mismo cliente tiene múltiples maquillajes, mostrar como uno
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in clients) {
      final client = Map<String, dynamic>.from(c);
      final name = client['customer_name'] ?? 'Sin nombre';
      grouped.putIfAbsent(name, () => []).add(client);
    }
    final uniqueClients = grouped.entries.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clientes atendidos (${uniqueClients.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tc.textSecondary)),
          const SizedBox(height: 8),
          ...uniqueClients.map((entry) {
            final customerName = entry.key;
            final tasks = entry.value;
            final maqCount = tasks.length;
            // Usar el peor resultado: si alguno fue tarde, marcar como tarde
            final allOnTime = tasks.every((t) => t['on_time'] == true);
            // Sumar duración total
            int totalDuration = 0;
            for (final t in tasks) {
              totalDuration += (t['duration_minutes'] as int?) ?? 0;
            }
            final lastCompleted = tasks.isNotEmpty && tasks.first['completed_at'] != null
                ? DateTime.tryParse(tasks.first['completed_at'].toString())
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: allOnTime
                    ? Colors.green.withValues(alpha: tc.isDark ? 0.08 : 0.04)
                    : Colors.red.withValues(alpha: tc.isDark ? 0.08 : 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (allOnTime ? Colors.green : Colors.red).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del cliente
                  Row(
                    children: [
                      Icon(allOnTime ? Icons.check_circle : Icons.cancel, size: 16, color: allOnTime ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(child: Text(customerName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tc.textPrimary), overflow: TextOverflow.ellipsis)),
                            if (maqCount > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFD4A84B).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                child: Text('x$maqCount maq.', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B))),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (totalDuration > 0)
                        Text('Total: ${totalDuration}min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tc.textSecondary)),
                    ],
                  ),
                  // Detalle de cada maquillaje
                  ...tasks.asMap().entries.map((taskEntry) {
                    final idx = taskEntry.key;
                    final t = taskEntry.value;
                    final tStarted = t['started_at'] != null ? DateTime.tryParse(t['started_at'].toString()) : null;
                    final tCompleted = t['completed_at'] != null ? DateTime.tryParse(t['completed_at'].toString()) : null;
                    final tDuration = t['duration_minutes'] as int?;
                    final tOnTime = t['on_time'] == true;

                    return Padding(
                      padding: const EdgeInsets.only(top: 4, left: 24),
                      child: Row(
                        children: [
                          Icon(tOnTime ? Icons.check : Icons.close, size: 12, color: tOnTime ? Colors.green.shade400 : Colors.red.shade400),
                          const SizedBox(width: 6),
                          Text(
                            maqCount > 1 ? '${emp['designation'] ?? 'Tarea'} ${idx + 1}' : (emp['designation']?.toString() ?? 'Tarea'),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: tc.textHint),
                          ),
                          const SizedBox(width: 8),
                          if (tStarted != null)
                            Text('${DateFormat('HH:mm').format(tStarted)}', style: TextStyle(fontSize: 10, color: tc.textSecondary)),
                          if (tStarted != null && tCompleted != null)
                            Text(' → ${DateFormat('HH:mm').format(tCompleted)}', style: TextStyle(fontSize: 10, color: tc.textSecondary)),
                          const Spacer(),
                          if (tDuration != null && tDuration > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (tOnTime ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${tDuration}min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tOnTime ? Colors.green : Colors.red)),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhoto(dynamic photoData, String name, double size) {
    if (photoData != null && photoData.toString().isNotEmpty) {
      try {
        String base64Str = photoData.toString();
        if (base64Str.contains(',')) base64Str = base64Str.split(',').last;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(Uint8List.fromList(bytes), width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _photoFallback(name, size)),
        );
      } catch (_) {}
    }
    return _photoFallback(name, size);
  }

  Widget _photoFallback(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD4A84B).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: const Color(0xFFD4A84B)),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }
}
