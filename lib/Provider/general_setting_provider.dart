import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Repository/general_setting_repo.dart';
import '../model/general_setting_model.dart';

GeneralSettingRepo generalSettingRepo = GeneralSettingRepo();
final generalSettingProvider = FutureProvider<GeneralSettingModel>((ref) => generalSettingRepo.getGeneralSetting());
