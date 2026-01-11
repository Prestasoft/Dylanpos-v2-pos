import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cross_file/cross_file.dart';

import '../../services/api_service.dart';

// Función para ver el PDF de la factura
Future<void> verPdfFactura(BuildContext context, SaleTransactionModel factura) async {
  EasyLoading.show(status: 'Generando visualización de PDF...');

  try {
    final apiService = ApiService();

    // Obtener información personal de la empresa
    final responsePersonal = await apiService.get('personal-information');

    // Obtener configuración general
    final responseGeneral = await apiService.get('general-settings');

    if (responsePersonal.success && responseGeneral.success &&
        responsePersonal.data != null && responseGeneral.data != null) {
      final personalInfo = PersonalInformationModel.fromJson(
          Map<String, dynamic>.from(responsePersonal.data));

      final generalSetting = GeneralSettingModel.fromJson(
          Map<String, dynamic>.from(responseGeneral.data));
      
      try {
        final pdfGenerator = GeneratePdfAndPrint();
        
        // Generar el PDF y obtener los datos sin imprimir
        final pdfData = await pdfGenerator.printSaleInvoice(
          personalInformationModel: personalInfo,
          saleTransactionModel: factura,
          context: context,
          fromInventorySale: false,
          printType: 'normal', // Siempre usar formato normal para visualización
          post: factura,
          setting: generalSetting,
          returnPdfData: true, // Solo devolver los datos sin imprimir
          skipPrinting: true // Evitar mostrar el diálogo de impresión
        );
        
        if (pdfData != null) {
          EasyLoading.dismiss();
          
          // Guardar temporalmente el PDF para visualizarlo
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/factura_${factura.invoiceNumber}.pdf');
          await file.writeAsBytes(pdfData);
          
          // Mostrar el PDF en un visualizador
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Factura #${factura.invoiceNumber}'),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.print),
                      onPressed: () {
                        // Imprimir desde el visualizador
                        Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfData,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () async {
                        // Compartir el archivo PDF
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Factura #${factura.invoiceNumber}',
                        );
                      },
                    ),
                  ],
                ),
                body: SfPdfViewer.file(
                  file,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableDoubleTapZooming: true,
                ),
              ),
            ),
          );
        } else {
          EasyLoading.showError('No se pudo generar la visualización del PDF');
        }
      } catch (e) {
        print('Error en la generación del PDF para visualización: $e');
        final errorMsg = e.toString();
        final shortErrorMsg = errorMsg.length > 50 ? errorMsg.substring(0, 50) + '...' : errorMsg;
        EasyLoading.showError('Error al generar el PDF: $shortErrorMsg');
      }
    } else {
      EasyLoading.showError('No se pudo obtener la información necesaria para la visualización');
    }
  } catch (e) {
    print('Error al preparar la visualización del PDF: $e');
    final errorMsg = e.toString();
    final shortErrorMsg = errorMsg.length > 50 ? errorMsg.substring(0, 50) + '...' : errorMsg;
    EasyLoading.showError('Error al preparar la visualización: $shortErrorMsg');
  }
}
