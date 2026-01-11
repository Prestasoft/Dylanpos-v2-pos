import 'package:salespro_admin/model/branch_settings_model.dart';
import '../services/api_service.dart';

/// Repositorio para gestionar la configuración de sucursales
class BranchSettingsRepo {
  final ApiService _apiService = ApiService();

  /// Obtener configuración de la sucursal actual
  Future<BranchSettingsModel> getBranchSettings() async {
    final defaultSettings = BranchSettingsModel(
      branchId: '',
      companyName: 'Victor Guzman Fotografía',
      rnc: '',
      branchName: '',
      city: '',
      address: '',
      phone: '',
    );

    try {
      final response = await _apiService.get('branch-settings');

      if (response.success && response.data != null) {
        final data = response.data['branch_settings'] ?? response.data;
        if (data != null) {
          return BranchSettingsModel.fromJson(data as Map<String, dynamic>);
        }
      }
      return defaultSettings;
    } catch (e) {
      print('Error obteniendo configuración de sucursal: $e');
      return defaultSettings;
    }
  }

  /// Obtener configuración de una sucursal específica por ID
  Future<BranchSettingsModel?> getBranchSettingsById(String branchId) async {
    try {
      final response = await _apiService.get('branch-settings/$branchId');

      if (response.success && response.data != null) {
        final data = response.data['branch_settings'] ?? response.data;
        if (data != null) {
          return BranchSettingsModel.fromJson(data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo configuración de sucursal $branchId: $e');
      return null;
    }
  }

  /// Obtener todas las configuraciones de sucursales
  Future<List<BranchSettingsModel>> getAllBranchSettings() async {
    try {
      final response = await _apiService.get('branch-settings/all');

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data['branches'] ?? response.data ?? [];
        return dataList
            .map((item) => BranchSettingsModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo todas las configuraciones: $e');
      return [];
    }
  }

  /// Actualizar configuración de sucursal
  Future<bool> updateBranchSettings(BranchSettingsModel settings) async {
    try {
      final settingsData = settings.toJson();
      final response = await _apiService.put('branch-settings', settingsData);
      return response.success;
    } catch (e) {
      print('Error actualizando configuración de sucursal: $e');
      return false;
    }
  }

  /// Crear configuración de sucursal inicial
  Future<bool> createBranchSettings(BranchSettingsModel settings) async {
    try {
      final settingsData = settings.toJson();
      final response = await _apiService.post('branch-settings', settingsData);
      return response.success;
    } catch (e) {
      print('Error creando configuración de sucursal: $e');
      return false;
    }
  }

  /// Guardar configuración (crear o actualizar automáticamente)
  Future<bool> saveBranchSettings(BranchSettingsModel settings) async {
    try {
      final settingsData = settings.toJson();
      // Usamos upsert endpoint que crea o actualiza según exista
      final response = await _apiService.put('branch-settings/upsert', settingsData);

      if (!response.success) {
        // Si falla el upsert, intentamos con PUT normal
        return await updateBranchSettings(settings);
      }
      return response.success;
    } catch (e) {
      print('Error guardando configuración de sucursal: $e');
      // Fallback: intentar actualizar directamente
      return await updateBranchSettings(settings);
    }
  }
}
