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
