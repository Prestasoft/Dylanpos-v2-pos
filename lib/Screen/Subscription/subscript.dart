import 'package:flutter/material.dart';
import 'package:salespro_admin/services/api_service.dart';

import '../../model/subscription_model.dart';
import '../../model/subscription_plan_model.dart';

class Subscript {
  static List<SubscriptionPlanModel> subscriptionPlan = [];
  static SubscriptionPlanModel customersActivePlan = SubscriptionPlanModel(
    subscriptionName: 'Free',
    saleNumber: 0,
    purchaseNumber: 0,
    products: 0,
    partiesNumber: 0,
    duration: 0,
    dueNumber: 0,
    offerPrice: 0,
    subscriptionPrice: 0,
  );
  static const String currency = 'USD';
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

  static void decreaseSubscriptionLimits({required String itemType, required BuildContext context}) async {
    final apiService = ApiService();

    // Obtener la suscripción actual
    final response = await apiService.get('subscriptions/current');

    if (response.success && response.data != null) {
      final data = response.data;
      Map<String, dynamic>? subscriptionData;

      if (data is Map && data['subscription'] != null) {
        subscriptionData = Map<String, dynamic>.from(data['subscription']);
      } else if (data is Map) {
        subscriptionData = Map<String, dynamic>.from(data);
      }

      if (subscriptionData != null) {
        int beforeAction = int.tryParse(subscriptionData[itemType]?.toString() ?? '0') ?? 0;
        if (beforeAction != -202) {
          int afterAction = beforeAction - 1;
          await apiService.put('subscriptions/current', {itemType: afterAction});
        }
      }
    }
  }
}
