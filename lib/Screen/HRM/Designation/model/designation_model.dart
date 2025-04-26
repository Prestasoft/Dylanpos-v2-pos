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
    id = json['id'];
    designation = json['designation'] as String;
    designationDescription = json['designationDescription'] as String;
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'id': id,
        'designation': designation,
        'designationDescription': designationDescription,
      };
}
