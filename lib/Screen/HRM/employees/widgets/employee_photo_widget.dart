import 'dart:convert';
import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar foto de empleado
/// Soporta URLs normales y base64 (con o sin prefijo data:image)
class EmployeePhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final Color? fallbackIconColor;
  final BoxFit fit;

  const EmployeePhotoWidget({
    super.key,
    this.photoUrl,
    this.size = 40,
    this.borderRadius = 8,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.fallbackIconSize = 24,
    this.fallbackIconColor,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(context),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return _buildFallback(context);
    }

    // Verificar si es base64 (con o sin prefijo data:image)
    if (_isBase64Image(photoUrl!)) {
      return _buildBase64Image(context);
    }

    // URL normal
    return Image.network(
      photoUrl!,
      fit: fit,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoading(context);
      },
    );
  }

  bool _isBase64Image(String url) {
    // Tiene prefijo data:image
    if (url.startsWith('data:image')) return true;
    // Es string base64 puro (sin URL válida)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Intentar decodificar para verificar si es base64 válido
      try {
        final decoded = base64.decode(url.substring(0, 100 > url.length ? url.length : 100));
        // JPEG magic bytes: 0xFF 0xD8
        // PNG magic bytes: 0x89 0x50 0x4E 0x47
        if (decoded.isNotEmpty) {
          if ((decoded[0] == 0xFF && decoded.length > 1 && decoded[1] == 0xD8) ||
              (decoded[0] == 0x89 && decoded.length > 3 && decoded[1] == 0x50)) {
            return true;
          }
        }
      } catch (_) {
        // No es base64 válido
      }
    }
    return false;
  }

  Widget _buildBase64Image(BuildContext context) {
    try {
      String base64Data = photoUrl!;

      // Remover prefijo data:image si existe
      if (base64Data.startsWith('data:image')) {
        final commaIndex = base64Data.indexOf(',');
        if (commaIndex != -1) {
          base64Data = base64Data.substring(commaIndex + 1);
        }
      }

      // Limpiar caracteres no válidos
      base64Data = base64Data.replaceAll(RegExp(r'\s'), '');

      final bytes = base64.decode(base64Data);

      return Image.memory(
        bytes,
        fit: fit,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } catch (e) {
      return _buildFallback(context);
    }
  }

  Widget _buildFallback(BuildContext context) {
    return Center(
      child: Icon(
        fallbackIcon,
        size: fallbackIconSize,
        color: fallbackIconColor ?? Colors.grey[400],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Variante circular del widget de foto con soporte para iniciales
class EmployeePhotoCircle extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final Color? fallbackIconColor;
  final String? employeeName; // Para mostrar iniciales si no hay foto
  final bool showBadge; // Indicador si tiene foto o no

  const EmployeePhotoCircle({
    super.key,
    this.photoUrl,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.fallbackIconSize = 24,
    this.fallbackIconColor,
    this.employeeName,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Stack(
      children: [
        ClipOval(
          child: hasPhoto
              ? EmployeePhotoWidget(
                  photoUrl: photoUrl,
                  size: radius * 2,
                  borderRadius: radius,
                  backgroundColor: backgroundColor,
                  fallbackIcon: fallbackIcon,
                  fallbackIconSize: fallbackIconSize,
                  fallbackIconColor: fallbackIconColor,
                )
              : _buildInitialsAvatar(),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: hasPhoto ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                hasPhoto ? Icons.check : Icons.camera_alt,
                size: radius * 0.3,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials(employeeName ?? '');
    final bgColor = _getColorFromName(employeeName ?? '');

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.grey;
    final colors = [
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEF5350), // Red
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFF8D6E63), // Brown
      const Color(0xFF78909C), // Blue Grey
      const Color(0xFFEC407A), // Pink
    ];
    final index = name.codeUnits.fold<int>(0, (sum, c) => sum + c) % colors.length;
    return colors[index];
  }
}

/// Widget para preview de foto con opción de editar/eliminar
class EmployeePhotoPreview extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const EmployeePhotoPreview({
    super.key,
    this.photoUrl,
    this.size = 120,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EmployeePhotoWidget(
          photoUrl: photoUrl,
          size: size,
          borderRadius: 12,
          fallbackIconSize: size * 0.4,
        ),
        if (showActions && (photoUrl != null && photoUrl!.isNotEmpty))
          Positioned(
            right: 0,
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  _ActionButton(
                    icon: Icons.edit,
                    onTap: onEdit!,
                    color: Colors.blue,
                  ),
                if (onDelete != null)
                  _ActionButton(
                    icon: Icons.delete,
                    onTap: onDelete!,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
