import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/Repository/send_whatsapp_message_repo.dart';
import 'package:salespro_admin/Repository/sms_template_repo.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/model/due_transaction_model.dart';
import 'package:salespro_admin/model/purchase_transation_model.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';

String convertShortCodes(Map<String, String> shortCodes, String text) {
  shortCodes.forEach((key, value) {
    text = text.replaceAll(key, value);
  });
  return text;
}

Future<void> sendSalesSms(SaleTransactionModel saleTransactionModel) async {
  EasyLoading.show(status: 'Sending SMS...');
  Map<String, String> shortCodes = {
    '{{CUSTOMER_NAME}}': saleTransactionModel.customerName,
    '{{CUSTOMER_ADDRESS}}': saleTransactionModel.customerAddress,
    '{{CUSTOMER_GST}}': saleTransactionModel.customerGst,
    '{{INVOICE_NUMBER}}': saleTransactionModel.invoiceNumber,
    //Dateformat like Thursday, 10 July 2021 12:30 PM
    '{{PURCHASE_DATE}}': DateFormat('EEEE, dd MMMM yyyy hh:mm a').format(DateTime.parse(saleTransactionModel.purchaseDate)),
    '{{TOTAL_AMOUNT}}': saleTransactionModel.totalAmount?.toStringAsFixed(2) ?? '',
    '{{DUE_AMOUNT}}': saleTransactionModel.dueAmount?.toStringAsFixed(2) ?? '',
    '{{SERVICE_CHARGE}}': saleTransactionModel.serviceCharge?.toStringAsFixed(2) ?? '',
    '{{VAT}}': saleTransactionModel.vat?.toStringAsFixed(2) ?? '',
    '{{DISCOUNT_AMOUNT}}': saleTransactionModel.discountAmount?.toStringAsFixed(2) ?? '',
    '{{TOTAL_QUANTITY}}': saleTransactionModel.totalQuantity?.toString() ?? '',
    '{{PAYMENT_TYPE}}': saleTransactionModel.paymentType ?? '',
    '{{INVOICE_URL}}': '$currentDomain/invoices/$constUserId/sale/${saleTransactionModel.invoiceNumber}',
  };
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = convertShortCodes(shortCodes, getSmsTemplate.saleTemplate ?? "Thank you for purchase from $appsName");

  if (isTwillio) {
    var response = await WhatsappInfoRepo().sendWhatsappMessage(saleTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else if (isUltraMsg) {
    var response = await WhatsappInfoRepo().sendUltraMsg(saleTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else {
    EasyLoading.showError('Failed to send SMS');
  }
}

Future<void> sendSalesReturnSms(SaleTransactionModel saleTransactionModel) async {
  EasyLoading.show(status: 'Sending SMS...');
  Map<String, String> shortCodes = {
    '{{CUSTOMER_NAME}}': saleTransactionModel.customerName,
    '{{CUSTOMER_ADDRESS}}': saleTransactionModel.customerAddress,
    '{{CUSTOMER_GST}}': saleTransactionModel.customerGst,
    '{{INVOICE_NUMBER}}': saleTransactionModel.invoiceNumber,
    '{{PURCHASE_DATE}}': DateFormat('EEEE, dd MMMM yyyy hh:mm a').format(DateTime.parse(saleTransactionModel.purchaseDate)),
    '{{TOTAL_AMOUNT}}': saleTransactionModel.totalAmount?.toStringAsFixed(2) ?? '',
    '{{DUE_AMOUNT}}': saleTransactionModel.dueAmount?.toStringAsFixed(2) ?? '',
    '{{SERVICE_CHARGE}}': saleTransactionModel.serviceCharge?.toStringAsFixed(2) ?? '',
    '{{VAT}}': saleTransactionModel.vat?.toStringAsFixed(2) ?? '',
    '{{DISCOUNT_AMOUNT}}': saleTransactionModel.discountAmount?.toStringAsFixed(2) ?? '',
    '{{TOTAL_QUANTITY}}': saleTransactionModel.totalQuantity?.toString() ?? '',
    '{{PAYMENT_TYPE}}': saleTransactionModel.paymentType ?? '',
    '{{INVOICE_URL}}': '$currentDomain/invoices/$constUserId/salereturn/${saleTransactionModel.invoiceNumber}',
  };
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = convertShortCodes(shortCodes, getSmsTemplate.saleReturnTemplate ?? "Thank you for purchase from $appsName");

  if (isTwillio) {
    var response = await WhatsappInfoRepo().sendWhatsappMessage(saleTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else if (isUltraMsg) {
    var response = await WhatsappInfoRepo().sendUltraMsg(saleTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else {
    EasyLoading.showError('Failed to send SMS');
  }
}

Future<void> sendQuotationSms(SaleTransactionModel saleTransactionModel) async {
  EasyLoading.show(status: 'Sending SMS...');
  Map<String, String> shortCodes = {
    '{{CUSTOMER_NAME}}': saleTransactionModel.customerName,
    '{{CUSTOMER_ADDRESS}}': saleTransactionModel.customerAddress,
    '{{CUSTOMER_GST}}': saleTransactionModel.customerGst,
    '{{INVOICE_NUMBER}}': saleTransactionModel.invoiceNumber,
    '{{PURCHASE_DATE}}': DateFormat('EEEE, dd MMMM yyyy hh:mm a').format(DateTime.parse(saleTransactionModel.purchaseDate)),
    '{{TOTAL_AMOUNT}}': saleTransactionModel.totalAmount?.toStringAsFixed(2) ?? '',
    '{{DUE_AMOUNT}}': saleTransactionModel.dueAmount?.toStringAsFixed(2) ?? '',
    '{{SERVICE_CHARGE}}': saleTransactionModel.serviceCharge?.toStringAsFixed(2) ?? '',
    '{{VAT}}': saleTransactionModel.vat?.toStringAsFixed(2) ?? '',
    '{{DISCOUNT_AMOUNT}}': saleTransactionModel.discountAmount?.toStringAsFixed(2) ?? '',
    '{{TOTAL_QUANTITY}}': saleTransactionModel.totalQuantity?.toString() ?? '',
    '{{PAYMENT_TYPE}}': saleTransactionModel.paymentType ?? '',
    '{{INVOICE_URL}}': '$currentDomain/invoices/$constUserId/salequote/${saleTransactionModel.invoiceNumber}',
  };
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = convertShortCodes(shortCodes, getSmsTemplate.quotationTemplate ?? "Thank you for purchase from $appsName");

  if (isTwillio) {
    var response = await WhatsappInfoRepo().sendWhatsappMessage(saleTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else if (isUltraMsg) {
    var response = await WhatsappInfoRepo().sendUltraMsg(saleTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else {
    EasyLoading.showError('Failed to send SMS');
  }
}

Future<void> sendPurchaseSms(PurchaseTransactionModel purchaseTransactionModel) async {
  EasyLoading.show(status: 'Sending SMS...');
  Map<String, String> shortCodes = {
    '{{CUSTOMER_NAME}}': purchaseTransactionModel.customerName,
    '{{CUSTOMER_ADDRESS}}': purchaseTransactionModel.customerAddress,
    '{{INVOICE_NUMBER}}': purchaseTransactionModel.invoiceNumber,
    '{{PURCHASE_DATE}}': DateFormat('EEEE, dd MMMM yyyy hh:mm a').format(DateTime.parse(purchaseTransactionModel.purchaseDate)),
    '{{TOTAL_AMOUNT}}': purchaseTransactionModel.totalAmount?.toStringAsFixed(2) ?? '',
    '{{DUE_AMOUNT}}': purchaseTransactionModel.dueAmount?.toStringAsFixed(2) ?? '',
    '{{DISCOUNT_AMOUNT}}': purchaseTransactionModel.discountAmount?.toStringAsFixed(2) ?? '',
    '{{PAYMENT_TYPE}}': purchaseTransactionModel.paymentType ?? '',
    '{{INVOICE_URL}}': '$currentDomain/invoices/$constUserId/purchase/${purchaseTransactionModel.invoiceNumber}',
  };
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = convertShortCodes(shortCodes, getSmsTemplate.purchaseTemplate ?? "Thank you for purchase from $appsName");

  if (isTwillio) {
    var response = await WhatsappInfoRepo().sendWhatsappMessage(purchaseTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else if (isUltraMsg) {
    var response = await WhatsappInfoRepo().sendUltraMsg(purchaseTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else {
    EasyLoading.showError('Failed to send SMS');
  }
}

Future<void> sendPurchaseReturnSms(PurchaseTransactionModel purchaseTransactionModel) async {
  EasyLoading.show(status: 'Sending SMS...');
  Map<String, String> shortCodes = {
    '{{CUSTOMER_NAME}}': purchaseTransactionModel.customerName,
    '{{CUSTOMER_ADDRESS}}': purchaseTransactionModel.customerAddress,
    '{{INVOICE_NUMBER}}': purchaseTransactionModel.invoiceNumber,
    '{{PURCHASE_DATE}}': DateFormat('EEEE, dd MMMM yyyy hh:mm a').format(DateTime.parse(purchaseTransactionModel.purchaseDate)),
    '{{TOTAL_AMOUNT}}': purchaseTransactionModel.totalAmount?.toStringAsFixed(2) ?? '',
    '{{DUE_AMOUNT}}': purchaseTransactionModel.dueAmount?.toStringAsFixed(2) ?? '',
    '{{DISCOUNT_AMOUNT}}': purchaseTransactionModel.discountAmount?.toStringAsFixed(2) ?? '',
    '{{PAYMENT_TYPE}}': purchaseTransactionModel.paymentType ?? '',
    '{{INVOICE_URL}}': '$currentDomain/invoices/$constUserId/purchasereturn/${purchaseTransactionModel.invoiceNumber}',
  };
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = convertShortCodes(shortCodes, getSmsTemplate.purchaseReturnTemplate ?? "Thank you for purchase from $appsName");

  if (isTwillio) {
    var response = await WhatsappInfoRepo().sendWhatsappMessage(purchaseTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else if (isUltraMsg) {
    var response = await WhatsappInfoRepo().sendUltraMsg(purchaseTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else {
    EasyLoading.showError('Failed to send SMS');
  }
}

Future<void> sendDueCollectionSms(DueTransactionModel dueTransactionModel) async {
  EasyLoading.show(status: 'Sending SMS...');
  Map<String, String> shortCodes = {
    '{{CUSTOMER_NAME}}': dueTransactionModel.customerName,
    '{{CUSTOMER_ADDRESS}}': dueTransactionModel.customerAddress,
    '{{CUSTOMER_GST}}': dueTransactionModel.customerGst,
    '{{INVOICE_NUMBER}}': dueTransactionModel.invoiceNumber,
    '{{PURCHASE_DATE}}': DateFormat('EEEE, dd MMMM yyyy hh:mm a').format(DateTime.parse(dueTransactionModel.purchaseDate)),
    '{{TOTAL_DUE}}': dueTransactionModel.totalDue?.toStringAsFixed(2) ?? '',
    '{{DUE_AMOUNT_AFTER_PAY}}': dueTransactionModel.dueAmountAfterPay?.toStringAsFixed(2) ?? '',
    '{{PAY_DUE_AMOUNT}}': dueTransactionModel.payDueAmount?.toStringAsFixed(2) ?? '',
    '{{PAYMENT_TYPE}}': dueTransactionModel.paymentType ?? '',
    '{{INVOICE_URL}}': '$currentDomain/invoices/$constUserId/due/${dueTransactionModel.invoiceNumber}',
  };
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = convertShortCodes(shortCodes, getSmsTemplate.dueTemplate ?? "Thank you for purchase from $appsName");

  if (isTwillio) {
    var response = await WhatsappInfoRepo().sendWhatsappMessage(dueTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else if (isUltraMsg) {
    var response = await WhatsappInfoRepo().sendUltraMsg(dueTransactionModel.customerPhone, message, getWhatsappMarketingApiData);
    if (response) {
      EasyLoading.showSuccess('SMS Sent');
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  } else {
    EasyLoading.showError('Failed to send SMS');
  }
}

Future<void> sendBulkSms(List<String> phone) async {
  EasyLoading.show(status: 'Sending SMS...');
  var getWhatsappMarketingApiData = await WhatsappInfoRepo().getWhatsappMarketingInfo();
  var getSmsTemplate = await SmsTemplateRepo().getAllTemplate();
  String message = getSmsTemplate.bulkSmsTemplate ?? "Thank you for purchase from $appsName";
  for (var number in phone) {
    if (isTwillio) {
      var response = await WhatsappInfoRepo().sendWhatsappMessage(number, message, getWhatsappMarketingApiData);
      if (response) {
        EasyLoading.showSuccess('SMS Sent');
      } else {
        EasyLoading.showError('Failed to send SMS');
      }
    } else if (isUltraMsg) {
      var response = await WhatsappInfoRepo().sendUltraMsg(number, message, getWhatsappMarketingApiData);
      if (response) {
        EasyLoading.showSuccess('SMS Sent');
      } else {
        EasyLoading.showError('Failed to send SMS');
      }
    } else {
      EasyLoading.showError('Failed to send SMS');
    }
  }
}
