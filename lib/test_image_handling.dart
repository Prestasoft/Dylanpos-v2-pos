import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Este widget prueba el manejo de errores de carga de imágenes
/// y asegura que la imagen de respaldo se muestre cuando la imagen de red falla
class ImageErrorHandlingDemo extends StatelessWidget {
  const ImageErrorHandlingDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Manejo de Errores de Imagen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Probar imagen de red que debería fallar
            const Text('Imagen de red (debería fallar):'),
            SizedBox(
              width: 200,
              height: 200,
              child: CachedNetworkImage(
                imageUrl: 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Product%20No%20Image%2Fno-image-found-360x250.png?alt=media&token=9299964e-22b3-4d88-924e-5eeb285ae672',
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => Image.asset('images/blank_image.svg'),
              ),
            ),
            const SizedBox(height: 20),
            
            // Probar imagen local de respaldo directamente
            const Text('Imagen local de respaldo:'),
            SizedBox(
              width: 200,
              height: 200,
              child: Image.asset('images/blank_image.svg'),
            ),
          ],
        ),
      ),
    );
  }
}

// Función principal para probar el widget
void main() {
  runApp(const MaterialApp(
    home: ImageErrorHandlingDemo(),
  ));
}
