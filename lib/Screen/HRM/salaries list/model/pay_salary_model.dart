class PaySalaryModel {
  final num id;
  final String employeeName;
  final num employmentId;
  final num designationId;
  final String designation;
  final num paySalary;
  final num netSalary;
  final String year;
  final String month;
  final DateTime payingDate;
  final String paymentType;
  final String? note;

  // Constructor with required and optional fields
  PaySalaryModel({
    required this.id,
    required this.employeeName,
    required this.employmentId,
    required this.designationId,
    required this.designation,
    required this.paySalary,
    required this.netSalary,
    required this.year,
    required this.month,
    required this.payingDate,
    required this.paymentType,
    this.note,
  });

  // Factory constructor to create PaySalaryModel from JSON
  factory PaySalaryModel.fromJson(Map<String, dynamic> json) {
    return PaySalaryModel(
      id: json['id'],
      employeeName: json['employeeName'],
      employmentId: json['employmentId'],
      designationId: json['designationId'],
      designation: json['designation'],
      paySalary: json['paySalary'],
      netSalary: json['netSalary'],
      year: json['year'],
      month: json['month'],
      payingDate: DateTime.parse(json['payingDate']),
      paymentType: json['paymentType'],
      note: json['note'],
    );
  }

  // Convert PaySalaryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeName': employeeName,
      'employmentId': employmentId,
      'designationId': designationId,
      'designation': designation,
      'paySalary': paySalary,
      'netSalary': netSalary,
      'year': year,
      'month': month,
      'payingDate': payingDate.toIso8601String(),
      'paymentType': paymentType,
      'note': note,
    };
  }
}
