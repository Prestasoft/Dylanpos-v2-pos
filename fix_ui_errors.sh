#!/bin/bash

# Script para aplicar las soluciones de errores de UI en Dylanpos-v2-pos

echo "Aplicando soluciones para errores de UI en Dylanpos-v2-pos..."

# 1. Descargar fuentes NotoSansCJK si no existen
NOTO_DIR="./fonts/NotoSansCJK"
if [ ! -d "$NOTO_DIR" ]; then
    echo "Creando directorio para NotoSansCJK..."
    mkdir -p "$NOTO_DIR"
    echo "Por favor, descarga manualmente las fuentes NotoSansCJK desde https://www.google.com/get/noto/ y colócalas en $NOTO_DIR"
fi

# 2. Limpiar y actualizar el proyecto Flutter
echo "Limpiando el proyecto Flutter..."
flutter clean

echo "Actualizando dependencias..."
flutter pub get

# 3. Ejecutar test de manejo de imágenes
echo "Puedes probar el manejo de errores de imágenes ejecutando:"
echo "flutter run -t lib/test_image_handling.dart"

echo "Soluciones aplicadas correctamente. Ejecuta la aplicación para verificar que los errores han sido resueltos."
