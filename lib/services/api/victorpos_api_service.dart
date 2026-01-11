import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Servicio para conectar con la API propia de VictorPos
class VictorPosApiService {
  static final VictorPosApiService _instance = VictorPosApiService._internal();
  factory VictorPosApiService() => _instance;
  VictorPosApiService._internal();

  static const String baseUrl = 'https://sistema.victorguzmanfotografia.com/api';

  String? _token;
  String? _branchId;

  /// Lee el branch_id directamente de localStorage (fuente de verdad)
  String? _readLocalStorageBranch() {
    try {
      return html.window.localStorage['selected_tenant_id'];
    } catch (e) {
      return null;
    }
  }

  /// Headers con autenticación y branch ID para multi-tenant
  /// CRÍTICO: SIEMPRE lee de localStorage para garantizar consistencia entre sucursales
  Map<String, String> get _headers {
    // Leer directamente de localStorage como fuente de verdad
    final localStorageBranch = _readLocalStorageBranch();
    final effectiveBranch = localStorageBranch ?? _branchId;

    // 🔴 DEBUG - REMOVER cuando se resuelva el bug
    debugPrint('');
    debugPrint('🔴🔴🔴 [VictorPosApiService._headers] 🔴🔴🔴');
    debugPrint('  📦 localStorage[selected_tenant_id]: $localStorageBranch');
    debugPrint('  📦 _branchId (cache): $_branchId');
    debugPrint('  ✅ USANDO BRANCH: $effectiveBranch');
    debugPrint('🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴');
    debugPrint('');

    // Sincronizar cache si hay desincronización
    if (localStorageBranch != null && localStorageBranch != _branchId) {
      debugPrint('⚠️ DESINCRONIZACIÓN! Actualizando cache: $_branchId -> $localStorageBranch');
      _branchId = localStorageBranch;
    }

    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (effectiveBranch != null && effectiveBranch.isNotEmpty) 'X-Branch-Id': effectiveBranch,
    };
  }

  /// Cambiar sucursal activa
  void setBranchId(String branchId) {
    _branchId = branchId;
    debugPrint('🏢 Sucursal cambiada a: $branchId');
  }

  /// Verificar si está autenticado
  bool get isAuthenticated => _token != null;

  /// Branch ID actual
  String? get currentBranchId => _branchId;

  // ==========================================
  // AUTENTICACIÓN
  // ==========================================

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        // Solo usar branch_id del usuario si no se ha configurado uno específico
        if (_branchId == null || _branchId!.isEmpty) {
          _branchId = data['user']['branch_id'];
        }
        debugPrint('✅ Login exitoso: ${data['user']['email']} (branch: $_branchId)');
      }

      return data;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return {'error': e.toString()};
    }
  }

  /// Registrar usuario
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String role = 'user',
    String branchId = 'stg',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'branch_id': branchId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _branchId = data['user']['branch_id'];
      }

      return data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Obtener sucursales
  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/branches'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['branches']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo sucursales: $e');
      return [];
    }
  }

  /// Logout
  void logout() {
    _token = null;
    _branchId = null;
  }

  // ==========================================
  // CLIENTES
  // ==========================================

  /// Obtener todos los clientes
  Future<List<Map<String, dynamic>>> getCustomers({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['customers']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo clientes: $e');
      return [];
    }
  }

  /// Crear cliente
  Future<Map<String, dynamic>?> createCustomer(Map<String, dynamic> customer) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: _headers,
        body: jsonEncode(customer),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['customer'];
      }
      debugPrint('Error creando cliente: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando cliente: $e');
      return null;
    }
  }

  // ==========================================
  // PRODUCTOS
  // ==========================================

  /// Obtener todos los productos
  Future<List<Map<String, dynamic>>> getProducts({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['products']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo productos: $e');
      return [];
    }
  }

  /// Crear producto
  Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: jsonEncode(product),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['product'];
      }
      debugPrint('Error creando producto: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando producto: $e');
      return null;
    }
  }

  // ==========================================
  // VENTAS
  // ==========================================

  /// Obtener todas las ventas
  Future<List<Map<String, dynamic>>> getSales({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sales']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo ventas: $e');
      return [];
    }
  }

  /// Crear venta
  Future<Map<String, dynamic>?> createSale(Map<String, dynamic> sale) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sales'),
        headers: _headers,
        body: jsonEncode(sale),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['sale'];
      }
      debugPrint('Error creando venta: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando venta: $e');
      return null;
    }
  }

  // ==========================================
  // GASTOS
  // ==========================================

  /// Obtener todos los gastos
  Future<List<Map<String, dynamic>>> getExpenses({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['expenses']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo gastos: $e');
      return [];
    }
  }

  /// Crear gasto
  Future<Map<String, dynamic>?> createExpense(Map<String, dynamic> expense) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: _headers,
        body: jsonEncode(expense),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['expense'];
      }
      debugPrint('Error creando gasto: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando gasto: $e');
      return null;
    }
  }

  // ==========================================
  // RESERVACIONES
  // ==========================================

  /// Obtener todas las reservaciones
  Future<List<Map<String, dynamic>>> getReservations({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservations?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['reservations']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo reservaciones: $e');
      return [];
    }
  }

  /// Crear reservación
  Future<Map<String, dynamic>?> createReservation(Map<String, dynamic> reservation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reservations'),
        headers: _headers,
        body: jsonEncode(reservation),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['reservation'];
      }
      debugPrint('Error creando reservación: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando reservación: $e');
      return null;
    }
  }

  // ==========================================
  // PAQUETES DE SERVICIOS
  // ==========================================

  /// Obtener todos los paquetes de servicios
  Future<List<Map<String, dynamic>>> getServices({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['services']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo servicios: $e');
      return [];
    }
  }

  /// Crear paquete de servicio
  Future<Map<String, dynamic>?> createService(Map<String, dynamic> service) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/services'),
        headers: _headers,
        body: jsonEncode(service),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['service'];
      }
      debugPrint('Error creando servicio: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando servicio: $e');
      return null;
    }
  }

  // ==========================================
  // VESTIDOS
  // ==========================================

  /// Obtener todos los vestidos
  Future<List<Map<String, dynamic>>> getDresses({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dresses?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['dresses']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo vestidos: $e');
      return [];
    }
  }

  /// Crear vestido
  Future<Map<String, dynamic>?> createDress(Map<String, dynamic> dress) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dresses'),
        headers: _headers,
        body: jsonEncode(dress),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['dress'];
      }
      debugPrint('Error creando vestido: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creando vestido: $e');
      return null;
    }
  }

  // ==========================================
  // BANCOS
  // ==========================================

  Future<List<Map<String, dynamic>>> getBanks({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/banks?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['banks']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo bancos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createBank(Map<String, dynamic> bank) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/banks'),
        headers: _headers,
        body: jsonEncode(bank),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['bank'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando banco: $e');
      return null;
    }
  }

  // ==========================================
  // ROLES DE USUARIO
  // ==========================================

  Future<List<Map<String, dynamic>>> getUserRoles({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-roles?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['user_roles']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo roles de usuario: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createUserRole(Map<String, dynamic> userRole) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-roles'),
        headers: _headers,
        body: jsonEncode(userRole),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['user_role'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando rol de usuario: $e');
      return null;
    }
  }

  // ==========================================
  // CATEGORÍAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/products'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['categories']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo categorías de productos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createProductCategory(Map<String, dynamic> category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/products'),
        headers: _headers,
        body: jsonEncode(category),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['category'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando categoría de producto: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/expenses'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['categories']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo categorías de gastos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createExpenseCategory(Map<String, dynamic> category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/expenses'),
        headers: _headers,
        body: jsonEncode(category),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['category'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando categoría de gasto: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getIncomeCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/incomes'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['categories']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo categorías de ingresos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createIncomeCategory(Map<String, dynamic> category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/incomes'),
        headers: _headers,
        body: jsonEncode(category),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['category'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando categoría de ingreso: $e');
      return null;
    }
  }

  // ==========================================
  // INGRESOS
  // ==========================================

  Future<List<Map<String, dynamic>>> getIncomes({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/incomes?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['incomes']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo ingresos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createIncome(Map<String, dynamic> income) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/incomes'),
        headers: _headers,
        body: jsonEncode(income),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['income'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando ingreso: $e');
      return null;
    }
  }

  // ==========================================
  // TRANSACCIONES DE VENTAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getSalesTransactions({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/sales?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sales']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo transacciones de ventas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createSaleTransaction(Map<String, dynamic> sale) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/sales'),
        headers: _headers,
        body: jsonEncode(sale),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['sale'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando transacción de venta: $e');
      return null;
    }
  }

  // ==========================================
  // TRANSACCIONES DE COMPRAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getPurchaseTransactions({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/purchases?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['purchases']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo transacciones de compras: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createPurchaseTransaction(Map<String, dynamic> purchase) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/purchases'),
        headers: _headers,
        body: jsonEncode(purchase),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['purchase'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando transacción de compra: $e');
      return null;
    }
  }

  // ==========================================
  // TRANSACCIONES DE DEUDAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getDueTransactions({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/due?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['due_transactions']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo transacciones de deudas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createDueTransaction(Map<String, dynamic> due) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/due'),
        headers: _headers,
        body: jsonEncode(due),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['due_transaction'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando transacción de deuda: $e');
      return null;
    }
  }

  // ==========================================
  // COTIZACIONES
  // ==========================================

  Future<List<Map<String, dynamic>>> getQuotations({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/quotations?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['quotations']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo cotizaciones: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createQuotation(Map<String, dynamic> quotation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/quotations'),
        headers: _headers,
        body: jsonEncode(quotation),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['quotation'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando cotización: $e');
      return null;
    }
  }

  // ==========================================
  // UNIDADES DE MEDIDA
  // ==========================================

  Future<List<Map<String, dynamic>>> getUnits() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/units'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['units']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo unidades: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createUnit(Map<String, dynamic> unit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/units'),
        headers: _headers,
        body: jsonEncode(unit),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['unit'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando unidad: $e');
      return null;
    }
  }

  // ==========================================
  // HRM - EMPLEADOS
  // ==========================================

  Future<List<Map<String, dynamic>>> getEmployees({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hrm/employees?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['employees']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo empleados: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createEmployee(Map<String, dynamic> employee) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hrm/employees'),
        headers: _headers,
        body: jsonEncode(employee),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['employee'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando empleado: $e');
      return null;
    }
  }

  // ==========================================
  // HRM - DESIGNACIONES
  // ==========================================

  Future<List<Map<String, dynamic>>> getDesignations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hrm/designations'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['designations']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo designaciones: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createDesignation(Map<String, dynamic> designation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hrm/designations'),
        headers: _headers,
        body: jsonEncode(designation),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['designation'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando designación: $e');
      return null;
    }
  }

  // ==========================================
  // HRM - SALARIOS PAGADOS
  // ==========================================

  Future<List<Map<String, dynamic>>> getPaidSalaries({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hrm/paid-salaries?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['paid_salaries']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo salarios pagados: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createPaidSalary(Map<String, dynamic> salary) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hrm/paid-salaries'),
        headers: _headers,
        body: jsonEncode(salary),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['paid_salary'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando salario pagado: $e');
      return null;
    }
  }

  // ==========================================
  // TRANSACCIONES DIARIAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getDailyTransactions({int limit = 5000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-transactions?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['daily_transactions']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo transacciones diarias: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createDailyTransaction(Map<String, dynamic> transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-transactions'),
        headers: _headers,
        body: jsonEncode(transaction),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['daily_transaction'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando transacción diaria: $e');
      return null;
    }
  }

  // ==========================================
  // DEVOLUCIONES DE VENTAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getSalesReturns({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/returns/sales?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sales_returns']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo devoluciones de ventas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createSalesReturn(Map<String, dynamic> salesReturn) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/returns/sales'),
        headers: _headers,
        body: jsonEncode(salesReturn),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['sales_return'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando devolución de venta: $e');
      return null;
    }
  }

  // ==========================================
  // DEVOLUCIONES DE COMPRAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getPurchaseReturns({int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/returns/purchases?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['purchase_returns']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo devoluciones de compras: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createPurchaseReturn(Map<String, dynamic> purchaseReturn) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/returns/purchases'),
        headers: _headers,
        body: jsonEncode(purchaseReturn),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['purchase_return'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creando devolución de compra: $e');
      return null;
    }
  }

  // ==========================================
  // CONFIGURACIÓN DEL NEGOCIO
  // ==========================================

  Future<Map<String, dynamic>?> getBusinessSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/business'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['business_settings'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo configuración del negocio: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveBusinessSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/business'),
        headers: _headers,
        body: jsonEncode(settings),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['business_settings'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error guardando configuración del negocio: $e');
      return null;
    }
  }

  // ==========================================
  // PLANTILLAS DE WHATSAPP
  // ==========================================

  Future<Map<String, dynamic>?> getWhatsappTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/whatsapp-templates'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['whatsapp_templates'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo plantillas de WhatsApp: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveWhatsappTemplates(Map<String, dynamic> templates) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/whatsapp-templates'),
        headers: _headers,
        body: jsonEncode(templates),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['whatsapp_templates'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error guardando plantillas de WhatsApp: $e');
      return null;
    }
  }

  // ==========================================
  // CONFIGURACIÓN GENERAL
  // ==========================================

  Future<Map<String, dynamic>?> getGeneralSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/general'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['general_settings'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo configuración general: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveGeneralSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/general'),
        headers: _headers,
        body: jsonEncode(settings),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['general_settings'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error guardando configuración general: $e');
      return null;
    }
  }

  // ==========================================
  // HEALTH CHECK
  // ==========================================

  /// Verificar estado de la API
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('https://sistema.victorguzmanfotografia.com/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Instancia global del servicio
final victorPosApi = VictorPosApiService();
