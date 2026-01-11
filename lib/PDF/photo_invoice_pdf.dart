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

FutureOr<Uint8List> generatePhotoInvoiceDocument({
  required PhotoInvoiceModel invoice,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel generalSetting,
}) async {
  // Cargar logo de la empresa
  final imageData = await rootBundle.load('images/vg_logo.png');
  final imageBytes = imageData.buffer.asUint8List();
  final image = pw.MemoryImage(imageBytes);

  final pw.Document doc = pw.Document();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  // Función para calcular totales
  double calculateTotal() {
    double total = 0;
    for (var product in invoice.products) {
      total += product.subtotal;
    }
    for (var service in invoice.services) {
      total += service.subtotal;
    }
    return total;
  }

  // Preparar filas para la tabla unificada
  List<List<String>> rows = [];
  int index = 1;

  // Agregar productos
  for (var product in invoice.products) {
    rows.add(<String>[
      '$index',
      '''${product.productName}
${product.productType.toUpperCase()} - ${product.size ?? ''} ${product.material ?? ''}''',
      myFormat.format(product.quantity),
      '$currency${myFormat.format(product.productPrice)}',
      '-',
      '$currency${myFormat.format(product.subtotal)}',
    ]);
    index++;
  }

  // Agregar servicios
  for (var service in invoice.services) {
    rows.add(<String>[
      '$index',
      '''${service.serviceName}
${service.serviceType.toUpperCase()} - ${service.size ?? service.description ?? ''}''',
      myFormat.format(service.quantity),
      '$currency${myFormat.format(service.servicePrice)}',
      '-',
      '$currency${myFormat.format(service.subtotal)}',
    ]);
    index++;
  }

  doc.addPage(
    pw.MultiPage(
      margin: pw.EdgeInsets.zero,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      header: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20.0, right: 20, bottom: 20, top: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 150,
                    padding: const pw.EdgeInsets.all(10.0),
                    child: pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Image(
                            image,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        personalInformation.companyName,
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          color: PdfColors.black, 
                          fontSize: 20.0, 
                          fontWeight: pw.FontWeight.bold
                        ),
                      ),
                      ///______Phone________________________________________________________________
                      pw.Container(
                        padding: const pw.EdgeInsets.all(1.0),
                        child: pw.Center(
                          child: pw.Text(
                            'Teléfono: ${personalInformation.phoneNumber}',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(
                              color: PdfColors.black, 
                              fontSize: 14.0
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10.0),
                      ///______Shop_GST________________________________________________________________
                      personalInformation.gst.trim().isNotEmpty
                          ? pw.Container(
                              padding: const pw.EdgeInsets.all(1.0),
                              child: pw.Center(
                                child: pw.Text(
                                  'RNC: ${personalInformation.gst}',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black, 
                                    fontSize: 14.0
                                  ),
                                ),
                              ),
                            )
                          : pw.Container(),
                    ],
                  )
                ],
              ),

              ///________Bill/Invoice_________________________________________________________
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10.0),
                child: pw.Center(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2.0, bottom: 2, left: 5, right: 5),
                      child: pw.Text(
                        'Factura de Impresión y Enmarcado',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          color: PdfColors.black, 
                          fontSize: 16.0, 
                          fontWeight: pw.FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              ///___________price_section_____________________________________________________
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, 
                crossAxisAlignment: pw.CrossAxisAlignment.start, 
                children: [
                  ///_________Left_Side__________________________________________________________
                  pw.Column(children: [
                    ///_____Name_______________________________________
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 75.0,
                        child: pw.Text(
                          'Cliente',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 140.0,
                        child: pw.Text(
                          invoice.customer.customerName,
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),

                    ///_____Phone_______________________________________
                    pw.SizedBox(height: 2),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 75.0,
                        child: pw.Text(
                          'Teléfono',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 140.0,
                        child: pw.Text(
                          invoice.customer.phoneNumber,
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),

                    ///_____Address_______________________________________
                    if (invoice.customer.customerAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(children: [
                        pw.SizedBox(
                          width: 75.0,
                          child: pw.Text(
                            'Dirección',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 10.0,
                          child: pw.Text(
                            ':',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 140.0,
                          child: pw.Text(
                            invoice.customer.customerAddress,
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                      ]),
                    ],
                  ]),

                  ///_________Right_Side___________________________________________________________
                  pw.Column(children: [
                    ///______invoice_number_____________________________________________
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 50.0,
                        child: pw.Text(
                          'Factura',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 125.0,
                        child: pw.Text(
                          '#${invoice.invoiceNumber}',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.SizedBox(height: 2),

                    ///______Date__________________________________________________________
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 50.0,
                        child: pw.Text(
                          'Fecha',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 125.0,
                        child: pw.Text(
                          dateFormat.format(invoice.invoiceDate),
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.SizedBox(height: 2),

                    ///______Payment_Method____________________________________________
                    if (invoice.paymentMethod.isNotEmpty) ...[
                      pw.Row(children: [
                        pw.SizedBox(
                          width: 50.0,
                          child: pw.Text(
                            'Pago',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 10.0,
                          child: pw.Text(
                            ':',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 125.0,
                          child: pw.Text(
                            invoice.paymentMethod,
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                      ]),
                      pw.SizedBox(height: 2),
                    ],

                    ///______Status____________________________________________
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 50.0,
                        child: pw.Text(
                          'Estado',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 125.0,
                        child: pw.Text(
                          invoice.isPaid ? 'Pagado' : 'Pendiente',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(
                            color: PdfColors.black, 
                            fontWeight: pw.FontWeight.bold
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ]
              ),
            ],
          ),
        );
      },
      footer: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10.0),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    child: pw.Column(children: [
                      pw.Container(
                        width: 120.0,
                        height: 1.0,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4.0),
                      pw.Text(
                        'Firma del Cliente',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          color: PdfColors.black,
                          fontSize: 11,
                        ),
                      )
                    ]),
                  ),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: 120.0,
                          height: 1.0,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 4.0),
                        pw.Text(
                          'Firma Autorizada',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(
                            color: PdfColors.black,
                            fontSize: 11,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Text(
              'Powered By ${generalSetting.companyName.isNotEmpty == true ? generalSetting.companyName : "Sistema POS"}', 
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)
            ),
            pw.SizedBox(height: 5),
          ],
        );
      },
      build: (pw.Context context) => <pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
          child: pw.Column(
            children: [
              ///___________Table__________________________________________________________
              pw.Table.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  left: pw.BorderSide(
                    color: PdfColors.grey600,
                  ),
                  right: pw.BorderSide(
                    color: PdfColors.grey600,
                  ),
                  bottom: pw.BorderSide(
                    color: PdfColors.grey600,
                  ),
                  top: pw.BorderSide(
                    color: PdfColors.grey600,
                  ),
                  verticalInside: pw.BorderSide(
                    color: PdfColors.grey600,
                  ),
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.grey600,
                  ),
                ),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(6),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.7),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
                headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                headerAlignments: <int, pw.Alignment>{
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                cellAlignments: <int, pw.Alignment>{
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                data: <List<String>>[
                  <String>['N°', 'Descripción', 'Cantidad', 'Precio unitario', 'Impuesto', 'Precio total'],
                  ...rows
                ],
              ),
              pw.Paragraph(text: ""),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    if (invoice.paymentMethod.isNotEmpty) ...[
                      pw.Text(
                        "Método de Pago: ${invoice.paymentMethod}",
                        style: const pw.TextStyle(
                          color: PdfColors.black,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 10.0),
                    ],
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      pw.Container(
                        width: 300,
                        child: pw.Text(
                          "Notas: ${invoice.notes}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ]),
                  
                  pw.SizedBox(
                    width: 250.0,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Column(children: [
                          ///________Total_Amount_____________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 100.0,
                              child: pw.Text(
                                'Subtotal',
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                  color: PdfColors.black,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.centerRight,
                              width: 150.0,
                              child: pw.Text(
                                '$currency${myFormat.format(invoice.subtotal)}',
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                  color: PdfColors.black,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),

                          ///________Discount_______________________________________________
                          if (invoice.discountAmount > 0) ...[
                            pw.Row(children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  'Descuento',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              pw.Container(
                                alignment: pw.Alignment.centerRight,
                                width: 150.0,
                                child: pw.Text(
                                  '- $currency${myFormat.format(invoice.discountAmount)}',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 2),
                          ],

                          ///________Tax_______________________________________________
                          if (invoice.taxAmount > 0) ...[
                            pw.Row(children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  'ITBIS (18%)',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              pw.Container(
                                alignment: pw.Alignment.centerRight,
                                width: 150.0,
                                child: pw.Text(
                                  '$currency${myFormat.format(invoice.taxAmount)}',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 2),
                          ],

                          ///_________divider__________________________________________
                          pw.Divider(thickness: .5, height: 0.5, color: PdfColors.black),
                          pw.SizedBox(height: 2),

                          ///________payable_Amount_______________________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 150.0,
                              child: pw.Text(
                                'Monto Total a Pagar',
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                  color: PdfColors.black, 
                                  fontSize: 11, 
                                  fontWeight: pw.FontWeight.bold
                                ),
                              ),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.centerRight,
                              width: 100.0,
                              child: pw.Text(
                                '$currency${myFormat.format(invoice.totalAmount)}',
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                  color: PdfColors.black, 
                                  fontSize: 11, 
                                  fontWeight: pw.FontWeight.bold
                                ),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),

                          ///________Paid_Amount_______________________________________________
                          if (invoice.paidAmount > 0) ...[
                            pw.Row(children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  'Monto Pagado',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              pw.Container(
                                alignment: pw.Alignment.centerRight,
                                width: 150.0,
                                child: pw.Text(
                                  '$currency${myFormat.format(invoice.paidAmount)}',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 2),

                            ///_________divider__________________________________________
                            pw.Divider(thickness: .5, height: 0.5, color: PdfColors.black),
                            pw.SizedBox(height: 2),

                            ///________Due_Amount_______________________________________________
                            pw.Row(children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  'Monto Pendiente',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: PdfColors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              pw.Container(
                                alignment: pw.Alignment.centerRight,
                                width: 150.0,
                                child: pw.Text(
                                  '$currency${myFormat.format(invoice.dueAmount)}',
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                    color: invoice.dueAmount > 0 ? PdfColors.red : PdfColors.green,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 2),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Padding(padding: const pw.EdgeInsets.all(10)),
            ],
          ),
        ),
      ],
    ),
  );

  return doc.save();
}