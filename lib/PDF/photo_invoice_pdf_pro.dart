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

FutureOr<Uint8List> generatePhotoInvoiceDocumentPro({
  required PhotoInvoiceModel invoice,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel generalSetting,
}) async {
  try {
    // Cargar logo con manejo de error
    pw.MemoryImage? image;
    try {
      final imageData = await rootBundle.load('images/vg_logo.png');
      final imageBytes = imageData.buffer.asUint8List();
      image = pw.MemoryImage(imageBytes);
    } catch (e) {
      print('No se pudo cargar el logo: $e');
      // Continuar sin logo
    }

    // Crear documento PDF con fuente por defecto
    // No intentar cargar fuentes Unicode ya que no están disponibles en este proyecto
    final doc = pw.Document();
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');

    // Colores profesionales para estudio fotográfico
    final PdfColor azulDominicano = PdfColor.fromHex('#2C3E50'); // Azul oscuro elegante
    final PdfColor rojoDominicano = PdfColor.fromHex('#E74C3C'); // Rojo coral profesional
    final PdfColor colorFondo = PdfColor.fromHex('#ECF0F1'); // Gris claro suave
    final PdfColor colorTextoSecundario = PdfColor.fromHex('#7F8C8D'); // Gris medio

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(20),
      header: (pw.Context context) {
        return pw.Column(
          children: [
            // Header principal con diseño profesional
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: azulDominicano, width: 3),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Logo e información de la empresa
                  pw.Expanded(
                    flex: 2,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (image != null) ...[
                          pw.Container(
                            width: 80,
                            height: 80,
                            child: pw.Image(image),
                          ),
                          pw.SizedBox(width: 15),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.Text(
                              personalInformation.companyName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: azulDominicano,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Servicios de Impresión y Enmarcado',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            if (personalInformation.gst.isNotEmpty) ...[
                              pw.Text(
                                'RNC: ${personalInformation.gst}',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            pw.Text(
                              'Tel: ${personalInformation.phoneNumber}',
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.black,
                              ),
                            ),
                            // Si tuviéramos dirección, la agregaríamos aquí
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Número de factura y fecha con diseño más compacto
                  pw.Stack(
                    children: [
                      // Marca de agua de cámara
                      pw.Positioned(
                        right: 10,
                        top: 10,
                        child: pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.CustomPaint(
                            painter: (PdfGraphics canvas, PdfPoint size) {
                              // Dibujar icono de cámara
                              canvas
                                ..setColor(PdfColors.grey200)
                                ..drawRect(10, 15, 40, 30)
                                ..fillPath()
                                ..setColor(PdfColors.grey300)
                                ..drawEllipse(30, 30, 12, 12)
                                ..fillPath()
                                ..setColor(PdfColors.white)
                                ..drawEllipse(30, 30, 8, 8)
                                ..fillPath()
                                ..setColor(PdfColors.grey300)
                                ..drawRect(15, 10, 10, 5)
                                ..fillPath();
                            },
                          ),
                        ),
                      ),
                      // Contenedor de factura
                      pw.Container(
                        width: 200,
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          gradient: pw.LinearGradient(
                            colors: [azulDominicano, azulDominicano.shade(0.8)],
                            begin: pw.Alignment.topLeft,
                            end: pw.Alignment.bottomRight,
                          ),
                          borderRadius: pw.BorderRadius.circular(8),
                          boxShadow: [
                            pw.BoxShadow(
                              color: PdfColors.grey400,
                              offset: const PdfPoint(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'FACTURA',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white.shade(0.9),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                invoice.invoiceNumber,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: azulDominicano,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              dateFormat.format(invoice.invoiceDate),
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              timeFormat.format(invoice.invoiceDate),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Información del cliente con diseño mejorado
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DATOS DEL CLIENTE',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: azulDominicano,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          invoice.customer.customerName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        if (invoice.customer.customerAddress.isNotEmpty) ...[
                          pw.Text(
                            invoice.customer.customerAddress,
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                        ],
                        pw.Row(
                          children: [
                            pw.Text(
                              'Tel: ',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.Text(
                              invoice.customer.phoneNumber,
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.black,
                              ),
                            ),
                            if (invoice.customer.emailAddress.isNotEmpty) ...[
                              pw.SizedBox(width: 20),
                              pw.Text(
                                'Email: ',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Text(
                                invoice.customer.emailAddress,
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.black,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Método de pago
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: azulDominicano),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'FORMA DE PAGO',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: azulDominicano,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          invoice.paymentMethod.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        if (invoice.selectedBank != null) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            invoice.selectedBank!,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],
        );
      },
      build: (pw.Context context) {
        return [
          // Tabla de productos (si hay)
          if (invoice.products.isNotEmpty) ...[
            _buildSectionTitle('PRODUCTOS', azulDominicano),
            pw.SizedBox(height: 10),
            _buildProductTable(invoice.products, azulDominicano),
            pw.SizedBox(height: 20),
          ],

          // Tabla de servicios (si hay)
          if (invoice.services.isNotEmpty) ...[
            _buildSectionTitle('SERVICIOS', azulDominicano),
            pw.SizedBox(height: 10),
            _buildServiceTable(invoice.services, azulDominicano),
            pw.SizedBox(height: 20),
          ],

          // Notas (si hay)
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColors.yellow50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 20,
                        height: 20,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.amber,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '!',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'OBSERVACIONES:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber800,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    invoice.notes!,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Totales con diseño mejorado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Espacio para firma
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 60),
                    pw.Container(
                      width: 180,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Firma del Cliente',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              // Resumen de totales
              pw.Container(
                width: 280,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: azulDominicano, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    // Header de totales
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: azulDominicano,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(6),
                          topRight: pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Text(
                        'RESUMEN DE FACTURA',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    // Detalles de totales
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Column(
                        children: [
                          if (invoice.products.isNotEmpty)
                            _buildTotalRowPro('Subtotal Productos:', invoice.productSubtotal, currency),
                          if (invoice.services.isNotEmpty)
                            _buildTotalRowPro('Subtotal Servicios:', invoice.serviceSubtotal, currency),
                          if (invoice.products.isNotEmpty && invoice.services.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 5),
                              child: pw.Container(
                                height: 1,
                                color: PdfColors.grey300,
                              ),
                            ),
                          _buildTotalRowPro('Subtotal:', invoice.subtotal, currency),
                          if (invoice.discountAmount > 0)
                            _buildTotalRowPro('Descuento:', -invoice.discountAmount, currency, color: rojoDominicano),
                          if (invoice.taxRate > 0)
                            _buildTotalRowPro('ITBIS (${invoice.taxRate}%):', invoice.taxAmount, currency),
                          pw.Container(
                            margin: const pw.EdgeInsets.symmetric(vertical: 8),
                            height: 2,
                            color: azulDominicano,
                          ),
                          _buildTotalRowPro(
                            'TOTAL A PAGAR:',
                            invoice.totalAmount,
                            currency,
                            bold: true,
                            fontSize: 16,
                            color: azulDominicano,
                          ),
                          if (invoice.paidAmount > 0) ...[
                            pw.SizedBox(height: 10),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: invoice.dueAmount > 0 ? PdfColors.red50 : PdfColors.green50,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Column(
                                children: [
                                  _buildTotalRowPro('Monto Pagado:', invoice.paidAmount, currency, color: PdfColors.green),
                                  pw.SizedBox(height: 4),
                                  _buildTotalRowPro(
                                    invoice.dueAmount > 0 ? 'PENDIENTE:' : 'CAMBIO:',
                                    invoice.dueAmount > 0 ? invoice.dueAmount : -invoice.dueAmount,
                                    currency,
                                    bold: true,
                                    color: invoice.dueAmount > 0 ? rojoDominicano : PdfColors.green,
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
              ),
            ],
          ),
        ];
      },
      footer: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.only(top: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: azulDominicano, width: 2),
            ),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Icono de cámara estilizado
                  pw.Container(
                    width: 30,
                    height: 30,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: colorFondo,
                    ),
                    child: pw.CustomPaint(
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        // Dibujar icono de cámara simplificado
                        canvas
                          ..setColor(azulDominicano)
                          ..drawRect(8, 10, 14, 10)
                          ..fillPath()
                          ..drawEllipse(15, 15, 4, 4)
                          ..fillPath()
                          ..drawRect(10, 7, 5, 3)
                          ..fillPath();
                      },
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '¡Gracias por confiar en nosotros!',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: azulDominicano,
                        ),
                      ),
                      pw.Text(
                        'Capturando momentos inolvidables',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: colorTextoSecundario,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: azulDominicano,
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                      border: pw.Border.all(color: azulDominicano),
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: rojoDominicano,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Factura generada el ${dateFormat.format(DateTime.now())} a las ${timeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

    final pdfBytes = await doc.save();
    print('PDF guardado en memoria, tamaño: ${pdfBytes.length} bytes');
    return pdfBytes;
  } catch (e) {
    print('Error en generatePhotoInvoiceDocumentPro: $e');
    rethrow;
  }
}

// Función auxiliar para títulos de sección
pw.Widget _buildSectionTitle(String title, PdfColor color) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(color: color, width: 4),
      ),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: color,
        letterSpacing: 1,
      ),
    ),
  );
}

// Tabla de productos mejorada
pw.Widget _buildProductTable(List<dynamic> products, PdfColor headerColor) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FixedColumnWidth(50),
      4: const pw.FixedColumnWidth(80),
      5: const pw.FixedColumnWidth(80),
    },
    children: [
      // Header
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerColor),
        children: [
          _buildTableHeader('#'),
          _buildTableHeader('PRODUCTO'),
          _buildTableHeader('DETALLES'),
          _buildTableHeader('CANT.'),
          _buildTableHeader('PRECIO'),
          _buildTableHeader('TOTAL'),
        ],
      ),
      // Rows
      ...products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final isEven = index % 2 == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.white : PdfColors.grey50,
          ),
          children: [
            _buildTableCell('${index + 1}', align: pw.TextAlign.center),
            _buildTableCell(product.productName),
            _buildTableCell('${product.size ?? ''} ${product.material ?? ''} ${product.color ?? ''}'.trim()),
            _buildTableCell(myFormat.format(product.quantity), align: pw.TextAlign.center),
            _buildTableCell('$currency${myFormat.format(product.productPrice)}', align: pw.TextAlign.right),
            _buildTableCell('$currency${myFormat.format(product.subtotal)}', align: pw.TextAlign.right, bold: true),
          ],
        );
      }).toList(),
    ],
  );
}

// Tabla de servicios mejorada
pw.Widget _buildServiceTable(List<dynamic> services, PdfColor headerColor) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(3),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FixedColumnWidth(50),
      4: const pw.FixedColumnWidth(80),
      5: const pw.FixedColumnWidth(80),
    },
    children: [
      // Header
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerColor),
        children: [
          _buildTableHeader('#'),
          _buildTableHeader('SERVICIO'),
          _buildTableHeader('TIPO/TAMAÑO'),
          _buildTableHeader('CANT.'),
          _buildTableHeader('PRECIO'),
          _buildTableHeader('TOTAL'),
        ],
      ),
      // Rows
      ...services.asMap().entries.map((entry) {
        final index = entry.key;
        final service = entry.value;
        final isEven = index % 2 == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.white : PdfColors.grey50,
          ),
          children: [
            _buildTableCell('${index + 1}', align: pw.TextAlign.center),
            _buildTableCell(service.serviceName),
            _buildTableCell(service.size ?? service.serviceType),
            _buildTableCell(myFormat.format(service.quantity), align: pw.TextAlign.center),
            _buildTableCell('$currency${myFormat.format(service.servicePrice)}', align: pw.TextAlign.right),
            _buildTableCell('$currency${myFormat.format(service.subtotal)}', align: pw.TextAlign.right, bold: true),
          ],
        );
      }).toList(),
    ],
  );
}

// Header de tabla
pw.Widget _buildTableHeader(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );
}

// Celda de tabla
pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

// Fila de totales mejorada
pw.Widget _buildTotalRowPro(
  String label,
  double amount,
  String currency, {
  bool bold = false,
  double fontSize = 12,
  PdfColor color = PdfColors.black,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
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