import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/customer_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../Provider/customer_provider.dart';
import '../../const.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  static const String route = '/customerList';

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  /// Verifica las dependencias del cliente y muestra modal de confirmación
  Future<void> _showDeleteConfirmation({
    required CustomerModel customer,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    if (!checkUserRoleDeletePermissionV2(type: 'customers')) {
      EasyLoading.showError(userPermissionErrorText);
      return;
    }

    EasyLoading.show(status: 'Verificando...');

    try {
      final apiService = ApiService();
      final response = await apiService.get('customers/${customer.id}/dependencies');

      EasyLoading.dismiss();

      if (!response.success || response.data == null) {
        EasyLoading.showError('Error al verificar dependencias');
        return;
      }

      final dependencies = response.data;
      final hasDependencies = dependencies['hasDependencies'] ?? false;
      final sales = dependencies['sales'] ?? {};
      final dueTransactions = dependencies['dueTransactions'] ?? {};
      final reservations = dependencies['reservations'] ?? {};

      if (!context.mounted) return;

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dialogContext) {
          return _DeleteConfirmationDialog(
            customer: customer,
            hasDependencies: hasDependencies,
            salesCount: sales['count'] ?? 0,
            salesTotal: (sales['total'] ?? 0).toDouble(),
            salesPending: (sales['pending'] ?? 0).toDouble(),
            dueTransactionsCount: dueTransactions['count'] ?? 0,
            dueTransactionsTotal: (dueTransactions['total'] ?? 0).toDouble(),
            reservationsCount: reservations['count'] ?? 0,
            onConfirm: (bool cascade) async {
              Navigator.of(dialogContext).pop();
              await _executeDelete(
                customerId: customer.id ?? '',
                cascade: cascade,
                ref: ref,
              );
            },
            onCancel: () {
              Navigator.of(dialogContext).pop();
            },
          );
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: $e');
    }
  }

  /// Ejecuta la eliminación del cliente
  Future<void> _executeDelete({
    required String customerId,
    required bool cascade,
    required WidgetRef ref,
  }) async {
    EasyLoading.show(status: 'Eliminando...');

    try {
      final apiService = ApiService();
      // Construir URL con query param si es cascada
      final endpoint = cascade
          ? 'customers/$customerId?cascade=true'
          : 'customers/$customerId';
      final response = await apiService.delete(endpoint);

      if (response.success) {
        // ignore: unused_result
        ref.refresh(allCustomerProvider);

        final deletedRecords = response.data?['deletedRecords'];
        if (cascade && deletedRecords != null) {
          final salesDeleted = deletedRecords['sales'] ?? 0;
          final dueDeleted = deletedRecords['dueTransactions'] ?? 0;
          final reservationsDeleted = deletedRecords['reservations'] ?? 0;

          EasyLoading.showSuccess(
            'Eliminado: $salesDeleted facturas, $dueDeleted pagos, $reservationsDeleted reservas',
            duration: const Duration(seconds: 3),
          );
        } else {
          EasyLoading.showSuccess('Cliente eliminado');
        }
      } else {
        EasyLoading.showError('Error al eliminar');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  ScrollController mainScroll = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    mainScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchQueryNotifier.value != value) {
        _searchQueryNotifier.value = value;
        _currentPage = 1;
      }
    });
  }

  final _horizontalScroll = ScrollController();
  int _customerPerPage = 10;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: kWhite,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        lang.S.of(context).customerList,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Consumer(
                      builder: (_, ref, __) {
                        final customersAsync = ref.watch(allCustomerProvider);
                        final listOfPhoneNumber = customersAsync.whenOrNull(
                              data: (list) => list
                                  .map((c) => c.phoneNumber
                                      .replaceAll(RegExp(r'\s+'), '')
                                      .toLowerCase())
                                  .toList(),
                            ) ??
                            [];

                        return ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(),
                          onPressed: () async {
                            if (!checkUserRoleEditPermissionV2(
                                type: 'customers')) {
                              EasyLoading.showError(userPermissionErrorText);
                              return;
                            }
                            if (await Subscription.subscriptionChecker(
                                item: "Parties")) {
                              context.push(
                                '/add-customer',
                                extra: {
                                  'typeOfCustomerAdd': 'Buyer',
                                  'listOfPhoneNumber': listOfPhoneNumber,
                                },
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          label: Text(
                            lang.S.of(context).addCustomer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                            Flexible(
                              child: Text(
                                'Ver-',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            DropdownButton<int>(
                              isDense: true,
                              padding: EdgeInsets.zero,
                              underline: const SizedBox(),
                              value: _customerPerPage,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black,
                              ),
                              items: [10, 20, 50, 100, -1]
                                  .map<DropdownMenuItem<int>>((int value) {
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
                                  if (newValue == -1) {
                                    _customerPerPage = -1;
                                  } else {
                                    _customerPerPage = newValue ?? 10;
                                  }
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xs: 100,
                    md: 60,
                    lg: 35,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextFormField(
                        controller: _searchController,
                        showCursor: true,
                        cursorColor: kTitleColor,
                        onChanged: _onSearchChanged,
                        keyboardType: TextInputType.name,
                        decoration: kInputDecoration.copyWith(
                          contentPadding: const EdgeInsets.all(10.0),
                          hintText: lang.S.of(context).searchByNameOrPhone,
                          suffixIcon: const Icon(
                            FeatherIcons.search,
                            color: kNeutral400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ValueListenableBuilder<String>(
                valueListenable: _searchQueryNotifier,
                builder: (context, searchQuery, _) {
                  return Consumer(
                    builder: (_, ref, __) {
                      AsyncValue<List<CustomerModel>> customers =
                          ref.watch(searchCustomerProvider(searchQuery));

                      return customers.when(
                        data: (list) {
                          List<CustomerModel> allCustomerList = list;
                          List<CustomerModel> showAbleCustomer = [];

                          for (var value1 in allCustomerList) {
                            if (value1.type != 'Supplier') {
                              showAbleCustomer.add(value1);
                            }
                          }

                          if (showAbleCustomer.isEmpty) {
                            return EmptyWidget(
                                title: lang.S.of(context).noCustomerFound);
                          }

                          final totalPages =
                              (showAbleCustomer.length / _customerPerPage)
                                  .ceil();

                          final startIndex =
                              ((_currentPage - 1) * _customerPerPage);
                          final endIndex = startIndex + _customerPerPage;
                          final paginatedList = showAbleCustomer.sublist(
                            startIndex,
                            endIndex > showAbleCustomer.length
                                ? showAbleCustomer.length
                                : endIndex,
                          );

                          return _buildCustomerTable(
                            context: context,
                            theme: theme,
                            globalCurrency: globalCurrency,
                            showAbleCustomer: showAbleCustomer,
                            paginatedList: paginatedList,
                            allCustomerList: allCustomerList,
                            totalPages: totalPages,
                            startIndex: startIndex,
                            ref: ref,
                          );
                        },
                        error: (e, stack) {
                          return Center(
                            child: Text(e.toString()),
                          );
                        },
                        loading: () {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerTable({
    required BuildContext context,
    required ThemeData theme,
    required String globalCurrency,
    required List<CustomerModel> showAbleCustomer,
    required List<CustomerModel> paginatedList,
    required List<CustomerModel> allCustomerList,
    required int totalPages,
    required int startIndex,
    required WidgetRef ref,
  }) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final kWidth = constraints.maxWidth;
            return Scrollbar(
              controller: _horizontalScroll,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              thickness: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScroll,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: kWidth,
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      dividerColor: Colors.transparent,
                      dividerTheme: const DividerThemeData(
                        color: Colors.transparent,
                      ),
                    ),
                    child: DataTable(
                      border: const TableBorder(
                        horizontalInside: BorderSide(
                          width: 1,
                          color: kNeutral300,
                        ),
                      ),
                      dataRowColor:
                          const WidgetStatePropertyAll(Colors.white),
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                      showBottomBorder: false,
                      dividerThickness: 0.0,
                      headingTextStyle: theme.textTheme.titleMedium,
                      dataTextStyle: theme.textTheme.bodyLarge,
                      columns: [
                        const DataColumn(label: Text('N°')),
                        DataColumn(label: Text(lang.S.of(context).image)),
                        DataColumn(label: Text(lang.S.of(context).name)),
                        DataColumn(label: Text(lang.S.of(context).paymentType)),
                        DataColumn(label: Text(lang.S.of(context).phone)),
                        DataColumn(label: Text(lang.S.of(context).due)),
                        DataColumn(label: Text(lang.S.of(context).setting)),
                      ],
                      rows: List.generate(paginatedList.length, (index) {
                        final dataIndex =
                            (_currentPage - 1) * _customerPerPage + index;
                        final customer = showAbleCustomer[dataIndex];
                        return DataRow(
                          cells: [
                            DataCell(
                              Text('${startIndex + index + 1}'),
                            ),
                            DataCell(
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kNeutral100,
                                ),
                                child: ClipOval(
                                  child: customer.profilePicture.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: customer.profilePicture,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const CircularProgressIndicator(
                                                  strokeWidth: 2),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.person,
                                                  size: 20),
                                        )
                                      : const Icon(Icons.person, size: 20),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(paginatedList[index].customerName),
                            ),
                            DataCell(
                              Text(paginatedList[index].type),
                            ),
                            DataCell(
                              Text(paginatedList[index].phoneNumber),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (double.tryParse(
                                                  paginatedList[index]
                                                      .dueAmount) ??
                                              0) ==
                                          0
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$globalCurrency${myFormat.format(double.tryParse(paginatedList[index].dueAmount) ?? 0)}",
                                  style: TextStyle(
                                    color: (double.tryParse(paginatedList[index]
                                                    .dueAmount) ??
                                                0) ==
                                            0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 30,
                                child: Theme(
                                  data: ThemeData(
                                    highlightColor: dropdownItemColor,
                                    focusColor: dropdownItemColor,
                                    hoverColor: dropdownItemColor,
                                  ),
                                  child: PopupMenuButton(
                                    surfaceTintColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    itemBuilder: (BuildContext bc) => [
                                      PopupMenuItem(
                                        onTap: () {
                                          final customerModel =
                                              paginatedList[index];
                                          context.push(
                                            '/customer-profile/${customerModel.id}',
                                            extra: {
                                              'customerName':
                                                  customerModel.customerName,
                                            },
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              IconlyLight.profile,
                                              size: 20.0,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              'Ver Perfil',
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          final customerModel =
                                              paginatedList[index];
                                          final allPreviousCustomer =
                                              allCustomerList;
                                          const typeOfCustomerAdd = 'Buyer';

                                          context.push(
                                            '/edit-customer',
                                            extra: {
                                              'customerModel': customerModel,
                                              'allPreviousCustomer':
                                                  allPreviousCustomer,
                                              'typeOfCustomerAdd':
                                                  typeOfCustomerAdd,
                                            },
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              IconlyLight.edit,
                                              size: 20.0,
                                              color: kNeutral500,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              lang.S.of(context).edit,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                color: kNeutral500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Solo mostrar opción de eliminar para administradores
                                      if (!isSubUser)
                                        PopupMenuItem(
                                          onTap: () {
                                            // Usar el nuevo método de confirmación
                                            _showDeleteConfirmation(
                                              customer: paginatedList[index],
                                              ref: ref,
                                              context: context,
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20.0,
                                              ),
                                              const SizedBox(width: 4.0),
                                              Text(
                                                lang.S.of(context).delete,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                    onSelected: (value) {
                                      context.go('$value');
                                    },
                                    child: Center(
                                      child: Container(
                                        height: 18,
                                        width: 18,
                                        alignment: Alignment.centerRight,
                                        child: const Icon(
                                          Icons.more_vert_sharp,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Ver ${((_currentPage - 1) * _customerPerPage + 1).toString()} a ${((_currentPage - 1) * _customerPerPage + _customerPerPage).clamp(0, showAbleCustomer.length)} de ${showAbleCustomer.length} registros',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    overlayColor: WidgetStateProperty.all<Color>(Colors.grey),
                    hoverColor: Colors.grey,
                    onTap: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                    child: Container(
                      height: 32,
                      width: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderColorTextField),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4.0),
                          topLeft: Radius.circular(4.0),
                        ),
                      ),
                      child: const Center(
                        child: Text('Anterior'),
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorderColorTextField),
                      color: kMainColor,
                    ),
                    child: Center(
                      child: Text(
                        '$_currentPage',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorderColorTextField),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text('$totalPages'),
                    ),
                  ),
                  InkWell(
                    hoverColor: Colors.blue.withValues(alpha: 0.1),
                    overlayColor: WidgetStateProperty.all<Color>(Colors.blue),
                    onTap: _currentPage * _customerPerPage <
                            showAbleCustomer.length
                        ? () => setState(() => _currentPage++)
                        : null,
                    child: Container(
                      height: 32,
                      width: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderColorTextField),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      child: const Center(
                        child: Text('Siguiente'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal de confirmación para eliminar cliente
class _DeleteConfirmationDialog extends StatelessWidget {
  final CustomerModel customer;
  final bool hasDependencies;
  final int salesCount;
  final double salesTotal;
  final double salesPending;
  final int dueTransactionsCount;
  final double dueTransactionsTotal;
  final int reservationsCount;
  final Function(bool cascade) onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.customer,
    required this.hasDependencies,
    required this.salesCount,
    required this.salesTotal,
    required this.salesPending,
    required this.dueTransactionsCount,
    required this.dueTransactionsTotal,
    required this.reservationsCount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de advertencia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasDependencies
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasDependencies ? Icons.warning_amber_rounded : Icons.delete_outline,
                color: hasDependencies ? Colors.orange : Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              hasDependencies
                  ? 'Cliente con registros asociados'
                  : 'Eliminar cliente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Nombre del cliente
            Text(
              customer.customerName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: kMainColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Información de dependencias
            if (hasDependencies) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Este cliente tiene los siguientes registros:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (salesCount > 0)
                      _buildDependencyRow(
                        icon: Icons.receipt_long,
                        label: 'Facturas',
                        count: salesCount,
                        amount: salesTotal,
                        pending: salesPending,
                      ),
                    if (dueTransactionsCount > 0)
                      _buildDependencyRow(
                        icon: Icons.payments,
                        label: 'Pagos registrados',
                        count: dueTransactionsCount,
                        amount: dueTransactionsTotal,
                      ),
                    if (reservationsCount > 0)
                      _buildDependencyRow(
                        icon: Icons.calendar_month,
                        label: 'Reservaciones',
                        count: reservationsCount,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Desea eliminar el cliente y TODOS sus registros asociados?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                '¿Está seguro que desea eliminar este cliente?',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onConfirm(hasDependencies),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      hasDependencies ? 'Eliminar Todo' : 'Eliminar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependencyRow({
    required IconData icon,
    required String label,
    required int count,
    double? amount,
    double? pending,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kNeutral500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (amount != null && amount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '(RD\$${myFormat.format(amount)})',
              style: TextStyle(
                color: kNeutral500,
                fontSize: 12,
              ),
            ),
          ],
          if (pending != null && pending > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pendiente: RD\$${myFormat.format(pending)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}