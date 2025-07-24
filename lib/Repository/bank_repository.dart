import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/bank_model.dart';
import '../const.dart';

class BankRepository {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();

  Future<List<BankModel>> getAllBanks() async {
    try {
      final userId = await getUserID();
      final snapshot = await ref.child(userId).child('Banks').get();
      
      if (snapshot.value == null) {
        return [];
      }

      final banksMap = snapshot.value as Map<dynamic, dynamic>;
      final banks = <BankModel>[];
      
      banksMap.forEach((key, value) {
        if (value is Map && (value['isActive'] ?? true)) {
          final bank = BankModel.fromJson(Map<String, dynamic>.from(value));
          bank.bankId = key;
          banks.add(bank);
        }
      });

      // Ordenar por nombre
      banks.sort((a, b) => (a.bankName ?? '').compareTo(b.bankName ?? ''));
      return banks;
    } catch (e) {
      print('Error getting banks: $e');
      return [];
    }
  }

  Stream<List<BankModel>> getBanksStream() {
    return Stream.fromFuture(getUserID()).asyncExpand((userId) {
      return ref.child(userId).child('Banks').onValue.map((event) {
        if (event.snapshot.value == null) {
          return <BankModel>[];
        }

        final banksMap = event.snapshot.value as Map<dynamic, dynamic>;
        final banks = <BankModel>[];
        
        banksMap.forEach((key, value) {
          if (value is Map && (value['isActive'] ?? true)) {
            final bank = BankModel.fromJson(Map<String, dynamic>.from(value));
            bank.bankId = key;
            banks.add(bank);
          }
        });

        // Ordenar por nombre
        banks.sort((a, b) => (a.bankName ?? '').compareTo(b.bankName ?? ''));
        return banks;
      });
    });
  }

  Future<BankModel?> getBankById(String bankId) async {
    try {
      final userId = await getUserID();
      final snapshot = await ref.child(userId).child('Banks').child(bankId).get();
      
      if (snapshot.value != null) {
        final bank = BankModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
        bank.bankId = bankId;
        return bank;
      }
      return null;
    } catch (e) {
      print('Error getting bank: $e');
      return null;
    }
  }

  Future<String> addBank(BankModel bank) async {
    try {
      final userId = await getUserID();
      final newBankRef = ref.child(userId).child('Banks').push();
      bank.bankId = newBankRef.key;
      bank.createdAt = DateTime.now();
      bank.updatedAt = DateTime.now();
      
      await newBankRef.set(bank.toJson());
      return newBankRef.key!;
    } catch (e) {
      print('Error adding bank: $e');
      rethrow;
    }
  }

  Future<void> updateBank(BankModel bank) async {
    try {
      final userId = await getUserID();
      bank.updatedAt = DateTime.now();
      await ref.child(userId).child('Banks').child(bank.bankId!).update(bank.toJson());
    } catch (e) {
      print('Error updating bank: $e');
      rethrow;
    }
  }

  Future<void> deleteBank(String bankId) async {
    try {
      final userId = await getUserID();
      // Soft delete - just mark as inactive
      await ref.child(userId).child('Banks').child(bankId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error deleting bank: $e');
      rethrow;
    }
  }

  Future<bool> isBankNameExists(String bankName, {String? excludeBankId}) async {
    try {
      final banks = await getAllBanks();
      return banks.any((bank) => 
        bank.bankName?.toLowerCase() == bankName.toLowerCase() && 
        bank.bankId != excludeBankId
      );
    } catch (e) {
      print('Error checking bank name: $e');
      return false;
    }
  }
}