
class BrandsModel {
  String? accountName;
  String? accountNumber;
  String? bankAccountCurrency;
  String? bankName;
  String? branchName;
  bool? isActive;
  String? swiftCode;
  String? brandName;

  BrandsModel({
    this.accountName,
    this.accountNumber,
    this.bankAccountCurrency,
    this.bankName,
    this.branchName,
    this.isActive,
    this.swiftCode,
    this.brandName,
  });

  factory BrandsModel.fromJson(Map<dynamic, dynamic> json) {
    return BrandsModel(
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      bankAccountCurrency: json['bankAccountCurrency'] ?? '',
      bankName: json['bankName'] ?? '',
      branchName: json['branchName'] ?? '',
      isActive: json['isActive'] ?? false,  // Asumimos que 'isActive' es un bool
      swiftCode: json['swiftCode'] ?? '',
      brandName: json['branchName'] ?? '',
    );
  }



  Map<String, dynamic> toJson() => {
    'accountName': accountName,
    'accountNumber': accountNumber,
    'bankAccountCurrency': bankAccountCurrency,
    'bankName': bankName,
    'branchName': branchName,
    'isActive': isActive,
    'swiftCode': swiftCode,
    'brandName': brandName,
  };
}
