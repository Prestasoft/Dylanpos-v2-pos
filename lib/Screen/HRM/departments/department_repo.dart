import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../services/api_service.dart';
import 'department_model.dart';

/// Repositorio de departamentos — CRUD via PostgreSQL API.
class DepartmentRepository {
  final _api = ApiService();

  Future<List<DepartmentModel>> getAll() async {
    try {
      final resp = await _api.get('hrm/departments');
      if (resp.success && resp.data != null) {
        final list = resp.data['departments'] as List<dynamic>? ?? [];
        return list.map((e) => DepartmentModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<DepartmentModel?> create(String name) async {
    try {
      EasyLoading.show(status: 'Creando...');
      final resp = await _api.post('hrm/departments', {'name': name.trim()});
      if (resp.success && resp.data != null) {
        final dept = resp.data['department'];
        EasyLoading.showSuccess('Departamento creado');
        if (dept != null) return DepartmentModel.fromJson(Map<String, dynamic>.from(dept));
      } else {
        EasyLoading.showError(resp.message ?? 'Error al crear departamento');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
    return null;
  }

  Future<bool> update(int id, String name) async {
    try {
      final resp = await _api.put('hrm/departments/$id', {'name': name.trim()});
      return resp.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final resp = await _api.delete('hrm/departments/$id');
      return resp.success;
    } catch (_) {
      return false;
    }
  }

  /// Guardar el orden de todos los departamentos de una vez.
  Future<bool> reorder(List<DepartmentModel> departments) async {
    try {
      final orders = departments.asMap().entries.map((e) => {
        'id': e.value.id,
        'display_order': e.key,
      }).toList();
      final resp = await _api.put('hrm/departments/reorder', {'orders': orders});
      return resp.success;
    } catch (_) {
      return false;
    }
  }
}