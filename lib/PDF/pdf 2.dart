// ignore_for_file: file_names

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:number_to_character/number_to_character.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salespro_admin/model/personal_information_model.dart';

import '../model/purchase_transation_model.dart';

class GeneratePdf {
  Future<void> generateDocument(PurchaseTransactionModel transactions, PersonalInformationModel personalInformation) async {
    final pw.Document doc = pw.Document();
    final netImage = await networkImage(
      'https://www.nfet.net/nfet.jpg',
    );
    EasyLoading.show(status: 'Generating PDF');
    doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: pw.EdgeInsets.zero,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        header: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20.0),
            child: pw.Column(
              children: [
                pw.Row(children: [
                  pw.Container(
                    height: 50.0,
                    width: 50.0,
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    decoration: pw.BoxDecoration(image: pw.DecorationImage(image: netImage), shape: pw.BoxShape.circle),
                  ),
                  pw.SizedBox(width: 10.0),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(
                      personalInformation.companyName,
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 25.0, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Tel: ${personalInformation.phoneNumber!}',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.red),
                    ),
                  ]),
                ]),
                pw.SizedBox(height: 30.0),
                pw.Row(children: [
                  pw.Expanded(
                    child: pw.Container(
                      height: 40.0,
                      color: PdfColor.fromHex('#007AD0'),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10.0, right: 10.0),
                    child: pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 25.0,
                      ),
                    ),
                  ),
                  pw.Container(
                    height: 40.0,
                    color: PdfColor.fromHex('#007AD0'),
                    width: 100,
                  ),
                ]),
                pw.SizedBox(height: 30.0),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(children: [
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Bill To',
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
                        width: 100.0,
                        child: pw.Text(
                          transactions.customerName,
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Phone',
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
                        width: 100.0,
                        child: pw.Text(
                          transactions.customerPhone,
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                  ]),
                  pw.Column(children: [
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Sells By',
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
                        width: 100.0,
                        child: pw.Text(
                          'Admin',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Invoice Number',
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
                        width: 100.0,
                        child: pw.Text(
                          '#${transactions.invoiceNumber}',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Date',
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
                        width: 100.0,
                        child: pw.Text(
                          DateTimeFormat.format(DateTime.parse(transactions.purchaseDate), format: 'D, M j'),
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
                      height: 2.0,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 4.0),
                    pw.Text(
                      'Customer Signature',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
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
                      height: 2.0,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 4.0),
                    pw.Text(
                      'Authorized Signature',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                    )
                  ]),
                ),
              ]),
            ),
            pw.Container(
              width: double.infinity,
              color: PdfColors.black,
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Center(child: pw.Text('Powered By Pos Saas', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
            ),
          ]);
        },
        build: (pw.Context context) => <pw.Widget>[
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                child: pw.Column(children: [
                  pw.Table.fromTextArray(
                      context: context,
                      border: const pw.TableBorder(
                          left: pw.BorderSide(
                            color: PdfColors.black,
                          ),
                          right: pw.BorderSide(
                            color: PdfColors.black,
                          ),
                          bottom: pw.BorderSide(
                            color: PdfColors.black,
                          )),
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#007AD0'),
                      ),
                      columnWidths: <int, pw.TableColumnWidth>{
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(6),
                        2: const pw.FlexColumnWidth(2),
                        3: const pw.FlexColumnWidth(2),
                        4: const pw.FlexColumnWidth(2),
                      },
                      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      headerAlignments: <int, pw.Alignment>{
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.center,
                        3: pw.Alignment.centerRight,
                        4: pw.Alignment.centerRight,
                      },
                      cellAlignments: <int, pw.Alignment>{
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.center,
                        3: pw.Alignment.centerRight,
                        4: pw.Alignment.centerRight,
                      },
                      data: <List<String>>[
                        <String>['SL', 'Item', 'Quantity', 'Unit Price', 'Total Price'],
                        for (int i = 0; i < transactions.productList!.length; i++) <String>[('${i + 1}'), (transactions.productList!.elementAt(i).productName), (transactions.productList!.elementAt(i).productStock), (transactions.productList!.elementAt(i).productSalePrice), ((transactions.productList!.elementAt(i).productSalePrice.toInt() * transactions.productList!.elementAt(i).productStock.toInt()).toString())],
                      ]),
                  pw.Paragraph(text: ""),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(
                          "Payment Method: ${transactions.paymentType}",
                          style: const pw.TextStyle(
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 10.0),
                        pw.Text(
                          "Amount in Word",
                          style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 10.0),
                        pw.Text(
                          NumberToCharacterConverter('en').convertDouble(transactions.totalAmount).toUpperCase(),
                          style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                        ),
                      ]),
                      pw.SizedBox(
                        width: 150.0,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  "Vat:",
                                  style: const pw.TextStyle(
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                '0.00',
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 10.0),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  "Tax:",
                                  style: const pw.TextStyle(
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                '0.00',
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 10.0),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  "Due:",
                                  style: const pw.TextStyle(
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                transactions.dueAmount.toString(),
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 10.0),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  "Discount:",
                                  style: const pw.TextStyle(
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                transactions.discountAmount.toString(),
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 10.0),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.SizedBox(
                                width: 100.0,
                                child: pw.Text(
                                  "Subtotal:",
                                  style: const pw.TextStyle(
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                "${transactions.totalAmount! + transactions.discountAmount!}",
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                ),
                              ),
                            ]),
                            pw.SizedBox(height: 10.0),
                            pw.Container(
                              color: PdfColor.fromHex('#007AD0'),
                              width: 150.0,
                              padding: const pw.EdgeInsets.all(10.0),
                              child: pw.Text("Total Amount: ${transactions.totalAmount}", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.SizedBox(height: 10.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(10)),
                ]),
              ),
            ]));
    // doc.addPage(pw.MultiPage(
    //     pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
    //     margin: pw.EdgeInsets.zero,
    //     crossAxisAlignment: pw.CrossAxisAlignment.start,
    //     header: (pw.Context context) {
    //       return pw.Padding(
    //         padding: const pw.EdgeInsets.all(20.0),
    //         child: pw.Column(
    //           children: [
    //             pw.Row(children: [
    //               pw.Container(
    //                 height: 50.0,
    //                 width: 50.0,
    //                 alignment: pw.Alignment.centerRight,
    //                 margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
    //                 padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
    //                 decoration: pw.BoxDecoration(image: pw.DecorationImage(image: netImage), shape: pw.BoxShape.circle),
    //               ),
    //               pw.SizedBox(width: 10.0),
    //               pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    //                 pw.Text(
    //                   personalInformation.companyName!,
    //                   style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 25.0, fontWeight: pw.FontWeight.bold),
    //                 ),
    //                 pw.Text(
    //                   'House/Road/Building No, City, Area, State, Country - Zip',
    //                   style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                 ),
    //                 pw.Text(
    //                   'Tel: ${personalInformation.phoneNumber!}',
    //                   style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.red),
    //                 ),
    //               ]),
    //             ]),
    //             pw.SizedBox(height: 30.0),
    //             pw.Text('Invoice/Bill', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 25.0)),
    //             pw.SizedBox(height: 30.0),
    //             pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
    //               pw.Column(children: [
    //                 pw.Row(children: [
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Sells By',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 10.0,
    //                     child: pw.Text(
    //                       ':',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Admin',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                 ]),
    //                 pw.Row(children: [
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Bill To',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 10.0,
    //                     child: pw.Text(
    //                       ':',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       transactions.customerName,
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                 ]),
    //                 pw.Row(children: [
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Phone',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 10.0,
    //                     child: pw.Text(
    //                       ':',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       transactions.customerPhone,
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                 ]),
    //               ]),
    //               pw.Column(children: [
    //                 pw.Row(children: [
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Invoice Number',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 10.0,
    //                     child: pw.Text(
    //                       ':',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       '#${transactions.invoiceNumber}',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                 ]),
    //                 pw.Row(children: [
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Date',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 10.0,
    //                     child: pw.Text(
    //                       ':',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       DateTimeFormat.format(DateTime.parse(transactions.purchaseDate), format: 'D, M j'),
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                 ]),
    //                 pw.Row(children: [
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       'Time',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 10.0,
    //                     child: pw.Text(
    //                       ':',
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                   pw.SizedBox(
    //                     width: 100.0,
    //                     child: pw.Text(
    //                       DateTimeFormat.format(DateTime.parse(transactions.purchaseDate), format: 'H:i'),
    //                       style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                     ),
    //                   ),
    //                 ]),
    //               ]),
    //             ]),
    //           ],
    //         ),
    //       );
    //     },
    //     footer: (pw.Context context) {
    //       return pw.Column(children: [
    //         pw.Padding(
    //           padding: pw.EdgeInsets.all(10.0),
    //           child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
    //             pw.Container(
    //               alignment: pw.Alignment.centerRight,
    //               margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
    //               padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
    //               child: pw.Column(children: [
    //                 pw.Container(
    //                   width: 120.0,
    //                   height: 2.0,
    //                   color: PdfColors.black,
    //                 ),
    //                 pw.SizedBox(height: 4.0),
    //                 pw.Text(
    //                   'Customer Signature',
    //                   style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                 )
    //               ]),
    //             ),
    //             pw.Container(
    //               alignment: pw.Alignment.centerRight,
    //               margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
    //               padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
    //               child: pw.Column(children: [
    //                 pw.Container(
    //                   width: 120.0,
    //                   height: 2.0,
    //                   color: PdfColors.black,
    //                 ),
    //                 pw.SizedBox(height: 4.0),
    //                 pw.Text(
    //                   'Authorized Signature',
    //                   style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
    //                 )
    //               ]),
    //             ),
    //           ]),
    //         ),
    //         pw.Container(
    //           width: double.infinity,
    //           color: PdfColors.red,
    //           padding: const pw.EdgeInsets.all(10.0),
    //           child: pw.Center(child: pw.Text('Powered By Pos Saas', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
    //         ),
    //       ]);
    //     },
    //     build: (pw.Context context) => <pw.Widget>[
    //           pw.Padding(
    //             padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
    //             child: pw.Column(children: [
    //               pw.Table.fromTextArray(
    //                   context: context,
    //                   border: pw.TableBorder.all(color: PdfColors.black),
    //                   headerDecoration: pw.BoxDecoration(color: PdfColors.red, border: pw.Border.all(color: PdfColors.red)),
    //                   columnWidths: <int, pw.TableColumnWidth>{
    //                     0: const pw.FlexColumnWidth(1),
    //                     1: const pw.FlexColumnWidth(6),
    //                     2: const pw.FlexColumnWidth(2),
    //                     3: const pw.FlexColumnWidth(2),
    //                     4: const pw.FlexColumnWidth(2),
    //                   },
    //                   headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
    //                   rowDecoration: const pw.BoxDecoration(
    //                       border:
    //                           pw.Border(bottom: pw.BorderSide(color: PdfColors.black), left: pw.BorderSide(color: PdfColors.black), right: pw.BorderSide(color: PdfColors.black))),
    //                   headerAlignments: <int, pw.Alignment>{
    //                     0: pw.Alignment.center,
    //                     1: pw.Alignment.centerLeft,
    //                     2: pw.Alignment.center,
    //                     3: pw.Alignment.centerRight,
    //                     4: pw.Alignment.centerRight,
    //                   },
    //                   cellAlignments: <int, pw.Alignment>{
    //                     0: pw.Alignment.center,
    //                     1: pw.Alignment.centerLeft,
    //                     2: pw.Alignment.center,
    //                     3: pw.Alignment.centerRight,
    //                     4: pw.Alignment.centerRight,
    //                   },
    //                   data: <List<String>>[
    //                     <String>['SL', 'Item', 'Quantity', 'Unit Price', 'Total Price'],
    //                     for (int i = 0; i < transactions.productList!.length; i++)
    //                       <String>[
    //                         ('${i + 1}'),
    //                         (transactions.productList!.elementAt(i).productName),
    //                         (transactions.productList!.elementAt(i).productStock),
    //                         (transactions.productList!.elementAt(i).productSalePrice),
    //                         ((transactions.productList!.elementAt(i).productSalePrice.toInt() * transactions.productList!.elementAt(i).productStock.toInt()).toString())
    //                       ],
    //                   ]),
    //               pw.Paragraph(text: ""),
    //               pw.Paragraph(text: "Subtotal: ${transactions.totalAmount}"),
    //               pw.Padding(padding: const pw.EdgeInsets.all(10)),
    //             ]),
    //           ),
    //         ]));
  }
}
