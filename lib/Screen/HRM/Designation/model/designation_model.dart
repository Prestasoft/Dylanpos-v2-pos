class DesignationModel {
  late num id;
  late String designation;
  late String designationDescription;

  DesignationModel({
    required this.id,
    required this.designation,
    required this.designationDescription,
  });

  DesignationModel.fromJson(Map<dynamic, dynamic> json) {
    // El servidor PostgreSQL devuelve:
    // - 'id' = UUID (string)
    // - 'designation_id' = ID numérico (string o num, puede ser null)
    // Usamos designation_id como identificador principal
    var designationId = json['designation_id'];
    if (designationId != null) {
      if (designationId is num) {
        id = designationId;
      } else if (designationId is String) {
        id = num.tryParse(designationId) ?? DateTime.now().millisecondsSinceEpoch;
      } else {
        id = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      // Fallback: usar timestamp actual si no hay designation_id
      id = DateTime.now().millisecondsSinceEpoch;
    }

    designation = (json['designation'] ?? '') as String;
    designationDescription = (json['designation_description'] ?? json['designationDescription'] ?? '') as String;
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'designation_id': id,
        'designation': designation,
        'designation_description': designationDescription,
      };
}
