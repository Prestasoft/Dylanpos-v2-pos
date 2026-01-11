import 'package:flutter/material.dart';

class ReservationTypeLegend extends StatelessWidget {
  const ReservationTypeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: Colors.amber, label: 'Fiesta'),
        SizedBox(width: 16),
        _LegendDot(color: Colors.blue, label: 'Estudio'),
        SizedBox(width: 16),
        _LegendDot(color: Colors.purple, label: 'Exterior'),
        SizedBox(width: 16),
        _LegendDot(color: Color(0xFF4CAF50), label: 'Renta'), // Verde elegante
        SizedBox(width: 16),
        _LegendDot(color: Colors.grey, label: 'Otro'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
