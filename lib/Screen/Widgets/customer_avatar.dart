import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar la foto de un cliente.
/// Soporta URLs normales y fotos en formato base64 (data:image/...)
class CustomerAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData fallbackIcon;
  final Color? backgroundColor;

  const CustomerAvatar({
    Key? key,
    this.imageUrl,
    this.size = 40,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si no hay imagen, mostrar icono por defecto
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context);
    }

    // Detectar si es una imagen base64
    if (imageUrl!.startsWith('data:image')) {
      return _buildBase64Image(context);
    }

    // Es una URL normal (Firebase, etc.)
    return _buildNetworkImage(context);
  }

  Widget _buildBase64Image(BuildContext context) {
    try {
      // Extraer el base64 del data URL
      String base64String = imageUrl!;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      Uint8List imageBytes = base64.decode(base64String);

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.grey[200],
        ),
        child: ClipOval(
          child: Image.memory(
            imageBytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback(context);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[CustomerAvatar] Error decodificando base64: $e');
      return _buildFallback(context);
    }
  }

  Widget _buildNetworkImage(BuildContext context) {
    // Verificar si es la imagen por defecto de Firebase (blank profile)
    if (imageUrl!.contains('blank-profile-picture')) {
      return _buildFallback(context);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[200],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(context);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[300],
      ),
      child: Icon(
        fallbackIcon,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}