import 'dart:ui';

import 'package:flutter/material.dart';

// Custom dotted border
class CustomDottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;

  const CustomDottedBorder({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              color: _theme.colorScheme.primaryContainer, // Set the background color here
              borderRadius: BorderRadius.circular(12)),
        ),
        CustomPaint(
          painter: DottedBorderPainter(color: color),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        ),
      ],
    );
  }
}

// For custom dotted widget
class DottedBorderPainter extends CustomPainter {
  final Color color;

  DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double dashWidth = 4, dashSpace = 4;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final PathMetrics metrics = path.computeMetrics();
    for (PathMetric metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
