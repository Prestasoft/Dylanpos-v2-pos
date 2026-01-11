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
    // Soporta tanto snake_case (API) como camelCase (Firebase legacy)
    bankId = json['id']?.toString() ?? json['bankId'];
    bankName = json['bank_name'] ?? json['bankName'];
    accountNumber = json['account_number'] ?? json['accountNumber'];
    accountHolder = json['account_name'] ?? json['accountHolder'] ?? json['holderName'];
    branch = json['branch_id'] ?? json['branch'];
    isActive = json['is_active'] ?? json['isActive'] ?? true;
    createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null);
    updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null);
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