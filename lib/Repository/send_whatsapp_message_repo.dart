import 'dart:convert';

import 'package:http/http.dart' as http;

import '../const.dart';
import '../model/whatsapp_marketing_model.dart';
import '../services/api_service.dart';

/// Repositorio de WhatsApp Marketing - Usa PostgreSQL API
class WhatsappInfoRepo {
  final ApiService _apiService = ApiService();

  /// Obtener información de WhatsApp Marketing desde PostgreSQL
  Future<WhatsappMarketing> getWhatsappMarketingInfo() async {
    WhatsappMarketing defaultModel = WhatsappMarketing(
      twillio: Twillio(
        accountSid: 'Loading...',
        authToken: 'Loading...',
      ),
      ultraMsg: UltraMsg(
        apiKey: 'Loading...',
        apiSecret: 'Loading...',
      ),
    );

    try {
      final response = await _apiService.get('whatsapp-marketing');

      if (response.success && response.data != null) {
        final marketingData = response.data['whatsapp_marketing'] ?? response.data;
        if (marketingData != null) {
          // Actualizar variables globales
          isTwillio = marketingData['twillio']?['isActive'] ?? true;
          isUltraMsg = marketingData['ultraMsg']?['isActive'] ?? true;
          return WhatsappMarketing.fromJson(marketingData as Map<String, dynamic>);
        }
      }
      return defaultModel;
    } catch (e) {
      return defaultModel;
    }
  }

  /// Actualizar configuración de WhatsApp Marketing
  Future<bool> updateWhatsappMarketingInfo(WhatsappMarketing model) async {
    try {
      final marketingData = Map<String, dynamic>.from(model.toJson());
      final response = await _apiService.put('whatsapp-marketing', marketingData);
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Enviar mensaje de WhatsApp vía Twilio
  Future<bool> sendWhatsappMessage(String phoneNumber, String message, WhatsappMarketing model) async {
    // Basic auth
    String basicAuth = 'Basic ${base64Encode(utf8.encode('${model.twillio?.accountSid}:${model.twillio?.authToken}'))}';
    // API URL
    String url = 'https://api.twilio.com/2010-04-01/Accounts/${model.twillio?.accountSid}/Messages.json';
    // API Body
    Map<String, dynamic> body = {
      'To': 'whatsapp:$phoneNumber',
      'From': 'whatsapp:${model.twillio?.phoneNumber}',
      'Body': message,
    };

    // API Call
    final response = await http.post(Uri.parse(url), body: body, headers: <String, String>{'authorization': basicAuth});
    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  /// Enviar mensaje de WhatsApp vía UltraMsg
  Future<bool> sendUltraMsg(String phoneNumber, String message, WhatsappMarketing model) async {
    var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    var bodyData = {'token': model.ultraMsg?.apiSecret, 'to': phoneNumber, 'body': message, 'priority': '10'};
    var response = await http.post(Uri.parse('${model.ultraMsg?.apiUrl}/messages/chat'), headers: headers, body: bodyData);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
