import 'package:salespro_admin/model/invoice_model.dart';

import '../services/api_service.dart';

/// Repositorio de configuración de facturas - Usa PostgreSQL API
class InvoiceSettingsRepo {
  final ApiService _apiService = ApiService();

  /// Obtener configuración de factura desde PostgreSQL
  Future<InvoiceModel> getDetails() async {
    InvoiceModel defaultInfo = InvoiceModel(
      phoneNumber: '',
      companyName: 'Not Defined',
      pictureUrl: 'https://i.imgur.com/jlyGd1j.jpg',
      emailAddress: 'Not Defined',
      address: 'Not Defined',
      description: 'Not Defined',
      website: 'Not Defined',
      isRight: true,
      showInvoice: true,
    );

    try {
      final response = await _apiService.get('invoice-settings');

      if (response.success && response.data != null) {
        final data = response.data['invoice_settings'] ?? response.data;
        if (data != null) {
          return InvoiceModel.fromJson(data as Map<String, dynamic>);
        }
      }
      return defaultInfo;
    } catch (e) {
      return defaultInfo;
    }
  }

  /// Actualizar configuración de factura
  Future<bool> updateInvoiceSettings(InvoiceModel settings) async {
    try {
      final settingsData = Map<String, dynamic>.from(settings.toJson());
      final response = await _apiService.put('invoice-settings', settingsData);
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Crear configuración de factura inicial
  Future<bool> createInvoiceSettings(InvoiceModel settings) async {
    try {
      final settingsData = Map<String, dynamic>.from(settings.toJson());
      final response = await _apiService.post('invoice-settings', settingsData);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
