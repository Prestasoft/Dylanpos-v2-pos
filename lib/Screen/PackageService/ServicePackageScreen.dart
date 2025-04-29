import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class ServicePackageScreen extends StatelessWidget {
  const ServicePackageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paquete de Servicio"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Pantalla principal para Paquete de Servicio"),
            // Puedes agregar más elementos aquí, como botones para navegar a 'Registrar' o 'Ver Paquetes'
          ],
        ),
      ),
    );
  }
}
