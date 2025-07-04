import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Imágenes')),
        body: const ImageTestWidget(),
      ),
    );
  }
}

class ImageTestWidget extends StatelessWidget {
  const ImageTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Prueba de imagen de billete de 1000 pesos:'),
        Image.asset(
          'images/dinero/billete_1000.png',
          width: 200,
          errorBuilder: (context, error, stackTrace) {
            print('Error cargando imagen: $error');
            return Column(
              children: [
                const Icon(Icons.error, color: Colors.red),
                Text('Error: $error'),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Prueba de imagen normal:'),
        Image.asset(
          'images/logo.png',
          width: 100,
          errorBuilder: (context, error, stackTrace) {
            print('Error cargando logo: $error');
            return Column(
              children: [
                const Icon(Icons.error, color: Colors.red),
                Text('Error logo: $error'),
              ],
            );
          },
        ),
      ],
    );
  }
}
