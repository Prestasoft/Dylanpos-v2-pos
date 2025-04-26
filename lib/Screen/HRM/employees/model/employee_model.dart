class EmployeeModel {
  final num id;
  late final String name;
  late final String phoneNumber;
  late final String email;
  late final String address;
  late final String gender;
  late final String employmentType;
  late final num designationId;
  late final String designation;
  late final DateTime birthDate;
  late final DateTime joiningDate;
  late final double salary; // Optional field

  // Constructor with required and optional fields
  EmployeeModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.gender,
    required this.employmentType,
    required this.designationId,
    required this.designation,
    required this.birthDate,
    required this.joiningDate,
    required this.salary, // Optional
  });

  // Factory constructor to create EmployeeModel from JSON
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as num,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      gender: json['gender'] as String,
      employmentType: json['employmentType'] as String,
      designation: json['designation'] as String,
      designationId: json['designationId'] as num,
      birthDate: DateTime.parse(json['birthDate'] as String),
      joiningDate: DateTime.parse(json['joiningDate'] as String),
      salary: json['salary'] as double,
    );
  }

  // Convert EmployeeModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'gender': gender,
      'employmentType': employmentType,
      'designationId': designationId,
      'designation': designation,
      'birthDate': birthDate.toIso8601String(),
      'joiningDate': joiningDate.toIso8601String(),
      'salary': salary,
    };
  }
}
