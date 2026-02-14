import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/menu_order_provider.dart';
import 'package:salespro_admin/Route/sidebar_item_model.dart';
import 'package:salespro_admin/const.dart';

/// Modal para editar el orden del menú del sidebar
/// Solo visible para administradores
class MenuOrderEditorModal extends ConsumerStatefulWidget {
  const MenuOrderEditorModal({super.key});

  /// Muestra el modal de edición de orden
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MenuOrderEditorModal(),
    );
  }

  @override
  ConsumerState<MenuOrderEditorModal> createState() => _MenuOrderEditorModalState();
}

class _MenuOrderEditorModalState extends ConsumerState<MenuOrderEditorModal> {
  late List<SidebarItemModel> _menuItems;
  bool _hasChanges = false;
  bool _isSaving = false;

  // Colores del diseño dorado
  static const Color _doradoPrincipal = Color(0xFFD4A853);
  static const Color _doradoOscuro = Color(0xFFC9973D);
  static const Color _fondoOscuro = Color(0xFF1A1A2E);
  static const Color _fondoCard = Color(0xFF16213E);

  @override
  void initState() {
    super.initState();
    _loadCurrentOrder();
  }

  void _loadCurrentOrder() {
    // Para admins: mostrar TODOS los menús disponibles (topMenus)
    // Esto permite ordenar todos los menús del sistema, incluyendo los que
    // el admin no tiene permisos específicos pero otros usuarios sí
    final baseMenus = topMenus;

    // Aplicar orden personalizado si existe
    final menuOrderState = ref.read(menuOrderProvider);
    _menuItems = menuOrderState.when(
      data: (menuOrder) {
        if (menuOrder.menuOrder.isEmpty) {
          return List.from(baseMenus);
        }
        return ref.read(menuOrderProvider.notifier).applyOrder(baseMenus);
      },
      loading: () => List.from(baseMenus),
      error: (_, __) => List.from(baseMenus),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _menuItems.removeAt(oldIndex);
      _menuItems.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);

    try {
      // Usar clave única: type|navigationPath (consistente con menu_order_provider)
      final newOrder = _menuItems.map((m) => '${m.type}|${m.navigationPath}').toList();
      final userName = isSubUser ? constSubUserTitle : 'Admin';

      await ref.read(menuOrderProvider.notifier).updateMenuOrder(
        newOrder,
        updatedBy: userName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Orden del menú guardado correctamente'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetToDefault() {
    setState(() {
      _menuItems = List.from(topMenus);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.95 : 500.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 40,
        vertical: 24,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: _fondoOscuro,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _doradoPrincipal.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Instrucciones
            _buildInstructions(),

            // Lista reordenable
            Flexible(
              child: _buildReorderableList(),
            ),

            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _doradoPrincipal.withValues(alpha: 0.2),
            _doradoOscuro.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: _doradoPrincipal.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _doradoPrincipal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.reorder_rounded,
              color: _doradoPrincipal,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordenar Menú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Arrastra para reorganizar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mantén presionado y arrastra los elementos para cambiar su orden en el menú lateral.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _menuItems.length,
          onReorder: _onReorder,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final scale = Tween<double>(begin: 1.0, end: 1.05).animate(animation);
                return Transform.scale(
                  scale: scale.value,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: _fondoOscuro,
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final menu = _menuItems[index];
            return _buildMenuItem(menu, index);
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(SidebarItemModel menu, int index) {
    final sectionColor = menu.sectionColor ?? _doradoPrincipal;
    // Usar clave única: type|navigationPath para manejar menús con type duplicado
    final uniqueKey = '${menu.type}|${menu.navigationPath}';

    return Container(
      key: ValueKey(uniqueKey),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _fondoOscuro,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sectionColor.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: sectionColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            menu.materialIcon ?? Icons.menu,
            color: sectionColor,
            size: 20,
          ),
        ),
        title: Text(
          menu.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: menu.sidebarItemType == SidebarItemType.submenu
            ? Text(
                '${menu.submenus?.length ?? 0} submenús',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Número de orden
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Icono de arrastre
            const Icon(
              Icons.drag_handle,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón Restaurar
          TextButton.icon(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Restaurar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
          ),
          const Spacer(),
          // Botón Cancelar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          // Botón Guardar
          ElevatedButton.icon(
            onPressed: _hasChanges && !_isSaving ? _saveOrder : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _doradoPrincipal,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
