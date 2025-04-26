class BankInfoModel {
  late String bankName, branchName, accountName, accountNumber, swiftCode, bankAccountCurrency;
  late bool isActive;

  BankInfoModel({
    required this.bankName,
    required this.branchName,
    required this.accountName,
    required this.accountNumber,
    required this.swiftCode,
    required this.bankAccountCurrency,
    required this.isActive,
  });

  BankInfoModel.fromJson(Map<dynamic, dynamic> json)
      : bankName = json['bankName'] ?? '',
        branchName = json['branchName'] ?? '',
        accountName = json['accountName'] ?? '',
        accountNumber = json['accountNumber'] ?? '',
        swiftCode = json['swiftCode'] ?? '',
        bankAccountCurrency = json['bankAccountCurrency'] ?? '',
        isActive = json['isActive'] ?? false;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'bankName': bankName,
        'branchName': branchName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'swiftCode': swiftCode,
        'bankAccountCurrency': bankAccountCurrency,
        'isActive': isActive,
      };
}
