/// Modelo unificado para la configuración de sucursal
/// Combina datos del negocio, facturación y sucursal
class BranchSettingsModel {
  // Identificación de la sucursal
  final String? id;
  final String branchId;

  // Información del negocio (compartida entre sucursales)
  final String companyName;
  final String rnc;
  final String? logoUrl;

  // Información específica de la sucursal
  final String branchName;
  final String city;
  final String address;
  final String phone;
  final String? whatsapp;

  // Información de contacto
  final String? email;
  final String? website;
  final String? instagram;
  final String? facebook;

  // Configuración de factura
  final bool showLogoInInvoice;
  final bool logoOnRight;
  final String? invoiceFooterText;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BranchSettingsModel({
    this.id,
    required this.branchId,
    required this.companyName,
    this.rnc = '',
    this.logoUrl,
    required this.branchName,
    required this.city,
    this.address = '',
    this.phone = '',
    this.whatsapp,
    this.email,
    this.website,
    this.instagram,
    this.facebook,
    this.showLogoInInvoice = true,
    this.logoOnRight = false,
    this.invoiceFooterText,
    this.createdAt,
    this.updatedAt,
  });

  /// Constructor desde JSON (para API response)
  factory BranchSettingsModel.fromJson(Map<String, dynamic> json) {
    return BranchSettingsModel(
      id: json['id']?.toString(),
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? json['companyName']?.toString() ?? '',
      rnc: json['rnc']?.toString() ?? json['gst']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? json['logoUrl']?.toString() ?? json['pictureUrl']?.toString(),
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString(),
      email: json['email']?.toString() ?? json['emailAddress']?.toString(),
      website: json['website']?.toString(),
      instagram: json['instagram']?.toString(),
      facebook: json['facebook']?.toString(),
      showLogoInInvoice: json['show_logo_in_invoice'] ?? json['showLogoInInvoice'] ?? json['showInvoice'] ?? true,
      logoOnRight: json['logo_on_right'] ?? json['logoOnRight'] ?? json['isRight'] ?? false,
      invoiceFooterText: json['invoice_footer_text']?.toString() ?? json['invoiceFooterText']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  /// Convertir a JSON (para API request)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'branch_id': branchId,
      'company_name': companyName,
      'rnc': rnc,
      'logo_url': logoUrl,
      'branch_name': branchName,
      'city': city,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'show_logo_in_invoice': showLogoInInvoice,
      'logo_on_right': logoOnRight,
      'invoice_footer_text': invoiceFooterText,
    };
  }

  /// Crear una copia con campos modificados
  BranchSettingsModel copyWith({
    String? id,
    String? branchId,
    String? companyName,
    String? rnc,
    String? logoUrl,
    String? branchName,
    String? city,
    String? address,
    String? phone,
    String? whatsapp,
    String? email,
    String? website,
    String? instagram,
    String? facebook,
    bool? showLogoInInvoice,
    bool? logoOnRight,
    String? invoiceFooterText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchSettingsModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      companyName: companyName ?? this.companyName,
      rnc: rnc ?? this.rnc,
      logoUrl: logoUrl ?? this.logoUrl,
      branchName: branchName ?? this.branchName,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      showLogoInInvoice: showLogoInInvoice ?? this.showLogoInInvoice,
      logoOnRight: logoOnRight ?? this.logoOnRight,
      invoiceFooterText: invoiceFooterText ?? this.invoiceFooterText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Modelo por defecto para nuevas sucursales
  factory BranchSettingsModel.defaultSettings(String branchId) {
    return BranchSettingsModel(
      branchId: branchId,
      companyName: 'Victor Guzman Fotografía',
      rnc: '',
      branchName: '',
      city: '',
      address: '',
      phone: '',
    );
  }

  /// Obtener el teléfono formateado para mostrar
  String get displayPhone {
    if (phone.isEmpty) return 'Sin teléfono';
    return phone;
  }

  /// Obtener la dirección formateada
  String get displayAddress {
    if (address.isEmpty && city.isEmpty) return 'Sin dirección';
    if (address.isEmpty) return city;
    if (city.isEmpty) return address;
    return '$address, $city';
  }

  /// Verificar si tiene datos completos para facturación
  bool get hasCompleteInvoiceData {
    return companyName.isNotEmpty &&
           rnc.isNotEmpty &&
           address.isNotEmpty &&
           phone.isNotEmpty;
  }

  @override
  String toString() {
    return 'BranchSettingsModel(branchId: $branchId, companyName: $companyName, branchName: $branchName, city: $city)';
  }
}
