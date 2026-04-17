import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';

// Colores del sistema de diseño
const Color _doradoPrincipal = Color(0xFFD4A853);
const Color _doradoOscuro = Color(0xFFC9973D);

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Detectar si estamos en la pantalla de login
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isLoginPage = currentRoute == '/' || currentRoute.contains('login');

    return Consumer(
      builder: (_, ref, watch) {
        final settingProvider = ref.watch(generalSettingProvider);
        return settingProvider.when(
          data: (setting) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: isLoginPage ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isLoginPage
                        ? _doradoPrincipal.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: isMobile
                  ? _buildMobileFooter(context, isLoginPage)
                  : _buildDesktopFooter(context, isLoginPage),
            );
          },
          error: (e, stack) {
            return const SizedBox.shrink();
          },
          loading: () {
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  /// Footer para móvil - Layout vertical compacto
  Widget _buildMobileFooter(BuildContext context, bool isLoginPage) {
    final textColor = isLoginPage ? Colors.white70 : Colors.grey[600];
    final accentColor = isLoginPage ? _doradoPrincipal : _doradoOscuro;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila 1: Copyright + Versión
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '© 2025 Victor Guzmán',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _buildVersionBadge(isLoginPage, compact: true),
          ],
        ),
        const SizedBox(height: 6),
        // Fila 2: Desarrollado por
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Desarrollado por ',
              style: TextStyle(
                fontSize: 10,
                color: textColor,
              ),
            ),
            Text(
              'PrestaSoft SRL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Footer para desktop - Layout horizontal elegante
  Widget _buildDesktopFooter(BuildContext context, bool isLoginPage) {
    final textColor = isLoginPage ? Colors.white70 : Colors.grey[600];
    final accentColor = isLoginPage ? _doradoPrincipal : _doradoOscuro;

    return Row(
      children: [
        // Izquierda: Copyright
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.copyright_rounded,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                '2025 Victor Guzmán Fotografía SRL',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 14,
                color: isLoginPage
                    ? Colors.white24
                    : Colors.grey.shade300,
              ),
              const SizedBox(width: 8),
              Text(
                'Todos los derechos reservados',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Centro: Versión
        _buildVersionBadge(isLoginPage, compact: false),
        const SizedBox(width: 16),
        // Derecha: Desarrollado por
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Desarrollado por ',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                'PrestaSoft SRL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Badge de versión con estilo dorado
  Widget _buildVersionBadge(bool isLoginPage, {required bool compact}) {
    final bgColor = isLoginPage
        ? _doradoPrincipal.withValues(alpha: 0.2)
        : _doradoPrincipal.withValues(alpha: 0.1);
    final borderColor = isLoginPage
        ? _doradoPrincipal.withValues(alpha: 0.5)
        : _doradoPrincipal.withValues(alpha: 0.3);
    final textColor = isLoginPage ? _doradoPrincipal : _doradoOscuro;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(
              Icons.verified_rounded,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            'v2.1.461',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
