#!/bin/bash

# Script para ejecutar el verificador de método de pago
# Creado el: 5 de julio de 2025

echo "==================================="
echo "VERIFICADOR DE MÉTODOS DE PAGO"
echo "==================================="
echo "Este script ejecutará una herramienta para verificar si las ventas"
echo "tienen correctamente asignado el método de pago."
echo ""

cd "$(dirname "$0")"
cd ../..

# Asegurarse de que las dependencias están instaladas
echo "Verificando dependencias..."
flutter pub get

# Ejecutar la herramienta
echo "Ejecutando verificador de métodos de pago..."
flutter run -d chrome --web-renderer html lib/Screen/Inventory\ Sales/verificador_metodo_pago.dart

# Nota: También se puede ejecutar en otros dispositivos cambiando -d chrome por:
# -d windows (para Windows)
# -d macos (para macOS)
# -d <ID-de-dispositivo-Android> (para Android)
