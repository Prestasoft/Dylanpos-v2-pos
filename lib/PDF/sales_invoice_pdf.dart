import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';
import 'package:salespro_admin/model/FullReservation.dart';
import '../const.dart';
import '../model/general_setting_model.dart';
import '../model/personal_information_model.dart';
import '../model/sale_transaction_model.dart';

///___________Sales_PDF_Formats____________________________________________________________________________________________________________________________
FutureOr<Uint8List> generateSaleDocument({
  required SaleTransactionModel transactions,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel generalSetting,
  SaleTransactionModel? post,
  required BuildContext context,
}) async {
  final imageData = await rootBundle.load('images/vg_logo.png');
  final imageBytes = imageData.buffer.asUint8List();
  final image = pw.MemoryImage(imageBytes);

  final pw.Document doc = pw.Document();
  final ref = ProviderScope.containerOf(context);
  final List<String> idReservaciones = post?.reservationIds ?? [];
  //actualizar los prodcutos
  await ref.read(ActualizarEstadoReservaProvider({
    'id': idReservaciones,
    'estado': 'confirmado',
    'estado_factura': true,
  }));
  //print("TRANSACCTION === ${transactions.key}");
  // Obtener la lista de IDs de reservaciones
  // Obtener todas las reservaciones primero
  final List<FullReservation?> reservaciones = await Future.wait(idReservaciones.map((id) => ref.read(fullReservationByIdProviderVQ(id).future)));
  double totalAmount({required SaleTransactionModel transactions}) {
    double amount = 0;

    for (var element in transactions.productList!) {
      amount = amount + double.parse(element.subTotal) * double.parse(element.quantity.toString());
    }

    return double.parse(amount.toStringAsFixed(2));
  }

  List<List<String>> rows = [];

  final notas = reservaciones
      .map((e) {
        final nota = e?.reservation['nota'];
        if (nota == null) return null;
        final texto = nota.toString().trim();
        return texto.isEmpty ? null : texto;
      })
      .whereType<String>() // Filtra los null
      .toList();

  final place = reservaciones.map((e) => e?.reservation['place']?.toString().trim()).firstWhere(
        (p) => p != null && p.isNotEmpty,
        orElse: () => '-',
      );

  for (int i = 0; i < transactions.productList!.length; i++) {
    final item = transactions.productList![i];
    print("PRODUCT ITEM ===== ${item.productId}");
    final fullReservation = ref.read(fullReservationByIdProviderVQ(item.productId)).value;
    final serviceDescription = fullReservation?.service?['description'] ?? '';

    rows.add(<String>[
      '${i + 1}',
      '''${item.productName}\n$serviceDescription''',
      myFormat.format(double.tryParse(item.quantity.toString()) ?? 0),
      myFormat.format(double.tryParse(item.subTotal.toString()) ?? 0),
      calculateProductVat(product: item),
      myFormat.format(double.tryParse((double.parse(item.subTotal) * item.quantity.toInt()).toStringAsFixed(2)) ?? 0),
    ]);
  }

  doc.addPage(
    pw.MultiPage(
      // pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
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
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 20.0, fontWeight: pw.FontWeight.bold),
                      ),

                      ///______Phone________________________________________________________________
                      pw.Container(
                        padding: const pw.EdgeInsets.all(1.0),
                        child: pw.Center(
                          child: pw.Text(
                            'Teléfono: ${personalInformation.phoneNumber}',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 14.0),
                          ),
                        ),
                      ),

                      ///______Address________________________________________________________________
                      // pw.Container(
                      //   padding: const pw.EdgeInsets.all(1.0),
                      //   child: pw.Center(
                      //     child: pw.Text(
                      //       'Dirección: ${personalInformation.countryName}',
                      //       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 14.0),
                      //     ),
                      //   ),
                      // ),

                      pw.Container(
                        width: 300,
                        child: pw.Text(
                          "Lugar: ${place ?? 'Sin lugar'}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 11,
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
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 14.0),
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
                        'Factura de Reservacion',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 16.0, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

              ///___________price_section_____________________________________________________
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
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
                        transactions.customerName,
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
                        transactions.customerPhone,
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),

                  ///_____Address_______________________________________
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 75.0,
                        child: pw.Text(
                          'Lugar',
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
                          place ?? '-',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),

                      // pw.SizedBox(
                      //   width: 75.0,
                      //   child: pw.Text(
                      //     'Dirección',
                      //     style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      //   ),
                      // ),
                      // pw.SizedBox(
                      //   width: 10.0,
                      //   child: pw.Text(
                      //     ':',
                      //     style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      //   ),
                      // ),
                      // pw.SizedBox(
                      //   width: 140.0,
                      //   child: pw.Text(
                      //     transactions.customerAddress,
                      //     style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      //   ),
                      // ),
                    ],
                  ),
                  pw.SizedBox(height: 2),

                  ///_____Reservation Date_______________________________________
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 75.0,
                        child: pw.Text(
                          reservaciones.isNotEmpty ? 'Fecha de reservación' : '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          reservaciones.isNotEmpty ? ':' : '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 140.0,
                        child: pw.Text(
                          reservaciones.isNotEmpty ? _formatearFechaYHora(reservaciones.first?.reservation['reservation_date'], reservaciones.first?.reservation?['reservation_time']) : '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 2),

                  ///_____Party GST_______________________________________
                  pw.SizedBox(height: transactions.customerGst.trim().isNotEmpty ? 2 : 0),
                  transactions.customerGst.trim().isNotEmpty
                      ? pw.Row(children: [
                          pw.SizedBox(
                            width: 75.0,
                            child: pw.Text(
                              'RNC',
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
                              transactions.customerGst,
                              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                            ),
                          ),
                        ])
                      : pw.Container(),
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
                        '#${transactions.invoiceNumber}',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 2),

                  ///_________Sells By________________________________________________
                  pw.Row(children: [
                    pw.SizedBox(
                      width: 50.0,
                      child: pw.Text(
                        'Vendido por',
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
                        transactions.sellerName ?? "Admin",
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 2),

                  ///______Date__________________________________________________________
                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
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
                    pw.Container(
                      width: 125.0,
                      child: pw.Text(
                        '${DateFormat.yMd().format(DateTime.parse(transactions.purchaseDate))}, ${DateFormat.jm().format(DateTime.parse(transactions.purchaseDate))}',
                        // DateTimeFormat.format(DateTime.parse(transactions.purchaseDate), format: AmericanDateTimeFormats.),
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 2),

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
                        transactions.isPaid! ? 'Pagado' : 'Pendiente',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ]),
                ]),
              ]),
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
            pw.Text('Powered By ${generalSetting.companyName.isNotEmpty == true ? generalSetting.companyName : pdfFooter}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
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
                // headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#D5D8DC')),
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
                // oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
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
                  <String>['N°', 'Descripción del producto', 'Cantidad', 'Precio unitario', 'Impuesto', 'Precio total'],
                  ...rows
                ],
              ),
              // pw.SizedBox(width: 5),
              pw.Paragraph(text: ""),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(
                      "Método de Pago: ${transactions.paymentType}",
                      style: const pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 11,
                      ),
                    ),
                    pw.SizedBox(height: 10.0),
                    pw.Container(
                      width: 300,
                      child: pw.Text(
                        "En Palabras: ${amountToWordsEs(transactions.totalAmount!.toInt())}",
                        maxLines: 3,
                        style: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(height: 10.0),
                    // pw.Container(
                    //   width: 300,
                    //   child: pw.Text(
                    //     "Lugar: ${place ?? 'Sin lugar'}",
                    //     style: pw.TextStyle(
                    //       color: PdfColors.black,
                    //       fontSize: 11,
                    //     ),
                    //   ),
                    // ),
                    // pw.SizedBox(height: 10.0),
                    pw.Container(
                      width: 300,
                      child: pw.Text(
                        "Notas: ${notas.isEmpty ? 'Sin notas' : notas.join(', ')}",
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontSize: 11,
                        ),
                      ),
                    )
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
                                'Total',
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
                                myFormat.format(double.tryParse(totalAmount(transactions: transactions).toString()) ?? 0),
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                      color: PdfColors.black,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),

                          ///________vat_______________________________________________
                          pw.ListView.builder(
                            itemCount: getAllTaxFromCartList(cart: transactions.productList ?? []).length,
                            itemBuilder: (context, index) {
                              return pw.Row(children: [
                                pw.SizedBox(
                                  width: 100.0,
                                  child: pw.Text(
                                    getAllTaxFromCartList(cart: transactions.productList ?? [])[index].name,
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
                                    '${getAllTaxFromCartList(cart: transactions.productList ?? [])[index].taxRate}%',
                                    style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                          color: PdfColors.black,
                                          fontSize: 11,
                                        ),
                                  ),
                                ),
                              ]);
                            },
                          ),

                          pw.SizedBox(height: 2),

                          ///________Service/Shipping__________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 100.0,
                              child: pw.Text(
                                "Envío/Servicios",
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
                                myFormat.format(double.tryParse(transactions.serviceCharge.toString()) ?? 0),
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

                          ///________Sub Total Amount_______________________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 100.0,
                              child: pw.Text(
                                'Sub-Total',
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
                                myFormat.format(double.tryParse((transactions.vat!.toDouble() + transactions.serviceCharge!.toDouble() + totalAmount(transactions: transactions)).toString()) ?? 0),
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                      color: PdfColors.black,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),

                          ///________Discount_______________________________________________
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
                                '- ${myFormat.format(double.tryParse(transactions.discountAmount.toString()) ?? 0)}',
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

                          ///________payable_Amount_______________________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 150.0,
                              child: pw.Text(
                                'Monto Neto a Pagar',
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.centerRight,
                              width: 100.0,
                              child: pw.Text(
                                myFormat.format(double.tryParse(transactions.totalAmount.toString()) ?? 0),
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),

                          ///________Received_Amount_______________________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 100.0,
                              child: pw.Text(
                                'Monto Recibido',
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
                                myFormat.format(double.tryParse((transactions.totalAmount! - transactions.dueAmount!).toString())),
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

                          ///________Received_Amount_______________________________________________
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
                            // pw.SizedBox(
                            //   width: 10.0,
                            //   child: pw.Text(
                            //     ':',
                            //     style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                            //   ),
                            // ),
                            pw.Container(
                              alignment: pw.Alignment.centerRight,
                              width: 150.0,
                              child: pw.Text(
                                myFormat.format(double.tryParse(transactions.dueAmount!.toString()) ?? 0),
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                      color: PdfColors.black,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),
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

Future<Uint8List> generateThermalDocument({
  required PersonalInformationModel personalInformation,
  required SaleTransactionModel transactions,
  required GeneralSettingModel generalSetting,
  SaleTransactionModel? post,
  required BuildContext context,
}) async {
  final pdf = pw.Document();
  final ref = ProviderScope.containerOf(context);
  final List<String> idReservaciones = post?.reservationIds ?? [];

  //debugger();

  //actualizar los prodcutos
  await ref.read(ActualizarEstadoReservaProvider({
    'id': idReservaciones,
    'estado': 'confirmado',
    'estado_factura': true,
  }));
  // Obtener la lista de IDs de reservaciones
  // Obtener todas las reservaciones primero
  final List<FullReservation?> reservaciones = await Future.wait(idReservaciones.map((id) => ref.read(fullReservationByIdProviderVQ(id).future)));

  // Configuración para impresora térmica (80mm de ancho)
  const pageWidth = 80 * PdfPageFormat.mm;
  const pageHeight = double.infinity;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: 2 * PdfPageFormat.mm),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Encabezado - Información de la empresa
            pw.Center(
              child: pw.Text(
                personalInformation.companyName.toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'Tel: ${personalInformation.phoneNumber}',
                style: pw.TextStyle(fontSize: 8),
              ),
            ),
            if (personalInformation.gst.trim().isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'RNC: ${personalInformation.gst}',
                  style: pw.TextStyle(fontSize: 8),
                ),
              ),
            pw.Center(
              child: pw.Text(
                personalInformation.countryName,
                style: pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.Divider(thickness: 0.5),

            // Tipo de documento
            pw.Center(
              child: pw.Text(
                'FACTURA DE RESERVACIÓN',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),

            // Información de la factura
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('No:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('#${transactions.invoiceNumber}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Fecha:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(transactions.purchaseDate)),
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Cliente:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  post?.customerName ?? '',
                  // Fallback to an empty string if customerName is null
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            if (transactions.customerPhone.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Teléfono:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(transactions.customerPhone, style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
            pw.Divider(thickness: 0.5),

            // Sección de reservaciones
            if (reservaciones.isNotEmpty) ...[
              pw.Center(
                child: pw.Text(
                  'RESERVACIONES ASOCIADAS',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              for (final reservacion in reservaciones.where((r) => r != null)) _buildReservationSection(reservacion!),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 5),
            ],

            // Encabezado de productos
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 13,
                  child: pw.Text('Nº ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('Descripción', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(
                  width: 30,
                  child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),

            pw.Divider(thickness: 0.2),

            ...transactions.productList!.map((item) {
              final fullReservation = ref.read(fullReservationByIdProviderVQ(item.productId)).value;
              final serviceDescription = fullReservation?.service?['description'] ?? '';

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 13,
                      child: pw.Text(
                        '${item.quantity}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            serviceDescription ?? '',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                          pw.Text(
                            '${formatCurrency(double.parse(item.subTotal))}',
                            style: pw.TextStyle(fontSize: 6),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      width: 40,
                      child: pw.Text(
                        formatCurrency(double.parse(item.subTotal) * item.quantity),
                        style: pw.TextStyle(fontSize: 6),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.Divider(thickness: 0.5),

            // Totales
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 8)),
                pw.Text(
                  formatCurrency(transactions.totalAmount! - transactions.vat! - transactions.serviceCharge!),
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            ),

            if (transactions.vat! > 0) ...[
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('IVA:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text(formatCurrency(transactions.vat!), style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],

            if (transactions.serviceCharge! > 0) ...[
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Servicio:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text(formatCurrency(transactions.serviceCharge!), style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],

            if (transactions.discountAmount! > 0) ...[
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Descuento:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text('-${formatCurrency(transactions.discountAmount!)}', style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],

            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  formatCurrency(transactions.totalAmount!),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),

            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pagado:', style: pw.TextStyle(fontSize: 8)),
                pw.Text(
                  formatCurrency(transactions.totalAmount! - transactions.dueAmount!),
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            ),

            if (transactions.dueAmount! > 0) ...[
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pendiente:', style: pw.TextStyle(fontSize: 8)),
                  pw.Text(formatCurrency(transactions.dueAmount!), style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],

            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Método:', style: pw.TextStyle(fontSize: 8)),
                pw.Text(transactions.paymentType ?? '', style: pw.TextStyle(fontSize: 8)),
              ],
            ),

            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 5),

            // Mensaje de agradecimiento
            pw.Center(
              child: pw.Text(
                '¡Gracias por su compra!',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),

            // Pie de página
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                generalSetting.companyName.isNotEmpty ? generalSetting.companyName : 'Powered by YourAppName',
                style: pw.TextStyle(fontSize: 7),
              ),
            ),

            pw.Center(
              child: pw.Text(
                '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 7),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// Función auxiliar para construir la sección de cada reservación
pw.Widget _buildReservationSection(FullReservation reservacion) {
  String nombresVestidos = "";

  if (reservacion.reservation['multiple_dress'] != null) {
    final multipleDress = reservacion.reservation['multiple_dress'] as List;
    // Filtrar los nombres de los vestidos
    if (multipleDress.isNotEmpty) {
      nombresVestidos = multipleDress.map((e) => e['dress_name'] ?? '').where((name) => name.isNotEmpty).join('\n');
    }
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Fecha:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            DateFormat('dd/MM/yy HH:mm').format(
              DateTime.fromMillisecondsSinceEpoch(
                reservacion.reservation['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
              ),
            ),
            style: pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
      if (reservacion.reservation['multiple_dress'] != null) ...[
        pw.SizedBox(height: 2),
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Vestimenta:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              nombresVestidos,
              style: pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
      if (reservacion.dress != null) ...[
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Vestido:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              () {
                final name = reservacion.dress?['name']?.toString();
                if (name == null || name.isEmpty) return 'N/A';
                return name.length > 20 ? '${name.substring(0, 20)}...' : name;
              }(),
              style: pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
      if (reservacion.service != null) ...[
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Servicio:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              (reservacion.service?['name']?.toString() ?? '').isEmpty ? '' : reservacion.service!['name']!.toString(),
              style: pw.TextStyle(fontSize: 8),
              softWrap: true,
            ),
          ],
        ),
      ],
      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Estado:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            reservacion.reservation['estado']?.toString().toUpperCase() ?? 'Confirmado',
            style: pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
      if (reservacion.reservation['place'] != null && reservacion.reservation['place'].toString().isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Notas:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 5),
            pw.Text(
              reservacion.reservation['place'].toString(),
              style: pw.TextStyle(fontSize: 8),
              maxLines: 2,
            ),
          ],
        ),
      ],
      if (reservacion.reservation['nota'] != null && reservacion.reservation['nota'].toString().isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Notas:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 5),
            pw.Text(
              reservacion.reservation['nota'].toString(),
              style: pw.TextStyle(fontSize: 8),
              maxLines: 2,
            ),
          ],
        ),
      ],
      pw.Divider(thickness: 0.5),
      pw.SizedBox(height: 5),
    ],
  );
}

String formatCurrency(double amount, {String symbol = '\$', bool useCommas = true}) {
  final formattedAmount = amount.toStringAsFixed(2);

  if (useCommas) {
    final parts = formattedAmount.split('.');
    final integerPart = _addThousandSeparators(parts[0]);
    return '$symbol$integerPart.${parts[1]}';
  }

  return '$symbol$formattedAmount';
}

String formatProductName(String? productName, {int maxLength = 20, String defaultText = 'Producto'}) {
  if (productName == null || productName.isEmpty) {
    return defaultText;
  }

  return productName.length > maxLength ? '${productName.substring(0, maxLength)}...' : productName;
}

/// Función auxiliar para agregar separadores de miles
String _addThousandSeparators(String number) {
  final reversed = number.split('').reversed.join();
  final chunks = <String>[];

  for (var i = 0; i < reversed.length; i += 3) {
    final end = i + 3 > reversed.length ? reversed.length : i + 3;
    chunks.add(reversed.substring(i, end));
  }

  return chunks.join(',').split('').reversed.join();
}

/// Formatea una fecha en formato dd/MM/yyyy HH:mm
///
/// Ejemplo:
/// ```dart
/// formatDate(DateTime.now())  // Retorna: 31/12/2023 23:59
/// ```
String formatDate(DateTime date, {bool includeSeconds = false}) {
  final formatPattern = includeSeconds ? 'dd/MM/yyyy HH:mm:ss' : 'dd/MM/yyyy HH:mm';
  return DateFormat(formatPattern).format(date);
}

/// Formatea una fecha en formato corto (dd/MM/yyyy)
String formatShortDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

/// Formatea una hora en formato HH:mm (opcionalmente con segundos)
String formatTime(DateTime date, {bool includeSeconds = false}) {
  return DateFormat(includeSeconds ? 'HH:mm:ss' : 'HH:mm').format(date);
}

/// Versión extendida con más opciones de formato
String formatDateTime(
  DateTime date, {
  bool includeDate = true,
  bool includeTime = true,
  bool includeSeconds = false,
  String separator = ' ',
}) {
  final datePart = includeDate ? formatShortDate(date) : '';
  final timePart = includeTime ? formatTime(date, includeSeconds: includeSeconds) : '';

  return [datePart, timePart].where((part) => part.isNotEmpty).join(separator);
}

String formatearFecha(String? fecha) {
  if (fecha == null || fecha.isEmpty) return '-';
  try {
    final date = DateTime.parse(fecha);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    return '-';
  }
}

String _formatearFechaYHora(String? fecha, String? hora) {
  if (fecha == null || fecha.isEmpty) return '-';
  try {
    final date = DateTime.parse(fecha);
    final fechaFormateada = DateFormat('dd/MM/yyyy').format(date);
    return hora != null && hora.isNotEmpty ? '$fechaFormateada $hora' : fechaFormateada;
  } catch (e) {
    return '-';
  }
}
