// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import '../../model/user_role_model.dart';
import '../Widgets/Constant Data/constant.dart';

/// Modelo para definir una categoría de permisos
class PermissionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<PermissionItem> items;
  bool isExpanded;

  PermissionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.items,
    this.isExpanded = false,
  });
}

/// Modelo para definir un item de permiso individual
class PermissionItem {
  final String type;
  final String name;
  final String? parentType;
  final bool isSubmenu;

  PermissionItem({
    required this.type,
    required this.name,
    this.parentType,
    this.isSubmenu = false,
  });
}

/// Widget profesional para editar permisos de usuario
class PermissionsEditorWidget extends StatefulWidget {
  final List<Permission> permissions;
  final Function(List<Permission>) onPermissionsChanged;
  final String? userName;

  const PermissionsEditorWidget({
    super.key,
    required this.permissions,
    required this.onPermissionsChanged,
    this.userName,
  });

  @override
  State<PermissionsEditorWidget> createState() => _PermissionsEditorWidgetState();
}

class _PermissionsEditorWidgetState extends State<PermissionsEditorWidget> {
  late List<PermissionCategory> categories;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _debugPrintPermissions('initState');
  }

  @override
  void didUpdateWidget(PermissionsEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cuando los permisos del padre cambian, forzar reconstrucción
    if (widget.permissions != oldWidget.permissions) {
      _debugPrintPermissions('didUpdateWidget - permissions changed');
      setState(() {});
    }
  }

  void _debugPrintPermissions(String source) {
    int active = widget.permissions.where((p) => p.view || p.edit || p.delete).length;
    debugPrint('🔷 [PermissionsEditorWidget.$source] Total permisos: ${widget.permissions.length}, Activos: $active');
    for (var p in widget.permissions) {
      if (p.view || p.edit || p.delete) {
        debugPrint('🔷   - ${p.type}: view=${p.view}, edit=${p.edit}, delete=${p.delete}');
      }
    }
  }

  void _initializeCategories() {
    categories = [
      PermissionCategory(
        id: 'navigation',
        name: 'Navegación Principal',
        icon: Icons.home_rounded,
        color: const Color(0xFF6366F1),
        isExpanded: true,
        items: [
          PermissionItem(type: 'dashboard', name: 'Dashboard'),
          PermissionItem(type: 'inicio', name: 'Inicio'),
          PermissionItem(type: 'tablero', name: 'Tablero'),
        ],
      ),
      PermissionCategory(
        id: 'services',
        name: 'Servicios y Paquetes',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF8B5CF6),
        items: [
          PermissionItem(type: 'services', name: 'Servicios (Menú)'),
          PermissionItem(type: 'register_package', name: 'Registrar Paquete', parentType: 'services', isSubmenu: true),
          PermissionItem(type: 'register_clothing', name: 'Registrar Vestimenta', parentType: 'services', isSubmenu: true),
        ],
      ),
      PermissionCategory(
        id: 'reservations',
        name: 'Reservas',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF06B6D4),
        items: [
          PermissionItem(type: 'reservations', name: 'Reservas (Menú)'),
          PermissionItem(type: 'rent_clothing', name: 'Rentar Vestimentas', parentType: 'reservations', isSubmenu: true),
          PermissionItem(type: 'reserve_package', name: 'Reservar Paquete', parentType: 'reservations', isSubmenu: true),
          PermissionItem(type: 'reservation_calendar', name: 'Calendario de Reservas', parentType: 'reservations', isSubmenu: true),
        ],
      ),
      PermissionCategory(
        id: 'sales',
        name: 'Ventas',
        icon: Icons.point_of_sale_rounded,
        color: const Color(0xFF10B981),
        items: [
          PermissionItem(type: 'sales', name: 'Ventas (Menú)'),
          PermissionItem(type: 'pos_sales', name: 'POS Ventas', parentType: 'sales', isSubmenu: true),
          PermissionItem(type: 'inventory_sales', name: 'Facturar', parentType: 'sales', isSubmenu: true),
          PermissionItem(type: 'sales_list', name: 'Lista de Ventas', parentType: 'sales', isSubmenu: true),
          PermissionItem(type: 'sales_return', name: 'Devoluciones', parentType: 'sales', isSubmenu: true),
          PermissionItem(type: 'quotation_list', name: 'Cotizaciones', parentType: 'sales', isSubmenu: true),
        ],
      ),
      PermissionCategory(
        id: 'confirmations',
        name: 'Confirmaciones',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF14B8A6),
        items: [
          PermissionItem(type: 'confirmations', name: 'Confirmaciones de Venta'),
        ],
      ),
      PermissionCategory(
        id: 'accounts',
        name: 'Cuentas y Pagos',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFF59E0B),
        items: [
          PermissionItem(type: 'dues', name: 'Cuentas por Cobrar'),
          PermissionItem(type: 'transfers', name: 'Transferencias'),
        ],
      ),
      PermissionCategory(
        id: 'purchases',
        name: 'Compras',
        icon: Icons.shopping_cart_rounded,
        color: const Color(0xFFEF4444),
        items: [
          PermissionItem(type: 'purchases', name: 'Compras (Menú)'),
          PermissionItem(type: 'pos_purchase', name: 'Realizar Compra', parentType: 'purchases', isSubmenu: true),
          PermissionItem(type: 'purchase_list', name: 'Lista de Compras', parentType: 'purchases', isSubmenu: true),
          PermissionItem(type: 'purchase_return', name: 'Devoluciones', parentType: 'purchases', isSubmenu: true),
        ],
      ),
      PermissionCategory(
        id: 'inventory',
        name: 'Inventario',
        icon: Icons.inventory_rounded,
        color: const Color(0xFF3B82F6),
        items: [
          PermissionItem(type: 'products', name: 'Productos'),
          PermissionItem(type: 'categories', name: 'Categorías'),
          PermissionItem(type: 'warehouses', name: 'Almacenes'),
          PermissionItem(type: 'inventory_list', name: 'Lista de Inventario'),
          PermissionItem(type: 'inventory_equipment', name: 'Equipos de Inventario'),
        ],
      ),
      PermissionCategory(
        id: 'contacts',
        name: 'Contactos',
        icon: Icons.people_rounded,
        color: const Color(0xFFEC4899),
        items: [
          PermissionItem(type: 'customers', name: 'Clientes'),
          PermissionItem(type: 'suppliers', name: 'Proveedores'),
        ],
      ),
      PermissionCategory(
        id: 'finance',
        name: 'Finanzas',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF22C55E),
        items: [
          PermissionItem(type: 'expense', name: 'Gastos'),
          PermissionItem(type: 'income', name: 'Ingresos'),
          PermissionItem(type: 'transaction', name: 'Transacciones'),
          PermissionItem(type: 'banks', name: 'Bancos'),
          PermissionItem(type: 'ledger', name: 'Libro Mayor'),
          PermissionItem(type: 'loss_profit', name: 'Pérdidas y Ganancias'),
        ],
      ),
      PermissionCategory(
        id: 'reports',
        name: 'Reportes y Auditoría',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF6366F1),
        items: [
          PermissionItem(type: 'reports', name: 'Reportes'),
          PermissionItem(type: 'audit', name: 'Auditoría'),
        ],
      ),
      PermissionCategory(
        id: 'hrm',
        name: 'Recursos Humanos',
        icon: Icons.badge_rounded,
        color: const Color(0xFFF97316),
        items: [
          PermissionItem(type: 'hrm', name: 'HRM (Menú)'),
          PermissionItem(type: 'employees', name: 'Empleados', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'designations', name: 'Cargos', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'salary_list', name: 'Nómina', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'attendance', name: 'Asistencia', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'vacations', name: 'Vacaciones', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'loans', name: 'Préstamos', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'prestaciones', name: 'Prestaciones', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'tss_reports', name: 'Reportes TSS', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'birthdays', name: 'Cumpleaños', parentType: 'hrm', isSubmenu: true),
          PermissionItem(type: 'rentability', name: 'Rentabilidad', parentType: 'hrm', isSubmenu: true),
        ],
      ),
      PermissionCategory(
        id: 'settings',
        name: 'Configuración',
        icon: Icons.settings_rounded,
        color: const Color(0xFF64748B),
        items: [
          PermissionItem(type: 'user_roles', name: 'Roles de Usuario'),
          PermissionItem(type: 'tax_rates', name: 'Impuestos'),
        ],
      ),
    ];
  }

  Permission _getPermission(String type) {
    return widget.permissions.firstWhere(
      (p) => p.type == type,
      orElse: () => Permission(type: type),
    );
  }

  void _updatePermission(String type, {bool? view, bool? edit, bool? delete}) {
    final permission = widget.permissions.firstWhere(
      (p) => p.type == type,
      orElse: () {
        final newPerm = Permission(type: type);
        widget.permissions.add(newPerm);
        return newPerm;
      },
    );

    if (view != null) permission.view = view;
    if (edit != null) permission.edit = edit;
    if (delete != null) permission.delete = delete;

    widget.onPermissionsChanged(widget.permissions);
    setState(() {});
  }

  void _toggleCategoryPermissions(PermissionCategory category, bool enable) {
    for (var item in category.items) {
      _updatePermission(item.type, view: enable, edit: enable, delete: enable);
    }
  }

  void _applyTemplate(String template) {
    for (var perm in widget.permissions) {
      perm.view = false;
      perm.edit = false;
      perm.delete = false;
    }

    switch (template) {
      case 'admin':
        for (var perm in widget.permissions) {
          perm.view = true;
          perm.edit = true;
          perm.delete = true;
        }
        break;

      case 'manager':
        _setTemplatePermissions([
          'dashboard', 'sales', 'inventory_sales', 'sales_list', 'sales_return',
          'quotation_list', 'customers', 'products', 'categories', 'warehouses',
          'inventory_list', 'reports', 'expense', 'income', 'dues', 'confirmations',
          'reservations', 'rent_clothing', 'reserve_package', 'reservation_calendar',
        ], viewOnly: false);
        break;

      case 'cashier':
        _setTemplatePermissions([
          'dashboard', 'sales', 'inventory_sales', 'sales_list',
          'customers', 'dues', 'confirmations',
        ], viewOnly: false);
        _setTemplatePermissions(['products', 'inventory_list'], viewOnly: true);
        break;

      case 'dress_operator':
        _setTemplatePermissions([
          'services', 'register_clothing', 'reservations', 'reservation_calendar',
        ], viewOnly: false);
        break;

      case 'viewer':
        for (var perm in widget.permissions) {
          perm.view = true;
          perm.edit = false;
          perm.delete = false;
        }
        break;

      case 'none':
        break;
    }

    widget.onPermissionsChanged(widget.permissions);
    setState(() {});
  }

  void _setTemplatePermissions(List<String> types, {required bool viewOnly}) {
    for (var type in types) {
      final perm = widget.permissions.firstWhere(
        (p) => p.type == type,
        orElse: () {
          final newPerm = Permission(type: type);
          widget.permissions.add(newPerm);
          return newPerm;
        },
      );
      perm.view = true;
      perm.edit = !viewOnly;
      perm.delete = !viewOnly;
    }
  }

  int get _totalActiveModules {
    return widget.permissions.where((p) => p.view || p.edit || p.delete).length;
  }

  int get _totalViewPermissions {
    return widget.permissions.where((p) => p.view).length;
  }

  int get _totalEditPermissions {
    return widget.permissions.where((p) => p.edit).length;
  }

  int get _totalDeletePermissions {
    return widget.permissions.where((p) => p.delete).length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildTemplatesSection(),
        const SizedBox(height: 20),
        _buildExpansionControls(),
        const SizedBox(height: 12),
        _buildCategoriesList(),
        const SizedBox(height: 16),
        _buildSummary(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMainColor.withValues(alpha: 0.1),
            kMainColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMainColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security_rounded, color: kMainColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Permisos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (widget.userName != null)
                  Text(
                    'Usuario: ${widget.userName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Plantillas Rápidas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('Administrador', Icons.admin_panel_settings_rounded, const Color(0xFF6366F1), () => _applyTemplate('admin')),
              _buildTemplateChip('Gerente', Icons.business_center_rounded, const Color(0xFF10B981), () => _applyTemplate('manager')),
              _buildTemplateChip('Cajero', Icons.point_of_sale_rounded, const Color(0xFF3B82F6), () => _applyTemplate('cashier')),
              _buildTemplateChip('Vestimentas', Icons.checkroom_rounded, const Color(0xFFEC4899), () => _applyTemplate('dress_operator')),
              _buildTemplateChip('Solo Ver', Icons.visibility_rounded, const Color(0xFFF59E0B), () => _applyTemplate('viewer')),
              _buildTemplateChip('Ninguno', Icons.block_rounded, const Color(0xFFEF4444), () => _applyTemplate('none')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Módulos del Sistema',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (var cat in categories) {
                    cat.isExpanded = true;
                  }
                });
              },
              icon: const Icon(Icons.unfold_more_rounded, size: 18),
              label: const Text('Expandir'),
              style: TextButton.styleFrom(
                foregroundColor: kMainColor,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (var cat in categories) {
                    cat.isExpanded = false;
                  }
                });
              },
              icon: const Icon(Icons.unfold_less_rounded, size: 18),
              label: const Text('Colapsar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final isLast = index == categories.length - 1;
            return _buildCategoryTile(category, isLast);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(PermissionCategory category, bool isLast) {
    int activeCount = 0;
    for (var item in category.items) {
      final perm = _getPermission(item.type);
      if (perm.view || perm.edit || perm.delete) activeCount++;
    }
    final totalCount = category.items.length;
    final isAllActive = activeCount == totalCount && totalCount > 0;
    final isSomeActive = activeCount > 0 && activeCount < totalCount;

    return Column(
      children: [
        Material(
          color: category.isExpanded ? category.color.withValues(alpha: 0.05) : Colors.white,
          child: InkWell(
            onTap: () {
              setState(() {
                category.isExpanded = !category.isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: category.isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded, color: Colors.grey[600], size: 24),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(category.icon, color: category.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                        ),
                        Text(
                          '$activeCount de $totalCount activos',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAllActive ? Colors.green : isSomeActive ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _toggleCategoryPermissions(category, true),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        iconSize: 20,
                        color: Colors.green,
                        tooltip: 'Activar todos',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: () => _toggleCategoryPermissions(category, false),
                        icon: const Icon(Icons.cancel_outlined),
                        iconSize: 20,
                        color: Colors.red,
                        tooltip: 'Desactivar todos',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: _buildCategoryItems(category),
          crossFadeState: category.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildCategoryItems(PermissionCategory category) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Módulo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
                _buildColumnHeader('Ver', Colors.blue),
                _buildColumnHeader('Editar', Colors.amber),
                _buildColumnHeader('Eliminar', Colors.red),
              ],
            ),
          ),
          ...category.items.map((item) => _buildPermissionRow(item, category.color)),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String text, Color color) {
    return SizedBox(
      width: 70,
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _buildPermissionRow(PermissionItem item, Color categoryColor) {
    final permission = _getPermission(item.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (item.isSubmenu) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: item.isSubmenu ? FontWeight.normal : FontWeight.w500,
                      color: item.isSubmenu ? Colors.grey[600] : Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _buildPermissionCheckbox(permission.view, Colors.blue, (value) => _updatePermission(item.type, view: value)),
          _buildPermissionCheckbox(permission.edit, Colors.amber[700]!, (value) => _updatePermission(item.type, edit: value)),
          _buildPermissionCheckbox(permission.delete, Colors.red, (value) => _updatePermission(item.type, delete: value)),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckbox(bool value, Color color, Function(bool) onChanged) {
    return SizedBox(
      width: 70,
      child: Center(
        child: Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize_rounded, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildSummaryItem('Módulos Activos', _totalActiveModules, kMainColor),
                _buildSummaryItem('Ver', _totalViewPermissions, Colors.blue),
                _buildSummaryItem('Editar', _totalEditPermissions, Colors.amber[700]!),
                _buildSummaryItem('Eliminar', _totalDeletePermissions, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
