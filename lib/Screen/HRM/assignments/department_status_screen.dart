import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Repository/task_repo.dart';
import 'package:salespro_admin/services/api_service.dart';

/// Panel del Encargado: vista general de su equipo con KPIs y semáforo.
///
/// El encargado ve cuántas tareas tiene cada empleado al día / por vencer /
/// atrasadas / completadas hoy. Auto-refresca cada 30 segundos.
class DepartmentStatusScreen extends ConsumerStatefulWidget {
  const DepartmentStatusScreen({super.key});

  @override
  ConsumerState<DepartmentStatusScreen> createState() => _DepartmentStatusScreenState();
}

class _DepartmentStatusScreenState extends ConsumerState<DepartmentStatusScreen> {
  final _taskRepo = TaskRepository();
  Timer? _refreshTimer;

  bool _loading = true;
  List<dynamic> _employees = [];
  Map<String, dynamic> _totals = {};
  num? _scopedDesignationId;

  @override
  void initState() {
    super.initState();
    _loadScope().then((_) {
      _loadData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadScope() async {
    final user = ApiService().currentUser;
    if (user == null) return;
    final scope = user['scoped_designation_id'];
    if (scope is num) {
      _scopedDesignationId = scope;
    } else if (scope is String) {
      _scopedDesignationId = num.tryParse(scope);
    }
  }

  Future<void> _loadData() async {
    try {
      final data = await _taskRepo.getDepartmentStatus(
        designationId: _scopedDesignationId,
      );
      if (!mounted) return;
      setState(() {
        _employees = (data['employees'] as List?) ?? [];
        _totals = (data['totals'] as Map<String, dynamic>?) ?? {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mi Equipo', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildKpiRow()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Empleados (${_employees.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  _employees.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Sin empleados en este departamento',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildEmployeeCard(_employees[i]),
                            childCount: _employees.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow() {
    final pendientes = _toInt(_totals['total_pendientes']);
    final enProgreso = _toInt(_totals['total_en_progreso']);
    final vencidas = _toInt(_totals['total_vencidas']);
    final completadas = _toInt(_totals['total_completadas_hoy']);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _kpiCard('Al día', pendientes + enProgreso, Colors.green),
          const SizedBox(width: 8),
          _kpiCard('Vencidas', vencidas, Colors.red),
          const SizedBox(width: 8),
          _kpiCard('Hoy', completadas, Colors.blue),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(dynamic emp) {
    final name = emp['employee_name']?.toString() ?? 'Desconocido';
    final estado = emp['estado']?.toString() ?? 'sin_tareas';
    final pendientes = _toInt(emp['pendientes']);
    final enProgreso = _toInt(emp['en_progreso']);
    final vencidas = _toInt(emp['vencidas']);
    final completadasHoy = _toInt(emp['completadas_hoy']);
    final canLogin = emp['can_login'] == true;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (estado) {
      case 'atrasado':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusLabel = 'Atrasado';
        break;
      case 'por_vencer':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Por vencer';
        break;
      case 'al_dia':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Al día';
        break;
      case 'sin_tareas':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
        statusLabel = 'Sin tareas';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (!canLogin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Sin acceso', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _statBadge('Pend', pendientes, Colors.amber),
              const SizedBox(width: 6),
              _statBadge('Prog', enProgreso, Colors.blue),
              const SizedBox(width: 6),
              _statBadge('Venc', vencidas, Colors.red),
              const SizedBox(width: 6),
              _statBadge('Hoy', completadasHoy, Colors.green),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: value > 0 ? color.withValues(alpha: 0.15) : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: value > 0 ? color : Colors.grey,
        ),
      ),
    );
  }
}
