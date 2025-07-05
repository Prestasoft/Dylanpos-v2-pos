#!/bin/bash

# Script para ejecutar el verificador completo de método de pago
# Este script ejecuta una aplicación Flutter para verificar visualmente
# que el método de pago seleccionado se guarda correctamente en Firebase

echo "=== Verificador Completo de Método de Pago ==="
echo ""
echo "Esta herramienta permite:"
echo "1. Visualizar las últimas transacciones y sus métodos de pago"
echo "2. Simular la selección de un método de pago en la pantalla de ventas"
echo "3. Generar reportes filtrados por método de pago"
echo ""

# Verificar si Flutter está disponible
if ! command -v flutter &> /dev/null; then
    echo "Flutter no está instalado o no está en el PATH. Por favor, instale Flutter primero."
    exit 1
fi

echo "Ejecutando verificador completo de método de pago..."
echo "Por favor, espere mientras se inicia la aplicación..."
echo ""

# Ejecutar la aplicación Flutter
flutter run -d chrome --web-renderer html --target=lib/Screen/Inventory\ Sales/verificador_metodo_pago_completo.dart

# Nota: También puedes ejecutarlo en dispositivos móviles cambiando -d chrome por el ID del dispositivo
# flutter devices # Para ver los dispositivos disponibles
