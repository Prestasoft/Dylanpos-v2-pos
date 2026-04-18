import 'package:flutter/foundation.dart';
import '../model/task_model.dart';
import '../services/api_service.dart';

/// Repositorio del sistema de tareas — consume /api/hrm/tasks
class TaskRepository {
  final ApiService _apiService = ApiService();

  /// El ApiService a veces retorna el body completo {success, data: {...}}
  /// en resp.data, y a veces solo el contenido de data directamente.
  /// Este helper normaliza para siempre obtener el contenido inner.
  Map<String, dynamic> _unwrapData(Map<String, dynamic>? data) {
    if (data == null) return {};
    // Si resp.data tiene key 'data', es el body completo → unwrap
    if (data.containsKey('data') && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return data;
  }

  /// GET /api/hrm/tasks con filtros opcionales
  Future<List<TaskModel>> getTasks({
    String? assignedToUserId,
    num? designationId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final qp = <String, String>{};
    if (assignedToUserId != null) qp['assigned_to_user_id'] = assignedToUserId;
    if (designationId != null) qp['designation_id'] = designationId.toString();
    if (status != null) qp['status'] = status;
    if (dateFrom != null) qp['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) qp['date_to'] = dateTo.toIso8601String();

    final resp = await _apiService.get('hrm/tasks', queryParams: qp);
    if (!resp.success || resp.data == null) return [];
    final inner = _unwrapData(resp.data);
    final list = (inner['tasks'] as List?) ?? const [];
    return list
        .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/hrm/tasks/my — tareas del user autenticado (vista empleado)
  Future<List<TaskModel>> getMyTasks() async {
    final resp = await _apiService.get('hrm/tasks/my');
    if (!resp.success || resp.data == null) return [];
    final inner = _unwrapData(resp.data);
    final list = (inner['tasks'] as List?) ?? const [];
    debugPrint('🔵 [TaskRepo.getMyTasks] Tasks: ${list.length}');
    return list
        .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/hrm/tasks/department-status — panel del encargado
  Future<Map<String, dynamic>> getDepartmentStatus({num? designationId}) async {
    final qp = <String, String>{};
    if (designationId != null) qp['designation_id'] = designationId.toString();
    final resp = await _apiService.get('hrm/tasks/department-status', queryParams: qp);
    if (!resp.success || resp.data == null) return {'employees': [], 'totals': {}};
    final inner = _unwrapData(resp.data);
    return inner;
  }

  /// POST /api/hrm/tasks — crea tarea con due_at calculado por el backend
  Future<TaskModel?> createTask({
    required String reservationId,
    required num designationId,
    String? assignedToUserId,
    String? assignedToEmployeeId,
  }) async {
    final body = {
      'reservation_id': reservationId,
      'designation_id': designationId,
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      if (assignedToEmployeeId != null) 'assigned_to_employee_id': assignedToEmployeeId,
    };
    final resp = await _apiService.post('hrm/tasks', body);
    if (!resp.success || resp.data == null) return null;
    final inner = _unwrapData(resp.data);
    final taskData = inner['task'];
    if (taskData == null) return null;
    return TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map));
  }

  /// PUT /api/hrm/tasks/:id — reasigna empleado O actualiza nota.
  Future<TaskModel?> updateTask({
    required String taskId,
    String? assignedToUserId,
    String? assignedToEmployeeId,
    String? status,
    String? completionNote,
  }) async {
    final body = <String, dynamic>{};
    if (assignedToUserId != null) body['assigned_to_user_id'] = assignedToUserId;
    if (assignedToEmployeeId != null) body['assigned_to_employee_id'] = assignedToEmployeeId;
    if (status != null) body['status'] = status;
    if (completionNote != null) body['completion_note'] = completionNote;

    final resp = await _apiService.put('hrm/tasks/$taskId', body);
    if (!resp.success || resp.data == null) return null;
    final inner = _unwrapData(resp.data);
    final taskData = inner['task'];
    if (taskData == null) return null;
    return TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map));
  }

  /// POST /api/hrm/tasks/:id/start — Empleado inicia la tarea
  Future<TaskModel?> startTask({required String taskId}) async {
    final resp = await _apiService.post('hrm/tasks/$taskId/start', {});
    if (!resp.success || resp.data == null) return null;
    final inner = _unwrapData(resp.data);
    final taskData = inner['task'];
    if (taskData == null) return null;
    return TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map));
  }

  /// POST /api/hrm/tasks/:id/complete
  Future<TaskModel?> completeTask({
    required String taskId,
    String? completionNote,
  }) async {
    final body = <String, dynamic>{};
    if (completionNote != null) body['completion_note'] = completionNote;
    final resp = await _apiService.post('hrm/tasks/$taskId/complete', body);
    if (!resp.success || resp.data == null) return null;
    final inner = _unwrapData(resp.data);
    final taskData = inner['task'];
    if (taskData == null) return null;
    return TaskModel.fromJson(Map<String, dynamic>.from(taskData as Map));
  }

  /// POST /api/hrm/tasks/mark-overdue — helper para vencer tareas pasadas
  Future<int> markOverdue() async {
    final resp = await _apiService.post('hrm/tasks/mark-overdue', {});
    if (!resp.success || resp.data == null) return 0;
    final inner = _unwrapData(resp.data);
    return (inner['marked_overdue'] as int?) ?? 0;
  }

  /// DELETE /api/hrm/tasks/:id
  Future<bool> deleteTask(String taskId) async {
    final resp = await _apiService.delete('hrm/tasks/$taskId');
    return resp.success;
  }
}
