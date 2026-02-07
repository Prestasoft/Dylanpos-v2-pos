import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_goals_model.dart';
import '../repo/goals_repository.dart';

/// Repository provider
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository();
});

/// Provider de metas de un empleado específico
/// Recibe parámetros: {employee_id, year, month}
final employeeGoalsProvider = FutureProvider.family<List<EmployeeGoal>, Map<String, dynamic>>(
  (ref, params) async {
    final repo = ref.read(goalsRepositoryProvider);
    final employeeId = params['employee_id'] as String;
    final year = params['year'] as int;
    final month = params['month'] as int;

    return await repo.getEmployeeGoals(
      employeeId: employeeId,
      year: year,
      month: month,
    );
  },
);

/// Provider de todas las metas de un período
/// Recibe parámetros: {year, month}
final allGoalsProvider = FutureProvider.family<List<EmployeeGoal>, Map<String, int>>(
  (ref, params) async {
    final repo = ref.read(goalsRepositoryProvider);
    final year = params['year']!;
    final month = params['month']!;

    return await repo.getAllGoals(
      year: year,
      month: month,
    );
  },
);
