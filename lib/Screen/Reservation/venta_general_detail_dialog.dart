import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/sale_transaction_model.dart';
import '../../model/reservation_model.dart';
import '../../Provider/transactions_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/general_setting_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../PDF/print_pdf.dart';
import 'package:intl/intl.dart';

class VentaGeneralDetailDialog extends ConsumerWidget {
  final String invoiceNumber;
  final ReservationModel reservation;

  const VentaGeneralDetailDialog({
    super.key,
    required this.invoiceNumber,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myFormat = NumberFormat('#,##0.00', 'en_US');

    if (invoiceNumber.isEmpty) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('No se pudo determinar el número de factura desde la nota de esta venta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    final saleAsync = ref.watch(searchSalesProvider(invoiceNumber));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0.0, 10.0)),
          ],
        ),
        child: saleAsync.when(
          data: (sales) {
            if (sales.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Factura #$invoiceNumber no encontrada.', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                ],
              );
            }

            final sale = sales.first;
            final dueAmount = sale.dueAmount ?? 0;
            final totalAmount = sale.totalAmount ?? 0;
            final paidAmount = totalAmount - dueAmount;
            final isPaid = dueAmount <= 0;
            final products = sale.productList ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.receipt_long, color: Colors.teal.shade700, size: 28),
                      const SizedBox(width: 8),
                      Text('Factura #$invoiceNumber',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                    ]),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 4),

                // ── Cliente ──────────────────────────────────
                Row(children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Cliente: ${sale.customerName}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                ]),
                const SizedBox(height: 12),

                // ── Estado de Pago ───────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPaid
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPaid ? 'PAGADA COMPLETA' : 'TIENE SALDO PENDIENTE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green.shade800 : Colors.red.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isPaid) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Pagado: \$${myFormat.format(paidAmount)}',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                  Text('Pendiente: \$${myFormat.format(dueAmount)}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Productos ────────────────────────────────
                Text('Productos (${products.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: products.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No se encontraron productos en esta factura.',
                          style: TextStyle(color: Colors.grey))),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final subTotal = double.tryParse(product.subTotal?.toString() ?? '0') ?? 0;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              radius: 16,
                              child: Text('${product.quantity.toInt()}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                            ),
                            title: Text(product.productName ?? 'Producto', style: const TextStyle(fontSize: 14)),
                            trailing: Text('\$${myFormat.format(subTotal)}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 16),

                // ── Total ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Factura:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('\$${myFormat.format(totalAmount)}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── PDF Button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text('Ver Factura Oficial (PDF)',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _printPdf(context, ref, sale),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Buscando detalles de factura...'),
              ],
            ),
          ),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ocurrió un error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printPdf(BuildContext context, WidgetRef ref, SaleTransactionModel sale) async {
    final personalData = ref.read(profileDetailsProvider);
    final settingsAsync = ref.read(generalSettingProvider);

    if (personalData.value == null || settingsAsync.value == null) {
      EasyLoading.showError('Faltan datos de configuración para imprimir');
      return;
    }

    try {
      await GeneratePdfAndPrint().printSaleInvoice(
        personalInformationModel: personalData.value!,
        saleTransactionModel: sale,
        context: context,
        setting: settingsAsync.value!,
        skipPrinting: false,
      );
    } catch (e) {
      EasyLoading.showError('Error al generar PDF: $e');
    }
  }
}
