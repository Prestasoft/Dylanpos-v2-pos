import 'package:flutter/material.dart';

class SantoDomingoHeader extends StatelessWidget {
  const SantoDomingoHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Text(
        'Santo Domingo',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.blue[800],
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              blurRadius: 2.0,
              color: Colors.blue.withOpacity(0.3),
              offset: const Offset(1, 1),
            )
          ],
        ),
      ),
    );
  }
}
