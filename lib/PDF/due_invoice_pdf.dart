import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salespro_admin/Provider/branch_settings_provider.dart';
import 'package:salespro_admin/commas.dart';
import '../const.dart';
import '../model/due_transaction_model.dart';
import '../model/general_setting_model.dart';
import '../model/personal_information_model.dart';
import '../model/branch_settings_model.dart';
import '../services/api_service.dart';

/// Genera documento PDF para recibo de pago de factura
/// Formato profesional estilo DGII
FutureOr<Uint8List> generateDueDocument({
  required DueTransactionModel transactions,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel setting,
  BuildContext? context,
}) async {
  debugPrint('📄 [generateDueDocument] Iniciando generación...');

  // Cargar logo
  Uint8List? imageBytes;
  pw.MemoryImage? image;
  try {
    final imageData = await rootBundle.load('images/vg_logo.png');
    imageBytes = imageData.buffer.asUint8List();
    image = pw.MemoryImage(imageBytes);
    debugPrint('📄 [generateDueDocument] Logo cargado correctamente');
  } catch (e) {
    debugPrint('📄 [generateDueDocument] No se pudo cargar el logo: $e');
  }

  // Obtener configuración de sucursal
  BranchSettingsModel? branchSettings;
  if (context != null) {
    try {
      final ref = ProviderScope.containerOf(context);
      branchSettings = await ref.read(branchSettingsProvider.future).timeout(
        const Duration(seconds: 3),
        onTimeout: () => BranchSettingsModel.defaultSettings(''),
      );
    } catch (e) {
      debugPrint('📄 [generateDueDocument] Error obteniendo branchSettings: $e');
      branchSettings = BranchSettingsModel.defaultSettings('');
    }
  }

  final pw.Document doc = pw.Document();

  // Extraer todos los valores como Strings simples ANTES de crear widgets
  final String companyName = branchSettings?.companyName.isNotEmpty == true
      ? branchSettings!.companyName.toUpperCase()
      : personalInformation.companyName.toUpperCase();
  final String rnc = branchSettings?.rnc.isNotEmpty == true
      ? branchSettings!.rnc
      : personalInformation.gst;
  final String phoneNumber = branchSettings?.phone.isNotEmpty == true
      ? branchSettings!.phone
      : personalInformation.phoneNumber;
  final String address = branchSettings?.address ?? '';
  final String city = branchSettings?.city ?? '';

  final String customerName = transactions.customerName;
  final String customerPhone = transactions.customerPhone;
  final String customerAddress = transactions.customerAddress;
  final String customerGst = transactions.customerGst;
  final String invoiceNumber = transactions.invoiceNumber;
  final String purchaseDate = transactions.purchaseDate;
  final String paymentType = transactions.paymentType ?? 'N/A';
  final String sellerName = transactions.sellerName ?? 'Admin';
  final String bankName = transactions.bankName ?? '';

  final double totalDue = transactions.totalDue ?? 0;
  final double payDueAmount = transactions.payDueAmount ?? 0;
  final double dueAmountAfterPay = transactions.dueAmountAfterPay ?? 0;
  final bool isPaid = transactions.isPaid ?? false;

  // Formatear fecha
  String formattedDate = '';
  String formattedTime = '';
  try {
    final date = DateTime.parse(purchaseDate);
    formattedDate = DateFormat('dd/MM/yyyy').format(date);
    formattedTime = DateFormat('HH:mm').format(date);
  } catch (e) {
    formattedDate = purchaseDate;
    formattedTime = '';
  }

  debugPrint('📄 [generateDueDocument] Datos extraídos: invoice=$invoiceNumber, total=$totalDue');

  // ─── OBTENER HISTORIAL DE PAGOS PARA ESTA FACTURA ───
  List<Map<String, dynamic>> paymentHistory = [];
  try {
    final apiService = ApiService();
    final response = await apiService.get('due-transactions', queryParams: {
      'customerPhone': customerPhone,
      'limit': '500',
    });

    if (response.success && response.data != null) {
      final transactions = response.data['dueTransactions'] as List<dynamic>? ??
                          response.data['due_transactions'] as List<dynamic>? ?? [];

      for (var data in transactions) {
        final map = Map<String, dynamic>.from(data);
        final txInvoice = map['invoiceNumber']?.toString() ?? map['invoice_number']?.toString() ?? '';
        if (txInvoice == invoiceNumber) {
          paymentHistory.add(map);
        }
      }

      // Ordenar por fecha (más antiguo primero para estado de cuenta cronológico)
      paymentHistory.sort((a, b) {
        final dateA = DateTime.tryParse(
          a['transactionDate']?.toString() ?? a['transaction_date']?.toString() ?? a['created_at']?.toString() ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(
          b['transactionDate']?.toString() ?? b['transaction_date']?.toString() ?? b['created_at']?.toString() ?? '') ?? DateTime(1900);
        return dateA.compareTo(dateB);
      });
    }
    debugPrint('📄 [generateDueDocument] Historial de pagos encontrados: ${paymentHistory.length}');
  } catch (e) {
    debugPrint('📄 [generateDueDocument] Error obteniendo historial de pagos: $e');
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════════════
            // ENCABEZADO CON BANDA DE COLOR (Estilo Gubernamental/DGII)
            // ═══════════════════════════════════════════════════════════════════════
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.black, width: 1.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // ─── Lado Izquierdo: Logo + Info Empresa ───
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (image != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(image),
                        ),
                      if (image != null) pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName,
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              fontSize: 14.0,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 3),
                          if (rnc.trim().isNotEmpty)
                            pw.Text(
                              'RNC: $rnc',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // ─── Lado Derecho: Número de Recibo ───
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'RECIBO DE PAGO',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 2),
                      ),
                      pw.Container(width: 100, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Factura #$invoiceNumber',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                      pw.Text(
                        formattedDate,
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ─── Línea secundaria con datos de contacto ───
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.black, width: 1.5),
                  right: pw.BorderSide(color: PdfColors.black, width: 1.5),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (address.isNotEmpty) ...[
                    pw.Text(address, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                    pw.Text('  |  ', style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                  ],
                  pw.Text(
                    'Tel: $phoneNumber',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.black),
                  ),
                  if (city.isNotEmpty) ...[
                    pw.Text('  |  ', style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                    pw.Text(city, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // ═══════════════════════════════════════════════════════════════════════
            // CONTENIDO PRINCIPAL (con padding)
            // ═══════════════════════════════════════════════════════════════════════
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ─── SECCIÓN: TIPO DE DOCUMENTO ───
                  pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 15),
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          child: pw.Text(
                            'RECIBO DE PAGO - DOCUMENTO INTERNO',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 2,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Row(
                            children: [
                              pw.Text('Tipo:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              pw.SizedBox(width: 10),
                              pw.Expanded(
                                child: pw.Text(
                                  'Abono a cuenta - Pago de balance pendiente',
                                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // ─── SECCIÓN: RECIBIDO DE (Cliente) ───
                  pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                          ),
                          child: pw.Text(
                            'RECIBIDO DE:',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildFormRow('Nombre/Razón Social ', customerName),
                              if (customerGst.trim().isNotEmpty)
                                _buildFormRow('RNC/Cédula ', customerGst),
                              if (customerAddress.isNotEmpty)
                                _buildFormRow('Dirección ', customerAddress),
                              if (customerPhone.isNotEmpty)
                                _buildFormRow('Teléfono ', customerPhone),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // ─── SECCIÓN: INFORMACIÓN DEL PAGO + RESPONSABLES ───
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda: Información del Pago
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                                ),
                                child: pw.Text('INFORMACIÓN DEL PAGO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Column(
                                  children: [
                                    _buildInfoRow('Estado', isPaid ? 'PAGADO' : 'PENDIENTE'),
                                    _buildInfoRow('Método', paymentType),
                                    if (bankName.isNotEmpty)
                                      _buildInfoRow('Banco', bankName),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Columna Derecha: Responsables
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                                ),
                                child: pw.Text('RESPONSABLES', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Column(
                                  children: [
                                    _buildInfoRow('Recibido por', sellerName),
                                    _buildInfoRow('Hora', formattedTime),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // ─── Línea divisoria antes de tabla ───
                  pw.Container(
                    width: double.infinity,
                    height: 2,
                    color: PdfColors.grey800,
                  ),
                  pw.SizedBox(height: 12),

                  // ─── TABLA DE DETALLES DEL PAGO ───
                  pw.Table.fromTextArray(
                    context: context,
                    border: const pw.TableBorder(
                      left: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                      right: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                      bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                      top: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                      verticalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
                      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 10, fontWeight: pw.FontWeight.bold),
                    rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                    oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFf5f5f5)),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(2),
                    },
                    headerAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                    },
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                    },
                    data: [
                      ['Concepto', 'Monto'],
                      ['Monto Total Pendiente', myFormat.format(totalDue)],
                      ['Monto Recibido (Abono)', myFormat.format(payDueAmount)],
                      ['Balance Restante', myFormat.format(dueAmountAfterPay)],
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // ─── RESUMEN EN GRANDE ───
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('MONTO RECIBIDO:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              myFormat.format(payDueAmount),
                              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                        pw.Container(
                          width: 1,
                          height: 50,
                          color: PdfColors.grey400,
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('BALANCE PENDIENTE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              myFormat.format(dueAmountAfterPay),
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: dueAmountAfterPay > 0 ? PdfColors.red700 : PdfColors.green700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // ─── ESTADO DE CUENTA (HISTORIAL DE PAGOS) ───
                  if (paymentHistory.isNotEmpty) ...[
                    pw.Container(
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.grey200,
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                            ),
                            child: pw.Text(
                              'ESTADO DE CUENTA - HISTORIAL DE PAGOS',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                          pw.Table.fromTextArray(
                            context: context,
                            border: const pw.TableBorder(
                              verticalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
                              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
                            ),
                            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFe8e8e8)),
                            headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 8, fontWeight: pw.FontWeight.bold),
                            cellStyle: const pw.TextStyle(fontSize: 8),
                            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                            oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFf9f9f9)),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(1),
                              1: const pw.FlexColumnWidth(2),
                              2: const pw.FlexColumnWidth(2),
                              3: const pw.FlexColumnWidth(1.5),
                              4: const pw.FlexColumnWidth(2),
                            },
                            headerAlignments: {
                              0: pw.Alignment.center,
                              1: pw.Alignment.center,
                              2: pw.Alignment.centerRight,
                              3: pw.Alignment.center,
                              4: pw.Alignment.centerRight,
                            },
                            cellAlignments: {
                              0: pw.Alignment.center,
                              1: pw.Alignment.center,
                              2: pw.Alignment.centerRight,
                              3: pw.Alignment.center,
                              4: pw.Alignment.centerRight,
                            },
                            data: [
                              ['#', 'Fecha', 'Monto Pagado', 'Método', 'Balance'],
                              ...paymentHistory.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final payment = entry.value;
                                final paidAmt = (payment['paidAmount'] ?? payment['paid_amount'] ?? 0);
                                final remaining = (payment['remainingDue'] ?? payment['remaining_due'] ?? 0);
                                final method = payment['paymentType']?.toString() ?? payment['payment_type']?.toString() ?? 'N/A';
                                final dateStr = payment['transactionDate']?.toString() ?? payment['transaction_date']?.toString() ?? payment['created_at']?.toString() ?? '';
                                String fmtDate = dateStr;
                                try {
                                  final dt = DateTime.parse(dateStr);
                                  fmtDate = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                                } catch (_) {}

                                final paidNum = paidAmt is num ? paidAmt.toDouble() : double.tryParse(paidAmt.toString()) ?? 0.0;
                                final remainNum = remaining is num ? remaining.toDouble() : double.tryParse(remaining.toString()) ?? 0.0;

                                return [
                                  '${idx + 1}',
                                  fmtDate,
                                  myFormat.format(paidNum),
                                  method,
                                  myFormat.format(remainNum),
                                ];
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],

                  // ─── SECCIÓN DE FIRMAS ───
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.SizedBox(height: 25),
                          pw.Container(
                            width: 150.0,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                            ),
                          ),
                          pw.SizedBox(height: 4.0),
                          pw.Text('Firma del Cliente', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.SizedBox(height: 25),
                          pw.Container(
                            width: 150.0,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                            ),
                          ),
                          pw.SizedBox(height: 4.0),
                          pw.Text('Firma Autorizada', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ═══════════════════════════════════════════════════════════════════════
            // PIE DE PÁGINA
            // ═══════════════════════════════════════════════════════════════════════
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 1,
              decoration: const pw.BoxDecoration(color: PdfColors.black),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20),
              child: pw.Column(
                children: [
                  pw.Text(
                    '"Capturando momentos que duran para siempre"',
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Documento generado electrónicamente - ${setting.companyName.isNotEmpty == true ? setting.companyName : pdfFooter}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        );
      },
    ),
  );

  debugPrint('📄 [generateDueDocument] Guardando documento...');
  final result = await doc.save();
  debugPrint('📄 [generateDueDocument] PDF generado: ${result.length} bytes');

  return result;
}

/// Widget auxiliar para construir filas de información en formato etiqueta: valor
pw.Widget _buildInfoRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Widget auxiliar para construir filas con líneas punteadas (estilo formulario oficial)
pw.Widget _buildFormRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
        ),
        pw.Expanded(
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(left: 5, bottom: 2),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
