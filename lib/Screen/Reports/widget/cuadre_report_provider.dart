// cuadre_report_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Repository/send_whatsapp_message_repo.dart';
import '../../../const.dart';
import '../../../model/sale_transaction_model.dart';

class CuadreReportProvider with ChangeNotifier {
  // Configuración del servidor SMTP
  static const String _smtpServer = 'mail.victorguzmanfotografia.com';
  static const String _smtpUsername = 'noreply@victorguzmanfotografia.com';
  static const String _smtpPassword = 'Abc16081991*+';
  static const int _smtpPort = 465;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Datos del cuadre para el reporte

  // Generar reporte HTML para email
  String _generateHtmlReport(CuadreData data) {
    final formatter = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'es_ES');

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Reporte de Cuadre de Caja</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 10px; }
            .header h1 { margin: 0; font-size: 28px; }
            .header p { margin: 5px 0 0 0; font-size: 16px; opacity: 0.9; }
            .section { margin-bottom: 25px; }
            .section h2 { color: #333; border-bottom: 2px solid #667eea; padding-bottom: 10px; margin-bottom: 15px; }
            .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
            .summary-card { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #667eea; }
            .summary-card h3 { margin: 0 0 10px 0; color: #333; font-size: 14px; text-transform: uppercase; }
            .summary-card .value { font-size: 22px; font-weight: bold; color: #667eea; }
            .table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
            .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
            .table th { background-color: #f8f9fa; font-weight: bold; color: #333; }
            .table .currency { text-align: right; font-weight: bold; }
            .positive { color: #28a745; }
            .negative { color: #dc3545; }
            .status { padding: 10px 20px; border-radius: 25px; font-weight: bold; text-align: center; }
            .status.success { background-color: #d4edda; color: #155724; }
            .status.error { background-color: #f8d7da; color: #721c24; }
            .footer { text-align: center; margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🏪 Reporte de Cuadre de Caja</h1>
                <p>${dateFormatter.format(data.fecha)}</p>
            </div>

            <div class="section">
                <h2>📊 Resumen Ejecutivo</h2>
                <div class="summary-grid">
                    <div class="summary-card">
                        <h3>Total Ventas</h3>
                        <div class="value">${formatter.format(data.totalVentasDia)}</div>
                    </div>
                    <div class="summary-card">
                        <h3>Total Pendiente</h3>
                        <div class="value">${formatter.format(data.totalPendiente)}</div>
                    </div>
                    <div class="summary-card">
                        <h3>Efectivo Neto</h3>
                        <div class="value">${formatter.format(data.efectivoNeto)}</div>
                    </div>
                    <div class="summary-card">
                        <h3>Total Gastos</h3>
                        <div class="value">${formatter.format(data.totalGastos)}</div>
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>💳 Métodos de Pago</h2>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Método</th>
                            <th>Ingresos</th>
                            <th>Salidas</th>
                            <th>Total Neto</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>💵 Efectivo</td>
                            <td class="currency positive">${formatter.format(data.totalEfectivo)}</td>
                            <td class="currency negative">${formatter.format(data.pagoEfectivo)}</td>
                            <td class="currency">${formatter.format(data.efectivoNeto)}</td>
                        </tr>
                        <tr>
                            <td>💳 Tarjeta</td>
                            <td class="currency positive">${formatter.format(data.totalTarjeta)}</td>
                            <td class="currency negative">${formatter.format(data.pagoTarjeta)}</td>
                            <td class="currency">${formatter.format(data.totalTarjeta - data.pagoTarjeta)}</td>
                        </tr>
                        <tr>
                            <td>🔄 Transferencia</td>
                            <td class="currency positive">${formatter.format(data.totalTransferencia)}</td>
                            <td class="currency negative">${formatter.format(data.pagoTransferencia)}</td>
                            <td class="currency">${formatter.format(data.totalTransferencia - data.pagoTransferencia)}</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="section">
                <h2>💰 Detalle de Efectivo</h2>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Denominación</th>
                            <th>Cantidad</th>
                            <th>Subtotal</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.cantidadesDenominaciones.entries.where((entry) => entry.value > 0).map((entry) {
      return '<tr><td>RD\$${entry.key}</td><td>${entry.value}</td><td class="currency">${formatter.format(entry.key * entry.value)}</td></tr>';
    }).join('')}
                        <tr style="border-top: 2px solid #333; font-weight: bold;">
                            <td colspan="2">Total Contado</td>
                            <td class="currency">${formatter.format(data.totalContado)}</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="section">
                <h2>✅ Estado del Cuadre</h2>
                <div class="status ${data.cuadreOk ? 'success' : 'error'}">
                    ${data.cuadreOk ? '✅ Cuadre Perfecto' : '⚠️ Diferencia: ${formatter.format(data.diferenciaCuadre.abs())}'}
                </div>
            </div>

            <div class="section">
                <h2>📈 Balance del Día</h2>
                <table class="table">
                    <tbody>
                        <tr>
                            <td><strong>➕ Total Ingresos</strong></td>
                            <td class="currency positive">${formatter.format(data.totalVentasDia - data.totalPendiente)}</td>
                        </tr>
                        <tr>
                            <td><strong>➖ Total Salidas</strong></td>
                            <td class="currency negative">${formatter.format(data.totalPagos)}</td>
                        </tr>
                        <tr>
                            <td><strong>🛒 Total Gastos</strong></td>
                            <td class="currency negative">${formatter.format(data.totalGastos)}</td>
                        </tr>
                        <tr style="border-top: 2px solid #333; font-weight: bold; font-size: 18px;">
                            <td><strong>💰 Balance Neto</strong></td>
                            <td class="currency ${(data.totalVentasDia - data.totalPendiente - data.totalPagos - data.totalGastos) >= 0 ? 'positive' : 'negative'}">
                                ${formatter.format(data.totalVentasDia - data.totalPendiente - data.totalPagos - data.totalGastos)}
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="footer">
                <p>Reporte generado automáticamente el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</p>
                <p>Sistema de Gestión - ${appsName ?? 'Tu Negocio'}</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Generar mensaje de texto para WhatsApp
  String _generateWhatsAppMessage(CuadreData data) {
    final formatter = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'es_ES');

    return '''
🏪 *CUADRE DE CAJA*
📅 ${dateFormatter.format(data.fecha)}

📊 *RESUMEN DEL DÍA*
💰 Total Ventas: ${formatter.format(data.totalVentasDia)}
⏰ Pendiente: ${formatter.format(data.totalPendiente)}
💵 Efectivo Neto: ${formatter.format(data.efectivoNeto)}
🛒 Total Gastos: ${formatter.format(data.totalGastos)}

💳 *MÉTODOS DE PAGO*
💵 Efectivo: ${formatter.format(data.totalEfectivo)}
💳 Tarjeta: ${formatter.format(data.totalTarjeta)}
🔄 Transferencia: ${formatter.format(data.totalTransferencia)}

💰 *EFECTIVO FÍSICO*
📦 Total Contado: ${formatter.format(data.totalContado)}
${data.cuadreOk ? '✅ Cuadre Perfecto' : '⚠️ Diferencia: ${formatter.format(data.diferenciaCuadre.abs())}'}

📈 *BALANCE FINAL*
💰 Balance Neto: ${formatter.format(data.totalVentasDia - data.totalPendiente - data.totalPagos - data.totalGastos)}

---
Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
Sistema: $appsName
    ''';
  }

  // Enviar reporte por email
  Future<bool> sendReportByEmail({
    required CuadreData cuadreData,
    required String recipientEmail,
    required String recipientName,
    String? subject,
  }) async {
    try {
      _setLoading(true);
      EasyLoading.show(status: 'Enviando reporte por email...');

      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        ssl: true,
        username: _smtpUsername,
        password: _smtpPassword,
      );

      final htmlContent = _generateHtmlReport(cuadreData);
      final dateStr = DateFormat('dd-MM-yyyy').format(cuadreData.fecha);

      final message = Message()
        ..from = Address(_smtpUsername, appsName ?? 'Sistema de Gestión')
        ..recipients.add(Address(recipientEmail, recipientName))
        ..subject = subject ?? 'Reporte de Cuadre de Caja - $dateStr'
        ..html = htmlContent;

      await send(message, smtpServer);

      EasyLoading.showSuccess('Reporte enviado exitosamente');
      return true;
    } catch (e) {
      debugPrint('Error enviando email: $e');
      EasyLoading.showError('Error al enviar el reporte por email');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enviar reporte por WhatsApp
  Future<bool> sendReportByWhatsApp({
    required CuadreData cuadreData,
    required String phoneNumber,
  }) async {
    try {
      _setLoading(true);
      EasyLoading.show(status: 'Enviando reporte por WhatsApp...');

      final message = _generateWhatsAppMessage(cuadreData);

      final body = {
        'token': '5i36w829nb1ljkj7', //token santo domingo
        //'token': '5gs146cmkgu6y5vw', //token santiago
        'to': phoneNumber,
        'body': message,
      };

      final url = Uri.parse(
          'https://api.ultramsg.com/instance127004/messages/chat'); //instancia santo domingo
      //final url = Uri.parse('https://api.ultramsg.com/instance129929/messages/chat'); //instancia santiago
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};

      final response = await http
          .post(
            url,
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Reporte enviado por WhatsApp');
        return true;
      } else {
        EasyLoading.showError('Error al enviar por WhatsApp');
        return false;
      }
    } catch (e) {
      debugPrint('Error enviando WhatsApp: $e');
      EasyLoading.showError('Error al enviar el reporte por WhatsApp');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Compartir reporte usando el sistema nativo
  Future<void> shareReport(CuadreData cuadreData) async {
    try {
      final message = _generateWhatsAppMessage(cuadreData);
      final uri =
          Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback para compartir por otras aplicaciones
        final shareUri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
        await launchUrl(shareUri);
      }
    } catch (e) {
      debugPrint('Error compartiendo reporte: $e');
      EasyLoading.showError('Error al compartir el reporte');
    }
  }

  // Función auxiliar para convertir datos del modal a CuadreData
  static CuadreData createCuadreDataFromModal({
    required DateTime fecha,
    required double totalVentasDia,
    required double totalPendiente,
    required double totalEfectivo,
    required double totalTarjeta,
    required double totalTransferencia,
    required double totalPagos,
    required double pagoEfectivo,
    required double pagoTarjeta,
    required double pagoTransferencia,
    required double totalGastos,
    required double totalContado,
    required List<SaleTransactionModel> ventasDelDia,
    required Map<int, int> cantidadesDenominaciones,
  }) {
    final efectivoNeto = totalEfectivo - pagoEfectivo;
    final diferenciaCuadre = totalContado - efectivoNeto;
    final cuadreOk = diferenciaCuadre.abs() < 0.01; // Tolerancia de 1 centavo

    return CuadreData(
      fecha: fecha,
      totalVentasDia: totalVentasDia,
      totalPendiente: totalPendiente,
      totalEfectivo: totalEfectivo,
      totalTarjeta: totalTarjeta,
      totalTransferencia: totalTransferencia,
      totalPagos: totalPagos,
      pagoEfectivo: pagoEfectivo,
      pagoTarjeta: pagoTarjeta,
      pagoTransferencia: pagoTransferencia,
      totalGastos: totalGastos,
      efectivoNeto: efectivoNeto,
      totalContado: totalContado,
      diferenciaCuadre: diferenciaCuadre,
      cuadreOk: cuadreOk,
      ventasDelDia: ventasDelDia,
      cantidadesDenominaciones: cantidadesDenominaciones,
    );
  }
}

class CuadreData {
  final DateTime fecha;
  final double totalVentasDia;
  final double totalPendiente;
  final double totalEfectivo;
  final double totalTarjeta;
  final double totalTransferencia;
  final double totalPagos;
  final double pagoEfectivo;
  final double pagoTarjeta;
  final double pagoTransferencia;
  final double totalGastos;
  final double efectivoNeto;
  final double totalContado;
  final double diferenciaCuadre;
  final bool cuadreOk;
  final List<SaleTransactionModel> ventasDelDia;
  final Map<int, int> cantidadesDenominaciones;

  CuadreData({
    required this.fecha,
    required this.totalVentasDia,
    required this.totalPendiente,
    required this.totalEfectivo,
    required this.totalTarjeta,
    required this.totalTransferencia,
    required this.totalPagos,
    required this.pagoEfectivo,
    required this.pagoTarjeta,
    required this.pagoTransferencia,
    required this.totalGastos,
    required this.efectivoNeto,
    required this.totalContado,
    required this.diferenciaCuadre,
    required this.cuadreOk,
    required this.ventasDelDia,
    required this.cantidadesDenominaciones,
  });
}
