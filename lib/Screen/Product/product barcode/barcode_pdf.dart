//____________________________________________
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../currency.dart';
import '../../../model/add_to_cart_model.dart';
import '../../../model/personal_information_model.dart';

Future<void> generateBarcodeFunc({
  required List<AddToCartModel> carts,
  required PersonalInformationModel personalInformationModel,
  BuildContext? context,
  required site,
  required name,
  required code,
  required price,
}) async {
  await Printing.layoutPdf(
    dynamicLayout: true,
    onLayout: (PdfPageFormat format) async => await generateBarCode(products: carts, personalInformation: personalInformationModel, site: site, name: name, code: code, price: price),
  );
}

FutureOr<Uint8List> generateBarCode({required List<AddToCartModel> products, required PersonalInformationModel personalInformation, required bool site, required bool name, required bool code, required bool price}) async {
  final pw.Document doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10.0),
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      build: (pw.Context context) => <pw.Widget>[
        for (final product in products)
          pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.start,
            alignment: pw.WrapAlignment.start,
            spacing: 20,
            runSpacing: 10,
            children: List.generate(
              product.quantity.round(),
              (index) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10.0),
                child: pw.Container(
                    padding: const pw.EdgeInsets.all(5.0),
                    decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(6.0), border: pw.Border.all(color: PdfColors.grey)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        site
                            ? pw.Text(
                                personalInformation.companyName,
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontWeight: pw.FontWeight.normal, fontSize: 10),
                              )
                            : pw.Text(''),
                        name
                            ? pw.Text(
                                product.productName.toString(),
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontWeight: pw.FontWeight.normal, fontSize: 8),
                              )
                            : pw.Text(''),
                        price
                            ? pw.Text(
                                '$currency.${product.productPurchasePrice}',
                                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
                              )
                            : pw.Text(''),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: product.productId,
                          drawText: code ? true : false,
                          color: PdfColors.black,
                          width: 100,
                          height: 30,
                        ),
                      ],
                    )),
              ),
            ),
          ),
      ],
    ),
  );

  return doc.save();
}
