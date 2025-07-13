import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Repository/profile_details_repo.dart';

import '../Screen/Authentication/add_profile.dart';
import '../services/audit_service.dart';
import '../const.dart';
import '../model/user_role_model.dart';

final logInProvider = ChangeNotifierProvider((ref) => LogInRepo());

class LogInRepo extends ChangeNotifier {
  String email = '';
  String password = '';

  Future<void> signIn(BuildContext context) async {
    EasyLoading.show(status: 'Login...');
    try {
      mainLoginEmail = email;
      mainLoginPassword = password;
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) async {
        if (await checkSubUser()) {
          EasyLoading.showSuccess('Successful');
          setUserDataOnLocalData(
              uid: constUserId,
              subUserTitle: constSubUserTitle,
              isSubUser: true);
          putUserDataImidiyate(uid: constUserId, title: '', isSubUse: true);
          
          // Configurar AuditService para sub-usuario
          await AuditService().logLogin(
            constUserId, 
            constSubUserTitle.isNotEmpty ? constSubUserTitle : 'Sub Usuario', 
            email
          );
          
          // Navigator.of(context).pushNamed(MtHomeScreen.route);
          // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MtHomeScreen()), (Route<dynamic> route) => false);
          context.go('/blank-home');
        } else {
          EasyLoading.showSuccess('Successful');
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          final currentUserEmail = FirebaseAuth.instance.currentUser!.email ?? email;
          
          await setUserDataOnLocalData(
              uid: currentUserId,
              subUserTitle: '',
              isSubUser: false);
          putUserDataImidiyate(
              uid: currentUserId,
              title: '',
              isSubUse: false);

          // Obtener información del perfil para el nombre de usuario
          String userName = 'Usuario Principal';
          try {
            final profileData = await ProfileRepo().getDetails();
            userName = profileData.companyName.isNotEmpty ? profileData.companyName : 'Usuario Principal';
          } catch (e) {
            // Si no se puede obtener el perfil, usar el email como nombre
            userName = currentUserEmail.split('@')[0];
          }
          
          // Configurar AuditService para usuario principal
          await AuditService().logLogin(
            currentUserId, 
            userName, 
            currentUserEmail
          );

          if (await ProfileRepo().isProfileSetupDone()) {
            // Navigator.of(context).pushNamed(MtHomeScreen.route);
            // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MtHomeScreen()), (Route<dynamic> route) => false);
            context.go('/blank-home');
          } else {
            // const ProfileAdd().launch(context);
            context.go(ProfileAdd.route);
          }
        }
      });
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError(e.message.toString());
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user found for that email.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong password provided for that user.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      EasyLoading.showError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> checkSubUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSubUser = false;
    await FirebaseDatabase.instance
        .ref('Admin Panel')
        .child('User Role')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data =
            UserRoleModel.fromJson(jsonDecode(jsonEncode(element.value)));
        if (data.email == email &&
            data.databaseId != null &&
            data.databaseId != '') {
          prefs.setString('userPermission', json.encode(data));
          finalUserRoleModel = data;

          constUserId = data.databaseId ?? '';
          constSubUserTitle = data.userTitle ?? '';
          isSubUser = true;
          return;
        }
      }
    });
    return isSubUser;
  }
}

Future<void> sendEmailVerification() async {
  User? user = FirebaseAuth.instance.currentUser;

  try {
    await user?.sendEmailVerification();
  } catch (e) {
  }
}
