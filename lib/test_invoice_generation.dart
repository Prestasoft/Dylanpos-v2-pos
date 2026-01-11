import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';
import 'package:salespro_admin/model/photo_invoice_model.dart';
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:salespro_admin/PDF/photo_invoice_pdf_pro.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class TestInvoiceGeneration extends ConsumerStatefulWidget {
  const TestInvoiceGeneration({super.key});

  @override
  ConsumerState<TestInvoiceGeneration> createState() => _TestInvoiceGenerationState();
}

class _TestInvoiceGenerationState extends ConsumerState<TestInvoiceGeneration> {
  String statusMessage = 'Presiona el botón para probar la generación de factura';
  
  Future<void> testInvoiceGeneration() async {
    setState(() {
      statusMessage = 'Iniciando prueba...';
    });
    
    try {
      // Crear datos de prueba
      setState(() {
        statusMessage = 'Creando customer de prueba...';
      });
      
      final testCustomer = CustomerModel(
        customerName: 'Cliente de Prueba',
        phoneNumber: '8091234567',
        type: 'Retailer',
        profilePicture: 'https://via.placeholder.com/150',
        emailAddress: 'test@example.com',
        customerAddress: 'Santo Domingo, RD',
        dueAmount: '0',
        openingBalance: '0',
        remainedBalance: '0',
        gst: '',
      );
      
      setState(() {
        statusMessage = 'Creando productos de prueba...';
      });
      
      final testProducts = [
        FrameProductModel(
          productId: 'test001',
          productName: 'Marco de Prueba',
          productType: 'marco',
          productPrice: 100.0,
          quantity: 2,
          size: '8x10',
          material: 'madera',
          color: 'Negro',
          discount: 0,
        ),
      ];
      
      setState(() {
        statusMessage = 'Creando servicios de prueba...';
      });
      
      final testServices = [
        PhotoServiceModel(
          serviceId: 'service001',
          serviceName: 'Impresión de Prueba',
          serviceType: 'impresion',
          servicePrice: 50.0,
          quantity: 3,
          size: '4x6',
          description: 'Servicio de prueba',
          discount: 0,
        ),
      ];
      
      setState(() {
        statusMessage = 'Creando PersonalInformation...';
      });
      
      // Crear PersonalInformation de prueba
      final personalInfo = PersonalInformationModel(
        phoneNumber: '8091234567',
        companyName: 'Empresa de Prueba',
        pictureUrl: 'https://via.placeholder.com/150',
        businessCategory: 'Photography',
        language: 'es',
        countryName: 'Dominican Republic',
        saleInvoiceCounter: 1,
        purchaseInvoiceCounter: 1,
        dueInvoiceCounter: 1,
        shopOpeningBalance: 0,
        remainingShopBalance: 0,
        currency: '\$',
        currentLocale: 'es_DO',
        gst: '123456789',
      );
      
      setState(() {
        statusMessage = 'Creando GeneralSetting...';
      });
      
      // Crear GeneralSetting de prueba
      final generalSetting = GeneralSettingModel(
        title: 'Sistema de Prueba',
        companyName: 'Empresa de Prueba SRL',
        mainLogo: '',
        commonHeaderLogo: '',
        sidebarLogo: '',
      );
      
      setState(() {
        statusMessage = 'Creando invoice modelo...';
      });
      
      // Crear invoice de prueba
      final testInvoice = PhotoInvoiceModel(
        invoiceNumber: 'TEST-001',
        invoiceDate: DateTime.now(),
        customer: testCustomer,
        products: testProducts,
        services: testServices,
        discountAmount: 10.0,
        taxRate: 18.0,
        taxAmount: 60.3,
        notes: 'Esta es una factura de prueba',
        paymentMethod: 'Efectivo',
        selectedBank: null,
        paymentStatus: 'Paid',
        paidAmount: 395.0,
        dueAmount: 0,
      );
      
      setState(() {
        statusMessage = 'Generando PDF...';
      });
      
      // Intentar generar el PDF
      final Uint8List pdfData = await generatePhotoInvoiceDocumentPro(
        invoice: testInvoice,
        personalInformation: personalInfo,
        generalSetting: generalSetting,
      );
      
      setState(() {
        statusMessage = 'PDF generado! Tamaño: ${pdfData.length} bytes. Abriendo vista previa...';
      });
      
      // Mostrar el PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'Test_Invoice',
      );
      
      setState(() {
        statusMessage = '✅ ÉXITO: La factura se generó correctamente!';
      });
      
    } catch (e, stackTrace) {
      setState(() {
        statusMessage = '❌ ERROR: $e\n\nStack trace:\n$stackTrace';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Generación de Factura'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: statusMessage.contains('ERROR') ? Colors.red : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: testInvoiceGeneration,
                child: const Text('Probar Generación de Factura'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}