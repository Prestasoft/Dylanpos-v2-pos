
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../const.dart'; // Aquí debe estar getUserID()
import '../model/sale_confirmation_model.dart';

/// 🧠 Stream de confirmaciones confirmadas pero aún no notificadas
final unnotifiedConfirmationsProvider = StreamProvider<List<SaleConfirmationModel>>((ref) async* {
  final userId = await getUserID();
  final refPath = FirebaseDatabase.instance.ref("$userId/SaleConfirmations");

  await for (final event in refPath.onValue) {
    final data = event.snapshot.value;

    if (data == null) {
      yield [];
      continue;
    }

    try {
      final Map<dynamic, dynamic> values = data as Map<dynamic, dynamic>;
      final notifications = <SaleConfirmationModel>[];

      values.forEach((_, value) {
        try {
          if (value is Map && 
              value['confirmed'] == true && 
              (value['notified'] == null || value['notified'] == false)) {
            final notification = SaleConfirmationModel.fromJson(
              Map<String, dynamic>.from(value)
            );
            notifications.add(notification);
          }
        } catch (e) {
        }
      });

      yield notifications;
    } catch (e) {
      yield [];
    }
  }
});