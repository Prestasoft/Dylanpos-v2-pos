// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:salespro_admin/Repository/subscriptionPlanRepo.dart';

import '../Screen/Authentication/add_profile.dart';
import '../const.dart';
import '../model/subscription_plan_model.dart';
import '../services/api_service.dart';
import '../subscription.dart';

final signUpProvider = ChangeNotifierProvider((ref) => SignUpRepo());

/// Repositorio de registro de usuarios - Usa PostgreSQL API
class SignUpRepo extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String email = '';
  String password = '';

  /// Registrar nuevo usuario
  Future<void> signUp(BuildContext context) async {
    EasyLoading.show(status: 'Registrando....');
    try {
      mainLoginEmail = email;
      mainLoginPassword = password;

      // Registrar usuario usando PostgreSQL API
      final response = await _apiService.register(
        email: email,
        password: password,
        name: email.split('@').first, // Nombre por defecto basado en email
      );

      if (response.success && response.data != null) {
        final userId = response.data['user']?['id'] ?? '';

        EasyLoading.showSuccess('Exitoso');
        setUserDataOnLocalData(uid: userId, subUserTitle: '', isSubUser: false);
        putUserDataImidiyate(uid: userId, title: '', isSubUse: false);

        SubscriptionPlanRepo subscriptionRepo = SubscriptionPlanRepo();
        List<SubscriptionPlanModel> allSubscriptionPlans = await subscriptionRepo.getAllSubscriptionPlans();

        for (var element in allSubscriptionPlans) {
          if (element.subscriptionName == 'Free') {
            Subscription.freeSubscriptionModel.subscriptionName = element.subscriptionName;
            Subscription.freeSubscriptionModel.subscriptionDate = DateTime.now().toString();
            Subscription.freeSubscriptionModel.saleNumber = element.saleNumber;
            Subscription.freeSubscriptionModel.purchaseNumber = element.purchaseNumber;
            Subscription.freeSubscriptionModel.dueNumber = element.dueNumber;
            Subscription.freeSubscriptionModel.partiesNumber = element.partiesNumber;
            Subscription.freeSubscriptionModel.products = element.products;
            Subscription.freeSubscriptionModel.duration = element.duration;
          }
        }
        context.go(ProfileAdd.route);
      } else {
        EasyLoading.showError('Error al registrar');
        final errorMessage = response.message ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      EasyLoading.showError('Falló con error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class PurchaseModel {
  Future<bool> isActiveBuyer() async {
    final response = await http.get(Uri.parse('https://api.envato.com/v3/market/author/sale?code=$purchaseCode'), headers: {'Authorization': 'Bearer orZoxiU81Ok7kxsE0FvfraaO0vDW5tiz'});
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
