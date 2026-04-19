import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../../../../services/api_service.dart';
import '../../assignments/widgets/task_theme.dart';
import '../../employees/model/employee_model.dart';
import '../../employees/repo/employee_repo.dart';
import '../client_tracking_model.dart';
import '../client_tracking_repo.dart';

/// Vista Kanban de asignaciones para encargada de recepción.
/// Columnas: Pendientes → En Atraso → Asignados → No Aplica
class ReceptionAssignmentsView extends StatefulWidget {
  const ReceptionAssignmentsView({super.key});

  @override
  State<ReceptionAssignmentsView> createState() => _ReceptionAssignmentsViewState();
}

class _ReceptionAssignmentsViewState extends State<ReceptionAssignmentsView> {
  final _repo = ClientTrackingRepository();
  final _api = ApiService();
  bool _loading = true;
  List<ClientTrackingModel> _clients = [];
  List<EmployeeModel> _receptionists = [];
  // Clientes marcados como "No aplica" (guardados localmente)
  final Set<String> _noAplicaIds = {};

  @override
  void initState() {
    super.initState();
    _loadNoAplica();
    _loadData();
  }

  void _loadNoAplica() {
    final stored = html.window.localStorage['reception_no_aplica'] ?? '';
    if (stored.isNotEmpty) {
      _noAplicaIds.addAll(stored.split(','));
    }
  }

  void _saveNoAplica() {
    html.window.localStorage['reception_no_aplica'] = _noAplicaIds.join(',');
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final dateFrom = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
      final dateTo = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 60)));
      final clients = await _repo.getClients(dateFrom: dateFrom, dateTo: dateTo);

      final allEmployees = await EmployeeRepository().getActiveEmployees();
      final receptionists = allEmployees.where((e) {
        final d = e.designation.toLowerCase();
        return d.contains('recepcion') || d.contains('tienda') || d.contains('vendedor');
      }).toList();

      if (!mounted) return;
      setState(() {
        _clients = clients;
        _receptionists = receptionists;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando asignaciones recepción: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    final now = DateTime.now();

    // Clasificar clientes
    final pendientes = <ClientTrackingModel>[];
    final enAtraso = <ClientTrackingModel>[];
    final asignados = <ClientTrackingModel>[];
    final noAplica = <ClientTrackingModel>[];

    for (final c in _clients) {
      if (_noAplicaIds.contains(c.reservationId)) {
        noAplica.add(c);
      } else if (!c.isUnassigned) {
        asignados.add(c);
      } else {
        // Calcular tiempo desde creación/reserva
        final resDate = DateTime.tryParse(c.reservationDate);
        final hoursAgo = resDate != null ? now.difference(resDate).inHours.abs() : 0;
        if (hoursAgo > 2) {
          enAtraso.add(c);
        } else {
          pendientes.add(c);
        }
      }
    }

    // Ordenar: más viejo primero (fecha de reserva ascendente)
    int sortByDateAsc(ClientTrackingModel a, ClientTrackingModel b) {
      return a.reservationDate.compareTo(b.reservationDate);
    }
    pendientes.sort(sortByDateAsc);
    enAtraso.sort(sortByDateAsc);
    asignados.sort(sortByDateAsc);
    noAplica.sort(sortByDateAsc);

    return Scaffold(
      backgroundColor: tc.scaffold,
      appBar: AppBar(
        backgroundColor: tc.appBar,
        elevation: 0.5,
        iconTheme: tc.appBarIconTheme,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Asignación de Clientes', style: TextStyle(color: tc.appBarTitle, fontSize: 16)),
            Text('Dpto. de Recepción', style: TextStyle(color: tc.tabSelected, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
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
          : LayoutBuilder(
              builder: (context, constraints) {
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: constraints.maxHeight - 24,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildColumn('Pendientes', pendientes, const Color(0xFFF59E0B), Icons.fiber_new, tc, showAssign: true),
                          _buildColumn('En Atraso', enAtraso, const Color(0xFFEF4444), Icons.warning_amber, tc, showAssign: true, blink: true),
                          _buildColumn('Asignados', asignados, const Color(0xFF10B981), Icons.check_circle, tc),
                          _buildColumn('No Aplica', noAplica, Colors.grey, Icons.block, tc, showRestore: true),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildColumn(String title, List<ClientTrackingModel> items, Color color, IconData icon, TaskColors tc, {bool showAssign = false, bool blink = false, bool showRestore = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth > 900 ? (screenWidth - 100) / 4 : 260.0;

    return Container(
      width: columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: color, width: 2)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text('${items.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
          // Cards con scroll vertical
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tc.isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              ),
              child: items.isEmpty
                  ? Center(child: Text('Sin clientes', style: TextStyle(fontSize: 11, color: tc.textHint)))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => _buildClientCard(items[i], tc, showAssign: showAssign, blink: blink, showRestore: showRestore),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(ClientTrackingModel client, TaskColors tc, {bool showAssign = false, bool blink = false, bool showRestore = false}) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.border.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: tc.shadow, blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + factura
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A84B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  client.customerName.isNotEmpty ? client.customerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD4A84B)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.customerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tc.textPrimary), overflow: TextOverflow.ellipsis),
                    if (client.invoiceNumber != null && client.invoiceNumber!.isNotEmpty && client.invoiceNumber != 'null')
                      Text('Factura #${client.invoiceNumber}', style: TextStyle(fontSize: 9, color: tc.textHint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Teléfono
          if (client.customerPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 10, color: tc.textHint),
                  const SizedBox(width: 4),
                  Text(client.customerPhone, style: TextStyle(fontSize: 10, color: tc.textSecondary)),
                ],
              ),
            ),
          // Plan
          if (client.serviceName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 10, color: tc.textHint),
                  const SizedBox(width: 4),
                  Expanded(child: Text(client.serviceName, style: TextStyle(fontSize: 10, color: tc.textSecondary), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          // Fecha
          Row(
            children: [
              Icon(Icons.calendar_today, size: 10, color: tc.textHint),
              const SizedBox(width: 4),
              Text(_formatDate(client.reservationDate), style: TextStyle(fontSize: 10, color: tc.textHint)),
              if (client.reservationTime.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.schedule, size: 10, color: tc.textHint),
                const SizedBox(width: 2),
                Text(client.reservationTime, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tc.textSecondary)),
              ],
            ],
          ),
          // Recepcionista asignada (si ya está asignada)
          if (!client.isUnassigned && client.bookedByName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: Colors.green.shade400),
                const SizedBox(width: 4),
                Text('→ ${client.bookedByName}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade400)),
              ],
            ),
          ],
          // Botones
          if (showAssign) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 14),
                      label: const Text('Asignar', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _showAssignDialog(client),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 30,
                  child: OutlinedButton(
                    onPressed: () => _markNoAplica(client),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('N/A', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ],
          if (showRestore) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restore, size: 14),
                label: const Text('Restaurar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _restoreFromNoAplica(client),
              ),
            ),
          ],
        ],
      ),
    );

    if (blink) return _BlinkingWidget(child: card);
    return card;
  }

  Future<void> _showAssignDialog(ClientTrackingModel client) async {
    if (_receptionists.isEmpty) {
      EasyLoading.showError('No hay recepcionistas disponibles');
      return;
    }
    final tc = TaskColors.read(context);
    final selected = await showDialog<EmployeeModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asignar Recepcionista', style: TextStyle(fontSize: 18, color: tc.textPrimary)),
            Text(client.customerName, style: TextStyle(fontSize: 13, color: tc.textHint, fontWeight: FontWeight.normal)),
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
                title: Text('${emp.name} ${emp.lastName}', style: TextStyle(fontWeight: FontWeight.w500, color: tc.textPrimary)),
                subtitle: Text(emp.designation, style: TextStyle(fontSize: 12, color: tc.textHint)),
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

  Future<void> _assignReceptionist(ClientTrackingModel client, EmployeeModel receptionist) async {
    try {
      EasyLoading.show(status: 'Asignando...');
      final getResp = await _api.get('reservations/${client.reservationId}');
      if (!getResp.success) {
        EasyLoading.showError('Error al leer reservación');
        return;
      }

      final reservation = getResp.data['reservation'] ?? getResp.data;
      String currentNota = reservation['nota']?.toString() ?? '';

      Map<String, dynamic> assignments = {};
      if (currentNota.contains('|||')) {
        try {
          final jsonPart = currentNota.split('|||').last.trim();
          assignments = jsonDecode(jsonPart);
        } catch (_) {}
        currentNota = currentNota.split('|||').first.trim();
      }

      assignments['b'] = receptionist.id.toString();
      assignments['bookedById'] = receptionist.id.toString();

      final newNota = currentNota.isEmpty
          ? '||| ${jsonEncode(assignments)}'
          : '$currentNota ||| ${jsonEncode(assignments)}';

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

  void _markNoAplica(ClientTrackingModel client) {
    setState(() {
      _noAplicaIds.add(client.reservationId);
      _saveNoAplica();
    });
  }

  void _restoreFromNoAplica(ClientTrackingModel client) {
    setState(() {
      _noAplicaIds.remove(client.reservationId);
      _saveNoAplica();
    });
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return date;
    }
  }
}

class _BlinkingWidget extends StatefulWidget {
  final Widget child;
  const _BlinkingWidget({required this.child});

  @override
  State<_BlinkingWidget> createState() => _BlinkingWidgetState();
}

class _BlinkingWidgetState extends State<_BlinkingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
