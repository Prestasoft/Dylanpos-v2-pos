import 'dart:async';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/model/personal_information_model.dart';

import '../const.dart';
import '../model/general_setting_model.dart';
import '../model/purchase_transation_model.dart';

///___________Purchase_PDF_Formats_______________________________________________________________________________________________________________________________________________________________
FutureOr<Uint8List> generatePurchaseReturnDocument(
    {required PurchaseTransactionModel transactions, required PersonalInformationModel personalInformation, required GeneralSettingModel setting}) async {
  final pw.Document doc = pw.Document();

  double totalPurchaseAmount({required PurchaseTransactionModel transactions}) {
    double amount = 0;

    for (var element in transactions.productList!) {
      amount = amount + double.parse(element.productPurchasePrice.toString()) * double.parse(element.productStock.toString());
    }

    return double.parse(amount.toStringAsFixed(2));
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
              ///________Company_Name_________________________________________________________
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10.0),
                child: pw.Center(
                  child: pw.Text(
                    personalInformation.companyName,
                    style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 22.0, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),

              ///______Phone________________________________________________________________
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(1.0),
                child: pw.Center(
                  child: pw.Text(
                    'Teléfono: ${personalInformation.phoneNumber}',
                    style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 14.0),
                  ),
                ),
              ),

              ///______Address________________________________________________________________
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(1.0),
                child: pw.Center(
                  child: pw.Text(
                    'Dirección: ${personalInformation.countryName}',
                    style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 14.0),
                  ),
                ),
              ),

              ///______Shop_GST________________________________________________________________
              personalInformation.gst.trim().isNotEmpty
                  ? pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(1.0),
                      child: pw.Center(
                        child: pw.Text(
                          'GST del Proveedor: ${personalInformation.gst}',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 14.0),
                        ),
                      ),
                    )
                  : pw.Container(),

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
                            'Factura de Devolución',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 16.0, fontWeight: pw.FontWeight.bold),
                          ),
                        ))),
              ),

              ///___________price_section_____________________________________________________
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                ///_________Left_Side__________________________________________________________
                pw.Column(children: [
                  ///_____Name_______________________________________
                  pw.Row(children: [
                    pw.SizedBox(
                      width: 60.0,
                      child: pw.Text(
                        'Proveedor',
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
                      width: 60.0,
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
                  pw.Row(children: [
                    pw.SizedBox(
                      width: 60.0,
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
                        transactions.customerAddress,
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),

                  ///_____Party GST_______________________________________
                  pw.SizedBox(height: transactions.customerGst.trim().isNotEmpty ? 2 : 0),
                  transactions.customerGst.trim().isNotEmpty
                      ? pw.Row(children: [
                          pw.SizedBox(
                            width: 60.0,
                            child: pw.Text(
                              'Party GST',
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

                  ///_____Remarks_______________________________________
                  // pw.SizedBox(height: 2),
                  // pw.Row(children: [
                  //   pw.SizedBox(
                  //     width: 60.0,
                  //     child: pw.Text(
                  //       'Remarks',
                  //       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                  //     ),
                  //   ),
                  //   pw.SizedBox(
                  //     width: 10.0,
                  //     child: pw.Text(
                  //       ':',
                  //       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                  //     ),
                  //   ),
                  //   pw.SizedBox(
                  //     width: 140.0,
                  //     child: pw.Text(
                  //       '',
                  //       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                  //     ),
                  //   ),
                  // ]),
                ]),

                ///_________Right_Side___________________________________________________________
                pw.Column(children: [
                  ///______invoice_number_____________________________________________
                  pw.Row(children: [
                    pw.SizedBox(
                      width: 60.0,
                      child: pw.Text(
                        'Factura de Compra',
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
                        '#Return-${transactions.invoiceNumber}',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 2),

                  ///_________Sells By________________________________________________
                  pw.Row(children: [
                    pw.SizedBox(
                      width: 60.0,
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
                        'Admin',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 2),

                  ///______Date__________________________________________________________
                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.SizedBox(
                      width: 60.0,
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
                      width: 60.0,
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
                        transactions.invoiceNumber,
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
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
        return pw.Column(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(10.0),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
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
                child: pw.Column(children: [
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
                ]),
              ),
            ]),
          ),
          pw.Text('Powered By ${setting.companyName.isNotEmpty == true ? setting.companyName : pdfFooter}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
          pw.SizedBox(height: 5),
        ]);
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
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.7),
                  5: const pw.FlexColumnWidth(1.5),
                },
                headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                // oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                headerAlignments: <int, pw.Alignment>{
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                cellAlignments: <int, pw.Alignment>{
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                data: <List<String>>[
                  <String>['SL', 'Descripción del Producto', 'Garantía', 'Cantidad', 'Precio Unitario', 'Precio'],
                  for (int i = 0; i < transactions.productList!.length; i++)
                    <String>[
                      ('${i + 1}'),
                      ("${transactions.productList!.elementAt(i).productName.toString()}\n${transactions.productList!.elementAt(i).serialNumber.isEmpty ? '' : transactions.productList!.elementAt(i).serialNumber.toString()}"),
                      // (transactions.productList!.elementAt(i).productName.toString()),
                      (transactions.productList!.elementAt(i).warranty.isEmptyOrNull ? '' : transactions.productList!.elementAt(i).warranty),
                      (myFormat.format(double.tryParse(transactions.productList!.elementAt(i).productStock.toString()) ?? 0)),
                      (myFormat.format(double.tryParse(transactions.productList!.elementAt(i).productPurchasePrice.toString()) ?? 0)),
                      (myFormat.format(double.tryParse(
                              (double.parse(transactions.productList!.elementAt(i).productPurchasePrice) * double.parse(transactions.productList!.elementAt(i).productStock))
                                  .toStringAsFixed(2)) ??
                          0))
                    ],
                ],
              ),
              // pw.SizedBox(width: 5),
              pw.Paragraph(text: ""),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Container(
                      width: 300,
                      child: pw.Text(
                        "En Palabras: ${amountToWords(transactions.totalAmount!.toInt())}",
                        maxLines: 3,
                        style: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
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
                                'Monto Total Devuelto',
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
                                myFormat.format(double.tryParse(totalPurchaseAmount(transactions: transactions).toString()) ?? 0),
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                      color: PdfColors.black,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 2),

                          // ///________vat_______________________________________________
                          // pw.Row(children: [
                          //   pw.SizedBox(
                          //     width: 100.0,
                          //     child: pw.Text(
                          //       'Vat',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          //   pw.Container(
                          //     alignment: pw.Alignment.centerRight,
                          //     width: 150.0,
                          //     child: pw.Text(
                          //       '0',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          // ]),
                          // pw.SizedBox(height: 2),

                          ///________Service/Shipping__________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 100.0,
                              child: pw.Text(
                                "Service/Shipping",
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
                                '0',
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
                          // pw.Row(children: [
                          //   pw.SizedBox(
                          //     width: 100.0,
                          //     child: pw.Text(
                          //       'Sub-Total',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          //   pw.Container(
                          //     alignment: pw.Alignment.centerRight,
                          //     width: 150.0,
                          //     child: pw.Text(
                          //       myFormat.format(double.tryParse(transactions.totalAmount.toString()) ?? 0),
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          // ]),
                          // pw.SizedBox(height: 2),
                          //
                          // ///________Discount_______________________________________________
                          // pw.Row(children: [
                          //   pw.SizedBox(
                          //     width: 100.0,
                          //     child: pw.Text(
                          //       'Discount',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          //   pw.Container(
                          //     alignment: pw.Alignment.centerRight,
                          //     width: 150.0,
                          //     child: pw.Text(
                          //       '- ${myFormat.format(double.tryParse(transactions.discountAmount.toString()) ?? 0)}',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          // ]),
                          // pw.SizedBox(height: 2),
                          //
                          // ///_________divider__________________________________________
                          // pw.Divider(thickness: .5, height: 0.5, color: PdfColors.black),
                          // pw.SizedBox(height: 2),

                          ///________payable_Amount_______________________________________________
                          pw.Row(children: [
                            pw.SizedBox(
                              width: 150.0,
                              child: pw.Text(
                                'Total Return Amount',
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
                          // pw.Row(children: [
                          //   pw.SizedBox(
                          //     width: 100.0,
                          //     child: pw.Text(
                          //       'Received Amount',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          //   pw.Container(
                          //     alignment: pw.Alignment.centerRight,
                          //     width: 150.0,
                          //     child: pw.Text(
                          //       myFormat.format(double.tryParse((transactions.totalAmount! - transactions.dueAmount!).toString()) ?? 0),
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          // ]),
                          // pw.SizedBox(height: 2),
                          //
                          // ///_________divider__________________________________________
                          // pw.Divider(thickness: .5, height: 0.5, color: PdfColors.black),
                          // pw.SizedBox(height: 2),
                          //
                          // ///________Received_Amount_______________________________________________
                          // pw.Row(children: [
                          //   pw.SizedBox(
                          //     width: 100.0,
                          //     child: pw.Text(
                          //       'Due Amount',
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          //   // pw.SizedBox(
                          //   //   width: 10.0,
                          //   //   child: pw.Text(
                          //   //     ':',
                          //   //     style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          //   //   ),
                          //   // ),
                          //   pw.Container(
                          //     alignment: pw.Alignment.centerRight,
                          //     width: 150.0,
                          //     child: pw.Text(
                          //       myFormat.format(double.tryParse(transactions.dueAmount!.toString())),
                          //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
                          //         color: PdfColors.black,
                          //         fontSize: 11,
                          //       ),
                          //     ),
                          //   ),
                          // ]),
                          // pw.SizedBox(height: 2),
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
