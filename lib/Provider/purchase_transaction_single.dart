import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/transactions_provider.dart';

import '../Repository/transactions_repo.dart';
import '../model/purchase_transation_model.dart';

PurchaseTransitionRepo purchaseTransitionSingleRepo = PurchaseTransitionRepo();
final purchaseTransitionProviderSIngle = FutureProvider.autoDispose<List<PurchaseTransactionModel>>((ref) => purchaseTransitionRepo.getAllTransitionSingle());
