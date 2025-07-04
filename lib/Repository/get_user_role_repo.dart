import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../model/user_role_model.dart';

class UserRoleRepo {
  Future<List<UserRoleModel>> getAllUserRole() async {
    List<UserRoleModel> allUser = [];

    await FirebaseDatabase.instance.ref(FirebaseAuth.instance.currentUser!.uid).child('User Role').orderByKey().get().then((value) {
      for (var element in value.children) {
        try {
          var data = UserRoleModel.fromJson(jsonDecode(jsonEncode(element.value)));
          data.userKey = element.key;
          allUser.add(data);
        } catch (e) {
          debugPrint('Error parsing user role: $e');
        }
      }
    });
    return allUser;
  }

  Future<List<UserRoleModel>> getAllUserRoleFromAdmin() async {
    List<UserRoleModel> allUser = [];

    await FirebaseDatabase.instance.ref('Admin Panel').child('User Role').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = UserRoleModel.fromJson(jsonDecode(jsonEncode(element.value)));
        data.userKey = element.key;
        allUser.add(data);
      }
    });
    return allUser;
  }

  // Método para eliminar un usuario
  Future<bool> deleteUserRole(String userKey, String adminKey, String email) async {
    try {
      // Eliminar de la base de datos del usuario actual
      if (userKey.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref(FirebaseAuth.instance.currentUser!.uid)
            .child('User Role')
            .child(userKey)
            .remove();
      }

      // Eliminar del panel de administración
      if (adminKey.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref('Admin Panel')
            .child('User Role')
            .child(adminKey)
            .remove();
      }

      // Nota: No se puede eliminar directamente un usuario de Firebase Auth
      // sin privilegios de administrador. Se debe usar Firebase Admin SDK para eso.
      // Por seguridad, solo eliminamos los datos de rol, no la cuenta de usuario.
      
      return true;
    } catch (e) {
      debugPrint('Error eliminando usuario: $e');
      return false;
    }
  }

  // Método para verificar si un usuario puede ser eliminado
  Future<bool> canDeleteUser(UserRoleModel user) async {
    try {
      // No permitir eliminar si es el usuario actual
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      
      if (user.email == currentUserEmail) {
        return false;
      }

      // Verificar que el usuario tenga email
      if (user.email == null || user.email!.isEmpty) {
        return false;
      }

      // Verificar si es el único administrador (opcional - descomentar si necesitas esta validación)
      // final allUsers = await getAllUserRole();
      // final adminUsers = allUsers.where((u) => u.userRoleName?.toLowerCase().contains('admin') == true).toList();
      // if (adminUsers.length <= 1 && user.userRoleName?.toLowerCase().contains('admin') == true) {
      //   return false; // No permitir eliminar el último administrador
      // }

      return true;
    } catch (e) {
      debugPrint('Error verificando si se puede eliminar usuario: $e');
      return false;
    }
  }
}
