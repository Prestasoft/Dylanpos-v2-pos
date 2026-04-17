import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'department_model.dart';
import 'department_repo.dart';

final departmentProvider = FutureProvider.autoDispose<List<DepartmentModel>>((ref) {
  return DepartmentRepository().getAll();
});