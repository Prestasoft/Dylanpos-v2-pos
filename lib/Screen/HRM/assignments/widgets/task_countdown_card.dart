import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../model/task_model.dart';

/// Card animada de una tarea con contador en vivo y pulso visual.
///
/// Comportamiento por % de tiempo consumido:
///   <50%  → verde, pulso suave cada 3s
///   50-80% → amarillo, pulso cada 1.5s
///   >80%  → rojo, pulso rápido 0.6s + shake horizontal + glow
///   >100% → rojo oscuro fijo + "VENCIDA HACE Xh"
///   completada → gris con check
class TaskCountdownCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onComplete;
  final String? customerName;
  final String? serviceName;

  const TaskCountdownCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.customerName,
    this.serviceName,
  });

  @override
  State<TaskCountdownCard> createState() => _TaskCountdownCardState();
}

class _TaskCountdownCardState extends State<TaskCountdownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _shakeAnim;
  Timer? _tickTimer;
  Duration _remaining = Duration.zero;
  double _progress = 0;
  TaskUrgency _urgency = TaskUrgency.normal;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _shakeAnim = Tween(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.elasticIn),
    );
    _updateState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateState());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateState() {
    if (!mounted) return;
    final now = DateTime.now();
    final newRemaining = widget.task.timeRemaining(now);
    final newProgress = widget.task.progress(now);
    final newUrgency = widget.task.urgency;

    if (newUrgency != _urgency) {
      _urgency = newUrgency;
      _configureAnimation();
    }

    setState(() {
      _remaining = newRemaining;
      _progress = newProgress;
    });
  }

  void _configureAnimation() {
    _pulseCtrl.stop();
    switch (_urgency) {
      case TaskUrgency.normal:
        _pulseCtrl.duration = const Duration(seconds: 3);
        _pulseCtrl.repeat(reverse: true);
        break;
      case TaskUrgency.warning:
        _pulseCtrl.duration = const Duration(milliseconds: 1500);
        _pulseCtrl.repeat(reverse: true);
        break;
      case TaskUrgency.critical:
        _pulseCtrl.duration = const Duration(milliseconds: 600);
        _pulseCtrl.repeat(reverse: true);
        break;
      case TaskUrgency.overdue:
        _pulseCtrl.duration = const Duration(milliseconds: 1200);
        _pulseCtrl.repeat(reverse: true);
        break;
      case TaskUrgency.done:
        _pulseCtrl.stop();
        break;
    }
  }

  Color get _baseColor {
    switch (_urgency) {
      case TaskUrgency.normal:
        return const Color(0xFF10B981);
      case TaskUrgency.warning:
        return const Color(0xFFF59E0B);
      case TaskUrgency.critical:
        return const Color(0xFFEF4444);
      case TaskUrgency.overdue:
        return const Color(0xFF991B1B);
      case TaskUrgency.done:
        return Colors.grey;
    }
  }

  String get _timeLabel {
    if (_urgency == TaskUrgency.done) return 'Completada';
    if (_urgency == TaskUrgency.overdue) {
      final over = _remaining.abs();
      if (over.inHours > 0) return 'VENCIDA hace ${over.inHours}h ${over.inMinutes % 60}m';
      if (over.inMinutes > 0) return 'VENCIDA hace ${over.inMinutes}m';
      return 'VENCIDA hace ${over.inSeconds}s';
    }
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final dx = (_urgency == TaskUrgency.critical || _urgency == TaskUrgency.overdue)
            ? _shakeAnim.value
            : 0.0;
        final opacity = _urgency == TaskUrgency.done ? 1.0 : _pulseAnim.value;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            if (_urgency == TaskUrgency.critical || _urgency == TaskUrgency.overdue)
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: cliente + servicio
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      _urgency == TaskUrgency.done ? Icons.check : Icons.person,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName ?? 'Cliente',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.serviceName != null)
                          Text(
                            widget.serviceName!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Badge designación
                  if (widget.task.designationName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.task.designationName!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Contador + barra de progreso
              Row(
                children: [
                  Icon(
                    _urgency == TaskUrgency.done ? Icons.check_circle : Icons.timer,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeLabel,
                    style: TextStyle(
                      fontSize: _urgency == TaskUrgency.overdue ? 14 : 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  if (_urgency != TaskUrgency.done)
                    Text(
                      '${(_progress * 100).clamp(0, 999).toInt()}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
              if (_urgency != TaskUrgency.done) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],

              // Botón completar
              if (_urgency != TaskUrgency.done) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('COMPLETAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: widget.onComplete,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
