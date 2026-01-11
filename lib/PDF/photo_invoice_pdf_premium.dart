import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/photo_invoice_model.dart';
import '../currency.dart';

FutureOr<Uint8List> generatePremiumPhotoInvoice({
  required PhotoInvoiceModel invoice,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel generalSetting,
}) async {
  // Cargar logo de la empresa
  final imageData = await rootBundle.load('images/vg_logo.png');
  final imageBytes = imageData.buffer.asUint8List();
  final image = pw.MemoryImage(imageBytes);

  final pw.Document doc = pw.Document();
  final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'es_ES');
  
  // Colores premium para fotografía
  final PdfColor primaryColor = PdfColor.fromHex('#1A1A1A'); // Negro elegante
  final PdfColor accentColor = PdfColor.fromHex('#D4AF37'); // Dorado premium
  final PdfColor bgLight = PdfColor.fromHex('#FAFAFA');
  final PdfColor borderColor = PdfColor.fromHex('#E5E5E5');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (pw.Context context) {
        return pw.Column(
          children: [
            // Header premium con diseño moderno
            pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryColor, primaryColor.shade(0.8)],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(15),
                  topRight: pw.Radius.circular(15),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Logo y datos de empresa
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 80,
                        height: 80,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            personalInformation.companyName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'ESTUDIO FOTOGRÁFICO PROFESIONAL',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.white.shade(0.9),
                              letterSpacing: 1.5,
                              fontWeight: pw.FontWeight.normal,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Capturando momentos únicos',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.white.shade(0.8),
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Número de factura elegante
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'FACTURA',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '#${invoice.invoiceNumber}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Información de contacto elegante
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: pw.BoxDecoration(
                color: bgLight,
                border: pw.Border(
                  left: pw.BorderSide(color: borderColor),
                  right: pw.BorderSide(color: borderColor),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildContactItem(
                    icon: '📞',
                    label: 'Teléfono',
                    value: personalInformation.phoneNumber,
                  ),
                  if (personalInformation.gst.isNotEmpty)
                    _buildContactItem(
                      icon: '📋',
                      label: 'RNC',
                      value: personalInformation.gst,
                    ),
                  _buildContactItem(
                    icon: '📅',
                    label: 'Fecha',
                    value: dateFormat.format(invoice.invoiceDate),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
          ],
        );
      },
      build: (pw.Context context) {
        return [
          // Información del cliente con diseño premium
          pw.Container(
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(15),
              border: pw.Border.all(color: borderColor, width: 1),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  offset: const PdfPoint(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 20,
                      color: accentColor,
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'DATOS DEL CLIENTE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          invoice.customer.customerName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        if (invoice.customer.customerAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 5),
                          pw.Text(
                            invoice.customer.customerAddress,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text(
                              '📱 ',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                            pw.Text(
                              invoice.customer.phoneNumber,
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        if (invoice.customer.emailAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Text(
                                '✉️ ',
                                style: pw.TextStyle(fontSize: 12),
                              ),
                              pw.Text(
                                invoice.customer.emailAddress,
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Sección de servicios y productos en contenedor unificado
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(15),
              border: pw.Border.all(color: borderColor, width: 0.5),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey200,
                  offset: const PdfPoint(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(25),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Detalle de productos con diseño elegante
                  if (invoice.products.isNotEmpty) ...[
                    _buildSectionTitle('PRODUCTOS FOTOGRÁFICOS', accentColor),
                    pw.SizedBox(height: 15),
            _buildPremiumTable(
              headers: ['#', 'Producto', 'Detalles', 'Cant.', 'Precio Unit.', 'Subtotal'],
              rows: invoice.products.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                return [
                  '${index + 1}',
                  product.productName,
                  '${product.size ?? ''} ${product.material ?? ''}'.trim(),
                  myFormat.format(product.quantity),
                  '$currency${myFormat.format(product.productPrice)}',
                  '$currency${myFormat.format(product.subtotal)}',
                ];
              }).toList(),
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
                    pw.SizedBox(height: 25),
                  ],
                  
                  // Separador elegante entre productos y servicios
                  if (invoice.products.isNotEmpty && invoice.services.isNotEmpty) ...[
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 20),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              height: 1,
                              color: borderColor.shade(0.5),
                            ),
                          ),
                          pw.Container(
                            margin: const pw.EdgeInsets.symmetric(horizontal: 15),
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: accentColor.shade(0.1),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Text(
                              '&',
                              style: pw.TextStyle(
                                fontSize: 14,
                                color: accentColor,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              height: 1,
                              color: borderColor.shade(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Detalle de servicios con diseño elegante
                  if (invoice.services.isNotEmpty) ...[
            _buildSectionTitle('SERVICIOS FOTOGRÁFICOS', accentColor),
            pw.SizedBox(height: 15),
            _buildPremiumTable(
              headers: ['#', 'Servicio', 'Especificaciones', 'Cant.', 'Precio Unit.', 'Subtotal'],
              rows: invoice.services.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                return [
                  '${index + 1}',
                  service.serviceName,
                  service.size ?? service.serviceType,
                  myFormat.format(service.quantity),
                  '$currency${myFormat.format(service.servicePrice)}',
                  '$currency${myFormat.format(service.subtotal)}',
                ];
              }).toList(),
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
                    pw.SizedBox(height: 25),
                  ],
                ],
              ),
            ),
          ),
              pw.SizedBox(height: 30),
          
          // Notas con diseño elegante
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: bgLight,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: borderColor.shade(0.5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 3,
                        height: 15,
                        color: accentColor,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'OBSERVACIONES',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    invoice.notes!,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                      lineSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),
          ],
          
          // Resumen de totales premium
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 300,
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [bgLight, PdfColors.white],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(15),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  children: [
                    if (invoice.productSubtotal > 0)
                      _buildPremiumTotalRow('Subtotal Productos:', invoice.productSubtotal),
                    if (invoice.serviceSubtotal > 0)
                      _buildPremiumTotalRow('Subtotal Servicios:', invoice.serviceSubtotal),
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 10),
                      height: 1,
                      color: borderColor,
                    ),
                    _buildPremiumTotalRow('Subtotal:', invoice.subtotal, fontSize: 13),
                    if (invoice.discountAmount > 0)
                      _buildPremiumTotalRow(
                        'Descuento:',
                        -invoice.discountAmount,
                        color: PdfColors.green700,
                      ),
                    if (invoice.taxAmount > 0)
                      _buildPremiumTotalRow('ITBIS (18%):', invoice.taxAmount),
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 10),
                      height: 2,
                      color: primaryColor,
                    ),
                    _buildPremiumTotalRow(
                      'TOTAL A PAGAR:',
                      invoice.totalAmount,
                      bold: true,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                    if (invoice.paidAmount > 0) ...[
                      pw.SizedBox(height: 15),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: invoice.dueAmount > 0 
                            ? PdfColors.red50 
                            : PdfColors.green50,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          children: [
                            _buildPremiumTotalRow(
                              'Monto Pagado:',
                              invoice.paidAmount,
                              color: PdfColors.grey800,
                            ),
                            pw.SizedBox(height: 5),
                            _buildPremiumTotalRow(
                              'Balance Pendiente:',
                              invoice.dueAmount,
                              bold: true,
                              color: invoice.dueAmount > 0 
                                ? PdfColors.red700 
                                : PdfColors.green700,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ];
      },
      footer: (pw.Context context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 30),
          padding: const pw.EdgeInsets.symmetric(vertical: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                '"Capturamos momentos, creamos recuerdos eternos"',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontStyle: pw.FontStyle.italic,
                  color: primaryColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Gracias por confiar en nosotros para preservar sus momentos especiales',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Síguenos en: ',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    '@${personalInformation.companyName.toLowerCase().replaceAll(' ', '_')}studio',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: accentColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  return doc.save();
}

// Widget para elementos de contacto
pw.Widget _buildContactItem({
  required String icon,
  required String label,
  required String value,
}) {
  return pw.Row(
    children: [
      pw.Text(icon, style: const pw.TextStyle(fontSize: 14)),
      pw.SizedBox(width: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey100,
              letterSpacing: 0.5,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

// Widget para títulos de sección
pw.Widget _buildSectionTitle(String title, PdfColor color) {
  return pw.Container(
    child: pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 25,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 15),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#2C3E50'),
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

// Tabla premium con diseño moderno
pw.Widget _buildPremiumTable({
  required List<String> headers,
  required List<List<String>> rows,
  required PdfColor primaryColor,
  required PdfColor accentColor,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColor.fromHex('#DEE2E6')),
    ),
    child: pw.ClipRRect(
      horizontalRadius: 10,
      verticalRadius: 10,
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#DEE2E6'), width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(30),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FixedColumnWidth(50),
          4: const pw.FixedColumnWidth(80),
          5: const pw.FixedColumnWidth(80),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryColor, primaryColor.shade(0.9)],
              ),
            ),
            children: headers.map((header) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: header == '#' ? pw.TextAlign.center : pw.TextAlign.left,
              ),
            )).toList(),
          ),
          // Data rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isEven = index % 2 == 0;
            
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : PdfColor.fromHex('#F8F9FA'),
              ),
              children: row.asMap().entries.map((cellEntry) {
                final cellIndex = cellEntry.key;
                final cell = cellEntry.value;
                
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: pw.Text(
                    cell,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey800,
                      fontWeight: (cellIndex == 0 || cellIndex == 5)
                        ? pw.FontWeight.bold 
                        : pw.FontWeight.normal,
                    ),
                    textAlign: (cellIndex == 0 || cellIndex >= 3)
                      ? pw.TextAlign.center 
                      : pw.TextAlign.left,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ),
  );
}

// Fila de total premium
pw.Widget _buildPremiumTotalRow(
  String label,
  double amount, {
  bool bold = false,
  double fontSize = 12,
  PdfColor color = PdfColors.grey800,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          '$currency${myFormat.format(amount.abs())}',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    ),
  );
}