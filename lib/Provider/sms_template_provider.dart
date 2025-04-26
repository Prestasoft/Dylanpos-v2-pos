import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Repository/sms_template_repo.dart';
import 'package:salespro_admin/model/whatsapp_marketing_sms_template_model.dart';

SmsTemplateRepo smsTemplateRepo = SmsTemplateRepo();
final smsTemplateProvider = FutureProvider.autoDispose<WhatsappMarketingSmsTemplateModel>((ref) => smsTemplateRepo.getAllTemplate());
