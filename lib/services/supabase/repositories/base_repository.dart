import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../supabase_auth_service.dart';

/// Repositorio base para operaciones CRUD con Supabase
/// Todos los repositorios específicos extienden de esta clase
abstract class BaseRepository<T> {
  /// Nombre de la tabla en Supabase
  abstract final String tableName;

  /// Cliente de Supabase
  SupabaseClient get client => supabaseService.client;

  /// Branch ID del usuario actual (para filtrar por sucursal)
  String? get currentBranchId => supabaseAuth.currentBranchId;

  /// Convertir un Map a modelo
  T fromMap(Map<String, dynamic> map);

  /// Convertir un modelo a Map
  Map<String, dynamic> toMap(T model);

  // =========================================
  // OPERACIONES DE LECTURA
  // =========================================

  /// Obtener todos los registros (filtrados por branch_id)
  Future<List<T>> getAll() async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) {
        debugPrint('⚠️ $tableName: No hay branch_id');
        return [];
      }

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener $tableName: $e');
      return [];
    }
  }

  /// Obtener un registro por ID
  Future<T?> getById(String id) async {
    try {
      final response = await client
          .from(tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return fromMap(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error al obtener $tableName por ID: $e');
      return null;
    }
  }

  /// Buscar registros por un campo específico
  Future<List<T>> findBy(String field, dynamic value) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .eq(field, value);

      return (response as List)
          .map((item) => fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al buscar en $tableName: $e');
      return [];
    }
  }

  /// Buscar registros que contengan texto
  Future<List<T>> search(String field, String query) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .ilike(field, '%$query%');

      return (response as List)
          .map((item) => fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al buscar en $tableName: $e');
      return [];
    }
  }

  // =========================================
  // OPERACIONES DE ESCRITURA
  // =========================================

  /// Insertar un nuevo registro
  Future<T?> insert(T model) async {
    try {
      final data = toMap(model);
      data['branch_id'] = currentBranchId;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(tableName)
          .insert(data)
          .select()
          .single();

      debugPrint('✅ Insertado en $tableName');
      return fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('❌ Error al insertar en $tableName: $e');
      return null;
    }
  }

  /// Actualizar un registro existente
  Future<bool> update(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from(tableName)
          .update(updates)
          .eq('id', id);

      debugPrint('✅ Actualizado en $tableName: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Error al actualizar $tableName: $e');
      return false;
    }
  }

  /// Eliminar un registro
  Future<bool> delete(String id) async {
    try {
      await client
          .from(tableName)
          .delete()
          .eq('id', id);

      debugPrint('✅ Eliminado de $tableName: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Error al eliminar de $tableName: $e');
      return false;
    }
  }

  /// Insertar múltiples registros
  Future<bool> insertMany(List<T> models) async {
    try {
      final data = models.map((m) {
        final map = toMap(m);
        map['branch_id'] = currentBranchId;
        map['created_at'] = DateTime.now().toIso8601String();
        return map;
      }).toList();

      await client.from(tableName).insert(data);

      debugPrint('✅ Insertados ${models.length} registros en $tableName');
      return true;
    } catch (e) {
      debugPrint('❌ Error al insertar múltiples en $tableName: $e');
      return false;
    }
  }

  // =========================================
  // SUSCRIPCIONES EN TIEMPO REAL
  // =========================================

  /// Suscribirse a cambios en la tabla
  RealtimeChannel subscribe({
    required void Function(List<T>) onData,
    void Function(Object error)? onError,
  }) {
    final branchId = currentBranchId;

    return client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: branchId != null
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'branch_id',
                  value: branchId,
                )
              : null,
          callback: (payload) async {
            // Recargar todos los datos cuando hay cambios
            final data = await getAll();
            onData(data);
          },
        )
        .subscribe();
  }

  /// Cancelar suscripción
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
