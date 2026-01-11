// dashboard_transaction_provider.dart - Migrado a PostgreSQL API
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/daily_transaction_model.dart';
import '../model/daily_summary_model.dart';
import '../services/api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

/// Repository class for daily transactions dashboard - Usa PostgreSQL API
class DashboardTransactionRepo {
  /// Obtener transacciones diarias por fecha desde PostgreSQL
  Future<List<DailyTransactionModel>> getDailyTransactions(String date) async {
    try {
      final response = await _apiService.get('daily-transactions', queryParams: {
        'date': date,
        'limit': '1000',
      });

      if (!response.success || response.data == null) {
        return [];
      }

      final transactionsData = response.data['daily_transactions'] as List<dynamic>? ??
                               response.data['transactions'] as List<dynamic>? ?? [];
      List<DailyTransactionModel> transactions = [];

      for (var item in transactionsData) {
        try {
          if (item is Map) {
            final transactionData = Map<String, dynamic>.from(item);
            transactionData['id'] = transactionData['id']?.toString() ?? '';
            transactions.add(DailyTransactionModel.fromJson(transactionData));
          }
        } catch (e) {
          // Error silencioso para elementos inválidos
        }
      }

      return transactions;
    } catch (e) {
      return [];
    }
  }

  /// Stream de transacciones diarias - Usa StreamController con polling
  Stream<List<DailyTransactionModel>> getDailyTransactionsStream(String date) {
    final controller = StreamController<List<DailyTransactionModel>>();

    Future<void> fetchTransactions() async {
      try {
        final transactions = await getDailyTransactions(date);
        if (!controller.isClosed) {
          controller.add(transactions);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    // Fetch inicial
    fetchTransactions();

    // Refresh periódico cada 30 segundos
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchTransactions());

    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

/// Repository instance
final DashboardTransactionRepo dashboardTransactionRepo = DashboardTransactionRepo();

/// Provider for daily transactions by date (for dashboard) - Usa PostgreSQL API
final dashboardTransactionsProvider = StreamProvider.family<List<DailyTransactionModel>, String>((ref, date) {
  final controller = StreamController<List<DailyTransactionModel>>();

  Future<void> fetchTransactions() async {
    try {
      final transactions = await dashboardTransactionRepo.getDailyTransactions(date);
      if (!controller.isClosed) {
        controller.add(transactions);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
  }

  // Fetch inicial
  fetchTransactions();

  // Refresh periódico
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchTransactions());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider for daily summary by date (for dashboard)
final dashboardSummaryProvider = Provider.family<AsyncValue<DailySummaryModel>, String>((ref, date) {
  final transactionsAsync = ref.watch(dashboardTransactionsProvider(date));

  return transactionsAsync.when(
    data: (transactions) => AsyncValue.data(DailySummaryModel.fromDailyTransactions(transactions)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for current date transactions (today) - for dashboard
final todayDashboardTransactionsProvider = StreamProvider<List<DailyTransactionModel>>((ref) {
  final controller = StreamController<List<DailyTransactionModel>>();
  final today = DateTime.now();
  final dateStr = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

  Future<void> fetchTransactions() async {
    try {
      final transactions = await dashboardTransactionRepo.getDailyTransactions(dateStr);
      if (!controller.isClosed) {
        controller.add(transactions);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
  }

  // Fetch inicial
  fetchTransactions();

  // Refresh periódico
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchTransactions());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider for today's summary - for dashboard
final todayDashboardSummaryProvider = Provider<AsyncValue<DailySummaryModel>>((ref) {
  final transactionsAsync = ref.watch(todayDashboardTransactionsProvider);

  return transactionsAsync.when(
    data: (transactions) => AsyncValue.data(DailySummaryModel.fromDailyTransactions(transactions)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
