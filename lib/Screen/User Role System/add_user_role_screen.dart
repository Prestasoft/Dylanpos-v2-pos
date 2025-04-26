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
  UserRoleModel? userRoleModel;

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
  List<Permission> permissions = [Permission(title: 'Sale'), Permission(title: 'Parties'), Permission(title: 'Purchase'), Permission(title: 'Product'), Permission(title: 'Profile Edit'), Permission(title: 'Add Expense'), Permission(title: 'Loss Profit'), Permission(title: 'Due List'), Permission(title: 'Stock'), Permission(title: 'Reports'), Permission(title: 'Sales List'), Permission(title: 'Purchase List'), Permission(title: 'HRM')];

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
    for (var data in permissions) {
      if (data.title == 'Sale') {
        data.view = widget.userRoleModel?.saleView ?? false;
        data.edit = widget.userRoleModel?.saleEdit ?? false;
        data.delete = widget.userRoleModel?.saleDelete ?? false;
      } else if (data.title == 'Parties') {
        data.view = widget.userRoleModel?.partiesView ?? false;
        data.edit = widget.userRoleModel?.partiesEdit ?? false;
        data.delete = widget.userRoleModel?.partiesDelete ?? false;
      } else if (data.title == 'Purchase') {
        data.view = widget.userRoleModel?.purchaseView ?? false;
        data.edit = widget.userRoleModel?.purchaseEdit ?? false;
        data.delete = widget.userRoleModel?.purchaseDelete ?? false;
      } else if (data.title == 'Product') {
        data.view = widget.userRoleModel?.productView ?? false;
        data.edit = widget.userRoleModel?.productEdit ?? false;
        data.delete = widget.userRoleModel?.productDelete ?? false;
      } else if (data.title == 'Profile Edit') {
        data.view = widget.userRoleModel?.profileEditView ?? false;
        data.edit = widget.userRoleModel?.profileEditEdit ?? false;
        data.delete = widget.userRoleModel?.profileEditDelete ?? false;
      } else if (data.title == 'Add Expense') {
        data.view = widget.userRoleModel?.addExpenseView ?? false;
        data.edit = widget.userRoleModel?.addExpenseEdit ?? false;
        data.delete = widget.userRoleModel?.addExpenseDelete ?? false;
      } else if (data.title == 'Loss Profit') {
        data.view = widget.userRoleModel?.lossProfitView ?? false;
        data.edit = widget.userRoleModel?.lossProfitEdit ?? false;
        data.delete = widget.userRoleModel?.lossProfitDelete ?? false;
      } else if (data.title == 'Due List') {
        data.view = widget.userRoleModel?.dueListView ?? false;
        data.edit = widget.userRoleModel?.dueListEdit ?? false;
        data.delete = widget.userRoleModel?.dueListDelete ?? false;
      } else if (data.title == 'Stock') {
        data.view = widget.userRoleModel?.stockView ?? false;
        data.edit = widget.userRoleModel?.stockEdit ?? false;
        data.delete = widget.userRoleModel?.stockDelete ?? false;
      } else if (data.title == 'Reports') {
        data.view = widget.userRoleModel?.reportsView ?? false;
        data.edit = widget.userRoleModel?.reportsEdit ?? false;
        data.delete = widget.userRoleModel?.reportsDelete ?? false;
      } else if (data.title == 'Sales List') {
        data.view = widget.userRoleModel?.salesListView ?? false;
        data.edit = widget.userRoleModel?.salesListEdit ?? false;
        data.delete = widget.userRoleModel?.salesListDelete ?? false;
      } else if (data.title == 'Purchase List') {
        data.view = widget.userRoleModel?.purchaseListView ?? false;
        data.edit = widget.userRoleModel?.purchaseListEdit ?? false;
        data.delete = widget.userRoleModel?.purchaseListDelete ?? false;
      } else if (data.title == 'HRM') {
        data.view = widget.userRoleModel?.hrmView ?? false;
        data.edit = widget.userRoleModel?.hrmEdit ?? false;
        data.delete = widget.userRoleModel?.hrmDelete ?? false;
      }
    }
  }

  bool hidePassword = true;
  bool confirmHidePassword = true;

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
                    itemCount: permissions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 10),
                          child: Text(
                            permissions[index].title,
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
                                checkboxTheme: const CheckboxThemeData(side: BorderSide(color: kNeutral500)),
                              ),
                              child: Checkbox(
                                value: permissions[index].view,
                                onChanged: (bool? value) {
                                  setState(() {
                                    permissions[index].view = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Theme(
                              data: theme.copyWith(
                                checkboxTheme: const CheckboxThemeData(side: BorderSide(color: kNeutral500)),
                              ),
                              child: Checkbox(
                                value: permissions[index].edit,
                                onChanged: (bool? value) {
                                  setState(() {
                                    permissions[index].edit = value ?? false;
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
                                value: permissions[index].delete,
                                onChanged: (bool? value) {
                                  setState(() {
                                    permissions[index].delete = value ?? false;
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
                            icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off))),
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
                        return lang.S.of(context).passwordAndConfirmPasswordDoesNotMatch;
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
                          icon: Icon(confirmHidePassword ? Icons.visibility : Icons.visibility_off)),
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
                style: ElevatedButton.styleFrom(minimumSize: Size(screenWidth, 48)),
                onPressed: (() async {
                  UserRoleModel userRolePermissionModel = UserRoleModel();

                  for (var data in permissions) {
                    if (data.title == 'Sale') {
                      userRolePermissionModel.saleEdit = data.edit;
                      userRolePermissionModel.saleView = data.view;
                      userRolePermissionModel.saleDelete = data.delete;
                    } else if (data.title == 'Parties') {
                      userRolePermissionModel.partiesEdit = data.edit;
                      userRolePermissionModel.partiesView = data.view;
                      userRolePermissionModel.partiesDelete = data.delete;
                    } else if (data.title == 'Purchase') {
                      userRolePermissionModel.purchaseEdit = data.edit;
                      userRolePermissionModel.purchaseView = data.view;
                      userRolePermissionModel.purchaseDelete = data.delete;
                    } else if (data.title == 'Product') {
                      userRolePermissionModel.productEdit = data.edit;
                      userRolePermissionModel.productView = data.view;
                      userRolePermissionModel.productDelete = data.delete;
                    } else if (data.title == 'Profile Edit') {
                      userRolePermissionModel.profileEditEdit = data.edit;
                      userRolePermissionModel.profileEditView = data.view;
                      userRolePermissionModel.profileEditDelete = data.delete;
                    } else if (data.title == 'Add Expense') {
                      userRolePermissionModel.addExpenseEdit = data.edit;
                      userRolePermissionModel.addExpenseView = data.view;
                      userRolePermissionModel.addExpenseDelete = data.delete;
                    } else if (data.title == 'Loss Profit') {
                      userRolePermissionModel.lossProfitEdit = data.edit;
                      userRolePermissionModel.lossProfitView = data.view;
                      userRolePermissionModel.lossProfitDelete = data.delete;
                    } else if (data.title == 'Due List') {
                      userRolePermissionModel.dueListEdit = data.edit;
                      userRolePermissionModel.dueListView = data.view;
                      userRolePermissionModel.dueListDelete = data.delete;
                    } else if (data.title == 'Stock') {
                      userRolePermissionModel.stockEdit = data.edit;
                      userRolePermissionModel.stockView = data.view;
                      userRolePermissionModel.stockDelete = data.delete;
                    } else if (data.title == 'Reports') {
                      userRolePermissionModel.reportsEdit = data.edit;
                      userRolePermissionModel.reportsView = data.view;
                      userRolePermissionModel.reportsDelete = data.delete;
                    } else if (data.title == 'Sales List') {
                      userRolePermissionModel.salesListEdit = data.edit;
                      userRolePermissionModel.salesListView = data.view;
                      userRolePermissionModel.salesListDelete = data.delete;
                    } else if (data.title == 'Purchase List') {
                      userRolePermissionModel.purchaseListEdit = data.edit;
                      userRolePermissionModel.purchaseListView = data.view;
                      userRolePermissionModel.purchaseListDelete = data.delete;
                    } else if (data.title == 'HRM') {
                      userRolePermissionModel.hrmEdit = data.edit;
                      userRolePermissionModel.hrmView = data.view;
                      userRolePermissionModel.hrmDelete = data.delete;
                    }
                  }
                  print(userRolePermissionModel.toJson());

                  //Check if no true in is permission array
                  if (permissions.every((element) => element.view == false && element.edit == false && element.delete == false)) {
                    EasyLoading.showError(lang.S.of(context).youHaveToGivePermission);
                    return;
                  }
                  if (widget.userRoleModel != null) {
                    try {
                      EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                      UserRoleRepo repo = UserRoleRepo();
                      String adminRoleKey = '';
                      String userRoleKey = '';
                      var adminRoleList = await repo.getAllUserRoleFromAdmin();
                      var userRoleList = await repo.getAllUserRole();
                      for (var element in adminRoleList) {
                        if (element.email == (widget.userRoleModel?.email ?? "")) {
                          adminRoleKey = element.userKey ?? '';
                          break;
                        }
                      }
                      for (var element in userRoleList) {
                        if (element.email == (widget.userRoleModel?.email ?? "")) {
                          userRoleKey = element.userKey ?? '';
                          break;
                        }
                      }

                      DatabaseReference dataRef = FirebaseDatabase.instance.ref("$constUserId/User Role/$userRoleKey");
                      DatabaseReference adminDataRef = FirebaseDatabase.instance.ref("Admin Panel/User Role/$adminRoleKey");
                      userRolePermissionModel.email = emailController.text;
                      userRolePermissionModel.userTitle = titleController.text;
                      userRolePermissionModel.userRoleName = userRoleName.text;
                      userRolePermissionModel.databaseId = FirebaseAuth.instance.currentUser!.uid;
                      await dataRef.update(userRolePermissionModel.toJson());
                      await adminDataRef.update(userRolePermissionModel.toJson());
                      ref.refresh(userRoleProvider);

                      EasyLoading.showSuccess(lang.S.of(context).successfullyUpdated, duration: const Duration(milliseconds: 500));
                      // ignore: use_build_context_synchronously
                      // Navigator.pop(context);
                      GoRouter.of(context).pop();
                    } catch (e) {
                      EasyLoading.dismiss();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                    return;
                  }
                  if (validateAndSave()) {
                    print(userRolePermissionModel.toJson());
                    // UserRoleModel userRoleData = UserRoleModel(
                    //   email: emailController.text,
                    //   userTitle: titleController.text,
                    //   databaseId: FirebaseAuth.instance.currentUser!.uid,
                    //   salePermission: salePermission,
                    //   partiesPermission: partiesPermission,
                    //   purchasePermission: purchasePermission,
                    //   productPermission: productPermission,
                    //   profileEditPermission: profileEditPermission,
                    //   addExpensePermission: addExpensePermission,
                    //   lossProfitPermission: lossProfitPermission,
                    //   dueListPermission: dueListPermission,
                    //   stockPermission: stockPermission,
                    //   reportsPermission: reportsPermission,
                    //   salesListPermission: salesListPermission,
                    //   purchaseListPermission: purchaseListPermission,
                    // );
                    userRolePermissionModel.email = emailController.text;
                    userRolePermissionModel.userTitle = titleController.text;
                    userRolePermissionModel.databaseId = FirebaseAuth.instance.currentUser!.uid;
                    // print(FirebaseAuth.instance.currentUser!.uid);
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
}

void signUp({required BuildContext context, required String email, required String password, required WidgetRef ref, required UserRoleModel userRoleModel}) async {
  EasyLoading.show(status: '${lang.S.of(context).registering}....');
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

    if (userCredential.additionalUserInfo!.isNewUser) {
      await FirebaseDatabase.instance.ref().child(userRoleModel.databaseId ?? "").child('User Role').push().set(userRoleModel.toJson());
      await FirebaseDatabase.instance.ref().child('Admin Panel').child('User Role').push().set(userRoleModel.toJson());

      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(seconds: 1));
      try {
        await Future.delayed(const Duration(seconds: 1));
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: mainLoginEmail, password: mainLoginPassword);
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
              content: Text('${lang.S.of(context).wrongPasswordProvidedForThatUser}.'),
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
          content: Text('${lang.S.of(context).theAccountAlreadyExistsForThatEmail}.'),
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
