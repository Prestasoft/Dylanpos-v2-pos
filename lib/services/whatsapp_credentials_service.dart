// whatsapp_credentials_service.dart - Migrado a PostgreSQL API
import 'package:nb_utils/nb_utils.dart';
import 'tenant/tenant_model.dart';
import 'api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

class WhatsAppCredentials {
  final String token;
  final String instanceId;

  WhatsAppCredentials({
    required this.token,
    required this.instanceId,
  });

  /// Verifica si las credenciales están configuradas
  bool get isConfigured => token.isNotEmpty && instanceId.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'instanceId': instanceId,
    };
  }

  factory WhatsAppCredentials.fromJson(Map<dynamic, dynamic> json) {
    return WhatsAppCredentials(
      token: json['token']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? json['instance_id']?.toString() ?? '',
    );
  }

  String getApiUrl(String endpoint) {
    return 'https://api.ultramsg.com/$instanceId/$endpoint';
  }
}

class WhatsAppCredentialsService {
  /// Obtiene las credenciales por defecto del tenant actual
  static WhatsAppConfig _getTenantDefaultCredentials() {
    final tenantId = getStringAsync('selected_tenant_id');
    if (tenantId.isEmpty) {
      return TenantConfig.defaultTenant.whatsAppConfig;
    }
    final tenant = TenantConfig.getTenantById(tenantId);
    return tenant?.whatsAppConfig ?? TenantConfig.defaultTenant.whatsAppConfig;
  }

  /// Obtiene el tenant actual
  static TenantModel? getCurrentTenant() {
    final tenantId = getStringAsync('selected_tenant_id');
    if (tenantId.isEmpty) return TenantConfig.defaultTenant;
    return TenantConfig.getTenantById(tenantId) ?? TenantConfig.defaultTenant;
  }

  /// Get current WhatsApp API credentials - Usa PostgreSQL API
  /// Primero busca en PostgreSQL, si no hay, usa las del tenant
  static Future<WhatsAppCredentials> getCredentials() async {
    try {
      final response = await _apiService.get('settings/whatsapp-credentials');

      if (response.success && response.data != null) {
        final data = response.data['credentials'] ?? response.data;
        if (data is Map) {
          final credentials = WhatsAppCredentials.fromJson(Map<dynamic, dynamic>.from(data));
          // Si las credenciales en PostgreSQL están configuradas, usarlas
          if (credentials.isConfigured) {
            return credentials;
          }
        }
      }

      // Si no hay credenciales en PostgreSQL, usar las del tenant
      final tenantConfig = _getTenantDefaultCredentials();
      if (tenantConfig.isConfigured) {
        // Guardar las credenciales del tenant en PostgreSQL para este usuario
        await _initializeWithTenantCredentials(tenantConfig);
        return WhatsAppCredentials(
          token: tenantConfig.token,
          instanceId: tenantConfig.instanceId,
        );
      }

      // No hay credenciales configuradas
      return WhatsAppCredentials(
        token: '',
        instanceId: '',
      );
    } catch (e) {
      print('Error getting credentials: $e');
      // En caso de error, intentar usar las del tenant
      final tenantConfig = _getTenantDefaultCredentials();
      return WhatsAppCredentials(
        token: tenantConfig.token,
        instanceId: tenantConfig.instanceId,
      );
    }
  }

  /// Inicializa con las credenciales del tenant actual - Usa PostgreSQL API
  static Future<void> _initializeWithTenantCredentials(WhatsAppConfig config) async {
    try {
      await _apiService.post('settings/whatsapp-credentials', {
        'token': config.token,
        'instanceId': config.instanceId,
      });
    } catch (e) {
      print('Error initializing tenant credentials: $e');
    }
  }

  /// Update WhatsApp API credentials - Usa PostgreSQL API
  static Future<bool> updateCredentials({
    required String token,
    required String instanceId,
  }) async {
    try {
      if (token.trim().isEmpty || instanceId.trim().isEmpty) {
        return false;
      }

      final credentials = WhatsAppCredentials(
        token: token.trim(),
        instanceId: instanceId.trim(),
      );

      final response = await _apiService.put('settings/whatsapp-credentials', credentials.toJson());
      return response.success;
    } catch (e) {
      print('Error updating credentials: $e');
      return false;
    }
  }

  /// Reset credentials to tenant defaults - Usa PostgreSQL API
  static Future<bool> resetToDefaults() async {
    try {
      final tenantConfig = _getTenantDefaultCredentials();
      final response = await _apiService.put('settings/whatsapp-credentials', {
        'token': tenantConfig.token,
        'instanceId': tenantConfig.instanceId,
      });
      return response.success;
    } catch (e) {
      print('Error resetting credentials: $e');
      return false;
    }
  }

  /// Verifica si la sucursal actual tiene WhatsApp configurado
  static bool isTenantWhatsAppEnabled() {
    final tenant = getCurrentTenant();
    return tenant?.hasWhatsApp ?? false;
  }

  /// Obtiene información del estado de WhatsApp para la sucursal actual
  static String getTenantWhatsAppStatus() {
    final tenant = getCurrentTenant();
    if (tenant == null) return 'Sin sucursal';
    if (!tenant.hasWhatsApp) return 'No configurado';
    return 'Configurado (${tenant.city})';
  }

  /// Validate credentials format
  static bool validateCredentials({
    required String token,
    required String instanceId,
  }) {
    // Token should be alphanumeric
    final tokenRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!tokenRegex.hasMatch(token)) {
      return false;
    }

    // Instance ID should start with "instance" and have numbers
    final instanceRegex = RegExp(r'^instance\d+$');
    if (!instanceRegex.hasMatch(instanceId)) {
      return false;
    }

    return true;
  }

  /// Get API URL for messages/chat endpoint
  static Future<String> getChatUrl() async {
    final credentials = await getCredentials();
    return credentials.getApiUrl('messages/chat');
  }

  /// Get API URL for messages/document endpoint
  static Future<String> getDocumentUrl() async {
    final credentials = await getCredentials();
    return credentials.getApiUrl('messages/document');
  }
}
