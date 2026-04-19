import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
    // Clasificar cada cliente en su columna actual
    final buckets = <String, List<ClientTrackingModel>>{};
    for (final col in _columns) {
      buckets[col.key] = [];
    }

    for (final client in clients) {
      final currentDept = _getCurrentColumn(client);
      if (buckets.containsKey(currentDept)) {
        buckets[currentDept]!.add(client);
      } else {
        buckets['seguimiento']!.add(client);
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
            return _buildColumn(col, items, columnWidth, col.key);
          }).toList(),
        ),
      ),
    );
  }

  /// Determina en qué columna está el cliente según flujo secuencial:
  /// Seguimiento → Makeup → Fotografía → Edición → Impresión → Completado
  /// El cliente avanza SOLO cuando el departamento actual marca completado.
  String _getCurrentColumn(ClientTrackingModel client) {
    if (client.isFullyCompleted) return 'completado';

    final groups = client.departmentGroups;

    // Helper: verifica si un departamento tiene tasks y si están todas completadas
    bool isDeptCompleted(String key) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      return group != null && group.tasks.isNotEmpty && group.isCompleted;
    }

    bool hasDeptTasks(String key) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      return group != null && group.tasks.isNotEmpty;
    }

    // Flujo secuencial: solo avanza si el anterior completó
    // 1. Si no tiene tasks de maquillaje → sigue en seguimiento
    if (!hasDeptTasks('maquillaje')) return 'seguimiento';

    // 2. Maquillaje tiene tasks pero no completó → En Makeup
    if (!isDeptCompleted('maquillaje')) return 'maquillaje';

    // 3. Maquillaje completado → pasa a Fotografía/Video
    if (!isDeptCompleted('sesion')) return 'sesion';

    // 4. Fotografía completada → pasa a Edición
    if (!isDeptCompleted('edicion')) return 'edicion';

    // 5. Edición completada → pasa a Impresión
    if (!isDeptCompleted('impresion')) return 'impresion';

    // 6. Todo completado
    return 'completado';
  }

  Widget _buildColumn(_KanbanColumnDef col, List<ClientTrackingModel> items, double width, String columnKey) {
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
              color: Colors.grey.shade50,
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
