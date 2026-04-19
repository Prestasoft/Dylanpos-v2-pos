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
    _KanbanColumnDef(key: 'seguimiento', label: 'Seguimiento', icon: Icons.visibility, color: Color(0xFF6366F1)),
    _KanbanColumnDef(key: 'maquillaje', label: 'Maquillaje', icon: Icons.face_retouching_natural, color: Color(0xFFEC4899)),
    _KanbanColumnDef(key: 'sesion', label: 'Sesión', icon: Icons.camera_alt, color: Color(0xFFF59E0B)),
    _KanbanColumnDef(key: 'edicion', label: 'Edición', icon: Icons.edit, color: Color(0xFF3B82F6)),
    _KanbanColumnDef(key: 'impresion', label: 'Impresión', icon: Icons.print, color: Color(0xFF10B981)),
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
            return _buildColumn(col, items, columnWidth);
          }).toList(),
        ),
      ),
    );
  }

  /// Determina en qué columna está el cliente actualmente
  String _getCurrentColumn(ClientTrackingModel client) {
    if (client.isFullyCompleted) return 'completado';

    final groups = client.departmentGroups;
    if (groups.isEmpty) return 'seguimiento';

    // El cliente está en el primer departamento que tiene tasks activas
    // Recorrer en orden: maquillaje → sesión → edición → impresión
    final order = ['maquillaje', 'sesion', 'edicion', 'impresion'];

    for (final key in order) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      if (group != null && group.hasActive) return key;
    }

    // Si todos los departamentos que tiene están completados pero no es fullCompleted
    // puede que falten departamentos por asignar
    for (final key in order) {
      final group = groups.where((g) => g.key == key).firstOrNull;
      if (group == null) continue; // No tiene este departamento
      if (!group.isCompleted) return key; // Primer no completado
    }

    return 'seguimiento';
  }

  Widget _buildColumn(_KanbanColumnDef col, List<ClientTrackingModel> items, double width) {
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
                    children: items.map((c) => KanbanClientCard(client: c)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
