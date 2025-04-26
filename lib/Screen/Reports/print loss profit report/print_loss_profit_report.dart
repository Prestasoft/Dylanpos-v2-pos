import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../commas.dart';
import '../../../const.dart';
import '../../../model/general_setting_model.dart';
import '../../../model/personal_information_model.dart';
import '../../../model/sale_transaction_model.dart';
import '../../Inventory Sales/inventory_sales.dart';
import '../../POS Sale/pos_sale.dart';

class DownloadLossProfitReport {
  Future<void> printLossProfitReport({required PersonalInformationModel personalInformationModel, required List<SaleTransactionModel> saleTransactionModel, required String fromDate, required String toDate, required String saleAmount, required String profit, required String loss, required GeneralSettingModel setting, BuildContext? context, bool? fromInventorySale}) async {
    final Uint8List pdf = await downloadLossProfitReport(
      personalInformation: personalInformationModel,
      transactions: saleTransactionModel,
      fromDate: fromDate,
      toDate: toDate,
      saleAmount: saleAmount,
      profit: profit,
      loss: loss,
      generalSetting: setting,
    );
    //
    // await Printing.layoutPdf(
    //   dynamicLayout: true,
    //   onLayout: (PdfPageFormat format) async => await generateLossProfitReport(
    //       personalInformation: personalInformationModel,
    //       transactions: saleTransactionModel ?? [],
    //       fromDate: fromDate,
    //       toDate: toDate,
    //       saleAmount: saleAmount,
    //       profit: profit,
    //       loss: loss),
    // );

    Future.delayed(const Duration(milliseconds: 200), () {
      ((fromInventorySale ?? false) && context != null) ? const InventorySales().launch(context, isNewTask: true) : const PosSale().launch(context!, isNewTask: true);
    });
  }
}

///___________Pdf_Format____________________________________________________________________________________________________________________________
FutureOr<Uint8List> downloadLossProfitReport({
  required List<SaleTransactionModel> transactions,
  required PersonalInformationModel personalInformation,
  required String fromDate,
  required String toDate,
  required String saleAmount,
  required String profit,
  required String loss,
  required GeneralSettingModel generalSetting,
}) async {
  final pw.Document doc = pw.Document();
  double totalAmount({required SaleTransactionModel transactions}) {
    double amount = 0;

    for (var element in transactions.productList!) {
      amount = amount + double.parse(element.subTotal) * double.parse(element.quantity.toString());
    }

    return double.parse(amount.toStringAsFixed(2));
  }

  doc.addPage(
    pw.MultiPage(
      // pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
      margin: const pw.EdgeInsets.all(14.0),
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      header: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ///________Company_Name_________________________________________________________
            pw.Center(
              child: pw.Text(
                personalInformation.companyName,
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 25.0, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Address: ${personalInformation.companyName}, Ph.no:${personalInformation.phoneNumber}',
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 11.0),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Container(
                  padding: pw.EdgeInsets.only(bottom: 2.0),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black))),
                  child: pw.Text(
                    'Loss/Profit Report',
                    style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 16.0, fontWeight: pw.FontWeight.bold),
                  )),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
                child: pw.Text(
              'Duration: From ${DateFormat.yMd().format(DateTime.parse(fromDate))} to ${DateFormat.yMd().format(DateTime.parse(toDate))}',
              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 11.0),
            ))
          ],
        );
      },
      footer: (pw.Context context) {
        return pw.Column(children: [
          pw.Divider(color: PdfColors.grey600),
          pw.Center(child: pw.Text('Powered By ${generalSetting.companyName.isNotEmpty == true ? generalSetting.companyName : appsName}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black))),
        ]);
      },
      build: (pw.Context context) => <pw.Widget>[
        pw.Column(
          children: [
            pw.SizedBox(height: 20),

            ///___________Table__________________________________________________________
            pw.Table.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
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
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(5.0),
                4: const pw.FlexColumnWidth(2.0),
                5: const pw.FlexColumnWidth(1.7),
                6: const pw.FlexColumnWidth(1.7),
              },
              headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              // oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              headerAlignments: <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              cellAlignments: <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              data: <List<String>>[
                <String>['SL', 'Date', 'Invoice', 'Party Name', 'Sale Amount', 'Profit', 'Loss'],
                for (int i = 0; i < transactions.length; i++)
                  <String>[
                    ('${i + 1}'),
                    (DateFormat.yMd().format(DateTime.parse(transactions.elementAt(i).purchaseDate))),
                    (transactions.elementAt(i).invoiceNumber),
                    (transactions.elementAt(i).customerName),
                    (myFormat.format(double.tryParse(transactions.elementAt(i).totalAmount.toString()) ?? 0)),
                    (myFormat.format(double.tryParse(transactions.elementAt(i).lossProfit!.isNegative ? ' 0' : transactions.elementAt(i).lossProfit!.toStringAsFixed(2)) ?? 0)),
                    (myFormat.format(double.tryParse(transactions.elementAt(i).lossProfit!.isNegative ? transactions.elementAt(i).lossProfit!.toStringAsFixed(2) : ' 0') ?? 0)),
                  ],
                <String>['', '', '', 'Sub Total:', '${saleAmount.toString()}', '${profit.toString()}', '${loss.toString()}'],
              ],
            ),
          ],
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  final anchor = AnchorElement(
    href: Uri.dataFromBytes(bytes).toString(),
    // Set desired filename
  );
  anchor.click();
  return doc.save();
}

class GenerateLossProfitReport {
  Future<void> printLossProfitReport({required PersonalInformationModel personalInformationModel, required List<SaleTransactionModel> saleTransactionModel, required String fromDate, required String toDate, required String saleAmount, required String profit, required String loss, BuildContext? context, required GeneralSettingModel setting, bool? fromInventorySale}) async {
    final Uint8List pdf = await generateLossProfitReport(
      personalInformation: personalInformationModel,
      transactions: saleTransactionModel,
      fromDate: fromDate,
      toDate: toDate,
      saleAmount: saleAmount,
      profit: profit,
      loss: loss,
      generalSetting: setting,
    );

    await Printing.layoutPdf(
      dynamicLayout: true,
      onLayout: (PdfPageFormat format) async => await generateLossProfitReport(generalSetting: setting, personalInformation: personalInformationModel, transactions: saleTransactionModel ?? [], fromDate: fromDate, toDate: toDate, saleAmount: saleAmount, profit: profit, loss: loss),
    );
  }
}

///___________Pdf_Format____________________________________________________________________________________________________________________________
FutureOr<Uint8List> generateLossProfitReport({
  required List<SaleTransactionModel> transactions,
  required PersonalInformationModel personalInformation,
  required String fromDate,
  required String toDate,
  required String saleAmount,
  required String profit,
  required String loss,
  required GeneralSettingModel generalSetting,
}) async {
  final pw.Document doc = pw.Document();
  double totalAmount({required SaleTransactionModel transactions}) {
    double amount = 0;

    for (var element in transactions.productList!) {
      amount = amount + double.parse(element.subTotal) * double.parse(element.quantity.toString());
    }

    return double.parse(amount.toStringAsFixed(2));
  }

  doc.addPage(
    pw.MultiPage(
      // pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
      margin: const pw.EdgeInsets.all(14.0),
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      header: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ///________Company_Name_________________________________________________________
            pw.Center(
              child: pw.Text(
                personalInformation.companyName,
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 25.0, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Address: ${personalInformation.companyName}, Ph.no:${personalInformation.phoneNumber}',
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 11.0),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Container(
                  padding: pw.EdgeInsets.only(bottom: 2.0),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black))),
                  child: pw.Text(
                    'Loss/Profit Report',
                    style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 16.0, fontWeight: pw.FontWeight.bold),
                  )),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
                child: pw.Text(
              'Duration: From ${DateFormat.yMd().format(DateTime.parse(fromDate))} to ${DateFormat.yMd().format(DateTime.parse(toDate))}',
              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 11.0),
            ))
          ],
        );
      },
      footer: (pw.Context context) {
        return pw.Column(children: [
          pw.Divider(color: PdfColors.grey600),
          pw.Center(child: pw.Text('Powered By ${generalSetting.companyName.isNotEmpty == true ? generalSetting.companyName : appsName}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black))),
        ]);
      },
      build: (pw.Context context) => <pw.Widget>[
        pw.Column(
          children: [
            pw.SizedBox(height: 20),

            ///___________Table__________________________________________________________
            pw.Table.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
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
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(5.0),
                4: const pw.FlexColumnWidth(2.0),
                5: const pw.FlexColumnWidth(1.7),
                6: const pw.FlexColumnWidth(1.7),
              },
              headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              // oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              headerAlignments: <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              cellAlignments: <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              data: <List<String>>[
                <String>['SL', 'Date', 'Invoice', 'Party Name', 'Sale Amount', 'Profit', 'Loss'],
                for (int i = 0; i < transactions.length; i++)
                  <String>[
                    ('${i + 1}'),
                    (DateFormat.yMd().format(DateTime.parse(transactions.elementAt(i).purchaseDate))),
                    (transactions.elementAt(i).invoiceNumber),
                    (transactions.elementAt(i).customerName),
                    (myFormat.format(double.tryParse(transactions.elementAt(i).totalAmount.toString()) ?? 0)),
                    (myFormat.format(double.tryParse(transactions.elementAt(i).lossProfit!.isNegative ? ' 0' : transactions.elementAt(i).lossProfit!.toStringAsFixed(2)) ?? 0)),
                    (myFormat.format(double.tryParse(transactions.elementAt(i).lossProfit!.isNegative ? transactions.elementAt(i).lossProfit!.toStringAsFixed(2) : ' 0') ?? 0)),
                  ],
                <String>['', '', '', 'Sub Total:', '${saleAmount.toString()}', '${profit.toString()}', '${loss.toString()}'],
              ],
            ),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
