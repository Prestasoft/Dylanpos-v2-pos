import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/daily_transaction_model.dart';
import '../model/daily_summary_model.dart';
import '../const.dart';

// Repository class for daily transactions dashboard
class DashboardTransactionRepo {
  Future<List<DailyTransactionModel>> getDailyTransactions(String date) async {
    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref(constUserId).child('Daily Transaction');
      final DatabaseEvent event = await ref.orderByChild('date').equalTo(date).once();
      
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<DailyTransactionModel> transactions = [];
        
        data.forEach((key, value) {
          try {
            final transactionData = Map<String, dynamic>.from(value);
            transactionData['id'] = key;
            transactions.add(DailyTransactionModel.fromJson(transactionData));
          } catch (e) {
            print('Error parsing transaction $key: $e');
          }
        });
        
        return transactions;
      }
      return [];
    } catch (e) {
      print('Error fetching daily transactions: $e');
      return [];
    }
  }

  Stream<List<DailyTransactionModel>> getDailyTransactionsStream(String date) {
    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref(constUserId).child('Daily Transaction');
      return ref.orderByChild('date').equalTo(date).onValue.map((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          List<DailyTransactionModel> transactions = [];
          
          data.forEach((key, value) {
            try {
              final transactionData = Map<String, dynamic>.from(value);
              transactionData['id'] = key;
              transactions.add(DailyTransactionModel.fromJson(transactionData));
            } catch (e) {
              print('Error parsing transaction $key: $e');
            }
          });
          
          return transactions;
        }
        return <DailyTransactionModel>[];
      });
    } catch (e) {
      print('Error streaming daily transactions: $e');
      return Stream.value(<DailyTransactionModel>[]);
    }
  }
}

// Repository instance
final DashboardTransactionRepo dashboardTransactionRepo = DashboardTransactionRepo();

// Provider for daily transactions by date (for dashboard)
final dashboardTransactionsProvider = StreamProvider.family<List<DailyTransactionModel>, String>((ref, date) {
  return dashboardTransactionRepo.getDailyTransactionsStream(date);
});

// Provider for daily summary by date (for dashboard)
final dashboardSummaryProvider = Provider.family<AsyncValue<DailySummaryModel>, String>((ref, date) {
  final transactionsAsync = ref.watch(dashboardTransactionsProvider(date));
  
  return transactionsAsync.when(
    data: (transactions) => AsyncValue.data(DailySummaryModel.fromDailyTransactions(transactions)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Provider for current date transactions (today) - for dashboard
final todayDashboardTransactionsProvider = StreamProvider<List<DailyTransactionModel>>((ref) {
  final today = DateTime.now();
  final dateStr = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';
  return dashboardTransactionRepo.getDailyTransactionsStream(dateStr);
});

// Provider for today's summary - for dashboard
final todayDashboardSummaryProvider = Provider<AsyncValue<DailySummaryModel>>((ref) {
  final transactionsAsync = ref.watch(todayDashboardTransactionsProvider);
  
  return transactionsAsync.when(
    data: (transactions) => AsyncValue.data(DailySummaryModel.fromDailyTransactions(transactions)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});