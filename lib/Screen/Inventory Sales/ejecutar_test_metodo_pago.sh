#!/bin/bash

# Script para ejecutar el verificador de método de pago por número de factura

echo "=== Test de Método de Pago por Factura ==="
echo "Esta herramienta permite verificar el método de pago de una factura específica"
echo ""

# Verificar si el Flutter está disponible
if ! command -v flutter &> /dev/null; then
    echo "Flutter no está instalado o no está en el PATH. Por favor, instale Flutter primero."
    exit 1
fi

echo "Ejecutando test de método de pago..."
echo "Ingrese el número de factura cuando se abra la aplicación para verificar"
echo "que el método de pago se guardó correctamente."
echo ""

# Ejecutar la aplicación de test
flutter run -d chrome --web-renderer html --target=lib/Screen/Inventory\ Sales/metodo_pago_test.dart
