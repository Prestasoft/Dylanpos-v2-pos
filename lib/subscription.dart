// subscription.dart - Migrado a PostgreSQL API
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import 'model/subscription_model.dart';
import 'model/subscription_plan_model.dart';
import 'services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

class Subscription {
  static List<SubscriptionPlanModel> subscriptionPlan = [];

  static SubscriptionModel freeSubscriptionModel = SubscriptionModel(
    dueNumber: 0,
    duration: 0,
    partiesNumber: 0,
    products: 0,
    purchaseNumber: 0,
    saleNumber: 0,
    subscriptionDate: DateTime.now().toString(),
    subscriptionName: 'Free',
  );
  static String selectedItem = 'Year';

  static bool isExpiringInFiveDays = false;
  static bool isExpiringInOneDays = false;

  /// Obtener datos de límites del usuario - Usa PostgreSQL API
  static Future<void> getUserLimitsData({required BuildContext context, required bool wannaShowMsg}) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiService.get('subscription');

      if (!response.success || response.data == null) {
        return;
      }

      final data = response.data['subscription'] ?? response.data;
      selectedItem = data['subscriptionName']?.toString() ?? 'Free';
      final dataModel = SubscriptionModel.fromJson(Map<String, dynamic>.from(data));
      final remainingTime = DateTime.parse(dataModel.subscriptionDate).difference(DateTime.now());

      if (wannaShowMsg) {
        if (remainingTime.inHours.abs().isBetween((dataModel.duration * 24) - 24, dataModel.duration * 24)) {
          await prefs.setBool('isFiveDayRemainderShown', false);
          isExpiringInOneDays = true;
          isExpiringInFiveDays = false;
        } else if (remainingTime.inHours.abs().isBetween((dataModel.duration * 24) - 120, dataModel.duration * 24)) {
          isExpiringInFiveDays = true;
          isExpiringInOneDays = false;
        }

        final bool isFiveDayRemainderShown = prefs.getBool('isFiveDayRemainderShown') ?? false;

        if (isExpiringInFiveDays && isFiveDayRemainderShown == false) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Your Package Will Expire in 5 Day',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () async {
                          await prefs.setBool('isFiveDayRemainderShown', true);
                          ContextExtensions(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        if (isExpiringInOneDays) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Your Package Will Expire Today\n\nPlease Purchase again',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            TextButton(
                              onPressed: () {
                                ContextExtensions(context).pop();
                                context.go("/subscription");
                              },
                              child: const Text('Purchase'),
                            ),
                            TextButton(
                              onPressed: () {
                                ContextExtensions(context).pop();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo datos de suscripción: $e');
    }
  }

  static Future<bool> subscriptionChecker({required String item}) async {
    // Habilitación de la verificación de suscripción por pedido
    // 18/05/2025
    return true;
  }

  /// Decrementar límites de suscripción - Usa PostgreSQL API
  static void decreaseSubscriptionLimits({required String itemType, required BuildContext context}) async {
    try {
      final response = await _apiService.get('subscription');

      if (response.success && response.data != null) {
        final data = response.data['subscription'] ?? response.data;
        int beforeAction = int.tryParse(data[itemType]?.toString() ?? '0') ?? 0;

        if (beforeAction != -202) {
          int afterAction = beforeAction - 1;
          await _apiService.put('subscription', {itemType: afterAction});
        }
      }

      Subscription.getUserLimitsData(context: context, wannaShowMsg: false);
    } catch (e) {
      debugPrint('Error actualizando límites de suscripción: $e');
    }
  }
}
