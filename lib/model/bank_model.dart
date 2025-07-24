class BankModel {
  String? bankId;
  String? bankName;
  String? accountNumber;
  String? accountHolder;
  String? branch;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  BankModel({
    this.bankId,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.branch,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  BankModel.fromJson(Map<String, dynamic> json) {
    bankId = json['bankId'];
    bankName = json['bankName'];
    accountNumber = json['accountNumber'];
    accountHolder = json['accountHolder'];
    branch = json['branch'];
    isActive = json['isActive'] ?? true;
    createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null;
    updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'bankId': bankId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'branch': branch,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}