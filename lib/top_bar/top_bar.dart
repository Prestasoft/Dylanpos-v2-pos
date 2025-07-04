import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as ri;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:restart_app/restart_app.dart';
import 'package:salespro_admin/Route/static_string.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../Provider/notification_provider.dart';
import '../Provider/profile_provider.dart';
import '../Provider/general_setting_provider.dart';
import '../PDF/print_pdf.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../Screen/currency/global_currency.dart';
import '../const.dart';
import '../model/personal_information_model.dart';
import '../model/sale_confirmation_model.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Screen/Reports/cuadre_modal.dart';

class TopBarWidget extends StatefulWidget {
  const TopBarWidget({super.key, this.onMenuTap});

  final void Function()? onMenuTap;

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  
  // Funciones de verificación de permisos para cada botón del header
  bool _canAccessRentClothing() {
    if (!isSubUser) return true;
    return checkUserRoleViewPermissionV2(type: 'rent_clothing');
  }

  bool _canAccessSales() {
    if (!isSubUser) return true;
    return checkUserRoleViewPermissionV2(type: 'sales') || 
           checkUserRoleViewPermissionV2(type: 'inventory_sales');
  }

  bool _canAccessClothingStatus() {
    if (!isSubUser) return true;
    return checkUserRoleViewPermissionV2(type: 'services') ||
           checkUserRoleViewPermissionV2(type: 'register_clothing');
  }

  bool _canAccessAvailabilityCalendar() {
    if (!isSubUser) return true;
    return checkUserRoleViewPermissionV2(type: 'reservation_calendar') ||
           checkUserRoleViewPermissionV2(type: 'reservations');
  }

  bool _canAccessNotifications() {
    if (!isSubUser) return true;
    // Las notificaciones pueden ser accesibles para usuarios con permisos de ventas o reservas
    return checkUserRoleViewPermissionV2(type: 'sales') ||
           checkUserRoleViewPermissionV2(type: 'reservations');
  }

  bool _canAccessCashRegisterSquare() {
    if (!isSubUser) return true;
    return checkUserRoleViewPermissionV2(type: 'reports') ||
           checkUserRoleViewPermissionV2(type: 'transaction');
  }

  bool _canAccessProfile() {
    if (!isSubUser) return true;
    return checkUserRoleViewPermissionV2(type: 'dashboard'); // Acceso básico al perfil
  }

  // Función para obtener los totales de ventas y gastos del día actual
  Future<Map<String, double>> _getTodaysSalesTotals() async {
    final userId = await getUserID();
    print('🔑 User ID obtenido: "$userId"');
    
    if (userId.isEmpty) {
      print('❌ Error: User ID está vacío');
      return {'efectivo': 0.0, 'tarjeta': 0.0, 'transferencia': 0.0, 'gastos': 0.0};
    }
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    print('🔍 Buscando ventas y gastos del día: ${todayStart.toString()} hasta ${todayEnd.toString()}');
    
    Map<String, double> totals = {
      'efectivo': 0.0,
      'tarjeta': 0.0,
      'transferencia': 0.0,
      'gastos': 0.0,
    };

    try {
      final databaseRef = FirebaseDatabase.instance.ref("$userId/Sales Transition");
      print('📡 Consultando Firebase en: $userId/Sales Transition');
      
      final snapshot = await databaseRef.get();
      
      if (snapshot.exists) {
        final salesData = snapshot.value as Map<dynamic, dynamic>;
        print('📊 Total de ventas encontradas: ${salesData.length}');
        
        int ventasDelDia = 0;
        for (var saleEntry in salesData.entries) {
          final saleData = saleEntry.value as Map<dynamic, dynamic>;
          
          // Debug: mostrar estructura de datos (solo para la primera venta)
          if (ventasDelDia == 0) {
            print('📝 Campos disponibles: ${saleData.keys.toList()}');
          }
          
          // Verificar si la venta es del día actual - revisar múltiples campos de fecha
          String? dateField;
          if (saleData['purchaseDate'] != null) {
            dateField = saleData['purchaseDate'].toString();
          } else if (saleData['saleDate'] != null) {
            dateField = saleData['saleDate'].toString();
          } else if (saleData['date'] != null) {
            dateField = saleData['date'].toString();
          } else if (saleData['timestamp'] != null) {
            dateField = saleData['timestamp'].toString();
          }
          
          if (dateField != null) {
            try {
              DateTime saleDate;
              
              // Intentar diferentes formatos de fecha
              if (dateField.contains('/')) {
                // Formato dd/MM/yyyy
                final parts = dateField.split('/');
                if (parts.length >= 3) {
                  saleDate = DateTime(
                    int.parse(parts[2]), // año
                    int.parse(parts[1]), // mes
                    int.parse(parts[0]), // día
                  );
                } else {
                  continue;
                }
              } else if (dateField.contains('-')) {
                // Formato ISO (YYYY-MM-DD) o DateTime.toString()
                // Primero extraer solo la parte de fecha si tiene hora
                String datePart = dateField.split(' ')[0];
                if (datePart.split('-').length >= 3) {
                  final parts = datePart.split('-');
                  saleDate = DateTime(
                    int.parse(parts[0]), // año
                    int.parse(parts[1]), // mes
                    int.parse(parts[2]), // día
                  );
                } else {
                  // Intentar parse directo
                  saleDate = DateTime.parse(dateField);
                }
              } else {
                // Formato timestamp o parse directo
                saleDate = DateTime.parse(dateField);
              }
              
              final isToday = saleDate.isAfter(todayStart.subtract(Duration(seconds: 1))) && saleDate.isBefore(todayEnd);
              print('📅 Fecha de venta: ${saleDate.toString()}, ¿Es hoy?: $isToday');
              
              if (isToday) {
                ventasDelDia++;
                final totalAmount = double.tryParse(saleData['totalAmount']?.toString() ?? '0') ?? 0.0;
                final paymentType = saleData['paymentType']?.toString().toLowerCase() ?? '';
                final invoiceNumber = saleData['invoiceNumber']?.toString() ?? 'N/A';
                
                print('💰 Venta #$ventasDelDia encontrada:');
                print('   📄 Factura: $invoiceNumber');
                print('   💵 Monto: $totalAmount');
                print('   🏷️ Método: $paymentType');
                print('   📅 Fecha: ${saleDate.toString()}');
                
                // Categorizar por método de pago - ampliar criterios
                if (paymentType.contains('cash') || 
                    paymentType.contains('efectivo') || 
                    paymentType.contains('Cash') ||
                    paymentType.contains('Efectivo')) {
                  totals['efectivo'] = (totals['efectivo'] ?? 0.0) + totalAmount;
                  print('   ✅ Categorizado como EFECTIVO. Total efectivo: ${totals['efectivo']}');
                } else if (paymentType.contains('card') || 
                          paymentType.contains('tarjeta') ||
                          paymentType.contains('Card') ||
                          paymentType.contains('Tarjeta') ||
                          paymentType.contains('bank') ||
                          paymentType.contains('Bank')) {
                  totals['tarjeta'] = (totals['tarjeta'] ?? 0.0) + totalAmount;
                  print('   ✅ Categorizado como TARJETA. Total tarjeta: ${totals['tarjeta']}');
                } else if (paymentType.contains('transfer') || 
                          paymentType.contains('transferencia') ||
                          paymentType.contains('Transfer') ||
                          paymentType.contains('Transferencia') ||
                          paymentType.contains('mobile') ||
                          paymentType.contains('Mobile')) {
                  totals['transferencia'] = (totals['transferencia'] ?? 0.0) + totalAmount;
                  print('   ✅ Categorizado como TRANSFERENCIA. Total transferencia: ${totals['transferencia']}');
                } else {
                  print('   ⚠️ Método de pago no reconocido: $paymentType - agregando a efectivo por defecto');
                  totals['efectivo'] = (totals['efectivo'] ?? 0.0) + totalAmount;
                  print('   ✅ Agregado a EFECTIVO por defecto. Total efectivo: ${totals['efectivo']}');
                }
              }
            } catch (e) {
              print('❌ Error parsing date for sale: $e, fecha: $dateField');
            }
          } else {
            print('⚠️ Venta sin fecha encontrada');
          }
        }
        print('📈 Total de ventas del día encontradas: $ventasDelDia');
      } else {
        print('⚠️ No se encontraron datos de ventas en Firebase');
        print('🔍 Verificar que exista la ruta: $userId/Sales Transition');
      }
    } catch (e) {
      print('❌ Error fetching today\'s sales: $e');
    }
    
    // Obtener gastos del día
    try {
      print('💸 Obteniendo gastos del día...');
      final expensesRef = FirebaseDatabase.instance.ref("$userId/Expense");
      final expensesSnapshot = await expensesRef.get();
      
      if (expensesSnapshot.exists) {
        final expensesData = expensesSnapshot.value as Map<dynamic, dynamic>;
        print('📊 Total de gastos encontrados: ${expensesData.length}');
        
        int gastosDelDia = 0;
        for (var expenseEntry in expensesData.entries) {
          final expenseData = expenseEntry.value as Map<dynamic, dynamic>;
          
          // Verificar si el gasto es del día actual
          String? dateField = expenseData['expenseDate']?.toString();
          
          if (dateField != null) {
            try {
              DateTime expenseDate;
              
              // Intentar diferentes formatos de fecha para gastos
              if (dateField.contains('/')) {
                // Formato dd/MM/yyyy
                final parts = dateField.split('/');
                if (parts.length >= 3) {
                  expenseDate = DateTime(
                    int.parse(parts[2]), // año
                    int.parse(parts[1]), // mes
                    int.parse(parts[0]), // día
                  );
                } else {
                  continue;
                }
              } else if (dateField.contains('-')) {
                // Formato ISO (YYYY-MM-DD) o DateTime.toString()
                String datePart = dateField.split(' ')[0];
                if (datePart.split('-').length >= 3) {
                  final parts = datePart.split('-');
                  expenseDate = DateTime(
                    int.parse(parts[0]), // año
                    int.parse(parts[1]), // mes
                    int.parse(parts[2]), // día
                  );
                } else {
                  expenseDate = DateTime.parse(dateField);
                }
              } else {
                expenseDate = DateTime.parse(dateField);
              }
              
              final isToday = expenseDate.isAfter(todayStart.subtract(Duration(seconds: 1))) && expenseDate.isBefore(todayEnd);
              print('📅 Fecha de gasto: ${expenseDate.toString()}, ¿Es hoy?: $isToday');
              
              if (isToday) {
                gastosDelDia++;
                final amount = double.tryParse(expenseData['amount']?.toString() ?? '0') ?? 0.0;
                final expenseFor = expenseData['expanseFor']?.toString() ?? '';
                final category = expenseData['category']?.toString() ?? '';
                final paymentType = expenseData['paymentType']?.toString() ?? '';
                
                print('💸 Gasto #$gastosDelDia encontrado:');
                print('   💰 Monto: $amount');
                print('   📝 Para: $expenseFor');
                print('   🏷️ Categoría: $category');
                print('   💳 Método pago: $paymentType');
                print('   📅 Fecha: ${expenseDate.toString()}');
                
                totals['gastos'] = (totals['gastos'] ?? 0.0) + amount;
                print('   ✅ Agregado a gastos. Total gastos: ${totals['gastos']}');
              }
            } catch (e) {
              print('❌ Error parsing date for expense: $e, fecha: $dateField');
            }
          } else {
            print('⚠️ Gasto sin fecha encontrado');
          }
        }
        print('💸 Total de gastos del día encontrados: $gastosDelDia');
        print('💸 Total gastos acumulado: ${totals['gastos']}');
      } else {
        print('⚠️ No se encontraron datos de gastos en Firebase');
        print('🔍 Verificar que exista la ruta: $userId/Expense');
      }
    } catch (e) {
      print('❌ Error fetching today\'s expenses: $e');
    }
    
    print('📈 RESUMEN FINAL DE TOTALES:');
    print('🏪 VENTAS DEL DÍA:');
    print('   💵 Efectivo: RD${totals['efectivo']?.toStringAsFixed(2)}');
    print('   💳 Tarjeta: RD${totals['tarjeta']?.toStringAsFixed(2)}');
    print('   📱 Transferencia: RD${totals['transferencia']?.toStringAsFixed(2)}');
    final totalVentas = (totals['efectivo'] ?? 0) + (totals['tarjeta'] ?? 0) + (totals['transferencia'] ?? 0);
    print('   🏦 Total Ventas: RD${totalVentas.toStringAsFixed(2)}');
    print('');
    print('💸 GASTOS DEL DÍA:');
    print('   💰 Total Gastos: RD${totals['gastos']?.toStringAsFixed(2)}');
    print('');
    print('🏆 BALANCE FINAL:');
    final balanceNeto = totalVentas - (totals['gastos'] ?? 0);
    print('   💎 Balance Neto: RD${balanceNeto.toStringAsFixed(2)} ${balanceNeto >= 0 ? '✅' : '❌'}');
    print('');
    print('📊 Datos completos: $totals');
    return totals;
  }

  void _showCuadreModal(BuildContext context) async {
    print('🎯 Usuario clickeó el botón de cuadre de caja');
    
    // Mostrar loading mientras se obtienen los datos
    EasyLoading.show(status: 'Obteniendo datos del día...');
    
    try {
      print('📡 Iniciando obtención de datos de ventas...');
      final todaysTotals = await _getTodaysSalesTotals();
      print('📊 Datos obtenidos del servidor: $todaysTotals');
      EasyLoading.dismiss();
      
      if (context.mounted) {
        print('🎨 Mostrando modal con los siguientes valores:');
        print('💵 Efectivo: ${todaysTotals['efectivo']}');
        print('💳 Tarjeta: ${todaysTotals['tarjeta']}');
        print('📱 Transferencia: ${todaysTotals['transferencia']}');
        print('💸 Gastos: ${todaysTotals['gastos']}');
        
        showDialog(
          context: context,
          builder: (context) => CuadreModal(
            totalEfectivo: todaysTotals['efectivo'] ?? 0.0,
            totalTarjeta: todaysTotals['tarjeta'] ?? 0.0,
            totalTransferencia: todaysTotals['transferencia'] ?? 0.0,
            totalGastos: todaysTotals['gastos'] ?? 0.0,
          ),
        );
      }
    } catch (e) {
      print('❌ Error en _showCuadreModal: $e');
      EasyLoading.dismiss();
      EasyLoading.showError('Error al obtener datos: ${e.toString()}');
    }
  }

  @override
  void initState() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) {
      Restart.restartApp();
    }
    super.initState();
  }

  Future<void> _markAllAsRead(BuildContext context, 
    List<SaleConfirmationModel> notifications, 
    WidgetRef ref) async {
      
  final userId = await getUserID();
  final databaseRef = FirebaseDatabase.instance.ref("$userId/SaleConfirmations");

  try {
    // Primero obtenemos todos los registros para encontrar los que coinciden
    final snapshot = await databaseRef.get();
    final Map<dynamic, dynamic> allRecords = snapshot.value as Map<dynamic, dynamic>? ?? {};

    final updates = <String, dynamic>{};

    for (final notification in notifications) {
      // Buscamos el registro que coincida con el token
      final recordEntry = allRecords.entries.firstWhere(
        (entry) => entry.value['token'] == notification.token,
        orElse: () => const MapEntry(null, null),
      );

      if (recordEntry.key != null) {
        updates['${recordEntry.key}/notified'] = true;
      }
    }

    if (updates.isNotEmpty) {
      await databaseRef.update(updates);
      if (mounted) {
        EasyLoading.showSuccess('Notificaciones marcadas como leídas');
      }
    }
  } catch (e) {
    debugPrint('Error al marcar como leídas: $e');
    if (mounted) {
      EasyLoading.showError('Error al actualizar notificaciones');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

  void _showNotificationsDialog(BuildContext context, List<SaleConfirmationModel> notifications, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del diálogo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kMainColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'Notificaciones de Confirmación',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contenido
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off, 
                          size: 48, 
                          color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay notificaciones nuevas',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Builder(
                                    builder: (rowContext) {
                                      bool isHovering = false;
                                      return StatefulBuilder(
                                        builder: (context, setState) => MouseRegion(
                                          onEnter: (_) => setState(() => isHovering = true),
                                          onExit: (_) => setState(() => isHovering = false),
                                          cursor: SystemMouseCursors.click,
                                          child: Tooltip(
                                            message: 'Ver factura',
                                            waitDuration: Duration(milliseconds: 200),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(4),
                                              onTap: () async {
                                                final ref = ri.ProviderScope.containerOf(rowContext);
                                                final setting = await ref.read(generalSettingProvider.future);
                                                final profileInfo = await ref.read(profileDetailsProvider.future);
                                                final saleData = notification.saleData;
                                                try {
                                                  EasyLoading.show(status: 'Preparando vista previa...');
                                                  await GeneratePdfAndPrint().printSaleInvoice(
                                                    setting: setting,
                                                    personalInformationModel: profileInfo,
                                                    saleTransactionModel: saleData,
                                                    context: rowContext,
                                                    printType: 'normal',
                                                    fromSaleReports: true,
                                                    post: saleData,
                                                  );
                                                  EasyLoading.dismiss();
                                                } catch (e) {
                                                  EasyLoading.dismiss();
                                                  EasyLoading.showError('No se pudo generar el PDF: \n${e.toString()}');
                                                }
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(milliseconds: 150),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isHovering ? kMainColor.withOpacity(0.25) : kMainColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Factura de Reserva #${notification.saleData.invoiceNumber.toString().isNotEmpty ? notification.saleData.invoiceNumber : 'N/A'}',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: kMainColor,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  Icon(Icons.circle, 
                                      size: 12, 
                                      color: Colors.green.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Confirmada',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cliente: ${notification.saleData.customerName.isNotEmpty ? notification.saleData.customerName : 'No especificado'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Total: ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '\$${notification.saleData.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kMainColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.access_time, 
                                      size: 16, 
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFormat.format(DateTime.parse(notification.createdAt)),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Footer del diálogo
              if (notifications.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cerrar',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => _markAllAsRead(context, notifications, ref),
                        child: Text(
                          'Marcar como leídas',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/sale-confirmations');
                        },
                        child: Text(
                          'Ver todas',
                          style: GoogleFonts.poppins(
                            color: kMainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ri.Consumer(builder: (context, ref, __) {
      AsyncValue<PersonalInformationModel> userProfileDetails =
          ref.watch(profileDetailsProvider);
      
      // Obtener las notificaciones no notificadas
      final unnotifiedConfirmations = ref.watch(unnotifiedConfirmationsProvider);
      
      return AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 40,
        leading: rf.ResponsiveValue<Widget?>(
          context,
          conditionalValues: [
            rf.Condition.largerThan(
              name: BreakpointName.MD.name,
              value: null,
            ),
          ],
          defaultValue: IconButton(
            onPressed: widget.onMenuTap,
            icon: const Tooltip(
              message: 'Open Navigation menu',
              waitDuration: Duration(milliseconds: 350),
              child: Icon(Icons.menu),
            ),
          ),
        ).value,
        toolbarHeight: rf.ResponsiveValue<double?>(
          context,
          conditionalValues: [
            rf.Condition.largerThan(name: BreakpointName.SM.name, value: 70)
          ],
        ).value,
        surfaceTintColor: Colors.transparent,
        title: ri.Consumer(builder: (context, ref, __) {
          AsyncValue<PersonalInformationModel> userProfileDetails =
              ref.watch(profileDetailsProvider);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              screenWidth < 670
                  ? const SizedBox.shrink()
                  : _canAccessRentClothing()
                      ? SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              backgroundColor: kMainColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              textStyle: kTextStyle.copyWith(color: kWhite),
                            ),
                            onPressed: () {
                              context.go('/reservations/rent-clothes');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded, color: kWhite),
                                Text(
                                  'Rentar',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
              screenWidth < 670
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : _canAccessSales()
                      ? SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              backgroundColor: kMainColor.withValues(alpha: 0.1),
                              side: const BorderSide(color: kMainColor, width: 1),
                              textStyle: kTextStyle.copyWith(color: kWhite),
                              surfaceTintColor: lightGreyColor,
                              shadowColor: lightGreyColor.withOpacity(0.1),
                            ),
                            onPressed: () {
                              context.go('/sales/inventory-sales');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded, color: kMainColor),
                                Text(
                                  'Facturar',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: kMainColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              userProfileDetails.when(data: (details) {
                return SizedBox(
                  width: screenWidth < 335 ? 150 : 180,
                  child: Text(
                    isSubUser
                        ? '${details.companyName} [$constSubUserTitle]'
                        : details.companyName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize:
                          context.width() < 900 ? 18 : context.width() * 0.005,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.start,
                  ),
                );
              }, error: (e, stack) {
                return Text(e.toString());
              }, loading: () {
                return const Text('');
              }),
              const Spacer(),
              // Botón de notificaciones mejorado y botón de cuadre
              Row(
                children: [
                  if (_canAccessNotifications())
                    unnotifiedConfirmations.when(
                      data: (notifications) {
                      final hasNotifications = notifications.isNotEmpty;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              if (hasNotifications) {
                                _showNotificationsDialog(context, notifications, ref);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No hay notificaciones nuevas'),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_none,
                                    color: kMainColor,
                                    size: 30,
                                  ),
                                  if (hasNotifications)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          notifications.length.toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, stack) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                  // Botón de cuadre de caja
                  if (_canAccessCashRegisterSquare())
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15CD75).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF15CD75),
                          width: 0.5,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.point_of_sale, 
                          color: Color(0xFF15CD75), 
                          size: 28
                        ),
                        tooltip: 'Cuadrar Caja',
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFF15CD75),
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: () => _showCuadreModal(context),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : _canAccessClothingStatus()
                      ? SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              backgroundColor: kMainColor.withValues(alpha: 0.05),
                              side: const BorderSide(color: kMainColor, width: 1),
                              textStyle: kTextStyle.copyWith(
                                  color: const Color(0xFFFF2525)),
                              surfaceTintColor: kWhite,
                              shadowColor: kMainColor.withOpacity(0.1),
                              foregroundColor: kMainColor.withOpacity(0.1),
                            ),
                            onPressed: () {
                              context.go('/service-package/dresses');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded, color: kMainColor),
                                Text(
                                  'Estado de Vestimentas',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: kMainColor,
                                          fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
              screenWidth < 800
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              screenWidth < 800
                  ? const SizedBox.shrink()
                  : _canAccessAvailabilityCalendar()
                      ? SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              backgroundColor:
                                  const Color(0xFF15CD75).withValues(alpha: 0.05),
                              side: const BorderSide(
                                  color: Color(0xFF15CD75), width: 1),
                              textStyle: kTextStyle.copyWith(
                                  color: const Color(0xFF15CD75)),
                              surfaceTintColor: kWhite,
                              shadowColor: const Color(0xFF15CD75).withOpacity(0.1),
                              foregroundColor:
                                  const Color(0xFF15CD75).withOpacity(0.1),
                            ),
                            onPressed: () {
                              context.go('/calendario-reservas');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: Color(0xFF15CD75)),
                                Text(
                                  'Disponibilidad de Vestimentas',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF15CD75),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
              screenWidth < 1260
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              screenWidth < 1260
                  ? const SizedBox.shrink()
                  : /* const GlobalLanguage(isDrawer: false), */
              screenWidth < 1430
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              screenWidth < 1430
                  ? const SizedBox.shrink()
                  : const GlobalCurrency(isDrawer: false)
            ],
          );
        }),
        actions: [
          userProfileDetails.when(data: (details) {
            return Theme(
              data: ThemeData(
                  highlightColor: dropdownItemColor,
                  focusColor: dropdownItemColor,
                  hoverColor: dropdownItemColor),
              child: PopupMenuButton(
                surfaceTintColor: Colors.white,
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.under,
                icon: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DB0F6).withOpacity(0.1),
                    shape: BoxShape.rectangle,
                  ),
                  child: const Icon(Icons.settings,
                      color: Color(0xFF2DB0F6), size: 30.0),
                ),
                itemBuilder: (BuildContext bc) => [
                  PopupMenuItem(
                    onTap: () {
                      if (_canAccessProfile()) {
                        isSubUser
                            ? null
                            : context.go('/profile-update', extra: details);
                      } else {
                        EasyLoading.showError('Acceso no autorizado');
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.manage_accounts_sharp,
                            size: 18.0, color: kTitleColor),
                        const SizedBox(width: 4.0),
                        Text(
                          isSubUser
                              ? '${details.companyName}[$constSubUserTitle]'
                              : lang.S.of(context).prof,
                          style: kTextStyle.copyWith(color: kTitleColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      EasyLoading.showSuccess('Successfully Logged Out');
                      if (context.mounted) {
                        context.go('/', extra: {'replace': true});
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(FeatherIcons.logOut,
                            size: 18.0, color: kTitleColor),
                        const SizedBox(width: 4.0),
                        Text(
                          lang.S.of(context).logOut,
                          style: kTextStyle.copyWith(color: kTitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }, error: (e, stack) {
            return Center(
              child: Text(e.toString()),
            );
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
        ],
      );
    });
  }

  Size get preferredSize => const Size(double.infinity, 64);
}