import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/designation_model.dart';
import '../repo/designation_repo.dart';

DesignationRepository expenseCategoryRepo = DesignationRepository();
final designationProvider = FutureProvider<List<DesignationModel>>((ref) => expenseCategoryRepo.getAllDesignation());
