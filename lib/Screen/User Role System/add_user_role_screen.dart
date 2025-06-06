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

  bool allPermissions = false;
  bool salePermission = false;
  bool partiesPermission = false;
  bool purchasePermission = false;
  bool productPermission = false;
  bool profileEditPermission = false;
  bool addExpensePermission = false;
  bool lossProfitPermission = false;
  bool dueListPermission = false;
  bool stockPermission = false;
  bool reportsPermission = false;
  bool salesListPermission = false;
  bool purchaseListPermission = false;
  bool incomePermission = false;
  bool ledgerPermission = false;
  bool dailyTransactionPermission = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController userRoleName = TextEditingController();
  List<Permission> permissions = [
    Permission(type: 'Sale'),
    Permission(type: 'Parties'),
    Permission(type: 'Purchase'),
    Permission(type: 'Product'),
    Permission(type: 'Profile Edit'),
    Permission(type: 'Add Expense'),
    Permission(type: 'Loss Profit'),
    Permission(type: 'Due List'),
    Permission(type: 'Stock'),
    Permission(type: 'Reports'),
    Permission(type: 'Sales List'),
    Permission(type: 'Purchase List'),
    Permission(type: 'HRM')
  ];
  List<Permission> defaultPermissions = [
    Permission(type: 'dashboard'),
    Permission(type: 'services'),
    Permission(type: 'register_package'),
    Permission(type: 'register_clothing'),
    Permission(type: 'reservations'),
    Permission(type: 'rent_clothing'),
    Permission(type: 'reserve_package'),
    Permission(type: 'reservation_calendar'),
    Permission(type: 'sales'),
    Permission(type: 'pos_sales'),
    Permission(type: 'inventory_sales'),
    Permission(type: 'sales_list'),
    Permission(type: 'sales_return'),
    Permission(type: 'quotation_list'),
    Permission(type: 'purchases'),
    Permission(type: 'pos_purchase'),
    Permission(type: 'purchase_list'),
    Permission(type: 'purchase_return'),
    Permission(type: 'categories'),
    Permission(type: 'products'),
    Permission(type: 'warehouses'),
    Permission(type: 'suppliers'),
    Permission(type: 'customers'),
    Permission(type: 'dues'),
    Permission(type: 'ledger'),
    Permission(type: 'loss_profit'),
    Permission(type: 'expense'),
    Permission(type: 'income'),
    Permission(type: 'transaction'),
    Permission(type: 'reports'),
    Permission(type: 'inventory_list'),
    Permission(type: 'user_roles'),
    Permission(type: 'tax_rates'),
    Permission(type: 'hrm'),
    Permission(type: 'designations'),
    Permission(type: 'employees'),
    Permission(type: 'salary_list'),
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
    print(widget.userRoleModel!.permissions);
    print(widget.userRoleModel!.databaseId);
    print(widget.userRoleModel!.userRoleName);
    print(widget.userRoleModel!.userKey);
    if (widget.userRoleModel!.permissions.isNotEmpty) {
      defaultPermissions = widget.userRoleModel!.permissions;
    }
  }

  bool hidePassword = true;
  bool confirmHidePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    print("Const user id: $constUserId");
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
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 10),
                          child: Text(
                            getPermissionTitle(defaultPermissions[index].type),
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                      );
                    },
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
                      if (value == null || value.isEmpty) {
                        // return 'Password can\'t be empty';
                        return lang.S.of(context).passwordCanNotBeEmpty;
                      } else if (value.length < 4) {
                        // return 'Please enter a bigger password';
                        return lang.S.of(context).pleaseEnterABiggerPassword;
                      }
                      return null;
                    },
                    controller: passwordController,
                    showCursor: true,
                    // cursorColor: kTitleColor,
                    decoration: InputDecoration(
                        labelText: lang.S.of(context).password,
                        hintText: lang.S.of(context).enterYourPassword,
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
                      if (value == null || value.isEmpty) {
                        //  return 'Password can\'t be empty';
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
                      labelText: lang.S.of(context).confirmPassword,
                      // labelStyle: kTextStyle.copyWith(color: kTitleColor),
                      hintText: lang.S.of(context).enterYourPassword,
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
                      userRolePermissionModel.databaseId =
                          FirebaseAuth.instance.currentUser!.uid;
                      print(userRolePermissionModel.toJson());
                      await dataRef.update(userRolePermissionModel.toJson());
                      await adminDataRef
                          .update(userRolePermissionModel.toJson());
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
                    // print(FirebaseAuth.instance.currentUser!.uid);
                    print(userRolePermissionModel.toJson());
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
