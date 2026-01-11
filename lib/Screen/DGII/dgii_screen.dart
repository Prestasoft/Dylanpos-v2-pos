import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../Provider/dgii_provider.dart';
import '../../Repository/dgii_repo.dart';
import '../../model/ncf_model.dart';
import '../Widgets/Constant Data/constant.dart';

class DgiiScreen extends ConsumerStatefulWidget {
  const DgiiScreen({super.key});

  @override
  ConsumerState<DgiiScreen> createState() => _DgiiScreenState();
}

class _DgiiScreenState extends ConsumerState<DgiiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor.withOpacity(0.05),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kMainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: kMainColor, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DGII - Comprobantes Fiscales',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestión de NCF y Reportes Fiscales',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Botón de refrescar
                IconButton(
                  onPressed: () {
                    ref.invalidate(ncfTypesProvider);
                    ref.invalidate(ncfSequencesProvider);
                    ref.invalidate(ncfSalesSummaryProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar datos',
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: kMainColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kMainColor,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
                Tab(icon: Icon(Icons.settings), text: 'Secuencias NCF'),
                Tab(icon: Icon(Icons.file_download), text: 'Reportes 607'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResumenTab(),
                _buildSequencesTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTab() {
    final summaryAsync = ref.watch(ncfSalesSummaryProvider);
    final ncfTypesAsync = ref.watch(ncfTypesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipos de NCF disponibles
          Text(
            'Tipos de Comprobantes Fiscales',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ncfTypesAsync.when(
            data: (types) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: types.map((type) => _buildNcfTypeCard(type)).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 32),

          // Resumen de ventas por tipo
          Text(
            'Resumen de Ventas por Tipo de Comprobante',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            data: (summary) => summary.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No hay datos de ventas para mostrar'),
                      ),
                    ),
                  )
                : _buildSummaryTable(summary),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildNcfTypeCard(NcfTypeModel type) {
    final color = Color(int.parse(type.colorHex.replaceFirst('#', '0xFF')));

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type.code,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              if (type.appliesItbis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${type.itbisRate.toInt()}% ITBIS',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            type.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (type.description != null) ...[
            const SizedBox(height: 4),
            Text(
              type.description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (type.requiresRnc) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Requiere RNC',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTable(List<NcfSalesSummaryModel> summary) {
    double totalSales = 0;
    double totalItbis = 0;
    int totalInvoices = 0;

    for (var s in summary) {
      totalSales += s.totalSales;
      totalItbis += s.totalItbis;
      totalInvoices += s.totalInvoices;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: kMainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Tipo NCF', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Facturas', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Ventas', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  Expanded(flex: 2, child: Text('ITBIS', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Rows
            ...summary.map((s) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getNcfColor(s.ncfType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.ncfType,
                            style: TextStyle(
                              color: _getNcfColor(s.ncfType),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.ncfTypeName ?? '',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.totalInvoices.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currencyFormat.format(s.totalSales),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currencyFormat.format(s.totalItbis),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: s.totalItbis > 0 ? Colors.green[700] : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            // Total
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                      totalInvoices.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currencyFormat.format(totalSales),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currencyFormat.format(totalItbis),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequencesTab() {
    final sequencesAsync = ref.watch(ncfSequencesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Secuencias de Comprobantes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // TODO: Agregar nueva secuencia
                  toast('Funcionalidad próximamente');
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva Secuencia'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Configure las secuencias de NCF autorizadas por la DGII para su negocio.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 20),
          sequencesAsync.when(
            data: (sequences) => sequences.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No hay secuencias NCF configuradas'),
                            const SizedBox(height: 8),
                            Text(
                              'Las secuencias se utilizan para tipos de comprobante diferentes a "Sin Comprobante"',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: sequences.map((seq) => _buildSequenceCard(seq)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceCard(NcfSequenceModel sequence) {
    final color = _getNcfColor(sequence.ncfTypeCode);
    final isWarning = sequence.isNearDepletion || sequence.isNearExpiration;
    final isError = sequence.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError
              ? Colors.red.withOpacity(0.5)
              : isWarning
                  ? Colors.orange.withOpacity(0.5)
                  : Colors.transparent,
          width: isError || isWarning ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sequence.ncfTypeCode,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sequence.typeName ?? sequence.ncfTypeCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Serie ${sequence.serie}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isError)
                  _buildStatusBadge('EXPIRADA', Colors.red)
                else if (sequence.isNearExpiration)
                  _buildStatusBadge('POR EXPIRAR', Colors.orange)
                else if (sequence.isNearDepletion)
                  _buildStatusBadge('CASI AGOTADA', Colors.orange)
                else
                  _buildStatusBadge('ACTIVA', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uso: ${sequence.currentSequence} de ${NumberFormat('#,###').format(sequence.maxSequence)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${sequence.usagePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sequence.isNearDepletion ? Colors.orange : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sequence.usagePercentage / 100,
                    backgroundColor: Colors.grey[200],
                    color: sequence.isNearDepletion ? Colors.orange : color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info adicional
            Row(
              children: [
                if (sequence.authorizationDate != null) ...[
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Desde: ${_formatDate(sequence.authorizationDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
                if (sequence.expirationDate != null) ...[
                  Icon(
                    Icons.event_busy,
                    size: 14,
                    color: sequence.isExpired
                        ? Colors.red
                        : sequence.isNearExpiration
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vence: ${_formatDate(sequence.expirationDate)}',
                    style: TextStyle(
                      color: sequence.isExpired
                          ? Colors.red
                          : sequence.isNearExpiration
                              ? Colors.orange
                              : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: sequence.isExpired || sequence.isNearExpiration ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showEditSequenceDialog(sequence),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final selectedMonth = ref.watch(reportMonthProvider);
    final selectedYear = ref.watch(reportYearProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generación de Reportes DGII',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Genere los archivos de texto para subir al portal de la DGII.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Selector de período
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período del Reporte',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Mes',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_getMonthName(i + 1)),
                          )),
                          onChanged: (v) => ref.read(reportMonthProvider.notifier).state = v!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Año',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(5, (i) => DropdownMenuItem(
                            value: DateTime.now().year - i,
                            child: Text((DateTime.now().year - i).toString()),
                          )),
                          onChanged: (v) => ref.read(reportYearProvider.notifier).state = v!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Cards de reportes
          Row(
            children: [
              Expanded(child: _buildReportCard(
                title: 'Reporte 607',
                subtitle: 'Ventas de Bienes y Servicios',
                icon: Icons.point_of_sale,
                color: Colors.blue,
                onGenerate: () => _generateReport607(selectedYear, selectedMonth),
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildReportCard(
                title: 'Reporte 606',
                subtitle: 'Compras de Bienes y Servicios',
                icon: Icons.shopping_cart,
                color: Colors.green,
                onGenerate: () => toast('Reporte 606 próximamente'),
                enabled: false,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildReportCard(
                title: 'Reporte 608',
                subtitle: 'Comprobantes Anulados',
                icon: Icons.cancel,
                color: Colors.red,
                onGenerate: () => toast('Reporte 608 próximamente'),
                enabled: false,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onGenerate,
    bool enabled = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(enabled ? 0.1 : 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: enabled ? color : Colors.grey, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: enabled ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: enabled ? onGenerate : null,
              icon: const Icon(Icons.download),
              label: const Text('Generar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? color : Colors.grey[300],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateReport607(int year, int month) async {
    final report = await ref.read(report607Provider({'year': year, 'month': month}).future);

    if (report['success'] == true && report['report'] != null) {
      final records = report['report'] as List<Report607RecordModel>;
      if (records.isEmpty) {
        toast('No hay registros para el período seleccionado');
        return;
      }

      // Generar contenido del archivo
      final lines = records.map((r) => r.toTxtLine()).join('\n');

      // En web, mostrar diálogo con el contenido
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Reporte 607 - ${_getMonthName(month)} $year'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total de registros: ${records.length}'),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        lines,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar descarga real del archivo
                toast('Copie el contenido para usar en DGII');
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
          ],
        ),
      );
    } else {
      toast('Error generando reporte');
    }
  }

  void _showEditSequenceDialog(NcfSequenceModel sequence) {
    final serieController = TextEditingController(text: sequence.serie);
    final currentSequenceController = TextEditingController(text: sequence.currentSequence.toString());
    final maxSequenceController = TextEditingController(text: sequence.maxSequence.toString());
    DateTime? authDate = sequence.authorizationDate != null ? DateTime.tryParse(sequence.authorizationDate!) : null;
    DateTime? expDate = sequence.expirationDate != null ? DateTime.tryParse(sequence.expirationDate!) : null;
    bool isActive = sequence.isActive;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getNcfColor(sequence.ncfTypeCode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sequence.ncfTypeCode,
                    style: TextStyle(
                      color: _getNcfColor(sequence.ncfTypeCode),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Editar Secuencia ${sequence.typeName ?? ""}'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info de la sucursal
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Sucursal: ${sequence.branchId.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Serie y Secuencia actual
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: serieController,
                            decoration: const InputDecoration(
                              labelText: 'Serie',
                              hintText: 'Ej: A, B',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.text_fields),
                            ),
                            maxLength: 5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: currentSequenceController,
                            decoration: const InputDecoration(
                              labelText: 'Secuencia Actual',
                              hintText: 'Último número usado',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Máximo autorizado
                    TextFormField(
                      controller: maxSequenceController,
                      decoration: const InputDecoration(
                        labelText: 'Máximo Autorizado por DGII',
                        hintText: 'Ej: 1000, 5000, 10000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                        helperText: 'Cantidad máxima de comprobantes autorizados',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Fechas
                    const Text(
                      'Período de Autorización',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: authDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setDialogState(() => authDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Autorización',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                authDate != null
                                    ? DateFormat('dd/MM/yyyy').format(authDate!)
                                    : 'Seleccionar',
                                style: TextStyle(
                                  color: authDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: expDate ?? DateTime.now().add(const Duration(days: 365)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setDialogState(() => expDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha Vencimiento',
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.event_busy,
                                  color: expDate != null && expDate!.isBefore(DateTime.now())
                                      ? Colors.red
                                      : null,
                                ),
                              ),
                              child: Text(
                                expDate != null
                                    ? DateFormat('dd/MM/yyyy').format(expDate!)
                                    : 'Seleccionar',
                                style: TextStyle(
                                  color: expDate != null
                                      ? expDate!.isBefore(DateTime.now())
                                          ? Colors.red
                                          : Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Estado activo
                    SwitchListTile(
                      title: const Text('Secuencia Activa'),
                      subtitle: const Text('Desactive si la secuencia ya no se utilizará'),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      activeColor: Colors.green,
                    ),

                    // Resumen
                    if (int.tryParse(maxSequenceController.text) != null &&
                        int.tryParse(currentSequenceController.text) != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Disponibles', style: TextStyle(fontSize: 12)),
                                Text(
                                  '${(int.tryParse(maxSequenceController.text) ?? 0) - (int.tryParse(currentSequenceController.text) ?? 0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Usados', style: TextStyle(fontSize: 12)),
                                Text(
                                  currentSequenceController.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('% Uso', style: TextStyle(fontSize: 12)),
                                Text(
                                  '${(((int.tryParse(currentSequenceController.text) ?? 0) / (int.tryParse(maxSequenceController.text) ?? 1)) * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: ((int.tryParse(currentSequenceController.text) ?? 0) /
                                                (int.tryParse(maxSequenceController.text) ?? 1)) >
                                            0.9
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        // Validaciones
                        final currentSeq = int.tryParse(currentSequenceController.text);
                        final maxSeq = int.tryParse(maxSequenceController.text);

                        if (serieController.text.trim().isEmpty) {
                          toast('La serie es requerida');
                          return;
                        }
                        if (currentSeq == null || currentSeq < 0) {
                          toast('Secuencia actual inválida');
                          return;
                        }
                        if (maxSeq == null || maxSeq <= 0) {
                          toast('Máximo autorizado inválido');
                          return;
                        }
                        if (currentSeq > maxSeq) {
                          toast('La secuencia actual no puede ser mayor al máximo');
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          final success = await DgiiRepository().updateNcfSequence(
                            sequence.id!,
                            serie: serieController.text.trim().toUpperCase(),
                            currentSequence: currentSeq,
                            maxSequence: maxSeq,
                            authorizationDate: authDate?.toIso8601String(),
                            expirationDate: expDate?.toIso8601String(),
                            isActive: isActive,
                          );

                          if (success) {
                            toast('Secuencia actualizada correctamente');
                            ref.invalidate(ncfSequencesProvider);
                            Navigator.pop(ctx);
                          } else {
                            toast('Error al actualizar la secuencia');
                            setDialogState(() => isSaving = false);
                          }
                        } catch (e) {
                          toast('Error: $e');
                          setDialogState(() => isSaving = false);
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getNcfColor(String code) {
    switch (code) {
      case 'SIN':
        return Colors.grey;
      case 'B01':
        return Colors.blue;
      case 'B02':
        return Colors.green;
      case 'B04':
        return Colors.orange;
      case 'B14':
        return Colors.purple;
      case 'B15':
        return Colors.cyan;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}
