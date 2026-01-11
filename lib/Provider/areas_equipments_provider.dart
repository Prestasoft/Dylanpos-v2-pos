// areas_equipments_provider.dart - Migrado a PostgreSQL API
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/admin_panel_models.dart';
import '../services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Provider de áreas - Usa PostgreSQL API
final areasProvider = AsyncNotifierProvider<AreasNotifier, List<Area>>(
  AreasNotifier.new,
);

/// Provider de equipos - Usa PostgreSQL API
final equipmentsProvider = AsyncNotifierProvider<EquipmentsNotifier, List<Equipment>>(
  EquipmentsNotifier.new,
);

/// Notifier de Áreas - Migrado a PostgreSQL API
class AreasNotifier extends AsyncNotifier<List<Area>> {

  @override
  Future<List<Area>> build() async {
    return _fetchAreas();
  }

  /// Obtener todas las áreas desde PostgreSQL
  Future<List<Area>> _fetchAreas() async {
    try {
      final response = await _apiService.get('areas', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final areasData = response.data['areas'] as List<dynamic>? ?? [];
        return areasData.map((item) {
          final data = Map<String, dynamic>.from(item as Map);
          data['id'] = data['id']?.toString() ?? '';
          return Area.fromMap(data);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtener áreas (método público)
  Future<List<Area>> getAreas() async {
    return await _fetchAreas();
  }

  /// Agregar área - Usa PostgreSQL API
  Future<String> addArea(Area area) async {
    try {
      final response = await _apiService.post('areas', area.toMap());

      if (response.success) {
        ref.invalidateSelf(); // Refrescar la lista
        final newId = response.data?['area']?['id']?.toString() ??
                      response.data?['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString();
        return newId;
      }
      throw Exception(response.message ?? 'Error al agregar área');
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar área - Usa PostgreSQL API
  Future<void> updateArea(Area area) async {
    try {
      final response = await _apiService.put('areas/${area.id}', area.toMap());

      if (response.success) {
        ref.invalidateSelf();
      } else {
        throw Exception(response.message ?? 'Error al actualizar área');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar área - Usa PostgreSQL API
  Future<void> deleteArea(String id) async {
    try {
      final response = await _apiService.delete('areas/$id');

      if (response.success) {
        ref.invalidateSelf();
      } else {
        throw Exception(response.message ?? 'Error al eliminar área');
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Notifier de Equipos - Migrado a PostgreSQL API
class EquipmentsNotifier extends AsyncNotifier<List<Equipment>> {

  @override
  Future<List<Equipment>> build() async {
    return _fetchEquipments();
  }

  /// Obtener todos los equipos desde PostgreSQL
  Future<List<Equipment>> _fetchEquipments() async {
    try {
      final response = await _apiService.get('equipments', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final equipmentsData = response.data['equipments'] as List<dynamic>? ?? [];
        return equipmentsData.map((item) {
          final data = Map<String, dynamic>.from(item as Map);
          data['id'] = data['id']?.toString() ?? '';
          return Equipment.fromMap(data);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Agregar equipo - Usa PostgreSQL API
  Future<String> addEquipment(Equipment equipment) async {
    try {
      final response = await _apiService.post('equipments', equipment.toMap());

      if (response.success) {
        ref.invalidateSelf();
        final newId = response.data?['equipment']?['id']?.toString() ??
                      response.data?['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString();
        return newId;
      }
      throw Exception(response.message ?? 'Error al agregar equipo');
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar equipo - Usa PostgreSQL API
  Future<void> updateEquipment(Equipment equipment) async {
    try {
      final response = await _apiService.put('equipments/${equipment.id}', equipment.toMap());

      if (response.success) {
        ref.invalidateSelf();
      } else {
        throw Exception(response.message ?? 'Error al actualizar equipo');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar equipo - Usa PostgreSQL API
  Future<void> deleteEquipment(String id) async {
    try {
      final response = await _apiService.delete('equipments/$id');

      if (response.success) {
        ref.invalidateSelf();
      } else {
        throw Exception(response.message ?? 'Error al eliminar equipo');
      }
    } catch (e) {
      rethrow;
    }
  }
}
