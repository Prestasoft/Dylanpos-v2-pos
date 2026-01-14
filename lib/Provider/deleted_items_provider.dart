// deleted_items_provider.dart - Provider para elementos eliminados
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/audit_model.dart';
import '../services/api_service.dart';

final deletedItemsProvider = FutureProvider.autoDispose.family<List<AuditModel>, DeletedItemsFilters>(
  (ref, filters) async {
    final apiService = ApiService();

    final queryParams = <String, String>{
      'action': 'delete',
      'limit': filters.limit.toString(),
      'offset': filters.offset.toString(),
    };

    if (filters.startDate != null) {
      queryParams['startDate'] = filters.startDate!;
    }

    if (filters.endDate != null) {
      queryParams['endDate'] = filters.endDate!;
    }

    if (filters.module != null && filters.module!.isNotEmpty) {
      queryParams['entityType'] = filters.module!;
    }

    try {
      final response = await apiService.get('audits', queryParams: queryParams);

      if (response.success && response.data != null) {
        final audits = response.data['audits'] as List<dynamic>? ?? [];
        return audits.map((audit) => AuditModel.fromJson(Map<String, dynamic>.from(audit))).toList();
      }

      return [];
    } catch (e) {
      developer.log('Error obteniendo elementos eliminados: $e', name: 'DeletedItemsProvider');
      return [];
    }
  },
);

// Provider para el conteo total
final deletedItemsCountProvider = FutureProvider.autoDispose.family<int, DeletedItemsFilters>(
  (ref, filters) async {
    final apiService = ApiService();

    final queryParams = <String, String>{
      'action': 'delete',
      'limit': '1', // Solo necesitamos el total
      'offset': '0',
    };

    if (filters.startDate != null) {
      queryParams['startDate'] = filters.startDate!;
    }

    if (filters.endDate != null) {
      queryParams['endDate'] = filters.endDate!;
    }

    if (filters.module != null && filters.module!.isNotEmpty) {
      queryParams['entityType'] = filters.module!;
    }

    try {
      final response = await apiService.get('audits', queryParams: queryParams);

      if (response.success && response.data != null) {
        return response.data['total'] as int? ?? 0;
      }

      return 0;
    } catch (e) {
      developer.log('Error obteniendo conteo de eliminados: $e', name: 'DeletedItemsProvider');
      return 0;
    }
  },
);

// Clase para filtros
class DeletedItemsFilters {
  final String? startDate;
  final String? endDate;
  final String? module;
  final int limit;
  final int offset;

  const DeletedItemsFilters({
    this.startDate,
    this.endDate,
    this.module,
    this.limit = 50,
    this.offset = 0,
  });

  DeletedItemsFilters copyWith({
    String? startDate,
    String? endDate,
    String? module,
    int? limit,
    int? offset,
  }) {
    return DeletedItemsFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      module: module ?? this.module,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeletedItemsFilters &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.module == module &&
      other.limit == limit &&
      other.offset == offset;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^
      endDate.hashCode ^
      module.hashCode ^
      limit.hashCode ^
      offset.hashCode;
  }
}
