import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Repository/subscriptionPlanRepo.dart';
import '../model/subscription_model.dart';
import '../model/subscription_plan_model.dart';

SubscriptionPlanRepo subscriptionRepo = SubscriptionPlanRepo();
CurrentSubscriptionPlanRepo currentSubscriptionPlanRepo = CurrentSubscriptionPlanRepo();
final subscriptionPlanProvider = FutureProvider<List<SubscriptionPlanModel>>((ref) => subscriptionRepo.getAllSubscriptionPlans());
final singleUserSubscriptionPlanProvider = FutureProvider<SubscriptionModel>((ref) => currentSubscriptionPlanRepo.getCurrentSubscriptionPlans());
