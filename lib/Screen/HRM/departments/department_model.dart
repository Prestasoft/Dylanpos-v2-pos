/// Modelo simple de departamento.
/// Un departamento agrupa varios cargos (designaciones).
class DepartmentModel {
  final int id;
  final String name;
  int displayOrder;

  DepartmentModel({required this.id, required this.name, this.displayOrder = 0});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '') as String,
      displayOrder: json['display_order'] is int ? json['display_order'] : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'display_order': displayOrder};
}