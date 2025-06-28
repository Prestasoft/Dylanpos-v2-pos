import 'package:flutter/material.dart';

class BlankHome extends StatelessWidget {
  const BlankHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/fondo2.webp'), // Fondo igual al login
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Image.asset(
            'images/loginLogo2.png',
            width: 400, // Aumenta el tamaño del logo
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
