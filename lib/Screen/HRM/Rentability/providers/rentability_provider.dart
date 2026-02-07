import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commission_config_model.dart';
import '../models/employee_performance_model.dart';
import '../repo/rentability_repo.dart';

/// Repository provider
final rentabilityRepositoryProvider = Provider<RentabilityRepository>((ref) {
  return RentabilityRepository();
});

/// Provider de configuración de comisiones
final commissionConfigProvider = FutureProvider<CommissionConfig>((ref) async {
  final repo = ref.read(rentabilityRepositoryProvider);
  final config = await repo.getCommissionConfig();

  // Si no existe configuración, retornar configuración por defecto
  if (config == null) {
    // TODO: Obtener branchId del usuario actual
    return CommissionConfig.defaultConfig('current_branch_id');
  }

  return config;
});

/// Provider de desempeño de todos los empleados
/// Usa el período del periodProvider para evitar recreación de parámetros
final employeesPerformanceProvider2 = FutureProvider<List<EmployeePerformance>>(
  (ref) async {
    final period = ref.watch(periodProvider);
    final repo = ref.read(rentabilityRepositoryProvider);

    return await repo.getEmployeesPerformance(
      startDate: period.startDate,
      endDate: period.endDate,
    );
  },
);

/// Provider legacy con family (mantener por compatibilidad)
final employeesPerformanceProvider = FutureProvider.family<List<EmployeePerformance>, Map<String, DateTime>>(
  (ref, params) async {
    final repo = ref.read(rentabilityRepositoryProvider);
    final startDate = params['startDate']!;
    final endDate = params['endDate']!;

    return await repo.getEmployeesPerformance(
      startDate: startDate,
      endDate: endDate,
    );
  },
);

/// Provider de desempeño de un empleado específico por ID
/// Usa periodProvider internamente para evitar loops infinitos
final employeePerformanceByIdProvider = FutureProvider.family<EmployeePerformance?, String>(
  (ref, employeeId) async {
    final period = ref.watch(periodProvider);
    final repo = ref.read(rentabilityRepositoryProvider);

    return await repo.getEmployeePerformance(
      employeeId: employeeId,
      startDate: period.startDate,
      endDate: period.endDate,
    );
  },
);

/// Provider legacy con family Map (mantener por compatibilidad)
final employeePerformanceProvider = FutureProvider.family<EmployeePerformance?, Map<String, dynamic>>(
  (ref, params) async {
    final repo = ref.read(rentabilityRepositoryProvider);
    final employeeId = params['employeeId'] as String;
    final startDate = params['startDate'] as DateTime;
    final endDate = params['endDate'] as DateTime;

    return await repo.getEmployeePerformance(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  },
);

/// Provider de reservas pendientes de facturar
final pendingInvoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(rentabilityRepositoryProvider);
  return await repo.getPendingInvoices();
});

/// Estado para controlar el período seleccionado (mes actual por defecto)
class PeriodState {
  final DateTime startDate;
  final DateTime endDate;
  final String filter; // 'month', 'quarter', 'year', 'custom'

  PeriodState({
    required this.startDate,
    required this.endDate,
    this.filter = 'month',
  });

  factory PeriodState.currentMonth() {
    final now = DateTime.now();
    return PeriodState(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
      filter: 'month',
    );
  }

  PeriodState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? filter,
  }) {
    return PeriodState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filter: filter ?? this.filter,
    );
  }
}

/// Notifier para manejar el período seleccionado
class PeriodNotifier extends StateNotifier<PeriodState> {
  PeriodNotifier() : super(PeriodState.currentMonth());

  void setFilter(String filter) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (filter) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'quarter':
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = state.startDate;
        endDate = state.endDate;
    }

    state = PeriodState(
      startDate: startDate,
      endDate: endDate,
      filter: filter,
    );
  }

  void setCustomPeriod(DateTime start, DateTime end) {
    state = PeriodState(
      startDate: start,
      endDate: end,
      filter: 'custom',
    );
  }
}

final periodProvider = StateNotifierProvider<PeriodNotifier, PeriodState>((ref) {
  return PeriodNotifier();
});
