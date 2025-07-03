import 'package:flutter/material.dart';

class BlankHome extends StatelessWidget {
  const BlankHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fondo con imagen y logo centrado
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/fondo2.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Image.asset(
          'images/loginLogo2.png',
          width: 400,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
