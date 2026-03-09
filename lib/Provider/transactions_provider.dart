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

  final trimmed = searchQuery.trim();
  
  // Limpiar caracteres no-numéricos excepto +
  final cleanedDigits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
  
  // Si empieza con + es definitivamente un teléfono
  if (trimmed.startsWith('+')) {
    return transitionRepo.searchSales(customerPhone: trimmed);
  }

  // Si es numérico, puede ser factura o teléfono
  final isNumeric = RegExp(r'^\d+$').hasMatch(trimmed);

  if (isNumeric) {
    // Si tiene menos de 7 dígitos, solo buscar como factura
    if (trimmed.length < 7) {
      return transitionRepo.searchSales(invoiceNumber: trimmed);
    }
    
    // 7+ dígitos: intentar como factura primero (rápido)
    final invoiceResults = await transitionRepo.searchSales(invoiceNumber: trimmed);
    if (invoiceResults.isNotEmpty) {
      return invoiceResults;
    }
    
    // No es factura — buscar como teléfono con múltiples variantes
    // Los teléfonos se guardan como +1XXXXXXXXXX
    // El usuario puede escribir: XXXXXXXXXX, 1XXXXXXXXXX, +1XXXXXXXXXX
    
    // Generar variantes de búsqueda de teléfono
    List<String> phoneVariants = [];
    
    // Variante 1: número limpio (solo dígitos)
    phoneVariants.add(cleanedDigits);
    
    // Variante 2: si empieza con 1 (código de país), quitar el 1 para buscar solo el local
    if (cleanedDigits.startsWith('1') && cleanedDigits.length >= 11) {
      phoneVariants.add(cleanedDigits.substring(1)); // sin código de país
    }
    
    // Variante 3: con prefijo +
    phoneVariants.add('+$cleanedDigits');
    
    // Variante 4: con prefijo +1 si no lo tiene
    if (!cleanedDigits.startsWith('1')) {
      phoneVariants.add('+1$cleanedDigits');
    }
    
    // Intentar cada variante hasta encontrar resultados
    for (final variant in phoneVariants) {
      final results = await transitionRepo.searchSales(customerPhone: variant);
      if (results.isNotEmpty) {
        return results;
      }
    }
    
    return [];
  } else {
    // Búsqueda por nombre de cliente
    return transitionRepo.searchSales(customerName: trimmed);
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
