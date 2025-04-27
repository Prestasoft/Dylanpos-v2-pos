class GeneralSettingModel {
  String title;
  String companyName;
  String mainLogo;
  String commonHeaderLogo;
  String sidebarLogo;

  GeneralSettingModel({
    required this.title,
    required this.companyName,
    required this.mainLogo,
    required this.commonHeaderLogo,
    required this.sidebarLogo,
  });

  factory GeneralSettingModel.fromJson(Map<String, dynamic> json) {
    return GeneralSettingModel(
      title: json['title'] ?? 'DylanPOS',
      companyName: json['companyName'] ?? 'PrestaSoft',
      mainLogo: json['mainLogo'] ?? '',
      commonHeaderLogo: json['commonHeaderLogo'] ?? '',
      sidebarLogo: json['sidebarLogo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'companyName': companyName,
      'mainLogo': mainLogo,
      'commonHeaderLogo': commonHeaderLogo,
      'sidebarLogo': sidebarLogo,
    };
  }
}
