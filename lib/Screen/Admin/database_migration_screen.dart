import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../const.dart';
import '../../services/api/victorpos_api_service.dart';
import '../../services/tenant/tenant_manager.dart';
import '../../services/tenant/tenant_model.dart';

/// Función helper para convertir Map de Firebase a Map<String, dynamic> de forma segura
/// Maneja valores anidados que pueden ser String, List o Map
Map<String, dynamic> _safeMapConvert(dynamic value) {
  if (value == null) return {};
  if (value is String) return {'_rawString': value};
  if (value is! Map) return {'_rawValue': value.toString()};

  final Map<String, dynamic> result = {};
  final Map<dynamic, dynamic> source = value;

  for (var entry in source.entries) {
    final key = entry.key.toString();
    final val = entry.value;

    if (val == null) {
      result[key] = null;
    } else if (val is String || val is num || val is bool) {
      result[key] = val;
    } else if (val is List) {
      // Convertir lista de forma segura
      result[key] = val.map((item) {
        if (item is Map) {
          return _safeMapConvert(item);
        }
        return item;
      }).toList();
    } else if (val is Map) {
      result[key] = _safeMapConvert(val);
    } else {
      result[key] = val.toString();
    }
  }

  return result;
}

class DatabaseMigrationScreen extends StatefulWidget {
  const DatabaseMigrationScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseMigrationScreen> createState() => _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState extends State<DatabaseMigrationScreen> {
  bool _isLoading = true;
  bool _isApiConnected = false;
  bool _isMigrating = false;
  String _migrationLog = '';
  String _currentTenantName = '';
  String _currentTenantId = '';

  // Contadores Firebase
  int _firebaseCustomers = 0;
  int _firebaseProducts = 0;
  int _firebaseExpenses = 0;
  int _firebaseReservations = 0;
  int _firebaseServices = 0;
  int _firebaseDresses = 0;
  int _firebaseBanks = 0;
  int _firebaseUserRoles = 0;
  int _firebaseCategories = 0;
  int _firebaseExpenseCategories = 0;
  int _firebaseIncomeCategories = 0;
  int _firebaseIncomes = 0;
  int _firebaseSalesTransactions = 0;
  int _firebasePurchaseTransactions = 0;
  int _firebaseDueTransactions = 0;
  int _firebaseQuotations = 0;
  int _firebaseUnits = 0;
  int _firebaseEmployees = 0;
  int _firebaseDesignations = 0;
  int _firebasePaidSalaries = 0;
  int _firebaseDailyTransactions = 0;
  int _firebaseSalesReturns = 0;
  int _firebasePurchaseReturns = 0;
  int _firebaseBusinessSettings = 0;
  int _firebaseWhatsappTemplates = 0;
  int _firebaseGeneralSettings = 0;

  // Contadores API
  int _apiCustomers = 0;
  int _apiProducts = 0;
  int _apiExpenses = 0;
  int _apiReservations = 0;
  int _apiServices = 0;
  int _apiDresses = 0;
  int _apiBanks = 0;
  int _apiUserRoles = 0;
  int _apiProductCategories = 0;
  int _apiExpenseCategories = 0;
  int _apiIncomeCategories = 0;
  int _apiIncomes = 0;
  int _apiSalesTransactions = 0;
  int _apiPurchaseTransactions = 0;
  int _apiDueTransactions = 0;
  int _apiQuotations = 0;
  int _apiUnits = 0;
  int _apiEmployees = 0;
  int _apiDesignations = 0;
  int _apiPaidSalaries = 0;
  int _apiDailyTransactions = 0;
  int _apiSalesReturns = 0;
  int _apiPurchaseReturns = 0;
  int _apiBusinessSettings = 0;
  int _apiWhatsappTemplates = 0;
  int _apiGeneralSettings = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // Obtener el tenant actual - primero intentar desde TenantManager
    final tenantManager = TenantManager();

    // Si el TenantManager tiene el tenant, usarlo
    if (tenantManager.currentTenant != null) {
      _currentTenantId = tenantManager.currentTenantId;
      _currentTenantName = tenantManager.currentTenantName;
    } else {
      // Si no, leer directamente desde nb_utils/SharedPreferences
      final savedTenantId = _getSavedTenantId();
      if (savedTenantId.isNotEmpty) {
        _currentTenantId = savedTenantId;
        // Buscar el nombre del tenant
        final tenant = TenantConfig.getTenantById(savedTenantId);
        _currentTenantName = tenant?.displayName ?? 'Sucursal: $savedTenantId';
      } else {
        _currentTenantId = 'sde'; // Default para esta app que está en SDE
        _currentTenantName = 'Santo Domingo Este';
      }
    }

    debugPrint('🏢 Migración: Tenant actual = $_currentTenantId ($_currentTenantName)');

    // Configurar el branch ID en la API antes de hacer login
    victorPosApi.setBranchId(_currentTenantId.isNotEmpty ? _currentTenantId : 'stg');

    // Conectar a la API con credenciales correctas
    final loginResult = await victorPosApi.login('admin@victorguzmanfotografia.com', 'admin123');
    _isApiConnected = loginResult['token'] != null;

    debugPrint('🔌 API conectada: $_isApiConnected');

    if (_isApiConnected) {
      await Future.wait([
        _loadFirebaseCounts(),
        _loadApiCounts(),
      ]);
    }

    setState(() => _isLoading = false);
  }

  /// Obtener el tenant ID guardado en localStorage (web)
  String _getSavedTenantId() {
    try {
      // Usar localStorage directamente (web)
      return html.window.localStorage['selected_tenant_id'] ?? '';
    } catch (e) {
      debugPrint('Error obteniendo tenant guardado: $e');
      return '';
    }
  }

  Future<void> _loadFirebaseCounts() async {
    try {
      final userId = await getUserID();
      final db = FirebaseDatabase.instance;

      // Datos por usuario
      final customerSnap = await db.ref('$userId/Customers').get();
      final productSnap = await db.ref('$userId/Products').get();
      final expenseSnap = await db.ref('$userId/Expense').get();
      final reservationSnap = await db.ref('Admin Panel/reservations').get();
      final bankSnap = await db.ref('$userId/Banks').get();
      final userRoleSnap = await db.ref('$userId/User Role').get();
      final categorySnap = await db.ref('$userId/Categories').get();
      final expenseCategorySnap = await db.ref('$userId/Expense Category').get();
      final incomeCategorySnap = await db.ref('$userId/Income Category').get();
      final incomeSnap = await db.ref('$userId/Income').get();
      final salesTransSnap = await db.ref('$userId/Sales Transition').get();
      final purchaseTransSnap = await db.ref('$userId/Purchase Transition').get();
      final dueTransSnap = await db.ref('$userId/Due Transaction').get();
      final quotationSnap = await db.ref('$userId/Sales Quotation').get();
      final unitSnap = await db.ref('$userId/Units').get();
      final employeeSnap = await db.ref('$userId/Employee').get();
      final designationSnap = await db.ref('$userId/Designation').get();
      final paidSalarySnap = await db.ref('$userId/Paid Salary').get();
      final dailyTransSnap = await db.ref('$userId/Daily Transaction').get();
      final salesReturnSnap = await db.ref('$userId/Sales Return').get();
      final purchaseReturnSnap = await db.ref('$userId/    Return').get();
      final businessSettingsSnap = await db.ref('$userId/Personal Information').get();
      final whatsappTemplateSnap = await db.ref('$userId/Whatsapp Marketing Template').get();

      // Datos globales (Admin Panel)
      final serviceSnap = await db.ref('Admin Panel/services').get();
      final dressSnap = await db.ref('Admin Panel/dresses').get();
      final generalSettingsSnap = await db.ref('Admin Panel/General Setting').get();

      setState(() {
        _firebaseCustomers = customerSnap.children.length;
        _firebaseProducts = productSnap.children.length;
        _firebaseExpenses = expenseSnap.children.length;
        _firebaseReservations = reservationSnap.children.length;
        _firebaseServices = serviceSnap.children.length;
        _firebaseDresses = dressSnap.children.length;
        _firebaseBanks = bankSnap.children.length;
        _firebaseUserRoles = userRoleSnap.children.length;
        _firebaseCategories = categorySnap.children.length;
        _firebaseExpenseCategories = expenseCategorySnap.children.length;
        _firebaseIncomeCategories = incomeCategorySnap.children.length;
        _firebaseIncomes = incomeSnap.children.length;
        _firebaseSalesTransactions = salesTransSnap.children.length;
        _firebasePurchaseTransactions = purchaseTransSnap.children.length;
        _firebaseDueTransactions = dueTransSnap.children.length;
        _firebaseQuotations = quotationSnap.children.length;
        _firebaseUnits = unitSnap.children.length;
        _firebaseEmployees = employeeSnap.children.length;
        _firebaseDesignations = designationSnap.children.length;
        _firebasePaidSalaries = paidSalarySnap.children.length;
        _firebaseDailyTransactions = dailyTransSnap.children.length;
        _firebaseSalesReturns = salesReturnSnap.children.length;
        _firebasePurchaseReturns = purchaseReturnSnap.children.length;
        _firebaseBusinessSettings = businessSettingsSnap.exists ? 1 : 0;
        _firebaseWhatsappTemplates = whatsappTemplateSnap.exists ? 1 : 0;
        _firebaseGeneralSettings = generalSettingsSnap.exists ? 1 : 0;
      });
    } catch (e) {
      debugPrint('Error cargando conteos de Firebase: $e');
    }
  }

  Future<void> _loadApiCounts() async {
    try {
      final customers = await victorPosApi.getCustomers();
      final products = await victorPosApi.getProducts();
      final expenses = await victorPosApi.getExpenses();
      final reservations = await victorPosApi.getReservations();
      final services = await victorPosApi.getServices();
      final dresses = await victorPosApi.getDresses();
      final banks = await victorPosApi.getBanks();
      final userRoles = await victorPosApi.getUserRoles();
      final productCategories = await victorPosApi.getProductCategories();
      final expenseCategories = await victorPosApi.getExpenseCategories();
      final incomeCategories = await victorPosApi.getIncomeCategories();
      final incomes = await victorPosApi.getIncomes();
      final salesTrans = await victorPosApi.getSalesTransactions();
      final purchaseTrans = await victorPosApi.getPurchaseTransactions();
      final dueTrans = await victorPosApi.getDueTransactions();
      final quotations = await victorPosApi.getQuotations();
      final units = await victorPosApi.getUnits();
      final employees = await victorPosApi.getEmployees();
      final designations = await victorPosApi.getDesignations();
      final paidSalaries = await victorPosApi.getPaidSalaries();
      final dailyTrans = await victorPosApi.getDailyTransactions();
      final salesReturns = await victorPosApi.getSalesReturns();
      final purchaseReturns = await victorPosApi.getPurchaseReturns();
      final businessSettings = await victorPosApi.getBusinessSettings();
      final whatsappTemplates = await victorPosApi.getWhatsappTemplates();
      final generalSettings = await victorPosApi.getGeneralSettings();

      setState(() {
        _apiCustomers = customers.length;
        _apiProducts = products.length;
        _apiExpenses = expenses.length;
        _apiReservations = reservations.length;
        _apiServices = services.length;
        _apiDresses = dresses.length;
        _apiBanks = banks.length;
        _apiUserRoles = userRoles.length;
        _apiProductCategories = productCategories.length;
        _apiExpenseCategories = expenseCategories.length;
        _apiIncomeCategories = incomeCategories.length;
        _apiIncomes = incomes.length;
        _apiSalesTransactions = salesTrans.length;
        _apiPurchaseTransactions = purchaseTrans.length;
        _apiDueTransactions = dueTrans.length;
        _apiQuotations = quotations.length;
        _apiUnits = units.length;
        _apiEmployees = employees.length;
        _apiDesignations = designations.length;
        _apiPaidSalaries = paidSalaries.length;
        _apiDailyTransactions = dailyTrans.length;
        _apiSalesReturns = salesReturns.length;
        _apiPurchaseReturns = purchaseReturns.length;
        _apiBusinessSettings = businessSettings != null ? 1 : 0;
        _apiWhatsappTemplates = whatsappTemplates != null ? 1 : 0;
        _apiGeneralSettings = generalSettings != null ? 1 : 0;
      });
    } catch (e) {
      debugPrint('Error cargando conteos de API: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _migrationLog = '$_migrationLog\n[${DateTime.now().toString().substring(11, 19)}] $message';
    });
  }

  /// Obtiene el color asociado a cada sucursal
  Color _getTenantColor(String tenantId) {
    switch (tenantId) {
      case 'sde':
        return Colors.blue;
      case 'stg':
        return Colors.green;
      case 'sdo':
        return Colors.purple;
      case 'rom':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Cambia a otra sucursal (requiere recargar la página en web)
  Future<void> _switchTenant(String newTenantId) async {
    final tenant = TenantConfig.getTenantById(newTenantId);
    if (tenant == null) return;

    // Mostrar diálogo de confirmación con opción de recargar
    final shouldReload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: _getTenantColor(newTenantId)),
            const SizedBox(width: 8),
            const Text('Cambiar Sucursal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas cambiar a ${tenant.city}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En web, para cambiar la conexión Firebase se necesita recargar la página.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Base de datos: ${tenant.firebaseOptions.databaseURL}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Cambiar y Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTenantColor(newTenantId),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldReload == true) {
      // Guardar el nuevo tenant en localStorage
      html.window.localStorage['selected_tenant_id'] = newTenantId;

      // Actualizar estado local
      setState(() {
        _currentTenantId = newTenantId;
        _currentTenantName = tenant.displayName;
      });

      // Recargar la página para que Firebase se conecte a la nueva base de datos
      html.window.location.reload();
    }
  }

  // Métodos para migrar individualmente cada tabla
  Future<void> _migrateEntity(String name, Future<void> Function() migrateFn) async {
    setState(() {
      _isMigrating = true;
      _migrationLog = '';
    });
    _addLog('🚀 Iniciando sincronización de $name...');
    try {
      await migrateFn();
      await _loadApiCounts();
      _addLog('✅ Sincronización de $name completada');
    } catch (e) {
      _addLog('❌ Error: $e');
    }
    setState(() => _isMigrating = false);
  }

  Future<void> _migrateCustomersOnly() => _migrateEntity('Clientes', _migrateCustomers);
  Future<void> _migrateProductsOnly() => _migrateEntity('Productos', _migrateProducts);
  Future<void> _migrateExpensesOnly() => _migrateEntity('Gastos', _migrateExpenses);
  Future<void> _migrateReservationsOnly() => _migrateEntity('Reservaciones', _migrateReservations);
  Future<void> _migrateServicesOnly() => _migrateEntity('Paquetes de Servicios', _migrateServices);
  Future<void> _migrateDressesOnly() => _migrateEntity('Vestidos', _migrateDresses);
  Future<void> _migrateBanksOnly() => _migrateEntity('Bancos', _migrateBanks);
  Future<void> _migrateUserRolesOnly() => _migrateEntity('Roles de Usuario', _migrateUserRoles);
  Future<void> _migrateProductCategoriesOnly() => _migrateEntity('Categorías de Productos', _migrateProductCategories);
  Future<void> _migrateExpenseCategoriesOnly() => _migrateEntity('Categorías de Gastos', _migrateExpenseCategories);
  Future<void> _migrateIncomeCategoriesOnly() => _migrateEntity('Categorías de Ingresos', _migrateIncomeCategories);
  Future<void> _migrateIncomesOnly() => _migrateEntity('Ingresos', _migrateIncomes);
  Future<void> _migrateSalesTransactionsOnly() => _migrateEntity('Transacciones de Ventas', _migrateSalesTransactions);
  Future<void> _migratePurchaseTransactionsOnly() => _migrateEntity('Transacciones de Compras', _migratePurchaseTransactions);
  Future<void> _migrateDueTransactionsOnly() => _migrateEntity('Transacciones de Deudas', _migrateDueTransactions);
  Future<void> _migrateQuotationsOnly() => _migrateEntity('Cotizaciones', _migrateQuotations);
  Future<void> _migrateUnitsOnly() => _migrateEntity('Unidades de Medida', _migrateUnits);
  Future<void> _migrateEmployeesOnly() => _migrateEntity('Empleados', _migrateEmployees);
  Future<void> _migrateDesignationsOnly() => _migrateEntity('Designaciones', _migrateDesignations);
  Future<void> _migratePaidSalariesOnly() => _migrateEntity('Salarios Pagados', _migratePaidSalaries);
  Future<void> _migrateDailyTransactionsOnly() => _migrateEntity('Transacciones Diarias', _migrateDailyTransactions);
  Future<void> _migrateSalesReturnsOnly() => _migrateEntity('Devoluciones de Ventas', _migrateSalesReturns);
  Future<void> _migratePurchaseReturnsOnly() => _migrateEntity('Devoluciones de Compras', _migratePurchaseReturns);
  Future<void> _migrateBusinessSettingsOnly() => _migrateEntity('Config. Negocio', _migrateBusinessSettings);
  Future<void> _migrateWhatsappTemplatesOnly() => _migrateEntity('Plantillas WhatsApp', _migrateWhatsappTemplates);
  Future<void> _migrateGeneralSettingsOnly() => _migrateEntity('Config. General', _migrateGeneralSettings);

  Future<void> _migrateAll() async {
    setState(() {
      _isMigrating = true;
      _migrationLog = '';
    });

    _addLog('🚀 Iniciando migración completa...');

    try {
      await _migrateCustomers();
      await _migrateProducts();
      await _migrateExpenses();
      await _migrateReservations();
      await _migrateServices();
      await _migrateDresses();
      await _migrateBanks();
      await _migrateUserRoles();
      await _migrateProductCategories();
      await _migrateExpenseCategories();
      await _migrateIncomeCategories();
      await _migrateIncomes();
      await _migrateSalesTransactions();
      await _migratePurchaseTransactions();
      await _migrateDueTransactions();
      await _migrateQuotations();
      await _migrateUnits();
      await _migrateEmployees();
      await _migrateDesignations();
      await _migratePaidSalaries();
      await _migrateDailyTransactions();
      await _migrateSalesReturns();
      await _migratePurchaseReturns();
      await _migrateBusinessSettings();
      await _migrateWhatsappTemplates();
      await _migrateGeneralSettings();

      _addLog('✅ Migración completa finalizada exitosamente');
      await _loadApiCounts();
    } catch (e) {
      _addLog('❌ Error en migración: $e');
    }

    setState(() => _isMigrating = false);
  }

  Future<void> _migrateCustomers() async {
    _addLog('📦 Migrando clientes...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Customers').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createCustomer(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Clientes migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando clientes: $e');
    }
  }

  Future<void> _migrateProducts() async {
    _addLog('📦 Migrando productos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Products').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createProduct(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Productos migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando productos: $e');
    }
  }

  Future<void> _migrateExpenses() async {
    _addLog('📦 Migrando gastos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Expense').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createExpense(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Gastos migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando gastos: $e');
    }
  }

  Future<void> _migrateReservations() async {
    _addLog('📦 Migrando reservaciones...');
    try {
      // Las reservaciones están en Admin Panel/reservations (no por usuario)
      final snapshot = await FirebaseDatabase.instance.ref('Admin Panel/reservations').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createReservation(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Reservaciones migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando reservaciones: $e');
    }
  }

  Future<void> _migrateServices() async {
    _addLog('📦 Migrando paquetes de servicios...');
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Admin Panel/services').get();
      int migrated = 0;
      int skipped = 0;
      int errors = 0;

      if (!snapshot.exists) {
        _addLog('   ⚠ No hay datos de servicios en Firebase');
        return;
      }

      // Usar snapshot.children en lugar de snapshot.value para evitar errores de tipo
      final children = snapshot.children.toList();
      _addLog('   Debug: Encontrados ${children.length} registros usando children');

      for (var child in children) {
        try {
          final key = child.key;

          // Verificar que el child tenga valor
          if (child.value == null) {
            skipped++;
            continue;
          }

          // Intentar convertir el valor de forma segura
          Map<String, dynamic> data;
          try {
            final childValue = child.value;
            if (childValue is String) {
              // Si es String, probablemente es un dato corrupto
              skipped++;
              continue;
            } else if (childValue is Map) {
              data = _safeMapConvert(childValue);
            } else {
              skipped++;
              continue;
            }
          } catch (conversionError) {
            _addLog('   ⚠ Error convirtiendo servicio $key: $conversionError');
            skipped++;
            continue;
          }

          data['firebase_id'] = key.toString();
          final result = await victorPosApi.createService(data);
          if (result != null) migrated++;
        } catch (e) {
          errors++;
        }
      }

      _addLog('   ✓ Servicios migrados: $migrated${skipped > 0 ? ' (omitidos: $skipped)' : ''}${errors > 0 ? ' (errores: $errors)' : ''}');
    } catch (e) {
      _addLog('   ✗ Error migrando servicios: $e');
    }
  }

  Future<void> _migrateDresses() async {
    _addLog('📦 Migrando vestidos...');
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Admin Panel/dresses').get();
      int migrated = 0;
      int skipped = 0;
      int errors = 0;

      if (!snapshot.exists) {
        _addLog('   ⚠ No hay datos de vestidos en Firebase');
        return;
      }

      // Usar snapshot.children en lugar de snapshot.value para evitar errores de tipo
      final children = snapshot.children.toList();
      _addLog('   Debug: Encontrados ${children.length} registros usando children');

      for (var child in children) {
        try {
          final key = child.key;

          // Verificar que el child tenga valor
          if (child.value == null) {
            skipped++;
            continue;
          }

          // Intentar convertir el valor de forma segura
          Map<String, dynamic> data;
          try {
            final childValue = child.value;
            if (childValue is String) {
              // Si es String, probablemente es un dato corrupto
              skipped++;
              continue;
            } else if (childValue is Map) {
              data = _safeMapConvert(childValue);
            } else {
              skipped++;
              continue;
            }
          } catch (conversionError) {
            _addLog('   ⚠ Error convirtiendo vestido $key: $conversionError');
            skipped++;
            continue;
          }

          data['firebase_id'] = key.toString();
          final result = await victorPosApi.createDress(data);
          if (result != null) migrated++;
        } catch (e) {
          errors++;
        }
      }

      _addLog('   ✓ Vestidos migrados: $migrated${skipped > 0 ? ' (omitidos: $skipped)' : ''}${errors > 0 ? ' (errores: $errors)' : ''}');
    } catch (e) {
      _addLog('   ✗ Error migrando vestidos: $e');
    }
  }

  Future<void> _migrateBanks() async {
    _addLog('📦 Migrando bancos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Banks').get();
      int migrated = 0;
      int skipped = 0;
      int errors = 0;

      for (var child in snapshot.children) {
        try {
          // Verificar que el valor sea un Map, no un String
          if (child.value == null || child.value is! Map) {
            skipped++;
            continue;
          }
          final data = _safeMapConvert(child.value);
          data['firebase_id'] = child.key;
          final result = await victorPosApi.createBank(data);
          if (result != null) migrated++;
        } catch (e) {
          errors++;
          // Continuar con el siguiente registro
        }
      }

      _addLog('   ✓ Bancos migrados: $migrated/${snapshot.children.length}${skipped > 0 ? ' (omitidos: $skipped)' : ''}${errors > 0 ? ' (errores: $errors)' : ''}');
    } catch (e) {
      _addLog('   ✗ Error migrando bancos: $e');
    }
  }

  Future<void> _migrateUserRoles() async {
    _addLog('📦 Migrando roles de usuario...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/User Role').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createUserRole(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Roles de usuario migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando roles de usuario: $e');
    }
  }

  Future<void> _migrateProductCategories() async {
    _addLog('📦 Migrando categorías de productos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Categories').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createProductCategory(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Categorías de productos migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando categorías: $e');
    }
  }

  Future<void> _migrateExpenseCategories() async {
    _addLog('📦 Migrando categorías de gastos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Expense Category').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createExpenseCategory(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Categorías de gastos migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando categorías de gastos: $e');
    }
  }

  Future<void> _migrateIncomeCategories() async {
    _addLog('📦 Migrando categorías de ingresos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Income Category').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createIncomeCategory(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Categorías de ingresos migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando categorías de ingresos: $e');
    }
  }

  Future<void> _migrateIncomes() async {
    _addLog('📦 Migrando ingresos...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Income').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createIncome(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Ingresos migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando ingresos: $e');
    }
  }

  Future<void> _migrateSalesTransactions() async {
    _addLog('📦 Migrando transacciones de ventas...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Sales Transition').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        data['firebase_key'] = child.key;
        if (data['productList'] != null) {
          data['products_json'] = jsonEncode(data['productList']);
        }
        final result = await victorPosApi.createSaleTransaction(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Transacciones de ventas migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando transacciones de ventas: $e');
    }
  }

  Future<void> _migratePurchaseTransactions() async {
    _addLog('📦 Migrando transacciones de compras...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Purchase Transition').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        data['firebase_key'] = child.key;
        if (data['productList'] != null) {
          data['products_json'] = jsonEncode(data['productList']);
        }
        final result = await victorPosApi.createPurchaseTransaction(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Transacciones de compras migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando transacciones de compras: $e');
    }
  }

  Future<void> _migrateDueTransactions() async {
    _addLog('📦 Migrando transacciones de deudas...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Due Transaction').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createDueTransaction(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Transacciones de deudas migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando transacciones de deudas: $e');
    }
  }

  Future<void> _migrateQuotations() async {
    _addLog('📦 Migrando cotizaciones...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Sales Quotation').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        if (data['productList'] != null) {
          data['products_json'] = jsonEncode(data['productList']);
        }
        final result = await victorPosApi.createQuotation(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Cotizaciones migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando cotizaciones: $e');
    }
  }

  Future<void> _migrateUnits() async {
    _addLog('📦 Migrando unidades de medida...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Units').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createUnit(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Unidades migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando unidades: $e');
    }
  }

  Future<void> _migrateEmployees() async {
    _addLog('📦 Migrando empleados...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Employee').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        data['employee_id'] = data['id'];
        final result = await victorPosApi.createEmployee(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Empleados migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando empleados: $e');
    }
  }

  Future<void> _migrateDesignations() async {
    _addLog('📦 Migrando designaciones...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Designation').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        data['designation_id'] = data['id'];
        final result = await victorPosApi.createDesignation(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Designaciones migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando designaciones: $e');
    }
  }

  Future<void> _migratePaidSalaries() async {
    _addLog('📦 Migrando salarios pagados...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Paid Salary').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createPaidSalary(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Salarios pagados migrados: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando salarios pagados: $e');
    }
  }

  Future<void> _migrateDailyTransactions() async {
    _addLog('📦 Migrando transacciones diarias...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Daily Transaction').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        final result = await victorPosApi.createDailyTransaction(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Transacciones diarias migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando transacciones diarias: $e');
    }
  }

  Future<void> _migrateSalesReturns() async {
    _addLog('📦 Migrando devoluciones de ventas...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Sales Return').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        if (data['productList'] != null) {
          data['products'] = jsonEncode(data['productList']);
        }
        final result = await victorPosApi.createSalesReturn(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Devoluciones de ventas migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando devoluciones de ventas: $e');
    }
  }

  Future<void> _migratePurchaseReturns() async {
    _addLog('📦 Migrando devoluciones de compras...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/    Return').get();
      int migrated = 0;

      for (var child in snapshot.children) {
        final data = _safeMapConvert(child.value);
        data['firebase_id'] = child.key;
        if (data['productList'] != null) {
          data['products'] = jsonEncode(data['productList']);
        }
        final result = await victorPosApi.createPurchaseReturn(data);
        if (result != null) migrated++;
      }

      _addLog('   ✓ Devoluciones de compras migradas: $migrated/${snapshot.children.length}');
    } catch (e) {
      _addLog('   ✗ Error migrando devoluciones de compras: $e');
    }
  }

  Future<void> _migrateBusinessSettings() async {
    _addLog('📦 Migrando configuración del negocio...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Personal Information').get();

      if (snapshot.exists) {
        final data = _safeMapConvert(snapshot.value);
        final result = await victorPosApi.saveBusinessSettings(data);
        if (result != null) {
          _addLog('   ✓ Configuración del negocio migrada');
        } else {
          _addLog('   ✗ Error al guardar configuración del negocio');
        }
      } else {
        _addLog('   ⚠ No hay configuración del negocio en Firebase');
      }
    } catch (e) {
      _addLog('   ✗ Error migrando configuración del negocio: $e');
    }
  }

  Future<void> _migrateWhatsappTemplates() async {
    _addLog('📦 Migrando plantillas de WhatsApp...');
    try {
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref('$userId/Whatsapp Marketing Template').get();

      if (snapshot.exists) {
        final data = _safeMapConvert(snapshot.value);
        final result = await victorPosApi.saveWhatsappTemplates(data);
        if (result != null) {
          _addLog('   ✓ Plantillas de WhatsApp migradas');
        } else {
          _addLog('   ✗ Error al guardar plantillas de WhatsApp');
        }
      } else {
        _addLog('   ⚠ No hay plantillas de WhatsApp en Firebase');
      }
    } catch (e) {
      _addLog('   ✗ Error migrando plantillas de WhatsApp: $e');
    }
  }

  Future<void> _migrateGeneralSettings() async {
    _addLog('📦 Migrando configuración general...');
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Admin Panel/General Setting').get();

      if (snapshot.exists) {
        final data = _safeMapConvert(snapshot.value);
        final result = await victorPosApi.saveGeneralSettings(data);
        if (result != null) {
          _addLog('   ✓ Configuración general migrada');
        } else {
          _addLog('   ✗ Error al guardar configuración general');
        }
      } else {
        _addLog('   ⚠ No hay configuración general en Firebase');
      }
    } catch (e) {
      _addLog('   ✗ Error migrando configuración general: $e');
    }
  }

  Widget _buildEntityCard(String title, int firebaseCount, int apiCount, IconData icon, Color color, {VoidCallback? onMigrate}) {
    final bool isSynced = apiCount >= firebaseCount && firebaseCount > 0;
    final bool needsSync = firebaseCount > 0 && apiCount < firebaseCount;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Firebase: $firebaseCount', style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('API: $apiCount', style: TextStyle(color: Colors.blue[800], fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onMigrate != null) ...[
              // Botón de sincronización mejorado
              ElevatedButton.icon(
                onPressed: (_isMigrating || !_isApiConnected) ? null : onMigrate,
                icon: _isMigrating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(needsSync ? Icons.sync : Icons.cloud_upload, size: 16),
                label: Text(_isMigrating ? '...' : 'Sync', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: needsSync ? Colors.orange : color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(70, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Indicador de estado
            if (isSynced)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
              )
            else if (needsSync)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migración de Base de Datos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de sucursal
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, color: Colors.blue, size: 28),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Seleccionar Sucursal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _currentTenantId.isNotEmpty ? _currentTenantId : 'sde',
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                                items: TenantConfig.allTenants.map((tenant) {
                                  return DropdownMenuItem<String>(
                                    value: tenant.id,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getTenantColor(tenant.id).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            tenant.id.toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: _getTenantColor(tenant.id),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                tenant.city,
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                tenant.firebaseOptions.databaseURL ?? '',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: _isMigrating ? null : (String? newValue) async {
                                  if (newValue != null && newValue != _currentTenantId) {
                                    await _switchTenant(newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '⚠️ En web: Para cambiar de base de datos Firebase se requiere recargar la página',
                            style: TextStyle(fontSize: 11, color: Colors.orange[800], fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status de conexión
                  Card(
                    color: _isApiConnected ? Colors.green[50] : Colors.red[50],
                    child: ListTile(
                      leading: Icon(
                        _isApiConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: _isApiConnected ? Colors.green : Colors.red,
                      ),
                      title: Text(_isApiConnected ? 'API Conectada' : 'API Desconectada'),
                      subtitle: const Text('sistema.victorguzmanfotografia.com'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Datos Principales
                  _buildSection('📊 Datos Principales', [
                    _buildEntityCard('Clientes', _firebaseCustomers, _apiCustomers, Icons.people, Colors.blue, onMigrate: _migrateCustomersOnly),
                    _buildEntityCard('Productos', _firebaseProducts, _apiProducts, Icons.inventory, Colors.orange, onMigrate: _migrateProductsOnly),
                    _buildEntityCard('Gastos', _firebaseExpenses, _apiExpenses, Icons.receipt_long, Colors.red, onMigrate: _migrateExpensesOnly),
                    _buildEntityCard('Reservaciones', _firebaseReservations, _apiReservations, Icons.calendar_month, Colors.purple, onMigrate: _migrateReservationsOnly),
                  ]),

                  // Catálogo
                  _buildSection('👗 Catálogo', [
                    _buildEntityCard('Paquetes de Servicios', _firebaseServices, _apiServices, Icons.photo_camera, Colors.teal, onMigrate: _migrateServicesOnly),
                    _buildEntityCard('Vestidos', _firebaseDresses, _apiDresses, Icons.checkroom, Colors.pink, onMigrate: _migrateDressesOnly),
                  ]),

                  // Configuración
                  _buildSection('⚙️ Configuración', [
                    _buildEntityCard('Bancos', _firebaseBanks, _apiBanks, Icons.account_balance, Colors.indigo, onMigrate: _migrateBanksOnly),
                    _buildEntityCard('Roles de Usuario', _firebaseUserRoles, _apiUserRoles, Icons.admin_panel_settings, Colors.brown, onMigrate: _migrateUserRolesOnly),
                    _buildEntityCard('Categorías de Productos', _firebaseCategories, _apiProductCategories, Icons.category, Colors.cyan, onMigrate: _migrateProductCategoriesOnly),
                    _buildEntityCard('Categorías de Gastos', _firebaseExpenseCategories, _apiExpenseCategories, Icons.label, Colors.deepOrange, onMigrate: _migrateExpenseCategoriesOnly),
                    _buildEntityCard('Categorías de Ingresos', _firebaseIncomeCategories, _apiIncomeCategories, Icons.label_outline, Colors.lightGreen, onMigrate: _migrateIncomeCategoriesOnly),
                    _buildEntityCard('Unidades de Medida', _firebaseUnits, _apiUnits, Icons.straighten, Colors.blueGrey, onMigrate: _migrateUnitsOnly),
                    _buildEntityCard('Config. Negocio', _firebaseBusinessSettings, _apiBusinessSettings, Icons.business, Colors.blue, onMigrate: _migrateBusinessSettingsOnly),
                    _buildEntityCard('Plantillas WhatsApp', _firebaseWhatsappTemplates, _apiWhatsappTemplates, Icons.chat, Colors.green, onMigrate: _migrateWhatsappTemplatesOnly),
                    _buildEntityCard('Config. General', _firebaseGeneralSettings, _apiGeneralSettings, Icons.settings, Colors.grey, onMigrate: _migrateGeneralSettingsOnly),
                  ]),

                  // Transacciones
                  _buildSection('💰 Transacciones', [
                    _buildEntityCard('Ingresos', _firebaseIncomes, _apiIncomes, Icons.arrow_downward, Colors.green, onMigrate: _migrateIncomesOnly),
                    _buildEntityCard('Transacciones de Ventas', _firebaseSalesTransactions, _apiSalesTransactions, Icons.point_of_sale, Colors.blue, onMigrate: _migrateSalesTransactionsOnly),
                    _buildEntityCard('Transacciones de Compras', _firebasePurchaseTransactions, _apiPurchaseTransactions, Icons.shopping_cart, Colors.amber, onMigrate: _migratePurchaseTransactionsOnly),
                    _buildEntityCard('Transacciones de Deudas', _firebaseDueTransactions, _apiDueTransactions, Icons.money_off, Colors.red, onMigrate: _migrateDueTransactionsOnly),
                    _buildEntityCard('Cotizaciones', _firebaseQuotations, _apiQuotations, Icons.request_quote, Colors.purple, onMigrate: _migrateQuotationsOnly),
                    _buildEntityCard('Transacciones Diarias', _firebaseDailyTransactions, _apiDailyTransactions, Icons.today, Colors.cyan, onMigrate: _migrateDailyTransactionsOnly),
                    _buildEntityCard('Devoluciones de Ventas', _firebaseSalesReturns, _apiSalesReturns, Icons.assignment_return, Colors.orange, onMigrate: _migrateSalesReturnsOnly),
                    _buildEntityCard('Devoluciones de Compras', _firebasePurchaseReturns, _apiPurchaseReturns, Icons.keyboard_return, Colors.deepPurple, onMigrate: _migratePurchaseReturnsOnly),
                  ]),

                  // HRM
                  _buildSection('👥 Recursos Humanos (HRM)', [
                    _buildEntityCard('Empleados', _firebaseEmployees, _apiEmployees, Icons.badge, Colors.teal, onMigrate: _migrateEmployeesOnly),
                    _buildEntityCard('Designaciones', _firebaseDesignations, _apiDesignations, Icons.work, Colors.indigo, onMigrate: _migrateDesignationsOnly),
                    _buildEntityCard('Salarios Pagados', _firebasePaidSalaries, _apiPaidSalaries, Icons.payments, Colors.green, onMigrate: _migratePaidSalariesOnly),
                  ]),

                  const SizedBox(height: 24),

                  // Botón de migración
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isMigrating || !_isApiConnected) ? null : _migrateAll,
                      icon: _isMigrating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload),
                      label: Text(_isMigrating ? 'Migrando...' : 'Migrar Todo a API Propia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // Log de migración
                  if (_migrationLog.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Log de Migración:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _migrationLog,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
