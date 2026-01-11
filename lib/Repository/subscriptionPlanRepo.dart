import '../model/subscription_model.dart';
import '../model/subscription_plan_model.dart';
import '../services/api_service.dart';

/// Repositorio de planes de suscripción - Usa PostgreSQL API
class SubscriptionPlanRepo {
  final ApiService _apiService = ApiService();

  /// Obtener todos los planes de suscripción desde PostgreSQL
  Future<List<SubscriptionPlanModel>> getAllSubscriptionPlans() async {
    try {
      final response = await _apiService.get('subscription-plans', queryParams: {'limit': '100'});

      if (response.success && response.data != null) {
        final plansData = response.data['subscription_plans'] as List<dynamic>? ?? [];

        return plansData.map((data) {
          return SubscriptionPlanModel.fromJson(data as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

/// Repositorio de suscripción actual del usuario - Usa PostgreSQL API
class CurrentSubscriptionPlanRepo {
  final ApiService _apiService = ApiService();

  /// Obtener un plan de suscripción por nombre
  Future<SubscriptionPlanModel?> getSubscriptionPlanByName(String planName) async {
    try {
      final response = await _apiService.get('subscription-plans', queryParams: {
        'name': planName,
        'limit': '1',
      });

      if (response.success && response.data != null) {
        final plansData = response.data['subscription_plans'] as List<dynamic>? ?? [];
        if (plansData.isNotEmpty) {
          return SubscriptionPlanModel.fromJson(plansData.first as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener la suscripción actual del usuario
  Future<SubscriptionModel> getCurrentSubscriptionPlans() async {
    SubscriptionModel defaultModel = SubscriptionModel(
      subscriptionName: '',
      subscriptionDate: '',
      saleNumber: 0,
      purchaseNumber: 0,
      partiesNumber: 0,
      dueNumber: 0,
      duration: 0,
      products: 0,
    );

    try {
      final response = await _apiService.get('user-subscription');

      if (response.success && response.data != null) {
        final subscriptionData = response.data['subscription'] ?? response.data;
        if (subscriptionData != null) {
          return SubscriptionModel.fromJson(subscriptionData as Map<String, dynamic>);
        }
      }
      return defaultModel;
    } catch (e) {
      return defaultModel;
    }
  }

  /// Actualizar la suscripción del usuario
  Future<bool> updateUserSubscription(SubscriptionModel subscription) async {
    try {
      final subscriptionData = Map<String, dynamic>.from(subscription.toJson());
      final response = await _apiService.put('user-subscription', subscriptionData);
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
