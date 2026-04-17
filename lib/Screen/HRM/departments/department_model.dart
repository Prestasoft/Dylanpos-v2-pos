/// Modelo simple de departamento.
/// Un departamento agrupa varios cargos (designaciones).
class DepartmentModel {
  final int id;
  final String name;

  const DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}