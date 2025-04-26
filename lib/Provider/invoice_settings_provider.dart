import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Repository/invoice_settings_repo.dart';
import 'package:salespro_admin/model/invoice_model.dart';

InvoiceSettingsRepo invoiceSettingsRepo = InvoiceSettingsRepo();
final invoiceSettingsProvider = FutureProvider.autoDispose<InvoiceModel>((ref) => invoiceSettingsRepo.getDetails());
