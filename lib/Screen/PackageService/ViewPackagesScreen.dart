import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterPackageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Paquete"),
      ),
      body: Center(
        child: Text("Formulario para registrar un nuevo paquete"),
      ),
    );
  }
}
