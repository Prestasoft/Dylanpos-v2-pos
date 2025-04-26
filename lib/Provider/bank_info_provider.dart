import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Repository/bank_info_repo.dart';
import '../model/bank_info_model.dart';

BankInfoRepo bankRepo = BankInfoRepo();
final bankInfoProvider = FutureProvider<BankInfoModel>((ref) => bankRepo.getPaypalInfo());
