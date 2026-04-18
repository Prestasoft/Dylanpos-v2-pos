import 'dart:math';
import 'package:flutter/material.dart';
import 'task_theme.dart';

/// Banner con gráfico circular de consumo de maquillajes del día.
class MakeupDashboardBanner extends StatelessWidget {
  final int totalNeeded; // Total maquillajes necesarios hoy
  final int completed; // Completados
  final int inProgress; // En progreso (iniciados)
  final int notStarted; // Sin iniciar (asignados pero no iniciados)
  final int unassigned; // Sin asignar aún

  const MakeupDashboardBanner({
    super.key,
    required this.totalNeeded,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.unassigned,
  });

  @override
  Widget build(BuildContext context) {
    final tc = TaskColors.of(context);
    final total = totalNeeded > 0 ? totalNeeded : 1;
    final progressPercent = (completed / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.border.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: tc.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Gráfico circular
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _DonutPainter(
                completed: completed,
                inProgress: inProgress,
                notStarted: notStarted,
                unassigned: unassigned,
                total: total,
                isDark: tc.isDark,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tc.textPrimary,
                      ),
                    ),
                    Text(
                      'de $totalNeeded',
                      style: TextStyle(fontSize: 9, color: tc.textHint),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info derecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maquillajes del día',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tc.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(progressPercent * 100).toInt()}% completado',
                  style: TextStyle(fontSize: 11, color: tc.textHint),
                ),
                const SizedBox(height: 10),
                // Indicadores
                Row(
                  children: [
                    _indicator('✅', '$completed', 'Listos', const Color(0xFF10B981), tc),
                    const SizedBox(width: 10),
                    _indicator('🔵', '$inProgress', 'En curso', const Color(0xFF3B82F6), tc),
                    const SizedBox(width: 10),
                    _indicator('⏳', '$notStarted', 'Esperando', const Color(0xFFF59E0B), tc),
                    if (unassigned > 0) ...[
                      const SizedBox(width: 10),
                      _indicator('⚪', '$unassigned', 'Sin asignar', Colors.grey, tc),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicator(String emoji, String value, String label, Color color, TaskColors tc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Painter para el gráfico donut
class _DonutPainter extends CustomPainter {
  final int completed;
  final int inProgress;
  final int notStarted;
  final int unassigned;
  final int total;
  final bool isDark;

  _DonutPainter({
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.unassigned,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 10.0;
    const startAngle = -pi / 2;

    // Fondo del donut
    final bgPaint = Paint()
      ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    // Segmentos
    final segments = <_Segment>[
      _Segment(completed, const Color(0xFF10B981)),
      _Segment(inProgress, const Color(0xFF3B82F6)),
      _Segment(notStarted, const Color(0xFFF59E0B)),
      _Segment(unassigned, isDark ? Colors.grey.shade500 : Colors.grey.shade400),
    ];

    double currentAngle = startAngle;
    for (final seg in segments) {
      if (seg.count <= 0) continue;
      final sweep = (seg.count / total) * 2 * pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweep - 0.04, // pequeño gap entre segmentos
        false,
        paint,
      );
      currentAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.completed != completed || old.inProgress != inProgress ||
        old.notStarted != notStarted || old.unassigned != unassigned;
  }
}

class _Segment {
  final int count;
  final Color color;
  const _Segment(this.count, this.color);
}
