#!/usr/bin/env dart

import 'dart:io';

/// Script para remover automáticamente imports no usados
/// Basado en los warnings reportados por flutter analyze
void main() async {
  print('🧹 Iniciando limpieza de imports no usados...');
  
  // Lista de imports no usados identificados por flutter analyze
  final Map<String, List<String>> unusedImports = {
    'lib/Provider/dress_with_reservations.dart': ['../model/args_dress.dart'],
    'lib/Provider/notification_provider.dart': ['dart:convert'],
    'lib/Provider/reservation_provider 2.dart': [
      'dart:async',
      'package:salespro_admin/Provider/servicePackagesProvider.dart',
      'package:salespro_admin/model/ReservationProductModel.dart',
      'package:salespro_admin/model/ServicePackageModel.dart',
      'package:salespro_admin/model/dress_model.dart',
      'dress_provider.dart',
      'package:rxdart/rxdart.dart'
    ],
    'lib/Provider/reservation_provider.dart': [
      'package:http/http.dart',
      'package:salespro_admin/Screen/Reservation/package_reservation_components_screen.dart',
      '../model/dress_model.dart'
    ],
    'lib/Repository/login_repo.dart': [
      'package:salespro_admin/Screen/Home/home_screen.dart',
      '../Screen/blank_home.dart'
    ],
    'lib/Route/global_side_bar.dart': ['package:salespro_admin/global_language.dart'],
    'lib/Screen/Calendar/CalendarDressScreen.dart': ['../../model/args_dress.dart'],
    'lib/Screen/Authentication/log_in.dart': ['package:flutter_svg/flutter_svg.dart'],
    'lib/Screen/Confirmation/sale_confirmations_list.dart': [
      'package:nb_utils/nb_utils.dart',
      '../../model/sale_transaction_model.dart',
      '../Widgets/noDataFound.dart'
    ],
    'lib/Screen/Equipments/areas_equipments_screen.dart': [
      'package:nb_utils/nb_utils.dart',
      'package:responsive_grid/responsive_grid.dart'
    ],
    'lib/Screen/Due List/due_popUp.dart': ['package:mime/mime.dart'],
    'lib/Screen/Inventory Sales/inventory_sales.dart': ['package:mime/mime.dart'],
    'lib/Screen/Sale List/inventory_sales.dart': ['package:mime/mime.dart'],
    'lib/Screen/Sale List/sale_list.dart': [
      'dart:developer',
      'package:mime/mime.dart',
      'package:material_design_icons_flutter/material_design_icons_flutter.dart',
      'package:salespro_admin/Screen/currency/currency_provider.dart',
      'package:salespro_admin/model/customer_model.dart',
      'package:salespro_admin/model/personal_information_model.dart',
      'package:salespro_admin/model/purchase_transation_model.dart'
    ],
    'lib/Screen/Reports/report_screen.dart': ['../../model/daily_transaction_model.dart'],
    'lib/Screen/Reservation/date_time_selection_screen.dart': ['dart:developer'],
    'lib/Screen/Reservation/dress_selection_screen_package.dart': ['date_time_selection_screen.dart'],
    'lib/Screen/Reservation/package_list_screen.dart': ['dart:math'],
    'lib/Screen/PackageService/ServicePackageScreen.dart': ['package:flutter/cupertino.dart'],
    'lib/Screen/PackageService/ViewPackagesScreen.dart': ['package:flutter/cupertino.dart'],
    'lib/share/PriceSummarySection.dart': ['package:flutter/cupertino.dart'],
    'lib/share/ProductSearchWidget.dart': ['package:flutter/cupertino.dart'],
    'lib/const.dart': ['package:flutter_easyloading/flutter_easyloading.dart'],
    'lib/subscription.dart': [
      'package:flutter_easyloading/flutter_easyloading.dart',
      'Repository/subscriptionPlanRepo.dart'
    ],
    'lib/main.dart': [
      'package:salespro_admin/Screen/Payment%20Handler/payment_success.dart',
      'package:http/http.dart'
    ],
    'prueba_final_sistema.dart': ['dart:convert'],
    'lib/delete_invoice_functions.dart': ['dart:developer']
  };
  
  int totalImportsRemoved = 0;
  int filesModified = 0;
  
  for (final entry in unusedImports.entries) {
    final filePath = entry.key;
    final importsToRemove = entry.value;
    
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️  Archivo no encontrado: $filePath');
      continue;
    }
    
    try {
      final content = await file.readAsString();
      String cleanedContent = content;
      int removedFromFile = 0;
      
      for (final importToRemove in importsToRemove) {
        // Different patterns for import statements
        final patterns = [
          "import '$importToRemove';",
          'import "$importToRemove";',
          "import 'package:$importToRemove';",
          'import "package:$importToRemove";',
          "import '$importToRemove';\n",
          'import "$importToRemove";\n',
          "import 'package:$importToRemove';\n",
          'import "package:$importToRemove";\n',
        ];
        
        for (final pattern in patterns) {
          if (cleanedContent.contains(pattern)) {
            cleanedContent = cleanedContent.replaceAll(pattern, '');
            removedFromFile++;
            break;
          }
        }
      }
      
      if (removedFromFile > 0) {
        // Clean up extra newlines
        cleanedContent = cleanedContent.replaceAll(RegExp(r'\n\n\n+'), '\n\n');
        
        await file.writeAsString(cleanedContent);
        totalImportsRemoved += removedFromFile;
        filesModified++;
        print('✅ $filePath: $removedFromFile imports removidos');
      }
    } catch (e) {
      print('❌ Error procesando $filePath: $e');
    }
  }
  
  print('\n🎉 Limpieza de imports completada:');
  print('📁 Archivos modificados: $filesModified');
  print('🗑️  Total imports removidos: $totalImportsRemoved');
}
