import 'dart:convert';

class AuditModel {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final String action;
  final String module;
  final String description;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final String createdAt;

  AuditModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.action,
    required this.module,
    required this.description,
    required this.ipAddress,
    required this.userAgent,
    this.beforeData,
    this.afterData,
    required this.createdAt,
  });

  factory AuditModel.fromJson(Map<String, dynamic> json) {
    return AuditModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      action: json['action'] ?? '',
      module: json['module'] ?? '',
      description: json['description'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      userAgent: json['userAgent'] ?? '',
      beforeData: json['beforeData'] != null 
          ? Map<String, dynamic>.from(json['beforeData'])
          : null,
      afterData: json['afterData'] != null 
          ? Map<String, dynamic>.from(json['afterData'])
          : null,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'action': action,
      'module': module,
      'description': description,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'beforeData': beforeData,
      'afterData': afterData,
      'createdAt': createdAt,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  AuditModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? action,
    String? module,
    String? description,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
    String? createdAt,
  }) {
    return AuditModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      action: action ?? this.action,
      module: module ?? this.module,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      beforeData: beforeData ?? this.beforeData,
      afterData: afterData ?? this.afterData,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Enums para acciones y módulos
enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
  view,
  print,
  export,
  approve,
  reject,
  cancel,
  restore,
  archive
}

enum AuditModule {
  users,
  customers,
  products,
  sales,
  purchases,
  inventory,
  reservations,
  reports,
  settings,
  authentication,
  dashboard,
  expenses,
  suppliers
}

extension AuditActionExtension on AuditAction {
  String get name {
    switch (this) {
      case AuditAction.create:
        return 'Crear';
      case AuditAction.update:
        return 'Actualizar';
      case AuditAction.delete:
        return 'Eliminar';
      case AuditAction.login:
        return 'Iniciar Sesión';
      case AuditAction.logout:
        return 'Cerrar Sesión';
      case AuditAction.view:
        return 'Ver';
      case AuditAction.print:
        return 'Imprimir';
      case AuditAction.export:
        return 'Exportar';
      case AuditAction.approve:
        return 'Aprobar';
      case AuditAction.reject:
        return 'Rechazar';
      case AuditAction.cancel:
        return 'Cancelar';
      case AuditAction.restore:
        return 'Restaurar';
      case AuditAction.archive:
        return 'Archivar';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

extension AuditModuleExtension on AuditModule {
  String get name {
    switch (this) {
      case AuditModule.users:
        return 'Usuarios';
      case AuditModule.customers:
        return 'Clientes';
      case AuditModule.products:
        return 'Productos';
      case AuditModule.sales:
        return 'Ventas';
      case AuditModule.purchases:
        return 'Compras';
      case AuditModule.inventory:
        return 'Inventario';
      case AuditModule.reservations:
        return 'Reservaciones';
      case AuditModule.reports:
        return 'Reportes';
      case AuditModule.settings:
        return 'Configuración';
      case AuditModule.authentication:
        return 'Autenticación';
      case AuditModule.dashboard:
        return 'Dashboard';
      case AuditModule.expenses:
        return 'Gastos';
      case AuditModule.suppliers:
        return 'Proveedores';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}