// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:salespro_admin/Repository/subscriptionPlanRepo.dart';

import '../Screen/Authentication/add_profile.dart';
import '../const.dart';
import '../model/subscription_plan_model.dart';
import '../subscription.dart';

final signUpProvider = ChangeNotifierProvider((ref) => SignUpRepo());

class SignUpRepo extends ChangeNotifier {
  String email = '';
  String password = '';

  Future<void> signUp(BuildContext context) async {
    EasyLoading.show(status: 'Registrando....');
    try {
      mainLoginEmail = email;
      mainLoginPassword = password;
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

      EasyLoading.showSuccess('Exitoso');
      setUserDataOnLocalData(uid: FirebaseAuth.instance.currentUser!.uid, subUserTitle: '', isSubUser: false);
      putUserDataImidiyate(uid: FirebaseAuth.instance.currentUser!.uid, title: '', isSubUse: false);
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
      // const ProfileAdd().launch(context);
      context.go(ProfileAdd.route);
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError('Falló con error');
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La contraseña proporcionada es demasiado débil.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cuenta ya existe para ese correo electrónico.'),
            duration: Duration(seconds: 3),
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
