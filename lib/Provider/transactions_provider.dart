import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Repository/transactions_repo.dart';
import '../model/sale_transaction_model.dart';

TransitionRepo transitionRepo = TransitionRepo();
final transitionProvider = FutureProvider.autoDispose<List<SaleTransactionModel>>((ref) => transitionRepo.getAllTransition());

PurchaseTransitionRepo purchaseTransitionRepo = PurchaseTransitionRepo();
final purchaseTransitionProvider = FutureProvider.autoDispose<List<dynamic>>((ref) => purchaseTransitionRepo.getAllTransition());

QuotationRepo quotationRepo = QuotationRepo();
final quotationProvider = FutureProvider.autoDispose<List<SaleTransactionModel>>((ref) => quotationRepo.getAllQuotation());

QuotationHistoryRepo quotationHistoryRepo = QuotationHistoryRepo();
final quotationHistoryProvider = FutureProvider.autoDispose<List<SaleTransactionModel>>((ref) => quotationHistoryRepo.getAllQuotationHistory());

/// Provider para buscar ventas por número de factura o cliente directamente en el API
/// Este provider NO tiene el límite de 100 ventas del transitionProvider normal
final searchSalesProvider = FutureProvider.autoDispose.family<List<SaleTransactionModel>, String>((ref, searchQuery) async {
  if (searchQuery.isEmpty) {
    return [];
  }

  // Determinar si es búsqueda por número de factura o por nombre
  final isNumeric = RegExp(r'^\d+$').hasMatch(searchQuery.trim());

  if (isNumeric) {
    // Búsqueda por número de factura
    return transitionRepo.searchSales(invoiceNumber: searchQuery.trim());
  } else {
    // Búsqueda por nombre de cliente
    return transitionRepo.searchSales(customerName: searchQuery.trim());
  }
});

/// Provider para obtener ventas con saldo pendiente (para Cuentas por Cobrar)
/// Busca directamente en el API sin límite de 100
final salesWithDueProvider = FutureProvider.autoDispose<List<SaleTransactionModel>>((ref) async {
  return transitionRepo.getSalesWithDue();
});

/// Provider para buscar ventas con saldo pendiente por nombre de cliente
final searchSalesWithDueProvider = FutureProvider.autoDispose.family<List<SaleTransactionModel>, String>((ref, searchQuery) async {
  if (searchQuery.isEmpty) {
    // Si no hay búsqueda, retornar todas las ventas con saldo
    return transitionRepo.getSalesWithDue();
  }

  // Buscar por nombre de cliente
  return transitionRepo.getSalesWithDue(customerName: searchQuery.trim());
});
