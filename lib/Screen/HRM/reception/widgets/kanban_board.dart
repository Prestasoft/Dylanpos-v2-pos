import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../assignments/widgets/task_theme.dart';
import '../client_tracking_model.dart';
import 'kanban_client_card.dart';

/// Columna del proceso con su nombre, conteo y color
class _KanbanColumnDef {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _KanbanColumnDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Vista Kanban tipo CRM para seguimiento de clientes.
/// Columnas: Seguimiento → Maquillaje → Sesión → Edición → Impresión → Completado
class KanbanBoard extends StatelessWidget {
  final List<ClientTrackingModel> clients;
  final Map<String, String> customColors;

  const KanbanBoard({super.key, required this.clients, this.customColors = const {}});

  static const _defaultColumns = [
    _KanbanColumnDef(key: 'seguimiento', label: 'En Seguimiento', icon: Icons.visibility, color: Color(0xFF6366F1)),
    _KanbanColumnDef(key: 'maquillaje', label: 'En Makeup', icon: Icons.face_retouching_natural, color: Color(0xFFEC4899)),
    _KanbanColumnDef(key: 'sesion', label: 'En Fotografía/Video', icon: Icons.camera_alt, color: Color(0xFFF59E0B)),
    _KanbanColumnDef(key: 'edicion', label: 'En Edición', icon: Icons.edit, color: Color(0xFF3B82F6)),
    _KanbanColumnDef(key: 'impresion', label: 'En Impresión', icon: Icons.print, color: Color(0xFF10B981)),
  ];

  List<_KanbanColumnDef> get _columns {
    if (customColors.isEmpty) return _defaultColumns;
    return _defaultColumns.map((col) {
      final hex = customColors[col.key];
      if (hex == null || hex.isEmpty) return col;
      final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
      return _KanbanColumnDef(key: col.key, label: col.label, icon: col.icon, color: color);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar clientes con mismo nombre + misma fecha en una sola tarjeta
    final grouped = <String, List<ClientTrackingModel>>{};
    for (final client in clients) {
      final key = '${client.customerName}|||${client.reservationDate}';
      grouped.putIfAbsent(key, () => []).add(client);
    }

    // Clasificar cada cliente/grupo en su columna actual
    final buckets = <String, List<ClientTrackingModel>>{};
    for (final col in _columns) {
      buckets[col.key] = [];
    }

    for (final entry in grouped.values) {
      // Usar el primer cliente del grupo como representante
      final primary = entry.first;
      // Si hay múltiples, marcar los planes adicionales
      if (entry.length > 1) {
        // Combinar service names para mostrar todos los planes
        final allPlans = entry.map((c) => c.serviceName).where((s) => s.isNotEmpty).toSet().join(' + ');
        // Combinar stages de todas las reservaciones
        final allStages = <StageStatus>[];
        for (final c in entry) {
          allStages.addAll(c.stages);
        }
        // Crear modelo combinado
        final combined = ClientTrackingModel(
          reservationId: primary.reservationId,
          customerName: primary.customerName,
          customerPhone: primary.customerPhone,
          invoiceNumber: primary.invoiceNumber,
          serviceName: allPlans,
          reservationDate: primary.reservationDate,
          fiestaDate: primary.fiestaDate,
          reservationTime: primary.reservationTime,
          estado: primary.estado,
          bookedById: primary.bookedById,
          bookedByName: primary.bookedByName,
          stages: allStages,
        );
        final currentDept = _getCurrentColumn(combined);
        (buckets[currentDept] ?? buckets['seguimiento']!).add(combined);
      } else {
        final currentDept = _getCurrentColumn(primary);
        (buckets[currentDept] ?? buckets['seguimiento']!).add(primary);
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth > 900 ? (screenWidth - 80) / _columns.length : 220.0;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _columns.map((col) {
            final items = buckets[col.key] ?? [];
            return _buildColumn(col, items, columnWidth, col.key, TaskColors.of(context));
          }).toList(),
        ),
      ),
    );
  }

  /// Determina en qué columna está el cliente según flujo secuencial:
  /// Seguimiento → Makeup → Fotografía → Edición → (pausa si falta fiesta) → Impresión → Completado
  ///
  /// Para planes Pre-Quince + Fiesta:
  /// Pre-Quince: Makeup → Fotografía → Edición (se edita pre-quince)
  /// ⏸ PAUSA — no pasa a Impresión hasta que termine la Fiesta
  /// Fiesta: vuelve a Makeup → Fotografía → Edición
  /// Cuando AMBAS ediciones terminan → Impresión → Completado
  String _getCurrentColumn(ClientTrackingModel client) {
    if (client.isFullyCompleted) return 'completado';

    final groups = client.departmentGroups;

    bool isDeptCompleted(String key) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      return group != null && group.tasks.isNotEmpty && group.isCompleted;
    }

    bool hasDeptTasks(String key) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      return group != null && group.tasks.isNotEmpty;
    }

    bool hasDeptActive(String key) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      return group != null && group.hasActive;
    }

    // 1. Sin tasks de maquillaje → sigue en seguimiento
    if (!hasDeptTasks('maquillaje')) return 'seguimiento';

    // 2. Maquillaje activo (no completado) → En Makeup
    if (hasDeptActive('maquillaje')) return 'maquillaje';

    // 3. Fotografía activa → En Fotografía
    if (hasDeptActive('sesion')) return 'sesion';

    // 4. Edición activa → En Edición
    if (hasDeptActive('edicion')) return 'edicion';

    // 5. Plan con dos eventos (Pre-Quince + Fiesta):
    // Si tiene fiesta_date, verificar si todas las tasks de pre Y fiesta completaron
    // antes de pasar a Impresión
    if (client.hasTwoEvents) {
      // Si maquillaje o fotografía no completaron todo → vuelve al primer pendiente
      if (!isDeptCompleted('maquillaje')) return 'maquillaje';
      if (!isDeptCompleted('sesion')) return 'sesion';
      if (!isDeptCompleted('edicion')) return 'edicion';
    }

    // 6. Todo antes de impresión completado → En Impresión
    if (!isDeptCompleted('impresion')) return 'impresion';

    // 7. Todo completado
    return 'completado';
  }

  Widget _buildColumn(_KanbanColumnDef col, List<ClientTrackingModel> items, double width, String columnKey, TaskColors tc) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // Header de columna
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: col.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: col.color, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(col.icon, size: 16, color: col.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    col.label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: col.color),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: col.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Cards de clientes
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tc.isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Sin clientes',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ),
                  )
                : Column(
                    children: items.map((c) => KanbanClientCard(client: c, currentColumn: columnKey)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
