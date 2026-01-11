import 'package:flutter/foundation.dart';
import 'base_repository.dart';
import '../supabase_auth_service.dart';

/// Modelo de Gasto para Supabase
class ExpenseModel {
  final String? id;
  final String branchId;
  final String category;
  final String? description;
  final double amount;
  final DateTime date;
  final String? paymentMethod;
  final String? createdBy;
  final DateTime? createdAt;

  ExpenseModel({
    this.id,
    required this.branchId,
    required this.category,
    this.description,
    required this.amount,
    required this.date,
    this.paymentMethod,
    this.createdBy,
    this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id']?.toString(),
      branchId: map['branch_id'] ?? '',
      category: map['category'] ?? '',
      description: map['description'],
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      paymentMethod: map['payment_method'],
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'branch_id': branchId,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'created_by': createdBy,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? branchId,
    String? category,
    String? description,
    double? amount,
    DateTime? date,
    String? paymentMethod,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

/// Repositorio de Gastos
class ExpenseRepository extends BaseRepository<ExpenseModel> {
  @override
  final String tableName = 'expenses';

  @override
  ExpenseModel fromMap(Map<String, dynamic> map) => ExpenseModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ExpenseModel model) => model.toMap();

  /// Crear gasto
  Future<ExpenseModel?> createExpense(ExpenseModel expense) async {
    try {
      final data = expense.toMap();
      data['branch_id'] = currentBranchId;
      data['created_by'] = supabaseAuth.currentUserId;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(tableName)
          .insert(data)
          .select()
          .single();

      debugPrint('✅ Gasto creado');
      return ExpenseModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('❌ Error al crear gasto: $e');
      return null;
    }
  }

  /// Obtener gastos por fecha
  Future<List<ExpenseModel>> getByDate(DateTime date) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .eq('date', dateStr)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ExpenseModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener gastos por rango de fechas
  Future<List<ExpenseModel>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final response = await client
          .from(tableName)
          .select()
          .eq('branch_id', branchId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: false);

      return (response as List)
          .map((item) => ExpenseModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener gastos por categoría
  Future<List<ExpenseModel>> getByCategory(String category) async {
    return findBy('category', category);
  }

  /// Obtener categorías de gastos usadas
  Future<List<String>> getCategories() async {
    try {
      final expenses = await getAll();
      final categories = expenses.map((e) => e.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }

  /// Obtener total de gastos por fecha
  Future<double> getTotalByDate(DateTime date) async {
    final expenses = await getByDate(date);
    double total = 0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }

  /// Obtener total de gastos por rango de fechas
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final expenses = await getByDateRange(start, end);
    double total = 0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }

  /// Obtener resumen de gastos por categoría
  Future<Map<String, double>> getSummaryByCategory(DateTime start, DateTime end) async {
    final expenses = await getByDateRange(start, end);
    final summary = <String, double>{};

    for (final expense in expenses) {
      summary[expense.category] = (summary[expense.category] ?? 0) + expense.amount;
    }

    return summary;
  }
}

/// Instancia global del repositorio
final expenseRepository = ExpenseRepository();
