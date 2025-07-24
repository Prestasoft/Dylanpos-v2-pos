import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/bank_model.dart';
import '../Repository/bank_repository.dart';

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  return BankRepository();
});

final banksStreamProvider = StreamProvider<List<BankModel>>((ref) {
  final repository = ref.watch(bankRepositoryProvider);
  return repository.getBanksStream();
});

final allBanksProvider = FutureProvider<List<BankModel>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  return await repository.getAllBanks();
});

final bankByIdProvider = FutureProvider.family<BankModel?, String>((ref, bankId) async {
  final repository = ref.watch(bankRepositoryProvider);
  return await repository.getBankById(bankId);
});

class BankNotifier extends StateNotifier<AsyncValue<void>> {
  final BankRepository _repository;

  BankNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addBank(BankModel bank) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBank(bank);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBank(BankModel bank) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBank(bank);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBank(String bankId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBank(bankId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> checkBankNameExists(String bankName, {String? excludeBankId}) async {
    try {
      return await _repository.isBankNameExists(bankName, excludeBankId: excludeBankId);
    } catch (e) {
      return false;
    }
  }
}

final bankNotifierProvider = StateNotifierProvider<BankNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(bankRepositoryProvider);
  return BankNotifier(repository);
});