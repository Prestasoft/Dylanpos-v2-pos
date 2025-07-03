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
import 'package:salespro_admin/global_language.dart';
import '../Provider/notification_provider.dart';
import '../Provider/profile_provider.dart';
import '../Provider/general_setting_provider.dart';
import '../PDF/print_pdf.dart';
import '../model/sale_transaction_model.dart';
import '../Screen/Widgets/Constant Data/constant.dart';
import '../Screen/currency/global_currency.dart';
import '../const.dart';
import '../model/personal_information_model.dart';
import '../model/sale_confirmation_model.dart';
import 'package:firebase_database/firebase_database.dart';

class TopBarWidget extends StatefulWidget {
  const TopBarWidget({super.key, this.onMenuTap});

  final void Function()? onMenuTap;

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
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
                  : SizedBox(
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
                    ),
              screenWidth < 670
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : SizedBox(
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
                    ),
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
              // Botón de notificaciones mejorado
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
              const SizedBox(width: 10),
              screenWidth < 590
                  ? const SizedBox.shrink()
                  : SizedBox(
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
                    ),
              screenWidth < 800
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 10.0),
              screenWidth < 800
                  ? const SizedBox.shrink()
                  : SizedBox(
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
                      isSubUser
                          ? null
                          : context.go('/profile-update', extra: details);
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