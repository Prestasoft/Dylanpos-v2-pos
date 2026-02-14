// top_bar.dart - Migrado a PostgreSQL API
// Firebase Auth deshabilitado - Usar ApiService para autenticación
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// GoogleFonts eliminado para reducir consumo de memoria - usar fuentes locales
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
import '../Provider/transactions_provider.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../Screen/currency/global_currency.dart';
import '../const.dart';
import '../model/personal_information_model.dart';
import '../model/sale_confirmation_model.dart';
import '../Screen/Reports/cuadre_modal.dart';
import '../model/sale_transaction_model.dart';
import '../services/audit_service.dart';
import '../services/version_check_service.dart';
import '../services/api_service.dart';
import '../widgets/update_dialog.dart' hide kMainColor, kTitleColor, kGreyTextColor;

class TopBarWidget extends ConsumerStatefulWidget {
  const TopBarWidget({super.key, this.onMenuTap});

  final void Function()? onMenuTap;

  @override
  ConsumerState<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends ConsumerState<TopBarWidget> {
  final VersionCheckService _versionCheckService = VersionCheckService();
  final ApiService _apiService = ApiService();

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
    return checkUserRoleViewPermissionV2(
        type: 'dashboard'); // Acceso básico al perfil
  }

  // Función para obtener la lista de ventas del día y el total de gastos
  Future<Map<String, dynamic>> _getTodaysSalesData() async {
    final userId = await getUserID();
    if (userId.isEmpty) {
      return {'ventasDelDia': <Map<String, dynamic>>[], 'gastos': 0.0};
    }
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    //List<Map<String, dynamic>> ventasDelDia = [];
    List<SaleTransactionModel> reTransaction = [];
    double gastos = 0.0;
    try {
      List<SaleTransactionModel> transaction =
          await ref.read(transitionProvider.future);
      // final databaseRef =
      //     FirebaseDatabase.instance.ref("$userId/Sales Transition");
      // final snapshot = await databaseRef.get();

      for (var element in transaction.reversed.toList()) {
        final purchaseDate = DateTime.parse(element.purchaseDate);
        if (purchaseDate
                .isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            purchaseDate.isBefore(todayEnd)) {
          reTransaction.add(element);
        }
      }

      // if (snapshot.exists) {
      //   final salesData = snapshot.value as Map<dynamic, dynamic>;
      //   for (var saleEntry in salesData.entries) {
      //     final saleData = saleEntry.value as Map<dynamic, dynamic>;
      //     String? dateField;
      //     if (saleData['purchaseDate'] != null) {
      //       dateField = saleData['purchaseDate'].toString();
      //     } else if (saleData['saleDate'] != null) {
      //       dateField = saleData['saleDate'].toString();
      //     } else if (saleData['date'] != null) {
      //       dateField = saleData['date'].toString();
      //     } else if (saleData['timestamp'] != null) {
      //       dateField = saleData['timestamp'].toString();
      //     }
      //     if (dateField != null) {
      //       try {
      //         DateTime saleDate;
      //         if (dateField.contains('/')) {
      //           final parts = dateField.split('/');
      //           if (parts.length >= 3) {
      //             saleDate = DateTime(
      //               int.parse(parts[2]),
      //               int.parse(parts[1]),
      //               int.parse(parts[0]),
      //             );
      //           } else {
      //             continue;
      //           }
      //         } else if (dateField.contains('-')) {
      //           String datePart = dateField.split(' ')[0];
      //           if (datePart.split('-').length >= 3) {
      //             final parts = datePart.split('-');
      //             saleDate = DateTime(
      //               int.parse(parts[0]),
      //               int.parse(parts[1]),
      //               int.parse(parts[2]),
      //             );
      //           } else {
      //             saleDate = DateTime.parse(dateField);
      //           }
      //         } else {
      //           saleDate = DateTime.parse(dateField);
      //         }
      //         final isToday =
      //             saleDate.isAfter(todayStart.subtract(Duration(seconds: 1))) &&
      //                 saleDate.isBefore(todayEnd);
      //         if (isToday) {
      //           ventasDelDia.add({
      //             'paymentType': saleData['paymentType']?.toString() ?? '',
      //             'amount': double.tryParse(
      //                     saleData['totalAmount']?.toString() ?? '0') ??
      //                 0.0,
      //           });
      //         }
      //       } catch (e) {}
      //     }
      //   }
      // }
    } catch (e) {}
    // Obtener gastos del día - Usa PostgreSQL API
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final response = await _apiService.get('expenses', queryParams: {
        'startDate': todayStr,
        'endDate': todayStr,
        'limit': '1000',
      });

      if (response.success && response.data != null) {
        final expenses = response.data['expenses'] as List<dynamic>? ?? [];
        for (var expense in expenses) {
          final expenseData = Map<String, dynamic>.from(expense);
          final amount = double.tryParse(expenseData['amount']?.toString() ?? '0') ?? 0.0;
          gastos += amount;
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo gastos: $e');
    }
    return {'ventasDelDia': reTransaction, 'gastos': gastos};
  }

  void _showCuadreModal(BuildContext context) async {
    // Mostrar loading mientras se obtienen los datos
    EasyLoading.show(status: 'Obteniendo datos del día...');

    try {
      final todaysData = await _getTodaysSalesData();
      EasyLoading.dismiss();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => CuadreModal(
            ventasDelDia:
                (todaysData['ventasDelDia'] as List<SaleTransactionModel>?) ??
                    [],
            totalGastos: (todaysData['gastos'] as double?) ?? 0.0,
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error al obtener datos: ${e.toString()}');
    }
  }

  @override
  void initState() {
    // Firebase Auth deshabilitado - Usar ApiService para verificar autenticación
    if (!_apiService.isAuthenticated) {
      Restart.restartApp();
    }
    super.initState();
    
    // Configurar el servicio de verificación de versiones
    _versionCheckService.onUpdateAvailable = (versionInfo) {
      // Mostrar diálogo de actualización cuando esté disponible
      if (mounted) {
        showUpdateDialog(context, versionInfo);
      }
    };
  }
  
  @override
  void dispose() {
    _versionCheckService.stopVersionCheck();
    super.dispose();
  }

  /// Marcar todas las notificaciones como leídas - Usa PostgreSQL API
  Future<void> _markAllAsRead(BuildContext context,
      List<SaleConfirmationModel> notifications, WidgetRef ref) async {
    try {
      int markedCount = 0;
      for (final notification in notifications) {
        // Buscar por token y actualizar
        final searchResponse = await _apiService.get('sale-confirmations', queryParams: {
          'token': notification.token,
          'limit': '1',
        });

        if (searchResponse.success && searchResponse.data != null) {
          final confirmations = searchResponse.data['sale_confirmations'] as List<dynamic>? ??
                               searchResponse.data['confirmations'] as List<dynamic>? ?? [];

          if (confirmations.isNotEmpty) {
            final confirmationData = Map<String, dynamic>.from(confirmations.first);
            final confirmationId = confirmationData['id']?.toString();

            if (confirmationId != null) {
              await _apiService.put('sale-confirmations/$confirmationId', {
                'notified': true,
              });
              markedCount++;
            }
          }
        }
      }

      if (markedCount > 0 && mounted) {
        EasyLoading.showSuccess('Notificaciones marcadas como leídas');
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

  void _showNotificationsDialog(BuildContext context,
      List<SaleConfirmationModel> notifications, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * (screenWidth < 600 ? 0.95 : 0.8),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * (screenWidth < 600 ? 0.9 : 0.8),
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
                      style: TextStyle(fontFamily: 'Poppins',
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
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay notificaciones nuevas',
                        style: TextStyle(fontFamily: 'Poppins',
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
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16),
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
                                        builder: (context, setState) =>
                                            MouseRegion(
                                          onEnter: (_) =>
                                              setState(() => isHovering = true),
                                          onExit: (_) => setState(
                                              () => isHovering = false),
                                          cursor: SystemMouseCursors.click,
                                          child: Tooltip(
                                            message: 'Ver factura',
                                            waitDuration:
                                                Duration(milliseconds: 200),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              onTap: () async {
                                                final ref =
                                                    ProviderScope.containerOf(
                                                        rowContext);
                                                final setting = await ref.read(
                                                    generalSettingProvider
                                                        .future);
                                                final profileInfo = await ref
                                                    .read(profileDetailsProvider
                                                        .future);
                                                final saleData =
                                                    notification.saleData;
                                                try {
                                                  EasyLoading.show(
                                                      status:
                                                          'Preparando vista previa...');
                                                  await GeneratePdfAndPrint()
                                                      .printSaleInvoice(
                                                    setting: setting,
                                                    personalInformationModel:
                                                        profileInfo,
                                                    saleTransactionModel:
                                                        saleData,
                                                    context: rowContext,
                                                    printType: 'normal',
                                                    fromSaleReports: true,
                                                    post: saleData,
                                                  );
                                                  EasyLoading.dismiss();
                                                } catch (e) {
                                                  EasyLoading.dismiss();
                                                  EasyLoading.showError(
                                                      'No se pudo generar el PDF: \n${e.toString()}');
                                                }
                                              },
                                              child: AnimatedContainer(
                                                duration:
                                                    Duration(milliseconds: 150),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isHovering
                                                      ? kMainColor.withValues(
                                                          alpha: 0.25)
                                                      : kMainColor.withValues(
                                                          alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Factura de Reserva #${notification.saleData.invoiceNumber.toString().isNotEmpty ? notification.saleData.invoiceNumber : 'N/A'}',
                                                  style: TextStyle(fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: kMainColor,
                                                    decoration: TextDecoration
                                                        .underline,
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
                                      size: 12, color: Colors.green.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Confirmada',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cliente: ${notification.saleData.customerName.isNotEmpty ? notification.saleData.customerName : 'No especificado'}',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Total: ',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '\$${notification.saleData.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kMainColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.access_time,
                                      size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFormat.format(
                                        DateTime.parse(notification.createdAt)),
                                    style: TextStyle(fontFamily: 'Poppins',
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
                          style: TextStyle(fontFamily: 'Poppins',
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
                        onPressed: () =>
                            _markAllAsRead(context, notifications, ref),
                        child: Text(
                          'Marcar como leídas',
                          style: TextStyle(fontFamily: 'Poppins',
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
                          style: TextStyle(fontFamily: 'Poppins',
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

  // Menú adaptativo para dispositivos móviles con botones principales
  // Colores consistentes con el sidebar
  static const Color _purpleVestimentas = Color(0xFF8B5CF6);
  static const Color _greenVentas = Color(0xFF10B981);

  Widget _buildMobileActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD4A853),  // Dorado principal
              Color(0xFFC9973D),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A853).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.apps_rounded, color: Colors.white, size: 22),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Acciones rápidas',
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        if (_canAccessRentClothing())
          PopupMenuItem<String>(
            value: 'rent',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _purpleVestimentas.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checkroom_rounded, color: _purpleVestimentas, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Rentar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _purpleVestimentas,
                  ),
                ),
              ],
            ),
          ),
        if (_canAccessSales())
          PopupMenuItem<String>(
            value: 'sales',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _greenVentas.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: _greenVentas, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Facturar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _greenVentas,
                  ),
                ),
              ],
            ),
          ),
        if (_canAccessClothingStatus())
          PopupMenuItem<String>(
            value: 'clothing_status',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _purpleVestimentas.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: _purpleVestimentas, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Estado Vestimentas',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _purpleVestimentas,
                  ),
                ),
              ],
            ),
          ),
        if (_canAccessAvailabilityCalendar())
          PopupMenuItem<String>(
            value: 'calendar',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _purpleVestimentas.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: _purpleVestimentas, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Disponibilidad',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _purpleVestimentas,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'rent':
            context.go('/reservations/rent-clothes');
            break;
          case 'sales':
            context.go('/sales/inventory-sales');
            break;
          case 'clothing_status':
            context.go('/service-package/dresses');
            break;
          case 'calendar':
            context.go('/calendario-reservas');
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (context, ref, __) {
      AsyncValue<PersonalInformationModel> userProfileDetails =
          ref.watch(profileDetailsProvider);

      // Obtener las notificaciones no notificadas
      final unnotifiedConfirmations =
          ref.watch(unnotifiedConfirmationsProvider);

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
        title: Consumer(builder: (context, ref, __) {
          AsyncValue<PersonalInformationModel> userProfileDetails =
              ref.watch(profileDetailsProvider);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
              // Usamos un enfoque más adaptativo para mostrar botones en móvil
              // Cuando la pantalla es muy pequeña, mostramos un menú desplegable en lugar de botones individuales
              // Colores consistentes con el sidebar
              // Púrpura (Vestimentas): 0xFF8B5CF6
              // Verde (Ventas): 0xFF10B981
              screenWidth < 480
                  ? _buildMobileActionsMenu(context)
                  : screenWidth < 670
                      ? const SizedBox.shrink()
                      : _canAccessRentClothing()
                          ? Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF8B5CF6),  // Púrpura vestimentas
                                    Color(0xFF7C3AED),  // Púrpura más oscuro
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 18, 8),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0)),
                                ),
                                onPressed: () {
                                  context.go('/reservations/rent-clothes');
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.checkroom_rounded, color: kWhite, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Rentar',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 14,
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
              screenWidth < 480
                  ? const SizedBox.shrink() // Ya está en el menú desplegable
                  : screenWidth < 590
                      ? const SizedBox.shrink()
                      : _canAccessSales()
                          ? Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFF10B981),
                                  width: 1.5,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0)),
                                  padding: const EdgeInsets.fromLTRB(16, 8, 18, 8),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: () {
                                  context.go('/sales/inventory-sales');
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt_long_rounded,
                                        color: Color(0xFF10B981), size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Facturar',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF10B981),
                                            fontSize: 14,
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
                  width: screenWidth < 380 ? 120 : screenWidth < 335 ? 150 : 180,
                  child: Text(
                    isSubUser
                        ? '${details.companyName} [$constSubUserTitle]'
                        : details.companyName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: screenWidth < 400 ? 14 : 
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canAccessNotifications())
                    unnotifiedConfirmations.when(
                      data: (notifications) {
                        final hasNotifications = notifications.isNotEmpty;
                        return Container(
                          margin: EdgeInsets.only(right: screenWidth < 400 ? 4 : 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () {
                                if (hasNotifications) {
                                  _showNotificationsDialog(
                                      context, notifications, ref);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('No hay notificaciones nuevas'),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth < 400 ? 4.0 : 6.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      color: kMainColor,
                                      size: screenWidth < 400 ? 24 : 30,
                                    ),
                                    if (hasNotifications)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth < 400 ? 4 : 5, 
                                              vertical: screenWidth < 400 ? 1 : 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: screenWidth < 400 ? 16 : 18,
                                            minHeight: screenWidth < 400 ? 16 : 18,
                                          ),
                                          child: Text(
                                            notifications.length.toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: screenWidth < 400 ? 10 : 11,
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
                  // Botón de cuadre de caja - OCULTO (no se usa)
                  // if (_canAccessCashRegisterSquare())
                  //   Container(
                  //     margin: EdgeInsets.only(right: screenWidth < 400 ? 2 : 4),
                  //     decoration: BoxDecoration(
                  //       color: const Color(0xFF15CD75).withValues(alpha: 0.15),
                  //       borderRadius: BorderRadius.circular(8),
                  //       border: Border.all(
                  //         color: const Color(0xFF15CD75),
                  //         width: 0.5,
                  //       ),
                  //     ),
                  //     child: IconButton(
                  //       icon: Icon(Icons.point_of_sale,
                  //           color: Color(0xFF15CD75), size: screenWidth < 400 ? 22 : 28),
                  //       tooltip: 'Cuadrar Caja',
                  //       style: IconButton.styleFrom(
                  //         foregroundColor: const Color(0xFF15CD75),
                  //         backgroundColor: Colors.transparent,
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         padding: EdgeInsets.all(screenWidth < 400 ? 6 : 8),
                  //       ),
                  //       onPressed: () => _showCuadreModal(context),
                  //     ),
                  //   ),
                ],
              ),
              // Dropdown de Vestimentas - Solo visible en pantallas >= 590px
              // Usa el color púrpura consistente con la sección de vestimentas del sidebar
              if (screenWidth >= 590 && (_canAccessClothingStatus() || _canAccessAvailabilityCalendar()))
                const SizedBox(width: 10),
              if (screenWidth >= 590 && (_canAccessClothingStatus() || _canAccessAvailabilityCalendar()))
                PopupMenuButton<String>(
                  tooltip: 'Vestimentas',
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  offset: const Offset(0, 8),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.dry_cleaning_rounded, color: Color(0xFF8B5CF6), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Vestimentas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8B5CF6), size: 20),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    if (_canAccessClothingStatus())
                      PopupMenuItem<String>(
                        value: 'status',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF8B5CF6), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estado de Vestimentas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Ver y gestionar inventario',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_canAccessAvailabilityCalendar())
                      PopupMenuItem<String>(
                        value: 'availability',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disponibilidad',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Calendario de reservas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'status':
                        context.go('/service-package/dresses');
                        break;
                      case 'availability':
                        context.go('/calendario-reservas');
                        break;
                    }
                  },
                ),
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
                ),
              ),
            ],
          );
        }),
        actions: [
          // Badge de versión profesional
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kMainColor.withValues(alpha: 0.1),
                  kMainColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kMainColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 14,
                  color: kMainColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'v2.1.283',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kMainColor,
                  ),
                ),
              ],
            ),
          ),
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
                    color: const Color(0xFF2DB0F6).withValues(alpha: 0.1),
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
                  // Botón de verificar actualizaciones
                  PopupMenuItem(
                    onTap: () async {
                      EasyLoading.show(status: 'Verificando actualizaciones...');
                      try {
                        // Configurar callback temporal para esta verificación manual
                        bool updateFound = false;
                        VersionInfo? foundUpdate;
                        
                        _versionCheckService.onUpdateAvailable = (versionInfo) {
                          updateFound = true;
                          foundUpdate = versionInfo;
                        };
                        
                        // Forzar verificación manual
                        await _versionCheckService.checkForUpdates();
                        EasyLoading.dismiss();
                        
                        if (updateFound && foundUpdate != null) {
                          // Mostrar el diálogo de actualización
                          if (mounted) {
                            showUpdateDialog(context, foundUpdate!);
                          }
                        } else {
                          EasyLoading.showSuccess('Sistema actualizado ✓');
                        }
                        
                        // Restaurar el callback original
                        _versionCheckService.onUpdateAvailable = (versionInfo) {
                          if (mounted) {
                            showUpdateDialog(context, versionInfo);
                          }
                        };
                      } catch (e) {
                        EasyLoading.dismiss();
                        EasyLoading.showError('Error al verificar actualizaciones');
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.system_update_alt,
                            size: 18.0, color: kTitleColor),
                        const SizedBox(width: 4.0),
                        Text(
                          'Verificar Actualizaciones',
                          style: kTextStyle.copyWith(color: kTitleColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () async {
                      // Registrar logout en auditoría antes de cerrar sesión
                      await AuditService().logLogout();

                      // Limpiar token del API (PostgreSQL)
                      await _apiService.logout();

                      // Firebase Auth deshabilitado
                      // await FirebaseAuth.instance.signOut();

                      EasyLoading.showSuccess('Sesión cerrada correctamente');
                      if (context.mounted) {
                        context.go('/');
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
