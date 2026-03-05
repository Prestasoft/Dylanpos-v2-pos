// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/user_role_provider.dart';
import '../../const.dart';
import '../../model/user_role_model.dart';
import '../../services/api_service.dart';
import 'permissions_editor_widget.dart';

class AddUserRole extends StatefulWidget {
  AddUserRole({Key? key, this.userRoleModel}) : super(key: key);
  final UserRoleModel? userRoleModel;

  @override
  // ignore: library_private_types_in_public_api
  _AddUserRoleState createState() => _AddUserRoleState();
}

class _AddUserRoleState extends State<AddUserRole> {
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool _isDataLoaded = false; // Flag para controlar cuándo mostrar el widget de permisos

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
  TextEditingController userRoleName = TextEditingController(text: 'user');
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
    
    // ===== AUDITORÍA =====
    Permission(type: 'audit'),
    
    // ===== RECURSOS HUMANOS =====
    Permission(type: 'hrm'),
    Permission(type: 'employees'),
    Permission(type: 'designations'),
    Permission(type: 'salary_list'),
    Permission(type: 'attendance'),
    Permission(type: 'vacations'),
    Permission(type: 'loans'),
    Permission(type: 'prestaciones'),
    Permission(type: 'tss_reports'),
    Permission(type: 'birthdays'),
    Permission(type: 'rentability'),

    // ===== TRANSFERENCIAS Y BANCOS =====
    Permission(type: 'transfers'),
    Permission(type: 'banks'),

    // ===== CONFIGURACIÓN =====
    Permission(type: 'user_roles'),
    Permission(type: 'tax_rates'),
  ];

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();

    debugPrint('🔴 [AddUserRole.initState] widget.userRoleModel: ${widget.userRoleModel}');
    debugPrint('🔴 [AddUserRole.initState] widget.userRoleModel != null: ${widget.userRoleModel != null}');

    if (widget.userRoleModel != null) {
      debugPrint('🔴 [AddUserRole.initState] userTitle: ${widget.userRoleModel!.userTitle}');
      debugPrint('🔴 [AddUserRole.initState] permissions.length: ${widget.userRoleModel!.permissions.length}');
      debugPrint('🔴 [AddUserRole.initState] permissions.isNotEmpty: ${widget.userRoleModel!.permissions.isNotEmpty}');

      // CRÍTICO: Primero migrar permisos ANTES de que se ejecute build()
      _initializeEditData();
    } else {
      debugPrint('🔴 [AddUserRole.initState] userRoleModel es NULL - modo crear nuevo usuario');
      _isDataLoaded = true;
    }
  }

  /// Inicializa los datos de edición ANTES de que el widget se construya
  void _initializeEditData() {
    emailController.text = widget.userRoleModel?.email ?? '';
    titleController.text = widget.userRoleModel?.userTitle ?? '';
    userRoleName.text = widget.userRoleModel?.userRoleName ?? '';
    selectedBranchId = widget.userRoleModel?.branchId ?? 'stg';
    selectedAllowedBranches = widget.userRoleModel?.allowedBranches ?? [];

    debugPrint('🔵 [_initializeEditData] email: ${emailController.text}');
    debugPrint('🔵 [_initializeEditData] userTitle: ${titleController.text}');
    debugPrint('🔵 [_initializeEditData] permissions.length: ${widget.userRoleModel?.permissions.length ?? 0}');

    if (widget.userRoleModel != null && widget.userRoleModel!.permissions.isNotEmpty) {
      // Migrar permisos del usuario existente
      migrateExistingPermissions();

      // DEBUG: Verificar permisos después de migrar
      int activeCount = defaultPermissions.where((p) => p.view || p.edit || p.delete).length;
      debugPrint('🟢 [_initializeEditData] Permisos activos después de migrar: $activeCount');
    }

    // Marcar como cargado para que build() muestre el widget
    _isDataLoaded = true;
  }

  bool hidePassword = true;
  bool confirmHidePassword = true;
  String selectedBranchId = 'stg'; // Sucursal seleccionada por defecto
  List<String> selectedAllowedBranches = []; // Sucursales permitidas para cambiar

  /// Valida que el valor del rol sea una opción válida del dropdown
  /// Si no es válido, retorna 'user' como valor por defecto
  String _getValidRoleValue(String? roleValue) {
    const validRoles = ['admin', 'user', 'manager', 'cashier', 'dress_operator'];
    if (roleValue == null || roleValue.isEmpty) {
      return 'user';
    }
    // Si el rol actual está en las opciones válidas, lo retornamos
    if (validRoles.contains(roleValue.toLowerCase())) {
      return roleValue.toLowerCase();
    }
    // Si no está en las opciones válidas, retornamos 'user' como default
    return 'user';
  }

  // Método para enviar email de restablecimiento de contraseña
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post('auth/password-reset', {
        'email': email,
      });

      if (response.success) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se ha enviado un correo de restablecimiento de contraseña a $email'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar correo de restablecimiento: ${response.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
            // Widget profesional de permisos con categorías colapsables
            // Solo mostrar cuando los datos estén cargados
            if (_isDataLoaded)
              PermissionsEditorWidget(
                key: ValueKey('permissions_${defaultPermissions.hashCode}'),
                permissions: defaultPermissions,
                onPermissionsChanged: (updatedPermissions) {
                  setState(() {
                    defaultPermissions = updatedPermissions;
                  });
                },
                userName: titleController.text,
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
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
                  // Selector de Rol de Usuario (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _getValidRoleValue(userRoleName.text),
                        hint: Text(lang.S.of(context).enterUserRoleName),
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'user',
                            child: Text('Usuario'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Gerente'),
                          ),
                          DropdownMenuItem(
                            value: 'cashier',
                            child: Text('Cajero'),
                          ),
                          DropdownMenuItem(
                            value: 'dress_operator',
                            child: Row(
                              children: [
                                Icon(Icons.checkroom, size: 18, color: Colors.purple),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Operador de Vestimentas'),
                                      Text(
                                        'Solo Estado y Disponibilidad',
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            userRoleName.text = newValue ?? 'user';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Selector de Sucursal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedBranchId,
                        hint: const Text('Seleccionar Sucursal'),
                        items: const [
                          DropdownMenuItem(
                            value: 'stg',
                            child: Text('Santiago'),
                          ),
                          DropdownMenuItem(
                            value: 'sde',
                            child: Text('Santo Domingo Este'),
                          ),
                          DropdownMenuItem(
                            value: 'sdo',
                            child: Text('Santo Domingo Oeste'),
                          ),
                          DropdownMenuItem(
                            value: 'rom',
                            child: Text('La Romana'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedBranchId = newValue ?? 'stg';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Sucursales permitidas para cambiar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.swap_horiz, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Sucursales Permitidas para Cambiar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona las sucursales a las que este usuario puede cambiar/acceder',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Santiago', style: TextStyle(fontSize: 13)),
                          value: selectedAllowedBranches.contains('stg'),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedAllowedBranches.contains('stg')) {
                                  selectedAllowedBranches.add('stg');
                                }
                              } else {
                                selectedAllowedBranches.remove('stg');
                              }
                            });
                          },
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Santo Domingo Este', style: TextStyle(fontSize: 13)),
                          value: selectedAllowedBranches.contains('sde'),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedAllowedBranches.contains('sde')) {
                                  selectedAllowedBranches.add('sde');
                                }
                              } else {
                                selectedAllowedBranches.remove('sde');
                              }
                            });
                          },
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Santo Domingo Oeste', style: TextStyle(fontSize: 13)),
                          value: selectedAllowedBranches.contains('sdo'),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedAllowedBranches.contains('sdo')) {
                                  selectedAllowedBranches.add('sdo');
                                }
                              } else {
                                selectedAllowedBranches.remove('sdo');
                              }
                            });
                          },
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('La Romana', style: TextStyle(fontSize: 13)),
                          value: selectedAllowedBranches.contains('rom'),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedAllowedBranches.contains('rom')) {
                                  selectedAllowedBranches.add('rom');
                                }
                              } else {
                                selectedAllowedBranches.remove('rom');
                              }
                            });
                          },
                        ),
                      ],
                    ),
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
                    // PROTECCIÓN: Verificar si es un usuario Super Admin protegido
                    if (isProtectedUser(widget.userRoleModel?.databaseId, widget.userRoleModel?.email)) {
                      EasyLoading.showError('Este usuario es Super Admin y no se pueden modificar sus permisos');
                      return;
                    }

                    try {
                      EasyLoading.show(
                          status: '${lang.S.of(context).loading}...',
                          dismissOnTap: false);

                      // Find user by email via API
                      final apiService = ApiService();
                      String? userId;

                      // Find the user in PostgreSQL by email
                      final userResponse = await apiService.get('users?email=${widget.userRoleModel?.email ?? ""}');
                      if (userResponse.success && userResponse.data != null) {
                        final data = userResponse.data;
                        List<dynamic> users = [];
                        if (data is Map && data['users'] != null) {
                          users = data['users'] as List<dynamic>;
                        } else if (data is List) {
                          users = data;
                        }
                        if (users.isNotEmpty) {
                          final userData = Map<String, dynamic>.from(users.first);
                          userId = userData['id']?.toString();
                        }
                      }

                      userRolePermissionModel.email = emailController.text;
                      userRolePermissionModel.userTitle = titleController.text;
                      userRolePermissionModel.userRoleName = userRoleName.text;
                      userRolePermissionModel.branchId = selectedBranchId;
                      userRolePermissionModel.allowedBranches = selectedAllowedBranches.isNotEmpty ? selectedAllowedBranches : null;
                      userRolePermissionModel.databaseId = constUserId;

                      // Update user via API
                      if (userId != null && userId.isNotEmpty) {
                        final updateData = userRolePermissionModel.toJson();

                        // Transform permissions from array to object for backend
                        if (updateData['permissions'] is List) {
                          final permissionsList = updateData['permissions'] as List;
                          final permissionsObject = <String, dynamic>{};

                          for (var perm in permissionsList) {
                            if (perm is Map && perm['type'] != null) {
                              permissionsObject[perm['type'].toString()] = {
                                'view': perm['view'] ?? false,
                                'edit': perm['edit'] ?? false,
                                'delete': perm['delete'] ?? false,
                              };
                            }
                          }

                          updateData['permissions'] = permissionsObject;
                        }

                        // Map frontend field names to backend field names
                        final backendData = <String, dynamic>{
                          'name': updateData['userTitle'],
                          'role': updateData['userRoleName'],
                          'branch_id': updateData['branchId'],
                          'allowed_branches': updateData['allowedBranches'],
                          'permissions': updateData['permissions'],
                        };

                        // Add password if changed
                        if (passwordController.text.isNotEmpty &&
                            confirmPasswordController.text.isNotEmpty &&
                            passwordController.text == confirmPasswordController.text) {
                          backendData['password'] = passwordController.text;
                        }

                        // DEBUG: Log data being sent
                        debugPrint('🔍 [UPDATE USER] userId: $userId');
                        debugPrint('🔍 [UPDATE USER] selectedAllowedBranches: $selectedAllowedBranches');
                        debugPrint('🔍 [UPDATE USER] backendData[allowed_branches]: ${backendData['allowed_branches']}');
                        debugPrint('🔍 [UPDATE USER] backendData COMPLETO: $backendData');
                        debugPrint('🔍 [UPDATE USER] Número de permisos: ${(backendData['permissions'] as Map).length}');

                        final response = await apiService.put('users/$userId', backendData);

                        debugPrint('🔍 [UPDATE USER RESPONSE] success: ${response.success}');
                        debugPrint('🔍 [UPDATE USER RESPONSE] message: ${response.message}');
                        debugPrint('🔍 [UPDATE USER RESPONSE] data: ${response.data}');
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
                    userRolePermissionModel.databaseId = constUserId;
                    userRolePermissionModel.userRoleName = userRoleName.text;
                    userRolePermissionModel.branchId = selectedBranchId;
                    userRolePermissionModel.allowedBranches = selectedAllowedBranches.isNotEmpty ? selectedAllowedBranches : null;
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
      case 'attendance':
        return 'Asistencia';
      case 'vacations':
        return 'Vacaciones';
      case 'loans':
        return 'Préstamos';
      case 'prestaciones':
        return 'Prestaciones';
      case 'tss_reports':
        return 'Reportes TSS';
      case 'birthdays':
        return 'Cumpleaños';
      case 'rentability':
        return 'Rentabilidad';
      case 'transfers':
        return 'Transferencias';
      case 'banks':
        return 'Bancos';
      case 'audit':
        return 'Auditoría';
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
      final apiService = ApiService();

      // Create user via API (register endpoint)
      final userData = userRoleModel.toJson();

      // Transform permissions from array to object for backend
      if (userData['permissions'] is List) {
        final permissionsList = userData['permissions'] as List;
        final permissionsObject = <String, dynamic>{};

        for (var perm in permissionsList) {
          if (perm is Map && perm['type'] != null) {
            permissionsObject[perm['type'].toString()] = {
              'view': perm['view'] ?? false,
              'edit': perm['edit'] ?? false,
              'delete': perm['delete'] ?? false,
            };
          }
        }
        userData['permissions'] = permissionsObject;
      }

      // Map frontend field names to backend field names
      final backendData = <String, dynamic>{
        'email': email,
        'password': password,
        'name': userRoleModel.userTitle ?? email,
        'role': userRoleModel.userRoleName ?? 'user',
        'branch_id': userRoleModel.branchId ?? 'stg',
        'allowed_branches': userRoleModel.allowedBranches,
        'permissions': userData['permissions'],
      };

      final response = await apiService.post('auth/register', backendData);

      if (response.success) {
        ref.refresh(userRoleProvider);
        ref.refresh(allUserRoleProvider);

        EasyLoading.showSuccess(lang.S.of(context).successfullyAdded);
        // ignore: use_build_context_synchronously
        context.go('/dashboard');
      } else {
        // Handle specific error cases
        final errorMessage = response.message ?? '';
        if (errorMessage.contains('already exists') || errorMessage.contains('already in use')) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${lang.S.of(context).theAccountAlreadyExistsForThatEmail}.'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (errorMessage.contains('weak') || errorMessage.contains('password')) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${lang.S.of(context).thePasswordProvidedIsTooWeak}.'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        EasyLoading.showError(lang.S.of(context).failedWithError);
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

    debugPrint('🟡 [migrateExistingPermissions] INICIO - permisos del modelo: ${widget.userRoleModel!.permissions.length}');

    // DEBUG: Mostrar todos los permisos que vienen del modelo
    for (var p in widget.userRoleModel!.permissions) {
      if (p.view || p.edit || p.delete) {
        debugPrint('🔵 [migrateExistingPermissions] Permiso ORIGINAL: ${p.type} -> view=${p.view}, edit=${p.edit}, delete=${p.delete}');
      }
    }

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
      'audit',
      'hrm', 'employees', 'designations', 'salary_list',
      'attendance', 'vacations', 'loans', 'prestaciones', 'tss_reports', 'birthdays', 'rentability',
      'transfers', 'banks',
      'user_roles', 'tax_rates',
    ];

    // Crear un mapa de los permisos existentes para acceso rápido
    Map<String, Permission> existingPermissionsMap = {};
    for (var p in widget.userRoleModel!.permissions) {
      existingPermissionsMap[p.type] = p;
    }

    // Construir la lista ordenada de permisos
    List<Permission> orderedPermissions = [];
    for (String requiredType in allRequiredPermissionTypes) {
      if (existingPermissionsMap.containsKey(requiredType)) {
        // Usar el permiso existente del usuario (mantiene los valores de view/edit/delete)
        orderedPermissions.add(existingPermissionsMap[requiredType]!);
      } else {
        // Crear un nuevo permiso con valores false si no existe
        orderedPermissions.add(Permission(
          type: requiredType,
          view: false,
          edit: false,
          delete: false,
        ));
      }
    }

    // Actualizar defaultPermissions con los permisos migrados y ordenados
    defaultPermissions = orderedPermissions;

    // DEBUG: Verificar permisos migrados
    int activePermissions = 0;
    for (var p in defaultPermissions) {
      if (p.view || p.edit || p.delete) {
        activePermissions++;
        debugPrint('🟢 [migrateExistingPermissions] Permission FINAL: ${p.type} -> view=${p.view}, edit=${p.edit}, delete=${p.delete}');
      }
    }
    debugPrint('🟡 [migrateExistingPermissions] FIN - Total permisos activos: $activePermissions / ${defaultPermissions.length}');
  }
}
