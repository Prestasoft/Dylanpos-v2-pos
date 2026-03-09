import 'dart:async';
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
import 'package:salespro_admin/Provider/branch_settings_provider.dart';
import 'package:salespro_admin/model/FullReservation.dart';
import '../const.dart';
import '../model/general_setting_model.dart';
import '../model/personal_information_model.dart';
import '../model/sale_transaction_model.dart';
import '../model/branch_settings_model.dart';
import 'package:salespro_admin/services/api/victorpos_api_service.dart';

///___________Sales_PDF_Formats____________________________________________________________________________________________________________________________
FutureOr<Uint8List> generateSaleDocument({
  required SaleTransactionModel transactions,
  required PersonalInformationModel personalInformation,
  required GeneralSettingModel generalSetting,
  SaleTransactionModel? post,
  required BuildContext context,
}) async {
  debugPrint('🔵 [generateSaleDocument] INICIO - Invoice: ${transactions.invoiceNumber}');
  debugPrint('🔵 [generateSaleDocument] purchaseDate: "${transactions.purchaseDate}"');
  debugPrint('🔵 [generateSaleDocument] productList null: ${transactions.productList == null}');
  debugPrint('🔵 [generateSaleDocument] productList length: ${transactions.productList?.length ?? 0}');
  debugPrint('🔵 [generateSaleDocument] reservationIds: ${transactions.reservationIds}');

  debugPrint('🔵 [generateSaleDocument] Cargando imagen logo...');
  final imageData = await rootBundle.load('images/vg_logo.png');
  final imageBytes = imageData.buffer.asUint8List();
  final image = pw.MemoryImage(imageBytes);

  final pw.Document doc = pw.Document();
  final ref = ProviderScope.containerOf(context);
  final List<String> idReservaciones = post?.reservationIds ?? [];

  // Obtener historial de pagos (Estado de Cuenta)
  List<Map<String, dynamic>> finalDueTransactions = [];
  try {
    final allDueTransactions = await VictorPosApiService().getDueTransactions();
    finalDueTransactions = allDueTransactions
        .where((element) => element['invoice_number'] == transactions.invoiceNumber)
        .toList();
    // Ordenar por fecha
    finalDueTransactions.sort((a, b) => (a['transaction_date'] ?? '').compareTo(b['transaction_date'] ?? ''));
  } catch (e) {
    debugPrint('Error obteniendo historial de pagos: $e');
  }

  // Inyectar el Pago Inicial como el primer registro del historial si hubo un pago
  final double totalAmt = transactions.totalAmount ?? 0.0;
  final double dueAmt = transactions.dueAmount ?? 0.0;
  final double initialPaymentAmount = totalAmt - dueAmt;

  debugPrint('🟡 [EstadoDeCuenta] invoiceNumber: ${transactions.invoiceNumber}');
  debugPrint('🟡 [EstadoDeCuenta] totalAmount raw: ${transactions.totalAmount} -> totalAmt: $totalAmt');
  debugPrint('🟡 [EstadoDeCuenta] dueAmount raw: ${transactions.dueAmount} -> dueAmt: $dueAmt');
  debugPrint('🟡 [EstadoDeCuenta] initialPaymentAmount: $initialPaymentAmount');
  debugPrint('🟡 [EstadoDeCuenta] finalDueTransactions (API) count: ${finalDueTransactions.length}');

  if (initialPaymentAmount > 0) {
    finalDueTransactions.insert(0, {
      'id': 'INI', // Pseudo-ID para el pago inicial
      'transaction_date': transactions.purchaseDate,
      'payment_type': transactions.paymentType ?? 'Sin especificar',
      'paid_amount': initialPaymentAmount,
    });
    debugPrint('🟢 [EstadoDeCuenta] Pago inicial inyectado: $initialPaymentAmount');
  } else {
    debugPrint('🔴 [EstadoDeCuenta] NO se inyectó pago inicial (initialPaymentAmount <= 0)');
  }

  debugPrint('🟡 [EstadoDeCuenta] finalDueTransactions FINAL count: ${finalDueTransactions.length}');

  // Obtener configuración de sucursal para el encabezado
  BranchSettingsModel? branchSettings;
  try {
    branchSettings = await ref.read(branchSettingsProvider.future).timeout(
      const Duration(seconds: 3),
      onTimeout: () => BranchSettingsModel.defaultSettings(''),
    );
  } catch (e) {
    branchSettings = BranchSettingsModel.defaultSettings('');
  }
  
  // Actualizar los productos de forma asíncrona sin bloquear
  if (idReservaciones.isNotEmpty) {
    // Ejecutar la actualización sin esperar el resultado
    Future(() async {
      try {
        await ref.read(ActualizarEstadoReservaProvider({
          'id': idReservaciones,
          'estado': 'confirmado',
          // estado_factura = true indica que la reserva YA tiene factura creada
          // El estado de pago se maneja por separado en la tabla de ventas (isPaid, dueAmount)
          'estado_factura': true,
        }).future);
      } catch (error) {
        print('Error actualizando estado de reserva: $error');
      }
    });
  }

  // Primero, obtener el primer ID de reservación (si existe)
  final firstReservationId = idReservaciones.isNotEmpty ? idReservaciones.first : null;

  // Obtener la reservación completa usando el primer ID con timeout
  FullReservation? fullReservation;
  try {
    fullReservation = firstReservationId != null 
        ? await ref.read(fullReservationByIdProviderVQ(firstReservationId).future).timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          )
        : null;
  } catch (e) {
    print('Error obteniendo reservación: $e');
    fullReservation = null;
  }

// Extraer el nombre del vendedor de la reservación
final reservationSellerName = fullReservation?.reservation['seller_name']?.toString() ?? 'No especificado';
  // Obtener la lista de IDs de reservaciones
  // Obtener todas las reservaciones con timeout
  List<FullReservation?> reservaciones = [];
  debugPrint('🔵 [generateSaleDocument] Iniciando carga de ${idReservaciones.length} reservaciones...');
  try {
    reservaciones = await Future.wait(
      idReservaciones.map((id) {
        debugPrint('🔵 [generateSaleDocument] Cargando reservación: $id');
        return ref.read(fullReservationByIdProviderVQ(id).future)
          .timeout(const Duration(seconds: 3), onTimeout: () {
            debugPrint('⚠️ [generateSaleDocument] TIMEOUT cargando reservación: $id');
            return null;
          })
          .catchError((e) {
            debugPrint('❌ [generateSaleDocument] ERROR cargando reservación $id: $e');
            return null;
          });
      })
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [generateSaleDocument] TIMEOUT GLOBAL cargando reservaciones');
        return <FullReservation?>[];
      },
    );
    debugPrint('🔵 [generateSaleDocument] Reservaciones cargadas: ${reservaciones.length}');
  } catch (e) {
    debugPrint('❌ [generateSaleDocument] ERROR obteniendo reservaciones: $e');
    reservaciones = [];
  }
  
  // Separar reservaciones por tipo
  FullReservation? preQuinceFiestaReservation;
  FullReservation? normalReservation;

  for (final reservacion in reservaciones) {
    if (reservacion != null) {
      final sessionType = reservacion.reservation['session_type']?.toString();
      if (sessionType == 'pre-quince-fiesta') {
        preQuinceFiestaReservation = reservacion;
      } else if (sessionType == null || sessionType == 'normal') {
        normalReservation ??= reservacion; // Solo tomar la primera si no hay ninguna asignada
      }
    }
  }

  // Validar que productList no sea null para evitar errores
  final productListSafe = transactions.productList ?? [];
  debugPrint('🔵 [generateSaleDocument] productListSafe length: ${productListSafe.length}');

  double totalAmount({required SaleTransactionModel transactions}) {
    double amount = 0;
    final products = transactions.productList ?? [];

    for (var element in products) {
      // Convertir subTotal de forma segura (puede ser String, num o null)
      final subTotalValue = double.tryParse(element.subTotal?.toString() ?? '0') ?? 0.0;
      final quantityValue = double.tryParse(element.quantity.toString()) ?? 1.0;
      amount = amount + subTotalValue * quantityValue;
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

  debugPrint('🔵 [generateSaleDocument] Iterando productos para rows...');
  for (int i = 0; i < productListSafe.length; i++) {
    final item = productListSafe[i];
    debugPrint('🔵 [generateSaleDocument] Procesando item $i: ${item.productName}');
    
    // Convertir valores de forma segura
    final subTotalValue = double.tryParse(item.subTotal?.toString() ?? '0') ?? 0.0;
    final quantityValue = item.quantity.toInt();
    final totalLine = subTotalValue * quantityValue;

    // Usar la descripción del item directamente para adicionales
    if (item.isAdditional == true) {
      rows.add(<String>[
        '${i + 1}',
        '''${item.productName}\n${item.descricpion ?? 'Adicional de reserva'}''',
        myFormat.format(double.tryParse(item.quantity.toString()) ?? 0),
        myFormat.format(subTotalValue),
        calculateProductVat(product: item),
        myFormat.format(double.tryParse(totalLine.toStringAsFixed(2)) ?? 0),
      ]);
    }
    // Para reservas normales, usar la descripción del servicio
    else {
      // Intentar obtener la reservación de las ya cargadas
      final fullReservation = reservaciones.firstWhere(
        (r) => r?.reservation['id'] == item.productId,
        orElse: () => null,
      );
      String serviceDescription = fullReservation?.service?['description'] ?? item.descricpion ?? '';
      
      // Ajuste de descripción: eliminar múltiples saltos de línea consecutivos para ahorrar espacio vertical
      // y mantener el diseño compacto.
      if (serviceDescription.isNotEmpty) {
        // Reemplazar 2 o más saltos de línea por uno solo
        serviceDescription = serviceDescription.replaceAll(RegExp(r'\n\s*\n'), '\n').trim();
        
        // Límite de seguridad muy alto (40 líneas) para evitar que el motor PDF se cuelgue 
        // si la fila es más alta que la página entera.
        final lines = serviceDescription.split('\n');
        if (lines.length > 40) {
          serviceDescription = '${lines.take(40).join('\n')}\n... (texto omitido por longitud)';
        }
      }

      rows.add(<String>[
        '${i + 1}',
        '''${item.productName}\n$serviceDescription''',
        myFormat.format(double.tryParse(item.quantity.toString()) ?? 0),
        myFormat.format(subTotalValue),
        calculateProductVat(product: item),
        myFormat.format(double.tryParse(totalLine.toStringAsFixed(2)) ?? 0),
      ]);
    }
  }

  debugPrint('🔵 [generateSaleDocument] Rows preparadas: ${rows.length}');
  debugPrint('🔵 [generateSaleDocument] branchSettings: ${branchSettings?.companyName ?? "NULL"}');
  debugPrint('🔵 [generateSaleDocument] Iniciando doc.addPage...');

  try {
  doc.addPage(
    pw.MultiPage(
      // pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
      margin: pw.EdgeInsets.zero,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      header: (pw.Context context) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════════════════
              // ENCABEZADO CON BANDA DE COLOR (Estilo Gubernamental/DGII)
              // ═══════════════════════════════════════════════════════════════════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white, // Fondo blanco para ahorrar tinta
                  border: pw.Border.all(color: PdfColors.black, width: 1.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // ─── Lado Izquierdo: Logo + Info Empresa ───
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(image),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              branchSettings?.companyName.isNotEmpty == true
                                  ? branchSettings!.companyName.toUpperCase()
                                  : personalInformation.companyName.toUpperCase(),
                              style: pw.TextStyle(
                                color: PdfColors.black,
                                fontSize: 14.0,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(width: 150, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 3),
                            if (branchSettings?.rnc.isNotEmpty == true || personalInformation.gst.trim().isNotEmpty)
                              pw.Text(
                                'RNC: ${branchSettings?.rnc.isNotEmpty == true ? branchSettings!.rnc : personalInformation.gst}',
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // ─── Lado Derecho: Número de Factura ───
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FACTURA',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 2),
                        ),
                        pw.Container(width: 70, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'No. ${transactions.invoiceNumber}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                        pw.Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.parse(transactions.purchaseDate)),
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ─── Línea secundaria con datos de contacto ───
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200, // Fondo gris claro para ahorrar tinta
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 1.5),
                    right: pw.BorderSide(color: PdfColors.black, width: 1.5),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (branchSettings?.address.isNotEmpty == true) ...[
                      pw.Text(branchSettings!.address, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                      pw.Text('  |  ', style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                    ],
                    pw.Text(
                      'Tel: ${branchSettings?.phone.isNotEmpty == true ? branchSettings!.phone : personalInformation.phoneNumber}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.black),
                    ),
                    if (branchSettings?.city.isNotEmpty == true) ...[
                      pw.Text('  |  ', style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                      pw.Text(branchSettings!.city, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [

              // ═══════════════════════════════════════════════════════════════════════
              // SECCIÓN COMPROBANTE FISCAL - Solo se muestra si tiene NCF válido
              // ═══════════════════════════════════════════════════════════════════════
              if (_hasValidNcf(transactions.ncfType)) ...[
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      // Encabezado con fondo de color
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 15),
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        child: pw.Text(
                          'COMPROBANTE FISCAL',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      // Contenido principal
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Column(
                          children: [
                            // Tipo de comprobante
                            pw.Row(
                              children: [
                                pw.Text('Tipo:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                pw.SizedBox(width: 10),
                                pw.Expanded(
                                  child: pw.Text(
                                    _getInvoiceTitle(transactions.ncfType),
                                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            // NCF en recuadro destacado
                            pw.Row(
                              children: [
                                pw.Text('NCF:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                pw.SizedBox(width: 10),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.black, width: 1),
                                    color: PdfColors.white,
                                  ),
                                  child: pw.Text(
                                    transactions.ncfNumber ?? '${transactions.ncfType}-Pendiente',
                                    style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (transactions.ncfExpirationDate != null) ...[
                              pw.SizedBox(height: 6),
                              pw.Row(
                                children: [
                                  pw.Text('Válido hasta:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                  pw.SizedBox(width: 10),
                                  pw.Text(
                                    _formatExpirationDate(transactions.ncfExpirationDate!),
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // ═══════════════════════════════════════════════════════════════════════
              // SECCIÓN: FACTURADO A (Cliente) - Estilo Formulario Oficial
              // ═══════════════════════════════════════════════════════════════════════
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                      ),
                      child: pw.Text(
                        'FACTURADO A:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                    // Contenido del cliente
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFormRow('Nombre/Razón Social ', transactions.customerName),
                          if (transactions.customerRnc != null && transactions.customerRnc!.isNotEmpty)
                            _buildFormRow('RNC/Cédula ', transactions.customerRnc!)
                          else if (transactions.customerGst.trim().isNotEmpty)
                            _buildFormRow('RNC/Cédula ', transactions.customerGst),
                          if (transactions.customerAddress.isNotEmpty)
                            _buildFormRow('Dirección ', transactions.customerAddress),
                          if (transactions.customerPhone.isNotEmpty)
                            _buildFormRow('Teléfono ', transactions.customerPhone),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ═══════════════════════════════════════════════════════════════════════
              // SECCIÓN: CONDICIONES + RESPONSABLES
              // ═══════════════════════════════════════════════════════════════════════
              // ─── Responsables (ancho completo) ───
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                      ),
                      child: pw.Text('RESPONSABLES', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Columna izquierda
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildInfoRowCompact('Vendedor', transactions.sellerName ?? 'Admin'),
                              _buildInfoRowCompact('Reservó', reservationSellerName),
                              _buildInfoRowCompact('Hora', DateFormat('h:mm a').format(DateTime.parse(transactions.purchaseDate))),
                            ],
                          ),
                          // Columna derecha - Fechas de reservación
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildInfoRowCompact('Tipo', _getInvoiceTitle(transactions.ncfType)),
                              _buildInfoRowCompact('Estado', transactions.isPaid! ? 'PAGADO' : 'PENDIENTE'),
                              ...() {
                                List<pw.Widget> dateWidgets = [];
                                final mainReservation = preQuinceFiestaReservation ?? normalReservation ??
                                    (reservaciones.where((r) => r != null).isNotEmpty ? reservaciones.where((r) => r != null).first : null);
                                if (mainReservation != null) {
                                  if (preQuinceFiestaReservation != null) {
                                    dateWidgets.add(_buildInfoRowCompact('Pre-Quince', _formatearFechaYHora(mainReservation.reservation['reservation_date'], mainReservation.reservation['reservation_time'])));
                                    final fiestaDate = mainReservation.reservation['fiesta_date']?.toString();
                                    final fiestaTime = mainReservation.reservation['fiesta_time']?.toString();
                                    if (fiestaDate != null && fiestaDate.isNotEmpty && fiestaTime != null && fiestaTime.isNotEmpty) {
                                      dateWidgets.add(_buildInfoRowCompact('Fiesta', _formatearFechaYHora(fiestaDate, fiestaTime)));
                                    }
                                  } else {
                                    dateWidgets.add(_buildInfoRowCompact('Cita', _formatearFechaYHora(mainReservation.reservation['reservation_date'], mainReservation.reservation['reservation_time'])));
                                  }
                                }
                                return dateWidgets;
                              }(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ─── Línea divisoria antes de productos ───
              pw.Container(
                width: double.infinity,
                height: 2,
                color: PdfColors.grey800,
              ),
                  ],
                ),
              ),
            ],
        );
      },
      footer: (pw.Context context) {
        return pw.Column(
          children: [
            // Sección de firmas
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20.0),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Firma del Cliente
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 25),
                      pw.Container(
                        width: 150.0,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4.0),
                      pw.Text(
                        'Firma del Cliente',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  // Firma Autorizada
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 25),
                      pw.Container(
                        width: 150.0,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4.0),
                      pw.Text(
                        'Firma Autorizada',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            // Línea separadora elegante
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 1,
              decoration: const pw.BoxDecoration(
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 8),
            // Pie de página con información
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20),
              child: pw.Column(
                children: [
                  pw.Text(
                    '"Capturando momentos que duran para siempre"',
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Documento generado electrónicamente - ${generalSetting.companyName.isNotEmpty == true ? generalSetting.companyName : pdfFooter}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 5),
          ],
        );
      },
      build: (pw.Context context) => <pw.Widget>[
        // ══════════════════════════════════════════════════════════════
        // WIDGET 1: Tabla de Productos (se paginará automáticamente)
        // ══════════════════════════════════════════════════════════════
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0),
          child: pw.Table.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  left: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                  top: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                  verticalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(6),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.7),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
                headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 10, fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(color: PdfColors.black, fontSize: 9),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFf5f5f5)),
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
        ),

        // ══════════════════════════════════════════════════════════════
        // WIDGET 2: Resumen Financiero (Método de Pago + Totales)
        // ══════════════════════════════════════════════════════════════
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
          child: pw.Row(
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
                    pw.Container(
                      width: 300,
                      child: pw.Text(
                        "Notas: ${notas.isEmpty ? 'Sin notas' : notas.join(', ')}",
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    // Lugar (si existe)
                    if (place != null && place != '-') ...[
                      pw.SizedBox(height: 6.0),
                      pw.Container(
                        width: 300,
                        child: pw.Text(
                          "Lugar: $place",
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
                                "Adicionales",
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

                          ///________ITBIS (18%)_______________________________________________
                          if (transactions.itbisAmount != null && transactions.itbisAmount! > 0)
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
                                  myFormat.format(transactions.itbisAmount!),
                                  style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                        color: PdfColors.black,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ]),
                          if (transactions.itbisAmount != null && transactions.itbisAmount! > 0)
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

                          ///________Pending_Amount_______________________________________________
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
        ),
        
        // ═══════════════════════════════════════════════════════════════════════
        // ESTADO DE CUENTA (solo si totalAmount > 0)
        // ═══════════════════════════════════════════════════════════════════════
        if (totalAmt > 0)
        pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: pw.Container(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header "ESTADO DE CUENTA"
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1a365d')),
                      child: pw.Text(
                        'ESTADO DE CUENTA',
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    // Resumen de Saldos
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Factura:', style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                        pw.Text('RD\$ ${myFormat.format(transactions.totalAmount ?? 0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Pagado:', style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                        pw.Text('RD\$ ${myFormat.format((transactions.totalAmount ?? 0) - (transactions.dueAmount ?? 0))}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: double.infinity,
                      height: 3,
                      color: (transactions.dueAmount ?? 0) <= 0 ? PdfColors.green : PdfColors.red,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Saldo Pendiente:', style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                        pw.Text(
                          (transactions.dueAmount ?? 0) <= 0 ? 'PAGADA' : 'RD\$ ${myFormat.format(transactions.dueAmount ?? 0)}',
                          style: pw.TextStyle(
                            color: (transactions.dueAmount ?? 0) <= 0 ? PdfColors.green : PdfColors.red,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    // Tabla de Historial
                    pw.Table.fromTextArray(
                      context: context,
                      border: const pw.TableBorder(
                        left: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                        right: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                        bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                        top: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                        verticalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
                        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
                      ),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
                      headerStyle: pw.TextStyle(color: PdfColors.black, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      cellStyle: const pw.TextStyle(color: PdfColors.black, fontSize: 8),
                      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                      headerAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.centerRight,
                      },
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.centerRight,
                      },
                      data: [
                        ['RECIBO', 'FECHA', 'METODO', 'MONTO'],
                        if (finalDueTransactions.isEmpty)
                          ['-', '-', 'Sin pagos registrados', '-'],
                        ...finalDueTransactions.map((tx) {
                          String fecha = '';
                          try {
                            fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(tx['transaction_date'] ?? ''));
                          } catch (_) {
                            fecha = tx['transaction_date']?.toString().split(' ')[0] ?? '';
                          }
                          // Extrae una porción del UUID como un ID corto de recibo
                          String reciboId = (tx['id']?.toString() ?? 'N/A').split('-').first.toUpperCase();
                          return [
                            'REC-$reciboId',
                            fecha,
                            tx['payment_type']?.toString() ?? '',
                            'RD\$ ${myFormat.format(double.tryParse(tx['paid_amount']?.toString() ?? '0') ?? 0)}',
                          ];
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    // Agregar página de Términos y Condiciones
  doc.addPage(
    pw.Page(
      margin: pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Título
            pw.Center(
              child: pw.Text(
                'TÉRMINOS Y CONDICIONES',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Contenido de términos y condiciones
            pw.Text(
              'DE SUMA IMPORTANCIA:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            pw.Text(
              'Nota 1: Para posponer fecha, tratar de hacerlo con tiempo, y esto independientemente tiene un costo de 2500 pesos.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 2: Las fotos adicionales tienen un costo de 500 pesos cada una.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 3: Llegar puntual el día del evento, 30 minutos de tardanza se le cobrará 1,500 pesos, y pasada la hora, la sesión de fotos se cancela y obligatoriamente hay que posponer nueva fecha. ¡Recuerda que posiblemente tenemos más eventos antes o después de ti! Por tanto, la PUNTUALIDAD es de suma importancia para nosotros. Cuando un cliente nos llega 20 o 30 minutos tarde, se nos complica todo el día, ayúdanos a quedar bien, con todos nuestros clientes.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 4: Un día después de la sesión se le enviarán las fotos para su selección, esta a través de un enlace, donde el cliente debe solo de dar like o corazones a las fotos que quiere le trabajemos. La primera vez le pedirá que ingrese su correo electrónico y después de, puede dar like libremente.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 5: Después de que el cliente selecciona las fotos en digitales se le estarán enviando al cliente editadas y retocadas a nivel profesional en un periodo de 10 a 20 días laborables. Los enmarcados en un máximo de 15 días, después de la selección del cliente, y el video o álbum 2 a 3 meses después de la selección del cliente.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 6: El cliente es el responsable de su transportación y del lugar seleccionado para la sesión fotográfica.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 7: El cliente debe de regresar el vestido en un periodo máximo de 1 hora después de su sesión fotográfica.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 8: El cliente se compromete a cuidar nuestros vestuarios como si fuesen suyo.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            
            pw.Text(
              'Nota 9: Recordar el dinero no es reembolsable.',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 15),
            
            pw.Text(
              'Todas estas restricciones nos ayudan a poder brindar un servicio de calidad, solo le pedimos a todos nuestros clientes educación, respeto y valoración de nuestro trabajo. Es su responsabilidad ayudarnos a quedar bien con todos los demás clientes. Agradecemos en gran manera su comprensión, en todos estos puntos. Nos vemos el día de su sesión fotográfica!',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            
            pw.Center(
              child: pw.Text(
                'Equipo Víctor Guzmán Fotografía',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Para llamadas: 8098982876',
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        );
      },
    ),
  );
  } catch (e, stackTrace) {
    debugPrint('🔴 [generateSaleDocument] ERROR en doc.addPage: $e');
    debugPrint('🔴 [generateSaleDocument] StackTrace: $stackTrace');
    rethrow;
  }

  debugPrint('🔵 [generateSaleDocument] doc.addPage completado exitosamente');
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

  //actualizar los productos
  await ref.read(ActualizarEstadoReservaProvider({
    'id': idReservaciones,
    'estado': 'confirmado',
    // estado_factura = true indica que la reserva YA tiene factura creada
    // El estado de pago se maneja por separado en la tabla de ventas (isPaid, dueAmount)
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

            // Tipo de documento según NCF
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    _getInvoiceTitle(transactions.ncfType),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  // Mostrar NCF si existe
                  if (_hasValidNcf(transactions.ncfType)) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'NCF: ${transactions.ncfNumber ?? "${transactions.ncfType}-Pendiente"}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (transactions.ncfExpirationDate != null) ...[
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'Válido hasta: ${_formatExpirationDate(transactions.ncfExpirationDate!)}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ],
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
              // Intentar obtener la reservación de las ya cargadas
              final fullReservation = reservaciones.firstWhere(
                (r) => r?.reservation['id'] == item.productId,
                orElse: () => null,
              );
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

  // Firebase usa 'multiple_dress', PostgreSQL usa 'dress_ids'
  final dressData = reservacion.reservation['multiple_dress'] ?? reservacion.reservation['dress_ids'];
  if (dressData != null && dressData is List) {
    final multipleDress = dressData;
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
      if (dressData != null && dressData is List) ...[
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
    if (hora != null && hora.isNotEmpty) {
      // Convertir hora a formato 12h AM/PM
      final horaFormateada = _convertirHora12h(hora);
      return '$fechaFormateada $horaFormateada';
    }
    return fechaFormateada;
  } catch (e) {
    return '-';
  }
}

/// Convierte hora de formato 24h (HH:mm) a formato 12h (h:mm AM/PM)
String _convertirHora12h(String hora) {
  try {
    // Parsear hora en formato HH:mm o H:mm
    final parts = hora.split(':');
    if (parts.length < 2) return hora;

    int hour = int.parse(parts[0]);
    final minutes = parts[1].substring(0, 2); // Solo los primeros 2 caracteres (minutos)

    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }

    return '$hour:$minutes $period';
  } catch (e) {
    return hora; // Si falla, retornar la hora original
  }
}

/// Obtiene el título de la factura según el tipo de NCF (DGII)
String _getInvoiceTitle(String? ncfType) {
  if (ncfType == null || ncfType.isEmpty || ncfType == 'SIN') {
    return 'RECIBO / FACTURA INTERNA';
  }

  switch (ncfType) {
    case 'B01':
      return 'FACTURA DE CRÉDITO FISCAL';
    case 'B02':
      return 'FACTURA DE CONSUMO';
    case 'B14':
      return 'FACTURA GUBERNAMENTAL';
    case 'B15':
      return 'FACTURA DE RÉGIMEN ESPECIAL';
    case 'B16':
      return 'FACTURA DE EXPORTACIÓN';
    default:
      return 'FACTURA CON COMPROBANTE FISCAL';
  }
}

/// Verifica si la factura tiene NCF válido
bool _hasValidNcf(String? ncfType) {
  return ncfType != null && ncfType.isNotEmpty && ncfType != 'SIN';
}

/// Formatea la fecha de vencimiento del NCF (YYYY-MM-DD a DD/MM/YYYY)
String _formatExpirationDate(String dateStr) {
  try {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return dateStr;
  } catch (e) {
    return dateStr;
  }
}

/// Widget auxiliar para construir filas de información compactas (para layout horizontal)
pw.Widget _buildInfoRowCompact(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Widget auxiliar para construir filas con líneas punteadas (estilo formulario oficial)
pw.Widget _buildFormRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
        ),
        pw.Expanded(
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(left: 5, bottom: 2),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
