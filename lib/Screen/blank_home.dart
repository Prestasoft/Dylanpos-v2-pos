import 'package:flutter/material.dart';
import 'Widgets/Constant Data/constant.dart';

class BlankHome extends StatelessWidget {
  const BlankHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fondo oscuro con partículas doradas y la imagen promocional de Victor Guzmán
    return Container(
      decoration: const BoxDecoration(
        color: kAppDarkBg,
        image: DecorationImage(
          image: AssetImage('images/fondo_login.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kAppGoldPrimary.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'images/portada_victor.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
