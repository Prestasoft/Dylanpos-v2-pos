// ignore_for_file: unused_result

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/user_role_provider.dart';
import '../../Repository/get_user_role_repo.dart';
import '../../const.dart';
import '../../model/user_role_model.dart';
import '../Widgets/Constant Data/constant.dart';

class AddUserRole extends StatefulWidget {
  AddUserRole({Key? key, this.userRoleModel}) : super(key: key);
  final UserRoleModel? userRoleModel;

  @override
  // ignore: library_private_types_in_public_api
  _AddUserRoleState createState() => _AddUserRoleState();
}

class _AddUserRoleState extends State<AddUserRole> {
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }


  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController userRoleName = TextEditingController();
  List<Permission> defaultPermissions = [
    // ===== NAVEGACIÓN PRINCIPAL =====
    Permission(type: 'dashboard'),
    Permission(type: 'inicio'),
    Permission(type: 'tablero'),
    
    // ===== SERVICIOS Y PAQUETES =====
    Permission(type: 'services'),
    Permission(type: 'register_package'),
    Permission(type: 'register_clothing'),
    
    // ===== RESERVAS =====
    Permission(type: 'reservations'),
    Permission(type: 'reservation_calendar'),
    Permission(type: 'rent_clothing'),
    Permission(type: 'reserve_package'),
    
    // ===== VENTAS =====
    Permission(type: 'sales'),
    Permission(type: 'pos_sales'),
    Permission(type: 'inventory_sales'),
    Permission(type: 'sales_list'),
    Permission(type: 'sales_return'),
    Permission(type: 'quotation_list'),
    
    // ===== COMPRAS =====
    Permission(type: 'purchases'),
    Permission(type: 'pos_purchase'),
    Permission(type: 'purchase_list'),
    Permission(type: 'purchase_return'),
    
    // ===== INVENTARIO =====
    Permission(type: 'products'),
    Permission(type: 'categories'),
    Permission(type: 'warehouses'),
    Permission(type: 'inventory_list'),
    Permission(type: 'inventory_equipment'),
    
    // ===== CONTACTOS =====
    Permission(type: 'customers'),
    Permission(type: 'suppliers'),
    
    // ===== CONFIRMACIONES =====
    Permission(type: 'confirmations'),
    
    // ===== FINANZAS =====
    Permission(type: 'expense'),
    Permission(type: 'income'),
    Permission(type: 'transaction'),
    Permission(type: 'dues'),
    Permission(type: 'ledger'),
    Permission(type: 'loss_profit'),
    
    // ===== REPORTES =====
    Permission(type: 'reports'),
    
    // ===== RECURSOS HUMANOS =====
    Permission(type: 'hrm'),
    Permission(type: 'employees'),
    Permission(type: 'designations'),
    Permission(type: 'salary_list'),
    
    // ===== CONFIGURACIÓN =====
    Permission(type: 'user_roles'),
    Permission(type: 'tax_rates'),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    if (widget.userRoleModel != null) {
      setEditData();
    }
  }

  setEditData() {
    emailController.text = widget.userRoleModel?.email ?? '';
    titleController.text = widget.userRoleModel?.userTitle ?? '';
    userRoleName.text = widget.userRoleModel?.userRoleName ?? '';
    if (widget.userRoleModel == null) return;
    if (widget.userRoleModel!.permissions.isNotEmpty) {
      // Migrar permisos faltantes antes de asignar
      migrateExistingPermissions();
    }
  }

  bool hidePassword = true;
  bool confirmHidePassword = true;

  // Métodos para roles predefinidos
  Widget _buildRoleButton(String title, VoidCallback onPressed, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setBasicSalesRole() {
    setState(() {
      // Limpiar todos los permisos primero
      _clearAllPermissions();
      
      // Dar permisos básicos
      _setPermission('dashboard', view: true);
      _setPermission('inicio', view: true);
      _setPermission('tablero', view: true);
      _setPermission('customers', view: true, edit: true);
      _setPermission('products', view: true);
      _setPermission('sales_list', view: true);
      _setPermission('reports', view: true);
    });
  }

  void _setRestrictedRole() {
    setState(() {
      // Limpiar todos los permisos primero
      _clearAllPermissions();
      
      // Dar permisos limitados (SIN rentar, facturar, disponibilidad)
      _setPermission('dashboard', view: true);
      _setPermission('inicio', view: true);
      _setPermission('tablero', view: true);
      _setPermission('services', view: true);
      _setPermission('customers', view: true, edit: true);
      _setPermission('products', view: true);
      _setPermission('reports', view: true);
      _setPermission('sales_list', view: true);
      
      // NO dar permisos a:
      // - rent_clothing (Rentar)
      // - sales, inventory_sales, pos_sales (Facturar)
      // - reservation_calendar (Disponibilidad de Vestimentas)
    });
  }

  void _setNoHeaderActionsRole() {
    setState(() {
      // Limpiar todos los permisos primero
      _clearAllPermissions();
      
      // Dar permisos básicos SIN acceso a botones principales del header
      _setPermission('dashboard', view: true);
      _setPermission('inicio', view: true);
      _setPermission('tablero', view: true);
      _setPermission('customers', view: true, edit: true);
      _setPermission('products', view: true);
      _setPermission('sales_list', view: true);
      _setPermission('purchase_list', view: true);
      
      // NO dar acceso a:
      // - rent_clothing (Botón "Rentar")
      // - sales, inventory_sales (Botón "Facturar") 
      // - services, register_clothing (Botón "Estado de Vestimentas")
      // - reservation_calendar, reservations (Botón "Disponibilidad de Vestimentas")
      // - reports, transaction (Botón "Cuadre de Caja")
    });
  }

  void _setOnlyConsultationRole() {
    setState(() {
      // Limpiar todos los permisos primero
      _clearAllPermissions();
      
      // Permisos específicos para Recursos Humanos
      _setPermission('dashboard', view: true, edit: true);
      _setPermission('inicio', view: true);
      _setPermission('tablero', view: true, edit: true);
      
      // Lista de ventas
      _setPermission('sales_list', view: true);
      
      // Reserva de calendario
      _setPermission('reservation_calendar', view: true);
      
      // Cuadre/cierre de caja (reportes y transacciones para el botón)
      _setPermission('reports', view: true);
      _setPermission('transaction', view: true);
      
      // Lista de clientes
      _setPermission('customers', view: true, edit: true);
      
      // Compras
      _setPermission('purchases', view: true);
      _setPermission('purchase_list', view: true);
      
      // Inventario de equipos
      _setPermission('inventory_list', view: true);
      _setPermission('inventory_equipment', view: true);
      _setPermission('products', view: true);
      
      // Confirmaciones
      _setPermission('confirmations', view: true);
      
      // Gastos
      _setPermission('expense', view: true, edit: true);
      
      // Ingresos
      _setPermission('income', view: true, edit: true);
      
      // Transacciones
      _setPermission('transaction', view: true);
      
      // Gestión de nómina (HRM)
      _setPermission('hrm', view: true, edit: true);
      _setPermission('employees', view: true, edit: true);
      _setPermission('salary_list', view: true, edit: true);
      _setPermission('designations', view: true, edit: true);
    });
  }

  void _setViewOnlyRole() {
    setState(() {
      // Dar solo permisos de visualización
      for (var permission in defaultPermissions) {
        permission.view = true;
        permission.edit = false;
        permission.delete = false;
      }
    });
  }

  void _clearAllPermissions() {
    for (var permission in defaultPermissions) {
      permission.view = false;
      permission.edit = false;
      permission.delete = false;
    }
  }

  void _setPermission(String type, {bool view = false, bool edit = false, bool delete = false}) {
    final permission = defaultPermissions.firstWhere(
      (p) => p.type == type,
      orElse: () => Permission(type: type),
    );
    permission.view = view;
    permission.edit = edit;
    permission.delete = delete;
  }

  // Método para enviar email de restablecimiento de contraseña
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se ha enviado un correo de restablecimiento de contraseña a $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo de restablecimiento: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Función para obtener la categoría del permiso
  String getPermissionCategory(String type) {
    switch (type) {
      case 'dashboard':
      case 'inicio':
      case 'tablero':
        return 'NAVEGACIÓN PRINCIPAL';
      case 'services':
      case 'register_package':
      case 'register_clothing':
        return 'SERVICIOS Y PAQUETES';
      case 'reservations':
      case 'reservation_calendar':
      case 'rent_clothing':
      case 'reserve_package':
        return 'RESERVAS';
      case 'sales':
      case 'pos_sales':
      case 'inventory_sales':
      case 'sales_list':
      case 'sales_return':
      case 'quotation_list':
        return 'VENTAS';
      case 'purchases':
      case 'pos_purchase':
      case 'purchase_list':
      case 'purchase_return':
        return 'COMPRAS';
      case 'products':
      case 'categories':
      case 'warehouses':
      case 'inventory_list':
      case 'inventory_equipment':
        return 'INVENTARIO';
      case 'customers':
      case 'suppliers':
        return 'CONTACTOS';
      case 'confirmations':
        return 'CONFIRMACIONES';
      case 'expense':
      case 'income':
      case 'transaction':
      case 'dues':
      case 'ledger':
      case 'loss_profit':
        return 'FINANZAS';
      case 'reports':
        return 'REPORTES';
      case 'hrm':
      case 'employees':
      case 'designations':
      case 'salary_list':
        return 'RECURSOS HUMANOS';
      case 'user_roles':
      case 'tax_rates':
        return 'CONFIGURACIÓN';
      default:
        return 'OTROS';
    }
  }

  // Función para obtener el color de la categoría
  Color getCategoryColor(String category) {
    switch (category) {
      case 'NAVEGACIÓN PRINCIPAL':
        return kMainColor;
      case 'SERVICIOS Y PAQUETES':
        return Colors.purple;
      case 'RESERVAS':
        return Colors.blue;
      case 'VENTAS':
        return Colors.green;
      case 'COMPRAS':
        return Colors.orange;
      case 'INVENTARIO':
        return Colors.teal;
      case 'CONTACTOS':
        return Colors.indigo;
      case 'CONFIRMACIONES':
        return Colors.lightBlue;
      case 'FINANZAS':
        return Colors.red;
      case 'REPORTES':
        return Colors.brown;
      case 'RECURSOS HUMANOS':
        return Colors.pink;
      case 'CONFIGURACIÓN':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Función para verificar si debe mostrar separador de categoría
  bool shouldShowCategorySeparator(int index) {
    if (index == 0) return true; // Mostrar para el primer elemento
    
    String currentCategory = getPermissionCategory(defaultPermissions[index].type);
    String previousCategory = getPermissionCategory(defaultPermissions[index - 1].type);
    
    return currentCategory != previousCategory;
  }

  // Función para obtener el ícono de la categoría
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'NAVEGACIÓN PRINCIPAL':
        return Icons.dashboard_rounded;
      case 'SERVICIOS Y PAQUETES':
        return Icons.room_service_rounded;
      case 'RESERVAS':
        return Icons.event_available_rounded;
      case 'VENTAS':
        return Icons.point_of_sale_rounded;
      case 'COMPRAS':
        return Icons.shopping_cart_rounded;
      case 'INVENTARIO':
        return Icons.inventory_rounded;
      case 'CONTACTOS':
        return Icons.contacts_rounded;
      case 'CONFIRMACIONES':
        return Icons.verified_rounded;
      case 'FINANZAS':
        return Icons.account_balance_rounded;
      case 'REPORTES':
        return Icons.assessment_rounded;
      case 'RECURSOS HUMANOS':
        return Icons.people_alt_rounded;
      case 'CONFIGURACIÓN':
        return Icons.settings_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(builder: (context, ref, __) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    lang.S.of(context).addUserRole,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    GoRouter.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close_sharp,
                    color: Colors.black,
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            // Padding(
            //   padding: const EdgeInsets.all(10.0),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(width: 0.5, color: kGreyTextColor),
            //       borderRadius: const BorderRadius.all(Radius.circular(10)),
            //     ),
            //     child: Column(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         ///_______all_&_sale____________________________________________
            //         Row(
            //           children: [
            //             ///_______all__________________________
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: allPermissions,
            //                 onChanged: (value) {
            //                   if (value == true) {
            //                     setState(() {
            //                       allPermissions = value!;
            //                       salePermission = true;
            //                       partiesPermission = true;
            //                       purchasePermission = true;
            //                       productPermission = true;
            //                       profileEditPermission = true;
            //                       addExpensePermission = true;
            //                       lossProfitPermission = true;
            //                       dueListPermission = true;
            //                       stockPermission = true;
            //                       reportsPermission = true;
            //                       salesListPermission = true;
            //                       purchaseListPermission = true;
            //                       dailyTransactionPermission = true;
            //                       ledgerPermission = true;
            //                       incomePermission = true;
            //                     });
            //                   } else {
            //                     setState(() {
            //                       allPermissions = value!;
            //                       salePermission = false;
            //                       partiesPermission = false;
            //                       purchasePermission = false;
            //                       productPermission = false;
            //                       profileEditPermission = false;
            //                       addExpensePermission = false;
            //                       lossProfitPermission = false;
            //                       dueListPermission = false;
            //                       stockPermission = false;
            //                       reportsPermission = false;
            //                       salesListPermission = false;
            //                       purchaseListPermission = false;
            //                       dailyTransactionPermission = false;
            //                       ledgerPermission = false;
            //                       incomePermission = false;
            //                     });
            //                   }
            //                 },
            //                 title: Text(lang.S.of(context).all),
            //               ),
            //             ),
            //           ],
            //         ),
            //
            //         ///_______Edit Profile_&_sale____________________________________________
            //         Row(
            //           children: [
            //             ///_______Edit_Profile_________________________
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: profileEditPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     profileEditPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).profileEdit),
            //               ),
            //             ),
            //
            //             ///______sales____________________________
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: salePermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     salePermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).sales),
            //               ),
            //             ),
            //           ],
            //         ),
            //
            //         ///_____parties_&_Purchase_________________________________________
            //         Row(
            //           children: [
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: partiesPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     partiesPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).practies),
            //               ),
            //             ),
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: purchasePermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     purchasePermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).purchase),
            //               ),
            //             ),
            //           ],
            //         ),
            //
            //         ///_____Product_&_DueList_________________________________________
            //         Row(
            //           children: [
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: productPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     productPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).product),
            //               ),
            //             ),
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: dueListPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     dueListPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).dueList),
            //               ),
            //             ),
            //           ],
            //         ),
            //
            //         ///_____Stock_&_Reports_________________________________________
            //         Row(
            //           children: [
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: stockPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     stockPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).stock),
            //               ),
            //             ),
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: reportsPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     reportsPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).reports),
            //               ),
            //             ),
            //           ],
            //         ),
            //
            //         ///_____SalesList_&_Purchase List_________________________________________
            //         Row(
            //           children: [
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: salesListPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     salesListPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).salesList),
            //               ),
            //             ),
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: purchaseListPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     purchaseListPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).purchaseList),
            //               ),
            //             ),
            //           ],
            //         ),
            //
            //         ///_____LossProfit_&_Expense_________________________________________
            //         Row(
            //           children: [
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: lossProfitPermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     lossProfitPermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).lossOrProfit),
            //               ),
            //             ),
            //             Expanded(
            //               child: CheckboxListTile(
            //                 controlAffinity: ListTileControlAffinity.leading,
            //                 value: addExpensePermission,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     addExpensePermission = value!;
            //                   });
            //                 },
            //                 title: Text(lang.S.of(context).expense),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: kNeutral300),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 10),
                      child: Text(
                        lang.S.of(context).type,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang.S.of(context).view,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lang.S.of(context).edit,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lang.S.of(context).delete,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 1.0,
                    color: kNeutral300,
                    height: 1,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: defaultPermissions.length,
                    itemBuilder: (context, index) {
                      final permissionType = defaultPermissions[index].type;
                      final currentCategory = getPermissionCategory(permissionType);
                      final categoryColor = getCategoryColor(currentCategory);
                      final showCategorySeparator = shouldShowCategorySeparator(index);
                      
                      final isDashboardPermission = permissionType == 'dashboard';
                      final isInicioPermission = permissionType == 'inicio';
                      final isTableroPermission = permissionType == 'tablero';
                      final isPrincipalPermission = isDashboardPermission || isInicioPermission || isTableroPermission;
                      
                      return Column(
                        children: [
                          // Mostrar separador de categoría si es necesario
                          if (showCategorySeparator)
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    categoryColor.withValues(alpha: 0.1),
                                    categoryColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border(
                                  left: BorderSide(
                                    color: categoryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(currentCategory),
                                    color: categoryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentCategory,
                                    style: TextStyle(
                                      color: categoryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      margin: const EdgeInsets.only(left: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            categoryColor.withValues(alpha: 0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            margin: isPrincipalPermission 
                              ? const EdgeInsets.symmetric(vertical: 2, horizontal: 8)
                              : EdgeInsets.zero,
                            decoration: isPrincipalPermission
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      kMainColor.withValues(alpha: isDashboardPermission ? 0.08 : 0.06),
                                      kMainColor.withValues(alpha: isDashboardPermission ? 0.02 : 0.01),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: kMainColor.withValues(alpha: isDashboardPermission ? 0.3 : 0.2),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                            child: ListTile(
                              contentPadding: isPrincipalPermission
                                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                                : EdgeInsets.zero,
                              leading: isPrincipalPermission
                                ? Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kMainColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isDashboardPermission 
                                        ? Icons.dashboard_rounded
                                        : isInicioPermission 
                                          ? Icons.home_rounded
                                          : Icons.bar_chart_rounded,
                                      color: kMainColor,
                                      size: 20,
                                    ),
                                  )
                                : null,
                              title: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: isPrincipalPermission ? 0 : 10
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        getPermissionTitle(permissionType),
                                        style: isPrincipalPermission
                                          ? theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: kMainColor.withValues(alpha: 0.9),
                                            )
                                          : theme.textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isDashboardPermission)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 2
                                        ),
                                        decoration: BoxDecoration(
                                          color: kMainColor.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'PRINCIPAL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (isInicioPermission || isTableroPermission)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6, 
                                          vertical: 2
                                        ),
                                        decoration: BoxDecoration(
                                          color: kMainColor.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'NAVEGACIÓN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Theme(
                                    data: theme.copyWith(
                                      checkboxTheme: const CheckboxThemeData(
                                          side: BorderSide(color: kNeutral500)),
                                    ),
                                    child: Checkbox(
                                      value: defaultPermissions[index].view,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          defaultPermissions[index].view =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  Theme(
                                    data: theme.copyWith(
                                      checkboxTheme: const CheckboxThemeData(
                                          side: BorderSide(color: kNeutral500)),
                                    ),
                                    child: Checkbox(
                                      value: defaultPermissions[index].edit,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          defaultPermissions[index].edit =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  Theme(
                                    data: theme.copyWith(
                                      checkboxTheme: const CheckboxThemeData(
                                        side: BorderSide(color: kNeutral500),
                                      ),
                                    ),
                                    child: Checkbox(
                                      value: defaultPermissions[index].delete,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          defaultPermissions[index].delete =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Botones de roles predefinidos
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                ),
                border: Border.all(color: kNeutral300.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kMainColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: kMainColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Roles Predefinidos',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona un rol para aplicar permisos automáticamente',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.0 : 1.3,
                    children: [
                      Tooltip(
                        message: 'Acceso básico a ventas y consulta de clientes',
                        child: _buildRoleButton(
                          'Solo Ventas Básicas',
                          () => _setBasicSalesRole(),
                          Colors.green,
                          Icons.point_of_sale_rounded,
                        ),
                      ),
                      Tooltip(
                        message: 'Sin acceso a rentar, facturar o disponibilidad',
                        child: _buildRoleButton(
                          'Sin Rentar/Facturar',
                          () => _setRestrictedRole(),
                          Colors.orange,
                          Icons.block_rounded,
                        ),
                      ),
                      Tooltip(
                        message: 'Sin acceso a botones principales del header',
                        child: _buildRoleButton(
                          'Sin Botones Header',
                          () => _setNoHeaderActionsRole(),
                          Colors.red.shade600,
                          Icons.remove_circle_outline_rounded,
                        ),
                      ),
                      Tooltip(
                        message: 'Acceso a ventas, clientes, nómina, gastos e ingresos + cuadre caja',
                        child: _buildRoleButton(
                          'Recursos Humanos',
                          () => _setOnlyConsultationRole(),
                          Colors.blue,
                          Icons.people_alt_rounded,
                        ),
                      ),
                      Tooltip(
                        message: 'Solo puede ver información, no editar',
                        child: _buildRoleButton(
                          'Ver Todo',
                          () => _setViewOnlyRole(),
                          Colors.cyan,
                          Icons.remove_red_eye_rounded,
                        ),
                      ),
                      Tooltip(
                        message: 'Quita todos los permisos para empezar de cero',
                        child: _buildRoleButton(
                          'Limpiar Todo',
                          () => _clearAllPermissions(),
                          Colors.red,
                          Icons.clear_all_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ///___________Text_fields_____________________________________________
            Form(
              key: globalKey,
              child: Column(
                children: [
                  ///__________email_________________________________________________________
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        //return 'Email can\'n be empty';
                        return lang.S.of(context).emailCanNotBeEmpty;
                      } else if (!value.contains('@')) {
                        //return 'Please enter a valid email';
                        return lang.S.of(context).pleaseEnterAValidEmail;
                      }
                      return null;
                    },
                    showCursor: true,
                    controller: emailController,
                    // cursorColor: kTitleColor,
                    decoration: InputDecoration(
                      labelText: lang.S.of(context).email,
                      // labelStyle: kTextStyle.copyWith(color: kTitleColor),
                      hintText: 'maantheme@gmail.com',
                    ),
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 20.0),

                  ///______password___________________________________________________________
                  TextFormField(
                    obscureText: hidePassword,
                    validator: (value) {
                      // Si estamos editando un usuario existente, la contraseña es opcional
                      if (widget.userRoleModel != null) {
                        // Si se proporciona contraseña, debe ser válida
                        if (value != null && value.isNotEmpty && value.length < 4) {
                          return lang.S.of(context).pleaseEnterABiggerPassword;
                        }
                        return null;
                      }
                      // Para usuarios nuevos, la contraseña es obligatoria
                      if (value == null || value.isEmpty) {
                        return lang.S.of(context).passwordCanNotBeEmpty;
                      } else if (value.length < 4) {
                        return lang.S.of(context).pleaseEnterABiggerPassword;
                      }
                      return null;
                    },
                    controller: passwordController,
                    showCursor: true,
                    // cursorColor: kTitleColor,
                    decoration: InputDecoration(
                        labelText: widget.userRoleModel != null 
                            ? '${lang.S.of(context).password} (Opcional - dejar vacío para no cambiar)'
                            : lang.S.of(context).password,
                        hintText: widget.userRoleModel != null 
                            ? 'Dejar vacío para no cambiar la contraseña'
                            : lang.S.of(context).enterYourPassword,
                        suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off))),
                    keyboardType: TextInputType.visiblePassword,
                  ),

                  ///________retype_email____________________________________________________
                  const SizedBox(height: 20.0),
                  TextFormField(
                    validator: (value) {
                      // Si estamos editando un usuario existente
                      if (widget.userRoleModel != null) {
                        // Si se proporciona contraseña, la confirmación debe coincidir
                        if (passwordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'Debe confirmar la nueva contraseña';
                          } else if (value != passwordController.text) {
                            return lang.S.of(context).passwordAndConfirmPasswordDoesNotMatch;
                          } else if (value.length < 4) {
                            return lang.S.of(context).pleaseEnterABiggerPassword;
                          }
                        }
                        return null;
                      }
                      // Para usuarios nuevos, la confirmación es obligatoria
                      if (value == null || value.isEmpty) {
                        return lang.S.of(context).passwordCanNotBeEmpty;
                      } else if (value != passwordController.text) {
                        // return 'Password and confirm password does not match';
                        return lang.S
                            .of(context)
                            .passwordAndConfirmPasswordDoesNotMatch;
                      } else if (value.length < 4) {
                        // return 'Please enter a bigger password';
                        return lang.S.of(context).pleaseEnterABiggerPassword;
                      }
                      return null;
                    },
                    controller: confirmPasswordController,
                    showCursor: true,
                    obscureText: confirmHidePassword,
                    // cursorColor: kTitleColor,
                    decoration: InputDecoration(
                      labelText: widget.userRoleModel != null 
                          ? '${lang.S.of(context).confirmPassword} (Opcional)'
                          : lang.S.of(context).confirmPassword,
                      // labelStyle: kTextStyle.copyWith(color: kTitleColor),
                      hintText: widget.userRoleModel != null 
                          ? 'Confirmar nueva contraseña si se va a cambiar'
                          : lang.S.of(context).enterYourPassword,
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              confirmHidePassword = !confirmHidePassword;
                            });
                          },
                          icon: Icon(confirmHidePassword
                              ? Icons.visibility
                              : Icons.visibility_off)),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                  ),

                  ///__________Title_________________________________________________________
                  const SizedBox(height: 20.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        //return 'User title can\'n be empty';
                        return lang.S.of(context).userTitleCanBeEmpty;
                      }
                      return null;
                    },
                    showCursor: true,
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: lang.S.of(context).userTitle,
                      hintText: lang.S.of(context).enterUserTitle,
                      contentPadding: const EdgeInsets.all(10.0),
                    ),
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 20.0),
                  AppTextField(
                    showCursor: true,
                    validator: (value) {
                      return null;
                    },
                    controller: userRoleName,
                    decoration: InputDecoration(
                      labelText: lang.S.of(context).userRoleName,
                      hintText: lang.S.of(context).enterUserRoleName,
                      contentPadding: const EdgeInsets.all(10.0),
                    ),
                    textFieldType: TextFieldType.EMAIL,
                  ),
                  const SizedBox(height: 20.0),

                  // Mensaje informativo para cambio de contraseña en edición
                  if (widget.userRoleModel != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Para cambiar la contraseña, ingrese la nueva contraseña. Se enviará un correo de restablecimiento al usuario.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                  ],

                ],
              ),
            ),

            ///_________button__________________________________________________
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(screenWidth, 48)),
                onPressed: (() async {
                  UserRoleModel userRolePermissionModel =
                      UserRoleModel(permissions: []);
                  userRolePermissionModel.permissions = defaultPermissions;

                  //Check if no true in is permission array
                  if (defaultPermissions.every((element) =>
                      element.view == false &&
                      element.edit == false &&
                      element.delete == false)) {
                    EasyLoading.showError(
                        lang.S.of(context).youHaveToGivePermission);
                    return;
                  }
                  if (widget.userRoleModel != null) {
                    try {
                      EasyLoading.show(
                          status: '${lang.S.of(context).loading}...',
                          dismissOnTap: false);
                      UserRoleRepo repo = UserRoleRepo();
                      String adminRoleKey = '';
                      String userRoleKey = '';
                      var adminRoleList = await repo.getAllUserRoleFromAdmin();
                      var userRoleList = await repo.getAllUserRole();
                      for (var element in adminRoleList) {
                        if (element.email ==
                            (widget.userRoleModel?.email ?? "")) {
                          adminRoleKey = element.userKey ?? '';
                          break;
                        }
                      }
                      for (var element in userRoleList) {
                        if (element.email ==
                            (widget.userRoleModel?.email ?? "")) {
                          userRoleKey = element.userKey ?? '';
                          break;
                        }
                      }

                      DatabaseReference dataRef = FirebaseDatabase.instance
                          .ref("$constUserId/User Role/$userRoleKey");
                      DatabaseReference adminDataRef = FirebaseDatabase.instance
                          .ref("Admin Panel/User Role/$adminRoleKey");
                      userRolePermissionModel.email = emailController.text;
                      userRolePermissionModel.userTitle = titleController.text;
                      userRolePermissionModel.userRoleName = userRoleName.text;
                      // userRolePermissionModel.databaseId =
                      //     widget.userRoleModel!.databaseId;
                      userRolePermissionModel.databaseId = constUserId;
                      await dataRef.update(userRolePermissionModel.toJson());
                      await adminDataRef
                          .update(userRolePermissionModel.toJson());
                      
                      // Si se cambió la contraseña, enviar email de restablecimiento
                      if (passwordController.text.isNotEmpty && 
                          confirmPasswordController.text.isNotEmpty &&
                          passwordController.text == confirmPasswordController.text) {
                        await _sendPasswordResetEmail(emailController.text);
                      }
                      
                      ref.refresh(userRoleProvider);
                      ref.refresh(allUserRoleProvider);

                      EasyLoading.showSuccess(
                          lang.S.of(context).successfullyUpdated,
                          duration: const Duration(milliseconds: 500));
                      // ignore: use_build_context_synchronously
                      // Navigator.pop(context);
                      GoRouter.of(context).pop();
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                    return;
                  } else {
                    if (!validateAndSave()) return;
                    userRolePermissionModel.email = emailController.text;
                    userRolePermissionModel.userTitle = titleController.text;
                    userRolePermissionModel.databaseId =
                        FirebaseAuth.instance.currentUser!.uid;
                    userRolePermissionModel.userRoleName = userRoleName.text;
                    signUp(
                      context: context,
                      email: emailController.text,
                      password: passwordController.text,
                      ref: ref,
                      userRoleModel: userRolePermissionModel,
                    );
                  }
                }),
                child: Text(lang.S.of(context).create)),
          ],
        ),
      );
    });
  }

  String getPermissionTitle(String type) {
    switch (type) {
      case 'dashboard':
        return 'Panel de Control';
      case 'inicio':
        return 'Inicio';
      case 'tablero':
        return 'Tablero';
      case 'services':
        return 'Servicios';
      case 'register_package':
        return 'Registrar Paquete';
      case 'register_clothing':
        return 'Registrar Vestimenta';
      case 'reservations':
        return 'Reservas';
      case 'rent_clothing':
        return 'Rentar Vestimentas';
      case 'reserve_package':
        return 'Reservar Paquete';
      case 'reservation_calendar':
        return 'Calendario de Reservas';
      case 'sales':
        return 'Ventas';
      case 'pos_sales':
        return 'Ventas en Punto de Venta';
      case 'inventory_sales':
        return 'Ventas desde Inventario';
      case 'sales_list':
        return 'Lista de Ventas';
      case 'sales_return':
        return 'Devoluciones de Venta';
      case 'quotation_list':
        return 'Lista de Cotizaciones';
      case 'purchases':
        return 'Compras';
      case 'pos_purchase':
        return 'Compra en Punto de Venta';
      case 'purchase_list':
        return 'Lista de Compras';
      case 'purchase_return':
        return 'Devoluciones de Compra';
      case 'categories':
        return 'Categorías';
      case 'products':
        return 'Productos';
      case 'warehouses':
        return 'Almacenes';
      case 'suppliers':
        return 'Proveedores';
      case 'customers':
        return 'Clientes';
      case 'dues':
        return 'Cuentas por Cobrar';
      case 'ledger':
        return 'Libro Mayor';
      case 'loss_profit':
        return 'Pérdidas y Ganancias';
      case 'expense':
        return 'Gastos';
      case 'income':
        return 'Ingresos';
      case 'transaction':
        return 'Transacciones';
      case 'reports':
        return 'Reportes';
      case 'inventory_list':
        return 'Lista de Inventario';
      case 'inventory_equipment':
        return 'Inventario de Equipos';
      case 'confirmations':
        return 'Confirmaciones';
      case 'user_roles':
        return 'Roles de Usuario';
      case 'tax_rates':
        return 'Tasas de Impuesto';
      case 'hrm':
        return 'Gestión de Nómina';
      case 'designations':
        return 'Puestos';
      case 'employees':
        return 'Empleados';
      case 'salary_list':
        return 'Lista de Salarios';
      default:
        return type; // fallback: puedes usar algo como `return 'Desconocido';`
    }
  }

  void signUp(
    {required BuildContext context,
    required String email,
    required String password,
    required WidgetRef ref,
    required UserRoleModel userRoleModel}) async {
    EasyLoading.show(status: '${lang.S.of(context).registering}....');
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.additionalUserInfo!.isNewUser) {
        await FirebaseDatabase.instance
            .ref()
            .child(userRoleModel.databaseId ?? "")
            .child('User Role')
            .push()
            .set(userRoleModel.toJson());
        await FirebaseDatabase.instance
            .ref()
            .child('Admin Panel')
            .child('User Role')
            .push()
            .set(userRoleModel.toJson());

        await FirebaseAuth.instance.signOut();
        await Future.delayed(const Duration(seconds: 1));
        try {
          await Future.delayed(const Duration(seconds: 1));
          await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: mainLoginEmail, password: mainLoginPassword);
          await Future.delayed(const Duration(seconds: 2));
          ref.refresh(userRoleProvider);

          EasyLoading.showSuccess(lang.S.of(context).successfullyAdded);
          // ignore: use_build_context_synchronously
          // Navigator.of(context).pushNamed(MtHomeScreen.route);
          context.go('/dashboard');
        } on FirebaseAuthException catch (e) {
          EasyLoading.showError(lang.S.of(context).error);
          EasyLoading.showError(e.message.toString());
          if (e.code == 'user-not-found') {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${lang.S.of(context).noUserFoundForThatEmail}.'),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (e.code == 'wrong-password') {
            //EasyLoading.showError('wrong-password');
            EasyLoading.showError(lang.S.of(context).wrongPassword);
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                //content: Text('Wrong password provided for that user.'),
                content: Text(
                    '${lang.S.of(context).wrongPasswordProvidedForThatUser}.'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          EasyLoading.showError(e.toString());
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError(lang.S.of(context).failedWithError);
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // content: Text('The password provided is too weak.'),
            content: Text('${lang.S.of(context).thePasswordProvidedIsTooWeak}.'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            //content: Text('The account already exists for that email.'),
            content: Text(
                '${lang.S.of(context).theAccountAlreadyExistsForThatEmail}.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      EasyLoading.showError(lang.S.of(context).failedWithError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Función para migrar permisos de usuarios existentes
  void migrateExistingPermissions() {
    if (widget.userRoleModel == null) return;
    
    // Obtener todos los tipos de permisos que deberían existir (del defaultPermissions original)
    List<String> allRequiredPermissionTypes = [
      'dashboard', 'inicio', 'tablero',
      'services', 'register_package', 'register_clothing',
      'reservations', 'reservation_calendar', 'rent_clothing', 'reserve_package',
      'sales', 'pos_sales', 'inventory_sales', 'sales_list', 'sales_return', 'quotation_list',
      'purchases', 'pos_purchase', 'purchase_list', 'purchase_return',
      'products', 'categories', 'warehouses', 'inventory_list', 'inventory_equipment',
      'customers', 'suppliers',
      'confirmations',
      'expense', 'income', 'transaction', 'dues', 'ledger', 'loss_profit',
      'reports',
      'hrm', 'employees', 'designations', 'salary_list',
      'user_roles', 'tax_rates',
    ];
    
    // Verificar qué permisos faltan y agregarlos
    List<String> existingPermissionTypes = widget.userRoleModel!.permissions.map((p) => p.type).toList();
    
    for (String requiredPermissionType in allRequiredPermissionTypes) {
      if (!existingPermissionTypes.contains(requiredPermissionType)) {
        // Agregar el permiso faltante con valores por defecto
        widget.userRoleModel!.permissions.add(Permission(
          type: requiredPermissionType,
          view: false,
          edit: false,
          delete: false,
        ));
      }
    }
    
    // Ordenar los permisos para mantener el mismo orden que defaultPermissions
    List<Permission> orderedPermissions = [];
    for (String requiredType in allRequiredPermissionTypes) {
      Permission? foundPermission = widget.userRoleModel!.permissions.firstWhere(
        (p) => p.type == requiredType,
        orElse: () => Permission(type: requiredType, view: false, edit: false, delete: false),
      );
      orderedPermissions.add(foundPermission);
    }
    
    // Actualizar defaultPermissions con los permisos migrados y ordenados
    defaultPermissions = orderedPermissions;
    
  }
}
