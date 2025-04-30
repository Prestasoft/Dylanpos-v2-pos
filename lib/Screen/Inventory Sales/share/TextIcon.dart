import 'package:flutter/material.dart';

class IconTextRow extends StatelessWidget {
  final IconData icon; // Tipo de ícono (IconData)
  final String text;   // El texto a mostrar

  const IconTextRow({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey), // Muestra el ícono pasado
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
