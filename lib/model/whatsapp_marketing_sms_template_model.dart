class WhatsappMarketingSmsTemplateModel {
  String? saleTemplate;
  String? purchaseTemplate;
  String? dueTemplate;
  String? saleReturnTemplate;
  String? purchaseReturnTemplate;
  String? paymentTemplate;
  String? quotationTemplate;
  String? bulkSmsTemplate;

  WhatsappMarketingSmsTemplateModel({
    this.saleTemplate,
    this.purchaseTemplate,
    this.dueTemplate,
    this.saleReturnTemplate,
    this.purchaseReturnTemplate,
    this.paymentTemplate,
    this.quotationTemplate,
    this.bulkSmsTemplate,
  });

  WhatsappMarketingSmsTemplateModel.fromJson(Map<dynamic, dynamic> json)
      : saleTemplate = json['saleTemplate'],
        purchaseTemplate = json['purchaseTemplate'],
        dueTemplate = json['dueTemplate'],
        saleReturnTemplate = json['saleReturnTemplate'],
        purchaseReturnTemplate = json['purchaseReturnTemplate'],
        paymentTemplate = json['paymentTemplate'],
        quotationTemplate = json['quotationTemplate'],
        bulkSmsTemplate = json['bulkSmsTemplate'];

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'saleTemplate': saleTemplate,
        'purchaseTemplate': purchaseTemplate,
        'dueTemplate': dueTemplate,
        'saleReturnTemplate': saleReturnTemplate,
        'purchaseReturnTemplate': purchaseReturnTemplate,
        'paymentTemplate': paymentTemplate,
        'quotationTemplate': quotationTemplate,
        'bulkSmsTemplate': bulkSmsTemplate,
      };
}
