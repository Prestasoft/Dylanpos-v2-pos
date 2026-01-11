import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../../services/api_service.dart';
import '../model/designation_model.dart';

/// Repositorio de designaciones/cargos - Usa PostgreSQL API
class DesignationRepository {
  final ApiService _apiService = ApiService();

  /// Obtener todas las designaciones desde PostgreSQL
  Future<List<DesignationModel>> getAllDesignation() async {
    List<DesignationModel> designations = [];

    try {
      final response = await _apiService.get('hrm/designations', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final designationsData = response.data['designations'] as List<dynamic>? ?? [];

        for (var element in designationsData) {
          final data = Map<String, dynamic>.from(element as Map);
          designations.add(DesignationModel.fromJson(data));
        }
      }
    } catch (e) {
      // Error silencioso para mantener compatibilidad
    }

    return designations;
  }

  /// Agregar nueva designación
  Future<bool> addDesignation({required DesignationModel designation}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final designationData = Map<String, dynamic>.from(designation.toJson());
      final response = await _apiService.post('hrm/designations', designationData);

      if (response.success) {
        EasyLoading.showSuccess('Added Successfully', duration: const Duration(milliseconds: 500));
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al agregar designación');
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to add designation: ${e.toString()}');
    }
  }

  /// Actualizar designación existente
  Future<bool> updateDesignation({required DesignationModel designation}) async {
    try {
      EasyLoading.show(status: 'Loading...', dismissOnTap: false);

      final updateData = {
        'designation': designation.designation,
        'designationDescription': designation.designationDescription,
      };

      final response = await _apiService.put('hrm/designations/${designation.id}', updateData);

      if (response.success) {
        EasyLoading.showSuccess('Updated Successfully', duration: const Duration(milliseconds: 500));
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al actualizar designación');
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      throw Exception('Failed to Updated designation: ${e.toString()}');
    }
  }

  /// Eliminar designación
  Future<bool> deleteDesignation({required num id}) async {
    try {
      EasyLoading.show(status: 'Deleting...');

      final response = await _apiService.delete('hrm/designations/$id');

      if (response.success) {
        EasyLoading.showSuccess('Deleted Successfully');
        return true;
      }

      EasyLoading.showError(response.message ?? 'Error al eliminar designación');
      return false;
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }
}
