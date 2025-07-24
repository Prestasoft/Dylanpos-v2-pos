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
import 'package:firebase_database/firebase_database.dart';
import '../../const.dart';

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
    
    
    // Agrupar transferencias por banco
    Map<String?, List<Map<String, dynamic>>> transfersByBank = {};
    Map<String?, double> totalsByBank = {};
    double totalGeneral = 0.0;
    
    dailyTransactions.forEach((key, value) {
      final type = value['type'];
      
      print('DEBUG: Procesando transacción $key - Tipo: $type');
      print('DEBUG: Contenido completo de value: $value');
      
      // Intentar obtener la transacción según el tipo
      Map<String, dynamic>? transaction;
      if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones') {
        transaction = value['saleTransactionModel'];
      } else if (type == 'Due Collection' || type == 'Due Payment') {
        transaction = value['dueTransactionModel'];
      }
      
      print('DEBUG: Transaction data: ${transaction != null ? "encontrada" : "null"}');
      
      final paymentType = transaction?['paymentType'];
      print('DEBUG: PaymentType extraído: $paymentType');
      
      if (_isTransfer(paymentType)) {
        final bankId = transaction?['bankId'];
        final bankName = transaction?['bankName'] ?? 'Banco no especificado';
        final amount = (value['paymentIn'] as num).toDouble();
        
        print('DEBUG: Es transferencia - BankId: $bankId - BankName: $bankName - Amount: $amount');
        
        // Agrupar por banco
        if (!transfersByBank.containsKey(bankId)) {
          transfersByBank[bankId] = [];
          totalsByBank[bankId] = 0.0;
        }
        
        transfersByBank[bankId]!.add({
          'customerName': transaction?['customerName'] ?? 'Cliente desconocido',
          'invoiceNumber': transaction?['invoiceNumber'] ?? key,
          'amount': amount,
          'date': value['time'] ?? DateTime.now().toString(),
          'bankName': bankName,
          'type': type,
        });
        
        totalsByBank[bankId] = (totalsByBank[bankId] ?? 0) + amount;
        totalGeneral += amount;
      }
    });
    
    print('DEBUG: Total de bancos encontrados: ${transfersByBank.keys.length}');
    print('DEBUG: Bancos: ${transfersByBank.keys.toList()}');
    print('DEBUG: Total general de transferencias: $totalGeneral');
    
    // Si no hay transferencias, mostrar mensaje con información de depuración
    if (transfersByBank.isEmpty) {
      // Contar todas las transacciones y sus tipos de pago
      Map<String, int> paymentTypeCounts = {};
      dailyTransactions.forEach((key, value) {
        final type = value['type'];
        Map<String, dynamic>? transaction;
        if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones') {
          transaction = value['saleTransactionModel'];
        } else if (type == 'Due Collection' || type == 'Due Payment') {
          transaction = value['dueTransactionModel'];
        }
        
        final paymentType = transaction?['paymentType']?.toString() ?? 'Sin tipo';
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
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
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
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.blue.shade200),
                                                ),
                                                child: Text(
                                                  transfer['invoiceNumber'],
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            transfer['customerName'],
                                            style: theme.textTheme.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '$globalCurrency${myFormat.format(transfer['amount'])}',
                                            textAlign: TextAlign.right,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
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
      
      // Obtener los providers necesarios
      final profileAsync = ref.watch(profileDetailsProvider);
      final settingAsync = ref.watch(generalSettingProvider);
      
      // Obtener userId primero
      final userId = await getUserID();
      print('DEBUG _showInvoiceDetails: userId obtenido: $userId');
      
      profileAsync.when(
        data: (profileInfo) {
          settingAsync.when(
            data: (setting) async {
              try {
                print('DEBUG _showInvoiceDetails: Providers cargados correctamente');
                
                // Determinar la referencia de la base de datos
                DatabaseReference dbRef;
                
                if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones') {
                  dbRef = FirebaseDatabase.instance.ref('$userId/Sales Transition');
                  print('DEBUG _showInvoiceDetails: Buscando en Sales Transition');
                } else if (type == 'Due Collection' || type == 'Due Payment') {
                  dbRef = FirebaseDatabase.instance.ref('$userId/Due Transaction');
                  print('DEBUG _showInvoiceDetails: Buscando en Due Transaction');
                } else {
                  print('DEBUG _showInvoiceDetails: Tipo no soportado: $type');
                  EasyLoading.showError('Tipo de transacción no soportado');
                  return;
                }
                
                // Buscar la transacción
                print('DEBUG _showInvoiceDetails: Obteniendo todas las transacciones');
                final snapshot = await dbRef.get();
                
                if (!snapshot.exists) {
                  print('DEBUG _showInvoiceDetails: No hay transacciones en la base de datos');
                  EasyLoading.showError('No se encontraron transacciones');
                  return;
                }
                
                // Buscar la factura específica
                final allData = snapshot.value as Map<dynamic, dynamic>;
                Map<dynamic, dynamic>? transactionData;
                
                allData.forEach((key, value) {
                  if (value is Map && value['invoiceNumber'] == invoiceNumber) {
                    print('DEBUG _showInvoiceDetails: Factura encontrada con key: $key');
                    transactionData = value;
                  }
                });
                
                if (transactionData == null) {
                  print('DEBUG _showInvoiceDetails: Factura $invoiceNumber no encontrada');
                  EasyLoading.showError('Factura no encontrada');
                  return;
                }
                
                // Generar el PDF según el tipo
                if (type == 'Sale' || type == 'Adicionales' || type == 'Impresiones') {
                  final saleTransaction = SaleTransactionModel.fromJson(transactionData!);
                  
                  await GeneratePdfAndPrint().printSaleInvoice(
                    personalInformationModel: profileInfo,
                    saleTransactionModel: saleTransaction,
                    context: context,
                    setting: setting,
                    printType: 'normal',
                    fromSaleReports: true,
                  );
                } else if (type == 'Due Collection' || type == 'Due Payment') {
                  final dueTransaction = DueTransactionModel.fromJson(transactionData!);
                  
                  await GeneratePdfAndPrint().printDueInvoice(
                    personalInformationModel: profileInfo,
                    dueTransactionModel: dueTransaction,
                    setting: setting,
                    context: context,
                    fromSaleReports: true,
                  );
                }
                
                EasyLoading.dismiss();
              } catch (dbError) {
                print('DEBUG _showInvoiceDetails: Error en base de datos: $dbError');
                EasyLoading.showError('Error: ${dbError.toString()}');
              }
            },
            loading: () => EasyLoading.show(status: 'Cargando configuración...'),
            error: (e, s) {
              EasyLoading.showError('Error al cargar configuración');
              print('Error configuración: $e');
            },
          );
        },
        loading: () => EasyLoading.show(status: 'Cargando datos del perfil...'),
        error: (e, s) {
          EasyLoading.showError('Error al cargar perfil');
          print('Error perfil: $e');
        },
      );
      
    } catch (e) {
      EasyLoading.showError('Error general: $e');
      print('Error en _showInvoiceDetails: $e');
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