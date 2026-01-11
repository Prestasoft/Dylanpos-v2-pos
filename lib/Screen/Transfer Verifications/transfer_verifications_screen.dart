import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../Provider/transfer_verification_provider.dart';
import '../../model/transfer_verification_model.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

class TransferVerificationsScreen extends StatefulWidget {
  const TransferVerificationsScreen({Key? key}) : super(key: key);

  @override
  State<TransferVerificationsScreen> createState() => _TransferVerificationsScreenState();
}

class _TransferVerificationsScreenState extends State<TransferVerificationsScreen> {
  String _selectedFilter = 'pending';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();  // Convertir a hora local
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'es_DO').format(amount);
  }

  void _showVerificationDialog(BuildContext context, TransferVerificationModel transfer, WidgetRef ref) {
    final notesController = TextEditingController();
    final rejectionReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: kBlueTextColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Verificar Transferencia - Factura #${transfer.invoiceNumber}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado actual
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(transfer.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(transfer.status)),
                          ),
                          child: Row(
                            children: [
                              Icon(_getStatusIcon(transfer.status), color: _getStatusColor(transfer.status)),
                              const SizedBox(width: 8),
                              Text(
                                'Estado: ${transfer.statusDisplayName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(transfer.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info en dos columnas
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Columna 1 - Datos del cliente
                            Expanded(
                              child: _buildInfoCard(
                                title: 'Datos del Cliente',
                                icon: Icons.person,
                                items: [
                                  _InfoItem('Nombre', transfer.customerName),
                                  _InfoItem('Teléfono', transfer.customerPhone ?? 'N/A'),
                                  _InfoItem('Email', transfer.customerEmail ?? 'N/A'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Columna 2 - Datos de la factura
                            Expanded(
                              child: _buildInfoCard(
                                title: 'Datos de la Factura',
                                icon: Icons.receipt,
                                items: [
                                  _InfoItem('Factura #', transfer.invoiceNumber),
                                  _InfoItem('Monto', 'RD\$ ${_formatAmount(transfer.amount)}'),
                                  _InfoItem('Vendedor', transfer.sellerName ?? 'N/A'),
                                  _InfoItem('Fecha registro', _formatDate(transfer.createdAt)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Datos de la transferencia
                        _buildInfoCard(
                          title: 'Datos de la Transferencia',
                          icon: Icons.account_balance,
                          items: [
                            _InfoItem('Banco destino', transfer.bankName),
                            _InfoItem('Nombre del titular', transfer.holderName),
                            _InfoItem('Monto transferido', 'RD\$ ${_formatAmount(transfer.amount)}'),
                            _InfoItem('Número de referencia', transfer.referenceNumber ?? 'No proporcionado'),
                            _InfoItem('Fecha transferencia', _formatDate(transfer.transferDate)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Comprobante
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.image, color: kBlueTextColor),
                                  SizedBox(width: 8),
                                  Text('Comprobante de Transferencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: GestureDetector(
                                  onTap: () => _showFullImage(context, transfer.receiptUrl),
                                  child: Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        transfer.receiptUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const SizedBox(
                                            height: 150,
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 150,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                  Text('Error al cargar imagen'),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _showFullImage(context, transfer.receiptUrl),
                                  icon: const Icon(Icons.zoom_in),
                                  label: const Text('Ver imagen completa'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Solo mostrar campos de acción si está pendiente
                        if (transfer.isPending) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: notesController,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones del operador (opcional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],

                        // Mostrar info de verificación si ya fue procesada
                        if (!transfer.isPending) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verificado por: ${transfer.verifiedBy ?? "N/A"}'),
                                Text('Fecha verificación: ${_formatDate(transfer.verifiedAt)}'),
                                if (transfer.operatorNotes?.isNotEmpty ?? false)
                                  Text('Notas: ${transfer.operatorNotes}'),
                                if (transfer.rejectionReason?.isNotEmpty ?? false)
                                  Text('Razón de rechazo: ${transfer.rejectionReason}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (transfer.isPending) ...[
                        ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(dialogContext, transfer, notesController.text, ref),
                          icon: const Icon(Icons.cancel, color: Colors.white),
                          label: const Text('Rechazar', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _approveTransfer(dialogContext, transfer, notesController.text, ref),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('Aprobar', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ] else
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlueTextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<_InfoItem> items}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kBlueTextColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text('${item.label}:', style: TextStyle(color: Colors.grey.shade600)),
                ),
                Expanded(child: Text(item.value, style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Error al cargar imagen'));
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveTransfer(BuildContext dialogContext, TransferVerificationModel transfer, String notes, WidgetRef ref) async {
    EasyLoading.show(status: 'Aprobando...');
    final success = await transferVerificationRepository.approveTransfer(
      transfer.id!,
      operatorNotes: notes.isNotEmpty ? notes : null,
      verifiedBy: 'Operador', // TODO: Usar nombre del usuario actual
    );
    EasyLoading.dismiss();

    if (success) {
      Navigator.pop(dialogContext);
      ref.invalidate(filteredTransfersProvider);
      ref.invalidate(pendingTransferCountProvider);
      EasyLoading.showSuccess('Transferencia aprobada');
    } else {
      EasyLoading.showError('Error al aprobar transferencia');
    }
  }

  void _showRejectDialog(BuildContext parentContext, TransferVerificationModel transfer, String notes, WidgetRef ref) {
    final rejectionController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, indique la razón del rechazo:'),
            const SizedBox(height: 12),
            TextFormField(
              controller: rejectionController,
              decoration: const InputDecoration(
                labelText: 'Razón del rechazo *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (rejectionController.text.isEmpty) {
                EasyLoading.showError('Debe indicar la razón del rechazo');
                return;
              }
              Navigator.pop(context); // Cerrar diálogo de razón

              EasyLoading.show(status: 'Rechazando...');
              final success = await transferVerificationRepository.rejectTransfer(
                transfer.id!,
                rejectionReason: rejectionController.text,
                operatorNotes: notes.isNotEmpty ? notes : null,
                verifiedBy: 'Operador',
              );
              EasyLoading.dismiss();

              if (success) {
                Navigator.pop(parentContext); // Cerrar diálogo principal
                ref.invalidate(filteredTransfersProvider);
                ref.invalidate(pendingTransferCountProvider);
                EasyLoading.showSuccess('Transferencia rechazada');
              } else {
                EasyLoading.showError('Error al rechazar transferencia');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Consumer(
        builder: (context, ref, child) {
          // Actualizar filtro en provider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(transferStatusFilterProvider.notifier).state = _selectedFilter;
          });

          final transfersAsync = ref.watch(filteredTransfersProvider);
          final pendingCountAsync = ref.watch(pendingTransferCountProvider);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance, color: kBlueTextColor, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Verificación de Transferencias',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        pendingCountAsync.when(
                          data: (count) => count > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$count pendientes',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const SizedBox(),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Filtros
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Botones de filtro
                        _buildFilterButton('pending', 'Pendientes', Colors.orange),
                        const SizedBox(width: 8),
                        _buildFilterButton('approved', 'Aprobadas', Colors.green),
                        const SizedBox(width: 8),
                        _buildFilterButton('rejected', 'Rechazadas', Colors.red),
                        const SizedBox(width: 8),
                        _buildFilterButton('all', 'Todas', Colors.grey),
                        const Spacer(),
                        // Búsqueda
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ref.invalidate(filteredTransfersProvider);
                            ref.invalidate(pendingTransferCountProvider);
                          },
                          tooltip: 'Actualizar',
                        ),
                      ],
                    ),
                  ),

                  // Lista
                  Expanded(
                    child: transfersAsync.when(
                      data: (transfers) {
                        // Filtrar por búsqueda
                        final filtered = transfers.where((t) {
                          if (_searchQuery.isEmpty) return true;
                          return t.customerName.toLowerCase().contains(_searchQuery) ||
                              t.invoiceNumber.toLowerCase().contains(_searchQuery) ||
                              t.holderName.toLowerCase().contains(_searchQuery) ||
                              t.bankName.toLowerCase().contains(_searchQuery);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay transferencias ${_selectedFilter == 'all' ? '' : _selectedFilter == 'pending' ? 'pendientes' : _selectedFilter == 'approved' ? 'aprobadas' : 'rechazadas'}',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('Factura')),
                              DataColumn(label: Text('Cliente')),
                              DataColumn(label: Text('Banco')),
                              DataColumn(label: Text('Titular')),
                              DataColumn(label: Text('Monto')),
                              DataColumn(label: Text('Estado')),
                              DataColumn(label: Text('Fecha')),
                              DataColumn(label: Text('Acción')),
                            ],
                            rows: List.generate(filtered.length, (index) {
                              final transfer = filtered[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text('#${transfer.invoiceNumber}')),
                                  DataCell(Text(transfer.customerName, overflow: TextOverflow.ellipsis)),
                                  DataCell(Text(transfer.bankName)),
                                  DataCell(Text(transfer.holderName, overflow: TextOverflow.ellipsis)),
                                  DataCell(Text('RD\$ ${_formatAmount(transfer.amount)}')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(transfer.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_getStatusIcon(transfer.status), size: 14, color: _getStatusColor(transfer.status)),
                                          const SizedBox(width: 4),
                                          Text(
                                            transfer.statusDisplayName,
                                            style: TextStyle(color: _getStatusColor(transfer.status), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(transfer.createdAt))),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: kBlueTextColor),
                                      onPressed: () => _showVerificationDialog(context, transfer, ref),
                                      tooltip: 'Ver detalles',
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('Error: $error')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(String filter, String label, Color color) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}
