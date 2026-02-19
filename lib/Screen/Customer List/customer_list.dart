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
  void deleteCustomer({
    required String phoneNumber,
    required WidgetRef updateRef,
    required BuildContext context,
  }) async {
    EasyLoading.show(status: 'Eliminando..');

    try {
      final apiService = ApiService();
      final searchResponse = await apiService.get('customers', queryParams: {
        'phoneNumber': phoneNumber,
        'limit': '1',
      });

      if (searchResponse.success && searchResponse.data != null) {
        final customers =
            searchResponse.data['customers'] as List<dynamic>? ?? [];
        if (customers.isNotEmpty) {
          final customerData = Map<String, dynamic>.from(customers.first);
          final customerId = customerData['id']?.toString();

          if (customerId != null) {
            await apiService.delete('customers/$customerId');
          }
        }
      }

      // ignore: unused_result
      updateRef.refresh(allCustomerProvider);
      EasyLoading.showSuccess('Realizado');
    } catch (e) {
      EasyLoading.showError('Error al eliminar');
    }
  }

  ScrollController mainScroll = ScrollController();

  // ✅ SOLUCIÓN PROFESIONAL: TextField completamente independiente
  // El controller y ValueNotifier están separados del árbol de widgets de la tabla
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

  /// ✅ Método para manejar el debounce de búsqueda
  /// IMPORTANTE: NO llama setState - solo actualiza el ValueNotifier
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
              // ═══════════════════════════════════════════════════════════
              // SECCIÓN FIJA: Header (NUNCA se reconstruye)
              // ═══════════════════════════════════════════════════════════
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
                    // Consumer mínimo solo para obtener la lista de teléfonos
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

              // ═══════════════════════════════════════════════════════════
              // CAMPO DE BÚSQUEDA - COMPLETAMENTE INDEPENDIENTE
              // Este TextField NUNCA se reconstruye cuando cambian los resultados
              // ═══════════════════════════════════════════════════════════
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
                      // ✅ TextField FUERA del ValueListenableBuilder
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

              // ═══════════════════════════════════════════════════════════
              // TABLA DE CLIENTES - Solo esta parte se reconstruye
              // ═══════════════════════════════════════════════════════════
              const SizedBox(height: 20.0),

              // ValueListenableBuilder SOLO envuelve la tabla
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

  /// Widget separado para la tabla de clientes
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
                            // N°
                            DataCell(
                              Text('${startIndex + index + 1}'),
                            ),
                            // Imagen
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
                            // Nombre
                            DataCell(
                              Text(paginatedList[index].customerName),
                            ),
                            // Tipo
                            DataCell(
                              Text(paginatedList[index].type),
                            ),
                            // Teléfono
                            DataCell(
                              Text(paginatedList[index].phoneNumber),
                            ),
                            // Due/Pendiente
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
                            // Acciones
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
                                      // Ver Perfil
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
                                      // Editar
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
                                      // Eliminar
                                      PopupMenuItem(
                                        onTap: () {
                                          if (double.parse(paginatedList[index]
                                                  .dueAmount
                                                  .toString()) ==
                                              0) {
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder:
                                                  (BuildContext dialogContext) {
                                                return Center(
                                                  child: Container(
                                                    width: 500,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(15),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            lang.S
                                                                .of(context)
                                                                .areYouWantToDeleteThisCustomer,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: theme
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 20),
                                                          ResponsiveGridRow(
                                                            children: [
                                                              ResponsiveGridCol(
                                                                xs: 12,
                                                                md: 6,
                                                                lg: 6,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                  child:
                                                                      OutlinedButton(
                                                                    onPressed:
                                                                        () {
                                                                      context
                                                                          .pop();
                                                                    },
                                                                    child: Text(
                                                                      lang.S
                                                                          .of(context)
                                                                          .cancel,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              ResponsiveGridCol(
                                                                xs: 12,
                                                                md: 6,
                                                                lg: 6,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      if (!checkUserRoleDeletePermissionV2(
                                                                          type:
                                                                              'customers')) {
                                                                        EasyLoading
                                                                            .showError(userPermissionErrorText);
                                                                        return;
                                                                      }
                                                                      if (!isDemo) {
                                                                        deleteCustomer(
                                                                          phoneNumber:
                                                                              paginatedList[index].phoneNumber,
                                                                          updateRef:
                                                                              ref,
                                                                          context:
                                                                              bc,
                                                                        );
                                                                        context
                                                                            .pop();
                                                                      } else {
                                                                        EasyLoading
                                                                            .showInfo(demoText);
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                      lang.S
                                                                          .of(context)
                                                                          .delete,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            EasyLoading.showError(
                                              lang.S
                                                  .of(context)
                                                  .thisCustomerHavepreviousDue,
                                            );
                                            context.pop();
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_outline,
                                              color: kNeutral500,
                                              size: 20.0,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              lang.S.of(context).delete,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                color: kNeutral500,
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
        // Paginación
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
