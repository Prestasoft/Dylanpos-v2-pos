// audit_service.dart - Migrado a PostgreSQL API
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../model/audit_model.dart';
import 'api_service.dart';

/// Servicio API compartido
final ApiService _apiService = ApiService();

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  // Cache del usuario actual para evitar llamadas repetitivas
  static String? _currentUserId;
  static String? _currentUserName;
  static String? _currentUserEmail;

  /// Establece el usuario actual para el logging
  static void setCurrentUser({
    required String userId,
    required String userName,
    required String userEmail,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserEmail = userEmail;
  }

  /// Limpiar usuario al cerrar sesión
  static void clearCurrentUser() {
    _currentUserId = null;
    _currentUserName = null;
    _currentUserEmail = null;
  }

  /// Registrar una acción en el sistema de auditoría - Usa PostgreSQL API
  Future<void> logAction({
    required AuditAction action,
    required AuditModule module,
    required String description,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
    String? specificUserId,
    String? specificUserName,
    String? specificUserEmail,
  }) async {
    try {
      final userId = specificUserId ?? _currentUserId ?? 'unknown';
      final userName = specificUserName ?? _currentUserName ?? 'Usuario Desconocido';
      final userEmail = specificUserEmail ?? _currentUserEmail ?? 'email_no_disponible';

      final auditId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      final audit = AuditModel(
        id: auditId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        action: action.value,
        module: module.value,
        description: description,
        ipAddress: await _getIpAddress(),
        userAgent: await _getUserAgent(),
        beforeData: beforeData,
        afterData: afterData,
        createdAt: now,
      );

      // Guardar en PostgreSQL API
      await _apiService.post('audits', audit.toJson());

      // Log en consola para desarrollo
      if (kDebugMode) {
        debugPrint('🔍 AUDIT LOG: ${action.name} en ${module.name} - $description');
        debugPrint('👤 Usuario: $userName ($userId)');
        if (beforeData != null || afterData != null) {
          debugPrint('📋 Cambios registrados');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al registrar auditoría: $e');
      // No lanzar excepción para evitar interrumpir el flujo principal
    }
  }

  /// Método conveniente para login
  Future<void> logLogin(String userId, String userName, String userEmail) async {
    setCurrentUser(userId: userId, userName: userName, userEmail: userEmail);

    await logAction(
      action: AuditAction.login,
      module: AuditModule.authentication,
      description: 'Usuario inició sesión en el sistema',
    );
  }

  /// Método conveniente para logout
  Future<void> logLogout() async {
    await logAction(
      action: AuditAction.logout,
      module: AuditModule.authentication,
      description: 'Usuario cerró sesión',
    );

    clearCurrentUser();
  }

  /// Método conveniente para crear registros
  Future<void> logCreate({
    required AuditModule module,
    required String itemName,
    required String itemId,
    Map<String, dynamic>? data,
  }) async {
    await logAction(
      action: AuditAction.create,
      module: module,
      description: 'Creó $itemName con ID: $itemId',
      afterData: data,
    );
  }

  /// Método conveniente para actualizar registros
  Future<void> logUpdate({
    required AuditModule module,
    required String itemName,
    required String itemId,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
  }) async {
    await logAction(
      action: AuditAction.update,
      module: module,
      description: 'Actualizó $itemName con ID: $itemId',
      beforeData: beforeData,
      afterData: afterData,
    );
  }

  /// Método conveniente para eliminar registros
  Future<void> logDelete({
    required AuditModule module,
    required String itemName,
    required String itemId,
    Map<String, dynamic>? data,
  }) async {
    await logAction(
      action: AuditAction.delete,
      module: module,
      description: 'Eliminó $itemName con ID: $itemId',
      beforeData: data,
    );
  }

  /// Método conveniente para ventas
  Future<void> logSale({
    required String invoiceNumber,
    required String customerName,
    required double amount,
    required List<Map<String, dynamic>> products,
  }) async {
    await logAction(
      action: AuditAction.create,
      module: AuditModule.sales,
      description: 'Registró venta #$invoiceNumber para $customerName por \$${amount.toStringAsFixed(2)}',
      afterData: {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'amount': amount,
        'productCount': products.length,
        'products': products,
      },
    );
  }

  /// Método conveniente para imprimir
  Future<void> logPrint({
    required AuditModule module,
    required String documentType,
    required String documentId,
  }) async {
    await logAction(
      action: AuditAction.print,
      module: module,
      description: 'Imprimió $documentType: $documentId',
    );
  }

  /// Obtener registros de auditoría con filtros - Usa PostgreSQL API
  Future<List<AuditModel>> getAuditLogs({
    String? userId,
    String? action,
    String? module,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (userId != null) queryParams['user_id'] = userId;
      if (action != null) queryParams['action'] = action;
      if (module != null) queryParams['module'] = module;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      debugPrint('🔍 [AuditService.getAuditLogs] Consultando audits con params: $queryParams');
      final response = await _apiService.get('audits', queryParams: queryParams);

      debugPrint('🔍 [AuditService.getAuditLogs] Response success: ${response.success}');
      debugPrint('🔍 [AuditService.getAuditLogs] Response error: ${response.error}');
      debugPrint('🔍 [AuditService.getAuditLogs] Response data type: ${response.data?.runtimeType}');
      debugPrint('🔍 [AuditService.getAuditLogs] Response data: ${response.data}');

      if (!response.success || response.data == null) {
        debugPrint('❌ [AuditService.getAuditLogs] No hay datos o respuesta fallida');
        return [];
      }

      final auditsData = response.data['audits'] as List<dynamic>? ?? [];
      debugPrint('🔍 [AuditService.getAuditLogs] Audits encontrados: ${auditsData.length}');
      final List<AuditModel> audits = [];

      for (var item in auditsData) {
        try {
          if (item is Map) {
            final auditData = Map<String, dynamic>.from(item);
            audits.add(AuditModel.fromJson(auditData));
          }
        } catch (e) {
          debugPrint('Error procesando registro de auditoría: $e');
        }
      }

      // Ordenar por fecha (más reciente primero)
      audits.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return audits;
    } catch (e) {
      debugPrint('Error obteniendo logs de auditoría: $e');
      return [];
    }
  }

  /// Obtener estadísticas de auditoría - Usa PostgreSQL API
  Future<Map<String, dynamic>> getAuditStats() async {
    try {
      final logs = await getAuditLogs(limit: 1000);

      final Map<String, int> actionCounts = {};
      final Map<String, int> moduleCounts = {};
      final Map<String, int> userCounts = {};
      final Map<String, String> userIdToName = {};

      for (final log in logs) {
        actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
        moduleCounts[log.module] = (moduleCounts[log.module] ?? 0) + 1;
        userCounts[log.userName] = (userCounts[log.userName] ?? 0) + 1;

        // Guardar mapeo userId -> userName
        if (log.userId.isNotEmpty && log.userName.isNotEmpty) {
          userIdToName[log.userId] = log.userName;
        }
      }

      return {
        'totalLogs': logs.length,
        'actionCounts': actionCounts,
        'moduleCounts': moduleCounts,
        'userCounts': userCounts,
        'userIdToName': userIdToName,
        'lastActivity': logs.isNotEmpty ? logs.first.createdAt : null,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Obtener IP address (simplificado para web)
  Future<String> _getIpAddress() async {
    try {
      if (kIsWeb) {
        return 'Web Client';
      } else {
        return 'Mobile Client';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Obtener User Agent
  Future<String> _getUserAgent() async {
    try {
      if (kIsWeb) {
        return 'Flutter Web App';
      } else if (Platform.isAndroid) {
        return 'Flutter Android App';
      } else if (Platform.isIOS) {
        return 'Flutter iOS App';
      } else {
        return 'Flutter Desktop App';
      }
    } catch (e) {
      return 'Flutter App';
    }
  }

  /// Obtener todos los usuarios registrados del sistema - Usa PostgreSQL API
  Future<Map<String, String>> getAllSystemUsers() async {
    final Map<String, String> users = {};

    try {
      // Obtener usuarios desde PostgreSQL API
      final response = await _apiService.get('users', queryParams: {'limit': '1000'});

      if (response.success && response.data != null) {
        final usersData = response.data['users'] as List<dynamic>? ?? [];

        for (var item in usersData) {
          try {
            if (item is Map) {
              final userData = Map<String, dynamic>.from(item);
              final id = userData['id']?.toString() ?? '';
              final name = userData['name']?.toString() ??
                          userData['userTitle']?.toString() ??
                          userData['email']?.toString() ?? 'Usuario';
              final role = userData['role']?.toString() ?? '';

              if (id.isNotEmpty) {
                final displayName = role.toLowerCase() == 'admin'
                    ? name
                    : '$name${role.isNotEmpty ? " ($role)" : ""}';
                users[id] = displayName;
              }
            }
          } catch (e) {
            debugPrint('Error procesando usuario: $e');
          }
        }
      }

      debugPrint('Total usuarios del sistema encontrados: ${users.length}');
    } catch (e) {
      debugPrint('Error obteniendo usuarios del sistema: $e');
    }

    return users;
  }
}
