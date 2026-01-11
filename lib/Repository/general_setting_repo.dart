import '../model/general_setting_model.dart';
import '../services/api_service.dart';

/// Repositorio de configuración general - Usa PostgreSQL API
class GeneralSettingRepo {
  final ApiService _apiService = ApiService();

  /// Obtener configuración general desde PostgreSQL
  Future<GeneralSettingModel> getGeneralSetting() async {
    try {
      final response = await _apiService.get('settings/general');

      if (response.success && response.data != null) {
        final data = response.data['settings'] ?? response.data;
        if (data != null && data is Map<String, dynamic>) {
          if (data.containsKey('title')) {
            return GeneralSettingModel.fromJson(data);
          } else if (data.isNotEmpty) {
            final firstKey = data.keys.first;
            if (data[firstKey] is Map) {
              return GeneralSettingModel.fromJson(Map<String, dynamic>.from(data[firstKey]));
            }
          }
        }
      }

      return _defaultSettings();
    } catch (e) {
      return _defaultSettings();
    }
  }

  /// Configuración por defecto
  GeneralSettingModel _defaultSettings() {
    return GeneralSettingModel(
      title: '',
      companyName: '',
      mainLogo: '',
      commonHeaderLogo: '',
      sidebarLogo: '',
    );
  }

  /// Actualizar configuración general
  Future<bool> updateGeneralSetting(GeneralSettingModel settings) async {
    try {
      final settingsData = settings.toJson();
      final response = await _apiService.put('settings/general', settingsData);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
