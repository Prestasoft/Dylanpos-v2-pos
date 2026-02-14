/// Modelo para guardar el orden personalizado del menú del sidebar
/// Se persiste en PostgreSQL y SharedPreferences
class MenuOrderModel {
  final String branchId;
  final List<String> menuOrder; // Lista de `type` en el orden deseado
  final DateTime updatedAt;
  final String? updatedBy;

  MenuOrderModel({
    required this.branchId,
    required this.menuOrder,
    required this.updatedAt,
    this.updatedBy,
  });

  factory MenuOrderModel.fromJson(Map<String, dynamic> json) {
    return MenuOrderModel(
      branchId: json['branch_id'] ?? json['branchId'] ?? '',
      menuOrder: json['menu_order'] != null
          ? List<String>.from(json['menu_order'])
          : json['menuOrder'] != null
              ? List<String>.from(json['menuOrder'])
              : [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      updatedBy: json['updated_by'] ?? json['updatedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'menu_order': menuOrder,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  /// Crea una copia con los valores modificados
  MenuOrderModel copyWith({
    String? branchId,
    List<String>? menuOrder,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return MenuOrderModel(
      branchId: branchId ?? this.branchId,
      menuOrder: menuOrder ?? this.menuOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Modelo vacío por defecto
  factory MenuOrderModel.empty(String branchId) {
    return MenuOrderModel(
      branchId: branchId,
      menuOrder: [],
      updatedAt: DateTime.now(),
    );
  }
}
