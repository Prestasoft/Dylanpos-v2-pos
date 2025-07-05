#!/bin/bash

# Script para ejecutar el analizador de método de pago
# Permite comparar el método esperado con el guardado en Firebase

echo "=== Analizador de Método de Pago ==="
echo ""
echo "Esta herramienta permite verificar si una factura específica"
echo "guardó correctamente el método de pago que se seleccionó."
echo ""
echo "Instrucciones:"
echo "1. Ingrese el número de factura a verificar"
echo "2. Ingrese el método de pago que seleccionó en la pantalla de ventas"
echo "3. La herramienta verificará si coinciden"
echo ""

# Verificar si Flutter está disponible
if ! command -v flutter &> /dev/null; then
    echo "Flutter no está instalado o no está en el PATH. Por favor, instale Flutter primero."
    exit 1
fi

echo "Ejecutando analizador de método de pago..."
echo "Por favor, espere mientras se inicia la aplicación..."
echo ""

# Ejecutar la aplicación Flutter
flutter run -d chrome --web-renderer html --target=lib/Screen/Inventory\ Sales/analizador_metodo_pago.dart
