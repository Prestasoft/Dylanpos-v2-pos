/// Modelo para verificación de transferencias bancarias
class TransferVerificationModel {
  final String? id;
  final String? branchId;
  final String? saleId;
  final String invoiceNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String bankName;
  final String holderName;
  final String? referenceNumber;
  final String? transferDate;
  final double amount;
  final String receiptUrl;
  final String? receiptFilename;
  final String status; // pending, approved, rejected
  final String? verifiedBy;
  final String? verifiedAt;
  final String? operatorNotes;
  final String? rejectionReason;
  final String? sellerId;
  final String? sellerName;
  final String? createdAt;
  final String? updatedAt;

  TransferVerificationModel({
    this.id,
    this.branchId,
    this.saleId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.bankName,
    required this.holderName,
    this.referenceNumber,
    this.transferDate,
    required this.amount,
    required this.receiptUrl,
    this.receiptFilename,
    this.status = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    this.operatorNotes,
    this.rejectionReason,
    this.sellerId,
    this.sellerName,
    this.createdAt,
    this.updatedAt,
  });

  factory TransferVerificationModel.fromJson(Map<String, dynamic> json) {
    return TransferVerificationModel(
      id: json['id']?.toString(),
      branchId: json['branchId']?.toString() ?? json['branch_id']?.toString(),
      saleId: json['saleId']?.toString() ?? json['sale_id']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? json['customer_phone']?.toString(),
      customerEmail: json['customerEmail']?.toString() ?? json['customer_email']?.toString(),
      bankName: json['bankName']?.toString() ?? json['bank_name']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? json['holder_name']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? json['reference_number']?.toString(),
      transferDate: json['transferDate']?.toString() ?? json['transfer_date']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      receiptUrl: json['receiptUrl']?.toString() ?? json['receipt_url']?.toString() ?? '',
      receiptFilename: json['receiptFilename']?.toString() ?? json['receipt_filename']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      verifiedBy: json['verifiedBy']?.toString() ?? json['verified_by']?.toString(),
      verifiedAt: json['verifiedAt']?.toString() ?? json['verified_at']?.toString(),
      operatorNotes: json['operatorNotes']?.toString() ?? json['operator_notes']?.toString(),
      rejectionReason: json['rejectionReason']?.toString() ?? json['rejection_reason']?.toString(),
      sellerId: json['sellerId']?.toString() ?? json['seller_id']?.toString(),
      sellerName: json['sellerName']?.toString() ?? json['seller_name']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }

  /// Convierte el modelo a JSON con camelCase para el backend API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'bankName': bankName,
      'holderName': holderName,
      'referenceNumber': referenceNumber,
      'transferDate': transferDate,
      'amount': amount,
      'receiptUrl': receiptUrl,
      'receiptFilename': receiptFilename,
      'status': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt,
      'operatorNotes': operatorNotes,
      'rejectionReason': rejectionReason,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  TransferVerificationModel copyWith({
    String? id,
    String? branchId,
    String? saleId,
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? bankName,
    String? holderName,
    String? referenceNumber,
    String? transferDate,
    double? amount,
    String? receiptUrl,
    String? receiptFilename,
    String? status,
    String? verifiedBy,
    String? verifiedAt,
    String? operatorNotes,
    String? rejectionReason,
    String? sellerId,
    String? sellerName,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransferVerificationModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      saleId: saleId ?? this.saleId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      bankName: bankName ?? this.bankName,
      holderName: holderName ?? this.holderName,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      transferDate: transferDate ?? this.transferDate,
      amount: amount ?? this.amount,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      receiptFilename: receiptFilename ?? this.receiptFilename,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      operatorNotes: operatorNotes ?? this.operatorNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si la transferencia está pendiente
  bool get isPending => status == 'pending';

  /// Verifica si la transferencia fue aprobada
  bool get isApproved => status == 'approved';

  /// Verifica si la transferencia fue rechazada
  bool get isRejected => status == 'rejected';

  /// Obtiene el nombre para mostrar del estado
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  }
}
