// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:salespro_admin/model/daily_transaction_model.dart';
import '../../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
// // import 'package:hugeicons/hugeicons.dart'; // Eliminado // Eliminado para reducir memoria
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Provider/daily_transaction_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';
import 'package:salespro_admin/Screen/Sale%20List/sale_edit.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/delete_invoice_functions.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../../PDF/print_pdf.dart';
import '../../Provider/product_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../services/deletion_password_service.dart';
import '../../services/whatsapp_template_service.dart';
import '../../services/whatsapp_credentials_service.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/sale_transaction_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../../services/audit_service.dart';
import '../../model/audit_model.dart';

class SaleList extends StatefulWidget {
  const SaleList({super.key});

  @override
  State<SaleList> createState() => _SaleListState();
}

class _SaleListState extends State<SaleList> {
  int currentPage = 1;
  late int itemsPerPage = 10;

  // Controller para mantener el texto de búsqueda cuando se reconstruye la UI
  final TextEditingController _searchController = TextEditingController();

  // ValueNotifier para búsqueda (NO usa setState - evita reconstruir el TextField)
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  // Timer para debounce de búsqueda
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Función de búsqueda con debounce (500ms como en Due List)
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchQueryNotifier.value != value) {
        _searchQueryNotifier.value = value;
        currentPage = 1; // Reset a página 1
      }
    });
  }

  // Widget del campo de búsqueda que NO se reconstruye
  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12.0),
          hintText: 'Buscar por nombre, teléfono o # factura...',
          hintStyle: const TextStyle(color: kNeutral400),
          prefixIcon: const Icon(FeatherIcons.search, color: kNeutral400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: kBorderColorTextField),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: kBorderColorTextField),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: kMainColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  final _horizontalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Column(
          children: [
            // BÚSQUEDA FIJA - No se reconstruye
            _buildSearchField(context),
            // DATOS - Se reconstruyen cuando cambia la búsqueda
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, searchQuery, child) {
                    return Consumer(builder: (_, consuearRef, watch) {
                      // Si hay búsqueda, usar el provider de búsqueda directa del API (sin límite de 100)
                      // Si no hay búsqueda, usar el provider normal con límite de 100
                      final bool isSearching = searchQuery.trim().isNotEmpty;

                      AsyncValue<List<SaleTransactionModel>> transactionReport = isSearching
                          ? consuearRef.watch(searchSalesProvider(searchQuery.trim()))
                          : consuearRef.watch(transitionProvider);
            final profile = consuearRef.watch(profileDetailsProvider);
            final settingProvider = consuearRef.watch(generalSettingProvider);

            return transactionReport.when(
              data: (mainTransaction) {
                // Las ventas ya vienen filtradas del API cuando hay búsqueda
                // o todas las ventas (hasta 100) cuando no hay búsqueda
                List<SaleTransactionModel> showAbleSaleTransactions = mainTransaction;


                final totalPages = itemsPerPage == -1 ? 1 : (showAbleSaleTransactions.length / itemsPerPage).ceil();
                final startIndex = itemsPerPage == -1 ? 0 : (currentPage - 1) * itemsPerPage;
                final endIndex = itemsPerPage == -1 
                    ? showAbleSaleTransactions.length 
                    : (startIndex + itemsPerPage).clamp(0, showAbleSaleTransactions.length);

                final paginatedTransactions = showAbleSaleTransactions.sublist(startIndex, endIndex);

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: kWhite,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        child: Text(
                          lang.S.of(context).salesList,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1.0,
                        color: kDividerColor,
                      ),
                      const SizedBox(height: 16),
                      ResponsiveGridRow(
                        rowSegments: 100, 
                        children: [
                          ResponsiveGridCol(
                            xs: screenWidth < 360
                                ? 50
                                : screenWidth > 430
                                    ? 33
                                    : 40,
                            md: screenWidth < 768
                                ? 24
                                : screenWidth < 950
                                    ? 20
                                    : 15,
                            lg: screenWidth < 1700 ? 15 : 10,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                alignment: Alignment.center,
                                height: 48,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: kNeutral300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(child: Text('Show-', style: theme.textTheme.bodyLarge)),
                                    DropdownButton<int>(
                                      isDense: true,
                                      padding: EdgeInsets.zero,
                                      underline: const SizedBox(),
                                      value: itemsPerPage,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.black,
                                      ),
                                      items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(
                                            value == -1 ? "All" : value.toString(),
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          itemsPerPage = newValue ?? 10;
                                          currentPage = 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      paginatedTransactions.isNotEmpty
                          ? Column(
                              children: [
                                Scrollbar(
                                  thickness: 8.0,
                                  thumbVisibility: true,
                                  controller: _horizontalScroll,
                                  radius: const Radius.circular(5),
                                  child: LayoutBuilder(
                                    builder: (BuildContext context, BoxConstraints constraints) {
                                      final kWidth = MediaQuery.of(context).size.width - 112.5;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        controller: _horizontalScroll,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: kWidth,
                                          ),
                                          child: Theme(
                                            data: theme.copyWith(
                                              dividerColor: Colors.transparent, 
                                              dividerTheme: const DividerThemeData(color: Colors.transparent)
                                            ),
                                            child: DataTable(
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  width: 1,
                                                  color: kNeutral300,
                                                ),
                                              ),
                                              dataRowColor: const WidgetStatePropertyAll(whiteColor),
                                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                              showBottomBorder: false,
                                              dividerThickness: 0.0,
                                              headingTextStyle: theme.textTheme.titleMedium,
                                              dataTextStyle: theme.textTheme.bodyLarge,
                                              columns: [
                                                DataColumn(label: Text(lang.S.of(context).SL, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).date, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).invoice, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).partyName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).amount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).due, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).status, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                                DataColumn(label: Text(lang.S.of(context).setting, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                              ],
                                              rows: List.generate(paginatedTransactions.length, (index) {
                                                return DataRow(cells: [
                                                  DataCell(
                                                    Text(
                                                      (index + 1 + (currentPage - 1) * itemsPerPage).toString(),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].purchaseDate.substring(0, 10),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    InkWell(
                                                      onTap: () async {
                                                        final setting = settingProvider.valueOrNull;
                                                        final profileInfo = profile.value;
                                                        if (setting != null && profileInfo != null) {
                                                          SaleTransactionModel post = checkLossProfit(transitionModel: paginatedTransactions[index]);
                                                          EasyLoading.show(status: 'Preparando vista previa...');
                                                          await GeneratePdfAndPrint().printSaleInvoice(
                                                            setting: setting,
                                                            personalInformationModel: profileInfo,
                                                            saleTransactionModel: paginatedTransactions[index],
                                                            context: context,
                                                            printType: 'normal',
                                                            fromSaleReports: true,
                                                            post: post,
                                                          );
                                                          EasyLoading.dismiss();
                                                        } else {
                                                          EasyLoading.showError('No se pudo cargar la configuración o el perfil');
                                                        }
                                                      },
                                                      child: Text(
                                                        paginatedTransactions[index].invoiceNumber,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                          decoration: TextDecoration.underline,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].customerName,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      '$currency${myFormat.format(double.tryParse(paginatedTransactions[index].totalAmount.toString()) ?? 0)}',
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      "$currency${myFormat.format(double.tryParse(paginatedTransactions[index].dueAmount.toString()) ?? 0)}",
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      paginatedTransactions[index].isPaid! ? lang.S.of(context).paid : lang.S.of(context).due,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    settingProvider.when(
                                                      data: (setting) {
                                                        return SizedBox(
                                                          width: 30,
                                                          child: Theme(
                                                            data: ThemeData(
                                                              highlightColor: dropdownItemColor, 
                                                              focusColor: dropdownItemColor, 
                                                              hoverColor: dropdownItemColor
                                                            ),
                                                            child: PopupMenuButton(
                                                              surfaceTintColor: Colors.white,
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (BuildContext bc) => [
                                                                PopupMenuItem(
                                                                  onTap: () async {
                                                                    final printType = await showDialog<String>(
                                                                      context: context,
                                                                      builder: (context) => AlertDialog(
                                                                        title: Text('Seleccionar formato de impresión'),
                                                                        content: Column(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            ListTile(
                                                                              leading: Icon(Icons.description, color: Colors.green),
                                                                              title: Text('Factura normal'),
                                                                              subtitle: Text('Formato completo A4/Letter'),
                                                                              onTap: () => Navigator.pop(context, 'normal'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            child: Text('Cancelar'),
                                                                            onPressed: () => Navigator.pop(context),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                    
                                                                    if (printType == null) return;
                                                                    
                                                                    final sendWhatsApp = await showDialog<bool>(
                                                                      context: context,
                                                                      builder: (context) => AlertDialog(
                                                                        title: Text('Enviar por WhatsApp'),
                                                                        content: Text('¿Desea enviar el comprobante por WhatsApp al cliente?'),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(context, false),
                                                                            child: Text('No'),
                                                                          ),
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(context, true),
                                                                            child: Text('Sí, enviar'),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ) ?? false;

                                                                    SaleTransactionModel post = checkLossProfit(transitionModel: paginatedTransactions[index]);
                                                                    
                                                                    if (sendWhatsApp) {
                                                                      try {
                                                                        EasyLoading.show(status: 'Generando PDF para enviar...');
                                                                        
                                                                        final pdfData = await GeneratePdfAndPrint().printSaleInvoice(
                                                                          setting: setting,
                                                                          personalInformationModel: profile.value!,
                                                                          saleTransactionModel: paginatedTransactions[index],
                                                                          context: context,
                                                                          printType: printType,
                                                                          fromSaleReports: true,
                                                                          post: post,
                                                                          returnPdfData: true,
                                                                        );

                                                                        if (pdfData != null) {
                                                                          await _sendPdfViaWhatsApp(
                                                                            phoneNumber: paginatedTransactions[index].customerPhone,
                                                                            pdfData: pdfData,
                                                                            invoiceNumber: paginatedTransactions[index].invoiceNumber,
                                                                            customerName: paginatedTransactions[index].customerName,
                                                                          );
                                                                        }
                                                                        EasyLoading.dismiss();
                                                                      } catch (e) {
                                                                        EasyLoading.dismiss();
                                                                        EasyLoading.showError('Error al enviar por WhatsApp: ${e.toString()}');
                                                                      }
                                                                    } else {
                                                                      EasyLoading.show(status: 'Preparando impresión...');
                                                                      await GeneratePdfAndPrint().printSaleInvoice(
                                                                        setting: setting,
                                                                        personalInformationModel: profile.value!,
                                                                        saleTransactionModel: paginatedTransactions[index],
                                                                        context: context,
                                                                        printType: printType,
                                                                        fromSaleReports: true,
                                                                        post: post,
                                                                      );
                                                                      EasyLoading.dismiss();
                                                                    }

                                                                    GoRouter.of(bc).pop();
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(Icons.print, color: kGreyTextColor, size: 22.0),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).print,
                                                                        style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  onTap: () {
                                                                    final arg = SaleEdit(
                                                                      transitionModel: paginatedTransactions[index],
                                                                      personalInformationModel: profile.value!,
                                                                      isPosScreen: false,
                                                                      popUpContext: context,
                                                                    );
                                                                    context.push('/sales/sales-edit', extra: arg);
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(IconlyLight.edit, size: 22.0, color: kGreyTextColor),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).edit,
                                                                        style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  onTap: () async {
                                                                    final ref = ProviderScope.containerOf(context);
                                                                    final List<String> idReservaciones = paginatedTransactions[index].reservationIds ?? [];
                                                                    final firstReservationId = idReservaciones.isNotEmpty ? idReservaciones.first : null;
                                                                    final fullReservation = firstReservationId != null 
                                                                        ? await ref.read(fullReservationByIdProviderVQ(firstReservationId).future)
                                                                        : null;

                                                                    final customer = Customer(
                                                                      customerName: paginatedTransactions[index].customerName,
                                                                      phoneNumber: paginatedTransactions[index].customerPhone,
                                                                      invoiceNumber: paginatedTransactions[index].invoiceNumber,
                                                                      payments: [],
                                                                      remainingDebt: paginatedTransactions[index].dueAmount ?? 0,
                                                                      totalPaid: paginatedTransactions[index].totalAmount ?? 0,
                                                                    );

                                                                    String? sellerName = fullReservation?.reservation?['seller_name']?.toString();

                                                                    Future.microtask(() {
                                                                      paysDetails(
                                                                        context: context,
                                                                        invoiceNumber: customer.invoiceNumber,
                                                                        customer: customer,
                                                                        reservedBy: sellerName,
                                                                      );
                                                                    });
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      SvgPicture.asset(
                                                                        "images/dashboard_icon/transaction.svg",
                                                                        height: 22.0,
                                                                        width: 22.0,
                                                                        color: kGreyTextColor,
                                                                      ),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        'Mostrar resumen de pagos',
                                                                        style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  onTap: () {
                                                                    _showDeleteAuthDialog(paginatedTransactions[index], consuearRef);
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.delete_outline,
                                                                        color: kGreyTextColor,
                                                                        size: 22,
                                                                      ),
                                                                      const SizedBox(width: 10.0),
                                                                      Text(
                                                                        lang.S.of(context).delete,
                                                                        style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  onTap: () {
                                                                    if (profile.value != null) {
                                                                      context.push(
                                                                        '/sales/sales-return',
                                                                        extra: {
                                                                          'personalInformationModel': profile.value!,
                                                                          'saleTransactionModel': paginatedTransactions[index],
                                                                        },
                                                                      );
                                                                    } else {
                                                                      EasyLoading.showError('Perfil no cargado');
                                                                    }
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(Icons.assignment_return, size: 22.0, color: kGreyTextColor),
                                                                      const SizedBox(width: 4.0),
                                                                      Text(
                                                                        lang.S.of(context).saleReturn,
                                                                        style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                              child: Center(
                                                                child: Container(
                                                                    height: 18,
                                                                    width: 18,
                                                                    alignment: Alignment.centerRight,
                                                                    child: const Icon(
                                                                      Icons.more_vert_sharp,
                                                                      size: 18,
                                                                    )),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }, 
                                                      error: (e, stack) {
                                                        return Text(e.toString());
                                                      }, 
                                                      loading: () {
                                                        return const Center(
                                                          child: CircularProgressIndicator(),
                                                        );
                                                      }
                                                    ),
                                                  ),
                                                ]);
                                              }
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Showing ${startIndex + 1} to ${endIndex > showAbleSaleTransactions.length ? showAbleSaleTransactions.length : endIndex} of ${showAbleSaleTransactions.length} entries',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: kNeutral700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: kNeutral300),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (currentPage > 1) {
                                                  setState(() {
                                                    currentPage--;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                'Previous',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                                color: kMainColor,
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                                  color: kNeutral300,
                                                ))),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$currentPage',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                                border: Border.symmetric(
                                                    vertical: BorderSide(
                                              color: kNeutral300,
                                            ))),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$totalPages',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (currentPage < totalPages) {
                                                  setState(() {
                                                    currentPage++;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                'Next',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: kNeutral700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        : EmptyWidget(title: lang.S.of(context).noSaleTransaactionFound)
                    ],
                  ),
                );
              }, 
              error: (e, stack) {
                return Center(
                  child: Text(e.toString()),
                );
              }, 
              loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            );
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPdfViaWhatsApp({
    required String phoneNumber,
    required Uint8List pdfData,
    required String invoiceNumber,
    required String customerName,
  }) async {
    try {
      final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!cleanedPhone.startsWith('+')) {
        throw Exception('El número debe incluir código de país (ej: +1...)');
      }

      EasyLoading.show(status: 'Preparando envío...');

      final pdfBase64 = base64Encode(pdfData);

      // Crear mensaje usando plantilla de WhatsApp
      final template = await WhatsAppTemplateService.getTemplate('invoice_caption');
      final safeMessage = WhatsAppTemplateService.replaceVariables(template, {
        'nombre': customerName,
        'factura': invoiceNumber,
      });

      // Obtener credenciales dinámicas de WhatsApp
      final credentials = await WhatsAppCredentialsService.getCredentials();

      final body = {
        'token': credentials.token,
        'to': cleanedPhone,
        'filename': 'Comprobante_${invoiceNumber}.pdf',
        'document': pdfBase64,
        'caption': safeMessage,
      };

      final url = Uri.parse(credentials.getApiUrl('messages/document'));
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
      
      EasyLoading.show(status: 'Enviando...');
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Enviado exitosamente');
      } else {
        throw Exception('Error en API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      EasyLoading.showError('Error al enviar: ${e.toString().replaceAll('\n', ' ')}');
      rethrow;
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      EasyLoading.dismiss();
    }
  }

  void paysDetails({
    required BuildContext context,
    required String invoiceNumber,
    required Customer customer,
    String? reservedBy,
  }) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return Consumer(
          builder: (context, ref, _) {
            final dailyTransactionReport = ref.watch(dailyTransactionProvider);

            return dailyTransactionReport.when(
              data: (transactions) {
                List<DailyTransactionModel> reTransaction = [];
                
                for (var element in transactions.reversed.toList()) {
                  if (element.id == invoiceNumber) {
                    reTransaction.add(element);
                  }
                }

                double totalAbonado = reTransaction.fold(0.0, (sum, payment) => sum + payment.paymentIn);

                return Dialog(
                  surfaceTintColor: kWhite,
                  backgroundColor: kWhite,
                  child: SizedBox(
                    width: 700,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Detalles del Cliente',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nombre: ${customer.customerName}', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 8),
                                    Text('Teléfono: ${customer.phoneNumber}', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 8),
                                    Text('Factura Nº: $invoiceNumber', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 8),
                                    if (reservedBy != null)
                                      Text('Reservado por: $reservedBy', style: theme.textTheme.bodyLarge),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total de la factura:  $currency${myFormat.format(double.tryParse(customer.totalPaid.toString()) ?? 0)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.red),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Pagado:  $currency${myFormat.format(double.tryParse(totalAbonado.toString()) ?? 0)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deuda Actual:  $currency${myFormat.format(double.tryParse(customer.remainingDebt.toString()) ?? 0)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          LayoutBuilder(builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F1F1)),
                                  columns: const [
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Pago Registrado')),
                                    DataColumn(label: Text('Método de Pago')),
                                  ],
                                  rows: reTransaction.map<DataRow>((payment) {
                                    String metodoPago = 'N/A';
                                    String metodoPagoOriginal = 'null';
                                    
                                    if (payment.dueTransactionModel != null) {
                                      var dueModel = payment.dueTransactionModel!;
                                      metodoPagoOriginal = dueModel.paymentType?.toString() ?? 'null';
                                      
                                      if (dueModel.paymentType != null && dueModel.paymentType!.isNotEmpty) {
                                        metodoPago = dueModel.paymentType!;
                                        
                                        switch (metodoPago.toLowerCase().trim()) {
                                          case 'cash':
                                          case 'efectivo':
                                            metodoPago = 'Efectivo';
                                            break;
                                          case 'card':
                                          case 'tarjeta':
                                            metodoPago = 'Tarjeta';
                                            break;
                                          case 'bank':
                                          case 'transferencia':
                                            metodoPago = 'Transferencia';
                                            break;
                                          case 'check':
                                          case 'cheque':
                                            metodoPago = 'Cheque';
                                            break;
                                          default:
                                            break;
                                        }
                                      }
                                    }
                                    
                                    return DataRow(cells: [
                                      DataCell(_fechaConvertida(payment.date)),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Text('$currency${myFormat.format(double.tryParse(payment.paymentIn.toString()) ?? 0)}'),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Text(
                                          metodoPago,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: metodoPago == 'N/A' ? Colors.grey : null,
                                          ),
                                        ),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => AlertDialog(
                title: const Text('Error'),
                content: Text('No se pudieron cargar los pagos.\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _fechaConvertida(String? date) {
    try {
      if (date == null || date.trim().isEmpty) {
        return const Text('-');
      }

      DateTime dateTime = DateTime.parse(date);
      String formattedDate = DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
      return Text(formattedDate);
    } catch (e) {
      return const Text('-');
    }
  }

  Future<void> _showDeleteAuthDialog(SaleTransactionModel transaction, WidgetRef ref) async {
    TextEditingController passwordController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmar Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Esta acción eliminará permanentemente la venta:'),
              SizedBox(height: 8),
              Text('Factura: ${transaction.invoiceNumber}', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Cliente: ${transaction.customerName}'),
              SizedBox(height: 16),
              Text('Ingrese la clave de autorización:'),
              SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Clave de autorización',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.key),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _validateDeletePassword(dialogContext, value.trim(), transaction, ref);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  _validateDeletePassword(dialogContext, password, transaction, ref);
                } else {
                  EasyLoading.showError('Ingrese la clave');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Eliminar Venta'),
            ),
          ],
        );
      },
    );
  }

  void _validateDeletePassword(BuildContext dialogContext, String password, SaleTransactionModel transaction, WidgetRef ref) async {
    // Validar contraseña con Firebase
    final isValid = await DeletionPasswordService.validatePassword(password);

    if (isValid) {
      // Cerrar el diálogo de autenticación
      Navigator.of(dialogContext).pop();

      // Ejecutar la eliminación después de un pequeño delay
      Future.delayed(Duration(milliseconds: 100), () {
        _performDeleteSale(transaction, ref);
      });
    } else {
      EasyLoading.showError('Clave incorrecta');
    }
  }

  void _performDeleteSale(SaleTransactionModel transaction, WidgetRef ref) async {
    try {
      EasyLoading.show(status: 'Eliminando venta...');
      
      // DEBUG: Log inicial
      debugPrint('🗑️ === INICIO ELIMINACIÓN FACTURA ${transaction.invoiceNumber} ===');
      debugPrint('🗑️ Tipo de venta: ${transaction.saleType}');
      debugPrint('🗑️ Monto total: ${transaction.totalAmount}');
      debugPrint('🗑️ Monto adeudado: ${transaction.dueAmount}');

      // Registrar auditoría ANTES de la eliminación
      await AuditService().logDelete(
        module: AuditModule.sales,
        itemName: 'Venta',
        itemId: transaction.invoiceNumber,
        data: {
          'customerName': transaction.customerName,
          'customerPhone': transaction.customerPhone,
          'totalAmount': transaction.totalAmount,
          'dueAmount': transaction.dueAmount,
          'productCount': transaction.productList?.length ?? 0,
          'paymentMethod': transaction.paymentType,
          'saleDate': transaction.purchaseDate,
        },
      );

      // NUEVO: Registrar eliminación en daily_transactions para tracking
      final apiServiceForDelete = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('subUserTitle') ?? 'Admin';

      try {
        debugPrint('🗑️ [DELETE TRACKING] Registrando eliminación en daily_transactions...');
        debugPrint('🗑️ [DELETE TRACKING] Invoice: ${transaction.invoiceNumber}');
        debugPrint('🗑️ [DELETE TRACKING] Customer: ${transaction.customerName}');
        debugPrint('🗑️ [DELETE TRACKING] DeletedBy: $userName');

        final deleteResponse = await apiServiceForDelete.post('daily-transactions', {
          'type': 'Deleted',
          'name': transaction.customerName ?? 'Cliente',
          'date': DateTime.now().toIso8601String(),
          'total': transaction.totalAmount ?? 0,
          'paymentIn': 0,
          'paymentOut': 0,
          'remainingBalance': 0,
          'paymentType': transaction.paymentType ?? 'N/A',
          'sellerName': userName,
          'invoiceNumber': transaction.invoiceNumber ?? '',
          'data': {
            'deletedBy': userName,
            'deletedAt': DateTime.now().toIso8601String(),
            'originalSaleType': transaction.saleType ?? '',
            'customerPhone': transaction.customerPhone ?? '',
            'productCount': transaction.productList?.length ?? 0,
            // IMPORTANTE: Guardar el modelo completo de la venta para poder generar PDF después
            'saleTransactionModel': transaction.toJson(),
          },
        });

        debugPrint('🗑️ [DELETE TRACKING] Response success: ${deleteResponse.success}');
        debugPrint('🗑️ [DELETE TRACKING] Response data: ${deleteResponse.data}');
        debugPrint('🗑️ [DELETE TRACKING] Response error: ${deleteResponse.error}');

        if (deleteResponse.success) {
          debugPrint('✅ [DELETE TRACKING] Eliminación registrada exitosamente');
        } else {
          debugPrint('⚠️ [DELETE TRACKING] Error en respuesta: ${deleteResponse.error}');
        }
      } catch (e) {
        debugPrint('❌ [DELETE TRACKING] Error registrando eliminación: $e');
      }

      DeleteInvoice delete = DeleteInvoice();
      
      // Paso 1: Restaurar stock
      debugPrint('🗑️ Paso 1: Restaurando stock de productos...');
      await delete.editStockAndSerial(saleTransactionModel: transaction);
      
      // Paso 2: Actualizar adeudo del cliente (restaurar monto TOTAL)
      debugPrint('🗑️ Paso 2: Actualizando adeudo del cliente...');
      debugPrint('🗑️ Monto total a restar: ${transaction.totalAmount}');
      debugPrint('🗑️ Monto pendiente actual: ${transaction.dueAmount}');
      
      // ANÁLISIS: Determinar qué monto restar del cliente
      double currentDue = transaction.dueAmount ?? 0;
      double totalAmount = transaction.totalAmount ?? 0;
      double paidAmount = totalAmount - currentDue;
      
      debugPrint('🗑️ Análisis de adeudo:');
      debugPrint('🗑️ - Total de la factura: $totalAmount');
      debugPrint('🗑️ - Monto ya pagado: $paidAmount');
      debugPrint('🗑️ - Monto pendiente actual: $currentDue');
      debugPrint('🗑️ - Monto a restar del cliente: $currentDue');
      
      // LÓGICA CORRECTA: Solo restar lo que realmente debe el cliente
      await delete.customerDueUpdate(
        due: currentDue,
        phone: transaction.customerPhone,
      );
      
      // Paso 3: Actualizar balance de la tienda
      debugPrint('🗑️ Paso 3: Actualizando balance de la tienda...');
      await delete.updateFromShopRemainBalance(
        paidAmount: (transaction.totalAmount ?? 0) - (transaction.dueAmount ?? 0),
        isFromPurchase: false,
      );
      // Paso 4: Eliminar transacción diaria de venta
      String dailyTransactionType = transaction.saleType == 'adicionales' ? 'Adicionales' : 
                                   transaction.saleType == 'impresiones' ? 'Impresiones' : 'Sale';
      debugPrint('🗑️ Paso 4a: Eliminando daily transaction de venta tipo: $dailyTransactionType');
      
      await delete.deleteDailyTransaction(
        invoice: transaction.invoiceNumber, 
        status: dailyTransactionType, 
        field: "saleTransactionModel"
      );
      
      // Paso 4b: Eliminar todas las transacciones Due Collection relacionadas
      debugPrint('🗑️ Paso 4b: Eliminando TODOS los pagos de cuentas x cobrar relacionados...');
      await delete.deleteAllDueCollections(invoice: transaction.invoiceNumber);
      
      // Paso 4c: Eliminar todos los registros Due Transaction relacionados
      debugPrint('🗑️ Paso 4c: Eliminando TODOS los registros Due Transaction relacionados...');
      await delete.deleteAllDueTransactions(invoice: transaction.invoiceNumber);

      final reservationId = (transaction.reservationIds != null && transaction.reservationIds!.isNotEmpty) 
          ? transaction.reservationIds!.first 
          : '';

      // Paso 5: Cancelar reservación si existe
      if (reservationId.isNotEmpty) {
        debugPrint('🗑️ Paso 5: Cancelando reservación: $reservationId');
        final consuearRef = ProviderScope.containerOf(context);
        await consuearRef.read(cancelReservationProvider(reservationId).future);
      }

      // Paso 6: Eliminar de PostgreSQL via API
      debugPrint('🗑️ Paso 6: Eliminando de Sales Transition...');
      final apiService = ApiService();
      final saleId = transaction.key ?? transaction.invoiceNumber;
      await apiService.delete('sales/$saleId');

      // Paso 7: Refrescar providers
      debugPrint('🗑️ Paso 7: Refrescando providers...');
      final consuearRef = ProviderScope.containerOf(context);
      await consuearRef.refresh(transitionProvider.future);
      await consuearRef.refresh(productProvider.future);
      await consuearRef.refresh(allCustomerProvider.future);
      await consuearRef.refresh(profileDetailsProvider.future);
      await consuearRef.refresh(dailyTransactionProvider.future);
      await consuearRef.refresh(reservationsProvider.future);

      debugPrint('🗑️ === ELIMINACIÓN COMPLETA FACTURA ${transaction.invoiceNumber} ===');
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Venta eliminada exitosamente');
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error al eliminar: ${e.toString()}');
      
      // Registrar error en auditoría
      await AuditService().logAction(
        action: AuditAction.delete,
        module: AuditModule.sales,
        description: 'Error al eliminar venta ${transaction.invoiceNumber}: ${e.toString()}',
      );
    }
  }
}

class Customer {
  final String customerName;
  final String phoneNumber;
  final String invoiceNumber;
  final List<Payment> payments;
  final double totalPaid;
  final double remainingDebt;

  Customer({
    required this.customerName,
    required this.phoneNumber,
    required this.invoiceNumber,
    required this.payments,
    required this.totalPaid,
    required this.remainingDebt,
  });
}

class Payment {
  final String date;
  final double amount;

  Payment({
    required this.date,
    required this.amount,
  });
}