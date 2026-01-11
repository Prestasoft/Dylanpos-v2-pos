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

FutureOr<Uint8List> generateSimplePhotoInvoice({
  required PhotoInvoiceModel invoice,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel generalSetting,
}) async {
  final pw.Document doc = pw.Document();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header simple
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    personalInformation.companyName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Servicios Fotográficos',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Tel: ${personalInformation.phoneNumber}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  if (personalInformation.gst.isNotEmpty) ...[
                    pw.Text(
                      'RNC: ${personalInformation.gst}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            
            // Información de factura
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FACTURA #${invoice.invoiceNumber}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Fecha: ${dateFormat.format(invoice.invoiceDate)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Text(
                    invoice.isPaid ? 'PAGADO' : 'PENDIENTE',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Información del cliente
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Cliente: ${invoice.customer.customerName}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Teléfono: ${invoice.customer.phoneNumber}'),
                  if (invoice.customer.customerAddress.isNotEmpty)
                    pw.Text('Dirección: ${invoice.customer.customerAddress}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Lista de productos y servicios
            pw.Text(
              'DETALLE DE LA COMPRA',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Tabla simple
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FixedColumnWidth(60),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(80),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Descripción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Cant.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Precio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                // Productos
                ...invoice.products.map((product) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(product.productName),
                          pw.Text(
                            '${product.productType} - ${product.size ?? ''} ${product.material ?? ''}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(myFormat.format(product.quantity), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('$currency${myFormat.format(product.productPrice)}', textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('$currency${myFormat.format(product.subtotal)}', textAlign: pw.TextAlign.right),
                    ),
                  ],
                )),
                // Servicios
                ...invoice.services.map((service) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(service.serviceName),
                          pw.Text(
                            '${service.serviceType} - ${service.size ?? service.description ?? ''}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(myFormat.format(service.quantity), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('$currency${myFormat.format(service.servicePrice)}', textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('$currency${myFormat.format(service.subtotal)}', textAlign: pw.TextAlign.right),
                    ),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Notas
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Notas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(invoice.notes!),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Totales
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  children: [
                    _buildSimpleTotalRow('Subtotal:', invoice.subtotal),
                    if (invoice.discountAmount > 0)
                      _buildSimpleTotalRow('Descuento:', -invoice.discountAmount),
                    if (invoice.taxAmount > 0)
                      _buildSimpleTotalRow('ITBIS (18%):', invoice.taxAmount),
                    pw.Divider(),
                    _buildSimpleTotalRow('TOTAL:', invoice.totalAmount, bold: true),
                    if (invoice.paidAmount > 0) ...[
                      pw.SizedBox(height: 10),
                      _buildSimpleTotalRow('Pagado:', invoice.paidAmount),
                      _buildSimpleTotalRow('Pendiente:', invoice.dueAmount, 
                        color: invoice.dueAmount > 0 ? PdfColors.red : PdfColors.green),
                    ],
                  ],
                ),
              ),
            ),
            
            pw.Spacer(),
            
            // Firma
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      height: 0.5,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Firma del Cliente', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      height: 0.5,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Firma Autorizada', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Gracias por su preferencia',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

// Helper para filas de totales
pw.Widget _buildSimpleTotalRow(String label, double amount, {bool bold = false, PdfColor? color}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          '$currency${myFormat.format(amount.abs())}',
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    ),
  );
}