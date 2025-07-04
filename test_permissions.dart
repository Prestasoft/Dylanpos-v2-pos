

// Simular la clase Permission para testing
class Permission {
  String type;
  bool view;
  bool edit;
  bool delete;

  Permission({
    required this.type,
    this.view = false,
    this.edit = false,
    this.delete = false,
  });

  @override
  String toString() {
    return 'Permission(type: $type, view: $view, edit: $edit, delete: $delete)';
  }
}

// Lista de permisos exactamente como está en el código
List<Permission> defaultPermissions = [
  // ===== NAVEGACIÓN PRINCIPAL =====
  Permission(type: 'dashboard'),
  Permission(type: 'inicio'),
  Permission(type: 'tablero'),
  
  // ===== SERVICIOS Y PAQUETES =====
  Permission(type: 'services'),
  Permission(type: 'register_package'),
  Permission(type: 'register_clothing'),
  
  // ===== RESERVAS =====
  Permission(type: 'reservations'),
  Permission(type: 'reservation_calendar'),
  Permission(type: 'rent_clothing'),
  Permission(type: 'reserve_package'),
  
  // ===== VENTAS =====
  Permission(type: 'sales'),
  Permission(type: 'pos_sales'),
  Permission(type: 'inventory_sales'),
  Permission(type: 'sales_list'),
  Permission(type: 'sales_return'),
  Permission(type: 'quotation_list'),
  
  // ===== COMPRAS =====
  Permission(type: 'purchases'),
  Permission(type: 'pos_purchase'),
  Permission(type: 'purchase_list'),
  Permission(type: 'purchase_return'),
  
  // ===== INVENTARIO =====
  Permission(type: 'products'),
  Permission(type: 'categories'),
  Permission(type: 'warehouses'),
  Permission(type: 'inventory_list'),
  Permission(type: 'inventory_equipment'),
  
  // ===== CONTACTOS =====
  Permission(type: 'customers'),
  Permission(type: 'suppliers'),
  
  // ===== CONFIRMACIONES =====
  Permission(type: 'confirmations'),
  
  // ===== FINANZAS =====
  Permission(type: 'expense'),
  Permission(type: 'income'),
  Permission(type: 'transaction'),
  Permission(type: 'dues'),
  Permission(type: 'ledger'),
  Permission(type: 'loss_profit'),
  
  // ===== REPORTES =====
  Permission(type: 'reports'),
  
  // ===== RECURSOS HUMANOS =====
  Permission(type: 'hrm'),
  Permission(type: 'employees'),
  Permission(type: 'designations'),
  Permission(type: 'salary_list'),
  
  // ===== CONFIGURACIÓN =====
  Permission(type: 'user_roles'),
  Permission(type: 'tax_rates'),
];

// Función para obtener categoría (simplificada para testing)
String getPermissionCategory(String permissionType) {
  switch (permissionType) {
    case 'dashboard':
    case 'inicio':
    case 'tablero':
      return 'NAVEGACIÓN PRINCIPAL';
    case 'services':
    case 'register_package':
    case 'register_clothing':
      return 'SERVICIOS Y PAQUETES';
    case 'reservations':
    case 'reservation_calendar':
    case 'rent_clothing':
    case 'reserve_package':
      return 'RESERVAS';
    case 'sales':
    case 'pos_sales':
    case 'inventory_sales':
    case 'sales_list':
    case 'sales_return':
    case 'quotation_list':
      return 'VENTAS';
    case 'purchases':
    case 'pos_purchase':
    case 'purchase_list':
    case 'purchase_return':
      return 'COMPRAS';
    case 'products':
    case 'categories':
    case 'warehouses':
    case 'inventory_list':
    case 'inventory_equipment':
      return 'INVENTARIO';
    case 'customers':
    case 'suppliers':
      return 'CONTACTOS';
    case 'confirmations':
      return 'CONFIRMACIONES';
    case 'expense':
    case 'income':
    case 'transaction':
    case 'dues':
    case 'ledger':
    case 'loss_profit':
      return 'FINANZAS';
    case 'reports':
      return 'REPORTES';
    case 'hrm':
    case 'employees':
    case 'designations':
    case 'salary_list':
      return 'RECURSOS HUMANOS';
    case 'user_roles':
    case 'tax_rates':
      return 'CONFIGURACIÓN';
    default:
      return 'OTROS';
  }
}

// Función para obtener el título (simplificada para testing)
String getPermissionTitle(String permissionType) {
  switch (permissionType) {
    case 'inventory_equipment':
      return 'Inventario de Equipos';
    case 'confirmations':
      return 'Confirmaciones';
    default:
      return permissionType.replaceAll('_', ' ').toUpperCase();
  }
}

void main() {
  print('=== TESTING PERMISSIONS SYSTEM ===\n');
  
  print('Total permissions: ${defaultPermissions.length}\n');
  
  // Verificar que inventory_equipment esté presente
  var inventoryEquipment = defaultPermissions.where((p) => p.type == 'inventory_equipment').toList();
  print('inventory_equipment found: ${inventoryEquipment.isNotEmpty}');
  if (inventoryEquipment.isNotEmpty) {
    print('inventory_equipment details: ${inventoryEquipment.first}');
    print('inventory_equipment category: ${getPermissionCategory('inventory_equipment')}');
    print('inventory_equipment title: ${getPermissionTitle('inventory_equipment')}');
  }
  
  // Verificar que confirmations esté presente
  var confirmations = defaultPermissions.where((p) => p.type == 'confirmations').toList();
  print('\nconfirmations found: ${confirmations.isNotEmpty}');
  if (confirmations.isNotEmpty) {
    print('confirmations details: ${confirmations.first}');
    print('confirmations category: ${getPermissionCategory('confirmations')}');
    print('confirmations title: ${getPermissionTitle('confirmations')}');
  }
  
  // Mostrar todos los permisos por categoría
  print('\n=== PERMISSIONS BY CATEGORY ===');
  Map<String, List<Permission>> categorizedPermissions = {};
  
  for (var permission in defaultPermissions) {
    String category = getPermissionCategory(permission.type);
    if (!categorizedPermissions.containsKey(category)) {
      categorizedPermissions[category] = [];
    }
    categorizedPermissions[category]!.add(permission);
  }
  
  categorizedPermissions.forEach((category, permissions) {
    print('\n$category (${permissions.length} permissions):');
    for (var permission in permissions) {
      print('  - ${permission.type} (${getPermissionTitle(permission.type)})');
    }
  });
  
  // Verificar si hay duplicados
  print('\n=== CHECKING FOR DUPLICATES ===');
  Map<String, int> permissionCounts = {};
  for (var permission in defaultPermissions) {
    permissionCounts[permission.type] = (permissionCounts[permission.type] ?? 0) + 1;
  }
  
  var duplicates = permissionCounts.entries.where((entry) => entry.value > 1).toList();
  if (duplicates.isNotEmpty) {
    print('DUPLICATES FOUND:');
    for (var duplicate in duplicates) {
      print('  - ${duplicate.key}: ${duplicate.value} times');
    }
  } else {
    print('No duplicates found.');
  }
}
