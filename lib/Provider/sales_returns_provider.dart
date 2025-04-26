import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Repository/sales_return_repo.dart';

import '../model/sale_transaction_model.dart';

SalesReturnRepo salesReturnRepo = SalesReturnRepo();
final saleReturnProvider = FutureProvider.autoDispose<List<SaleTransactionModel>>((ref) => salesReturnRepo.getAllTransition());
