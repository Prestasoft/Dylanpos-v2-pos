/// Modelo para tipos de NCF (Número de Comprobante Fiscal)
class NcfTypeModel {
  final String? id;
  final String code;
  final String name;
  final String? description;
  final bool requiresRnc;
  final bool appliesItbis;
  final double itbisRate;
  final bool isActive;
  final int sortOrder;

  NcfTypeModel({
    this.id,
    required this.code,
    required this.name,
    this.description,
    this.requiresRnc = false,
    this.appliesItbis = true,
    this.itbisRate = 18.0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory NcfTypeModel.fromJson(Map<String, dynamic> json) {
    return NcfTypeModel(
      id: json['id']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      requiresRnc: json['requires_rnc'] == true || json['requiresRnc'] == true,
      appliesItbis: json['applies_itbis'] != false && json['appliesItbis'] != false,
      itbisRate: double.tryParse(json['itbis_rate']?.toString() ?? json['itbisRate']?.toString() ?? '18') ?? 18.0,
      isActive: json['is_active'] != false && json['isActive'] != false,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? json['sortOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'requiresRnc': requiresRnc,
    'appliesItbis': appliesItbis,
    'itbisRate': itbisRate,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };

  /// Obtiene el color asociado al tipo de NCF
  String get colorHex {
    switch (code) {
      case 'SIN':
        return '#9E9E9E'; // Gris
      case 'B01':
        return '#2196F3'; // Azul
      case 'B02':
        return '#4CAF50'; // Verde
      case 'B04':
        return '#FF9800'; // Naranja
      case 'B14':
        return '#9C27B0'; // Púrpura
      case 'B15':
        return '#00BCD4'; // Cyan
      default:
        return '#607D8B'; // Gris azulado
    }
  }

  /// Obtiene el ícono asociado al tipo
  String get iconName {
    switch (code) {
      case 'SIN':
        return 'receipt_long';
      case 'B01':
        return 'business';
      case 'B02':
        return 'person';
      case 'B04':
        return 'assignment_return';
      case 'B14':
        return 'verified';
      case 'B15':
        return 'account_balance';
      default:
        return 'description';
    }
  }
}

/// Modelo para secuencias de NCF
class NcfSequenceModel {
  final String? id;
  final String branchId;
  final String ncfTypeCode;
  final String serie;
  final int currentSequence;
  final int maxSequence;
  final String? prefix;
  final bool isActive;
  final String? authorizationDate;
  final String? expirationDate;
  final String? typeName;
  final String? typeDescription;

  NcfSequenceModel({
    this.id,
    required this.branchId,
    required this.ncfTypeCode,
    this.serie = 'A',
    this.currentSequence = 0,
    this.maxSequence = 99999999,
    this.prefix,
    this.isActive = true,
    this.authorizationDate,
    this.expirationDate,
    this.typeName,
    this.typeDescription,
  });

  factory NcfSequenceModel.fromJson(Map<String, dynamic> json) {
    return NcfSequenceModel(
      id: json['id']?.toString(),
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      ncfTypeCode: json['ncf_type_code']?.toString() ?? json['ncfTypeCode']?.toString() ?? '',
      serie: json['serie']?.toString() ?? 'A',
      currentSequence: int.tryParse(json['current_sequence']?.toString() ?? json['currentSequence']?.toString() ?? '0') ?? 0,
      maxSequence: int.tryParse(json['max_sequence']?.toString() ?? json['maxSequence']?.toString() ?? '99999999') ?? 99999999,
      prefix: json['prefix']?.toString(),
      isActive: json['is_active'] != false && json['isActive'] != false,
      authorizationDate: json['authorization_date']?.toString() ?? json['authorizationDate']?.toString(),
      expirationDate: json['expiration_date']?.toString() ?? json['expirationDate']?.toString(),
      typeName: json['type_name']?.toString() ?? json['typeName']?.toString(),
      typeDescription: json['type_description']?.toString() ?? json['typeDescription']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': branchId,
    'ncfTypeCode': ncfTypeCode,
    'serie': serie,
    'currentSequence': currentSequence,
    'maxSequence': maxSequence,
    'prefix': prefix,
    'isActive': isActive,
    'authorizationDate': authorizationDate,
    'expirationDate': expirationDate,
  };

  /// Calcula cuántos NCF quedan disponibles
  int get remainingNcf => maxSequence - currentSequence;

  /// Porcentaje de uso de la secuencia
  double get usagePercentage => maxSequence > 0 ? (currentSequence / maxSequence) * 100 : 0;

  /// Verifica si la secuencia está próxima a expirar (menos de 30 días)
  bool get isNearExpiration {
    if (expirationDate == null) return false;
    final expDate = DateTime.tryParse(expirationDate!);
    if (expDate == null) return false;
    return expDate.difference(DateTime.now()).inDays < 30;
  }

  /// Verifica si la secuencia ha expirado
  bool get isExpired {
    if (expirationDate == null) return false;
    final expDate = DateTime.tryParse(expirationDate!);
    if (expDate == null) return false;
    return expDate.isBefore(DateTime.now());
  }

  /// Verifica si la secuencia está próxima a agotarse (menos del 10%)
  bool get isNearDepletion => usagePercentage > 90;
}

/// Modelo para resumen de ventas por NCF
class NcfSalesSummaryModel {
  final String ncfType;
  final String? ncfTypeName;
  final int totalInvoices;
  final double totalSales;
  final double totalItbis;

  NcfSalesSummaryModel({
    required this.ncfType,
    this.ncfTypeName,
    required this.totalInvoices,
    required this.totalSales,
    required this.totalItbis,
  });

  factory NcfSalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return NcfSalesSummaryModel(
      ncfType: json['ncf_type']?.toString() ?? json['ncfType']?.toString() ?? 'SIN',
      ncfTypeName: json['ncf_type_name']?.toString() ?? json['ncfTypeName']?.toString(),
      totalInvoices: int.tryParse(json['total_invoices']?.toString() ?? json['totalInvoices']?.toString() ?? '0') ?? 0,
      totalSales: double.tryParse(json['total_sales']?.toString() ?? json['totalSales']?.toString() ?? '0') ?? 0.0,
      totalItbis: double.tryParse(json['total_itbis']?.toString() ?? json['totalItbis']?.toString() ?? '0') ?? 0.0,
    );
  }
}

/// Modelo para registro 607 (ventas)
class Report607RecordModel {
  final String? rncCedula;
  final String tipoIdentificacion;
  final String numeroComprobanteFiscal;
  final String tipoIngreso;
  final String fechaComprobante;
  final double montoFacturado;
  final double itbisFacturado;
  final double efectivo;

  Report607RecordModel({
    this.rncCedula,
    this.tipoIdentificacion = '3',
    required this.numeroComprobanteFiscal,
    this.tipoIngreso = '01',
    required this.fechaComprobante,
    required this.montoFacturado,
    required this.itbisFacturado,
    required this.efectivo,
  });

  factory Report607RecordModel.fromJson(Map<String, dynamic> json) {
    return Report607RecordModel(
      rncCedula: json['RNC_Cedula']?.toString(),
      tipoIdentificacion: json['Tipo_Identificacion']?.toString() ?? '3',
      numeroComprobanteFiscal: json['Numero_Comprobante_Fiscal']?.toString() ?? '',
      tipoIngreso: json['Tipo_Ingreso']?.toString() ?? '01',
      fechaComprobante: json['Fecha_Comprobante']?.toString() ?? '',
      montoFacturado: double.tryParse(json['Monto_Facturado']?.toString() ?? '0') ?? 0.0,
      itbisFacturado: double.tryParse(json['ITBIS_Facturado']?.toString() ?? '0') ?? 0.0,
      efectivo: double.tryParse(json['Efectivo']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Convierte a línea de texto para archivo 607
  String toTxtLine() {
    return [
      rncCedula ?? '',
      tipoIdentificacion,
      numeroComprobanteFiscal,
      '', // NCF Modificado
      tipoIngreso,
      fechaComprobante,
      '', // Fecha retención
      montoFacturado.toStringAsFixed(2),
      itbisFacturado.toStringAsFixed(2),
      '0.00', // ITBIS Retenido
      '0.00', // ITBIS Percibido
      '0.00', // Retención Renta
      '0.00', // ISR Percibido
      '0.00', // ISC
      '0.00', // Otros impuestos
      '0.00', // Propina legal
      efectivo.toStringAsFixed(2),
      '0.00', // Cheque/Transferencia
      '0.00', // Tarjeta
      '0.00', // Crédito
      '0.00', // Bonos
      '0.00', // Permuta
      '0.00', // Otras formas
    ].join('|');
  }
}
