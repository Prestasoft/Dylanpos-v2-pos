// whatsapp_template_service.dart - Migrado a PostgreSQL API
import 'api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

class WhatsAppTemplateService {
  // Default templates
  static const Map<String, String> _defaultTemplates = {
    'invoice_caption': '''Hola {nombre},
Adjunto su comprobante #{factura}.
Gracias por su preferencia!''',

    'reservation_confirmation': '''🎉 Hola {nombre}! 🎉

¡Gracias por confiar en nosotros! Tu sesión fotográfica está reservada para el {fecha}.

📋 Detalles de tu reserva:
• Fecha: {fecha}
• Total: {total}
• Abono: {abono}

📸 Recuerda:
• Llega 15 minutos antes
• Si no puedes asistir, avísanos con 24 horas de anticipación
• Cualquier cambio debe confirmarse por escrito

✨ Políticas Importantes:
• Las reservas no confirmadas serán canceladas 24 horas antes
• No se realizan devoluciones de depósitos, pero pueden aplicarse a futuras sesiones
• Los paquetes tienen validez de 6 meses

📞 Contacto:
Para más información o cambios, contáctanos:
WhatsApp: 8098982876
Con aprecio,
Equipo Víctor Guzmán Fotografía
Para llamadas: 8098982876 ☎️''',

    'payment_receipt': '''Hola {nombre},
Adjunto su comprobante #{factura}.
Gracias por su preferencia!''',

    'confirmation_link': '''Hola {nombre} 👋🏼

Tu reserva está pendiente de confirmación.

Haz clic en el siguiente enlace para confirmar tu reserva: 👇🏼
{link}

Este enlace expira en 24 horas. ¡Gracias por tu preferencia!

Con aprecio,
Equipo Víctor Guzmán Fotografía
Para llamadas: 8098982876 ☎️''',

    'daily_report': '''🏪 CUADRE DE CAJA
📅 {fecha}

📊 RESUMEN DEL DÍA
💰 Total Ventas: {totalVentas} RD\$
💵 Cobros del día: {totalCobros} RD\$
⏰ Pendiente: {totalPendiente} RD\$
💵 Efectivo Neto: {efectivoNeto} RD\$
🛒 Total Gastos: {totalGastos} RD\$

💳 MÉTODOS DE PAGO
💵 Efectivo: {totalEfectivo} RD\$
💳 Tarjeta: {totalTarjeta} RD\$
🔄 Transferencia: {totalTransferencia} RD\$

💰 EFECTIVO FÍSICO
📦 Total Contado: {totalContado} RD\$
{cuadreStatus}

📈 BALANCE FINAL
💰 Balance Neto: {balanceNeto} RD\$

---
Generado: {horaGeneracion}
Sistema: VICTOR GUZMAN FOTOGRAFIA''',
  };

  /// Get all templates from PostgreSQL API (or initialize with defaults)
  static Future<Map<String, String>> getAllTemplates() async {
    try {
      final response = await _apiService.get('settings/whatsapp-templates');

      if (response.success && response.data != null) {
        final data = response.data['templates'] ?? response.data;
        if (data is Map && data.isNotEmpty) {
          return Map<String, dynamic>.from(data)
              .map((key, value) => MapEntry(key, value.toString()));
        }
      }

      // Initialize with default templates if not exists
      await _initializeDefaultTemplates();
      return Map<String, String>.from(_defaultTemplates);
    } catch (e) {
      print('Error getting templates: $e');
      return Map<String, String>.from(_defaultTemplates);
    }
  }

  /// Get a specific template by key - Usa PostgreSQL API
  static Future<String> getTemplate(String templateKey) async {
    try {
      final response = await _apiService.get('settings/whatsapp-templates/$templateKey');

      if (response.success && response.data != null) {
        final template = response.data['template']?.toString() ??
                        response.data['content']?.toString();
        if (template != null && template.isNotEmpty) {
          return template;
        }
      }

      // Return default template if not found
      return _defaultTemplates[templateKey] ?? '';
    } catch (e) {
      print('Error getting template $templateKey: $e');
      return _defaultTemplates[templateKey] ?? '';
    }
  }

  /// Update a specific template - Usa PostgreSQL API
  static Future<bool> updateTemplate(String templateKey, String templateText) async {
    try {
      if (templateText.trim().isEmpty) {
        return false;
      }

      final response = await _apiService.put('settings/whatsapp-templates/$templateKey', {
        'template': templateText.trim(),
      });
      return response.success;
    } catch (e) {
      print('Error updating template $templateKey: $e');
      return false;
    }
  }

  /// Update multiple templates at once - Usa PostgreSQL API
  static Future<bool> updateTemplates(Map<String, String> templates) async {
    try {
      final updates = <String, String>{};

      templates.forEach((key, value) {
        if (value.trim().isNotEmpty) {
          updates[key] = value.trim();
        }
      });

      if (updates.isEmpty) {
        return false;
      }

      final response = await _apiService.put('settings/whatsapp-templates', {
        'templates': updates,
      });
      return response.success;
    } catch (e) {
      print('Error updating templates: $e');
      return false;
    }
  }

  /// Reset all templates to defaults - Usa PostgreSQL API
  static Future<bool> resetToDefaults() async {
    try {
      final response = await _apiService.put('settings/whatsapp-templates', {
        'templates': _defaultTemplates,
      });
      return response.success;
    } catch (e) {
      print('Error resetting templates: $e');
      return false;
    }
  }

  /// Initialize default templates if they don't exist - Usa PostgreSQL API
  static Future<void> _initializeDefaultTemplates() async {
    try {
      await _apiService.post('settings/whatsapp-templates', {
        'templates': _defaultTemplates,
      });
    } catch (e) {
      print('Error initializing default templates: $e');
    }
  }

  /// Replace variables in template with actual values
  static String replaceVariables(String template, Map<String, String> variables) {
    String result = template;

    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });

    return result;
  }

  /// Get available variables for a template
  static List<String> getAvailableVariables(String templateKey) {
    switch (templateKey) {
      case 'invoice_caption':
        return ['nombre', 'factura'];

      case 'reservation_confirmation':
        return ['nombre', 'fecha', 'total', 'abono'];

      case 'payment_receipt':
        return ['nombre', 'factura'];

      case 'confirmation_link':
        return ['nombre', 'link'];

      case 'daily_report':
        return [
          'fecha',
          'totalVentas',
          'totalCobros',
          'totalPendiente',
          'efectivoNeto',
          'totalGastos',
          'totalEfectivo',
          'totalTarjeta',
          'totalTransferencia',
          'totalContado',
          'cuadreStatus',
          'balanceNeto',
          'horaGeneracion',
        ];

      default:
        return [];
    }
  }

  /// Get template display name
  static String getTemplateDisplayName(String templateKey) {
    switch (templateKey) {
      case 'invoice_caption':
        return 'Comprobante de Factura';
      case 'reservation_confirmation':
        return 'Confirmación de Reserva';
      case 'payment_receipt':
        return 'Recibo de Pago';
      case 'confirmation_link':
        return 'Enlace de Confirmación';
      case 'daily_report':
        return 'Reporte de Cuadre Diario';
      default:
        return templateKey;
    }
  }

  /// Get template description
  static String getTemplateDescription(String templateKey) {
    switch (templateKey) {
      case 'invoice_caption':
        return 'Mensaje enviado al adjuntar comprobante PDF por WhatsApp';
      case 'reservation_confirmation':
        return 'Mensaje de confirmación enviado al hacer una reserva';
      case 'payment_receipt':
        return 'Mensaje enviado al registrar pago de cuenta pendiente';
      case 'confirmation_link':
        return 'Mensaje con enlace para confirmar reserva';
      case 'daily_report':
        return 'Reporte de cuadre de caja enviado al administrador';
      default:
        return '';
    }
  }
}
