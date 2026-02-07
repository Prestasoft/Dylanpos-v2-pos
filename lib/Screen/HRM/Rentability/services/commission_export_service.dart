import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/employee_performance_model.dart';

/// Servicio para exportar reportes de comisiones a PDF y Excel
class CommissionExportService {
  /// Generar PDF con reporte de comisiones
  Future<Uint8List> generateCommissionsPDF({
    required List<EmployeePerformance> performances,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String branchName,
  }) async {
    final pdf = pw.Document();

    // Calcular totales
    double totalRevenue = 0;
    double totalCommissions = 0;
    int totalReservations = 0;

    for (var perf in performances) {
      totalRevenue += perf.totalRevenue;
      totalCommissions += perf.commissionEarned;
      totalReservations += perf.totalReservations;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'REPORTE DE COMISIONES',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  branchName,
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Período: ${DateFormat('dd/MM/yyyy').format(periodStart)} - ${DateFormat('dd/MM/yyyy').format(periodEnd)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Resumen Ejecutivo
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESUMEN EJECUTIVO',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Empleados Activos:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('${performances.length}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Reservas:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('$totalReservations', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Ingresos Totales:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('\$${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Comisiones Totales:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('\$${totalCommissions.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.purple700)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Tabla de Comisiones
          pw.Text(
            'DETALLE DE COMISIONES POR EMPLEADO',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: [
              'Ranking',
              'Empleado',
              'Reservas',
              'Facturadas',
              'Ingresos',
              'Tier',
              '%',
              'Comisión',
            ],
            data: performances.asMap().entries.map((entry) {
              final index = entry.key;
              final perf = entry.value;
              return [
                '#${index + 1}',
                perf.employeeName,
                perf.totalReservations.toString(),
                perf.invoicedReservations.toString(),
                '\$${perf.totalRevenue.toStringAsFixed(2)}',
                perf.assignedTier?.name ?? 'N/A',
                '${perf.commissionPercentage.toStringAsFixed(1)}%',
                '\$${perf.commissionEarned.toStringAsFixed(2)}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),

          // Pie de página
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Este documento es un reporte interno generado electrónicamente.',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generar Excel con reporte de comisiones
  Future<Uint8List> generateCommissionsExcel({
    required List<EmployeePerformance> performances,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String branchName,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Comisiones'];

    // Configurar ancho de columnas
    sheet.setColumnWidth(0, 8);  // Ranking
    sheet.setColumnWidth(1, 25); // Empleado
    sheet.setColumnWidth(2, 12); // Total Reservas
    sheet.setColumnWidth(3, 12); // Facturadas
    sheet.setColumnWidth(4, 12); // Pendientes
    sheet.setColumnWidth(5, 15); // Ingresos
    sheet.setColumnWidth(6, 10); // Tier
    sheet.setColumnWidth(7, 8);  // %
    sheet.setColumnWidth(8, 15); // Comisión

    // Estilo para encabezados
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Título
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('REPORTE DE COMISIONES');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
    );

    // Información del período
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Sucursal: $branchName');
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Período: ${DateFormat('dd/MM/yyyy').format(periodStart)} - ${DateFormat('dd/MM/yyyy').format(periodEnd)}'
    );
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
    );

    // Encabezados de tabla (fila 6)
    final headers = [
      'Ranking',
      'Empleado',
      'Total Reservas',
      'Facturadas',
      'Pendientes',
      'Ingresos',
      'Tier',
      '%',
      'Comisión',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Datos
    for (var i = 0; i < performances.length; i++) {
      final perf = performances[i];
      final rowIndex = i + 6;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
        IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
        TextCellValue(perf.employeeName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
        IntCellValue(perf.totalReservations);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
        IntCellValue(perf.invoicedReservations);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
        IntCellValue(perf.pendingReservations);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value =
        DoubleCellValue(perf.totalRevenue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value =
        TextCellValue(perf.assignedTier?.name ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value =
        DoubleCellValue(perf.commissionPercentage);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value =
        DoubleCellValue(perf.commissionEarned);

      // Aplicar formato de moneda a columnas de ingresos y comisiones
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).cellStyle =
        CellStyle(numberFormat: NumFormat.standard_2);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).cellStyle =
        CellStyle(numberFormat: NumFormat.standard_2);
    }

    // Fila de totales
    final totalRow = performances.length + 7;
    double totalRevenue = performances.fold(0, (sum, p) => sum + p.totalRevenue);
    double totalCommissions = performances.fold(0, (sum, p) => sum + p.commissionEarned);

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow)).value =
      TextCellValue('TOTALES:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow)).cellStyle =
      CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow)).value =
      DoubleCellValue(totalRevenue);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow)).cellStyle =
      CellStyle(bold: true, numberFormat: NumFormat.standard_2);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: totalRow)).value =
      DoubleCellValue(totalCommissions);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: totalRow)).cellStyle =
      CellStyle(bold: true, numberFormat: NumFormat.standard_2);

    // Eliminar hoja por defecto si existe
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return Uint8List.fromList(excel.encode()!);
  }
}
