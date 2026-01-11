import 'package:salespro_admin/model/whatsapp_marketing_sms_template_model.dart';

import '../services/api_service.dart';

/// Repositorio de plantillas SMS/WhatsApp - Usa PostgreSQL API
class SmsTemplateRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todas las plantillas desde PostgreSQL
  Future<WhatsappMarketingSmsTemplateModel> getAllTemplate() async {
    WhatsappMarketingSmsTemplateModel defaultModel = WhatsappMarketingSmsTemplateModel(
      saleTemplate: 'Loading...',
      purchaseTemplate: 'Loading...',
      paymentTemplate: 'Loading...',
      dueTemplate: 'Loading...',
      saleReturnTemplate: 'Loading...',
      purchaseReturnTemplate: 'Loading...',
      quotationTemplate: 'Loading...',
    );

    try {
      final response = await _apiService.get('whatsapp-templates');

      if (response.success && response.data != null) {
        final templateData = response.data['whatsapp_template'] ?? response.data;
        if (templateData != null) {
          return WhatsappMarketingSmsTemplateModel.fromJson(templateData as Map<String, dynamic>);
        }
      }
      return defaultModel;
    } catch (e) {
      return defaultModel;
    }
  }

  /// Actualizar plantillas
  Future<bool> updateTemplate(WhatsappMarketingSmsTemplateModel model) async {
    try {
      final templateData = Map<String, dynamic>.from(model.toJson());
      final response = await _apiService.put('whatsapp-templates', templateData);
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Crear plantillas iniciales
  Future<bool> createTemplate(WhatsappMarketingSmsTemplateModel model) async {
    try {
      final templateData = Map<String, dynamic>.from(model.toJson());
      final response = await _apiService.post('whatsapp-templates', templateData);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
