import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as pro;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../Provider/bank_provider.dart';
import '../currency/currency_provider.dart';
import '../Widgets/Constant Data/constant.dart';
import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/general_setting_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../model/sale_transaction_model.dart';
import '../../model/due_transaction_model.dart';
import '../../services/api_service.dart';

class TransferDetailsDialog extends ConsumerWidget {
  final Map<String, dynamic> dailyTransactions;
  
  const TransferDetailsDialog({
    Key? key,
    required this.dailyTransactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('DEBUG TransferDetailsDialog: Build iniciado');
    print('DEBUG TransferDetailsDialog: Transacciones recibidas: ${dailyTransactions.length}');

    final myFormat = NumberFormat('#,##0.00', 'es_DO');
    final theme = Theme.of(context);
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';

    // Obtener lista de bancos para hacer lookup del nombre
    final banksAsync = ref.watch(allBanksProvider);
    final banksList = banksAsync.valueOrNull ?? [];

    // Crear mapa de bankId -> bankName para lookup rápido
    final Map<String, String> bankIdToName = {};
    for (var bank in banksList) {
      if (bank.bankId != null && bank.bankName != null) {
        bankIdToName[bank.bankId!] = bank.bankName!;
        print('DEBUG: Banco cargado: ${bank.bankId} -> ${bank.bankName}');
      }
    }
    print('DEBUG TransferDetailsDialog: ${bankIdToName.length} bancos cargados para lookup');

    // Agrupar transferencias por banco
    Map<String?, List<Map<String, dynamic>>> transfersByBank = {};
    Map<String?, double> totalsByBank = {};
    double totalGeneral = 0.0;

    dailyTransactions.forEach((key, value) {
      final type = value['type'];

      print('DEBUG: Procesando transacción $key - Tipo: $type');

      // Intentar obtener la transacción según el tipo
      Map<String, dynamic>? transaction;
      bool isDeleted = type == 'Deleted';

      if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones' || type == 'Reserva') {
        transaction = value['saleTransactionModel'];
      } else if (type == 'Due Collection' || type == 'Due Payment' || type == 'Cuenta x Cobrar') {
        transaction = value['dueTransactionModel'];
      } else if (isDeleted) {
        // Para facturas eliminadas, buscar el saleTransactionModel dentro de 'data' o directamente
        transaction = value['saleTransactionModel'] ?? value['data']?['saleTransactionModel'];
      }

      // Obtener paymentType: primero del modelo anidado, luego del campo directo (soporte snake_case)
      String? paymentType = transaction?['paymentType']?.toString()
          ?? transaction?['payment_type']?.toString()
          ?? value['paymentType']?.toString()
          ?? value['payment_type']?.toString();
      print('DEBUG: PaymentType extraído: $paymentType (modelo: ${transaction?['paymentType']}, directo: ${value['paymentType']})');

      if (_isTransfer(paymentType)) {
        // Obtener campos: primero del modelo anidado, luego del campo directo (soporte snake_case para PostgreSQL)
        final bankId = transaction?['bankId']?.toString()
            ?? transaction?['bank_id']?.toString()
            ?? value['bankId']?.toString()
            ?? value['bank_id']?.toString();

        // CRÍTICO: Hacer lookup del nombre del banco usando bankId
        // Si el bankName guardado es null/vacío, buscar en la lista de bancos
        String? savedBankName = transaction?['bankName']?.toString()
            ?? transaction?['bank_name']?.toString()
            ?? value['bankName']?.toString()
            ?? value['bank_name']?.toString();

        // Si no hay nombre guardado o es genérico, intentar lookup por ID
        String bankName;
        if (savedBankName == null || savedBankName.isEmpty || savedBankName == 'Banco no especificado') {
          bankName = bankId != null ? (bankIdToName[bankId] ?? 'Banco no especificado') : 'Banco no especificado';
          print('DEBUG: Nombre de banco resuelto por lookup: bankId=$bankId -> $bankName');
        } else {
          bankName = savedBankName;
        }

        final customerName = transaction?['customerName']
            ?? transaction?['customer_name']
            ?? value['customerName']
            ?? value['customer_name']
            ?? 'Cliente desconocido';
        final invoiceNumber = transaction?['invoiceNumber']
            ?? transaction?['invoice_number']
            ?? value['invoiceNumber']
            ?? value['invoice_number']
            ?? key;
        final amount = (value['paymentIn'] as num).toDouble();

        print('DEBUG: Es transferencia - BankId: $bankId - BankName: $bankName - Amount: $amount');

        // Agrupar por banco (usar bankId como key para agrupar correctamente)
        final groupKey = bankId ?? bankName; // Usar bankId si existe, si no el nombre
        if (!transfersByBank.containsKey(groupKey)) {
          transfersByBank[groupKey] = [];
          totalsByBank[groupKey] = 0.0;
        }

        transfersByBank[groupKey]!.add({
          'customerName': customerName,
          'invoiceNumber': invoiceNumber,
          'amount': amount,
          'date': value['time'] ?? DateTime.now().toString(),
          'bankName': bankName,
          'bankId': bankId,
          'type': type,
          'isDeleted': isDeleted,
        });

        // CORREGIDO: Usar groupKey en lugar de bankId para el total
        totalsByBank[groupKey] = (totalsByBank[groupKey] ?? 0) + amount;
        totalGeneral += amount;

        // DEBUG: Mostrar toda la estructura para diagnosticar
        print('DEBUG FULL: transaction keys: ${transaction?.keys.toList()}');
        print('DEBUG FULL: value keys: ${value.keys.toList()}');
        if (transaction != null) {
          print('DEBUG FULL: transaction[bankId]=${transaction['bankId']}, transaction[bank_id]=${transaction['bank_id']}');
          print('DEBUG FULL: transaction[bankName]=${transaction['bankName']}, transaction[bank_name]=${transaction['bank_name']}');
        }
      }
    });

    print('DEBUG: Total de bancos encontrados: ${transfersByBank.keys.length}');
    print('DEBUG: Bancos: ${transfersByBank.keys.toList()}');
    print('DEBUG: TotalsByBank: $totalsByBank');
    print('DEBUG: Total general de transferencias: $totalGeneral');
    
    // Si no hay transferencias, mostrar mensaje con información de depuración
    if (transfersByBank.isEmpty) {
      // Contar todas las transacciones y sus tipos de pago
      Map<String, int> paymentTypeCounts = {};
      dailyTransactions.forEach((key, value) {
        final type = value['type'];
        Map<String, dynamic>? transaction;
        if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones' || type == 'Reserva') {
          transaction = value['saleTransactionModel'];
        } else if (type == 'Due Collection' || type == 'Due Payment' || type == 'Cuenta x Cobrar') {
          transaction = value['dueTransactionModel'];
        }

        // Usar campo directo como fallback si el modelo anidado no tiene paymentType
        final paymentType = transaction?['paymentType']?.toString() ?? value['paymentType']?.toString() ?? 'Sin tipo';
        paymentTypeCounts[paymentType] = (paymentTypeCounts[paymentType] ?? 0) + 1;
      });
      
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              Text(
                'No se encontraron transferencias',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Total de transacciones analizadas: ${dailyTransactions.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Tipos de pago encontrados:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ...paymentTypeCounts.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text('${entry.key}: ${entry.value}'),
                )
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance, color: const Color(0xFF009688), size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Detalle de Transferencias',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kTitleColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // Total general
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF009688).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF009688)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TOTAL GENERAL: ',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$globalCurrency${myFormat.format(totalGeneral)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF009688),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de transferencias por banco
            Expanded(
              child: ListView.builder(
                itemCount: transfersByBank.keys.length,
                itemBuilder: (context, index) {
                  final bankId = transfersByBank.keys.elementAt(index);
                  final transfers = transfersByBank[bankId]!;
                  final bankTotal = totalsByBank[bankId] ?? 0.0;
                  final bankName = transfers.isNotEmpty ? transfers.first['bankName'] : 'Banco desconocido';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 2,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance, color: kMainColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  bankName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kMainColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$globalCurrency${myFormat.format(bankTotal)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kMainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('${transfers.length} transferencias'),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                // Encabezados de la tabla
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Factura',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Cliente',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Monto',
                                          textAlign: TextAlign.right,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                // Lista de transferencias
                                ...transfers.map((transfer) {
                                  final bool isDeleted = transfer['isDeleted'] == true;
                                  final Color rowBgColor = isDeleted ? Colors.red.shade50 : Colors.transparent;
                                  final Color textColor = isDeleted ? Colors.red.shade700 : (theme.textTheme.bodySmall?.color ?? Colors.black);
                                  final Color invoiceBgColor = isDeleted ? Colors.red.shade100 : Colors.blue.shade50;
                                  final Color invoiceBorderColor = isDeleted ? Colors.red.shade300 : Colors.blue.shade200;
                                  final Color invoiceTextColor = isDeleted ? Colors.red.shade800 : Colors.blue.shade700;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                                    decoration: BoxDecoration(
                                      color: rowBgColor,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isDeleted ? Colors.red.shade200 : Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: GestureDetector(
                                            onTap: () async {
                                              print('DEBUG: Click en factura ${transfer['invoiceNumber']} tipo ${transfer['type']}');
                                              await _showInvoiceDetails(
                                                context,
                                                ref,
                                                transfer['invoiceNumber'],
                                                transfer['type'],
                                              );
                                            },
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: invoiceBgColor,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: invoiceBorderColor),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isDeleted) ...[
                                                      Icon(Icons.delete_outline, size: 14, color: invoiceTextColor),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Flexible(
                                                      child: Text(
                                                        transfer['invoiceNumber'],
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: invoiceTextColor,
                                                          fontWeight: FontWeight.w600,
                                                          decoration: isDeleted ? TextDecoration.lineThrough : TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  transfer['customerName'],
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: textColor,
                                                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isDeleted) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade600,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'ELIMINADA',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '$globalCurrency${myFormat.format(transfer['amount'])}',
                                            textAlign: TextAlign.right,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                              decoration: isDeleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                // Total del banco
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: kMainColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total $bankName:',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$globalCurrency${myFormat.format(bankTotal)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: kMainColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Botón de cerrar
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showInvoiceDetails(BuildContext context, WidgetRef ref, String invoiceNumber, String type) async {
    try {
      print('DEBUG _showInvoiceDetails: Iniciando para factura $invoiceNumber tipo $type');

      EasyLoading.show(status: 'Generando factura...');

      // Obtener los providers necesarios usando read y esperando los futures
      final profileInfo = await ref.read(profileDetailsProvider.future);
      final setting = await ref.read(generalSettingProvider.future);

      print('DEBUG _showInvoiceDetails: Providers cargados correctamente');

      final apiService = ApiService();
      String endpoint;

      if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones' || type == 'Reserva') {
        endpoint = 'sales';
        print('DEBUG _showInvoiceDetails: Buscando en Sales');
      } else if (type == 'Due Collection' || type == 'Due Payment' || type == 'Cuenta x Cobrar') {
        endpoint = 'due-transactions';
        print('DEBUG _showInvoiceDetails: Buscando en Due Transactions');
      } else {
        print('DEBUG _showInvoiceDetails: Tipo no soportado: $type');
        EasyLoading.showError('Tipo de transacción no soportado');
        return;
      }

      // Buscar la transacción por invoiceNumber (soporte snake_case)
      print('DEBUG _showInvoiceDetails: Obteniendo transacciones para invoice: $invoiceNumber');
      final response = await apiService.get(endpoint, queryParams: {
        'invoiceNumber': invoiceNumber,
        'invoice_number': invoiceNumber,
        'limit': '10',
      });

      if (!response.success || response.data == null) {
        print('DEBUG _showInvoiceDetails: No hay transacciones en la base de datos');
        EasyLoading.showError('No se encontraron transacciones');
        return;
      }

      // Buscar la factura específica
      final dataList = response.data[endpoint == 'sales' ? 'sales' : 'due_transactions'] as List<dynamic>? ?? [];
      print('DEBUG _showInvoiceDetails: Transacciones encontradas: ${dataList.length}');

      Map<String, dynamic>? transactionData;

      for (var element in dataList) {
        final data = Map<String, dynamic>.from(element);
        // Soporte para camelCase y snake_case
        final dataInvoice = data['invoiceNumber']?.toString() ?? data['invoice_number']?.toString();
        print('DEBUG _showInvoiceDetails: Comparando "$dataInvoice" con "$invoiceNumber"');
        if (dataInvoice == invoiceNumber) {
          print('DEBUG _showInvoiceDetails: Factura encontrada');
          transactionData = data;
          break;
        }
      }

      if (transactionData == null) {
        print('DEBUG _showInvoiceDetails: Factura $invoiceNumber no encontrada en lista');
        EasyLoading.showError('Factura no encontrada');
        return;
      }

      // Generar el PDF según el tipo
      if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones' || type == 'Reserva') {
        final saleTransaction = SaleTransactionModel.fromJson(transactionData);
        print('DEBUG _showInvoiceDetails: Generando PDF de venta...');

        await GeneratePdfAndPrint().printSaleInvoice(
          personalInformationModel: profileInfo,
          saleTransactionModel: saleTransaction,
          context: context,
          setting: setting,
          printType: 'normal',
          fromSaleReports: true,
        );
        print('DEBUG _showInvoiceDetails: PDF de venta generado');
      } else if (type == 'Due Collection' || type == 'Due Payment' || type == 'Cuenta x Cobrar') {
        final dueTransaction = DueTransactionModel.fromJson(transactionData);
        print('DEBUG _showInvoiceDetails: Generando PDF de pago...');

        await GeneratePdfAndPrint().printDueInvoice(
          personalInformationModel: profileInfo,
          dueTransactionModel: dueTransaction,
          setting: setting,
          context: context,
          fromSaleReports: true,
        );
        print('DEBUG _showInvoiceDetails: PDF de pago generado');
      }

      EasyLoading.dismiss();

    } catch (e, stackTrace) {
      print('DEBUG _showInvoiceDetails: Error: $e');
      print('DEBUG _showInvoiceDetails: StackTrace: $stackTrace');
      EasyLoading.showError('Error: ${e.toString()}');
    }
  }
  
  bool _isTransfer(String? paymentType) {
    if (paymentType == null || paymentType.isEmpty) {
      print('DEBUG _isTransfer: paymentType es null o vacío');
      return false;
    }
    
    final tipo = paymentType.toLowerCase().trim();
    
    // Lista más amplia de posibles valores para transferencia
    final transferKeywords = [
      'transfer',
      'transferencia',
      'mobile',
      'bank',
      'banco',
      'transferencias', // plural
      'wire'
    ];
    
    bool isTransfer = transferKeywords.any((keyword) => tipo.contains(keyword));
    
    // También verificar si es exactamente "Transferencia"
    if (!isTransfer && paymentType.trim() == 'Transferencia') {
      isTransfer = true;
    }
    
    print('DEBUG _isTransfer: "$paymentType" -> lowercase: "$tipo" -> isTransfer: $isTransfer');
    return isTransfer;
  }
}