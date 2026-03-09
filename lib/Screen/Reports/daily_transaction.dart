import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hugeicons/hugeicons.dart'; // Eliminado
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/currency/currency_provider.dart';
import 'package:salespro_admin/Provider/daily_transaction_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/transactions_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/daily_transaction_model.dart';
import 'package:salespro_admin/model/daily_summary_model.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';
import 'package:salespro_admin/model/due_transaction_model.dart';

import '../../PDF/print_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../Expenses/expense_details.dart';
import '../Income/income_details.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../../services/api_service.dart';
import '../../services/deletion_password_service.dart';
import './transfer_details_dialog.dart';
import '../../delete_invoice_functions.dart';
import '../../model/expense_model.dart';
import '../../services/audit_service.dart';
import '../../model/audit_model.dart';
import '../../Provider/transfer_verification_provider.dart';

class DailyTransaction extends StatefulWidget {
  const DailyTransaction({super.key});

  @override
  State<DailyTransaction> createState() => _DailyTransactionState();
}

class _DailyTransactionState extends State<DailyTransaction> {
  List<String> _problematicInvoices = [];

  // Construir lista de facturas eliminadas desde las transacciones filtradas
  // Esto asegura que respeta los filtros de fecha aplicados
  List<Map<String, dynamic>> _buildDeletedInvoicesFromTransactions(List<DailyTransactionModel> transactions) {
    List<Map<String, dynamic>> deletedList = [];

    for (var tx in transactions) {
      if (tx.type == 'Deleted') {
        // Extraer datos del saleTransactionModel si existe
        final saleModel = tx.saleTransactionModel;

        deletedList.add({
          'invoiceNumber': tx.invoiceNumber ?? saleModel?.invoiceNumber ?? 'N/A',
          'customerName': tx.name ?? saleModel?.customerName ?? 'Cliente desconocido',
          'deletedBy': tx.sellerName ?? 'Desconocido',
          'deletedAt': tx.date ?? '',
          'totalAmount': tx.total,
          'paymentType': tx.paymentType ?? saleModel?.paymentType ?? 'N/A',
          'data': null,
        });
      }
    }

    return deletedList;
  }

  double calculateTotalPaymentIn(List<DailyTransactionModel> dailyTransaction) {
    double total = 0.0;
    for (var element in dailyTransaction) {
      total += element.paymentIn;
    }
    return total;
  }

  double calculateTotalPaymentOut(List<DailyTransactionModel> dailyTransaction) {
    double total = 0.0;
    for (var element in dailyTransaction) {
      total += element.paymentOut;
    }
    return total;
  }

  String searchItem = '';
  String selectedTypeFilter = 'Todos'; // Nuevo filtro por tipo

  DateTimeRange selectedDate = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime.now(),
  );

  Future<void> _selectDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101),
        initialEntryMode: DatePickerEntryMode.calendar,
        builder: (context, child) {
          return Column(
            children: [
              Material(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.hardEdge,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400.0, maxHeight: 600),
                  child: child,
                ),
              )
            ],
          );
        });

    if (picked != null && picked != selectedDate) {
      final DateTime start = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final DateTime end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      setState(() {
        selectedDate = DateTimeRange(start: start, end: end);
      });
    }
  }

  List<String> month = [
    'Hoy',
    'Este mes',
    'Ultimo mes',
    'Ultimos 6 meses',
    'Este año',
    'Ver todo'
  ];

  // Opciones para el filtro por tipo
  Map<String, String> typeFilters = {
    'Todos': 'Todos',
    'Sale': 'Reservas',
    'Adicionales': 'Adicionales',
    'Impresiones': 'Producto',
    'Due Collection': 'Cuentas x Cobrar',
    'Sale Return': 'Devolución de Reserva',
    'Purchase': 'Compras',
    'Purchase Return': 'Devolución de Compra',
    'Due Payment': 'Pago de Adeudo',
    'Expense': 'Gastos',
    'Devolución': 'Devoluciones',
    'Income': 'Ingresos',
  };

  String selectedMonth = 'Hoy';

  DropdownButton<String> getMonth() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in month) {
      var item = DropdownMenuItem(
        value: des,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(des),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      isExpanded: true,
      items: dropDownItems,
      value: selectedMonth,
      onChanged: (value) {
        setState(() {
          selectedMonth = value!;
          switch (selectedMonth) {
            case 'Hoy':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                    end: DateTime.now());
              }
              break;
            case 'Este mes':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                    end: DateTime.now());
              }
              break;
            case 'Ultimo mes':
              {
                final now = DateTime.now();
                final lastMonthStart = DateTime(now.year, now.month - 1, 1);
                final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
                selectedDate = DateTimeRange(
                    start: lastMonthStart,
                    end: lastMonthEnd);
              }
              break;
            case 'Ultimos 6 meses':
              {
                final now = DateTime.now();
                // Calcular 6 meses atrás de manera segura
                int targetYear = now.year;
                int targetMonth = now.month - 6;
                
                // Ajustar año si el mes es <= 0
                if (targetMonth <= 0) {
                  targetYear--;
                  targetMonth += 12;
                }
                
                selectedDate = DateTimeRange(
                    start: DateTime(targetYear, targetMonth, 1),
                    end: DateTime.now());
              }
              break;
            case 'Este año':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(DateTime.now().year, 1, 1),
                    end: DateTime.now());
              }
              break;
            case 'Ver todo':
              {
                selectedDate = DateTimeRange(
                    start: DateTime(1900, 01, 01), end: DateTime.now());
              }
              break;
          }
        });
      },
    );
  }

  // Widget para el filtro por tipo
  DropdownButton<String> getTypeFilter() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    typeFilters.forEach((key, value) {
      var item = DropdownMenuItem(
        value: key,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value),
        ),
      );
      dropDownItems.add(item);
    });
    return DropdownButton(
      isExpanded: true,
      items: dropDownItems,
      value: selectedTypeFilter,
      onChanged: (value) {
        setState(() {
          selectedTypeFilter = value!;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  // Función para traducir el tipo a español
  String translateType(String type) {
    switch (type) {
      case 'Sale':
        return 'Reserva';
      case 'Adicionales':
        return 'Adicionales';
      case 'Impresiones':
        return 'Producto';
      case 'Sale Return':
        return 'Devolución de reserva';
      case 'Purchase':
        return 'Compra';
      case 'Purchase Return':
        return 'Devolución de compra';
      case 'Due Collection':
        return 'Cuenta x Cobrar';
      case 'Due Payment':
        return 'Pago de adeudo';
      case 'Expense':
        return 'Gasto';
      default:
        return type;
    }
  }

  // Función para obtener el tipo traducido considerando categorías especiales
  String getTranslatedType(DailyTransactionModel transaction) {
    // Si es un gasto, verificar si es una devolución de depósito
    if (transaction.type == 'Expense' && transaction.expenseModel != null) {
      final category = transaction.expenseModel!.category.toLowerCase();
      if (category.contains('devolución') || 
          category.contains('devolucion') ||
          category.contains('depósito') || 
          category.contains('deposito') ||
          category.contains('refund') ||
          category.contains('deposit')) {
        return 'Devolución';
      }
    }
    
    // Si no es un caso especial, usar la traducción normal
    return translateType(transaction.type);
  }

  // Función para obtener el tipo de pago de una transacción
  String _getPaymentType(DailyTransactionModel transaction) {
    String paymentType = 'N/A';

    // DEBUG: Verificar qué datos llegan
    if (transaction.type == 'Sale' || transaction.type == 'Producto') {
      debugPrint('💳 _getPaymentType - ID: ${transaction.id}, Type: ${transaction.type}');
      debugPrint('   paymentType directo: "${transaction.paymentType}"');
      debugPrint('   saleModel?.paymentType: "${transaction.saleTransactionModel?.paymentType}"');
    }

    // ✅ PRIMERO: Intentar campo directo del modelo (viene directamente de la API)
    if (transaction.paymentType != null && transaction.paymentType!.isNotEmpty) {
      paymentType = transaction.paymentType!;
    }
    // SEGUNDO: Fallback a modelos anidados (compatibilidad con datos completos)
    else if (transaction.saleTransactionModel != null) {
      paymentType = transaction.saleTransactionModel!.paymentType ?? 'N/A';
    } else if (transaction.dueTransactionModel != null) {
      paymentType = transaction.dueTransactionModel!.paymentType ?? 'N/A';
    } else if (transaction.purchaseTransactionModel != null) {
      paymentType = transaction.purchaseTransactionModel!.paymentType ?? 'N/A';
    } else if (transaction.expenseModel != null) {
      paymentType = transaction.expenseModel!.paymentType ?? 'N/A';
    } else if (transaction.incomeModel != null) {
      paymentType = transaction.incomeModel!.paymentType ?? 'N/A';
    }

    // Traducir tipos de pago comunes al español
    switch (paymentType.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        return 'Efectivo';
      case 'card':
      case 'tarjeta':
      case 'credit card':
        return 'Tarjeta';
      case 'transfer':
      case 'bank transfer':
      case 'transferencia':
      case 'bank':
        return 'Transferencia';
      case 'mobile payment':
        return 'Pago Móvil';
      default:
        return paymentType;
    }
  }

  String _getUserName(DailyTransactionModel transaction) {
    // ✅ PRIMERO: Intentar campo directo del modelo (viene directamente de la API)
    if (transaction.sellerName != null && transaction.sellerName!.isNotEmpty) {
      return transaction.sellerName!;
    }

    // SEGUNDO: Fallback a modelos anidados según el tipo de transacción
    switch (transaction.type) {
      case 'Sale':
      case 'Adicionales':
      case 'Impresiones':
      case 'Sale Return':
        return transaction.saleTransactionModel?.sellerName ?? 'N/A';
      case 'Purchase':
      case 'Purchase Return':
        return transaction.purchaseTransactionModel?.sellerName ?? 'N/A';
      case 'Due Collection':
      case 'Due Payment':
        return transaction.dueTransactionModel?.sellerName ?? 'N/A';
      case 'Expense':
        // ExpenseModel - ahora tiene campo userName
        return transaction.expenseModel?.userName ?? 'N/A';
      case 'Income':
        // IncomeModel - verificar si tiene campo de usuario
        return 'N/A';
      default:
        return 'N/A';
    }
  }

  double _getTotalPendiente(DailyTransactionModel transaction) {
    // Para Due Collection/Payment: usar dueAmountAfterPay directo si está disponible
    if (transaction.type == 'Due Collection' || transaction.type == 'Due Payment') {
      // PRIMERO: Intentar campo directo dueAmountAfterPay (viene de la API)
      if (transaction.dueAmountAfterPay != null && transaction.dueAmountAfterPay! > 0) {
        return transaction.dueAmountAfterPay!;
      }
      // SEGUNDO: Fallback a modelo anidado
      return transaction.dueTransactionModel?.dueAmountAfterPay ?? 0.0;
    }

    // Para ventas (Sale, Adicionales, Impresiones, Reserva, Producto):
    // CÁLCULO CORRECTO: total - paymentIn (no confiar en remaining_balance de BD que puede estar mal)
    if (transaction.type == 'Sale' ||
        transaction.type == 'Adicionales' ||
        transaction.type == 'Impresiones' ||
        transaction.type == 'Reserva' ||
        transaction.type == 'Producto') {
      // Calcular pendiente como total - pago entrante
      // Esto es más confiable que remaining_balance que puede tener datos incorrectos
      final calculatedPending = transaction.total - transaction.paymentIn;
      if (calculatedPending > 0) {
        return calculatedPending;
      }
      // Si el cálculo da 0 o negativo, verificar con dueAmount
      if (transaction.dueAmount != null && transaction.dueAmount! > 0) {
        return transaction.dueAmount!;
      }
      // Fallback a modelo anidado
      return transaction.saleTransactionModel?.dueAmount ?? 0.0;
    }

    // Para otros tipos: usar dueAmount directo si está disponible
    if (transaction.dueAmount != null && transaction.dueAmount! > 0) {
      return transaction.dueAmount!;
    }

    // Fallback a modelos anidados según el tipo de transacción
    switch (transaction.type) {
      case 'Purchase':
      case 'Purchase Return':
        return transaction.remainingBalance;
      case 'Expense':
      case 'Income':
        return 0.0;
      default:
        return transaction.remainingBalance;
    }
  }

  final _horizontalScroll = ScrollController();
  int _lossProfitPerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (_, ref, watch) {
      final dailyTransactionReport = ref.watch(dailyTransactionProvider);
      final salesTransactionReport = ref.watch(transitionProvider);
      final profile = ref.watch(profileDetailsProvider);
      final settingProvider = ref.watch(generalSettingProvider);
      // Provider de transferencias verificadas para obtener bankName
      final transferVerifications = ref.watch(transferVerificationsProvider);
      return dailyTransactionReport.when(
        data: (dailyReport) {
          return salesTransactionReport.when(
            data: (salesReport) {
              List<DailyTransactionModel> reTransaction = [];
              
              // Función para convertir SaleTransactionModel a DailyTransactionModel
              DailyTransactionModel convertSaleToDaily(SaleTransactionModel sale) {
                // DEBUG: Verificar qué datos tiene la venta
                debugPrint('🔄 convertSaleToDaily - Invoice: ${sale.invoiceNumber}, saleType: "${sale.saleType}", paymentType: "${sale.paymentType}", sellerName: "${sale.sellerName}"');

                // Mapear saleType a type correcto
                String type;
                switch (sale.saleType?.toLowerCase()) {
                  case 'adicionales':
                    type = 'Adicionales';
                    break;
                  case 'impresiones':
                    type = 'Impresiones';
                    break;
                  case 'reserva':
                    type = 'Reserva';
                    break;
                  default:
                    type = 'Sale';
                }

                // Calcular el monto pagado: total - due (pendiente)
                final paidAmount = (sale.totalAmount ?? 0.0) - (sale.dueAmount ?? 0.0);

                return DailyTransactionModel(
                  name: sale.customerName,
                  date: sale.purchaseDate,
                  type: type,
                  total: sale.totalAmount ?? 0.0,
                  paymentIn: paidAmount, // ✅ CORREGIDO: Mostrar el monto pagado, no el total
                  paymentOut: 0.0,
                  remainingBalance: sale.dueAmount ?? 0.0,
                  id: sale.invoiceNumber,
                  // ✅ Pasar campos directos para mostrar en la tabla
                  paymentType: sale.paymentType,
                  sellerName: sale.sellerName,
                  invoiceNumber: sale.invoiceNumber,
                  dueAmount: sale.dueAmount,
                  saleTransactionModel: sale,
                );
              }

              // LOGGING PARA VALIDACIÓN
              debugPrint('=== ANÁLISIS DE FUENTES DE DATOS ===');
              debugPrint('📊 Daily Transactions encontradas: ${dailyReport.length}');
              debugPrint('📊 Sales Transitions encontradas: ${salesReport.length}');
              debugPrint('📅 Filtro de fecha: ${selectedDate.start.toString().substring(0, 10)} a ${selectedDate.end.toString().substring(0, 10)}');
              debugPrint('🔍 Filtro de tipo: $selectedTypeFilter');
              
              // Contar ventas en Daily Transactions
              int salesInDaily = dailyReport.where((t) => t.type == 'Sale').length;
              debugPrint('💰 Ventas en Daily Transaction: $salesInDaily');
              
              // Mostrar algunos ejemplos de facturas en Sales Transition
              var recentSales = salesReport.take(5).map((s) => s.invoiceNumber).toList();
              debugPrint('🧾 Ejemplos de facturas en Sales Transition: $recentSales');
              
              // 🔍 VALIDACIÓN DE FACTURAS CON ERRORES
              _problematicInvoices.clear(); // Limpiar lista anterior
              debugPrint('\n=== VALIDACIÓN DE FACTURAS ===');
              for (var transaction in dailyReport.where((t) => t.type == 'Sale')) {
                if (transaction.saleTransactionModel != null) {
                  final saleModel = transaction.saleTransactionModel!;
                  final hasProducts = saleModel.productList != null && saleModel.productList!.isNotEmpty;
                  debugPrint('📋 Factura ${saleModel.invoiceNumber}: productos=${saleModel.productList?.length ?? 0}, válida=$hasProducts');
                  
                  if (!hasProducts) {
                    debugPrint('❌ FACTURA PROBLEMÁTICA: ${saleModel.invoiceNumber} - SIN PRODUCTOS');
                    // Buscar en Sales Transition si existe una versión completa
                    final fullSale = salesReport.where((s) => s.invoiceNumber == saleModel.invoiceNumber).firstOrNull;
                    if (fullSale != null && fullSale.productList != null && fullSale.productList!.isNotEmpty) {
                      debugPrint('✅ Versión completa encontrada en Sales Transition con ${fullSale.productList!.length} productos');
                    } else {
                      debugPrint('💀 FACTURA CORRUPTA: ${saleModel.invoiceNumber} - NO EXISTE EN SALES TRANSITION O TAMBIÉN SIN PRODUCTOS');
                      // Marcar para eliminación
                      _problematicInvoices.add(saleModel.invoiceNumber);
                    }
                  }
                } else {
                  debugPrint('❌ TRANSACCIÓN SIN SALE MODEL: ${transaction.id}');
                }
              }
              
              // Mostrar resumen de facturas problemáticas
              if (_problematicInvoices.isNotEmpty) {
                debugPrint('\n🚨 RESUMEN DE FACTURAS PROBLEMÁTICAS:');
                debugPrint('📊 Total de facturas con problemas: ${_problematicInvoices.length}');
                debugPrint('📋 Facturas: ${_problematicInvoices.join(", ")}');
                
                // Mostrar botón para eliminar facturas problemáticas
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showDeleteProblematicInvoicesDialog();
                });
              }

              // NUEVO: Limpiar facturas huérfanas automáticamente (COMENTADO DESPUÉS DE USAR)
              // WidgetsBinding.instance.addPostFrameCallback((_) {
              //   _cleanOrphanInvoices();
              // });

              // NUEVO: Corregir saldos negativos automáticamente (TEMPORAL)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fixNegativeBalances();
              });

              // Primero agregar todas las transacciones diarias existentes
              // Usar Set para evitar duplicados basados en ID
              Set<String> addedTransactionIds = {};

              for (var element in dailyReport.reversed.toList()) {
            if (element.date.isNotEmpty) {
              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(element.date);
              } catch (e) {
                // Log para debugging - comentar en producción
                // print('Error parsing date: ${element.date} for ${element.name} - $e');
                continue;
              }

              if ((selectedDate.start.isBefore(parsedDate) ||
                      parsedDate.isAtSameMomentAs(selectedDate.start)) &&
                  (selectedDate.end.isAfter(parsedDate) ||
                      parsedDate.isAtSameMomentAs(selectedDate.end))) {
                // Aplicar filtro por tipo si no es "Todos"
                bool matchesTypeFilter = false;

                if (selectedTypeFilter == 'Todos') {
                  matchesTypeFilter = true;
                } else if (selectedTypeFilter == 'Devolución') {
                  // Caso especial para devoluciones: verificar si es un gasto de tipo devolución
                  if (element.type == 'Expense' && element.expenseModel != null) {
                    final category = element.expenseModel!.category.toLowerCase();
                    matchesTypeFilter = category.contains('devolución') ||
                                      category.contains('devolucion') ||
                                      category.contains('depósito') ||
                                      category.contains('deposito') ||
                                      category.contains('refund') ||
                                      category.contains('deposit');
                  }
                } else {
                  // Para otros filtros, comparar el tipo directamente
                  matchesTypeFilter = element.type == selectedTypeFilter;
                }

                // Evitar duplicados: solo agregar si el ID no está ya en la lista
                if (matchesTypeFilter && !addedTransactionIds.contains(element.id)) {
                  addedTransactionIds.add(element.id);
                  reTransaction.add(element);
                }
              }
            }
          }

          debugPrint('✅ Daily Transactions procesadas: ${reTransaction.length}');
          debugPrint('💰 Ventas en reTransaction desde Daily: ${reTransaction.where((t) => t.type == 'Sale').length}');

          // Agregar ventas del transitionProvider que no estén ya en dailyReport
          // ✅ FIX: Extraer invoiceNumber correctamente de campos directos o modelos anidados
          Set<String> existingInvoiceNumbers = {};
          for (var t in reTransaction.where((t) => t.type == 'Sale' || t.type == 'Adicionales' || t.type == 'Impresiones' || t.type == 'Reserva')) {
            // Prioridad: campo directo invoiceNumber > saleTransactionModel.invoiceNumber > id
            final invoice = t.invoiceNumber ?? t.saleTransactionModel?.invoiceNumber ?? t.id;
            debugPrint('🔍 Extrayendo factura - Type: ${t.type}, invoiceNumber: ${t.invoiceNumber}, saleModel.invoice: ${t.saleTransactionModel?.invoiceNumber}, usando: $invoice');
            if (invoice.isNotEmpty) {
              existingInvoiceNumbers.add(invoice);
            }
          }

          for (var sale in salesReport.reversed.toList()) {
            // Solo agregar si no está ya en reTransaction
            if (!existingInvoiceNumbers.contains(sale.invoiceNumber)) {
              // Aplicar los mismos filtros de fecha y tipo
              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(sale.purchaseDate);
              } catch (e) {
                continue; // Saltar si la fecha no es válida
              }

              // Filtro por rango de fecha
              if ((selectedDate.start.isBefore(parsedDate) || parsedDate.isAtSameMomentAs(selectedDate.start)) &&
                  (selectedDate.end.isAfter(parsedDate) || parsedDate.isAtSameMomentAs(selectedDate.end))) {
                
                // Convertir sale a daily para obtener el tipo correcto
                DailyTransactionModel dailyFromSale = convertSaleToDaily(sale);
                
                // Filtro por tipo
                if (selectedTypeFilter == 'Todos' || 
                    selectedTypeFilter == dailyFromSale.type) {
                  reTransaction.add(dailyFromSale);
                }
              }
            }
          }

          debugPrint('🔄 Facturas ya existentes en Daily: $existingInvoiceNumbers');
          debugPrint('✅ Total después de agregar Sales Transition: ${reTransaction.length}');
          debugPrint('💰 Total de ventas combinadas: ${reTransaction.where((t) => t.type == 'Sale' || t.type == 'Adicionales' || t.type == 'Impresiones').length}');
          
          // Mostrar algunas facturas de ejemplo que se agregaron
          var addedSales = reTransaction
              .where((t) => (t.type == 'Sale' || t.type == 'Adicionales' || t.type == 'Impresiones') && !existingInvoiceNumbers.contains(t.id))
              .take(3)
              .map((t) => t.id)
              .toList();
          debugPrint('🆕 Ejemplos de facturas agregadas desde Sales Transition: $addedSales');

          // Apply search filter
          if (searchItem.isNotEmpty) {
            final searchLower = searchItem.toLowerCase();
            reTransaction = reTransaction.where((element) {
              // Búsqueda por teléfono a través de modelos anidados
              final customerPhone = element.saleTransactionModel?.customerPhone ??
                                   element.dueTransactionModel?.customerPhone ??
                                   '';
              final invoiceNum = element.invoiceNumber ?? '';

              return element.name.toLowerCase().contains(searchLower) ||
                  customerPhone.toLowerCase().contains(searchLower) ||
                  invoiceNum.toLowerCase().contains(searchLower) ||
                  element.date.toLowerCase().contains(searchLower) ||
                  translateType(element.type).toLowerCase().contains(searchLower) ||
                  _getPaymentType(element).toLowerCase().contains(searchLower) ||
                  _getUserName(element).toLowerCase().contains(searchLower) ||
                  element.id.toLowerCase().contains(searchLower) ||
                  element.total.toString().toLowerCase().contains(searchLower) ||
                  element.paymentIn.toString().toLowerCase().contains(searchLower) ||
                  element.paymentOut.toString().toLowerCase().contains(searchLower) ||
                  element.remainingBalance.toString().toLowerCase().contains(searchLower) ||
                  _getTotalPendiente(element).toString().toLowerCase().contains(searchLower);
            }).toList();
            debugPrint('🔍 Después del filtro de búsqueda "$searchItem": ${reTransaction.length} transacciones');
          } else {
            debugPrint('🔍 Sin filtro de búsqueda: ${reTransaction.length} transacciones');
          }

          debugPrint('📋 RESULTADO FINAL: ${reTransaction.length} transacciones mostradas');
          debugPrint('💰 Ventas finales: ${reTransaction.where((t) => t.type == 'Sale' || t.type == 'Adicionales' || t.type == 'Impresiones').length}');

          // Mostrar facturas específicas que se están buscando
          var salesInResult = reTransaction.where((t) => t.type == 'Sale' || t.type == 'Adicionales' || t.type == 'Impresiones').map((t) => t.id).toList();
          debugPrint('🧾 Facturas mostradas: ${salesInResult.take(10).toList()}${salesInResult.length > 10 ? '... y ${salesInResult.length - 10} más' : ''}');

          // Verificar específicamente la factura 516
          bool has516 = reTransaction.any((t) => t.id == '516');
          debugPrint('🎯 ¿Incluye factura 516?: $has516');

          // Ordenar por fecha descendente (más recientes primero)
          reTransaction.sort((a, b) {
            try {
              // Intentar parsear las fechas (formato: DD-MM-YYYY HH:MM:SS o YYYY-MM-DD HH:MM:SS)
              DateTime dateA;
              DateTime dateB;

              if (a.date.contains('-') && a.date.split('-')[0].length == 4) {
                // Formato ISO: YYYY-MM-DD
                dateA = DateTime.tryParse(a.date) ?? DateTime(1900);
              } else {
                // Formato DD-MM-YYYY
                final partsA = a.date.split(' ')[0].split('-');
                if (partsA.length >= 3) {
                  dateA = DateTime(int.tryParse(partsA[2]) ?? 1900, int.tryParse(partsA[1]) ?? 1, int.tryParse(partsA[0]) ?? 1);
                } else {
                  dateA = DateTime(1900);
                }
              }

              if (b.date.contains('-') && b.date.split('-')[0].length == 4) {
                dateB = DateTime.tryParse(b.date) ?? DateTime(1900);
              } else {
                final partsB = b.date.split(' ')[0].split('-');
                if (partsB.length >= 3) {
                  dateB = DateTime(int.tryParse(partsB[2]) ?? 1900, int.tryParse(partsB[1]) ?? 1, int.tryParse(partsB[0]) ?? 1);
                } else {
                  dateB = DateTime(1900);
                }
              }

              return dateB.compareTo(dateA); // Descendente (más reciente primero)
            } catch (e) {
              return 0;
            }
          });

          final pages = _lossProfitPerPage == -1
              ? 1
              : (reTransaction.length / _lossProfitPerPage).ceil();
          final startIndex = _lossProfitPerPage == -1
              ? 0
              : (_currentPage - 1) * _lossProfitPerPage;
          final endIndex = _lossProfitPerPage == -1
              ? reTransaction.length
              : (startIndex + _lossProfitPerPage)
                  .clamp(0, reTransaction.length);

          final paginatedList = reTransaction.sublist(startIndex, endIndex);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtros en Row para usar ancho completo
                      Row(
                        children: [
                          // Filtro de mes
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SizedBox(
                                height: 48,
                                child: FormField(
                                  builder: (FormFieldState<dynamic> field) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(),
                                      child: Theme(
                                          data: ThemeData(
                                              highlightColor: dropdownItemColor,
                                              focusColor: dropdownItemColor,
                                              hoverColor: dropdownItemColor),
                                          child: DropdownButtonHideUnderline(
                                              child: getMonth())),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Filtro por tipo
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SizedBox(
                                height: 48,
                                child: FormField(
                                  builder: (FormFieldState<dynamic> field) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(),
                                      child: Theme(
                                          data: ThemeData(
                                              highlightColor: dropdownItemColor,
                                              focusColor: dropdownItemColor,
                                              hoverColor: dropdownItemColor),
                                          child: DropdownButtonHideUnderline(
                                              child: getTypeFilter())),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Filtro de fecha
                          Expanded(
                            flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(color: kGreyTextColor)),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.all(4),
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          color: kGreyTextColor),
                                      child: Center(
                                        child: Text(
                                          lang.S.of(context).between,
                                          style: kTextStyle.copyWith(
                                              color: kWhite),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10.0),
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () => _selectDate(context),
                                        child: RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.titleSmall,
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${selectedDate.start.day}/${selectedDate.start.month}/${selectedDate.start.year} ',
                                                style:
                                                    theme.textTheme.titleSmall,
                                              ),
                                              TextSpan(
                                                  text: lang.S.of(context).to),
                                              TextSpan(
                                                text:
                                                    ' ${selectedDate.end.day}/${selectedDate.end.month}/${selectedDate.end.year}',
                                                style:
                                                    theme.textTheme.titleSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )),
                          ),
                          ),
                        ],
                      ),
                      // Comentado: Tarjetas de Saldo Restante, Pago Total Saliente y Pago Entrante
                      /*
                      ResponsiveGridRow(rowSegments: 100, children: [
                        ResponsiveGridCol(
                          xs: 100,
                          md: screenWidth < 950 ? 30 : 20,
                          lg: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: const EdgeInsets.only(
                                  left: 10.0,
                                  right: 20.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color(0xFFCFF4E3),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    reTransaction.isNotEmpty
                                        ? '$globalCurrency${myFormat.format(double.tryParse(reTransaction.first.remainingBalance.toStringAsFixed(2))?.abs() ?? 0)}'
                                        : '0',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    lang.S.of(context).remainingBalance,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: screenWidth < 950 ? 30 : 20,
                          lg: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: const EdgeInsets.only(
                                  left: 10.0,
                                  right: 20.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color.fromARGB(143, 243, 110, 66),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$globalCurrency ${reTransaction.isNotEmpty ? myFormat.format(double.tryParse(calculateTotalPaymentOut(reTransaction).toStringAsFixed(2)) ?? 0) : 0}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        color: kTitleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    lang.S.of(context).totalpaymentIn,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: screenWidth < 950 ? 30 : 20,
                          lg: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: const EdgeInsets.only(
                                  left: 10.0,
                                  right: 20.0,
                                  top: 10.0,
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color.fromARGB(131, 95, 226, 47),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$globalCurrency ${reTransaction.isNotEmpty ? myFormat.format(double.tryParse(calculateTotalPaymentIn(reTransaction).toStringAsFixed(2)) ?? 0) : 0}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    lang.S.of(context).totalPaymentOut,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                      */
                      // Nuevas tarjetas de métricas de pagos
                      Consumer(builder: (_, ref, __) {
                        // Calcular métricas de pagos desde las transacciones filtradas
                        final summary = DailySummaryModel.fromDailyTransactions(reTransaction);
                        
                        return ResponsiveGridRow(rowSegments: 100, children: [
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFF2196F3), width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long, color: const Color(0xFF2196F3), size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$globalCurrency ${myFormat.format(summary.totalFacturado)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                          color: const Color(0xFF2196F3),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      'Total Facturado',
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$globalCurrency ${myFormat.format(summary.totalPagado)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                          color: const Color(0xFF4CAF50),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      'Total Pagado',
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFFFF9800), width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pending_actions, color: const Color(0xFFFF9800), size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$globalCurrency ${myFormat.format(summary.totalPendiente)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                          color: const Color(0xFFFF9800),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      'Total Pendiente',
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
            ),
                          ),
                        ]);
                      }),
                      Consumer(builder: (_, ref, __) {
                        // Segunda fila con los métodos de pago
                        final summary = DailySummaryModel.fromDailyTransactions(reTransaction);
                        
                        return ResponsiveGridRow(rowSegments: 100, children: [
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _showCashDetailsDialog(context, summary, reTransaction);
                                  },
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                      border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.money, color: const Color(0xFF4CAF50), size: 24),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$globalCurrency ${myFormat.format(summary.ingresoEfectivo - summary.gastoEfectivo)}',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                              color: const Color(0xFF4CAF50),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Efectivo Neto',
                                          style: theme.textTheme.bodyMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    print('DEBUG: Click en tarjeta de transferencias');
                                    print('DEBUG: Total transferencias: ${summary.pagoTransferencia}');

                                    // Crear mapa de invoiceNumber -> bankName desde transfer_verifications
                                    final transferVerificationsList = transferVerifications.valueOrNull ?? [];
                                    final Map<String, String> invoiceToBankName = {};
                                    for (var tv in transferVerificationsList) {
                                      if (tv.invoiceNumber.isNotEmpty && tv.bankName.isNotEmpty) {
                                        invoiceToBankName[tv.invoiceNumber] = tv.bankName;
                                      }
                                    }
                                    print('DEBUG: Mapa de transferencias verificadas: ${invoiceToBankName.length} registros');

                                    // Crear un mapa con las transacciones del día
                                    Map<String, dynamic> dailyTransactions = {};
                                    int transferCount = 0;
                                    for (var transaction in reTransaction) {
                                      // DEBUG: Mostrar todos los campos disponibles
                                      print('DEBUG TX: type=${transaction.type}, paymentType=${transaction.paymentType}, dueModel=${transaction.dueTransactionModel != null}, saleModel=${transaction.saleTransactionModel != null}');

                                      // Verificar si es una transferencia
                                      // Prioridad: modelo anidado > campo directo del DailyTransactionModel
                                      String? paymentType;
                                      String? bankId;
                                      String? bankName;
                                      String? customerName;
                                      String? invoiceNumber;

                                      if (transaction.saleTransactionModel != null) {
                                        paymentType = transaction.saleTransactionModel!.paymentType;
                                        bankId = transaction.saleTransactionModel!.bankId;
                                        bankName = transaction.saleTransactionModel!.bankName;
                                        customerName = transaction.saleTransactionModel!.customerName;
                                        invoiceNumber = transaction.saleTransactionModel!.invoiceNumber;
                                      } else if (transaction.dueTransactionModel != null) {
                                        paymentType = transaction.dueTransactionModel!.paymentType;
                                        bankId = transaction.dueTransactionModel!.bankId;
                                        bankName = transaction.dueTransactionModel!.bankName;
                                        customerName = transaction.dueTransactionModel!.customerName;
                                        invoiceNumber = transaction.dueTransactionModel!.invoiceNumber;
                                        print('DEBUG: dueTransactionModel.paymentType = $paymentType');
                                      }

                                      // Fallback: usar campos directos del DailyTransactionModel si los modelos están vacíos
                                      paymentType ??= transaction.paymentType;
                                      invoiceNumber ??= transaction.invoiceNumber;
                                      // CRÍTICO: Extraer bankId y bankName de campos directos del DailyTransactionModel
                                      // Estos campos ahora están en el modelo y se extraen del JSON del API
                                      bankId ??= transaction.bankId;
                                      bankName ??= transaction.bankName;
                                      customerName ??= transaction.name;

                                      // FALLBACK EXTRA: Si bankName sigue siendo null y es una transferencia,
                                      // buscar en múltiples fuentes
                                      if ((bankName == null || bankName!.isEmpty) && paymentType != null &&
                                          (paymentType.toLowerCase().contains('transfer') ||
                                           paymentType.toLowerCase().contains('transferencia'))) {
                                        // 1. Buscar en transfer_verifications (fuente más confiable)
                                        if (invoiceNumber != null && invoiceToBankName.containsKey(invoiceNumber)) {
                                          bankName = invoiceToBankName[invoiceNumber];
                                          debugPrint('DEBUG: Lookup desde transfer_verifications - invoiceNumber: $invoiceNumber, bankName: $bankName');
                                        }
                                        // 2. Si aún no hay bankName, buscar en salesReport
                                        if ((bankName == null || bankName!.isEmpty) && invoiceNumber != null) {
                                          final saleFromReport = salesReport.firstWhere(
                                            (s) => s.invoiceNumber == invoiceNumber,
                                            orElse: () => SaleTransactionModel(
                                              customerName: '', customerPhone: '', customerType: '',
                                              customerAddress: '', customerImage: '', customerGst: '',
                                              invoiceNumber: '', purchaseDate: '', paymentType: '',
                                            ),
                                          );
                                          if (saleFromReport.invoiceNumber.isNotEmpty) {
                                            bankId = saleFromReport.bankId;
                                            bankName = saleFromReport.bankName;
                                            debugPrint('DEBUG: Lookup desde salesReport - bankId: $bankId, bankName: $bankName');
                                          }
                                        }
                                      }
                                      print('DEBUG: Final paymentType = $paymentType (directo: ${transaction.paymentType})');
                                      print('DEBUG: Final bankId = $bankId, bankName = $bankName (directo: ${transaction.bankId}, ${transaction.bankName})');

                                      if (paymentType != null &&
                                          (paymentType.toLowerCase().contains('transfer') ||
                                           paymentType.toLowerCase().contains('transferencia'))) {
                                        transferCount++;
                                        print('DEBUG: Transferencia encontrada - ID: ${transaction.id}, PaymentType: $paymentType');
                                        print('DEBUG: BankId: $bankId, BankName: $bankName');
                                      }

                                      // Incluir campos directos además de los modelos anidados
                                      dailyTransactions[transaction.id] = {
                                        'type': transaction.type,
                                        'saleTransactionModel': transaction.saleTransactionModel?.toJson(),
                                        'dueTransactionModel': transaction.dueTransactionModel?.toJson(),
                                        'purchaseTransactionModel': transaction.purchaseTransactionModel?.toJson(),
                                        'paymentIn': transaction.paymentIn,
                                        'paymentOut': transaction.paymentOut,
                                        'time': transaction.date,
                                        // Campos directos como fallback
                                        'paymentType': paymentType,
                                        'bankId': bankId,
                                        'bankName': bankName,
                                        'customerName': customerName ?? transaction.name,
                                        'invoiceNumber': invoiceNumber,
                                      };
                                    }
                                    
                                    print('DEBUG: Total transacciones procesadas: ${reTransaction.length}');
                                    print('DEBUG: Total transferencias encontradas: $transferCount');
                                    
                                    // Imprimir una transacción de ejemplo para verificar estructura
                                    if (reTransaction.isNotEmpty) {
                                      var firstTransaction = reTransaction.first;
                                      print('DEBUG: Ejemplo de transacción:');
                                      print('  - Type: ${firstTransaction.type}');
                                      print('  - ID: ${firstTransaction.id}');
                                      print('  - PaymentIn: ${firstTransaction.paymentIn}');
                                      print('  - Date: ${firstTransaction.date}');
                                    }
                                    
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (BuildContext dialogContext) {
                                        return TransferDetailsDialog(
                                          dailyTransactions: dailyTransactions,
                                        );
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: const Color(0xFF009688).withValues(alpha: 0.1),
                                      border: Border.all(color: const Color(0xFF009688), width: 1),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.account_balance, color: const Color(0xFF009688), size: 24),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$globalCurrency ${myFormat.format(summary.pagoTransferencia)}',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                              color: const Color(0xFF009688),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Transferencias',
                                          style: theme.textTheme.bodyMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Click para ver detalles',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFF009688),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFF9C27B0), width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.credit_card, color: const Color(0xFF9C27B0), size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$globalCurrency ${myFormat.format(summary.pagoTarjetas)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                          color: const Color(0xFF9C27B0),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      'Pago Tarjetas',
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }),
                      // Tercera fila: Facturas Eliminadas (usa summary calculado de reTransaction)
                      Consumer(builder: (context, consumerRef, _) {
                        // Calcular el count de eliminadas desde las transacciones filtradas
                        final deletedList = _buildDeletedInvoicesFromTransactions(reTransaction);
                        final deletedCount = deletedList.length;

                        return ResponsiveGridRow(rowSegments: 100, children: [
                          ResponsiveGridCol(
                            xs: 100,
                            md: screenWidth < 950 ? 50 : 33,
                            lg: 33,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _showDeletedInvoicesDialog(context, deletedList, ref: consumerRef);
                                  },
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                      border: Border.all(color: const Color(0xFFE53935), width: 1),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete_outline, color: const Color(0xFFE53935), size: 24),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$deletedCount',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                              color: const Color(0xFFE53935),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Facturas Eliminadas',
                                          style: theme.textTheme.bodyMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Click para ver detalles',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFFE53935),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          lang.S.of(context).dailyTransaction,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(
                        thickness: 1.0,
                        color: kNeutral300,
                        height: 1,
                      ),
                      const ExportButton().visible(false),
                      
                      // Botón temporal para buscar transacciones huérfanas
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showOrphanTransactions(ref),
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar Transacciones Huérfanas'),
                        ),
                      ),

                      ///___________search________________________________________________-
                      ResponsiveGridRow(rowSegments: 100, children: [
                        ResponsiveGridCol(
                          xs: screenWidth < 360
                              ? 50
                              : screenWidth > 430
                                  ? 33
                                  : 40,
                          md: screenWidth < 768
                              ? 24
                              : screenWidth < 950
                                  ? 20
                                  : 15,
                          lg: screenWidth < 1700 ? 15 : 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 48,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: kNeutral300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: Text(
                                    'Mostrar-',
                                    style: theme.textTheme.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  DropdownButton<int>(
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    underline: const SizedBox(),
                                    value: _lossProfitPerPage,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                    items: [
                                      10,
                                      20,
                                      50,
                                      100,
                                      -1
                                    ].map<DropdownMenuItem<int>>((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text(
                                          value == -1
                                              ? "All"
                                              : value.toString(),
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        if (newValue == -1) {
                                          _lossProfitPerPage =
                                              -1; // Set to -1 for "All"
                                        } else {
                                          _lossProfitPerPage = newValue ?? 10;
                                        }
                                        _currentPage = 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ResponsiveGridCol(
                          xs: 100,
                          md: 60,
                          lg: 35,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: true,
                              cursorColor: kTitleColor,
                              onChanged: (value) {
                                setState(() {
                                  searchItem = value;
                                });
                              },
                              keyboardType: TextInputType.name,
                              decoration: kInputDecoration.copyWith(
                                contentPadding: const EdgeInsets.all(10.0),
                                hintText: 'Buscar por nombre, teléfono o # factura...',
                                border: InputBorder.none,
                                suffixIcon: const Icon(
                                  FeatherIcons.search,
                                  color: kTitleColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),

                      reTransaction.isNotEmpty
                          ? Column(
                              children: [
                                LayoutBuilder(
                                  builder: (BuildContext context,
                                      BoxConstraints constraints) {
                                    return Scrollbar(
                                      controller: _horizontalScroll,
                                      thumbVisibility: true,
                                      radius: const Radius.circular(8),
                                      thickness: 8,
                                      child: SingleChildScrollView(
                                        controller: _horizontalScroll,
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: Theme(
                                            data: theme.copyWith(
                                              dividerColor: Colors.transparent,
                                              dividerTheme:
                                                  const DividerThemeData(
                                                      color:
                                                          Colors.transparent),
                                            ),
                                            child: DataTable(
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  width: 1,
                                                  color: kNeutral300,
                                                ),
                                              ),
                                              dataRowColor:
                                                  const WidgetStatePropertyAll(
                                                      Colors.white),
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                      const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle:
                                                  theme.textTheme.titleMedium,
                                              columns: [
                                                DataColumn(
                                                    label: Text(
                                                        lang.S.of(context).SL)),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).name,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).date,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).type,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Tipo de Pago',
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Usuario',
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Nº Factura',
                                                    style: TextStyle(
                                                      color: Colors.blue.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).total,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S
                                                        .of(context)
                                                        .paymentIn,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Total Pendiente',
                                                    style: TextStyle(
                                                      color: Colors.red.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S
                                                        .of(context)
                                                        .paymentOut,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    lang.S.of(context).action,
                                                  ),
                                                ),
                                              ],
                                              rows: List.generate(
                                                paginatedList.length,
                                                (index) => DataRow(cells: [
                                                            DataCell(Text(
                                                                '${startIndex + index + 1}')),
                                                            DataCell(
                                                              Text(
                                                                paginatedList[
                                                                        index]
                                                                    .name,
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                paginatedList[
                                                                        index]
                                                                    .date
                                                                    .substring(
                                                                        0, 10),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                getTranslatedType(paginatedList[index]),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                _getPaymentType(paginatedList[index]),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                _getUserName(paginatedList[index]),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              _buildInvoiceNumberCell(paginatedList[index], context, profile, settingProvider),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].total.toStringAsFixed(2)) ?? 0)}',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                myFormat.format(double.tryParse(paginatedList[index].paymentIn.toStringAsFixed(2)) ?? 0) == '0'
                                                                    ? ''
                                                                    : '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].paymentIn.toStringAsFixed(2)) ?? 0)}',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                                decoration: BoxDecoration(
                                                                  color: _getTotalPendiente(paginatedList[index]) > 0 
                                                                      ? Colors.red.shade50 
                                                                      : Colors.transparent,
                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                  border: _getTotalPendiente(paginatedList[index]) > 0 
                                                                      ? Border.all(color: Colors.red.shade200, width: 1)
                                                                      : null,
                                                                ),
                                                                child: Text(
                                                                  _getTotalPendiente(paginatedList[index]) == 0
                                                                      ? '-'
                                                                      : '$globalCurrency${myFormat.format(_getTotalPendiente(paginatedList[index]))}',
                                                                  style: TextStyle(
                                                                    color: _getTotalPendiente(paginatedList[index]) > 0 
                                                                        ? Colors.red.shade800 
                                                                        : Colors.grey.shade600,
                                                                    fontWeight: _getTotalPendiente(paginatedList[index]) > 0 
                                                                        ? FontWeight.bold 
                                                                        : FontWeight.normal,
                                                                    fontSize: _getTotalPendiente(paginatedList[index]) > 0 
                                                                        ? 13 
                                                                        : 12,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                myFormat.format(double.tryParse(paginatedList[index].paymentOut.toStringAsFixed(2)) ?? 0) == '0'
                                                                    ? ''
                                                                    : '$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].paymentOut.toStringAsFixed(2)) ?? 0)}',
                                                              ),
                                                            ),
                                                            DataCell(
                                                                settingProvider
                                                                    .when(data:
                                                                        (setting) {
                                                              return Theme(
                                                                data: ThemeData(
                                                                    highlightColor:
                                                                        dropdownItemColor,
                                                                    focusColor:
                                                                        dropdownItemColor,
                                                                    hoverColor:
                                                                        dropdownItemColor),
                                                                child:
                                                                    PopupMenuButton(
                                                                  surfaceTintColor:
                                                                      Colors
                                                                          .white,
                                                                  icon: const Icon(
                                                                      FeatherIcons
                                                                          .moreVertical,
                                                                      size:
                                                                          18.0),
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                              bc) =>
                                                                          [
                                                                    PopupMenuItem(
                                                                      onTap:
                                                                          () async {
                                                                        final messenger = ScaffoldMessenger.of(context);
                                                                        try {
                                                                          // Mostrar indicador de carga
                                                                          messenger.showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Generando PDF...'),
                                                                              duration: Duration(seconds: 2),
                                                                              backgroundColor: Colors.blue,
                                                                            ),
                                                                          );

                                                                          if (paginatedList[index].type == 'Sale' || paginatedList[index].type == 'Adicionales' || paginatedList[index].type == 'Impresiones') {
                                                                            // Verificar que el modelo de venta no sea nulo
                                                                            if (paginatedList[index].saleTransactionModel == null) {
                                                                              throw Exception('Los datos de la venta no están disponibles');
                                                                            }
                                                                            
                                                                            await GeneratePdfAndPrint().printSaleInvoice(
                                                                                personalInformationModel: profile.value!,
                                                                                setting: setting,
                                                                                saleTransactionModel: paginatedList[index].saleTransactionModel!,
                                                                                context: context,
                                                                                fromSaleReports: true);
                                                                          } else if (paginatedList[index].type == 'Sale Return') {
                                                                            if (paginatedList[index].saleTransactionModel == null) {
                                                                              throw Exception('Los datos de devolución de venta no están disponibles');
                                                                            }
                                                                            
                                                                            await GeneratePdfAndPrint().printSaleReturnInvoice(
                                                                                setting: setting,
                                                                                personalInformationModel: profile.value!,
                                                                                saleTransactionModel: paginatedList[index].saleTransactionModel!);
                                                                          } else if (paginatedList[index].type == 'Purchase') {
                                                                            if (paginatedList[index].purchaseTransactionModel == null) {
                                                                              throw Exception('Los datos de compra no están disponibles');
                                                                            }
                                                                            
                                                                            await GeneratePdfAndPrint().printPurchaseInvoice(
                                                                                setting: setting,
                                                                                personalInformationModel: profile.value!,
                                                                                purchaseTransactionModel: paginatedList[index].purchaseTransactionModel!);
                                                                          } else if (paginatedList[index].type == 'Purchase Return') {
                                                                            if (paginatedList[index].purchaseTransactionModel == null) {
                                                                              throw Exception('Los datos de devolución de compra no están disponibles');
                                                                            }
                                                                            
                                                                            await GeneratePdfAndPrint().printPurchaseReturnInvoice(
                                                                                setting: setting,
                                                                                personalInformationModel: profile.value!,
                                                                                purchaseTransactionModel: paginatedList[index].purchaseTransactionModel!);
                                                                          } else if (paginatedList[index].type == 'Due Collection' ||
                                                                              paginatedList[index].type == 'Due Payment') {
                                                                            if (paginatedList[index].dueTransactionModel == null) {
                                                                              throw Exception('Los datos de cuenta por cobrar/pagar no están disponibles');
                                                                            }
                                                                            
                                                                            await GeneratePdfAndPrint().printDueInvoice(
                                                                                setting: setting,
                                                                                personalInformationModel: profile.value!,
                                                                                dueTransactionModel: paginatedList[index].dueTransactionModel!,
                                                                                fromSaleReports: true);
                                                                          } else if (paginatedList[index].type == 'Expense') {
                                                                            showDialog(
                                                                              barrierDismissible: false,
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return StatefulBuilder(
                                                                                  builder: (context, setStates) {
                                                                                    return Dialog(
                                                                                      surfaceTintColor: Colors.white,
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(20.0),
                                                                                      ),
                                                                                      child: ExpenseDetails(expense: paginatedList[index].expenseModel!, manuContext: bc),
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                            );
                                                                          } else if (paginatedList[index].type == 'Income') {
                                                                            showDialog(
                                                                              barrierDismissible: false,
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return StatefulBuilder(
                                                                                  builder: (context, setStates) {
                                                                                    return Dialog(
                                                                                      surfaceTintColor: Colors.white,
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(20.0),
                                                                                      ),
                                                                                      child: IncomeDetails(income: paginatedList[index].incomeModel!, manuContext: bc),
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                            );
                                                                          } else {
                                                                            throw Exception('Tipo de transacción "${paginatedList[index].type}" no soportado para impresión');
                                                                          }

                                                                          // Mostrar mensaje de éxito
                                                                          messenger.showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('PDF generado exitosamente'),
                                                                              duration: Duration(seconds: 2),
                                                                              backgroundColor: Colors.green,
                                                                            ),
                                                                          );
                                                                        } catch (e) {
                                                                          // Mostrar mensaje de error detallado
                                                                          messenger.showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Error al generar PDF: ${e.toString()}'),
                                                                              duration: Duration(seconds: 4),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          
                                                                          // Registrar el error para debugging
                                                                          debugPrint('Error al imprimir transacción: $e');
                                                                          debugPrint('Tipo de transacción: ${paginatedList[index].type}');
                                                                          debugPrint('ID de transacción: ${paginatedList[index].id}');
                                                                        }
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          paginatedList[index].type == 'Income' || paginatedList[index].type == 'Expense'
                                                                              ? Icon(IconlyLight.show, size: 22.0, color: kGreyTextColor)
                                                                              : Icon(Icons.print, size: 22.0, color: kGreyTextColor),
                                                                          const SizedBox(
                                                                              width: 4.0),
                                                                          Text(
                                                                            // Show "View" for Income/Expense, "Print" for others
                                                                            paginatedList[index].type == 'Income' || paginatedList[index].type == 'Expense'
                                                                                ? lang.S.of(context).view
                                                                                : lang.S.of(context).print,
                                                                            style:
                                                                                theme.textTheme.bodyLarge?.copyWith(
                                                                              color: kGreyTextColor,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    // Nuevo botón para ver detalle de factura y pagos
                                                                    PopupMenuItem(
                                                                      onTap: () {
                                                                        // Debug: verificar valores
                                                                        debugPrint('DEBUG BUTTON: Tipo = "${paginatedList[index].type}"');
                                                                        debugPrint('DEBUG BUTTON: ID = "${paginatedList[index].id}"');
                                                                        debugPrint('DEBUG BUTTON: ID isEmpty = ${paginatedList[index].id.isEmpty}');
                                                                        
                                                                        // Solo mostrar para ventas y transacciones relacionadas que tengan invoice number
                                                                        if ((paginatedList[index].type == 'Sale' || 
                                                                             paginatedList[index].type == 'Adicionales' ||
                                                                             paginatedList[index].type == 'Impresiones' ||
                                                                             paginatedList[index].type == 'Sale Return' ||
                                                                             paginatedList[index].type == 'Due Collection' ||
                                                                             paginatedList[index].type == 'Due Payment') && 
                                                                            paginatedList[index].id.isNotEmpty) {
                                                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                                                            _showPaymentDetails(
                                                                              context: context,
                                                                              invoiceNumber: paginatedList[index].id,
                                                                              transaction: paginatedList[index],
                                                                            );
                                                                          });
                                                                        } else {
                                                                          // Debug: mostrar mensaje específico
                                                                          String debugMsg = '';
                                                                          List<String> validTypes = ['Sale', 'Sale Return', 'Due Collection', 'Due Payment'];
                                                                          if (!validTypes.contains(paginatedList[index].type)) {
                                                                            debugMsg = 'Tipo de transacción: "${paginatedList[index].type}" (no válido)';
                                                                          } else if (paginatedList[index].id.isEmpty) {
                                                                            debugMsg = 'ID de factura está vacío';
                                                                          }
                                                                          
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Esta opción solo está disponible para transacciones de venta. $debugMsg'),
                                                                              duration: Duration(seconds: 3),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      child: Row(
                                                                        children: [
                                                                          Icon(
                                                                            Icons.receipt_long,
                                                                            size: 22.0,
                                                                            color: ['Sale', 'Sale Return', 'Due Collection', 'Due Payment'].contains(paginatedList[index].type)
                                                                                ? kTitleColor 
                                                                                : kGreyTextColor,
                                                                          ),
                                                                          const SizedBox(width: 4.0),
                                                                          Text(
                                                                            'Ver Detalle',
                                                                            style: theme.textTheme.bodyLarge?.copyWith(
                                                                              color: ['Sale', 'Sale Return', 'Due Collection', 'Due Payment'].contains(paginatedList[index].type)
                                                                                  ? kTitleColor 
                                                                                  : kGreyTextColor,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                  onSelected:
                                                                      (value) {
                                                                    // Solo navegar si value no es null y es una ruta válida
                                                                    if (value != null && value.toString().isNotEmpty && value != 'null') {
                                                                      Navigator.pushNamed(
                                                                          context,
                                                                          '$value');
                                                                    }
                                                                  },
                                                                ),
                                                              );
                                                            }, error: (e,
                                                                        stack) {
                                                              return Text(
                                                                  e.toString());
                                                            }, loading: () {
                                                              return Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              );
                                                            })),
                                                          ]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${lang.S.of(context).showing} ${((_currentPage - 1) * _lossProfitPerPage + 1).toString()} to ${((_currentPage - 1) * _lossProfitPerPage + _lossProfitPerPage).clamp(0, reTransaction.length)} of ${reTransaction.length} entries',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            overlayColor:
                                                WidgetStateProperty.all<Color>(
                                                    Colors.grey),
                                            hoverColor: Colors.grey,
                                            onTap: _currentPage > 1
                                                ? () => setState(
                                                    () => _currentPage--)
                                                : null,
                                            child: Container(
                                              height: 32,
                                              width: 90,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(4.0),
                                                  topLeft: Radius.circular(4.0),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(lang.S
                                                    .of(context)
                                                    .previous),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 32,
                                            width: 32,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBorderColorTextField),
                                              color: kMainColor,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_currentPage',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 32,
                                            width: 32,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kBorderColorTextField),
                                              color: Colors.transparent,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$pages',
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            hoverColor: Colors.blue
                                                .withValues(alpha: 0.1),
                                            overlayColor:
                                                WidgetStateProperty.all<Color>(
                                                    Colors.blue),
                                            onTap: _currentPage *
                                                        _lossProfitPerPage <
                                                    reTransaction.length
                                                ? () => setState(
                                                    () => _currentPage++)
                                                : null,
                                            child: Container(
                                              height: 32,
                                              width: 90,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(4.0),
                                                  topRight:
                                                      Radius.circular(4.0),
                                                ),
                                              ),
                                              child: const Center(
                                                  child: Text('Next')),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : EmptyWidget(
                              title: lang.S.of(context).noTransactionFound),
                    ],
                  ),
                )
              ],
            ),
          );
            },
            error: (e, stack) {
              return Center(
                child: Text('Error cargando ventas: ${e.toString()}'),
              );
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        },
        error: (e, stack) {
          return Center(
            child: Text(e.toString()),
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    });
  }

  Widget _buildInvoiceNumberCell(
    DailyTransactionModel transaction,
    BuildContext context,
    AsyncValue<PersonalInformationModel> profile,
    AsyncValue<GeneralSettingModel> settingProvider
  ) {
    return Consumer(
      builder: (context, ref, child) {
        // PRIMERO: Verificar si hay invoiceNumber directo del API (campo plano)
        // Esto tiene prioridad porque es el campo enriquecido que viene del backend
        final directInvoiceNumber = transaction.invoiceNumber ?? '';

        // PARA TRANSACCIONES DE DUE PAYMENT (Cuentas por Cobrar)
        if (transaction.type == 'Due Payment') {
          // Prioridad: 1) invoiceNumber directo del API, 2) dueTransactionModel, 3) ID
          String displayText = directInvoiceNumber.isNotEmpty
              ? directInvoiceNumber
              : (transaction.dueTransactionModel?.invoiceNumber.isNotEmpty == true
                  ? transaction.dueTransactionModel!.invoiceNumber
                  : (transaction.id.isNotEmpty ? transaction.id : 'Due Payment'));

          return InkWell(
            onTap: () async {
              final setting = settingProvider.valueOrNull;
              final profileInfo = profile.valueOrNull;
              if (setting != null && profileInfo != null) {
                debugPrint('🧾 Generando recibo de Due Payment - Display: $displayText');

                try {
                  EasyLoading.show(status: 'Generando recibo de pago...');

                  // Si tiene dueTransactionModel, usarlo; si no, crear uno desde los datos disponibles
                  DueTransactionModel dueModel;
                  if (transaction.dueTransactionModel != null) {
                    dueModel = transaction.dueTransactionModel!;
                  } else {
                    // Crear DueTransactionModel desde los datos de la transacción
                    dueModel = DueTransactionModel(
                      customerName: transaction.name,
                      customerType: 'Customer',
                      customerAddress: '',
                      customerPhone: '',
                      customerGst: '',
                      invoiceNumber: displayText,
                      purchaseDate: transaction.date,
                      totalDue: transaction.total,
                      dueAmountAfterPay: transaction.dueAmountAfterPay ?? 0,
                      payDueAmount: transaction.paymentIn,
                      isPaid: (transaction.dueAmountAfterPay ?? 0) <= 0,
                      paymentType: transaction.paymentType ?? 'Efectivo',
                      sellerName: transaction.sellerName ?? 'Admin',
                    );
                    debugPrint('📝 DueTransactionModel creado desde datos de transacción');
                  }

                  await GeneratePdfAndPrint().printDueInvoice(
                    personalInformationModel: profileInfo,
                    dueTransactionModel: dueModel,
                    setting: setting,
                    context: context,
                    fromSaleReports: true,
                  );

                  EasyLoading.dismiss();
                  debugPrint('✅ Recibo de Due Payment generado exitosamente');
                } catch (e) {
                  EasyLoading.dismiss();
                  debugPrint('❌ Error generando recibo de Due Payment: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error generando recibo: $e')),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt, size: 16.0, color: Colors.green.shade700),
                  const SizedBox(width: 4.0),
                  Text(
                    displayText,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // PARA TRANSACCIONES DE DUE COLLECTION (También pueden necesitar recibo)
        if (transaction.type == 'Due Collection') {
          // Usar directInvoiceNumber primero, luego modelo si existe
          final invoiceNumber = directInvoiceNumber.isNotEmpty
              ? directInvoiceNumber
              : (transaction.dueTransactionModel?.invoiceNumber ?? '');

          // Mostrar aunque no haya modelo, usando el campo directo
          if (invoiceNumber.isNotEmpty) {
            return InkWell(
              onTap: () async {
                final setting = settingProvider.valueOrNull;
                final profileInfo = profile.valueOrNull;
                if (setting != null && profileInfo != null) {
                  debugPrint('🧾 Generando recibo de Due Collection - Factura: $invoiceNumber');

                  try {
                    EasyLoading.show(status: 'Generando recibo de cobro...');

                    // Si tiene dueTransactionModel, usarlo; si no, crear uno desde los datos disponibles
                    DueTransactionModel dueModel;
                    if (transaction.dueTransactionModel != null) {
                      dueModel = transaction.dueTransactionModel!;
                    } else {
                      // Crear DueTransactionModel desde los datos de la transacción
                      dueModel = DueTransactionModel(
                        customerName: transaction.name,
                        customerType: 'Customer',
                        customerAddress: '',
                        customerPhone: '',
                        customerGst: '',
                        invoiceNumber: invoiceNumber,
                        purchaseDate: transaction.date,
                        totalDue: transaction.total,
                        dueAmountAfterPay: transaction.dueAmountAfterPay ?? 0,
                        payDueAmount: transaction.paymentIn,
                        isPaid: (transaction.dueAmountAfterPay ?? 0) <= 0,
                        paymentType: transaction.paymentType ?? 'Efectivo',
                        sellerName: transaction.sellerName ?? 'Admin',
                      );
                      debugPrint('📝 DueTransactionModel creado desde datos de transacción (Due Collection)');
                    }

                    await GeneratePdfAndPrint().printDueInvoice(
                      personalInformationModel: profileInfo,
                      dueTransactionModel: dueModel,
                      setting: setting,
                      context: context,
                      fromSaleReports: true,
                    );
                    EasyLoading.dismiss();
                    debugPrint('✅ Recibo de Due Collection generado exitosamente');
                  } catch (e) {
                    EasyLoading.dismiss();
                    debugPrint('❌ Error generando recibo de Due Collection: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error generando recibo: $e')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.green.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 16.0, color: Colors.green.shade700),
                    const SizedBox(width: 4.0),
                    Text(
                      invoiceNumber,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        
        // PARA TRANSACCIONES DE VENTA (SALE, Impresiones, Adicionales) - Usar directInvoiceNumber primero
        // Nota: 'Impresiones' se muestra como 'Producto' en la UI, 'Adicionales' también son ventas
        if (transaction.type == 'Sale' || transaction.type == 'Impresiones' || transaction.type == 'Adicionales') {
          // Priorizar directInvoiceNumber (del API), luego modelo si existe
          final invoiceNumber = directInvoiceNumber.isNotEmpty
              ? directInvoiceNumber
              : (transaction.saleTransactionModel?.invoiceNumber ?? '');
          return InkWell(
            onTap: () async {
              final setting = settingProvider.valueOrNull;
              final profileInfo = profile.valueOrNull;
              if (setting != null && profileInfo != null) {
                // Obtener modelo de venta - si es null, buscar en transitionProvider por invoiceNumber
                SaleTransactionModel? saleModel = transaction.saleTransactionModel;

                if (saleModel == null && invoiceNumber.isNotEmpty) {
                  debugPrint('🔍 saleTransactionModel es null - buscando factura $invoiceNumber en Sales...');
                  final allSalesTransitions = ref.read(transitionProvider).valueOrNull;
                  if (allSalesTransitions != null) {
                    try {
                      saleModel = allSalesTransitions.firstWhere(
                        (sale) => sale.invoiceNumber == invoiceNumber,
                      );
                      debugPrint('✅ Factura encontrada en Sales Transition');
                    } catch (e) {
                      debugPrint('❌ Factura $invoiceNumber no encontrada en Sales Transition');
                    }
                  }
                }

                // Si aún es null, no podemos generar PDF
                if (saleModel == null) {
                  debugPrint('⚠️ No se pudo obtener datos de la venta para generar PDF');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se puede generar PDF para esta venta (Invoice: $invoiceNumber)')),
                  );
                  return;
                }

                // Verificar que tenga productos antes de procesar
                debugPrint('🔍 DEBUG PDF - Factura: ${saleModel.invoiceNumber}');
                debugPrint('📦 Productos en la transacción: ${saleModel.productList?.length ?? 0}');
                debugPrint('📋 productList es null?: ${saleModel.productList == null}');
                if (saleModel.productList != null && saleModel.productList!.isNotEmpty) {
                  debugPrint('✅ Primeros productos: ${saleModel.productList!.take(2).map((p) => p.productName).join(", ")}');
                }
                
                if (saleModel.productList == null || saleModel.productList!.isEmpty) {
                  debugPrint('❌ Esta venta no tiene productos - buscando en Sales Transition...');

                  // Guardar invoiceNumber antes de usar en closure
                  final saleInvoiceNumber = saleModel.invoiceNumber;

                  // Intentar buscar la venta completa en Sales Transition
                  final allSalesTransitions = ref.read(transitionProvider).valueOrNull;
                  if (allSalesTransitions != null) {
                    SaleTransactionModel? fullSale;
                    try {
                      fullSale = allSalesTransitions.firstWhere(
                        (sale) => sale.invoiceNumber == saleInvoiceNumber,
                      );
                    } catch (e) {
                      fullSale = null;
                    }

                    if (fullSale != null) {
                      debugPrint('🔍 Venta encontrada en Sales Transition - productos: ${fullSale.productList?.length ?? 0}');

                      if (fullSale.productList != null && fullSale.productList!.isNotEmpty) {
                        // Usar la venta completa de Sales Transition
                        SaleTransactionModel post = checkLossProfit(transitionModel: fullSale);
                        EasyLoading.show(status: 'Preparando vista previa...');
                        await GeneratePdfAndPrint().printSaleInvoice(
                          setting: setting,
                          personalInformationModel: profileInfo,
                          saleTransactionModel: fullSale,
                          context: context,
                          printType: 'normal',
                          fromSaleReports: true,
                          post: post,
                        );
                        EasyLoading.dismiss();
                        return;
                      }
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Esta venta (${saleModel.invoiceNumber}) no tiene productos asociados')),
                  );
                  return;
                }
                
                SaleTransactionModel post = checkLossProfit(transitionModel: saleModel);
                EasyLoading.show(status: 'Preparando vista previa...');
                await GeneratePdfAndPrint().printSaleInvoice(
                  setting: setting,
                  personalInformationModel: profileInfo,
                  saleTransactionModel: saleModel,
                  context: context,
                  printType: 'normal',
                  fromSaleReports: true,
                  post: post,
                );
                EasyLoading.dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, size: 16.0, color: Colors.blue.shade700),
                  const SizedBox(width: 4.0),
                  Text(
                    invoiceNumber,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // PARA TRANSACCIONES ELIMINADAS (Deleted) - Mostrar botón rojo para ver PDF
        if (transaction.type == 'Deleted') {
          final invoiceNumber = directInvoiceNumber.isNotEmpty
              ? directInvoiceNumber
              : (transaction.id.isNotEmpty ? transaction.id : '');

          if (invoiceNumber.isNotEmpty) {
            return InkWell(
              onTap: () async {
                // Intentar generar PDF desde los datos guardados
                await _generateDeletedInvoicePdfFromTransaction(context, transaction);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, size: 16.0, color: Colors.red.shade700),
                    const SizedBox(width: 4.0),
                    Text(
                      invoiceNumber,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return const Text('-');
      },
    );
  }

  /// Generar PDF de una factura eliminada desde DailyTransactionModel
  Future<void> _generateDeletedInvoicePdfFromTransaction(BuildContext context, DailyTransactionModel transaction) async {
    try {
      EasyLoading.show(status: 'Preparando PDF...');

      final invoiceNumber = transaction.invoiceNumber ?? '';
      debugPrint('📄 Intentando generar PDF para factura eliminada: $invoiceNumber');

      // Los datos de la factura eliminada deberían estar en saleTransactionModel
      // o se pueden reconstruir desde los datos disponibles
      SaleTransactionModel? saleModel = transaction.saleTransactionModel;

      // Si no tiene saleTransactionModel, buscar en Sales Transition por invoiceNumber
      if (saleModel == null && invoiceNumber.isNotEmpty) {
        debugPrint('⚠️ saleTransactionModel es null - Buscando en Sales Transition...');

        final ref = ProviderScope.containerOf(context);
        final allSalesTransitions = ref.read(transitionProvider).valueOrNull;

        if (allSalesTransitions != null) {
          try {
            saleModel = allSalesTransitions.firstWhere(
              (sale) => sale.invoiceNumber == invoiceNumber,
            );
            debugPrint('✅ Factura $invoiceNumber encontrada en Sales Transition');
          } catch (e) {
            debugPrint('❌ Factura $invoiceNumber NO encontrada en Sales Transition');
          }
        }
      }

      if (saleModel == null) {
        debugPrint('⚠️ No se pudo encontrar la factura eliminada en ninguna fuente');
        EasyLoading.dismiss();

        if (context.mounted) {
          // Mostrar diálogo con información detallada
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 28),
                    SizedBox(width: 10),
                    Text('Datos No Disponibles'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La factura #$invoiceNumber fue eliminada antes de la actualización del sistema que guarda los datos completos.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Información disponible:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 6),
                          Text('• Cliente: ${transaction.name}', style: TextStyle(fontSize: 12)),
                          Text('• Total: \$${myFormat.format(transaction.total)}', style: TextStyle(fontSize: 12)),
                          Text('• Fecha: ${transaction.date}', style: TextStyle(fontSize: 12)),
                          if (transaction.sellerName != null && transaction.sellerName!.isNotEmpty)
                            Text('• Vendedor: ${transaction.sellerName}', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Las facturas eliminadas a partir de ahora sí podrán generar PDF.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text('Entendido'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Verificar que tenga productos
      if (saleModel.productList == null || saleModel.productList!.isEmpty) {
        EasyLoading.dismiss();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La factura eliminada no tiene productos para mostrar en el PDF.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Obtener información del perfil y configuración
      final ref = ProviderScope.containerOf(context);
      final profileInfo = await ref.read(profileDetailsProvider.future);
      final setting = await ref.read(generalSettingProvider.future);

      debugPrint('✅ Modelo de venta encontrado: ${saleModel.invoiceNumber}');
      debugPrint('✅ Productos: ${saleModel.productList?.length ?? 0}');

      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }

      // Generar el PDF
      await GeneratePdfAndPrint().printSaleInvoice(
        setting: setting,
        personalInformationModel: profileInfo,
        saleTransactionModel: saleModel,
        context: context,
        printType: 'normal',
        fromSaleReports: true,
      );

      EasyLoading.dismiss();
      debugPrint('✅ PDF de factura eliminada generado exitosamente');

    } catch (e, stackTrace) {
      debugPrint('❌ Error generando PDF de factura eliminada: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      EasyLoading.dismiss();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentDetails({
    required BuildContext context,
    required String invoiceNumber,
    required DailyTransactionModel transaction,
  }) {
    debugPrint('DEBUG: Mostrando detalles de pago para invoice: $invoiceNumber');
    debugPrint('DEBUG: Tipo de transacción: ${transaction.type}');
    
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
        final globalCurrency = currencyProvider.currency ?? '\$';

        return Consumer(
          builder: (context, ref, _) {
            final dailyTransactionReport = ref.watch(dailyTransactionProvider);

            return dailyTransactionReport.when(
              data: (transactions) {
                // Filtrar transacciones por invoice number
                List<DailyTransactionModel> reTransaction = [];
                
                for (var element in transactions.reversed.toList()) {
                  if (element.id == invoiceNumber) {
                    reTransaction.add(element);
                  }
                }

                // Calcular total abonado
                double totalAbonado = reTransaction.fold(0.0, (sum, payment) => sum + payment.paymentIn);
                
                // Obtener información del cliente desde la transacción de venta
                String customerName = transaction.saleTransactionModel?.customerName ?? 'N/A';
                String customerPhone = transaction.saleTransactionModel?.customerPhone ?? 'N/A';
                String sellerName = transaction.saleTransactionModel?.sellerName ?? 'N/A';
                double totalFactura = transaction.saleTransactionModel?.totalAmount ?? transaction.total;
                double deudaActual = transaction.saleTransactionModel?.dueAmount ?? 0.0;

                return Dialog(
                  surfaceTintColor: kWhite,
                  backgroundColor: kWhite,
                  child: SizedBox(
                    width: 700,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con título y botón cerrar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Detalles del Cliente',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Divider(),
                          
                          // Información del cliente y resumen
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nombre: $customerName', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 8),
                                    Text('Teléfono: $customerPhone', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 8),
                                    Text('Factura Nº: $invoiceNumber', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 8),
                                    Text('Vendido por: $sellerName', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total de la factura:  $globalCurrency${myFormat.format(totalFactura)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600, 
                                      color: Colors.red
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Pagado:  $globalCurrency${myFormat.format(totalAbonado)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deuda Actual:  $globalCurrency${myFormat.format(deudaActual)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Tabla de pagos realizados
                          LayoutBuilder(builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F1F1)),
                                  columns: const [
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Pago Registrado')),
                                    DataColumn(label: Text('Método de Pago')),
                                  ],
                                  rows: reTransaction.map<DataRow>((payment) {
                                    // Determinar método de pago
                                    String metodoPago = 'N/A';
                                    String bankInfo = '';
                                    
                                    if (payment.dueTransactionModel != null) {
                                      var dueModel = payment.dueTransactionModel!;
                                      
                                      if (dueModel.paymentType != null && dueModel.paymentType!.isNotEmpty) {
                                        metodoPago = dueModel.paymentType!;
                                        
                                        switch (metodoPago.toLowerCase().trim()) {
                                          case 'cash':
                                          case 'efectivo':
                                            metodoPago = 'Efectivo';
                                            break;
                                          case 'card':
                                          case 'tarjeta':
                                            metodoPago = 'Tarjeta';
                                            break;
                                          case 'bank':
                                          case 'transferencia':
                                            metodoPago = 'Transferencia';
                                            // Agregar información del banco si está disponible
                                            if (dueModel.bankName != null && dueModel.bankName!.isNotEmpty) {
                                              bankInfo = ' (${dueModel.bankName})';
                                            }
                                            break;
                                          case 'check':
                                          case 'cheque':
                                            metodoPago = 'Cheque';
                                            break;
                                          default:
                                            break;
                                        }
                                      }
                                    } else if (payment.saleTransactionModel != null) {
                                      // Para la venta original, usar el método de pago de la venta
                                      metodoPago = _getPaymentType(payment);
                                      
                                      // Si es transferencia, obtener información del banco
                                      if (metodoPago.toLowerCase().contains('transfer') && 
                                          payment.saleTransactionModel!.bankName != null && 
                                          payment.saleTransactionModel!.bankName!.isNotEmpty) {
                                        bankInfo = ' (${payment.saleTransactionModel!.bankName})';
                                      }
                                    }
                                    
                                    return DataRow(cells: [
                                      DataCell(_fechaConvertida(payment.date)),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Text('$globalCurrency${myFormat.format(payment.paymentIn)}'),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Text(
                                          metodoPago + bankInfo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: metodoPago == 'N/A' ? Colors.grey : null,
                                          ),
                                        ),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => AlertDialog(
                title: const Text('Error'),
                content: Text('No se pudieron cargar los pagos.\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _fechaConvertida(String? date) {
    try {
      if (date == null || date.trim().isEmpty) {
        return const Text('-');
      }

      DateTime dateTime = DateTime.parse(date);
      String formattedDate = DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
      return Text(formattedDate);
    } catch (e) {
      return const Text('-');
    }
  }

  // Método para mostrar diálogo de eliminación de facturas problemáticas
  void _showDeleteProblematicInvoicesDialog() {
    if (_problematicInvoices.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Facturas Problemáticas Detectadas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Se encontraron ${_problematicInvoices.length} facturas con problemas:'),
              const SizedBox(height: 8),
              ...(_problematicInvoices.map((invoice) => Text('• Factura $invoice')).toList()),
              const SizedBox(height: 16),
              const Text(
                'Estas facturas no tienen productos asociados y no existen en Sales Transition. ¿Desea eliminarlas de Daily Transaction?',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProblematicInvoices();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Método para buscar y mostrar transacciones huérfanas
  Future<void> _showOrphanTransactions(WidgetRef ref) async {
    try {
      EasyLoading.show(status: 'Buscando transacciones huérfanas...');

      final apiService = ApiService();

      // Obtener todas las transacciones diarias
      final dailyResponse = await apiService.get('daily-transactions', queryParams: {
        'limit': '5000',
      });

      // Obtener todos los gastos actuales
      final expenseResponse = await apiService.get('expenses', queryParams: {
        'limit': '5000',
      });

      List<Map<String, dynamic>> orphanTransactions = [];
      Map<String, bool> existingExpenses = {};

      // Crear un mapa de gastos existentes para búsqueda rápida
      if (expenseResponse.success && expenseResponse.data != null) {
        final expenses = expenseResponse.data['expenses'] as List<dynamic>? ?? [];
        for (var element in expenses) {
          final expense = Map<String, dynamic>.from(element);
          final key = '${expense['expanseFor']}_${expense['amount']}_${expense['expenseDate']}';
          existingExpenses[key] = true;
        }
      }

      // Buscar transacciones de tipo Expense sin gasto correspondiente
      if (dailyResponse.success && dailyResponse.data != null) {
        final transactions = dailyResponse.data['daily_transactions'] as List<dynamic>? ??
            dailyResponse.data['transactions'] as List<dynamic>? ?? [];

        for (var element in transactions) {
          final transactionData = Map<String, dynamic>.from(element);
          final transactionId = transactionData['id']?.toString();
          final transaction = DailyTransactionModel.fromJson(transactionData);

          if (transaction.type == 'Expense' && transaction.expenseModel != null) {
            final expense = transaction.expenseModel!;
            final key = '${expense.expanseFor}_${expense.amount}_${expense.expenseDate}';

            // Si no existe el gasto en la tabla de gastos, es huérfano
            if (!existingExpenses.containsKey(key)) {
              // Verificar si es la transacción de Victor Guzmán
              if ((expense.customerName?.toLowerCase().contains('victor') ?? false) ||
                  (expense.customerName?.toLowerCase().contains('guzman') ?? false) ||
                  expense.amount == '5000' || expense.amount == '5000.00') {
                orphanTransactions.add({
                  'key': transactionId,
                  'transaction': transaction,
                  'expense': expense,
                });
              }
            }
          }
        }
      }
      
      EasyLoading.dismiss();
      
      if (orphanTransactions.isEmpty) {
        EasyLoading.showInfo('No se encontraron transacciones huérfanas de Victor Guzmán');
        return;
      }
      
      // Mostrar diálogo con las transacciones encontradas
      if (!mounted) return;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transacciones Huérfanas Encontradas',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const Divider(),
                
                // Lista de transacciones
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orphanTransactions.length,
                    itemBuilder: (context, index) {
                      final data = orphanTransactions[index];
                      final expense = data['expense'] as ExpenseModel;
                      final transaction = data['transaction'] as DailyTransactionModel;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transacción #${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HUÉRFANA',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Cliente: ${expense.customerName ?? "N/A"}'),
                              Text('Concepto: ${expense.expanseFor}'),
                              Text('Monto: \$${expense.amount}'),
                              Text('Fecha: ${expense.expenseDate}'),
                              Text('Categoría: ${expense.category}'),
                              if (expense.customerPhone != null)
                                Text('Teléfono: ${expense.customerPhone}'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      // Pedir confirmación con contraseña
                                      final confirmed = await _confirmDeleteOrphan(
                                        context, 
                                        expense,
                                        data['key'] as String,
                                      );
                                      
                                      if (confirmed) {
                                        Navigator.pop(dialogContext);
                                        await _deleteOrphanTransaction(
                                          data['key'] as String,
                                          transaction,
                                          ref,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Eliminar del Informe'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Botón cerrar
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }
  
  // Confirmar eliminación con contraseña
  Future<bool> _confirmDeleteOrphan(BuildContext context, ExpenseModel expense, String transactionKey) async {
    final passwordController = TextEditingController();
    bool confirmed = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro de eliminar esta transacción del informe?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente: ${expense.customerName}'),
                  Text('Monto: \$${expense.amount}'),
                  Text('Fecha: ${expense.expenseDate}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña de autorización',
                hintText: 'Ingrese la contraseña',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Validar contraseña con Firebase
              final isValid = await DeletionPasswordService.validatePassword(
                passwordController.text,
              );

              if (isValid) {
                confirmed = true;
                Navigator.pop(dialogContext);
              } else {
                EasyLoading.showError('Contraseña incorrecta');
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    return confirmed;
  }
  
  // Eliminar transacción huérfana
  Future<void> _deleteOrphanTransaction(String transactionKey, DailyTransactionModel transaction, WidgetRef ref) async {
    try {
      EasyLoading.show(status: 'Eliminando transacción...');

      final apiService = ApiService();

      // Eliminar la transacción diaria
      await apiService.delete('daily-transactions/$transactionKey');

      // Actualizar el balance si es necesario
      if (transaction.type == 'Expense' && transaction.paymentOut > 0) {
        final personalInfoResponse = await apiService.get('personal-information');

        if (personalInfoResponse.success && personalInfoResponse.data != null) {
          final data = Map<String, dynamic>.from(personalInfoResponse.data);
          double currentBalance = double.tryParse(data['remainingShopBalance']?.toString() ?? '0') ?? 0.0;
          double newBalance = currentBalance + transaction.paymentOut;

          await apiService.put('personal-information', {
            'remainingShopBalance': newBalance,
          });
        }
      }

      // Registrar en auditoría
      await AuditService().logAction(
        action: AuditAction.delete,
        module: AuditModule.expenses,
        description: 'Eliminó transacción huérfana del informe: ${transaction.name} por \$${transaction.paymentOut}',
        beforeData: {
          'transactionKey': transactionKey,
          'name': transaction.name,
          'amount': transaction.paymentOut,
          'date': transaction.date,
          'type': transaction.type,
        },
      );

      // Refrescar el provider
      ref.invalidate(dailyTransactionProvider);

      EasyLoading.showSuccess('Transacción eliminada del informe');
    } catch (e) {
      EasyLoading.showError('Error al eliminar: $e');
    }
  }

  // NUEVO: Método para corregir saldos negativos en clientes
  Future<void> _fixNegativeBalances() async {
    try {
      EasyLoading.show(status: 'Corrigiendo saldos negativos...');
      
      DeleteInvoice delete = DeleteInvoice();
      await delete.fixNegativeCustomerBalances();
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('✅ Saldos negativos corregidos');
      
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
    }
  }

  // NUEVO: Método para limpiar facturas huérfanas específicas (517, 514)
  Future<void> _cleanOrphanInvoices() async {
    List<String> orphanInvoices = ["517", "514"];
    
    try {
      EasyLoading.show(status: 'Limpiando facturas huérfanas...');
      
      for (String invoice in orphanInvoices) {
        DeleteInvoice delete = DeleteInvoice();
        await delete.cleanOrphanInvoicePayments(invoice: invoice);
      }
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('✅ Facturas huérfanas limpiadas');
      
      // Refrescar la página
      setState(() {});
      
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
    }
  }

  // Método para eliminar facturas problemáticas
  Future<void> _deleteProblematicInvoices() async {
    try {
      EasyLoading.show(status: 'Eliminando facturas problemáticas...');

      final apiService = ApiService();

      // Obtener todas las entradas de Daily Transaction
      final response = await apiService.get('daily-transactions', queryParams: {
        'limit': '5000',
      });

      if (response.success && response.data != null) {
        final transactions = response.data['daily_transactions'] as List<dynamic>? ??
            response.data['transactions'] as List<dynamic>? ?? [];
        int deletedCount = 0;

        for (var element in transactions) {
          final value = Map<String, dynamic>.from(element);
          final transactionId = value['id']?.toString();

          // Verificar si es una venta y tiene el invoiceNumber problemático
          if ((value['type'] == 'Sale' || value['type'] == 'Adicionales' || value['type'] == 'Impresiones') &&
              value['saleTransactionModel'] != null &&
              _problematicInvoices.contains(value['saleTransactionModel']['invoiceNumber'])) {

            if (transactionId != null) {
              await apiService.delete('daily-transactions/$transactionId');
              deletedCount++;
              debugPrint('🗑️ Eliminada factura problemática: ${value['saleTransactionModel']['invoiceNumber']}');
            }
          }
        }

        EasyLoading.dismiss();

        // Mostrar resultado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eliminadas $deletedCount facturas problemáticas'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar la lista y refrescar
        _problematicInvoices.clear();
        setState(() {});

      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron datos en Daily Transaction')),
        );
      }

    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('❌ Error eliminando facturas problemáticas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCashDetailsDialog(BuildContext context, DailySummaryModel summary, List<DailyTransactionModel> transactions) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context, listen: false);
    final globalCurrency = currencyProvider.currency ?? '\$';
    
    // Filtrar transacciones en efectivo
    List<DailyTransactionModel> cashInTransactions = [];
    List<DailyTransactionModel> cashOutTransactions = [];
    
    for (var transaction in transactions) {
      String? paymentType;

      if (transaction.saleTransactionModel != null) {
        paymentType = transaction.saleTransactionModel!.paymentType;
      } else if (transaction.dueTransactionModel != null) {
        paymentType = transaction.dueTransactionModel!.paymentType;
      } else if (transaction.purchaseTransactionModel != null) {
        paymentType = transaction.purchaseTransactionModel!.paymentType;
      } else if (transaction.expenseModel != null) {
        paymentType = transaction.expenseModel!.paymentType;
      } else if (transaction.incomeModel != null) {
        paymentType = transaction.incomeModel!.paymentType;
      } else if (transaction.paySalary != null) {
        paymentType = transaction.paySalary!.paymentType;
      } else {
        // Fallback: usar campo directo de la transacción
        paymentType = transaction.paymentType;
      }

      if (paymentType != null) {
        final paymentTypeLower = paymentType.toLowerCase().trim();
        if (paymentTypeLower == "cash" || paymentTypeLower == "efectivo") {
          if (transaction.paymentIn > 0) {
            cashInTransactions.add(transaction);
          } else if (transaction.paymentOut > 0) {
            cashOutTransactions.add(transaction);
          }
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'Detalle de Efectivo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                // Balance Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  color: Colors.grey.shade50,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryItem(
                            'Ingresos',
                            '$globalCurrency ${myFormat.format(summary.ingresoEfectivo)}',
                            Colors.green,
                            Icons.arrow_downward,
                          ),
                          Container(
                            height: 60,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildSummaryItem(
                            'Gastos/Devoluciones',
                            '$globalCurrency ${myFormat.format(summary.gastoEfectivo)}',
                            Colors.red,
                            Icons.arrow_upward,
                          ),
                          Container(
                            height: 60,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildSummaryItem(
                            'Balance',
                            '$globalCurrency ${myFormat.format(summary.ingresoEfectivo - summary.gastoEfectivo)}',
                            (summary.ingresoEfectivo - summary.gastoEfectivo) >= 0 ? Colors.blue : Colors.orange,
                            Icons.account_balance,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Transactions List
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: const Color(0xFF4CAF50),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF4CAF50),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Ingresos (${cashInTransactions.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Gastos/Devoluciones (${cashOutTransactions.length})'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Ingresos Tab
                              _buildTransactionsList(cashInTransactions, globalCurrency, true),
                              // Gastos Tab
                              _buildTransactionsList(cashOutTransactions, globalCurrency, false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionsList(List<DailyTransactionModel> transactions, String currency, bool isIncome) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncome ? Icons.inbox : Icons.money_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isIncome ? 'No hay ingresos en efectivo' : 'No hay gastos en efectivo',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              transaction.name,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(translateType(transaction.type)),
                Text(
                  transaction.date.substring(0, 10),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              '$currency ${myFormat.format(isIncome ? transaction.paymentIn : transaction.paymentOut)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
  
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'Sale':
      case 'Adicionales':
      case 'Impresiones':
        return Icons.shopping_cart;
      case 'Due Collection':
        return Icons.account_balance_wallet;
      case 'Income':
        return Icons.attach_money;
      case 'Expense':
        return Icons.money_off;
      case 'Purchase':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }

  /// Generar PDF de una factura eliminada
  Future<void> _generateDeletedInvoicePdf(BuildContext context, Map<String, dynamic> deleted) async {
    try {
      EasyLoading.show(status: 'Preparando PDF...');

      // Obtener los datos originales de la factura desde el campo 'data'
      final invoiceData = deleted['data'];

      if (invoiceData == null) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron datos de la factura original'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      debugPrint('📄 Generando PDF para factura eliminada: ${deleted['invoiceNumber']}');
      debugPrint('📄 Datos de factura: $invoiceData');

      // Intentar extraer el modelo de venta
      SaleTransactionModel? saleModel;

      // Los datos pueden estar en diferentes formatos según cómo se guardaron
      if (invoiceData is Map) {
        final dataMap = Map<String, dynamic>.from(invoiceData);

        // Buscar el modelo de venta en diferentes ubicaciones posibles
        if (dataMap.containsKey('saleTransactionModel')) {
          final saleData = dataMap['saleTransactionModel'];
          if (saleData is Map) {
            saleModel = SaleTransactionModel.fromJson(Map<String, dynamic>.from(saleData));
          }
        } else if (dataMap.containsKey('sale_transaction_model')) {
          final saleData = dataMap['sale_transaction_model'];
          if (saleData is Map) {
            saleModel = SaleTransactionModel.fromJson(Map<String, dynamic>.from(saleData));
          }
        } else {
          // Intentar crear el modelo directamente desde los datos
          // Los campos pueden estar en el nivel superior del data
          saleModel = SaleTransactionModel.fromJson(dataMap);
        }
      }

      if (saleModel == null) {
        EasyLoading.dismiss();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta factura fue eliminada antes de que se guardaran los datos completos. Las nuevas eliminaciones sí podrán generar PDF.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Verificar que tenga productos
      if (saleModel.productList == null || saleModel.productList!.isEmpty) {
        EasyLoading.dismiss();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta factura fue eliminada antes de que se guardaran los datos del PDF. Las facturas eliminadas a partir de ahora sí podrán generar PDF.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Obtener información del perfil y configuración
      final ref = ProviderScope.containerOf(context);
      final profileInfo = await ref.read(profileDetailsProvider.future);
      final setting = await ref.read(generalSettingProvider.future);

      debugPrint('✅ Modelo de venta reconstruido: ${saleModel.invoiceNumber}');
      debugPrint('✅ Productos: ${saleModel.productList?.length ?? 0}');

      // Verificar que el context sigue montado antes de usar
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }

      // Generar el PDF
      await GeneratePdfAndPrint().printSaleInvoice(
        setting: setting,
        personalInformationModel: profileInfo,
        saleTransactionModel: saleModel,
        context: context,
        printType: 'normal',
        fromSaleReports: true,
      );

      EasyLoading.dismiss();

    } catch (e, stackTrace) {
      debugPrint('❌ Error generando PDF de factura eliminada: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      EasyLoading.dismiss();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar diálogo con las facturas eliminadas
  /// [deletedInvoices] Lista de facturas eliminadas filtradas por fecha
  /// [ref] WidgetRef para refrescar providers después de limpieza
  void _showDeletedInvoicesDialog(BuildContext context, List<Map<String, dynamic>> deletedInvoices, {WidgetRef? ref}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Facturas Eliminadas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Del ${DateFormat('dd/MM/yyyy').format(selectedDate.start)} al ${DateFormat('dd/MM/yyyy').format(selectedDate.end)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón para limpiar transacciones huérfanas
                      TextButton.icon(
                        onPressed: () async {
                          // Confirmar acción
                          final confirm = await showDialog<bool>(
                            context: dialogContext,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Limpiar transacciones huérfanas?'),
                              content: const Text(
                                'Esta acción eliminará las transacciones de venta que corresponden a facturas ya eliminadas.\n\n'
                                'Esto corregirá los totales del informe.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                  ),
                                  child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            Navigator.of(dialogContext).pop(); // Cerrar diálogo actual
                            EasyLoading.show(status: 'Limpiando transacciones...');
                            try {
                              final delete = DeleteInvoice();
                              final result = await delete.cleanOrphanDailyTransactions();
                              EasyLoading.dismiss();

                              final totalCleaned = (result['sales'] ?? 0) +
                                                   (result['dueCollections'] ?? 0) +
                                                   (result['dueTransactions'] ?? 0);

                              if (totalCleaned > 0) {
                                EasyLoading.showSuccess(
                                  'Limpieza completada!\n'
                                  'Ventas: ${result['sales']}\n'
                                  'Due Collections: ${result['dueCollections']}',
                                );
                                // Refrescar providers si ref está disponible
                                if (ref != null) {
                                  ref.refresh(dailyTransactionProvider);
                                  ref.refresh(transitionProvider);
                                }
                              } else {
                                EasyLoading.showInfo('No se encontraron transacciones huérfanas');
                              }
                            } catch (e) {
                              EasyLoading.dismiss();
                              EasyLoading.showError('Error: $e');
                            }
                          }
                        },
                        icon: const Icon(Icons.cleaning_services, color: Colors.white, size: 18),
                        label: const Text(
                          'Limpiar',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: deletedInvoices.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay facturas eliminadas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No se encontraron eliminaciones en el período seleccionado',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: deletedInvoices.length,
                          itemBuilder: (context, index) {
                            final deleted = deletedInvoices[index];

                            // Extraer datos del mapa
                            final invoiceNumber = deleted['invoiceNumber']?.toString() ?? 'N/A';
                            final customerName = deleted['customerName']?.toString() ?? 'Desconocido';
                            final deletedBy = deleted['deletedBy']?.toString() ?? 'Desconocido';
                            final totalAmount = deleted['totalAmount'];
                            final amount = totalAmount != null ? 'RD\$ $totalAmount' : '';

                            // Formatear fecha
                            String formattedDate = '';
                            try {
                              final deletedAt = deleted['deletedAt']?.toString() ?? '';
                              if (deletedAt.isNotEmpty) {
                                final date = DateTime.parse(deletedAt);
                                formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                              }
                            } catch (e) {
                              formattedDate = deleted['deletedAt']?.toString() ?? '';
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
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
                                            color: const Color(0xFFE53935),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Factura #$invoiceNumber',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (amount.isNotEmpty)
                                          Text(
                                            amount,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFFE53935),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Cliente: $customerName',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.account_circle, size: 18, color: Colors.orange.shade600),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Eliminado por: $deletedBy',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (deleted['paymentType'] != null && deleted['paymentType'] != 'N/A') ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Método de pago: ${deleted['paymentType']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Botón para ver PDF de factura eliminada
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _generateDeletedInvoicePdf(context, deleted);
                                          },
                                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                                          label: const Text('Ver PDF'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Footer con resumen
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${deletedInvoices.length} factura(s) eliminada(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cerrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
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
    );
  }
}