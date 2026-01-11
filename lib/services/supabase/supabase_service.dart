import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para inicializar y gestionar la conexión con Supabase
/// Funciona en paralelo con Firebase durante la migración
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _supabaseUrl = 'https://mfduhbrwfjmkfgsqeygq.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_Q0q1NFHO_68T4_x1l1fbAA_cubF320f';

  bool _initialized = false;

  /// Obtener el cliente de Supabase
  SupabaseClient get client => Supabase.instance.client;

  /// Verificar si Supabase está inicializado
  bool get isInitialized => _initialized;

  /// Inicializar Supabase
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚡ Supabase ya está inicializado');
      return;
    }

    try {
      debugPrint('🚀 Inicializando Supabase...');

      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: kDebugMode,
      );

      _initialized = true;
      debugPrint('✅ Supabase inicializado correctamente');
      debugPrint('📍 URL: $_supabaseUrl');
    } catch (e) {
      debugPrint('❌ Error al inicializar Supabase: $e');
      rethrow;
    }
  }

  /// Obtener el usuario actual de Supabase
  User? get currentUser => client.auth.currentUser;

  /// Verificar si hay un usuario autenticado
  bool get isAuthenticated => currentUser != null;

  /// Cerrar sesión
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ===========================================
  // MÉTODOS DE ACCESO A DATOS
  // ===========================================

  /// Obtener referencia a una tabla
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Obtener todos los registros de una tabla
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final response = await client.from(table).select();
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtener registros filtrados por branch_id
  Future<List<Map<String, dynamic>>> getByBranch(String table, String branchId) async {
    final response = await client
        .from(table)
        .select()
        .eq('branch_id', branchId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Insertar un registro
  Future<Map<String, dynamic>?> insert(String table, Map<String, dynamic> data) async {
    final response = await client
        .from(table)
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Actualizar un registro
  Future<void> update(String table, String id, Map<String, dynamic> data) async {
    await client
        .from(table)
        .update(data)
        .eq('id', id);
  }

  /// Eliminar un registro
  Future<void> delete(String table, String id) async {
    await client
        .from(table)
        .delete()
        .eq('id', id);
  }

  // ===========================================
  // MÉTODOS ESPECÍFICOS POR ENTIDAD
  // ===========================================

  /// Obtener todas las sucursales
  Future<List<Map<String, dynamic>>> getBranches() async {
    return await getAll('branches');
  }

  /// Obtener clientes por sucursal
  Future<List<Map<String, dynamic>>> getCustomers(String branchId) async {
    return await getByBranch('customers', branchId);
  }

  /// Obtener productos por sucursal
  Future<List<Map<String, dynamic>>> getProducts(String branchId) async {
    return await getByBranch('products', branchId);
  }

  /// Obtener servicios por sucursal
  Future<List<Map<String, dynamic>>> getServices(String branchId) async {
    return await getByBranch('services', branchId);
  }

  /// Obtener ventas por sucursal
  Future<List<Map<String, dynamic>>> getSales(String branchId) async {
    return await getByBranch('sales', branchId);
  }

  /// Obtener reservaciones por sucursal
  Future<List<Map<String, dynamic>>> getReservations(String branchId) async {
    return await getByBranch('reservations', branchId);
  }

  /// Obtener gastos por sucursal
  Future<List<Map<String, dynamic>>> getExpenses(String branchId) async {
    return await getByBranch('expenses', branchId);
  }
}

/// Instancia global del servicio Supabase
final supabaseService = SupabaseService();
