// ignore_for_file: use_build_context_synchronously

// class FirebaseAuthentication {
//   sendOTP(String phoneNumber) async {
//     FirebaseAuth auth = FirebaseAuth.instance;
//     ConfirmationResult confirmationResult = await auth.signInWithPhoneNumber(
//       phoneNumber,
//     );
//
//     return confirmationResult;
//   }
//
//   authenticateMe(
//       {required ConfirmationResult confirmationResult,
//       required String otp,
//       required BuildContext context,
//       required TextEditingController otpController,
//       required String phone}) async {
//     try {
//       SubscriptionPlanRepo subscriptionRepo = SubscriptionPlanRepo();
//       List<SubscriptionPlanModel> allSubscriptionPlans = await subscriptionRepo.getAllSubscriptionPlans();
//
//       for (var element in allSubscriptionPlans) {
//         if (element.subscriptionName == 'Free') {
//           Subscription.freeSubscriptionModel.subscriptionName = element.subscriptionName;
//           Subscription.freeSubscriptionModel.subscriptionDate = DateTime.now().toString();
//           Subscription.freeSubscriptionModel.saleNumber = element.saleNumber;
//           Subscription.freeSubscriptionModel.purchaseNumber = element.purchaseNumber;
//           Subscription.freeSubscriptionModel.dueNumber = element.dueNumber;
//           Subscription.freeSubscriptionModel.partiesNumber = element.partiesNumber;
//           Subscription.freeSubscriptionModel.products = element.products;
//           Subscription.freeSubscriptionModel.duration = element.duration;
//         }
//       }
//       UserCredential userCredential = await confirmationResult.confirm(otp);
//       Subscription.getUserLimitsData(context: context, wannaShowMsg: true);
//       //
//       userCredential.additionalUserInfo!.isNewUser ? const ProfileAdd().launch(context) : const MtHomeScreen().launch(context);
//     } catch (e) {
//       otpController.clear();
//       EasyLoading.showError('Wrong OTP');
//     }
//   }
// }
