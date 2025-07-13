import 'package:flutter/material.dart';

class SantoDomingoTitle extends StatelessWidget {
  final String title;
  final double fontSize;
  final Color? color;

  const SantoDomingoTitle({
    Key? key, 
    this.title = 'Santo Domingo', 
    this.fontSize = 24,
    this.color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4)
          )
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: color ?? Colors.blue[800],
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(1, 1)
            )
          ]
        ),
      ),
    );
  }
}
