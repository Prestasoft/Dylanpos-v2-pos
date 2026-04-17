import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task_theme_provider.dart';

/// Colores temáticos para las pantallas del panel de empleados.
///
/// Uso: `final tc = TaskColors.of(context);`
/// Luego: `tc.scaffold`, `tc.card`, `tc.textPrimary`, etc.
class TaskColors {
  final bool isDark;

  const TaskColors._({required this.isDark});

  factory TaskColors.of(BuildContext context) {
    final isDark = context.watch<TaskThemeProvider>().isDark;
    return TaskColors._(isDark: isDark);
  }

  /// Leer sin suscribirse (para callbacks, no rebuild)
  factory TaskColors.read(BuildContext context) {
    final isDark = context.read<TaskThemeProvider>().isDark;
    return TaskColors._(isDark: isDark);
  }

  // ── Fondos ──
  Color get scaffold      => isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get appBar        => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get card          => isDark ? const Color(0xFF2A2A2A) : Colors.white;
  Color get cardAlt       => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);
  Color get surface       => isDark ? const Color(0xFF333333) : const Color(0xFFF0F0F0);

  // ── Texto ──
  Color get textPrimary   => isDark ? const Color(0xFFE0E0E0) : Colors.black;
  Color get textSecondary => isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;
  Color get textHint      => isDark ? const Color(0xFF757575) : Colors.grey.shade400;

  // ── AppBar ──
  Color get appBarTitle    => isDark ? const Color(0xFFE0E0E0) : Colors.black;
  Color get appBarIcon     => isDark ? const Color(0xFFBDBDBD) : Colors.black54;
  Color get appBarSubtitle => isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

  // ── Bordes y dividers ──
  Color get border        => isDark ? const Color(0xFF424242) : Colors.grey.shade300;
  Color get divider       => isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200;

  // ── Badges / chips ──
  Color get chipBg        => isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE);
  Color get chipText      => isDark ? const Color(0xFFBDBDBD) : Colors.grey.shade700;

  // ── TabBar ──
  Color get tabSelected   => isDark ? Colors.deepPurple.shade300 : Colors.deepPurple;
  Color get tabUnselected => isDark ? const Color(0xFF757575) : Colors.grey;
  Color get tabIndicator  => isDark ? Colors.deepPurple.shade300 : Colors.deepPurple;

  // ── Progress bar background ──
  Color get progressBg    => isDark ? const Color(0xFF424242) : Colors.grey.shade200;

  // ── Sombras ──
  Color get shadow        => isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);

  // ── Diálogos ──
  Color get dialogBg      => isDark ? const Color(0xFF2A2A2A) : Colors.white;

  // ── Banners de alerta (se mantienen iguales en ambos modos para consistencia) ──
  // Los colores de urgencia (rojo/amarillo/verde) son semánticos y no cambian.

  // ── Helpers ──
  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;

  IconThemeData get appBarIconTheme => IconThemeData(color: appBarIcon);
}

/// Botón toggle sol/luna para el AppBar de pantallas de Mi Panel.
class TaskThemeToggle extends StatelessWidget {
  const TaskThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<TaskThemeProvider>().isDark;
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(isDark),
          color: isDark ? const Color(0xFFFFD54F) : Colors.blueGrey,
        ),
      ),
      tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
      onPressed: () => context.read<TaskThemeProvider>().toggle(),
    );
  }
}
