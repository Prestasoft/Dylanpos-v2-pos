import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Firebase Auth deshabilitado - Usando PostgreSQL API
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:salespro_admin/services/api_service.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/user_role_model.dart';

import '../../Provider/user_role_provider.dart';
import '../../Repository/get_user_role_repo.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';
import '../HRM/employees/model/employee_model.dart';
import '../HRM/employees/repo/employee_repo.dart';
import 'add_user_role_screen.dart';
import 'change_deletion_password_dialog.dart';
import 'change_user_password_dialog.dart';
import 'whatsapp_templates_dialog.dart';
import 'whatsapp_credentials_dialog.dart';

class UserRoleScreen extends StatefulWidget {
  const UserRoleScreen({super.key});

  static const String route = '/user_role';

  @override
  State<UserRoleScreen> createState() => _UserRoleScreenState();
}

class _UserRoleScreenState extends State<UserRoleScreen> {
  // Cache de vinculaciones: userId → employeeName
  final Map<String, String> _linkedCache = {};

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  int selectedItem = 10;
  int itemCount = 10;
  final _horizontalScroll = ScrollController();
  int _lossProfitPerPage = 10; // Default number of items to display
  int _currentPage = 1;
  String searchItem = '';
  String selectedBranch = 'all'; // Filtro de sucursal

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
          backgroundColor: kDarkWhite,
          body: Consumer(builder: (_, ref, watch) {
            final customers = ref.watch(userRoleProvider);
            return customers.when(data: (allCustomerList) {
              List<UserRoleModel> customerList = allCustomerList;
              final pages = (customerList.length / _lossProfitPerPage).ceil();

              // Filter the list based on searchItem and selectedBranch
              if (searchItem.isNotEmpty) {
                customerList = customerList.where((user) {
                  return user.userTitle
                              ?.toLowerCase()
                              .contains(searchItem.toLowerCase()) ==
                          true ||
                      user.username
                              ?.toLowerCase()
                              .contains(searchItem.toLowerCase()) ==
                          true ||
                      user.email
                              ?.toLowerCase()
                              .contains(searchItem.toLowerCase()) ==
                          true;
                }).toList();
              }

              // Filter by branch
              if (selectedBranch != 'all') {
                customerList = customerList.where((user) {
                  return user.branchId == selectedBranch;
                }).toList();
              }

              final startIndex = (_currentPage - 1) * _lossProfitPerPage;
              final endIndex = _lossProfitPerPage == -1
                  ? customerList.length
                  : startIndex + _lossProfitPerPage;
              final paginatedList = customerList.sublist(
                startIndex,
                endIndex > customerList.length ? customerList.length : endIndex,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //_______________________________top_bar____________________________
                    // const TopBar(),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: kWhite),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    lang.S.of(context).userRole,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón para configurar credenciales WhatsApp
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return const WhatsAppCredentialsDialog();
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.api, size: 18),
                                      label: const Text('Config. WhatsApp'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue[700],
                                        side: BorderSide(color: Colors.blue[700]!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Botón para plantillas WhatsApp
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return const WhatsAppTemplatesDialog();
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.message, size: 18),
                                      label: const Text('Plantillas WhatsApp'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green[700],
                                        side: BorderSide(color: Colors.green[700]!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Botón para cambiar clave de eliminación
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return const ChangeDeletionPasswordDialog();
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.lock_reset, size: 18),
                                      label: const Text('Cambiar Clave'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange[700],
                                        side: BorderSide(color: Colors.orange[700]!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Botón agregar usuario
                                    ElevatedButton(
                                      onPressed: (() {
                                        showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return StatefulBuilder(
                                                builder: (context, setState1) {
                                              return Dialog(
                                                  insetPadding:
                                                      const EdgeInsets.all(8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(10.0),
                                                  ),
                                                  surfaceTintColor: kWhite,
                                                  child: SizedBox(
                                                    width: 700,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(
                                                          15.0),
                                                      child: AddUserRole(),
                                                    ),
                                                  ));
                                            });
                                          },
                                        );
                                      }),
                                      child: Text(
                                        lang.S.of(context).addNewUser,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          const Divider(
                            thickness: 1.0,
                            color: kNeutral300,
                            height: 1,
                          ),
                          const SizedBox(height: 20.0),

                          ///___________search________________________________________________-
                          ResponsiveGridRow(rowSegments: 100, children: [
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
                                  padding: const EdgeInsets.all(6),
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
                                        'Show-',
                                        style: theme.textTheme.bodyLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DropdownButton<int>(
                                        isDense: true,
                                        padding: EdgeInsets.zero,
                                        underline: const SizedBox(),
                                        value: _lossProfitPerPage,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.black,
                                        ),
                                        items: [10, 20, 50, 100, -1]
                                            .map<DropdownMenuItem<int>>(
                                                (int value) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text(
                                              value == -1
                                                  ? "All"
                                                  : value.toString(),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (int? newValue) {
                                          setState(() {
                                            if (newValue == -1) {
                                              _lossProfitPerPage =
                                                  -1; // Set to -1 for "All"
                                            } else {
                                              _lossProfitPerPage =
                                                  newValue ?? 10;
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
                              md: 40,
                              lg: 25,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextFormField(
                                  showCursor: true,
                                  cursorColor: kTitleColor,
                                  onChanged: (value) {
                                    setState(() {
                                      searchItem = value;
                                    });
                                  },
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(10.0),
                                    hintText: (lang.S.of(context).searchByName),
                                    border: InputBorder.none,
                                    suffixIcon: const Icon(
                                      FeatherIcons.search,
                                      color: kTitleColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveGridCol(
                              xs: 100,
                              md: 20,
                              lg: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: kNeutral300),
                                  ),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    value: selectedBranch,
                                    hint: const Text('Sucursal'),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('Todas las sucursales', style: theme.textTheme.bodyMedium),
                                      ),
                                      DropdownMenuItem(
                                        value: 'stg',
                                        child: Text('Santiago', style: theme.textTheme.bodyMedium),
                                      ),
                                      DropdownMenuItem(
                                        value: 'sde',
                                        child: Text('Santo Domingo Este', style: theme.textTheme.bodyMedium),
                                      ),
                                      DropdownMenuItem(
                                        value: 'sdo',
                                        child: Text('Santo Domingo Oeste', style: theme.textTheme.bodyMedium),
                                      ),
                                      DropdownMenuItem(
                                        value: 'rom',
                                        child: Text('La Romana', style: theme.textTheme.bodyMedium),
                                      ),
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedBranch = newValue ?? 'all';
                                        _currentPage = 1;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ]),
                          customerList.isNotEmpty
                              ? Column(
                                  children: [
                                    Column(
                                      children: [
                                        LayoutBuilder(
                                          builder: (BuildContext context,
                                              BoxConstraints constraints) {
                                            return Scrollbar(
                                              controller: _horizontalScroll,
                                              thumbVisibility: true,
                                              radius: const Radius.circular(8),
                                              thickness: 8,
                                              child: SingleChildScrollView(
                                                controller: _horizontalScroll,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minWidth:
                                                        constraints.maxWidth,
                                                  ),
                                                  child: Theme(
                                                    data: theme.copyWith(
                                                      dividerColor:
                                                          Colors.transparent,
                                                      dividerTheme:
                                                          const DividerThemeData(
                                                              color: Colors
                                                                  .transparent),
                                                    ),
                                                    child: DataTable(
                                                        border:
                                                            const TableBorder(
                                                          horizontalInside:
                                                              BorderSide(
                                                            width: 1,
                                                            color: kNeutral300,
                                                          ),
                                                        ),
                                                        dataRowColor:
                                                            const WidgetStatePropertyAll(
                                                                Colors.white),
                                                        headingRowColor:
                                                            WidgetStateProperty
                                                                .all(const Color(
                                                                    0xFFF8F3FF)),
                                                        showBottomBorder: false,
                                                        dividerThickness: 0.0,
                                                        headingTextStyle: theme
                                                            .textTheme
                                                            .titleMedium,
                                                        columns: [
                                                          DataColumn(
                                                              label: Text(lang.S
                                                                  .of(context)
                                                                  .SL)),
                                                          DataColumn(
                                                              label: Text(lang.S
                                                                  .of(context)
                                                                  .userName)),
                                                          DataColumn(
                                                              label: Text(lang.S
                                                                  .of(context)
                                                                  .userRole)),
                                                          DataColumn(
                                                              label: Text(lang.S
                                                                  .of(context)
                                                                  .email)),
                                                          const DataColumn(
                                                              label: Text('Sucursal')),
                                                          DataColumn(
                                                              label: Text(lang.S
                                                                  .of(context)
                                                                  .action)),
                                                        ],
                                                        rows: List.generate(
                                                            paginatedList
                                                                .length,
                                                            (index) {
                                                          return DataRow(
                                                              cells: [
                                                                ///______________S.L__________________________________________________
                                                                DataCell(Text(
                                                                    "${startIndex + index + 1}")),

                                                                ///______________Username__________________________________________________
                                                                DataCell(
                                                                  Text(
                                                                    paginatedList[index]
                                                                            .username ??
                                                                        '',
                                                                  ),
                                                                ),

                                                                DataCell(
                                                                  Text(
                                                                    paginatedList[index]
                                                                            .userRoleName ??
                                                                        '',
                                                                  ),
                                                                ),

                                                                ///____________Email_________________________________________________
                                                                DataCell(
                                                                  Text(
                                                                    paginatedList[index]
                                                                            .email ??
                                                                        '',
                                                                  ),
                                                                ),

                                                                ///____________Sucursal_________________________________________________
                                                                DataCell(
                                                                  Text(
                                                                    paginatedList[index]
                                                                            .branchName ??
                                                                        '',
                                                                  ),
                                                                ),

                                                                ///______Actions___________________________________________________________
                                                                DataCell(
                                                                  Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      // Botón de editar (oculto para usuarios protegidos)
                                                                      if (!isProtectedUser(paginatedList[index].databaseId, paginatedList[index].email))
                                                                        IconButton(
                                                                          onPressed: () {
                                                                            showDialog(
                                                                              barrierDismissible: false,
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return StatefulBuilder(builder: (context, setState1) {
                                                                                  return Dialog(
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(10.0),
                                                                                      ),
                                                                                      child: SizedBox(
                                                                                        width: 700,
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.all(10.0),
                                                                                          child: AddUserRole(
                                                                                            userRoleModel: paginatedList[index],
                                                                                          ),
                                                                                        ),
                                                                                      ));
                                                                                });
                                                                              },
                                                                            );
                                                                          },
                                                                          icon: const Icon(
                                                                            FeatherIcons.edit,
                                                                            color: kMainColor,
                                                                            size: 18,
                                                                          ),
                                                                          tooltip: 'Editar usuario',
                                                                        ),
                                                                      // Indicador de usuario protegido
                                                                      if (isProtectedUser(paginatedList[index].databaseId, paginatedList[index].email))
                                                                        Tooltip(
                                                                          message: 'Usuario Super Admin protegido',
                                                                          child: Icon(
                                                                            Icons.shield,
                                                                            color: Colors.green[700],
                                                                            size: 20,
                                                                          ),
                                                                        ),
                                                                      const SizedBox(width: 4),
                                                                      // Botón de eliminar (oculto para usuarios protegidos)
                                                                      if (!isProtectedUser(paginatedList[index].databaseId, paginatedList[index].email))
                                                                        IconButton(
                                                                          onPressed: () async {
                                                                            await _showDeleteConfirmation(
                                                                              context,
                                                                              paginatedList[index],
                                                                              ref
                                                                            );
                                                                          },
                                                                          icon: const Icon(
                                                                            FeatherIcons.trash2,
                                                                            color: Colors.red,
                                                                            size: 18,
                                                                          ),
                                                                          tooltip: 'Eliminar usuario',
                                                                        ),
                                                                      const SizedBox(width: 4),
                                                                      // Botón de vincular empleado
                                                                      if (!isProtectedUser(paginatedList[index].databaseId, paginatedList[index].email))
                                                                        Builder(builder: (_) {
                                                                          final uid = paginatedList[index].userKey ?? paginatedList[index].databaseId ?? '';
                                                                          final linkedName = _linkedCache[uid];
                                                                          final isLinked = linkedName != null;
                                                                          return Tooltip(
                                                                            message: isLinked ? 'Vinculado: $linkedName' : 'Vincular con empleado',
                                                                            child: InkWell(
                                                                              borderRadius: BorderRadius.circular(20),
                                                                              onTap: () => _showLinkEmployeeDialog(context, paginatedList[index], ref),
                                                                              child: Container(
                                                                                padding: const EdgeInsets.all(6),
                                                                                decoration: BoxDecoration(
                                                                                  color: isLinked ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.08),
                                                                                  shape: BoxShape.circle,
                                                                                  border: Border.all(
                                                                                    color: isLinked ? Colors.green.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3),
                                                                                  ),
                                                                                ),
                                                                                child: Icon(
                                                                                  isLinked ? Icons.check : Icons.link,
                                                                                  color: isLinked ? Colors.green : Colors.grey,
                                                                                  size: 16,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }),
                                                                      const SizedBox(width: 4),
                                                                      // Botón de cambiar contraseña
                                                                      IconButton(
                                                                        onPressed: () {
                                                                          final user = paginatedList[index];
                                                                          showDialog(
                                                                            context: context,
                                                                            builder: (BuildContext context) {
                                                                              return ChangeUserPasswordDialog(
                                                                                userId: user.databaseId ?? '',
                                                                                userName: user.username ?? user.userTitle ?? 'Usuario',
                                                                                userEmail: user.email ?? '',
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        icon: Icon(
                                                                          Icons.key,
                                                                          color: Colors.orange[700],
                                                                          size: 18,
                                                                        ),
                                                                        tooltip: 'Cambiar contraseña',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ]);
                                                        })),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${lang.S.of(context).showing} ${((_currentPage - 1) * _lossProfitPerPage + 1).toString()} to ${((_currentPage - 1) * _lossProfitPerPage + _lossProfitPerPage).clamp(0, customerList.length)} of ${customerList.length} entries',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  InkWell(
                                                    overlayColor:
                                                        WidgetStateProperty.all<
                                                            Color>(Colors.grey),
                                                    hoverColor: Colors.grey,
                                                    onTap: _currentPage > 1
                                                        ? () => setState(() =>
                                                            _currentPage--)
                                                        : null,
                                                    child: Container(
                                                      height: 32,
                                                      width: 90,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                                kBorderColorTextField),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  4.0),
                                                          topLeft:
                                                              Radius.circular(
                                                                  4.0),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(lang.S
                                                            .of(context)
                                                            .previous),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 32,
                                                    width: 32,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      color: kMainColor,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '$_currentPage',
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 32,
                                                    width: 32,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              kBorderColorTextField),
                                                      color: Colors.transparent,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '$pages',
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    hoverColor: Colors.blue
                                                        .withValues(alpha: 0.1),
                                                    overlayColor:
                                                        WidgetStateProperty.all<
                                                            Color>(Colors.blue),
                                                    onTap: _currentPage *
                                                                _lossProfitPerPage <
                                                            customerList.length
                                                        ? () => setState(() =>
                                                            _currentPage++)
                                                        : null,
                                                    child: Container(
                                                      height: 32,
                                                      width: 90,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                                kBorderColorTextField),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                          bottomRight:
                                                              Radius.circular(
                                                                  4.0),
                                                          topRight:
                                                              Radius.circular(
                                                                  4.0),
                                                        ),
                                                      ),
                                                      child: const Center(
                                                          child: Text('Next')),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : noDataFoundImage(
                                  text: lang.S.of(context).noUserFound),
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
            });
          })),
    );
  }

  // Método para mostrar confirmación de eliminación
  /// Modal rápido para vincular un usuario con su perfil de empleado
  Future<void> _showLinkEmployeeDialog(BuildContext context, UserRoleModel user, WidgetRef ref) async {
    final userId = user.userKey ?? user.databaseId ?? '';
    if (userId.isEmpty) return;

    // Cargar empleados
    final employees = await EmployeeRepository().getActiveEmployees();
    if (!mounted) return;

    // Cargar linked_employee_id actual
    String? currentLinkedId;
    try {
      final resp = await ApiService().get('users/$userId');
      if (resp.success && resp.data != null) {
        final u = resp.data['user'] ?? resp.data;
        final linked = u['linked_employee_id']?.toString();
        if (linked != null && linked.isNotEmpty && linked != 'null') {
          currentLinkedId = linked;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    // Resolver nombre actual y actualizar cache
    String? currentName;
    if (currentLinkedId != null) {
      final match = employees.where((e) => e.id.toString() == currentLinkedId).firstOrNull;
      if (match != null) {
        currentName = '${match.name} ${match.lastName}'.trim();
        _linkedCache[userId] = currentName;
      }
    } else {
      _linkedCache.remove(userId);
    }
    if (mounted) setState(() {});

    final selected = await showDialog<EmployeeModel>(
      context: context,
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = search.isEmpty
                ? employees
                : employees.where((e) => '${e.name} ${e.lastName}'.toLowerCase().contains(search.toLowerCase())).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text('Vincular Empleado', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Usuario: ${user.userTitle ?? user.email ?? ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
                  if (currentName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Vinculado a: $currentName',
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setDialogState(() => search = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar empleado...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text('No se encontraron empleados', style: TextStyle(color: Colors.grey.shade500)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final emp = filtered[i];
                                final isLinked = emp.id.toString() == currentLinkedId;
                                return ListTile(
                                  dense: true,
                                  selected: isLinked,
                                  selectedTileColor: Colors.deepPurple.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isLinked ? Colors.green.withValues(alpha: 0.15) : Colors.deepPurple.withValues(alpha: 0.1),
                                    child: Text(emp.name.isNotEmpty ? emp.name[0] : '?',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                            color: isLinked ? Colors.green : Colors.deepPurple)),
                                  ),
                                  title: Text('${emp.name} ${emp.lastName}',
                                      style: TextStyle(fontSize: 13, fontWeight: isLinked ? FontWeight.w700 : FontWeight.w400)),
                                  subtitle: Text('${emp.designation} · ${emp.department}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  trailing: isLinked ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : null,
                                  onTap: () => Navigator.pop(ctx, emp),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (currentLinkedId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.link_off, size: 16, color: Colors.red),
                    label: const Text('Desvincular', style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      try {
                        await ApiService().put('users/$userId', {'linked_employee_id': null});
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() => _linkedCache.remove(userId));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Usuario desvinculado'), backgroundColor: Colors.orange));
                        }
                      } catch (_) {}
                    },
                  ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ],
            );
          },
        );
      },
    );

    if (selected == null) return;

    // Guardar vinculación
    try {
      final resp = await ApiService().put('users/$userId', {
        'linked_employee_id': selected.id.toString(),
      });

      if (resp.success && mounted) {
        setState(() {
          _linkedCache[userId] = '${selected.name} ${selected.lastName}'.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Vinculado a ${selected.name} ${selected.lastName}'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, UserRoleModel user, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirmar eliminación'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar el usuario?'),
                const SizedBox(height: 8),
                Text('Usuario: ${user.userTitle ?? "Sin título"}'),
                Text('Email: ${user.email ?? "Sin email"}'),
                Text('Rol: ${user.userRoleName ?? "Sin rol"}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Nota: Esta acción eliminará permanentemente el usuario y todos sus datos asociados de la base de datos.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteUser(context, user, ref);
              },
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar usuario
  Future<void> _deleteUser(BuildContext context, UserRoleModel user, WidgetRef ref) async {
    // PROTECCIÓN: Verificar si es un usuario Super Admin protegido
    if (isProtectedUser(user.databaseId, user.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este usuario es Super Admin y no puede ser eliminado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('Eliminando usuario...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final repo = UserRoleRepo();
      
      // Verificar si el usuario puede ser eliminado
      bool canDelete = await repo.canDeleteUser(user);
      if (!canDelete) {
        String errorMessage = 'No se puede eliminar este usuario';
        
        // Personalizar mensaje según el motivo
        // Firebase Auth deshabilitado - Usar ApiService para verificar usuario actual
        final currentUserEmail = ApiService().currentUser?['email'];
        if (user.email == currentUserEmail) {
          errorMessage = 'No puedes eliminar tu propia cuenta';
        } else if (user.email == null || user.email!.isEmpty) {
          errorMessage = 'No se puede eliminar un usuario sin email';
        }
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // Usar directamente el userKey del objeto usuario
      String userKey = user.userKey ?? user.databaseId ?? '';

      if (userKey.isEmpty) {
        debugPrint('Error: userKey está vacío para el usuario ${user.email}');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se puede identificar el usuario'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('Eliminando usuario con ID: $userKey, email: ${user.email}');

      // Eliminar el usuario
      bool success = await repo.deleteUserRole(userKey, '', user.email ?? '');
      
      if (success) {
        // Refrescar la lista
        ref.invalidate(userRoleProvider);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario ${user.userTitle ?? user.email} eliminado exitosamente'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al eliminar el usuario'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
