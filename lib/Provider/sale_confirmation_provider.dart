// sale_confirmation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/sale_confirmation_model.dart';
import '../const.dart';

final saleConfirmationsProvider = AsyncNotifierProvider<SaleConfirmationsNotifier, List<SaleConfirmationModel>>(
  SaleConfirmationsNotifier.new,
);

class SaleConfirmationsNotifier extends AsyncNotifier<List<SaleConfirmationModel>> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _forceRefresh = false;

  @override
  Future<List<SaleConfirmationModel>> build() async {
    if (_forceRefresh) {
      _forceRefresh = false;
      state = await AsyncValue.guard(_fetchConfirmations);
    }
    return _fetchConfirmations();
  }

  Future<List<SaleConfirmationModel>> _fetchConfirmations() async {
    try {
      final userId = await getUserID();
      final DatabaseReference ref = _dbRef.child('$userId/SaleConfirmations');
      
      final snapshot = await ref.get();
      
      if (!snapshot.exists) {
        return [];
      }

      final dynamic data = snapshot.value;
      if (data == null) {
        return [];
      }

      final List<SaleConfirmationModel> confirmations = [];
      
      if (data is Map) {
        data.forEach((key, value) {
          try {
            if (value is Map) {
              final confirmationData = Map<String, dynamic>.from(value);
              // confirmationData['token'] = key;
              final confirmation = SaleConfirmationModel.fromJson(confirmationData);
              confirmations.add(confirmation);
            }
          } catch (e) {
          }
        });
      }

      return confirmations;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshConfirmations() async {
    _forceRefresh = true;
    ref.invalidateSelf();
  }

  Future<void> updateConfirmation(SaleConfirmationModel confirmation) async {
    try {
      final userId = await getUserID();
      await _dbRef.child('$userId/SaleConfirmations/${confirmation.token}').update(confirmation.toJson());
      await refreshConfirmations();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteConfirmation(String token) async {
    try {
      final userId = await getUserID();
      await _dbRef.child('$userId/SaleConfirmations/$token').remove();
      await refreshConfirmations();
    } catch (e) {
      rethrow;
    }
  }
}